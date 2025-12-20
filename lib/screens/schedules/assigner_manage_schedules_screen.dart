import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../app_colors.dart';
import '../../app_theme.dart';
import '../../services/user_repository.dart';
import '../../services/game_service.dart';
import '../../models/game_template_model.dart';

class AssignerManageSchedulesScreen extends StatefulWidget {
  const AssignerManageSchedulesScreen({super.key});

  @override
  State<AssignerManageSchedulesScreen> createState() =>
      _AssignerManageSchedulesScreenState();
}

class _AssignerManageSchedulesScreenState
    extends State<AssignerManageSchedulesScreen> {
  String? selectedTeam;
  List<String> teams = [];
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> games = [];
  bool isLoading = true;
  DateTime _focusedDay = DateTime.now();
  final TextEditingController _deleteConfirmationController =
      TextEditingController();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayGames = [];
  String? assignerSport;
  String? associatedTemplateName;
  DateTime? _dateToFocus; // Store date to focus calendar on

  // Services
  final UserRepository _userRepository = UserRepository();
  final GameService _gameService = GameService();

  // Helper function to check if two dates are the same day
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Handle route arguments for focusing on a specific date (e.g., after publishing a game)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final initialDate = args['initialDate'] as DateTime?;
      if (initialDate != null) {
        _dateToFocus = initialDate;
      }
    }
  }

  Future<void> _showDeleteScheduleDialog() async {
    if (selectedTeam == null) return;

    // Find the schedule data
    final schedule = schedules.firstWhere(
      (s) => s['name'] == selectedTeam,
      orElse: () => <String, dynamic>{},
    );

    final scheduleId = schedule['id'];
    final scheduleName = selectedTeam!;

    if (scheduleId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Delete Schedule',
          style: TextStyle(
            color: AppColors.efficialsYellow,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$scheduleName"? This will also delete all games associated with this schedule.',
              style: const TextStyle(color: primaryTextColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'This action CANNOT be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deleteConfirmationController,
              decoration: InputDecoration(
                hintText: 'Type DELETE here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              style: const TextStyle(
                color: primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _deleteConfirmationController.clear();
              Navigator.pop(context, false);
            },
            child: const Text('Cancel',
                style: TextStyle(color: secondaryTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_deleteConfirmationController.text == 'DELETE') {
                _deleteConfirmationController.clear();
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type "DELETE" to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'DELETE PERMANENTLY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _gameService.deleteSchedule(scheduleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reset selected team and refresh the schedules list
          setState(() {
            selectedTeam = null;
          });
          await _fetchTeams();
          // If there are teams available, select the first one
          if (teams.isNotEmpty && mounted) {
            setState(() {
              selectedTeam = teams.first;
            });
            await _fetchGames();
            await _loadAssociatedTemplate();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete schedule: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> _getGamesForDay(DateTime day) {
    final matchingGames = games.where((game) {
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: primaryTextColor,
          ),
        ),
      ],
    );
  }

  Future<void> _showGameTypeDialog(DateTime day) async {
    if (selectedTeam == null) return;

    final String? gameType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.efficialsYellow,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Add Game',
                style: const TextStyle(
                  color: AppColors.efficialsYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Add a game for ${day.month}/${day.day}/${day.year}?',
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('away'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.efficialsYellow,
                foregroundColor: AppColors.efficialsBlack,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_bus, size: 16),
                  const SizedBox(width: 4),
                  const Text('Away', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.efficialsYellow,
                foregroundColor: AppColors.efficialsBlack,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home, size: 16),
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
    // Load template from database if one is associated with this team
    Map<String, dynamic>? template;

    if (associatedTemplateName != null) {
      try {
        final currentUser = await _userRepository.getCurrentUser();
        final userId = currentUser?.id;
        if (userId != null) {
          final templateData =
              await _gameService.getTemplateAssociations(selectedTeam!);
          if (templateData.isNotEmpty) {
            template =
                templateData.first['templateData'] as Map<String, dynamic>?;
          }
        }
      } catch (e) {
        debugPrint('Error loading template: $e');
      }
    }

    if (mounted) {
      // Set up navigation arguments
      Map<String, dynamic> routeArgs = {
        'scheduleName': selectedTeam,
        'date': selectedDate,
        'fromScheduleDetails': true,
        'template': template,
        'isAssignerFlow': true,
        'opponent': selectedTeam,
        'sport': assignerSport,
        'isAwayGame': isAway,
        'isAway': isAway,
      };

      // Add template time if available
      if (template != null &&
          template['includeTime'] == true &&
          template['time'] != null) {
        routeArgs['time'] = template['time'];
      }

      // Determine navigation route
      String nextRoute;
      if (template == null ||
          template['includeTime'] != true ||
          template['time'] == null) {
        nextRoute = '/date-time';
      } else if (template['includeLocation'] != true ||
          template['location'] == null ||
          template['location'].isEmpty) {
        nextRoute = '/choose-location';
      } else {
        nextRoute = '/additional-game-info';
      }

      Navigator.pushNamed(
        context,
        nextRoute,
        arguments: routeArgs,
      ).then((_) {
        _fetchGames();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAssignerInfo();
  }

  Future<void> _loadAssignerInfo() async {
    try {
      // Get current user info and sport from database
      final currentUser = await _userRepository.getCurrentUser();
      if (currentUser != null) {
        assignerSport = currentUser.schedulerProfile?.sport;
      }

      await _fetchTeams();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading assigner info: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addNewTeam() async {
    final result = await Navigator.pushNamed(
      context,
      '/name-schedule',
      arguments: {
        'sport': assignerSport, // Pass the assigner's primary sport
      },
    );

    if (result != null) {
      await _fetchTeams();
      if (mounted) {
        setState(() {
          // Handle both schedule object (from database) and string (from SharedPreferences)
          if (result is Map<String, dynamic>) {
            selectedTeam = result['name'] as String;
          } else {
            selectedTeam = result as String;
          }
        });
      }
    }
  }

  Future<void> _fetchTeams() async {
    try {
      final fetchedSchedules = await _gameService.getSchedules();
      setState(() {
        schedules = fetchedSchedules;
        teams = fetchedSchedules
            .map((schedule) => schedule['name'] as String)
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
      setState(() {
        teams = [];
      });
    }
  }

  Future<void> _loadAssociatedTemplate() async {
    if (selectedTeam == null) return;

    try {
      final templateAssociations =
          await _gameService.getTemplateAssociations(selectedTeam!);
      if (mounted) {
        if (templateAssociations.isNotEmpty) {
          // Get the most recent association
          final association = templateAssociations.first;
          final templateId = association['templateId'] as String?;

          // Verify the template still exists by checking if we can get it
          if (templateId != null) {
            try {
              final template = await _gameService.getTemplate(templateId);
              if (template != null) {
                // Template still exists, show it
                final templateData =
                    association['templateData'] as Map<String, dynamic>?;
                setState(() {
                  associatedTemplateName = templateData?['name'] as String?;
                });
                debugPrint(
                    '✅ ASSIGNER MANAGE: Template still exists: $associatedTemplateName');
              } else {
                // Template no longer exists, clean up the association
                debugPrint(
                    '⚠️ ASSIGNER MANAGE: Template $templateId no longer exists, cleaning up association');
                await _gameService.removeTemplateAssociation(selectedTeam!);
                setState(() {
                  associatedTemplateName = null;
                });
              }
            } catch (e) {
              debugPrint(
                  '❌ ASSIGNER MANAGE: Error verifying template existence: $e');
              // If we can't verify, assume it doesn't exist and clean up
              await _gameService.removeTemplateAssociation(selectedTeam!);
              setState(() {
                associatedTemplateName = null;
              });
            }
          } else {
            setState(() {
              associatedTemplateName = null;
            });
          }
        } else {
          setState(() {
            associatedTemplateName = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading associated template: $e');
      if (mounted) {
        setState(() {
          associatedTemplateName = null;
        });
      }
    }
  }

  Future<void> _removeAssociatedTemplate() async {
    if (selectedTeam == null) return;

    try {
      final success =
          await _gameService.removeTemplateAssociation(selectedTeam!);
      if (success && mounted) {
        // Refresh template information from server to ensure UI consistency
        await _loadAssociatedTemplate();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template association removed')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to remove template association')),
        );
      }
    } catch (e) {
      debugPrint('Error removing associated template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error removing template association')),
        );
      }
    }
  }

  Future<void> _fetchGames() async {
    if (selectedTeam == null) {
      setState(() {
        games.clear();
        _selectedDay = null;
        _selectedDayGames = [];
      });
      return;
    }

    try {
      // Get games from GameService using the schedule name
      final teamGames =
          await _gameService.getGamesByScheduleName(selectedTeam!);

      // Filter by sport if needed
      games = teamGames.where((game) {
        final matchesSport =
            assignerSport == null || game['sport'] == assignerSport;
        final hasDate = game['date'] != null;
        return matchesSport && hasDate;
      }).toList();

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

      // Set focused day based on priority: dateToFocus > next upcoming game > current date
      if (_dateToFocus != null) {
        _focusedDay = _dateToFocus!;
        _dateToFocus = null; // Clear after use
      } else if (games.isNotEmpty) {
        games.sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

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
        _selectedDay = null;
        _selectedDayGames = [];
      }

      // Update UI only if widget is still mounted
      if (mounted) {
        setState(() {});
      }

      await _loadAssociatedTemplate();
    } catch (e) {
      debugPrint('Error fetching games: $e');
      if (mounted) {
        setState(() {
          games = [];
          _selectedDay = null;
          _selectedDayGames = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 36, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Schedules', style: appBarTextStyle),
        actions: selectedTeam != null
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteScheduleDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Schedule',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : teams.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -80),
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 80,
                                color:
                                    AppColors.efficialsYellow.withOpacity(0.6),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Welcome to Schedule Management!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.efficialsYellow,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Get started by adding your first team to manage their game schedules.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _addNewTeam,
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 24),
                                label: const Text(
                                  'Add Your First Team',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.efficialsYellow,
                                  foregroundColor: AppColors.efficialsBlack,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Team dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Team',
                            labelStyle: const TextStyle(
                                color: AppColors.efficialsYellow),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.efficialsYellow),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: AppColors.efficialsYellow
                                      .withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: AppColors.efficialsYellow, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          value: selectedTeam,
                          hint: const Text('Select a team',
                              style: TextStyle(color: secondaryTextColor)),
                          dropdownColor: AppColors.darkSurface,
                          style: const TextStyle(color: primaryTextColor),
                          onChanged: (newValue) async {
                            if (newValue == '+ Add new') {
                              await _addNewTeam();
                            } else {
                              if (mounted) {
                                setState(() {
                                  selectedTeam = newValue;
                                  _selectedDay = null;
                                  _selectedDayGames = [];
                                });
                                await _fetchGames();
                                await _loadAssociatedTemplate();
                              }
                            }
                          },
                          items: [
                            ...teams.map((team) => DropdownMenuItem(
                                  value: team,
                                  child: Text(team,
                                      style: const TextStyle(
                                          color: primaryTextColor)),
                                )),
                            const DropdownMenuItem(
                              value: '+ Add new',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: AppColors.efficialsYellow,
                                      size: 20),
                                  SizedBox(width: 8),
                                  Text('+ Add new',
                                      style:
                                          TextStyle(color: primaryTextColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (selectedTeam != null) ...[
                          Column(
                            children: [
                              Text(
                                '$selectedTeam Schedule',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.efficialsYellow,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (associatedTemplateName != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.efficialsYellow
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.efficialsYellow
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.content_copy,
                                            size: 16,
                                            color: AppColors.efficialsYellow,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            associatedTemplateName ??
                                                'Unknown Template',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.efficialsYellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _removeAssociatedTemplate,
                                      icon: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red.shade600,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            Colors.red.withOpacity(0.1),
                                        padding: const EdgeInsets.all(6),
                                        shape: const CircleBorder(),
                                        side: BorderSide(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
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
                                      color: AppColors.efficialsYellow
                                          .withOpacity(0.5),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: AppColors.efficialsYellow,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    selectedTextStyle: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.efficialsBlack,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    defaultTextStyle: const TextStyle(
                                        fontSize: 16, color: primaryTextColor),
                                    weekendTextStyle: const TextStyle(
                                        fontSize: 16, color: primaryTextColor),
                                    outsideTextStyle: TextStyle(
                                        fontSize: 16, color: Colors.grey[400]),
                                    markersMaxCount: 0,
                                  ),
                                  daysOfWeekStyle: const DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: primaryTextColor),
                                    weekendStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: primaryTextColor),
                                  ),
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleTextStyle: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.efficialsYellow),
                                    leftChevronIcon: Icon(Icons.chevron_left,
                                        color: AppColors.efficialsYellow,
                                        size: 28),
                                    rightChevronIcon: Icon(Icons.chevron_right,
                                        color: AppColors.efficialsYellow,
                                        size: 28),
                                    titleCentered: true,
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    selectedBuilder:
                                        (context, day, focusedDay) {
                                      final events = _getGamesForDay(day);
                                      final hasEvents = events.isNotEmpty;

                                      Color? backgroundColor =
                                          AppColors.efficialsYellow;
                                      Color textColor =
                                          AppColors.efficialsBlack;

                                      // For selected days, always show yellow background regardless of events
                                      // The yellow indicates selection, not event status

                                      return GestureDetector(
                                        onLongPress: () =>
                                            _showGameTypeDialog(day),
                                        onSecondaryTap: () =>
                                            _showGameTypeDialog(day),
                                        child: Container(
                                          margin: const EdgeInsets.all(4.0),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color:
                                                    AppColors.efficialsYellow,
                                                width: 2),
                                            boxShadow: hasEvents
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      spreadRadius: 1,
                                                      blurRadius: 1,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: hasEvents
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
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
                                      final isToday =
                                          isSameDay(day, DateTime.now());
                                      final isOutsideMonth =
                                          day.month != focusedDay.month;
                                      final isSelected = _selectedDay != null &&
                                          day.year == _selectedDay!.year &&
                                          day.month == _selectedDay!.month &&
                                          day.day == _selectedDay!.day;

                                      Color? backgroundColor;
                                      Color textColor = isOutsideMonth
                                          ? Colors.grey[400]!
                                          : primaryTextColor;

                                      if (hasEvents) {
                                        bool allAway = true;
                                        bool allFullyHired = true;
                                        bool needsOfficials = false;

                                        for (var event in events) {
                                          final isEventAway =
                                              event['isAway'] as bool? ?? false;
                                          final hiredOfficials =
                                              event['officialsHired'] as int? ??
                                                  0;
                                          final requiredOfficials =
                                              int.tryParse(
                                                      event['officialsRequired']
                                                              ?.toString() ??
                                                          '0') ??
                                                  0;
                                          final isFullyHired = hiredOfficials >=
                                              requiredOfficials;

                                          if (!isEventAway) allAway = false;
                                          if (!isFullyHired) {
                                            allFullyHired = false;
                                          }
                                          if (!isEventAway && !isFullyHired) {
                                            needsOfficials = true;
                                          }
                                        }

                                        if (allAway) {
                                          backgroundColor = Colors.grey[300];
                                          textColor = Colors.white;
                                        } else if (needsOfficials) {
                                          backgroundColor = Colors.red[400];
                                          textColor = Colors.white;
                                        } else if (allFullyHired) {
                                          backgroundColor = Colors.green[400];
                                          textColor = Colors.white;
                                        }
                                      }

                                      // Override text color for selected dates to ensure readability
                                      if (isSelected) {
                                        textColor = AppColors.efficialsBlack;
                                      }

                                      return GestureDetector(
                                        onLongPress: () =>
                                            _showGameTypeDialog(day),
                                        onSecondaryTap: () =>
                                            _showGameTypeDialog(day),
                                        child: Container(
                                          margin: const EdgeInsets.all(4.0),
                                          decoration: BoxDecoration(
                                            color: backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: isSelected
                                                ? Border.all(
                                                    color: AppColors
                                                        .efficialsYellow,
                                                    width: 2)
                                                : isToday &&
                                                        backgroundColor == null
                                                    ? Border.all(
                                                        color: AppColors
                                                            .efficialsBlue
                                                            .withOpacity(0.5),
                                                        width: 1)
                                                    : null,
                                            boxShadow: hasEvents
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      spreadRadius: 1,
                                                      blurRadius: 1,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: hasEvents
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Calendar legend with improved styling
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurface,
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildLegendItem(
                                        color: Colors.green[400]!,
                                        label: 'Fully Hired',
                                        icon: Icons.check_circle,
                                      ),
                                      _buildLegendItem(
                                        color: Colors.red[400]!,
                                        label: 'Needs Officials',
                                        icon: Icons.warning,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Selected day games list with improved styling
                          if (_selectedDayGames.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.3,
                                minHeight: 100,
                              ),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                shrinkWrap: true,
                                itemCount: _selectedDayGames.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 16),
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
                                  final isAway =
                                      game['isAway'] as bool? ?? false;

                                  return InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/game_information',
                                        arguments: game,
                                      ).then((result) {
                                        if (result == true ||
                                            (result is Map<String, dynamic> &&
                                                result.isNotEmpty)) {
                                          _fetchGames();
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkSurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: hiredOfficials >=
                                                  requiredOfficials
                                              ? Colors.green[400]!
                                              : Colors.red[400]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: 18,
                                                    color: secondaryTextColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    gameTime,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: primaryTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: hiredOfficials >=
                                                          requiredOfficials
                                                      ? Colors.green
                                                      : Colors.red[400],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '$hiredOfficials/$requiredOfficials officials',
                                                  style: TextStyle(
                                                    color: hiredOfficials >=
                                                            requiredOfficials
                                                        ? Colors.white
                                                        : AppColors.darkSurface,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(
                                                isAway
                                                    ? Icons.directions_bus
                                                    : Icons.location_on,
                                                size: 18,
                                                color: secondaryTextColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  location,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: primaryTextColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.people,
                                                size: 18,
                                                color: secondaryTextColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'vs $opponent',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: primaryTextColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (_selectedDay != null && _selectedDayGames.isEmpty)
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Text(
                                'No games scheduled for ${_selectedDay!.month}/${_selectedDay!.day}/${_selectedDay!.year}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: secondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
      floatingActionButton: selectedTeam != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'setTemplate',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/game-templates',
                      arguments: {
                        'scheduleName': selectedTeam,
                        'sport': assignerSport,
                        'isAssignerFlow': true,
                      },
                    ).then((_) {
                      _loadAssociatedTemplate();
                    });
                  },
                  backgroundColor: AppColors.efficialsYellow,
                  tooltip: 'Set Template',
                  child:
                      const Icon(Icons.link, color: AppColors.efficialsBlack),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'addGame',
                  onPressed: _selectedDay == null
                      ? null
                      : () async {
                          // Load template from database if one is associated with this team
                          Map<String, dynamic>? rawTemplate;

                          if (associatedTemplateName != null) {
                            try {
                              final currentUser =
                                  await _userRepository.getCurrentUser();
                              final userId = currentUser?.id;
                              if (userId != null) {
                                final templateData = await _gameService
                                    .getTemplateAssociations(selectedTeam!);
                                if (templateData.isNotEmpty) {
                                  rawTemplate =
                                      templateData.first['templateData']
                                          as Map<String, dynamic>?;
                                }
                              }
                            } catch (e) {
                              debugPrint('Error loading template: $e');
                            }
                          }

                          if (mounted) {
                            // Convert template Map to GameTemplateModel if available
                            GameTemplateModel? gameTemplateModel;
                            if (rawTemplate != null) {
                              try {
                                gameTemplateModel =
                                    GameTemplateModel.fromJson(rawTemplate);
                              } catch (e) {
                                debugPrint(
                                    'Error converting template Map to GameTemplateModel: $e');
                              }
                            }

                            // Determine the navigation flow based on template settings
                            String nextRoute;
                            // Get the actual team name from the schedule data
                            final selectedSchedule = schedules.firstWhere(
                              (s) => s['name'] == selectedTeam,
                              orElse: () => <String, dynamic>{},
                            );

                            // Handle schedules that don't have homeTeamName set yet
                            // Temporary mapping for existing schedules
                            String homeTeamName;
                            final scheduleHomeTeamName =
                                selectedSchedule['homeTeamName'];
                            if (scheduleHomeTeamName is String &&
                                scheduleHomeTeamName.isNotEmpty) {
                              homeTeamName = scheduleHomeTeamName;
                            } else if (selectedTeam == 'Edwardsville Varsity') {
                              homeTeamName =
                                  'Edwardsville Tigers'; // Temporary fix
                            } else {
                              homeTeamName = selectedTeam ??
                                  'Unknown Team'; // Fallback to schedule name
                            }

                            Map<String, dynamic> routeArgs = {
                              'scheduleName': selectedTeam,
                              'scheduleId': selectedSchedule['id'],
                              'date': _selectedDay,
                              'fromScheduleDetails': true,
                              'template': gameTemplateModel,
                              'isAssignerFlow': true,
                              'homeTeam':
                                  homeTeamName, // Use the actual team name, not schedule name
                              'opponent':
                                  '', // Opponent will be filled in by user
                              'sport': assignerSport,
                            };

                            // Add template time to args if it exists, regardless of route
                            if (gameTemplateModel != null &&
                                gameTemplateModel.includeTime &&
                                gameTemplateModel.time != null) {
                              routeArgs['time'] = gameTemplateModel.time;
                            }

                            // Add template location to args if it exists, regardless of route
                            if (gameTemplateModel != null &&
                                gameTemplateModel.includeLocation &&
                                gameTemplateModel.location != null &&
                                gameTemplateModel.location!.isNotEmpty) {
                              routeArgs['location'] =
                                  gameTemplateModel.location;
                            }

                            // Determine the navigation flow based on template settings
                            // Always go to date_time screen first if no template or template doesn't have time set
                            if (gameTemplateModel == null ||
                                !gameTemplateModel.includeTime ||
                                gameTemplateModel.time == null) {
                              nextRoute = '/date-time';
                            }
                            // Check if template has location set - if not, go to location screen
                            else if (!gameTemplateModel.includeLocation ||
                                gameTemplateModel.location == null ||
                                gameTemplateModel.location!.isEmpty) {
                              nextRoute = '/choose-location';
                            }
                            // Template has time and location set - go to additional_game_info to enter opponent and other details
                            else {
                              nextRoute = '/additional-game-info';
                            }

                            Navigator.pushNamed(
                              context,
                              nextRoute,
                              arguments: routeArgs,
                            ).then((_) {
                              _fetchGames();
                            });
                          }
                        },
                  backgroundColor: _selectedDay == null
                      ? Colors.grey
                      : AppColors.efficialsYellow,
                  tooltip: 'Add Game',
                  child: const Icon(Icons.add,
                      size: 30, color: AppColors.efficialsBlack),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
