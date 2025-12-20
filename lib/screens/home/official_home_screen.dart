import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/theme_provider.dart';
import '../../services/user_service.dart';
import '../../services/game_service.dart';
import '../../services/official_list_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../models/crew_model.dart';
import '../../app_colors.dart';
import '../../constants/firebase_constants.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class OfficialHomeScreen extends StatefulWidget {
  const OfficialHomeScreen({super.key});

  @override
  State<OfficialHomeScreen> createState() => _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  final UserService _userService = UserService();
  final GameService _gameService = GameService();
  final OfficialListService _listService = OfficialListService();
  final CrewRepository _crewRepo = CrewRepository();
  final NotificationService _notificationService = NotificationService();

  int _currentIndex = 0;
  UserModel? _currentUser;
  List<Map<String, dynamic>> _availableGames = [];
  List<Map<String, dynamic>> _pendingGames = [];
  List<Map<String, dynamic>> _confirmedGames = []; // Track confirmed games
  List<String> _dismissedGameIds = []; // Track dismissed game IDs
  List<String> _confirmedGameIds = []; // Track confirmed game IDs

  // Undo dismiss functionality
  Map<String, Map<String, dynamic>> _recentlyDismissedGames =
      {}; // Track recently dismissed games with full game data
  Timer? _undoTimer;
  Timer? _countdownTimer; // Timer to update countdown display
  bool _isLoading = true;
  int _pendingInvitationsCount = 0;
  int _preferenceRefreshCounter = 0; // Counter to force FutureBuilder refresh

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];

  // Legend toggle states
  bool _showConfirmedGames = true;
  bool _showAvailableGames = true;
  bool _showPendingGames = true;

  // Notification state
  int _unreadNotificationsCount = 0;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;

  void _startNotificationListener() {
    _stopNotificationListener(); // Clean up any existing listener

    final userId = _currentUser?.id;
    if (userId == null) return;

    debugPrint('📡 NOTIFICATION LISTENER: Starting listener for user $userId');

    _notificationSubscription = _getNotificationsStream().listen(
      (notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        if (unreadCount != _unreadNotificationsCount) {
          setState(() {
            _unreadNotificationsCount = unreadCount;
          });
          debugPrint(
              '📡 NOTIFICATION LISTENER: Updated unread count to $unreadCount');
        }
      },
      onError: (error) {
        debugPrint('📡 NOTIFICATION LISTENER: Error: $error');
      },
    );
  }

  void _stopNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  Future<void> _markNotificationsAsRead() async {
    final userId = _currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('📡 MARKING NOTIFICATIONS AS READ: For user $userId');
      await _notificationService.markAllAsRead(userId);

      // Update local count
      setState(() {
        _unreadNotificationsCount = 0;
      });
    } catch (e) {
      debugPrint('❌ Error marking notifications as read: $e');
    }
  }

  Future<void> _markSingleNotificationAsRead(String notificationId) async {
    try {
      debugPrint('📖 MARKING SINGLE NOTIFICATION AS READ: $notificationId');

      // Mark the notification as read in Firestore
      final success = await _notificationService.markAsRead(notificationId);

      if (success) {
        // Update the unread count (will be handled by the stream listener)
        debugPrint('✅ Notification marked as read successfully');
      } else {
        debugPrint('❌ Failed to mark notification as read');
      }
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    try {
      debugPrint('🗑️ DISMISSING NOTIFICATION: $notificationId');

      // Delete the notification from Firestore
      final success =
          await _notificationService.deleteNotification(notificationId);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to dismiss notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error dismissing notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to dismiss notification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopNotificationListener();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadPersistentData();
    await _loadData();
  }

  Future<void> _loadPersistentData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Load user's persistent game state from Firestore (force fresh read)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server)); // Force server read

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;

        // Load dismissed game IDs
        final dismissedIds =
            List<String>.from(userData['dismissedGameIds'] ?? []);

        // Load confirmed game IDs
        final confirmedIds =
            List<String>.from(userData['confirmedGameIds'] ?? []);

        print(
            '🔍 OFFICIAL HOME: Loaded confirmedGameIds from Firestore: $confirmedIds');

        setState(() {
          _dismissedGameIds = dismissedIds;
          _confirmedGameIds = confirmedIds;
        });

        // Load pending game IDs and match with actual games
        final pendingIds = List<String>.from(userData['pendingGameIds'] ?? []);
        await _loadPendingGamesFromIds(pendingIds);

        // Load confirmed games from IDs
        await _loadConfirmedGamesFromIds(confirmedIds);
      }
    } catch (e) {
      print('Error loading persistent data from Firestore: $e');
    }
  }

  Future<void> _loadPendingGamesFromIds(List<String> pendingIds) async {
    if (pendingIds.isEmpty) return;

    try {
      // Get all games and find the ones that match our pending IDs
      final allGames = await _gameService.getGames();

      // Get today's date for filtering past games
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final pendingGamesRaw = allGames.where((game) {
        final gameId = game['id'] as String?;
        if (gameId == null || !pendingIds.contains(gameId)) {
          return false;
        }

        // Filter out past games
        final gameDate = game['date'];
        if (gameDate != null) {
          try {
            final parsedDate = DateTime.parse(gameDate);
            final gameDay =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            if (gameDay.isBefore(today)) {
              return false; // Skip past games
            }
          } catch (e) {
            print('Error parsing pending game date: $e');
          }
        }

        return true;
      }).toList();

      // Add home team and determine pending status for games
      final pendingGames = <Map<String, dynamic>>[];
      for (final game in pendingGamesRaw) {
        final gameWithHomeTeam =
            game['homeTeam'] == null ? await _addHomeTeamToGame(game) : game;

        // Load crew information for crew games
        Map<String, dynamic> gameWithCrewInfo = gameWithHomeTeam;
        final selectedCrews =
            gameWithHomeTeam['selectedCrews'] as List<dynamic>?;
        final isCrewGame = selectedCrews != null && selectedCrews.isNotEmpty;

        if (isCrewGame && _currentUser?.id != null) {
          final crewInfo =
              await _loadCrewInfoForGame(gameWithHomeTeam, _currentUser!.id);
          gameWithCrewInfo = {...gameWithHomeTeam, ...crewInfo};
        }

        // Determine pending status for crew games
        String pendingStatus = 'waiting_for_scheduler'; // Default
        String? memberPreference;

        if (isCrewGame && _currentUser?.id != null) {
          // Check if crew chief has expressed interest
          final interestedOfficials = await _gameService
              .getInterestedOfficialsForGame(game['id'] as String);
          final hasCrewChiefInterest = interestedOfficials
              .any((official) => official['id'] == _currentUser!.id);

          if (hasCrewChiefInterest) {
            pendingStatus = 'waiting_for_scheduler';
          } else {
            pendingStatus = 'waiting_for_crew_chief';
            // Load member's preference for this game
            final userCrewId = gameWithCrewInfo['userCrewId'] as String?;
            if (userCrewId != null) {
              memberPreference = await _crewRepo.getCrewMemberPreference(
                  game['id'] as String, userCrewId, _currentUser!.id);
            }
          }
        }

        final gameData = {
          ...gameWithCrewInfo,
          'pending_status': pendingStatus,
        };

        if (memberPreference != null) {
          gameData['member_preference'] = memberPreference;
        }

        pendingGames.add(gameData);
      }

      setState(() {
        _pendingGames = pendingGames;
      });
    } catch (e) {
      print('Error loading pending games from IDs: $e');
    }
  }

  Future<void> _loadConfirmedGamesFromIds(List<String> confirmedIds) async {
    print('🔍 OFFICIAL HOME: Loading confirmed games from IDs: $confirmedIds');

    // Always clear the confirmed games list first, even if confirmedIds is empty
    if (confirmedIds.isEmpty) {
      print(
          '✅ OFFICIAL HOME: Confirmed IDs empty, clearing confirmed games list');
      setState(() {
        _confirmedGames = [];
      });
      return;
    }

    try {
      // Get all games and find the ones that match our confirmed IDs
      final allGames = await _gameService.getGames();
      print('🔍 OFFICIAL HOME: Found ${allGames.length} total games');

      // Get today's date for filtering past games
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final confirmedGamesRaw = allGames.where((game) {
        final gameId = game['id'] as String?;
        if (gameId == null || !confirmedIds.contains(gameId)) {
          return false;
        }

        // Filter out past games
        final gameDate = game['date'];
        if (gameDate != null) {
          try {
            final parsedDate = DateTime.parse(gameDate);
            final gameDay =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            if (gameDay.isBefore(today)) {
              return false; // Skip past games
            }
          } catch (e) {
            print('Error parsing confirmed game date: $e');
          }
        }

        return true;
      }).toList();

      print(
          '🔍 OFFICIAL HOME: Filtered to ${confirmedGamesRaw.length} confirmed games');

      // Add home team to games that don't have it
      final confirmedGames = <Map<String, dynamic>>[];
      for (final game in confirmedGamesRaw) {
        if (game['homeTeam'] == null) {
          final gameWithHomeTeam = await _addHomeTeamToGame(game);
          confirmedGames.add(gameWithHomeTeam);
        } else {
          confirmedGames.add(game);
        }
      }

      print(
          '✅ OFFICIAL HOME: Setting ${confirmedGames.length} confirmed games in state');
      setState(() {
        _confirmedGames = confirmedGames;
      });
    } catch (e) {
      print('❌ OFFICIAL HOME: Error loading confirmed games from IDs: $e');
      // Even on error, clear the list to prevent showing stale data
      setState(() {
        _confirmedGames = [];
      });
    }
  }

  Future<void> _savePersistentData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Prepare the data to save
      final pendingIds =
          _pendingGames.map((game) => game['id'] as String).toList();
      final confirmedIds =
          _confirmedGames.map((game) => game['id'] as String).toList();

      final updateData = {
        'dismissedGameIds': _dismissedGameIds,
        'pendingGameIds': pendingIds,
        'confirmedGameIds': confirmedIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updateData);

      print('✅ Saved persistent game state to Firestore for user $userId');
    } catch (e) {
      print('❌ Error saving persistent data to Firestore: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user
      _currentUser = await _userService.getCurrentUser();

      // Start listening to notifications for badge count
      _startNotificationListener();

      // Reload persistent data to get latest confirmed game IDs
      await _loadPersistentData();

      // Load real available games data
      await _loadAvailableGames();

      // Check for confirmed games and update pending/confirmed lists
      await _updateGameStatuses();

      // Load pending crew invitations count
      await _loadPendingInvitationsCount();

      // Increment preference refresh counter to force FutureBuilders to refresh
      _preferenceRefreshCounter++;
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingInvitationsCount() async {
    try {
      if (_currentUser?.id == null) return;

      print(
          '🏠 OFFICIAL HOME: Loading pending invitations for user: ${_currentUser!.id}');
      final invitations =
          await _crewRepo.getPendingInvitations(_currentUser!.id);
      print(
          '🏠 OFFICIAL HOME: Found ${invitations.length} pending invitations');
      if (mounted) {
        setState(() {
          _pendingInvitationsCount = invitations.length;
        });
      }
    } catch (e) {
      print('Error loading pending invitations count: $e');
    }
  }

  Future<void> _updateGameStatuses() async {
    if (_currentUser?.id == null) return;

    final currentOfficialId = _currentUser!.id;
    final gamesToMove = <Map<String, dynamic>>[];
    final confirmedGameIds = <String>[];

    // Check each pending game to see if this official has been confirmed
    for (final game in _pendingGames) {
      final gameId = game['id'] as String?;
      if (gameId != null) {
        try {
          final confirmedOfficials =
              await _gameService.getConfirmedOfficialsForGame(gameId);
          final isConfirmed = confirmedOfficials
              .any((official) => official['id'] == currentOfficialId);

          if (isConfirmed) {
            gamesToMove.add(game);
            confirmedGameIds.add(gameId);
          }
        } catch (e) {
          print('Error checking confirmation status for game $gameId: $e');
        }
      }
    }

    // Move confirmed games from pending to confirmed
    if (gamesToMove.isNotEmpty) {
      setState(() {
        _pendingGames.removeWhere((game) => gamesToMove.contains(game));
        _confirmedGames.addAll(gamesToMove);
        _confirmedGameIds.addAll(confirmedGameIds);
      });

      // Remove confirmed games from persistent pending IDs to prevent them from reappearing
      for (final gameId in confirmedGameIds) {
        // Remove from the in-memory dismissed list if present (though it shouldn't be)
        _dismissedGameIds.remove(gameId);
      }

      // Update persistent storage
      await _savePersistentData();

      print(
          '✅ Moved ${gamesToMove.length} games from pending to confirmed for official $currentOfficialId');
    }
  }

  Future<void> _loadAvailableGames() async {
    try {
      // Get all games from Firestore
      final allGames = await _gameService.getGames();

      // Get current official's ID
      final currentOfficialId = _currentUser?.id;
      if (currentOfficialId == null) {
        _availableGames = [];
        return;
      }

      // Get today's date for filtering past games
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filter for published games that are available for this specific official
      final filteredGames = <Map<String, dynamic>>[];

      for (final game in allGames) {
        final status = game['status'] as String?;
        final officialsHired = game['officialsHired'] as int? ?? 0;
        final officialsRequired = game['officialsRequired'] as int? ?? 1;

        // Game must be published and have available spots
        if (status != 'Published' || officialsHired >= officialsRequired) {
          continue;
        }

        // Skip past games
        final gameDate = game['date'];
        if (gameDate != null) {
          try {
            final parsedDate = DateTime.parse(gameDate);
            final gameDay =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            if (gameDay.isBefore(today)) {
              continue; // Skip past games
            }
          } catch (e) {
            print('Error parsing game date: $e');
            // Continue processing if date parsing fails
          }
        }

        // Check if this official is included in the game's selection criteria
        if (await _isOfficialIncludedInGameAsync(game, currentOfficialId)) {
          // Check if official is already confirmed for this game
          final confirmedOfficials = await _gameService
              .getConfirmedOfficialsForGame(game['id'] as String);
          final isAlreadyConfirmed = confirmedOfficials
              .any((official) => official['id'] == currentOfficialId);

          if (!isAlreadyConfirmed) {
            // Skip dismissed games and games that are already pending
            final gameId = game['id'] as String?;
            final pendingGameIds =
                _pendingGames.map((g) => g['id'] as String).toList();

            if (gameId != null &&
                !_dismissedGameIds.contains(gameId) &&
                !pendingGameIds.contains(gameId)) {
              // Load crew information for crew games
              Map<String, dynamic> gameWithCrewInfo = game;
              final selectedCrews = game['selectedCrews'] as List<dynamic>?;
              if (selectedCrews != null && selectedCrews.isNotEmpty) {
                final crewInfo =
                    await _loadCrewInfoForGame(game, currentOfficialId);
                gameWithCrewInfo = {...game, ...crewInfo};
              }

              // For games that don't have homeTeam set, try to derive it from the scheduler's profile
              if (gameWithCrewInfo['homeTeam'] == null) {
                final gameWithHomeTeam =
                    await _addHomeTeamToGame(gameWithCrewInfo);
                filteredGames.add(gameWithHomeTeam);
              } else {
                filteredGames.add(gameWithCrewInfo);
              }
            }
          }
        }
      }

      _availableGames = filteredGames;
      print(
          'Loaded ${_availableGames.length} available games for official $currentOfficialId');
      setState(() {});
    } catch (e) {
      print('Error loading available games: $e');
      _availableGames = [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadDismissedAvailableGames() async {
    try {
      // Get all games from Firestore
      final allGames = await _gameService.getGames();

      // Get current official's ID
      final currentOfficialId = _currentUser?.id;
      if (currentOfficialId == null) {
        return [];
      }

      // Get today's date for filtering past games
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filter for published games that are dismissed by this official but still available
      final filteredGames = <Map<String, dynamic>>[];

      for (final game in allGames) {
        final status = game['status'] as String?;
        final officialsHired = game['officialsHired'] as int? ?? 0;
        final officialsRequired = game['officialsRequired'] as int? ?? 1;
        final gameId = game['id'] as String?;

        // Game must be published, have available spots, and be dismissed by this official
        if (status != 'Published' ||
            officialsHired >= officialsRequired ||
            gameId == null ||
            !_dismissedGameIds.contains(gameId)) {
          continue;
        }

        // Skip past games
        final gameDate = game['date'];
        if (gameDate != null) {
          try {
            final parsedDate = DateTime.parse(gameDate);
            final gameDay =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            if (gameDay.isBefore(today)) {
              continue; // Skip past games
            }
          } catch (e) {
            print('Error parsing game date: $e');
            // Continue processing if date parsing fails
          }
        }

        // Check if this official is included in the game's selection criteria
        if (await _isOfficialIncludedInGameAsync(game, currentOfficialId)) {
          // Check if official is already confirmed for this game
          final confirmedOfficials =
              await _gameService.getConfirmedOfficialsForGame(gameId);
          final isAlreadyConfirmed = confirmedOfficials
              .any((official) => official['id'] == currentOfficialId);

          if (!isAlreadyConfirmed) {
            // Check if game is already pending (though dismissed games shouldn't be pending)
            final pendingGameIds =
                _pendingGames.map((g) => g['id'] as String).toList();

            if (!pendingGameIds.contains(gameId)) {
              // Load crew information for crew games
              Map<String, dynamic> gameWithCrewInfo = game;
              final selectedCrews = game['selectedCrews'] as List<dynamic>?;
              if (selectedCrews != null && selectedCrews.isNotEmpty) {
                final crewInfo =
                    await _loadCrewInfoForGame(game, currentOfficialId);
                gameWithCrewInfo = {...game, ...crewInfo};
              }

              // For games that don't have homeTeam set, try to derive it from the scheduler's profile
              if (gameWithCrewInfo['homeTeam'] == null) {
                final gameWithHomeTeam =
                    await _addHomeTeamToGame(gameWithCrewInfo);
                filteredGames.add(gameWithHomeTeam);
              } else {
                filteredGames.add(gameWithCrewInfo);
              }
            }
          }
        }
      }

      print(
          'Loaded ${filteredGames.length} dismissed but available games for official $currentOfficialId');
      return filteredGames;
    } catch (e) {
      print('Error loading dismissed available games: $e');
      return [];
    }
  }

  Future<void> _updatePersistentPendingGames() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Extract game IDs from pending games
      final pendingGameIds =
          _pendingGames.map((game) => game['id'] as String).toList();

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'pendingGameIds': pendingGameIds,
      });

      print('✅ Updated persistent pending games: $pendingGameIds');
    } catch (e) {
      print('❌ Error updating persistent pending games: $e');
    }
  }

  Widget _buildPendingGamesList() {
    // Separate games by status
    final waitingForCrewChief = _pendingGames
        .where((game) => game['pending_status'] == 'waiting_for_crew_chief')
        .toList();

    final waitingForScheduler = _pendingGames
        .where((game) => game['pending_status'] != 'waiting_for_crew_chief')
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Waiting for Crew Chief Decision section
        if (waitingForCrewChief.isNotEmpty) ...[
          _buildSectionHeader(
              'Waiting for Crew Chief Decision', waitingForCrewChief.length),
          const SizedBox(height: 8),
          ...waitingForCrewChief.map((game) =>
              _buildPendingGameCard(game, isWaitingForCrewChief: true)),
          if (waitingForScheduler.isNotEmpty) const SizedBox(height: 24),
        ],

        // Waiting for Scheduler Response section
        if (waitingForScheduler.isNotEmpty) ...[
          _buildSectionHeader(
              'Waiting for Scheduler Response', waitingForScheduler.length),
          const SizedBox(height: 8),
          ...waitingForScheduler.map((game) =>
              _buildPendingGameCard(game, isWaitingForCrewChief: false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getCrewMemberPreferenceSummary(
      String gameId, String crewId, int refreshCounter) async {
    // The refreshCounter parameter forces the FutureBuilder to refresh when it changes
    return await _crewRepo.getCrewMemberPreferenceSummary(gameId, crewId);
  }

  void _navigateToGameDetails(Map<String, dynamic> game) {
    Navigator.pushNamed(
      context,
      '/official-game-details',
      arguments: game,
    );
  }

  void _showCrewPreferenceDetails(
      BuildContext context,
      Map<String, dynamic> game,
      List<QueryDocumentSnapshot> preferenceDocs) async {
    // Fetch member names
    List<Map<String, dynamic>> preferencesWithNames = [];

    for (final doc in preferenceDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final crewMemberId = data['crew_member_id'] as String?;
      final preference = data['preference'] as String?;

      if (crewMemberId != null) {
        try {
          // Fetch user data to get the name
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(crewMemberId)
              .get();

          String memberName = 'Unknown';
          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;
            final profile = userData['profile'] as Map<String, dynamic>? ?? {};
            final firstName = profile['firstName'] as String? ?? '';
            final lastName = profile['lastName'] as String? ?? '';
            memberName = '$firstName $lastName'.trim();
            if (memberName.isEmpty) memberName = 'Unknown';
          }

          preferencesWithNames.add({
            'member_name': memberName,
            'preference': preference,
          });
        } catch (e) {
          print('Error fetching member name: $e');
          preferencesWithNames.add({
            'member_name': 'Unknown',
            'preference': preference,
          });
        }
      }
    }

    // Sort by preference then name
    preferencesWithNames.sort((a, b) {
      final prefA = a['preference'] as String?;
      final prefB = b['preference'] as String?;
      final nameA = a['member_name'] as String?;
      final nameB = b['member_name'] as String?;

      // First sort by preference (thumbs_up before thumbs_down)
      if (prefA != prefB) {
        if (prefA == 'thumbs_up') return -1;
        if (prefB == 'thumbs_up') return 1;
        return 0;
      }

      // Then sort by name
      return (nameA ?? '').compareTo(nameB ?? '');
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.group, color: AppColors.efficialsYellow, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Crew Preferences',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatGameTitle(game),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (preferencesWithNames.isEmpty)
                Center(
                  child: Text(
                    'No preferences recorded yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ...preferencesWithNames.map((pref) {
                  final memberName = pref['member_name'] as String?;
                  final preference = pref['preference'] as String?;

                  IconData icon;
                  Color iconColor;
                  String preferenceText;

                  switch (preference) {
                    case 'thumbs_up':
                      icon = Icons.thumb_up;
                      iconColor = Colors.green[600]!;
                      preferenceText = 'Likes this game';
                      break;
                    case 'thumbs_down':
                      icon = Icons.thumb_down;
                      iconColor = Colors.red[600]!;
                      preferenceText = 'Dislikes this game';
                      break;
                    default:
                      icon = Icons.help_outline;
                      iconColor = Colors.grey[600]!;
                      preferenceText = 'No preference';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            memberName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          preferenceText,
                          style: TextStyle(
                            fontSize: 12,
                            color: iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadCrewInfoForGame(
      Map<String, dynamic> game, String officialId) async {
    try {
      final selectedCrews = game['selectedCrews'] as List<dynamic>? ?? [];
      if (selectedCrews.isEmpty) {
        return {};
      }

      // Get user's crews
      final userCrews = await _crewRepo.getCrewsForOfficial(officialId);
      final userChiefCrews = await _crewRepo.getCrewsWhereChief(officialId);

      for (final crew in selectedCrews) {
        String crewId;
        if (crew is String) {
          crewId = crew;
        } else if (crew is Map && crew['id'] != null) {
          crewId = crew['id'] as String;
        } else {
          continue;
        }

        // Check if user is chief of this crew
        final chiefCrew = userChiefCrews.firstWhere(
          (c) => c.id == crewId,
          orElse: () => Crew(
            name: '',
            crewTypeId: 0,
            crewChiefId: '',
            createdBy: '',
            isActive: false,
            paymentMethod: '',
          ),
        );
        if (chiefCrew.id != null) {
          return {
            'isUserCrewChief': true,
            'isUserCrewMember': false,
            'userCrewId': crewId,
            'userCrewName': chiefCrew.name,
          };
        }

        // Check if user is member of this crew
        final memberCrew = userCrews.firstWhere(
          (c) => c.id == crewId,
          orElse: () => Crew(
            name: '',
            crewTypeId: 0,
            crewChiefId: '',
            createdBy: '',
            isActive: false,
            paymentMethod: '',
          ),
        );
        if (memberCrew.id != null) {
          return {
            'isUserCrewChief': false,
            'isUserCrewMember': true,
            'userCrewId': crewId,
            'userCrewName': memberCrew.name,
          };
        }
      }

      return {};
    } catch (e) {
      print('Error loading crew info for game: $e');
      return {};
    }
  }

  Future<void> _setCrewMemberPreference(
      Map<String, dynamic> game, String preference) async {
    try {
      if (_currentUser?.id == null || game['userCrewId'] == null) return;

      final gameId = game['id'] as String;
      final crewId = game['userCrewId'] as String;
      final memberId = _currentUser!.id;

      final success = await _crewRepo.setCrewMemberGamePreference(
          gameId, crewId, memberId, preference);

      if (success) {
        // Add game to pending games list (waiting for crew chief decision)
        final crewInfo = await _loadCrewInfoForGame(game, memberId);
        final gameWithStatus = {
          ...game, // Preserve all original game data
          ...crewInfo, // Add crew-specific info
          'pending_status':
              'waiting_for_crew_chief', // New field to track status
          'member_preference': preference,
        };

        setState(() {
          // Add to pending games if not already there
          if (!_pendingGames.any((g) => g['id'] == gameId)) {
            _pendingGames.add(gameWithStatus);
          }
          // Remove from available games
          _availableGames.removeWhere((g) => g['id'] == gameId);
          // Increment counter to force preference refresh for crew chiefs
          _preferenceRefreshCounter++;
        });

        // Update persistent data
        await _updatePersistentPendingGames();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              preference == 'thumbs_up'
                  ? 'You indicated you like this game - waiting for crew chief decision'
                  : 'You indicated you don\'t like this game - waiting for crew chief decision',
            ),
            backgroundColor:
                preference == 'thumbs_up' ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save your preference. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error setting crew member preference: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving preference. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _addHomeTeamToGame(
      Map<String, dynamic> game) async {
    try {
      final schedulerId = game['schedulerId'] as String?;
      if (schedulerId != null) {
        // Try to get the scheduler's profile
        final schedulerUser = await _userService.getUserById(schedulerId);
        if (schedulerUser != null && schedulerUser.schedulerProfile != null) {
          final profile = schedulerUser.schedulerProfile!;
          if (profile.type == 'Athletic Director' && profile.teamName != null) {
            // Add the home team to the game data
            final gameWithHomeTeam = Map<String, dynamic>.from(game);
            gameWithHomeTeam['homeTeam'] = profile.teamName;
            print(
                '🏈 Added homeTeam "${profile.teamName}" to game ${game['id']}');
            return gameWithHomeTeam;
          }
        }
      }
    } catch (e) {
      print('Error adding home team to game ${game['id']}: $e');
    }

    // Return the original game if we can't add home team
    return game;
  }

  Future<bool> _isOfficialIncludedInGameAsync(
      Map<String, dynamic> game, String officialId) async {
    try {
      // Check if official is directly selected
      final selectedOfficials = game['selectedOfficials'] as List<dynamic>?;
      if (selectedOfficials != null) {
        // selectedOfficials can contain either user IDs or official objects
        for (final selectedOfficial in selectedOfficials) {
          if (selectedOfficial is String && selectedOfficial == officialId) {
            return true;
          } else if (selectedOfficial is Map &&
              selectedOfficial['id'] == officialId) {
            return true;
          } else if (selectedOfficial is Map &&
              selectedOfficial['userId'] == officialId) {
            return true;
          }
        }
      }

      // Check if official is in a single selected list (e.g., from bulk import)
      final selectedListName = game['selectedListName'] as String?;
      if (selectedListName != null && selectedListName.isNotEmpty) {
        print(
            '🔍 Checking selectedListName: $selectedListName for official $officialId');
        if (await _isOfficialInListByNameAsync(officialId, selectedListName)) {
          print('✅ Official $officialId IS in list $selectedListName');
          return true;
        } else {
          print('❌ Official $officialId NOT in list $selectedListName');
        }
      }

      // Check if official is in selected lists (array format)
      final selectedLists = game['selectedLists'] as List<dynamic>?;
      if (selectedLists != null && selectedLists.isNotEmpty) {
        // Check if official is in any of the selected lists
        for (final listConfig in selectedLists) {
          if (listConfig is Map && listConfig['list'] != null) {
            final listName = listConfig['list'] as String;
            if (await _isOfficialInListByNameAsync(officialId, listName)) {
              return true;
            }
          }
          // Also handle simple string format
          if (listConfig is String && listConfig.isNotEmpty) {
            if (await _isOfficialInListByNameAsync(officialId, listConfig)) {
              return true;
            }
          }
        }
      }

      // Check if official is in selected crews
      final selectedCrews = game['selectedCrews'] as List<dynamic>?;
      if (selectedCrews != null && selectedCrews.isNotEmpty) {
        // Check if the official is a member of any of the selected crews
        final officialCrews = await _crewRepo.getCrewsForOfficial(officialId);
        final officialCrewIds = officialCrews.map((crew) => crew.id).toSet();

        for (final selectedCrew in selectedCrews) {
          String crewId;
          if (selectedCrew is String) {
            crewId = selectedCrew;
          } else if (selectedCrew is Map && selectedCrew['id'] != null) {
            crewId = selectedCrew['id'] as String;
          } else {
            continue;
          }

          if (officialCrewIds.contains(crewId)) {
            return true;
          }
        }
      }

      // If no specific selection criteria, check if it's "hire automatically" method
      // In this case, all eligible officials should see the game
      final method = game['method'] as String?;
      if (method == 'hire_automatically' || method == 'use_list') {
        // For use_list method, we've already checked selectedListName above
        // If we get here with use_list but no list matched, it means the official
        // is not in that list
        if (method == 'use_list' && selectedListName == null) {
          // No list specified, show to all officials
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking if official is included in game: $e');
      return false;
    }
  }

  Future<bool> _isOfficialInListByNameAsync(
      String officialId, String listName) async {
    try {
      // First, find the list document by name
      print('🔍 Looking for official_lists with name: "$listName"');
      final listsQuery = await _listService.firestore
          .collection('official_lists')
          .where('name', isEqualTo: listName)
          .get();

      if (listsQuery.docs.isEmpty) {
        print('⚠️ No list found with name: "$listName"');
        return false;
      }
      print('✅ Found list "$listName" with ${listsQuery.docs.length} docs');

      // Get the first matching list (should only be one with unique names)
      final listDoc = listsQuery.docs.first;
      final listData = listDoc.data();
      final officials = listData['officials'] as List<dynamic>?;

      if (officials == null) {
        print('⚠️ List "$listName" has no officials array');
        return false;
      }
      print('📋 List "$listName" has ${officials.length} officials');

      // Check if the official ID is in the list
      for (final official in officials) {
        if (official is Map && official['id'] == officialId) {
          return true;
        } else if (official is Map && official['userId'] == officialId) {
          return true;
        } else if (official is String && official == officialId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking list membership for list "$listName": $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Icon(
              Icons.sports,
              color:
                  themeProvider.isDarkMode ? colorScheme.primary : Colors.black,
              size: 32,
            );
          },
        ),
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: 'Toggle theme',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            color: colorScheme.surface,
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'profile') {
                Navigator.pushNamed(context, '/official-profile-view');
              } else if (value == 'dismissed_games') {
                _showDismissedGames();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'dismissed_games',
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('View Dismissed Games',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildAvailableTab();
      case 2:
        return _buildPendingTab();
      case 3:
        return _buildCalendarTab();
      case 4:
        return _buildNotificationsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading your assignments...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            // Welcome Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good ${_getGreetingTime()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _currentUser?.fullName ?? 'Official',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Crew Management Button (like v1.0)
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/crew_dashboard')
                                .then((_) {
                              // Refresh invitation count when returning from crew dashboard
                              _loadPendingInvitationsCount();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.efficialsYellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    AppColors.efficialsYellow.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups, // Three people icon like v1.0
                                  color: AppColors.efficialsYellow,
                                  size: 20,
                                ),
                                if (_pendingInvitationsCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _pendingInvitationsCount > 99
                                          ? '99+'
                                          : _pendingInvitationsCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Confirmed',
                        value: '${_confirmedGames.length}',
                        icon: Icons.check_circle,
                        color: Colors.green,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Available',
                        value: '${_availableGames.length}',
                        icon: Icons.sports,
                        color: Colors.blue,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Pending',
                        value: '${_pendingGames.length}',
                        icon: Icons.hourglass_empty,
                        color: Colors.orange,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Games Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Confirmed Games',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_confirmedGames.length}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Confirmed Games List
            SliverFillRemaining(
              child: _confirmedGames.isEmpty
                  ? _buildEmptyState(
                      'No confirmed games yet',
                      Icons.assignment_turned_in,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _getGroupedConfirmedGames().length,
                      itemBuilder: (context, index) {
                        final group = _getGroupedConfirmedGames()[index];
                        if (group.length == 1) {
                          // Single game
                          return _buildConfirmedGameCard(group[0]);
                        } else {
                          // Linked games group
                          return _buildLinkedConfirmedGamesGroup(group);
                        }
                      },
                    ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  List<List<Map<String, dynamic>>> _getGroupedAvailableGames() {
    final linkedGroups = <String, List<Map<String, dynamic>>>{};
    final unlinkedGames = <Map<String, dynamic>>[];

    for (final game in _availableGames) {
      final linkGroupId = game['linkGroupId'] as String?;
      if (linkGroupId != null && linkGroupId.isNotEmpty) {
        linkedGroups.putIfAbsent(linkGroupId, () => []).add(game);
      } else {
        unlinkedGames.add(game);
      }
    }

    // Sort games within each linked group by date and time
    linkedGroups.forEach((key, games) {
      games.sort((a, b) {
        DateTime? aDate;
        DateTime? bDate;
        TimeOfDay? aTime;
        TimeOfDay? bTime;

        // Parse dates
        if (a['date'] != null) {
          try {
            final dateValue = a['date'];
            aDate = dateValue is DateTime
                ? dateValue
                : DateTime.parse(dateValue.toString());
          } catch (e) {/* handle error */}
        }
        if (b['date'] != null) {
          try {
            final dateValue = b['date'];
            bDate = dateValue is DateTime
                ? dateValue
                : DateTime.parse(dateValue.toString());
          } catch (e) {/* handle error */}
        }

        // Parse times
        if (a['time'] != null) {
          try {
            final timeValue = a['time'];
            if (timeValue is TimeOfDay) {
              aTime = timeValue;
            } else {
              final parts = timeValue.toString().split(':');
              if (parts.length == 2) {
                aTime = TimeOfDay(
                    hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
            }
          } catch (e) {/* handle error */}
        }
        if (b['time'] != null) {
          try {
            final timeValue = b['time'];
            if (timeValue is TimeOfDay) {
              bTime = timeValue;
            } else {
              final parts = timeValue.toString().split(':');
              if (parts.length == 2) {
                bTime = TimeOfDay(
                    hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
            }
          } catch (e) {/* handle error */}
        }

        // Compare dates first
        if (aDate != null && bDate != null) {
          final dateComparison = aDate.compareTo(bDate);
          if (dateComparison != 0) {
            return dateComparison;
          }
        } else if (aDate != null) {
          return -1;
        } else if (bDate != null) {
          return 1;
        }

        // If dates are the same or one is null, compare times
        if (aTime != null && bTime != null) {
          return (aTime.hour * 60 + aTime.minute)
              .compareTo(bTime.hour * 60 + bTime.minute);
        } else if (aTime != null) {
          return -1;
        } else if (bTime != null) {
          return 1;
        }

        return 0;
      });
    });

    // Combine linked groups and unlinked games
    final result = <List<Map<String, dynamic>>>[];
    result.addAll(linkedGroups.values);
    result.addAll(unlinkedGames.map((game) => [game]));

    return result;
  }

  List<List<Map<String, dynamic>>> _getGroupedGames(
      List<Map<String, dynamic>> games) {
    final linkedGroups = <String, List<Map<String, dynamic>>>{};
    final unlinkedGames = <Map<String, dynamic>>[];

    for (final game in games) {
      final linkGroupId = game['linkGroupId'] as String?;
      if (linkGroupId != null && linkGroupId.isNotEmpty) {
        linkedGroups.putIfAbsent(linkGroupId, () => []).add(game);
      } else {
        unlinkedGames.add(game);
      }
    }

    // Sort games within each linked group by date and time
    linkedGroups.forEach((key, groupGames) {
      groupGames.sort((a, b) {
        DateTime? aDate;
        DateTime? bDate;
        TimeOfDay? aTime;
        TimeOfDay? bTime;

        // Parse dates
        if (a['date'] != null) {
          try {
            final dateValue = a['date'];
            aDate = dateValue is DateTime
                ? dateValue
                : DateTime.parse(dateValue.toString());
          } catch (e) {/* handle error */}
        }
        if (b['date'] != null) {
          try {
            final dateValue = b['date'];
            bDate = dateValue is DateTime
                ? dateValue
                : DateTime.parse(dateValue.toString());
          } catch (e) {/* handle error */}
        }

        // Parse times
        if (a['time'] != null) {
          try {
            final timeValue = a['time'];
            if (timeValue is TimeOfDay) {
              aTime = timeValue;
            } else {
              final parts = timeValue.toString().split(':');
              if (parts.length == 2) {
                aTime = TimeOfDay(
                    hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
            }
          } catch (e) {/* handle error */}
        }
        if (b['time'] != null) {
          try {
            final timeValue = b['time'];
            if (timeValue is TimeOfDay) {
              bTime = timeValue;
            } else {
              final parts = timeValue.toString().split(':');
              if (parts.length == 2) {
                bTime = TimeOfDay(
                    hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
            }
          } catch (e) {/* handle error */}
        }

        // Compare dates first
        if (aDate != null && bDate != null) {
          final dateComparison = aDate.compareTo(bDate);
          if (dateComparison != 0) {
            return dateComparison;
          }
        } else if (aDate != null) {
          return -1;
        } else if (bDate != null) {
          return 1;
        }

        // If dates are the same or one is null, compare times
        if (aTime != null && bTime != null) {
          return (aTime.hour * 60 + aTime.minute)
              .compareTo(bTime.hour * 60 + bTime.minute);
        } else if (aTime != null) {
          return -1;
        } else if (bTime != null) {
          return 1;
        }

        return 0;
      });
    });

    // Combine linked groups and unlinked games
    final result = <List<Map<String, dynamic>>>[];
    result.addAll(linkedGroups.values);
    result.addAll(unlinkedGames.map((game) => [game]));

    return result;
  }

  Widget _buildLinkedAvailableGamesGroup(
      List<Map<String, dynamic>> linkedGames) {
    if (linkedGames.length < 2) {
      return _buildAvailableGameCard(linkedGames.first);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Column(
            children: [
              // Top card - first game
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildTopLinkedGameContent(linkedGames[0]),
              ),
              // No gap - cards pressed together
              // Bottom card - second game + shared info
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    _buildBottomLinkedGameContent(linkedGames[1], linkedGames),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopLinkedGameContent(Map<String, dynamic> game) {
    return InkWell(
      onTap: () => _navigateToGameDetails(game),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  game['sport'] ?? 'Sport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.efficialsYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LINKED GAMES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatGameTitle(game),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game['scheduleName'] ?? 'Unnamed Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLinkedGameContent(
      Map<String, dynamic> game, List<Map<String, dynamic>> linkedGames) {
    // Check if this is a "Hire Automatically" game
    final isHireAutomatically = game['hireAutomatically'] == true;

    // Check if this is a crew-offered game
    final selectedCrews = game['selectedCrews'] as List<dynamic>?;
    final isCrewGame = selectedCrews != null && selectedCrews.isNotEmpty;

    // Get crew information from game data (should be loaded in _loadAvailableGames)
    final isUserCrewChief = game['isUserCrewChief'] as bool? ?? false;
    final isUserCrewMember = game['isUserCrewMember'] as bool? ?? false;
    final userCrewId = game['userCrewId'] as String?;
    final userCrewName = game['userCrewName'] as String?;

    return InkWell(
      onTap: () => _navigateToGameDetails(game),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatGameTitle(game),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game['scheduleName'] ?? 'Unnamed Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${game['officialsHired'] ?? 0} of ${game['officialsRequired'] ?? 0} officials confirmed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),

            // Show crew information for crew games
            if (isCrewGame) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.efficialsYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.efficialsYellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUserCrewChief ? Icons.star : Icons.group,
                      size: 14,
                      color: AppColors.efficialsYellow,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUserCrewChief
                                ? 'Your crew "${userCrewName ?? 'Unknown'}" can accept this game'
                                : isUserCrewMember
                                    ? 'Offered to your crew "${userCrewName ?? 'Unknown'}"'
                                    : 'Crew game - contact your crew chief',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Show crew member preferences for crew chiefs
                          if (isUserCrewChief && userCrewId != null) ...[
                            const SizedBox(height: 4),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('crew_member_game_preferences')
                                  .where('game_id', isEqualTo: game['id'])
                                  .where('crew_id', isEqualTo: userCrewId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  final docs = snapshot.data!.docs;
                                  int thumbsUp = 0;
                                  int thumbsDown = 0;

                                  for (final doc in docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final preference =
                                        data['preference'] as String?;

                                    if (preference == 'thumbs_up') thumbsUp++;
                                    if (preference == 'thumbs_down')
                                      thumbsDown++;
                                  }

                                  final totalResponses = thumbsUp + thumbsDown;

                                  if (totalResponses > 0) {
                                    return GestureDetector(
                                      onTap: () => _showCrewPreferenceDetails(
                                          context, game, docs),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.efficialsYellow
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: AppColors.efficialsYellow
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.thumb_up,
                                                size: 12,
                                                color: Colors.green[600]),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$thumbsUp',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(Icons.thumb_down,
                                                size: 12,
                                                color: Colors.red[600]),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$thumbsDown',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.info_outline,
                                              size: 10,
                                              color: AppColors.efficialsYellow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Shared information for linked games (no longer in blue container)
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  game['location'] ?? 'TBD',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fee: \$${game['gameFee'] ?? '0'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dismiss button (always available)
                    ElevatedButton(
                      onPressed: () => _dismissGame(game),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button - only for crew chiefs or non-crew games
                    ElevatedButton(
                      onPressed: () => isHireAutomatically
                          ? _showClaimLinkedGamesDialog(linkedGames)
                          : _showExpressInterestDialog(game),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHireAutomatically
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            isHireAutomatically ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        isHireAutomatically ? 'Claim All' : 'Express Interest',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<List<Map<String, dynamic>>> _getGroupedConfirmedGames() {
    final linkedGroups = <String, List<Map<String, dynamic>>>{};
    final unlinkedGames = <Map<String, dynamic>>[];

    for (final game in _confirmedGames) {
      final linkGroupId = game['linkGroupId'] as String?;
      if (linkGroupId != null && linkGroupId.isNotEmpty) {
        linkedGroups.putIfAbsent(linkGroupId, () => []).add(game);
      } else {
        unlinkedGames.add(game);
      }
    }

    // Sort games within each linked group by date and time
    linkedGroups.forEach((key, games) {
      games.sort((a, b) {
        DateTime? aDate;
        DateTime? bDate;
        TimeOfDay? aTime;
        TimeOfDay? bTime;

        // Parse dates
        if (a['date'] != null) {
          try {
            final dateValue = a['date'];
            aDate = dateValue is DateTime
                ? dateValue
                : DateTime.parse(dateValue.toString());
          } catch (e) {/* handle error */}
        }
        if (b['date'] != null) {
          try {
            final dateValue = b['date'];
            bDate = dateValue is DateTime
                ? dateValue
                : DateTime.parse(dateValue.toString());
          } catch (e) {/* handle error */}
        }

        // Parse times
        if (a['time'] != null) {
          try {
            final timeValue = a['time'];
            if (timeValue is TimeOfDay) {
              aTime = timeValue;
            } else {
              final parts = timeValue.toString().split(':');
              if (parts.length == 2) {
                aTime = TimeOfDay(
                    hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
            }
          } catch (e) {/* handle error */}
        }
        if (b['time'] != null) {
          try {
            final timeValue = b['time'];
            if (timeValue is TimeOfDay) {
              bTime = timeValue;
            } else {
              final parts = timeValue.toString().split(':');
              if (parts.length == 2) {
                bTime = TimeOfDay(
                    hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
            }
          } catch (e) {/* handle error */}
        }

        // Compare dates first
        if (aDate != null && bDate != null) {
          final dateComparison = aDate.compareTo(bDate);
          if (dateComparison != 0) {
            return dateComparison;
          }
        } else if (aDate != null) {
          return -1;
        } else if (bDate != null) {
          return 1;
        }

        // If dates are the same or one is null, compare times
        if (aTime != null && bTime != null) {
          return (aTime.hour * 60 + aTime.minute)
              .compareTo(bTime.hour * 60 + bTime.minute);
        } else if (aTime != null) {
          return -1;
        } else if (bTime != null) {
          return 1;
        }

        return 0;
      });
    });

    // Combine linked groups and unlinked games
    final result = <List<Map<String, dynamic>>>[];
    result.addAll(linkedGroups.values);
    result.addAll(unlinkedGames.map((game) => [game]));

    return result;
  }

  Widget _buildLinkedConfirmedGamesGroup(
      List<Map<String, dynamic>> linkedGames) {
    if (linkedGames.length < 2) {
      return _buildConfirmedGameCard(linkedGames.first);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Column(
            children: [
              // Top card - first game
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildTopLinkedConfirmedGameContent(linkedGames[0]),
              ),
              // No gap - cards pressed together
              // Bottom card - second game + shared info
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildBottomLinkedConfirmedGameContent(linkedGames[1]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopLinkedConfirmedGameContent(Map<String, dynamic> game) {
    return InkWell(
      onTap: () => _viewGameDetails(game),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  game['sport'] ?? 'Sport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.efficialsYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'LINKED GAMES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatGameTitle(game),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game['scheduleName'] ?? 'Unnamed Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLinkedConfirmedGameContent(Map<String, dynamic> game) {
    return InkWell(
      onTap: () => _viewGameDetails(game),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatGameTitle(game),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game['scheduleName'] ?? 'Unnamed Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Shared information for linked games (Location and Fee)
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  game['location'] ?? 'TBD',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Fee: \$${game['gameFee'] ?? '0'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirmed: Ready to officiate',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<NotificationModel>> _getNotificationsStream() {
    final userId = _currentUser?.id;
    if (userId == null) return Stream.value([]);

    debugPrint('📡 NOTIFICATION STREAM: Setting up stream for user $userId');

    // Listen to real-time changes in the notifications collection
    // Note: Removed orderBy to avoid requiring a composite index for now
    // We'll sort in memory instead
    return FirebaseFirestore.instance
        .collection(FirebaseCollections.notifications)
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      debugPrint(
          '📡 NOTIFICATION STREAM: Received ${snapshot.docs.length} notification documents for user $userId');
      final notifications = snapshot.docs
          .map((doc) {
            try {
              final notification = NotificationModel.fromMap(doc.data());
              debugPrint(
                  '📡 NOTIFICATION STREAM: Parsed notification ${doc.id}: ${notification.title}');
              return notification;
            } catch (e) {
              debugPrint(
                  '📡 NOTIFICATION STREAM: Error parsing notification ${doc.id}: $e');
              return null;
            }
          })
          .where((n) => n != null)
          .cast<NotificationModel>()
          .toList();

      // Sort by createdAt descending since we can't do it in the query without an index
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
          '📡 NOTIFICATION STREAM: Returning ${notifications.length} parsed and sorted notifications');
      return notifications;
    });
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getNotificationBorderColor(notification.type),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Text(
                notification.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (!notification.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          // Show changes for game updates
          if (notification.type == NotificationType.gameUpdated &&
              notification.data?['changes'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Changes Made:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...(notification.data!['changes'] as List<dynamic>)
                      .map((change) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• ${change.toString().capitalize()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          )),
                ],
              ),
            ),
          ],

          if (notification.contactInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.contactInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatNotificationTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
              Row(
                children: [
                  if (!notification.isRead)
                    TextButton(
                      onPressed: () =>
                          _markSingleNotificationAsRead(notification.id),
                      child: const Text(
                        'Mark as Read',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  TextButton(
                    onPressed: () => _dismissNotification(notification.id),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDismissedGames() async {
    final dismissedAvailableGames = await _loadDismissedAvailableGames();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dismissed Games',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${dismissedAvailableGames.length} dismissed ${dismissedAvailableGames.length == 1 ? 'game' : 'games'} still available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 20),

                // Games List
                Expanded(
                  child: dismissedAvailableGames.isEmpty
                      ? _buildEmptyState(
                          'No dismissed games available', Icons.visibility_off)
                      : ListView.builder(
                          itemCount:
                              _getGroupedGames(dismissedAvailableGames).length,
                          itemBuilder: (context, index) {
                            final group = _getGroupedGames(
                                dismissedAvailableGames)[index];
                            if (group.length == 1) {
                              // Single game
                              return _buildDismissedGameCard(group[0]);
                            } else {
                              // Linked games group
                              return _buildLinkedDismissedGamesGroup(group);
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDismissedGameCard(Map<String, dynamic> game) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewGameDetails(game),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game title and sport
              Row(
                children: [
                  Expanded(
                    child: Text(
                      game['title'] ?? 'Untitled Game',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      game['sport'] ?? 'Unknown Sport',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date, time, location
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatGameDate(game),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(
                    _formatGameTime(game),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on,
                      size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game['location'] ?? 'Location TBD',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Officials needed and action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${game['officialsHired'] ?? 0} of ${game['officialsRequired'] ?? 0} officials confirmed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _reshowGame(game),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Re-show'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedDismissedGamesGroup(List<Map<String, dynamic>> games) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.link, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Linked Games',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${games.length} games',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Individual games in group
          ...games.map((game) => InkWell(
                onTap: () => _viewGameDetails(game),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Game title
                      Text(
                        game['title'] ?? 'Untitled Game',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Date, time, location
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatGameDate(game),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            _formatGameTime(game),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              game['location'] ?? 'Location TBD',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Officials needed and action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${game['officialsHired'] ?? 0} of ${game['officialsRequired'] ?? 0} officials confirmed',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _reshowGame(game),
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('Re-show'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Color _getNotificationBorderColor(NotificationType type) {
    switch (type) {
      case NotificationType.gameCanceled:
      case NotificationType.gameDeleted:
        return Colors.red;
      case NotificationType.gameUpdated:
        return Colors.orange;
      case NotificationType.gameAssigned:
        return Colors.green;
      case NotificationType.gameUnassigned:
        return Colors.orange;
      case NotificationType.crewInvitation:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
    setState(() {}); // Refresh the UI
  }

  Widget _buildAvailableTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Available Games',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_availableGames.length} ${_availableGames.length == 1 ? 'game' : 'games'} posted by schedulers',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // Undo Dismiss Section
          if (_recentlyDismissedGames.isNotEmpty) ...[
            Builder(
              builder: (context) {
                // Find the most recently dismissed game
                final mostRecentEntry =
                    _recentlyDismissedGames.entries.reduce((a, b) {
                  final aTime = a.value['_dismissedAt'] as DateTime;
                  final bTime = b.value['_dismissedAt'] as DateTime;
                  return aTime.isAfter(bTime) ? a : b;
                });
                final gameId = mostRecentEntry.key;
                final dismissedGame = mostRecentEntry.value;
                final dismissedTime = dismissedGame['_dismissedAt'] as DateTime;
                final secondsLeft =
                    4 - DateTime.now().difference(dismissedTime).inSeconds;
                final canUndo = secondsLeft > 0;

                return GestureDetector(
                  onTap: canUndo ? () => _undoDismiss(gameId) : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: canUndo
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: canUndo
                            ? Colors.red.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.undo,
                          color: canUndo ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Game dismissed',
                            style: TextStyle(
                              color: canUndo ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          secondsLeft > 0
                              ? 'Undo (${secondsLeft}s)'
                              : 'Expired',
                          style: TextStyle(
                            color: canUndo ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          // Available Games List
          Expanded(
            child: _availableGames.isEmpty
                ? _buildEmptyState('No available games', Icons.sports)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _getGroupedAvailableGames().length,
                    itemBuilder: (context, index) {
                      final group = _getGroupedAvailableGames()[index];
                      if (group.length == 1) {
                        // Single game
                        return _buildAvailableGameCard(group[0]);
                      } else {
                        // Linked games group
                        return _buildLinkedAvailableGamesGroup(group);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Pending Interest',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_pendingGames.length} ${_pendingGames.length == 1 ? 'game' : 'games'} awaiting scheduler response',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // Pending Games List
          Expanded(
            child: _pendingGames.isEmpty
                ? _buildEmptyState(
                    'No pending applications', Icons.hourglass_empty)
                : _buildPendingGamesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    final gamesByDate = _getGamesByDate();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () =>
              setState(() => _currentIndex = 0), // Go back to home tab
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar and Legend (sized to content)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Calendar
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: _onDaySelected,
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                    weekendTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                    leftChevronIcon: Icon(Icons.chevron_left,
                        color: Theme.of(context).colorScheme.primary),
                    rightChevronIcon: Icon(Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary),
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final dateColor = _getDateColor(day, gamesByDate);
                      if (dateColor != Colors.transparent) {
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: dateColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final dateColor = _getDateColor(day, gamesByDate);
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: dateColor != Colors.transparent
                              ? dateColor
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: dateColor != Colors.transparent
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final dateColor = _getDateColor(day, gamesByDate);
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: dateColor != Colors.transparent
                              ? dateColor
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: dateColor != Colors.transparent
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Color Legend (toggleable)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendToggleItem(
                          'Confirmed', Colors.green, _showConfirmedGames, () {
                        setState(
                            () => _showConfirmedGames = !_showConfirmedGames);
                      }),
                      _buildLegendToggleItem(
                          'Available', Colors.blue[300]!, _showAvailableGames,
                          () {
                        setState(
                            () => _showAvailableGames = !_showAvailableGames);
                      }),
                      _buildLegendToggleItem(
                          'Pending', Colors.orange[300]!, _showPendingGames,
                          () {
                        setState(() => _showPendingGames = !_showPendingGames);
                      }),
                    ],
                  ),
                ),
              ],
            ),

            // Selected Day Games (only show for confirmed games) - takes remaining space
            if (_selectedDayGames.isNotEmpty)
              Expanded(
                child: Container(
                  child: ListView.builder(
                    itemCount: _selectedDayGames.length,
                    itemBuilder: (context, index) {
                      final game = _selectedDayGames[index];
                      return _buildAbbreviatedGameTile(game);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendToggleItem(
      String label, Color color, bool isEnabled, VoidCallback onToggle) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isEnabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled ? color : Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isEnabled ? color : Colors.grey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isEnabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbbreviatedGameTile(Map<String, dynamic> game) {
    final gameTitle = _formatGameTitle(game);
    final gameTime = _formatGameTime(game);
    final location = game['location'] ?? 'TBD';
    final fee = _parseFee(game['gameFee']);

    return GestureDetector(
      onTap: () => _viewGameDetails(game),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CONFIRMED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[300],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game['scheduleName'] ?? 'Unnamed Schedule',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        gameTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '\$${fee.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay updated with your assignments',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('⏳ NOTIFICATION UI: Stream is waiting for data');
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint(
                      '❌ NOTIFICATION UI: Stream error: ${snapshot.error}');
                  return _buildEmptyState(
                    'Error loading notifications',
                    Icons.error_outline,
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return _buildEmptyState(
                    'No notifications yet',
                    Icons.notifications_none,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final officialProfile = _currentUser?.officialProfile;
    final followThroughRate = officialProfile?.followThroughRate ?? 100.0;
    final totalAcceptedGames = officialProfile?.totalAcceptedGames ?? 0;
    final totalBackedOutGames = officialProfile?.totalBackedOutGames ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.fullName ?? 'Official',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        _currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance Stats Section
            Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Stats Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  title: 'Follow-Through',
                  value: '${followThroughRate.toStringAsFixed(1)}%',
                  icon: Icons.check_circle,
                  color: followThroughRate >= 90.0
                      ? Colors.green
                      : followThroughRate >= 75.0
                          ? Colors.orange
                          : Colors.red,
                ),
                _buildStatCard(
                  title: 'Total Accepted',
                  value: '$totalAcceptedGames',
                  icon: Icons.assignment_turned_in,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Backed Out',
                  value: '$totalBackedOutGames',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
                _buildStatCard(
                  title: 'Completed',
                  value: '${totalAcceptedGames - totalBackedOutGames}',
                  icon: Icons.done_all,
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About Follow-Through Rate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your follow-through rate is calculated as the percentage of games you accept and complete without backing out. Maintaining a high rate increases your credibility with schedulers.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Edit Profile Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/official-profile'),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableGameCard(Map<String, dynamic> game) {
    // Check if this is a "Hire Automatically" game
    final isHireAutomatically = game['hireAutomatically'] == true;

    // Check if this is a crew-offered game
    final selectedCrews = game['selectedCrews'] as List<dynamic>?;
    final isCrewGame = selectedCrews != null && selectedCrews.isNotEmpty;

    // Get crew information from game data (should be loaded in _loadAvailableGames)
    final isUserCrewChief = game['isUserCrewChief'] as bool? ?? false;
    final isUserCrewMember = game['isUserCrewMember'] as bool? ?? false;
    final userCrewId = game['userCrewId'] as String?;
    final userCrewName = game['userCrewName'] as String?;

    return InkWell(
      onTap: () => _navigateToGameDetails(game),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  game['sport'] ?? 'Sport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCrewGame
                        ? AppColors.efficialsYellow.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isCrewGame ? 'CREW GAME' : 'AVAILABLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCrewGame ? Colors.white : Colors.blue[300],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatGameTitle(game),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game['scheduleName'] ?? 'Unnamed Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  game['location'] ?? 'TBD',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            // Show crew information for crew games
            if (isCrewGame) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.efficialsYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.efficialsYellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUserCrewChief ? Icons.star : Icons.group,
                      size: 14,
                      color: AppColors.efficialsYellow,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUserCrewChief
                                ? 'Your crew "${userCrewName ?? 'Unknown'}" can accept this game'
                                : isUserCrewMember
                                    ? 'Offered to your crew "${userCrewName ?? 'Unknown'}"'
                                    : 'Crew game - contact your crew chief',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Show crew member preferences for crew chiefs
                          if (isUserCrewChief && userCrewId != null) ...[
                            const SizedBox(height: 4),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('crew_member_game_preferences')
                                  .where('game_id', isEqualTo: game['id'])
                                  .where('crew_id', isEqualTo: userCrewId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  final docs = snapshot.data!.docs;
                                  int thumbsUp = 0;
                                  int thumbsDown = 0;
                                  List<Map<String, dynamic>> preferences = [];

                                  // Collect preference data
                                  List<String> memberIds = [];
                                  for (final doc in docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final preference =
                                        data['preference'] as String?;
                                    final crewMemberId =
                                        data['crew_member_id'] as String?;

                                    if (crewMemberId != null) {
                                      memberIds.add(crewMemberId);
                                      preferences.add({
                                        'member_id': crewMemberId,
                                        'preference': preference,
                                      });
                                    }

                                    if (preference == 'thumbs_up') thumbsUp++;
                                    if (preference == 'thumbs_down')
                                      thumbsDown++;
                                  }

                                  final totalResponses = thumbsUp + thumbsDown;
                                  print(
                                      '🔍 PREFERENCE STREAM: Game ${game['id']}, Crew $userCrewId - Up: $thumbsUp, Down: $thumbsDown, Total: $totalResponses');

                                  if (totalResponses > 0) {
                                    return GestureDetector(
                                      onTap: () => _showCrewPreferenceDetails(
                                          context, game, docs),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.efficialsYellow
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: AppColors.efficialsYellow
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.thumb_up,
                                                size: 12,
                                                color: Colors.green[600]),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$thumbsUp',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(Icons.thumb_down,
                                                size: 12,
                                                color: Colors.red[600]),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$thumbsDown',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.info_outline,
                                              size: 10,
                                              color: AppColors.efficialsYellow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee: \$${game['gameFee'] ?? '0'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dismiss button (always available)
                    ElevatedButton(
                      onPressed: () => _dismissGame(game),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Dismiss',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button - only for crew chiefs or non-crew games
                    if (isCrewGame ? isUserCrewChief : true) ...[
                      ElevatedButton(
                        onPressed: () => isHireAutomatically
                            ? _claimGame(game)
                            : _showExpressInterestDialog(game),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHireAutomatically
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              isHireAutomatically ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          isHireAutomatically ? 'Claim' : 'Express Interest',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ] else if (isCrewGame && isUserCrewMember) ...[
                      // Thumbs up/down buttons for crew members
                      ElevatedButton.icon(
                        onPressed: () =>
                            _setCrewMemberPreference(game, 'thumbs_up'),
                        icon: const Icon(Icons.thumb_up, size: 16),
                        label:
                            const Text('Like', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _setCrewMemberPreference(game, 'thumbs_down'),
                        icon: const Icon(Icons.thumb_down, size: 16),
                        label: const Text('Dislike',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedGameCard(Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () => _viewGameDetails(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  game['sport'] ?? 'Sport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'CONFIRMED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[300],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatGameTitle(game),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game['scheduleName'] ?? 'Unnamed Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  game['location'] ?? 'TBD',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fee: \$${game['gameFee'] ?? '0'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Confirmed: Ready to officiate',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingGameCard(Map<String, dynamic> game,
      {bool isWaitingForCrewChief = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                game['sport'] ?? 'Sport',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isWaitingForCrewChief
                      ? AppColors.efficialsYellow.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isWaitingForCrewChief ? 'WAITING FOR CREW CHIEF' : 'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isWaitingForCrewChief
                        ? Colors.white
                        : Colors.orange[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatGameTitle(game),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            game['scheduleName'] ?? 'Unnamed Schedule',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                game['location'] ?? 'TBD',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee: \$${game['gameFee'] ?? '0'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    isWaitingForCrewChief
                        ? 'You indicated: ${game['member_preference'] == 'thumbs_up' ? 'Like' : 'Dislike'} - Waiting for crew chief'
                        : 'Applied: Pending scheduler response',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _withdrawInterest(game),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: const Text('Withdraw', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        // Mark notifications as read when notifications tab is selected
        if (index == 4) {
          // Notifications tab index
          _markNotificationsAsRead();
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.sports),
          label: 'Available',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.hourglass_empty),
          label: 'Pending',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: _buildNotificationIcon(),
          label: 'Notifications',
        ),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        const Icon(Icons.notifications),
        if (_unreadNotificationsCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadNotificationsCount > 99
                    ? '99+'
                    : _unreadNotificationsCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  String _getGreetingTime() {
    final now = DateTime.now();
    if (now.hour < 12) return 'morning';
    if (now.hour < 17) return 'afternoon';
    return 'evening';
  }

  String _formatGameDate(Map<String, dynamic> game) {
    if (game['date'] == null) return 'TBD';
    try {
      final date = DateTime.parse(game['date']);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      final dayName = days[date.weekday - 1];
      final monthName = months[date.month - 1];

      return '$dayName, $monthName ${date.day}';
    } catch (e) {
      return 'TBD';
    }
  }

  String _formatGameTime(Map<String, dynamic> game) {
    if (game['time'] == null) return 'TBD';
    try {
      final timeString = game['time'] as String;
      // Handle "H:MM" or "HH:MM" format (e.g., "9:00", "14:30")
      final parts = timeString.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format: $timeString');
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'TBD';
    }
  }

  String _formatGameTitle(Map<String, dynamic> game) {
    final opponent = game['opponent'] as String?;
    final scheduleHomeTeam = game['schedule_home_team_name'] as String?;
    final queryHomeTeam = game['home_team'] as String?;
    final camelCaseHomeTeam = game['homeTeam'] as String?;

    final homeTeam = (scheduleHomeTeam != null &&
            scheduleHomeTeam.trim().isNotEmpty)
        ? scheduleHomeTeam
        : (queryHomeTeam != null && queryHomeTeam.trim().isNotEmpty)
            ? queryHomeTeam
            : (camelCaseHomeTeam != null && camelCaseHomeTeam.trim().isNotEmpty)
                ? camelCaseHomeTeam
                : 'Home Team';

    if (opponent != null && homeTeam != null && homeTeam != 'Home Team') {
      return '$opponent @ $homeTeam';
    } else if (opponent != null) {
      return opponent;
    } else {
      return 'TBD';
    }
  }

  void _dismissGame(Map<String, dynamic> game) {
    final gameId = game['id'] as String?;

    setState(() {
      _availableGames.removeWhere((g) => g['id'] == game['id']);
      if (gameId != null && !_dismissedGameIds.contains(gameId)) {
        _dismissedGameIds.add(gameId);
        // Track recently dismissed game with full game data and timestamp
        final gameWithTimestamp = Map<String, dynamic>.from(game);
        gameWithTimestamp['_dismissedAt'] = DateTime.now();
        _recentlyDismissedGames[gameId] = gameWithTimestamp;
      }
    });

    // Save persistent data
    _savePersistentData();

    // Start undo timer - show undo option for 3 seconds
    _startUndoTimer(gameId);
  }

  void _startUndoTimer(String? gameId) {
    if (gameId == null) return;

    // Cancel any existing timers
    _undoTimer?.cancel();
    _countdownTimer?.cancel();

    // Start countdown timer to update UI every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Force rebuild to update countdown display
        });
      }
    });

    // Start main timer for 4 seconds
    _undoTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _recentlyDismissedGames.remove(gameId);
        });
        _countdownTimer?.cancel();
      }
    });
  }

  void _undoDismiss(String gameId) {
    // Cancel both timers since user clicked undo
    _undoTimer?.cancel();
    _countdownTimer?.cancel();

    // Check if game was recently dismissed
    final dismissedGame = _recentlyDismissedGames[gameId];
    if (dismissedGame == null) return;

    // Remove from dismissed list and add back to available (without timestamp)
    final gameToRestore = Map<String, dynamic>.from(dismissedGame);
    gameToRestore.remove('_dismissedAt'); // Remove our internal timestamp

    setState(() {
      _dismissedGameIds.remove(gameId);
      _availableGames.add(gameToRestore);
      _recentlyDismissedGames.remove(gameId);
    });

    // Save persistent data
    _savePersistentData();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game restored to Available list'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewGameDetails(Map<String, dynamic> game) async {
    final result = await Navigator.pushNamed(
      context,
      '/official-game-details',
      arguments: game,
    );

    // If the official backed out (result == true), refresh the data
    if (result == true) {
      // The backout has already completed, so just reload the data
      await _loadData();
    }
  }

  void _withdrawInterest(Map<String, dynamic> game) {
    _showWithdrawConfirmationDialog(game);
  }

  void _reshowGame(Map<String, dynamic> game) {
    final gameId = game['id'] as String?;
    if (gameId != null) {
      setState(() {
        _dismissedGameIds.remove(gameId);
        // Add the game back to available games if it's not already there
        if (!_availableGames.any((g) => g['id'] == gameId)) {
          _availableGames.add(game);
        }
      });

      // Save persistent data
      _savePersistentData();

      // Close the dialog since the game will no longer be in the dismissed list
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Game restored to Available list'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWithdrawConfirmationDialog(Map<String, dynamic> game) {
    bool alsoRemoveFromAvailable = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.undo,
                    color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Withdraw Interest',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to withdraw your interest in this game?',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Text(
                    _formatGameTitle(game),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(
                    'Also remove this game from my\nAvailable games list',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                  subtitle: Text(
                    'You won\'t see this game in Available games again',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  value: alsoRemoveFromAvailable,
                  onChanged: (bool? value) {
                    setState(() {
                      alsoRemoveFromAvailable = value ?? false;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmWithdrawInterest(game, alsoRemoveFromAvailable);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Withdraw Interest'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmWithdrawInterest(
      Map<String, dynamic> game, bool alsoRemoveFromAvailable) async {
    final gameId = game['id'] as String?;
    final currentUser = await _userService.getCurrentUser();
    final officialId = currentUser?.id;

    // Remove official from game's interested officials list if we have the required data
    if (gameId != null && officialId != null) {
      await _gameService.removeInterestedOfficial(gameId, officialId);
    }

    // Store the current state for undo functionality
    final wasInPending = _pendingGames.contains(game);
    final wasInAvailable = _availableGames.contains(game);

    // Remove from pending
    setState(() {
      _pendingGames.removeWhere((g) => g['id'] == game['id']);
    });

    // Handle the available games list based on user choice
    if (alsoRemoveFromAvailable) {
      // Add to dismissed list so it won't appear in available games again
      final gameId = game['id'] as String?;
      if (gameId != null && !_dismissedGameIds.contains(gameId)) {
        setState(() {
          _dismissedGameIds.add(gameId);
          // Also remove from available if it was there
          _availableGames.removeWhere((g) => g['id'] == gameId);
        });
      }
    } else {
      // Add back to available games if it wasn't already there
      if (!_availableGames.contains(game)) {
        setState(() {
          _availableGames.add(game);
        });
      }
    }

    // Save persistent data
    _savePersistentData();

    // Show undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alsoRemoveFromAvailable
              ? 'Interest withdrawn and game removed from Available list'
              : 'Interest withdrawn - game returned to Available list',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () => _undoWithdrawInterest(
              game, wasInPending, wasInAvailable, alsoRemoveFromAvailable),
        ),
      ),
    );
  }

  void _undoWithdrawInterest(Map<String, dynamic> game, bool wasInPending,
      bool wasInAvailable, bool wasRemovedFromAvailable) async {
    final gameId = game['id'] as String?;
    final currentUser = await _userService.getCurrentUser();

    // Add official back to game's interested officials list if undoing withdrawal
    if (gameId != null && currentUser != null) {
      final officialData = {
        'id': currentUser.id,
        'name': currentUser.fullName,
        'distance': 0.0,
      };
      await _gameService.addInterestedOfficial(gameId, officialData);
    }

    setState(() {
      // Restore pending status
      if (wasInPending && !_pendingGames.contains(game)) {
        _pendingGames.add(game);
      }

      // Restore available status based on original choice
      if (!wasRemovedFromAvailable) {
        // If user didn't want it removed, make sure it's back in available
        if (!wasInAvailable && !_availableGames.contains(game)) {
          _availableGames.add(game);
        }
      } else {
        // If user wanted it removed, undo that removal
        final gameId = game['id'] as String?;
        if (gameId != null) {
          _dismissedGameIds.remove(gameId);
          if (!wasInAvailable && !_availableGames.contains(game)) {
            _availableGames.add(game);
          }
        }
      }
    });

    // Save persistent data after undo
    _savePersistentData();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Withdrawal undone'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showExpressInterestDialog(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.sports,
                  color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Express Interest',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Express interest in this game?',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[300], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The scheduler will be notified of your interest and must confirm your assignment.',
                        style: TextStyle(color: Colors.blue[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _expressInterest(game);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Express Interest'),
            ),
          ],
        );
      },
    );
  }

  void _expressInterest(Map<String, dynamic> game) async {
    final gameId = game['id'] as String?;
    if (gameId == null) return;

    // Get current user data
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) return;

    // Prepare official data to add to game's interested officials
    final officialData = {
      'id': currentUser.id,
      'name': currentUser.fullName,
      'distance': 0.0, // Could calculate actual distance if needed
    };

    // Add official to game's interested officials list
    final success =
        await _gameService.addInterestedOfficial(gameId, officialData);

    if (success) {
      // Handle crew games differently
      final isCrewGame = game['selectedCrews'] != null &&
          (game['selectedCrews'] as List).isNotEmpty;

      setState(() {
        _availableGames.removeWhere((g) => g['id'] == game['id']);

        if (isCrewGame) {
          // For crew games, update any existing pending entries or add new one
          final existingIndices = _pendingGames
              .asMap()
              .entries
              .where((entry) => entry.value['id'] == game['id'])
              .map((entry) => entry.key)
              .toList();

          final gameWithStatus = {
            ...game,
            'pending_status':
                'waiting_for_scheduler', // Now waiting for scheduler
          };

          if (existingIndices.isNotEmpty) {
            // Update all existing entries for this game
            for (final index in existingIndices) {
              _pendingGames[index] = gameWithStatus;
            }
          } else {
            // Add new entry
            _pendingGames.add(gameWithStatus);
          }
        } else {
          // Regular games - just add to pending
          _pendingGames.add(game);
        }
      });

      // Save persistent data
      _savePersistentData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interest expressed in ${game['sport']} game'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to express interest. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _claimGame(Map<String, dynamic> game) async {
    final gameId = game['id'] as String?;
    if (gameId == null) return;

    // Get current user data
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) return;

    // Get additional user profile data
    final userDoc = await _userService.getUserById(currentUser.id);
    if (userDoc == null) return;

    // Prepare official data to add to game's confirmed officials
    final officialData = {
      'id': currentUser.id,
      'name': currentUser.fullName,
      'email': currentUser.email,
      'city': userDoc.officialProfile?.city ?? '',
      'state': userDoc.officialProfile?.state ?? '',
    };

    // Add official to game's confirmed officials list (automatic hire)
    final success =
        await _gameService.addConfirmedOfficial(gameId, officialData);

    if (success) {
      // Store the current state for undo functionality
      final wasInAvailable = _availableGames.contains(game);

      // Move game from available to confirmed
      setState(() {
        _availableGames.removeWhere((g) => g['id'] == game['id']);
        _confirmedGames.add(game);
      });

      // Add the game ID to the user's confirmed games list in Firestore
      if (!_confirmedGameIds.contains(gameId)) {
        _confirmedGameIds.add(gameId);
        // Update Firestore directly
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.id)
            .update({
          'confirmedGameIds': _confirmedGameIds,
          'updatedAt': Timestamp.now(),
        });
      }

      // Save persistent data
      _savePersistentData();

      // Show undo snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully claimed ${game['sport']} game!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () =>
                _undoClaimGame(game, wasInAvailable, currentUser.id),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to claim game. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _undoClaimGame(
      Map<String, dynamic> game, bool wasInAvailable, String userId) async {
    final gameId = game['id'] as String?;
    if (gameId == null) return;

    // Remove official from game's confirmed officials list
    final removeSuccess =
        await _gameService.removeConfirmedOfficial(gameId, userId);

    if (removeSuccess) {
      // Remove from confirmed games in UI
      setState(() {
        _confirmedGames.removeWhere((g) => g['id'] == game['id']);
      });

      // Remove the game ID from the user's confirmed games list
      if (_confirmedGameIds.contains(gameId)) {
        _confirmedGameIds.remove(gameId);
        // Update Firestore directly
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'confirmedGameIds': _confirmedGameIds,
          'updatedAt': Timestamp.now(),
        });
      }

      // Add back to available games if it was there before
      if (wasInAvailable && !_availableGames.contains(game)) {
        setState(() {
          _availableGames.add(game);
        });
      }

      // Save persistent data after undo
      _savePersistentData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Claim undone - ${game['sport']} game returned to Available'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to undo claim. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _claimLinkedGames(List<Map<String, dynamic>> linkedGames) async {
    if (linkedGames.isEmpty) return;

    // Get current user data
    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null) return;

    // Get additional user profile data
    final userDoc = await _userService.getUserById(currentUser.id);
    if (userDoc == null) return;

    // Prepare official data to add to game's confirmed officials
    final officialData = {
      'id': currentUser.id,
      'name': currentUser.fullName,
      'email': currentUser.email,
      'city': userDoc.officialProfile?.city ?? '',
      'state': userDoc.officialProfile?.state ?? '',
    };

    bool allSuccess = true;
    final List<String> failedGames = [];

    // Claim all games in the linked group
    for (final game in linkedGames) {
      final gameId = game['id'] as String?;
      if (gameId == null) continue;

      final success =
          await _gameService.addConfirmedOfficial(gameId, officialData);
      if (success) {
        // Move game from available to confirmed
        setState(() {
          _availableGames.removeWhere((g) => g['id'] == game['id']);
          _confirmedGames.add(game);
        });

        // Add the game ID to the user's confirmed games list in Firestore
        if (!_confirmedGameIds.contains(gameId)) {
          _confirmedGameIds.add(gameId);
        }
      } else {
        allSuccess = false;
        failedGames.add(game['sport'] ?? 'Unknown game');
      }
    }

    if (allSuccess) {
      // Update Firestore with all confirmed game IDs
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.id)
          .update({
        'confirmedGameIds': _confirmedGameIds,
        'updatedAt': Timestamp.now(),
      });

      // Save persistent data
      _savePersistentData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully claimed all ${linkedGames.length} linked games!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to claim some games: ${failedGames.join(', ')}. Please try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showClaimLinkedGamesDialog(List<Map<String, dynamic>> linkedGames) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      Icon(Icons.link,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Claim Linked Games',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are about to claim ${linkedGames.length} linked games:',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: linkedGames.length > 3
                            ? 200
                            : linkedGames.length * 100.0,
                        child: ListView.builder(
                          itemCount: linkedGames.length,
                          itemBuilder: (context, index) {
                            final game = linkedGames[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatGameTitle(game),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    game['scheduleName'] ?? 'Unknown Schedule',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatGameDate(game)} at ${_formatGameTime(game)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  Text(
                                    game['location'] ?? 'TBD',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          _claimLinkedGames(linkedGames);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Claim All Games'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Logout',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Sign out from Firebase Auth
                await FirebaseAuth.instance.signOut();

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Calendar helper methods
  Map<DateTime, List<Map<String, dynamic>>> _getGamesByDate() {
    final Map<DateTime, List<Map<String, dynamic>>> gamesByDate = {};

    // Add confirmed games
    for (final game in _confirmedGames) {
      final date = _parseGameDate(game);
      if (date != null) {
        final dateKey = DateTime(date.year, date.month, date.day);
        gamesByDate.putIfAbsent(dateKey, () => []);
        gamesByDate[dateKey]!.add({...game, 'type': 'confirmed'});
      }
    }

    // Add pending games
    for (final game in _pendingGames) {
      final date = _parseGameDate(game);
      if (date != null) {
        final dateKey = DateTime(date.year, date.month, date.day);
        gamesByDate.putIfAbsent(dateKey, () => []);
        // Only add if not already confirmed
        if (!gamesByDate[dateKey]!
            .any((g) => g['id'] == game['id'] && g['type'] == 'confirmed')) {
          gamesByDate[dateKey]!.add({...game, 'type': 'pending'});
        }
      }
    }

    // Add available games (only if no confirmed or pending for that date)
    for (final game in _availableGames) {
      final date = _parseGameDate(game);
      if (date != null) {
        final dateKey = DateTime(date.year, date.month, date.day);
        gamesByDate.putIfAbsent(dateKey, () => []);
        // Only add if not already confirmed or pending
        if (!gamesByDate[dateKey]!.any((g) =>
            g['id'] == game['id'] &&
            (g['type'] == 'confirmed' || g['type'] == 'pending'))) {
          gamesByDate[dateKey]!.add({...game, 'type': 'available'});
        }
      }
    }

    return gamesByDate;
  }

  DateTime? _parseGameDate(Map<String, dynamic> game) {
    if (game['date'] == null) return null;
    try {
      return DateTime.parse(game['date']);
    } catch (e) {
      return null;
    }
  }

  Color _getDateColor(
      DateTime date, Map<DateTime, List<Map<String, dynamic>>> gamesByDate) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final games = gamesByDate[dateKey];

    if (games == null || games.isEmpty) return Colors.transparent;

    // Priority: Confirmed (green) > Pending (orange) > Available (blue)
    // But only show colors for enabled legend items
    if (_showConfirmedGames &&
        games.any((game) => game['type'] == 'confirmed')) {
      return Colors.green;
    } else if (_showPendingGames &&
        games.any((game) => game['type'] == 'pending')) {
      return Colors.orange[300]!;
    } else if (_showAvailableGames &&
        games.any((game) => game['type'] == 'available')) {
      return Colors.blue[300]!;
    }

    return Colors.transparent;
  }

  String _getDateType(
      DateTime date, Map<DateTime, List<Map<String, dynamic>>> gamesByDate) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final games = gamesByDate[dateKey];

    if (games == null || games.isEmpty) return '';

    // Priority: Confirmed > Pending > Available
    if (games.any((game) => game['type'] == 'confirmed')) {
      return 'confirmed';
    } else if (games.any((game) => game['type'] == 'pending')) {
      return 'pending';
    } else if (games.any((game) => game['type'] == 'available')) {
      return 'available';
    }

    return '';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final gamesByDate = _getGamesByDate();
    final dateKey =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final gamesOnDate = gamesByDate[dateKey] ?? [];

    // Filter games based on enabled legend items
    final enabledGames = gamesOnDate.where((game) {
      switch (game['type']) {
        case 'confirmed':
          return _showConfirmedGames;
        case 'available':
          return _showAvailableGames;
        case 'pending':
          return _showPendingGames;
        default:
          return false;
      }
    }).toList();

    // Determine the primary action based on enabled game types
    String primaryType = '';
    if (enabledGames.any((game) => game['type'] == 'confirmed')) {
      primaryType = 'confirmed';
    } else if (enabledGames.any((game) => game['type'] == 'pending')) {
      primaryType = 'pending';
    } else if (enabledGames.any((game) => game['type'] == 'available')) {
      primaryType = 'available';
    }

    switch (primaryType) {
      case 'confirmed':
        // Show confirmed games as tiles at the bottom (only enabled ones)
        final confirmedGames =
            enabledGames.where((g) => g['type'] == 'confirmed').toList();
        setState(() {
          _selectedDayGames = confirmedGames;
        });
        break;
      case 'pending':
        // Navigate to pending games list
        setState(() {
          _selectedDayGames = [];
          _currentIndex = 2;
        });
        break;
      case 'available':
        // Navigate to available games list
        setState(() {
          _selectedDayGames = [];
          _currentIndex = 1;
        });
        break;
      default:
        // No enabled games on this date, clear selection
        setState(() {
          _selectedDayGames = [];
        });
        break;
    }
  }

  double _parseFee(dynamic feeValue) {
    if (feeValue == null) return 0.0;

    if (feeValue is double) return feeValue;
    if (feeValue is int) return feeValue.toDouble();
    if (feeValue is String) {
      try {
        return double.parse(feeValue);
      } catch (e) {
        return 0.0;
      }
    }

    return 0.0;
  }
}
