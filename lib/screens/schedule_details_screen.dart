import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/user_model.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';

class ScheduleDetailsScreen extends StatefulWidget {
  const ScheduleDetailsScreen({super.key});

  @override
  State<ScheduleDetailsScreen> createState() => _ScheduleDetailsScreenState();
}

class _ScheduleDetailsScreenState extends State<ScheduleDetailsScreen> {
  String? scheduleName;
  int? scheduleId;
  String? sport; // Store the schedule's sport
  List<Map<String, dynamic>> games = [];
  bool isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];
  bool _hasInitialized = false; // Track if we've initialized from route args
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
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      scheduleName = args['scheduleName'] as String?;
      scheduleId = args['scheduleId'] as int?;

      // If scheduleId is null but we have a scheduleName, try to look it up
      if (scheduleId == null && scheduleName != null) {
        _lookupScheduleId();
      }

      _hasInitialized = true;
    } else {}

    // Run async operations concurrently for better performance
    _initializeScheduleData();
  }

  Future<void> _initializeScheduleData() async {
    // Run independent operations concurrently for better performance
    final futures = <Future<void>>[
      _fetchGames(),
    ];

    await Future.wait(futures);

    // Load schedule details after games are loaded (depends on games data)
    await _loadScheduleDetails();
  }

  Future<void> _lookupScheduleId() async {
    if (scheduleName == null) return;

    try {
      // Mock implementation - in a real app, this would query a schedule service
      // For now, we'll just set a default schedule ID
      scheduleId = 1; // Mock ID
      debugPrint('SCHEDULE SCREEN: Using mock scheduleId: $scheduleId');
    } catch (e) {
      debugPrint('SCHEDULE SCREEN: Error looking up scheduleId: $e');
    }
  }

  Future<void> _loadScheduleDetails() async {
    if (scheduleId != null) {
      try {
        // Mock implementation - in a real app, this would query the database
        final scheduleDetails = {
          'sport': sport ?? 'Unknown',
        };

        final scheduleSport = scheduleDetails['sport'] as String?;

        // If schedule sport is null or empty, try to infer it from games
        if (scheduleSport == null ||
            scheduleSport.isEmpty ||
            scheduleSport == 'null') {
          await _inferAndUpdateScheduleSport();
        } else {
          if (mounted) {
            setState(() {
              sport = scheduleSport;
            });
          }
        }
      } catch (e) {
        // If database fails, sport will remain null and fall back to old method
        debugPrint('Failed to load schedule details: $e');
      }
    }
  }

  Future<void> _inferAndUpdateScheduleSport() async {
    // Try to infer sport from existing games
    String? inferredSport;
    if (games.isNotEmpty) {
      inferredSport = games.first['sport'] as String?;
    }

    // If we still don't have a sport, try to guess from schedule name
    if (inferredSport == null || inferredSport.isEmpty) {
      inferredSport = _inferSportFromScheduleName(scheduleName ?? '');
    }

    if (inferredSport.isNotEmpty && inferredSport != 'Unknown') {
      try {
        // Update the schedule in the database with the inferred sport
        // This is a simplified approach - you might want to implement updateScheduleSport in ScheduleService
        if (mounted) {
          setState(() {
            sport = inferredSport;
          });
        }
      } catch (e) {
        debugPrint('Failed to update schedule sport: $e');
      }
    } else {
      if (mounted) {
        setState(() {
          sport = 'Unknown';
        });
      }
    }
  }

  String _inferSportFromScheduleName(String scheduleName) {
    final name = scheduleName.toLowerCase();
    if (name.contains('football')) return 'Football';
    if (name.contains('basketball')) return 'Basketball';
    if (name.contains('baseball')) return 'Baseball';
    if (name.contains('soccer')) return 'Soccer';
    if (name.contains('tennis')) return 'Tennis';
    if (name.contains('volleyball')) return 'Volleyball';
    if (name.contains('track')) return 'Track';
    if (name.contains('swim')) return 'Swimming';
    if (name.contains('golf')) return 'Golf';
    if (name.contains('wrestling')) return 'Wrestling';
    if (name.contains('cross country')) return 'Cross Country';
    return 'Unknown';
  }

  Future<void> _fetchGames() async {
    try {
      // Use GameService exclusively to get games for this schedule
      final scheduleGames = scheduleName != null
          ? await _gameService.getGamesByScheduleName(scheduleName!)
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          games.clear();
          games = scheduleGames;

          // Ensure DateTime and TimeOfDay objects are properly parsed
          for (var game in games) {
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

          if (games.isNotEmpty) {
            games.sort((a, b) =>
                (a['date'] as DateTime).compareTo(b['date'] as DateTime));

            // Find the next upcoming game (today or later)
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            DateTime? nextGameDate;
            for (var game in games) {
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
            _focusedDay = nextGameDate ?? games.first['date'] as DateTime;

            // Don't auto-select any date - let user manually select
            _selectedDay = null;
            _selectedDayGames = [];
          } else {
            _focusedDay = DateTime.now();
          }

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading games from database: $e');
      if (mounted) {
        setState(() {
          games.clear();
          _focusedDay = DateTime.now();
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getGamesForDay(DateTime day) {
    return games.where((game) {
      final gameDate = game['date'] as DateTime?;
      if (gameDate == null) return false;
      final matchesDay = gameDate.year == day.year &&
          gameDate.month == day.month &&
          gameDate.day == day.day;
      return matchesDay;
    }).toList();
  }

  Future<void> _showGameTypeDialog(DateTime day) async {
    if (scheduleName == null) return;

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
    if (!mounted) return;

    // Set up navigation arguments
    Map<String, dynamic> routeArgs = {
      'scheduleName': scheduleName,
      'scheduleId': scheduleId,
      'date': selectedDate,
      'fromScheduleDetails': true,
      'sport': sport ?? _inferSportFromScheduleName(scheduleName ?? ''),
      'isAwayGame': isAway,
      'isAway': isAway,
    };

    // Determine navigation route
    String nextRoute = '/date_time';

    Navigator.pushNamed(
      context,
      nextRoute,
      arguments: routeArgs,
    ).then((_) {
      _fetchGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Schedule Details',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            // Check if we can pop back to the previous screen
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Fallback to AD home screen if navigation stack is empty
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/athletic_director_home',
                (route) => false,
              );
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: isLoading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    scheduleName ?? 'Unnamed Schedule',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                _selectedDayGames =
                                    _getGamesForDay(selectedDay);
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                            },
                            eventLoader: (day) {
                              return _getGamesForDay(day);
                            },
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

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDay = day;
                                      _selectedDayGames = _getGamesForDay(day);
                                    });
                                  },
                                  onLongPress: () => _showGameTypeDialog(day),
                                  onSecondaryTap: () =>
                                      _showGameTypeDialog(day),
                                  child: Container(
                                    margin: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: colorScheme.primary, width: 2),
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
                                  ),
                                );
                              },
                              defaultBuilder: (context, day, focusedDay) {
                                final events = _getGamesForDay(day);
                                final hasEvents = events.isNotEmpty;
                                final isToday = isSameDay(day, DateTime.now());
                                final isOutsideMonth =
                                    day.month != focusedDay.month;
                                final isSelected = _selectedDay != null &&
                                    day.year == _selectedDay!.year &&
                                    day.month == _selectedDay!.month &&
                                    day.day == _selectedDay!.day;

                                // If the day is selected, return null to let the built-in selectedDecoration handle it
                                if (isSelected) {
                                  return null;
                                }

                                Color? backgroundColor;
                                Color textColor = isOutsideMonth
                                    ? Colors.grey
                                    : colorScheme.onSurface;

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

                                // Override text color to black when day is selected
                                if (isSelected) {
                                  textColor = Colors.black;
                                }

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDay = day;
                                      _selectedDayGames = _getGamesForDay(day);
                                    });
                                  },
                                  onLongPress: () => _showGameTypeDialog(day),
                                  onSecondaryTap: () => _showGameTypeDialog(
                                      day), // Right-click for web
                                  child: Container(
                                    margin: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: BorderRadius.circular(4),
                                      border: isSelected &&
                                              backgroundColor == null
                                          ? Border.all(
                                              color: colorScheme.primary,
                                              width: 2)
                                          : isToday && backgroundColor == null
                                              ? Border.all(
                                                  color: colorScheme.primary,
                                                  width: 2)
                                              : null,
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
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('Away Game',
                                        style: TextStyle(
                                            color: colorScheme.onSurface)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
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
                                const SizedBox(width: 16),
                                Row(
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
                          // Scrollable game details section
                          if (_selectedDayGames.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _selectedDayGames.length,
                                padding: const EdgeInsets.only(
                                    bottom:
                                        140), // Add bottom padding to prevent FAB overlap
                                itemBuilder: (context, index) {
                                  final game = _selectedDayGames[index];
                                  final gameTime = game['time'] != null
                                      ? (game['time'] as TimeOfDay)
                                          .format(context)
                                      : 'Not set';
                                  final hiredOfficials =
                                      game['officialsHired'] as int? ?? 0;
                                  final requiredOfficials = int.tryParse(
                                          game['officialsRequired']
                                                  ?.toString() ??
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
                                        '/game_information',
                                        arguments: {
                                          ...game,
                                          'sourceScreen': 'schedule_details',
                                          'scheduleName': scheduleName,
                                          'scheduleId': scheduleId,
                                        },
                                      ).then((result) {
                                        if (result != null) {
                                          if (result is Map<String, dynamic> &&
                                              result['deleted'] == true) {
                                            // Game was deleted, refresh and notify parent
                                            _fetchGames();
                                            Navigator.pop(context, true);
                                          } else if (result == true ||
                                              (result is Map<String, dynamic> &&
                                                  result.isNotEmpty)) {
                                            // Game was modified, just refresh
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
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Time: $gameTime',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: colorScheme
                                                              .onSurface),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    if (hiredOfficials >=
                                                        requiredOfficials)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.green,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          '$hiredOfficials/$requiredOfficials officials confirmed',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Text(
                                                        '$hiredOfficials/$requiredOfficials officials confirmed',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Location: $location',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: colorScheme
                                                              .onSurface),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Opponent: $opponent',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: colorScheme
                                                              .onSurface),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addGame',
            onPressed: _selectedDay == null
                ? null
                : () async {
                    // Ensure we can proceed
                    if (!mounted) return;

                    // Check if we can skip straight to additional info
                    String nextRoute = '/date_time';

                    Navigator.pushNamed(
                      context,
                      nextRoute,
                      arguments: {
                        'scheduleName': scheduleName,
                        'scheduleId': scheduleId,
                        'date': _selectedDay,
                        'time': null,
                        'fromScheduleDetails': true,
                        'sport': sport ??
                            _inferSportFromScheduleName(scheduleName ?? ''),
                      },
                    ).then((_) {
                      _fetchGames();
                    });
                  },
            backgroundColor:
                _selectedDay == null ? Colors.grey[800] : colorScheme.primary,
            tooltip: 'Add Game',
            child: Icon(Icons.add, size: 30, color: colorScheme.onPrimary),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
