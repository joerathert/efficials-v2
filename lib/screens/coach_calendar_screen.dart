import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/scheduler_bottom_navigation.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';

class CoachCalendarScreen extends StatefulWidget {
  const CoachCalendarScreen({super.key});

  @override
  State<CoachCalendarScreen> createState() => _CoachCalendarScreenState();
}

class _CoachCalendarScreenState extends State<CoachCalendarScreen> {
  String? _teamName;
  String? _sport;
  String? _scheduleName;
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];
  bool _hasInitialized = false;
  final GameService _gameService = GameService();

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize from route arguments if we haven't already
    if (!_hasInitialized) {
      // Check for focusDate argument to focus calendar on specific date
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('focusDate')) {
        final focusDate = args['focusDate'] as DateTime?;
        if (focusDate != null) {
          _focusedDay = focusDate;
          _selectedDay = focusDate;
        }
      }

      _initializeCoachData();
      _hasInitialized = true;
    } else {
      // If already initialized, check if we have focusDate arguments (returning from game creation)
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('focusDate')) {
        final focusDate = args['focusDate'] as DateTime?;
        if (focusDate != null) {
          // Refresh games data since a new game may have been created
          _fetchGames().then((_) {
            if (mounted) {
              setState(() {
                _focusedDay = focusDate;
                _selectedDay = focusDate;
                _selectedDayGames = _getGamesForDay(focusDate);
              });
            }
          });
        }
      }
    }
  }

  Future<void> _initializeCoachData() async {
    try {
      // Get coach profile data from auth service
      final authService = AuthService();
      final userProfile = await authService.getCurrentUserProfile();
      final userData = userProfile?.toMap();

      if (userData != null && userData['schedulerProfile'] != null) {
        final profile = userData['schedulerProfile'] as Map<String, dynamic>;
        _teamName = profile['teamName'] as String?;
        _sport = profile['sport'] as String?;

        // For coaches, the schedule name is their team name
        _scheduleName = _teamName;

        debugPrint(
            '🏆 COACH CALENDAR: Initialized with team: $_teamName, sport: $_sport');

        // Load games for this schedule
        await _fetchGames();
      }
    } catch (e) {
      debugPrint('❌ COACH CALENDAR: Error initializing coach data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchGames() async {
    if (_scheduleName == null) return;

    try {
      debugPrint(
          '🔍 COACH CALENDAR: Fetching games for schedule: $_scheduleName');
      final scheduleGames =
          await _gameService.getGamesByScheduleName(_scheduleName!);

      debugPrint('✅ COACH CALENDAR: Retrieved ${scheduleGames.length} games');

      if (mounted) {
        setState(() {
          _games.clear();
          _games = scheduleGames;

          // Ensure DateTime and TimeOfDay objects are properly parsed
          for (var game in _games) {
            if (game['date'] != null && game['date'] is String) {
              game['date'] = DateTime.parse(game['date'] as String);
            }
            if (game['time'] != null && game['time'] is String) {
              final timeParts = (game['time'] as String).split(':');
              game['time'] = TimeOfDay(
                hour: int.parse(timeParts[0]),
                minute: int.parse(timeParts[1]),
              );
            }
          }

          if (_games.isNotEmpty) {
            _games.sort((a, b) =>
                (a['date'] as DateTime).compareTo(b['date'] as DateTime));

            // Find the next upcoming game (today or later)
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            DateTime? nextGameDate;
            for (var game in _games) {
              final gameDate = game['date'] as DateTime;
              final gameDateOnly =
                  DateTime(gameDate.year, gameDate.month, gameDate.day);
              if (gameDateOnly.isAtSameMomentAs(today) ||
                  gameDateOnly.isAfter(today)) {
                nextGameDate = gameDate;
                break;
              }
            }

            // Focus on the month containing the next upcoming game, or first game if all are past
            _focusedDay = nextGameDate ?? _games.first['date'] as DateTime;

            // Don't auto-select any date - let user manually select
            _selectedDay = null;
            _selectedDayGames = [];
          } else {
            _focusedDay = DateTime.now();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ COACH CALENDAR: Error loading games: $e');
      if (mounted) {
        setState(() {
          _games.clear();
          _focusedDay = DateTime.now();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getGamesForDay(DateTime day) {
    final matchingGames = _games.where((game) {
      final gameDate = game['date'] as DateTime?;
      if (gameDate == null) {
        return false;
      }
      return gameDate.year == day.year &&
          gameDate.month == day.month &&
          gameDate.day == day.day;
    }).toList();

    return matchingGames;
  }

  Future<void> _showGameTypeDialog(DateTime day) async {
    if (_scheduleName == null) return;

    final String? gameType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Add Game',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Add a game for ${day.month}/${day.day}/${day.year}?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('away'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_bus, size: 16),
                  const SizedBox(width: 4),
                  const Text('Away', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, size: 16),
                  const SizedBox(width: 4),
                  const Text('Home', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (gameType != null && mounted) {
      await _createGame(day, gameType == 'away');
    }
  }

  Future<void> _createGame(DateTime selectedDate, bool isAway) async {
    if (!mounted || _scheduleName == null) return;

    Map<String, dynamic> routeArgs = {
      'scheduleName': _scheduleName,
      'date': selectedDate,
      'fromScheduleDetails': true,
      'sport': _sport ?? 'Unknown',
      'isAwayGame': isAway,
      'isAway': isAway,
      'isCoachFlow': true, // Flag to indicate this is from coach flow
    };

    // Navigate directly to date-time screen for coach flow
    Navigator.pushNamed(
      context,
      '/date-time',
      arguments: routeArgs,
    ).then((_) {
      _fetchGames();
    });
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/coach-home',
          (route) => false,
        );
        break;
      case 1: // Calendar - already here
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Icon(
          Icons.sports,
          color: colorScheme.primary,
          size: 32,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colorScheme.onSurface),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Transform.translate(
                  offset: const Offset(0, -60),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Team header
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _teamName ?? 'Your Team',
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              if (_sport != null)
                                Text(
                                  _sport!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),

                        // Calendar section
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: CalendarFormat.month,
                          selectedDayPredicate: (day) {
                            return _selectedDay != null &&
                                day.year == _selectedDay!.year &&
                                day.month == _selectedDay!.month &&
                                day.day == _selectedDay!.day;
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              _selectedDayGames = _getGamesForDay(selectedDay);
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          eventLoader: (day) => _getGamesForDay(day),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.5),
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            selectedDecoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            selectedTextStyle: TextStyle(
                                fontSize: 16, color: colorScheme.onPrimary),
                            defaultTextStyle: TextStyle(
                                fontSize: 16, color: colorScheme.onSurface),
                            weekendTextStyle: TextStyle(
                                fontSize: 16, color: colorScheme.onSurface),
                            outsideTextStyle:
                                TextStyle(fontSize: 16, color: Colors.grey),
                            markersMaxCount: 0,
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                                fontSize: 14, color: colorScheme.onSurface),
                            weekendStyle: TextStyle(
                                fontSize: 14, color: colorScheme.onSurface),
                            dowTextFormatter: (date, locale) =>
                                date.weekday == 7
                                    ? 'Sun'
                                    : date.weekday == 1
                                        ? 'Mon'
                                        : date.weekday == 2
                                            ? 'Tue'
                                            : date.weekday == 3
                                                ? 'Wed'
                                                : date.weekday == 4
                                                    ? 'Thu'
                                                    : date.weekday == 5
                                                        ? 'Fri'
                                                        : 'Sat',
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface),
                            leftChevronIcon: Icon(Icons.chevron_left,
                                color: colorScheme.primary),
                            rightChevronIcon: Icon(Icons.chevron_right,
                                color: colorScheme.primary),
                            titleCentered: true,
                          ),
                          calendarBuilders: CalendarBuilders(
                            selectedBuilder: (context, day, focusedDay) {
                              final events = _getGamesForDay(day);
                              final hasEvents = events.isNotEmpty;

                              Color backgroundColor = colorScheme.primary;
                              Color textColor = colorScheme.onPrimary;

                              if (hasEvents) {
                                bool allAway = true;
                                bool allFullyHired = true;
                                bool needsOfficials = false;

                                for (var event in events) {
                                  final isEventAway =
                                      event['isAway'] as bool? ?? false;
                                  final hiredOfficials =
                                      event['officialsHired'] as int? ?? 0;
                                  final requiredOfficials = int.tryParse(
                                          event['officialsRequired']
                                                  ?.toString() ??
                                              '0') ??
                                      0;
                                  final isFullyHired =
                                      hiredOfficials >= requiredOfficials;

                                  if (!isEventAway) allAway = false;
                                  if (!isFullyHired) allFullyHired = false;
                                  if (!isEventAway && !isFullyHired) {
                                    needsOfficials = true;
                                  }
                                }

                                if (allAway) {
                                  backgroundColor = Colors.grey[300]!;
                                  textColor = Colors.black;
                                } else if (needsOfficials) {
                                  backgroundColor = Colors.red;
                                  textColor = Colors.white;
                                } else if (allFullyHired) {
                                  backgroundColor = Colors.green;
                                  textColor = Colors.white;
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.white, width: 3.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                            defaultBuilder: (context, day, focusedDay) {
                              final events = _getGamesForDay(day);
                              final hasEvents = events.isNotEmpty;

                              Color? backgroundColor;
                              Color textColor = colorScheme.onSurface;

                              if (hasEvents) {
                                bool allAway = true;
                                bool allFullyHired = true;
                                bool needsOfficials = false;

                                for (var event in events) {
                                  final isEventAway =
                                      event['isAway'] as bool? ?? false;
                                  final hiredOfficials =
                                      event['officialsHired'] as int? ?? 0;
                                  final requiredOfficials = int.tryParse(
                                          event['officialsRequired']
                                                  ?.toString() ??
                                              '0') ??
                                      0;
                                  final isFullyHired =
                                      hiredOfficials >= requiredOfficials;

                                  if (!isEventAway) allAway = false;
                                  if (!isFullyHired) allFullyHired = false;
                                  if (!isEventAway && !isFullyHired) {
                                    needsOfficials = true;
                                  }
                                }

                                if (allAway) {
                                  backgroundColor = Colors.grey[300];
                                  textColor = Colors.black;
                                } else if (needsOfficials) {
                                  backgroundColor = Colors.red;
                                  textColor = Colors.white;
                                } else if (allFullyHired) {
                                  backgroundColor = Colors.green;
                                  textColor = Colors.white;
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Legend
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12.0,
                            runSpacing: 4.0,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Away Game',
                                      style: TextStyle(
                                          color: colorScheme.onSurface)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Fully Hired',
                                      style: TextStyle(
                                          color: colorScheme.onSurface)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('Needs Officials',
                                      style: TextStyle(
                                          color: colorScheme.onSurface)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Game details section
                        if (_selectedDayGames.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _selectedDayGames.length,
                              padding: const EdgeInsets.only(bottom: 140),
                              itemBuilder: (context, index) {
                                final game = _selectedDayGames[index];
                                final gameTime = game['time'] != null
                                    ? (game['time'] as TimeOfDay)
                                        .format(context)
                                    : 'Not set';
                                final hiredOfficials =
                                    game['officialsHired'] as int? ?? 0;
                                final requiredOfficials = int.tryParse(
                                        game['officialsRequired']?.toString() ??
                                            '0') ??
                                    0;
                                final location =
                                    game['location'] as String? ?? 'Not set';
                                final opponent =
                                    game['opponent'] as String? ?? 'Not set';

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/game-information',
                                      arguments: {
                                        ...game,
                                        'sourceScreen': 'coach_calendar',
                                        'scheduleName': _scheduleName,
                                      },
                                    ).then((result) {
                                      if (result != null) {
                                        if (result is Map<String, dynamic> &&
                                            result['deleted'] == true) {
                                          _fetchGames();
                                        } else if (result == true ||
                                            (result is Map<String, dynamic> &&
                                                result.isNotEmpty)) {
                                          _fetchGames();
                                        }
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 16.0),
                                    child: Card(
                                      elevation: 2,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Time: $gameTime',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        colorScheme.onSurface)),
                                            const SizedBox(height: 4),
                                            if (hiredOfficials >=
                                                requiredOfficials)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '$hiredOfficials/$requiredOfficials officials confirmed',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.white),
                                                ),
                                              )
                                            else
                                              Text(
                                                  '$hiredOfficials/$requiredOfficials officials confirmed',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.red)),
                                            const SizedBox(height: 4),
                                            Text('Location: $location',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        colorScheme.onSurface)),
                                            const SizedBox(height: 4),
                                            Text('Opponent: $opponent',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        colorScheme.onSurface)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Add game button
          Positioned(
            bottom: 40,
            right: (MediaQuery.of(context).size.width -
                        (MediaQuery.of(context).size.width > 550
                            ? 550
                            : MediaQuery.of(context).size.width)) /
                    2 +
                20,
            child: FloatingActionButton(
              heroTag: 'addGame',
              onPressed: _selectedDay == null
                  ? null
                  : () async {
                      await _createGame(
                          _selectedDay!, false); // Default to home game
                    },
              backgroundColor:
                  _selectedDay == null ? Colors.grey[800] : colorScheme.primary,
              tooltip: 'Add Game',
              child: Icon(Icons.add, size: 30, color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SchedulerBottomNavigation(
        currentIndex: 1, // Calendar tab is selected
        onTap: _onBottomNavTap,
        schedulerType: SchedulerType.coach,
        unreadNotificationCount: 0,
      ),
    );
  }
}
