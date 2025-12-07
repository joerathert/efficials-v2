import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../app_theme.dart';
import '../../services/user_repository.dart';
import '../../services/game_service.dart';
import '../../widgets/linked_games_list.dart';
import '../../widgets/scheduler_bottom_navigation.dart';

class AssignerHomeScreen extends StatefulWidget {
  const AssignerHomeScreen({super.key});

  @override
  State<AssignerHomeScreen> createState() => _AssignerHomeScreenState();
}

class _AssignerHomeScreenState extends State<AssignerHomeScreen>
    with TickerProviderStateMixin {
  String? sport;
  String? leagueName;
  bool isLoading = true;
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  int _unpublishedGamesCount = 0;
  int _pendingBackoutCount = 0; // Count of pending backout notifications
  List<Map<String, dynamic>> _gamesNeedingOfficials = [];

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  final UserRepository _userRepository = UserRepository();
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _initializeAssignerHome();
  }

  Future<void> _initializeAssignerHome() async {
    await Future.wait([
      _checkAssignerSetup(),
      _loadUnreadNotificationCount(),
      _loadUnpublishedGamesCount(),
      _loadGamesNeedingOfficials(),
      _loadPendingBackoutCount(),
    ]);
  }

  Future<void> _loadPendingBackoutCount() async {
    try {
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser == null) {
        if (mounted) setState(() => _pendingBackoutCount = 0);
        return;
      }

      final backouts = await _gameService.getPendingBackouts(currentUser.id);
      if (mounted) {
        setState(() {
          _pendingBackoutCount = backouts.length;
        });
      }
      debugPrint('🔔 ASSIGNER HOME: Loaded $_pendingBackoutCount pending backouts');
    } catch (e) {
      debugPrint('🔴 ASSIGNER HOME: Error loading pending backouts: $e');
      if (mounted) {
        setState(() => _pendingBackoutCount = 0);
      }
    }
  }

  Future<void> _checkAssignerSetup() async {
    debugPrint('Checking assigner setup from database');
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

      // Extract sport and league name from scheduler profile
      if (currentUser.schedulerProfile != null) {
        sport = currentUser.schedulerProfile!.sport;
        leagueName = currentUser.schedulerProfile!.organizationName ?? 'Organization';
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking assigner setup: $e');
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


  Future<void> _loadUnreadNotificationCount() async {
    try {
      // For now, set to 0 as we don't have notification service implemented yet
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread notification count: $e');
    }
  }

  Future<void> _loadUnpublishedGamesCount() async {
    try {
      final unpublishedGames = await _gameService.getUnpublishedGames();
      if (mounted) {
        setState(() {
          _unpublishedGamesCount = unpublishedGames.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading unpublished games count: $e');
    }
  }

  Future<void> _loadGamesNeedingOfficials() async {
    try {
      final games = await _gameService.getPublishedGames();

      final gamesNeedingOfficials = <Map<String, dynamic>>[];

      for (final game in games) {
        final officialsHired = game['officialsHired'] as int? ?? 0;
        final officialsRequired = game['officialsRequired'] as int? ?? 0;
        final needsOfficials = officialsHired < officialsRequired;
        final hasDate = game['date'] != null;
        final hasValidSchedule = game['scheduleId'] != null && game['scheduleId'].toString().isNotEmpty;

        // Parse date properly - it comes from Firestore as a string
        DateTime? gameDate;
        if (hasDate) {
          try {
            final dateValue = game['date'];
            gameDate = dateValue is DateTime ? dateValue : DateTime.parse(dateValue.toString());
          } catch (e) {
            debugPrint('🏠 ERROR parsing game date: $e');
            gameDate = null;
          }
        }

        final isFuture = gameDate != null && gameDate.isAfter(DateTime.now());

        // Only include games that have a valid schedule that still exists
        if (needsOfficials && hasDate && isFuture && hasValidSchedule) {
          try {
            final schedule = await _gameService.getSchedule(game['scheduleId']);
            if (schedule != null) {
              gamesNeedingOfficials.add(game); // Only include if schedule exists
            }
          } catch (e) {
            debugPrint('🏠 ERROR validating schedule for game ${game['id']}: $e');
            // Exclude games where we can't validate the schedule
          }
        }
      }

      gamesNeedingOfficials.sort((a, b) {
        try {
          final aDateValue = a['date'];
          final bDateValue = b['date'];
          final aDate = aDateValue is DateTime ? aDateValue : DateTime.parse(aDateValue.toString());
          final bDate = bDateValue is DateTime ? bDateValue : DateTime.parse(bDateValue.toString());
          return aDate.compareTo(bDate);
        } catch (e) {
          debugPrint('🏠 ERROR sorting games by date: $e');
          return 0;
        }
      });

      if (mounted) {
        setState(() {
          _gamesNeedingOfficials = gamesNeedingOfficials;
        });
      }
    } catch (e) {
      debugPrint('🏠 ERROR in _loadGamesNeedingOfficials: $e');
    }
  }

  void _toggleExpandedView() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _navigateToFullScheduleView() {
    Navigator.pushNamed(context, '/assigner_manage_schedules');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0: // Home - already on home screen, do nothing
        break;
      case 1: // Schedules
        Navigator.pushNamed(context, '/assigner_manage_schedules').then((_) {
          // Refresh games needing officials when returning from schedules
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
      case 2: // Officials/Crews Choice
        Navigator.pushNamed(context, '/select_officials').then((_) {
          // Refresh games needing officials when returning from choice screen
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
      case 3: // Templates (Game Templates)
        Navigator.pushNamed(context, '/game-templates').then((_) {
          // Refresh games needing officials when returning from templates screen
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
      case 4: // Notifications
        Navigator.pushNamed(context, '/notifications').then((_) {
          // Refresh notification count and games when returning from notifications screen
          _loadUnreadNotificationCount();
          _loadUnpublishedGamesCount();
          _loadGamesNeedingOfficials();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.efficialsYellow)),
      );
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;
    final double totalBannerHeight = statusBarHeight + appBarHeight;

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
          // Notification bell icon with badge for backout notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.efficialsYellow,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications')
                      .then((_) {
                    // Refresh the backout count when returning
                    _loadPendingBackoutCount();
                  });
                },
                tooltip: 'Notifications',
              ),
              if (_pendingBackoutCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _pendingBackoutCount > 9
                          ? '9+'
                          : _pendingBackoutCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
              height: totalBannerHeight,
              decoration: const BoxDecoration(color: AppColors.efficialsBlack),
              child: Padding(
                padding: EdgeInsets.only(
                    top: statusBarHeight + 8.0,
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
              leading: const Icon(Icons.sports, color: AppColors.efficialsYellow),
              title: const Text('Officials Assignment',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Officials Assignment not implemented yet')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.efficialsYellow),
              title: const Text('Manage Schedules',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/assigner_manage_schedules')
                    .then((_) {
                  _loadUnpublishedGamesCount();
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.unpublished, color: AppColors.efficialsYellow),
              title: Row(
                children: [
                  const Text('Unpublished Games',
                      style: TextStyle(color: Colors.white)),
                  if (_unpublishedGamesCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_unpublishedGamesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/unpublished-games').then((_) {
                  _loadUnpublishedGamesCount(); // Refresh count after returning
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: Stack(
                children: [
                  const Icon(Icons.notification_important, color: AppColors.efficialsYellow),
                  if (_pendingBackoutCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          _pendingBackoutCount > 9
                              ? '9+'
                              : _pendingBackoutCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('Notifications',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notifications').then((_) {
                  _loadPendingBackoutCount(); // Refresh count after returning
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: AppColors.efficialsYellow),
              title: const Text('Manage Officials',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/select_officials').then((_) {
                  _loadUnpublishedGamesCount();
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.efficialsYellow),
              title: const Text('Game Templates',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/game-templates').then((_) {
                  _loadUnpublishedGamesCount();
                  _loadGamesNeedingOfficials();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.efficialsYellow),
              title: const Text('Manage Locations',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/choose_location');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.efficialsYellow),
              title: const Text('Settings',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: AppColors.efficialsYellow),
              title: const Text('Game Defaults',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/game_defaults');
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.efficialsYellow),
              title: const Text('Bulk Import Games',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/bulk_import');
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            // Detect upward swipe
            if (details.delta.dy < -2 && !_isExpanded) {
              _toggleExpandedView();
            }
            // Detect downward swipe when expanded
            else if (details.delta.dy > 2 && _isExpanded) {
              _toggleExpandedView();
            }
          },
          onTap: () {
            if (_isExpanded) {
              _navigateToFullScheduleView();
            }
          },
          child: AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Main home content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Transform.translate(
                      offset: Offset(
                          0,
                          -MediaQuery.of(context).size.height *
                              0.4 *
                              _slideAnimation.value),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // League Info Card
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  leagueName ?? 'Organization',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.efficialsBlack,
                                                  ),
                                                ),
                                                Text(
                                                  '${sport ?? 'Unknown'} Assigner',
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
                              ),

                              // Spacing after Assigner tile
                              const SizedBox(height: 20),

                              // Games Needing Officials Section
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildGamesNeedingOfficialsSection(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlay hint for expanded state
                  if (_isExpanded)
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.efficialsYellow.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to open full schedule view',
                            style: TextStyle(
                              color: AppColors.efficialsBlack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SchedulerBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        schedulerType: SchedulerType.assigner,
        unreadNotificationCount: _unreadNotificationCount,
      ),
    );
  }

  Widget _buildGamesNeedingOfficialsSection() {
    debugPrint('🏠 _buildGamesNeedingOfficialsSection called with ${_gamesNeedingOfficials.length} games');
    if (_gamesNeedingOfficials.isEmpty) {
      debugPrint('🏠 Games list is empty, showing empty state');
      // Check if there are any schedules at all
      final hasAnySchedules = _gameService.getSchedules().then((schedules) {
        return schedules.isNotEmpty;
      }).catchError((_) => false);

      // Check if there are any games at all (published or unpublished, past or future)
      final hasAnyGamesAtAll = Future.wait([
        _gameService.getPublishedGames(),
        _gameService.getUnpublishedGames(),
      ]).then((results) {
        final publishedGames = results[0];
        final unpublishedGames = results[1];
        return publishedGames.isNotEmpty || unpublishedGames.isNotEmpty;
      }).catchError((_) => false);

      // Check if there are any upcoming games (published or unpublished)
      final now = DateTime.now();
      final hasAnyUpcomingGames = Future.wait([
        _gameService.getPublishedGames(),
        _gameService.getUnpublishedGames(),
      ]).then((results) {
        final publishedGames = results[0];
        final unpublishedGames = results[1];
        final allGames = [...publishedGames, ...unpublishedGames];

        return allGames.any((game) {
          if (game['date'] == null) return false;
          try {
            final dateValue = game['date'];
            final gameDate = dateValue is DateTime ? dateValue : DateTime.parse(dateValue.toString());
            return gameDate.isAfter(now);
          } catch (e) {
            debugPrint('🏠 ERROR parsing date in empty state check: $e');
            return false;
          }
        });
      }).catchError((_) => false);

      // Also check for unpublished games
      final hasUnpublishedGames = _gameService.getUnpublishedGames().then((games) {
        return games.isNotEmpty;
      }).catchError((_) => false);

      return FutureBuilder<List<bool>>(
        future: Future.wait([hasAnySchedules, hasAnyGamesAtAll, hasAnyUpcomingGames, hasUnpublishedGames]),
        builder: (context, snapshot) {
          // Show loading state while waiting for all futures to complete
          if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
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
              child: const Column(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.efficialsYellow,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.efficialsYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final results = snapshot.data!;
          final hasSchedules = results[0];
          final hasAnyGames = results[1];
          final hasUpcomingGames = results[2];
          final hasUnpublished = results[3];

          // If no schedules exist at all, show welcome message for creating first schedule
          if (!hasSchedules) {
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
                    Icons.sports,
                    color: AppColors.efficialsYellow,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome to Efficials!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.efficialsYellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get started by creating your first team schedule. Build schedules to organize your games and assign officials.',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/assigner_manage_schedules');
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Create Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.efficialsYellow,
                      foregroundColor: AppColors.efficialsBlack,
                    ),
                  ),
                ],
              ),
            );
          }

          // If schedules exist but no games, show message about adding first game
          if (!hasAnyGames) {
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
                    Icons.add_circle_outline,
                    color: AppColors.efficialsYellow,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add Your First Game',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.efficialsYellow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have a schedule created, but no games added yet. Go to your schedule to add your first game and start hiring officials.',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/assigner_manage_schedules');
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Go to Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.efficialsYellow,
                      foregroundColor: AppColors.efficialsBlack,
                    ),
                  ),
                ],
              ),
            );
          }

          // If games exist but none are upcoming, show message about past games
          if (!hasUpcomingGames) {
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
                    Icons.history,
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
                    'All your games have passed. Create new games to continue hiring officials.',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/game_templates');
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create New Game'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.efficialsYellow,
                      foregroundColor: AppColors.efficialsBlack,
                    ),
                  ),
                ],
              ),
            );
          }

          // If there are upcoming games, show the appropriate message
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: hasUpcomingGames && !hasUnpublished
                  ? Colors.green.withOpacity(0.1)
                  : AppColors.efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: hasUpcomingGames && !hasUnpublished
                      ? Colors.green.withOpacity(0.3)
                      : AppColors.efficialsYellow.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  hasUpcomingGames && !hasUnpublished ? Icons.check_circle : Icons.calendar_today,
                  color: hasUpcomingGames && !hasUnpublished ? Colors.green : AppColors.efficialsYellow,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  hasUnpublished
                      ? 'Games Ready to Publish'
                      : hasUpcomingGames
                          ? 'All Games Covered!'
                          : 'No Upcoming Games',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: hasUnpublished
                        ? AppColors.efficialsYellow
                        : hasUpcomingGames
                            ? Colors.green
                            : AppColors.efficialsYellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasUnpublished
                      ? 'You have unpublished games that need to be published before officials can be assigned.'
                      : hasUpcomingGames
                          ? 'All upcoming games have the necessary number of officials confirmed.'
                          : 'You have no games scheduled for future dates.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasUnpublished) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/unpublished-games').then((_) {
                        _loadUnpublishedGamesCount();
                        _loadGamesNeedingOfficials();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.efficialsYellow,
                      foregroundColor: AppColors.efficialsBlack,
                    ),
                    child: const Text('View Unpublished Games'),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    debugPrint('🏠 Games list is NOT empty, showing ${_gamesNeedingOfficials.length} games');
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
        SizedBox(
          height: 600, // Set a fixed height for the LinkedGamesList
          child: LinkedGamesList(
            games: _gamesNeedingOfficials,
            onGameTap: _navigateToGame,
            emptyMessage: 'No games needing officials',
            emptyIcon: Icons.check_circle,
          ),
        ),
      ],
    );
  }

  void _navigateToGame(Map<String, dynamic> game) {
    Navigator.pushNamed(
      context,
      '/game-information',
      arguments: {
        'id': game['id'],
        'sport': game['sport'],
        'scheduleName': game['scheduleName'] ?? '',
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
        'sourceScreen': 'assigner_home',
      },
    ).then((result) {
      // Refresh games list when returning from game information screen
      // This handles cases where a game was deleted or modified
      if (result == true || result != null) {
        _loadUnpublishedGamesCount();
        _loadGamesNeedingOfficials();
      }
    });
  }


  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text(
            'Logout',
            style: TextStyle(color: primaryTextColor),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: primaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Clear user session (simplified for now)
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  ); // Go to welcome screen and clear navigation stack
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
