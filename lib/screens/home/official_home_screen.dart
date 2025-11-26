import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/theme_provider.dart';
import '../../services/user_service.dart';
import '../../services/game_service.dart';
import '../../services/official_list_service.dart';
import '../../models/user_model.dart';

class OfficialHomeScreen extends StatefulWidget {
  const OfficialHomeScreen({super.key});

  @override
  State<OfficialHomeScreen> createState() => _OfficialHomeScreenState();
}

class _OfficialHomeScreenState extends State<OfficialHomeScreen> {
  final UserService _userService = UserService();
  final GameService _gameService = GameService();
  final OfficialListService _listService = OfficialListService();

  int _currentIndex = 0;
  UserModel? _currentUser;
  List<Map<String, dynamic>> _availableGames = [];
  List<Map<String, dynamic>> _pendingGames = [];
  List<Map<String, dynamic>> _confirmedGames = []; // Track confirmed games
  List<String> _dismissedGameIds = []; // Track dismissed game IDs
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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

      // Load user's persistent game state from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;

        // Load dismissed game IDs
        final dismissedIds =
            List<String>.from(userData['dismissedGameIds'] ?? []);
        setState(() {
          _dismissedGameIds = dismissedIds;
        });

        // Load pending game IDs and match with actual games
        final pendingIds = List<String>.from(userData['pendingGameIds'] ?? []);
        await _loadPendingGamesFromIds(pendingIds);
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

      final pendingGamesRaw = allGames.where((game) {
        final gameId = game['id'] as String?;
        return gameId != null && pendingIds.contains(gameId);
      }).toList();

      // Add home team to games that don't have it
      final pendingGames = <Map<String, dynamic>>[];
      for (final game in pendingGamesRaw) {
        if (game['homeTeam'] == null) {
          final gameWithHomeTeam = await _addHomeTeamToGame(game);
          pendingGames.add(gameWithHomeTeam);
        } else {
          pendingGames.add(game);
        }
      }

      setState(() {
        _pendingGames = pendingGames;
      });
    } catch (e) {
      print('Error loading pending games from IDs: $e');
    }
  }

  Future<void> _savePersistentData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Prepare the data to save
      final pendingIds =
          _pendingGames.map((game) => game['id'] as String).toList();

      // Save to Firestore user document
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'dismissedGameIds': _dismissedGameIds,
        'pendingGameIds': pendingIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

      // Load real available games data
      await _loadAvailableGames();

      // Check for confirmed games and update pending/confirmed lists
      await _updateGameStatuses();
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

  Future<void> _updateGameStatuses() async {
    if (_currentUser?.id == null) return;

    final currentOfficialId = _currentUser!.id;
    final gamesToMove = <Map<String, dynamic>>[];

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
      });

      // Update persistent storage
      await _savePersistentData();
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

        // Check if this official is included in the game's selection criteria
        if (await _isOfficialIncludedInGameAsync(game, currentOfficialId)) {
          // Skip dismissed games and games that are already pending
          final gameId = game['id'] as String?;
          final pendingGameIds =
              _pendingGames.map((g) => g['id'] as String).toList();

          if (gameId != null &&
              !_dismissedGameIds.contains(gameId) &&
              !pendingGameIds.contains(gameId)) {
            // For games that don't have homeTeam set, try to derive it from the scheduler's profile
            if (game['homeTeam'] == null) {
              final gameWithHomeTeam = await _addHomeTeamToGame(game);
              filteredGames.add(gameWithHomeTeam);
            } else {
              filteredGames.add(game);
            }

            final loadedGame = game['homeTeam'] == null
                ? await _addHomeTeamToGame(game)
                : game;
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

      // Check if official is in selected lists
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
        }
      }

      // Check if official is in selected crews
      final selectedCrews = game['selectedCrews'] as List<dynamic>?;
      if (selectedCrews != null && selectedCrews.isNotEmpty) {
        // TODO: Implement crew membership checking when crew service is available
        // For now, crews are not implemented, so skip this check
      }

      // If no specific selection criteria, check if it's "hire automatically" method
      // In this case, all eligible officials should see the game
      final method = game['method'] as String?;
      if (method == 'hire_automatically') {
        return true;
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
      final listsQuery = await _listService.firestore
          .collection('official_lists')
          .where('name', isEqualTo: listName)
          .get();

      if (listsQuery.docs.isEmpty) {
        return false;
      }

      // Get the first matching list (should only be one with unique names)
      final listDoc = listsQuery.docs.first;
      final listData = listDoc.data();
      final officials = listData['officials'] as List<dynamic>?;

      if (officials == null) {
        return false;
      }

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
                Navigator.pushNamed(context, '/official-profile');
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
        return _buildProfileTab();
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
                            Icons.sports_basketball,
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
                      itemCount: _confirmedGames.length,
                      itemBuilder: (context, index) {
                        final game = _confirmedGames[index];
                        return _buildConfirmedGameCard(game);
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
          // Available Games List
          Expanded(
            child: _availableGames.isEmpty
                ? _buildEmptyState('No available games', Icons.sports)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _availableGames.length,
                    itemBuilder: (context, index) {
                      final game = _availableGames[index];
                      return _buildAvailableGameCard(game);
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _pendingGames.length,
                    itemBuilder: (context, index) {
                      final game = _pendingGames[index];
                      return _buildPendingGameCard(game);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Calendar View',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/official-profile'),
              child: const Text('Edit Profile'),
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
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AVAILABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[300],
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
                  ElevatedButton(
                    onPressed: () => _showExpressInterestDialog(game),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Express Interest',
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

  Widget _buildConfirmedGameCard(Map<String, dynamic> game) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    'Confirmed: Ready to officiate',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _viewGameDetails(game),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.2),
                  foregroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child:
                    const Text('View Details', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingGameCard(Map<String, dynamic> game) {
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
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[300],
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
                    'Applied: Pending response',
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
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports),
          label: 'Available',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.hourglass_empty),
          label: 'Pending',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
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
      }
    });

    // Save persistent data
    _savePersistentData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Game dismissed from Available list'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewGameDetails(Map<String, dynamic> game) {
    Navigator.pushNamed(
      context,
      '/game_information',
      arguments: game,
    );
  }

  void _withdrawInterest(Map<String, dynamic> game) {
    _showWithdrawConfirmationDialog(game);
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
                        'The scheduler will be notified of your interest.',
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
      // Move game from available to pending
      setState(() {
        _availableGames.removeWhere((g) => g['id'] == game['id']);
        _pendingGames.add(game);
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
}
