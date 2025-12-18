import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_colors.dart';
import '../../app_theme.dart';
import '../../services/user_repository.dart';
import '../../services/game_service.dart';
import '../../widgets/linked_games_list.dart';
import '../../widgets/scheduler_bottom_navigation.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  String? sport;
  String? teamName;
  bool isLoading = true;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _upcomingGames = [];
  List<Map<String, dynamic>> _gamesNeedingOfficials = [];
  bool _showUpcomingGames =
      true; // Toggle between upcoming and needing officials

  final UserRepository _userRepository = UserRepository();
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _initializeCoachHome();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh games when returning to this screen
    debugPrint('🏆 COACH HOME: didChangeDependencies called');
    final route = ModalRoute.of(context);
    debugPrint(
        '🏆 COACH HOME: Route isCurrent: ${route?.isCurrent}, route settings: ${route?.settings.name}');
    if (route?.isCurrent == true) {
      debugPrint('🏆 COACH HOME: Screen became current, refreshing games');
      _initializeCoachHome();
    }
  }

  @override
  void didUpdateWidget(covariant CoachHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Also refresh when widget is updated (e.g., after hot reload)
    debugPrint('🏆 COACH HOME: Widget updated, refreshing games');
    _initializeCoachHome();
  }

  Future<void> _initializeCoachHome() async {
    debugPrint('🏆 COACH HOME: _initializeCoachHome called');

    // Call sequentially for better debugging
    await _checkCoachSetup();
    debugPrint('🏆 COACH HOME: _checkCoachSetup completed');
    await _loadUpcomingGames();
    debugPrint('🏆 COACH HOME: _loadUpcomingGames completed');
    await _loadGamesNeedingOfficials();
    debugPrint('🏆 COACH HOME: _loadGamesNeedingOfficials completed');

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    debugPrint('🏆 COACH HOME: _initializeCoachHome completed');
  }

  Future<void> _checkCoachSetup() async {
    debugPrint('Checking coach setup from database');
    try {
      // Get current user directly from UserRepository
      final currentUser = await _userRepository.getCurrentUser();

      if (currentUser == null) {
        debugPrint('No current user found, redirecting to welcome');
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/welcome');
          });
        }
        return;
      }

      debugPrint(
          'Current user: ${currentUser.email}, role: ${currentUser.role}');

      // Extract team name and sport from scheduler profile
      if (currentUser.schedulerProfile != null) {
        teamName = currentUser.schedulerProfile!.teamName;
        sport = currentUser.schedulerProfile!.sport;
      }

      debugPrint('🏆 COACH HOME: Team: $teamName, Sport: $sport');
      debugPrint(
          '🏆 COACH HOME: Will search for games with scheduleName: $teamName');
    } catch (e) {
      debugPrint('Error checking coach setup: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/welcome');
        });
      }
    }
  }

  Future<void> _loadUpcomingGames() async {
    debugPrint('🏆 COACH HOME: _loadUpcomingGames called, teamName: $teamName');
    try {
      if (teamName == null) {
        debugPrint('🏆 COACH HOME: teamName is null, returning early');
        return;
      }

      debugPrint('🏆 COACH HOME: Loading upcoming games for team: $teamName');
      debugPrint('🏆 COACH HOME: About to call getGamesByScheduleName');
      final allGames = await _gameService.getGamesByScheduleName(teamName!);
      debugPrint(
          '🏆 COACH HOME: getGamesByScheduleName returned, allGames length: ${allGames.length}');

      // Parse dates to DateTime objects (handle both strings and Timestamps)
      for (var game in allGames) {
        if (game['date'] != null) {
          if (game['date'] is String) {
            game['date'] = DateTime.parse(game['date'] as String);
            debugPrint('🏆 COACH HOME: Parsed string date: ${game['date']}');
          } else if (game['date'] is Timestamp) {
            game['date'] = (game['date'] as Timestamp).toDate();
            debugPrint(
                '🏆 COACH HOME: Converted Timestamp to DateTime: ${game['date']}');
          }
        }
      }

      debugPrint(
          '🏆 COACH HOME: Retrieved ${allGames.length} total games for team $teamName');
      for (var game in allGames) {
        debugPrint(
            '🏆 COACH HOME: Game - ID: ${game['id']}, Date: ${game['date']} (type: ${game['date']?.runtimeType}), Status: ${game['status']}, Schedule: ${game['scheduleName']}');
      }

      final now = DateTime.now();
      final upcomingGames = allGames.where((game) {
        debugPrint(
            '🏆 COACH HOME: Evaluating game ${game['id']} for upcoming filter');
        if (game['date'] == null) {
          debugPrint(
              '🏆 COACH HOME: Game ${game['id']} has null date, excluding');
          return false;
        }
        try {
          final gameDate = game['date'] as DateTime;
          final isUpcoming = gameDate.isAfter(now) ||
              gameDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
          debugPrint(
              '🏆 COACH HOME: Game ${game['id']} date: $gameDate, now: $now, isUpcoming: $isUpcoming');
          if (isUpcoming) {
            debugPrint(
                '🏆 COACH HOME: Game ${game['id']} PASSED upcoming filter');
          } else {
            debugPrint(
                '🏆 COACH HOME: Game ${game['id']} FAILED upcoming filter');
          }
          return isUpcoming;
        } catch (e) {
          debugPrint(
              '🏆 COACH HOME: Error parsing date for game ${game['id']}: $e');
          return false;
        }
      }).toList();

      // Sort by date
      upcomingGames.sort((a, b) {
        try {
          // Ensure dates are DateTime objects
          DateTime aDate = a['date'] as DateTime;
          DateTime bDate = b['date'] as DateTime;
          return aDate.compareTo(bDate);
        } catch (e) {
          debugPrint('🏆 COACH HOME: Error sorting games by date: $e');
          return 0;
        }
      });

      if (mounted) {
        setState(() {
          _upcomingGames = upcomingGames;
        });
        debugPrint(
            '🏆 COACH HOME: Set state with ${_upcomingGames.length} upcoming games');
        debugPrint(
            '🏆 COACH HOME: Game IDs: ${_upcomingGames.map((g) => g['id']).toList()}');
      }
      debugPrint(
          '🏆 COACH HOME: Loaded ${_upcomingGames.length} upcoming games');
    } catch (e) {
      debugPrint('🏆 COACH HOME: Error loading upcoming games: $e');
    }
  }

  Future<void> _loadGamesNeedingOfficials() async {
    try {
      if (teamName == null) return;

      debugPrint(
          '🏆 COACH HOME: Loading games needing officials for team: $teamName');
      final allGames = await _gameService.getGamesByScheduleName(teamName!);

      final gamesNeedingOfficials = <Map<String, dynamic>>[];

      for (final game in allGames) {
        debugPrint(
            '🏆 COACH HOME: Checking game ${game['id']}: status=${game['status']}');

        final officialsHired = game['officialsHired'] as int? ?? 0;
        final officialsRequired = game['officialsRequired'] as int? ?? 0;
        final needsOfficials = officialsHired < officialsRequired;

        if (needsOfficials) {
          gamesNeedingOfficials.add(game);
        }
      }

      // Sort by date
      gamesNeedingOfficials.sort((a, b) {
        try {
          final aDateValue = a['date'];
          final bDateValue = b['date'];
          final aDate = aDateValue is DateTime
              ? aDateValue
              : DateTime.parse(aDateValue.toString());
          final bDate = bDateValue is DateTime
              ? bDateValue
              : DateTime.parse(bDateValue.toString());
          return aDate.compareTo(bDate);
        } catch (e) {
          return 0;
        }
      });

      if (mounted) {
        setState(() {
          _gamesNeedingOfficials = gamesNeedingOfficials;
        });
      }
      debugPrint(
          '🏆 COACH HOME: Loaded ${_gamesNeedingOfficials.length} games needing officials');
    } catch (e) {
      debugPrint('🏆 COACH HOME: Error loading games needing officials: $e');
    }
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0: // Home - already on home screen
        break;
      case 1: // Calendar
        Navigator.pushNamed(context, '/coach-calendar');
        break;
      case 2: // Officials
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Officials screen coming soon')),
        );
        break;
      case 3: // Locations
        Navigator.pushNamed(context, '/choose_location');
        break;
      case 4: // Notifications
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications screen coming soon')),
        );
        break;
    }
  }

  void _navigateToGame(Map<String, dynamic> game) {
    Navigator.pushNamed(
      context,
      '/game-information',
      arguments: {
        'id': game['id'],
        'sport': game['sport'],
        'scheduleName': game['scheduleName'] ?? teamName ?? '',
        'opponent': game['opponent'],
        'date': game['date'],
        'time': game['time'],
        'location': game['location'],
        'levelOfCompetition': game['levelOfCompetition'] ?? '',
        'gender': game['gender'] ?? '',
        'officialsRequired': game['officialsRequired'],
        'officialsHired': game['officialsHired'],
        'gameFee': game['gameFee']?.toString() ?? 'Not set',
        'hireAutomatically': game['hireAutomatically'] ?? false,
        'isAway': game['isAway'],
        'method': game['method'],
        'selectedListName': game['selectedListName'],
        'selectedLists': game['selectedLists'],
        'selectedCrews': game['selectedCrews'],
        'selectedCrew': game['selectedCrew'],
        'selectedOfficials': game['selectedOfficials'],
        'sourceScreen': 'coach_home',
      },
    ).then((result) {
      // Refresh games when returning from game information screen
      if (result == true || result != null) {
        _loadUpcomingGames();
        _loadGamesNeedingOfficials();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🏆 COACH HOME: Building widget, isLoading: $isLoading, upcomingGames length: ${_upcomingGames.length}');
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.efficialsYellow)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text('', style: appBarTextStyle),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.efficialsYellow),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppColors.efficialsYellow,
            ),
            onPressed: () async {
              debugPrint('🏆 COACH HOME: Manual refresh triggered');
              setState(() {
                isLoading = true;
              });
              await _initializeCoachHome();
              debugPrint('🏆 COACH HOME: Manual refresh completed');
            },
            tooltip: 'Refresh Games',
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.efficialsYellow,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[800],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: const BoxDecoration(color: AppColors.efficialsBlack),
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8.0,
                    bottom: 8.0,
                    left: 16.0,
                    right: 16.0),
                child: const Text(
                  'Menu',
                  style: TextStyle(
                      color: AppColors.efficialsWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month,
                  color: AppColors.efficialsYellow),
              title: const Text('Calendar View',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/coach-calendar');
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.settings, color: AppColors.efficialsYellow),
              title:
                  const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.efficialsYellow,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getSportIcon(sport ?? ''),
                          color: AppColors.efficialsBlack,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teamName ?? 'Your Team',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.efficialsBlack,
                                ),
                              ),
                              Text(
                                '${sport ?? 'Unknown'} Team',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.efficialsBlack,
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

              const SizedBox(height: 20),

              // Toggle Buttons for Game Lists
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showUpcomingGames = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showUpcomingGames
                              ? AppColors.efficialsYellow
                              : Colors.grey[700],
                          foregroundColor: _showUpcomingGames
                              ? AppColors.efficialsBlack
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Upcoming Games (${_upcomingGames.length})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showUpcomingGames = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_showUpcomingGames
                              ? AppColors.efficialsYellow
                              : Colors.grey[700],
                          foregroundColor: !_showUpcomingGames
                              ? AppColors.efficialsBlack
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Needs Officials (${_gamesNeedingOfficials.length})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Games List Section
              if (_showUpcomingGames)
                _buildUpcomingGamesSection()
              else
                _buildGamesNeedingOfficialsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SchedulerBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        schedulerType: SchedulerType.coach,
        unreadNotificationCount: 0, // TODO: Implement notifications
      ),
    );
  }

  Widget _buildUpcomingGamesSection() {
    if (_upcomingGames.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.efficialsYellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.efficialsYellow.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.efficialsYellow,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Upcoming Games',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.efficialsYellow,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your upcoming games will appear here. Add games using the calendar view.',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/coach-calendar');
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Go to Calendar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.efficialsYellow,
                foregroundColor: AppColors.efficialsBlack,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Games',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            debugPrint(
                '🏆 COACH HOME: Building LinkedGamesList with ${_upcomingGames.length} games');
            return LinkedGamesList(
              games: _upcomingGames,
              onGameTap: _navigateToGame,
              emptyMessage: 'No upcoming games',
              emptyIcon: Icons.calendar_today,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGamesNeedingOfficialsSection() {
    if (_gamesNeedingOfficials.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'All Games Covered!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All your games have the necessary number of officials confirmed.',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Games Needing Officials',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        LinkedGamesList(
          games: _gamesNeedingOfficials,
          onGameTap: _navigateToGame,
          emptyMessage: 'No games needing officials',
          emptyIcon: Icons.check_circle,
        ),
      ],
    );
  }
}
