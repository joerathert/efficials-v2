import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';
import '../services/game_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Use the typedef from GameService
typedef ScheduleData = Map<String, Object>;

class SelectScheduleScreen extends StatefulWidget {
  const SelectScheduleScreen({super.key});

  @override
  State<SelectScheduleScreen> createState() => _SelectScheduleScreenState();
}

class _SelectScheduleScreenState extends State<SelectScheduleScreen> {
  String? selectedSchedule;
  List<ScheduleData> schedules = [];
  bool isLoading = true;
  GameTemplateModel? template;
  UserModel? _currentUser;
  final UserService _userService = UserService();
  bool viewOnly = false; // Flag to determine if we're viewing schedules or creating a game

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _fetchSchedules();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _userService.getCurrentUser();
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the arguments from the current route
    final route = ModalRoute.of(context);
    if (route != null) {
      final args = route.settings.arguments;

      // Handle the case when args is a Map
      if (args is Map<String, dynamic>?) {
        if (args != null) {
          // Check if we're in view-only mode (from hamburger menu)
          if (args.containsKey('viewOnly')) {
            viewOnly = args['viewOnly'] as bool? ?? false;
          }
          
          if (args.containsKey('template')) {
            template = args['template'] as GameTemplateModel?;
          } else if (args.containsKey('name') && args.containsKey('sport')) {
            // This is a new schedule that was just created
            // Add it to the schedules list and select it
            final ScheduleData newSchedule = {
              'id': args['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              'name': args['name'] as String,
              'sport': args['sport'] as String,
            };

            // Only add if it's not already in the list
            if (!schedules.any((s) => s['name'] == newSchedule['name'])) {
              setState(() {
                schedules.insert(0, newSchedule);
                selectedSchedule = newSchedule['name'] as String;
              });
            }
          }
        }
      }
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      // Fetch schedules from Firebase
      final gameService = GameService();
      final fetchedSchedules = await gameService.getSchedules();

      setState(() {
        schedules = fetchedSchedules;

        // Filter schedules by the template's sport if a template is provided
        if (template != null &&
            template!.includeSport &&
            template!.sport != null) {
          schedules = schedules
              .where((schedule) =>
                  schedule['sport'] == template!.sport ||
                  schedule['name'] == '+ Create new schedule')
              .toList();
        }

        // Add default options
        if (schedules.isEmpty) {
          schedules.add(
              {'name': 'No schedules available', 'id': -1, 'sport': 'None'});
        }
        schedules
            .add({'name': '+ Create new schedule', 'id': 0, 'sport': 'None'});

        // Ensure selectedSchedule is valid or null
        if (selectedSchedule != null &&
            !schedules.any((s) => s['name'] == selectedSchedule)) {
          selectedSchedule = null;
        }

        isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchSchedules: $e');
      setState(() {
        schedules.clear();
        schedules
            .add({'name': 'No schedules available', 'id': -1, 'sport': 'None'});
        schedules
            .add({'name': '+ Create new schedule', 'id': 0, 'sport': 'None'});

        // Ensure selectedSchedule is valid or null
        if (selectedSchedule != null &&
            !schedules.any((s) => s['name'] == selectedSchedule)) {
          selectedSchedule = null;
        }

        isLoading = false;
      });
    }
  }

  bool _validateSportMatch() {
    if (template == null || !template!.includeSport) {
      return true; // No template or sport not included, so no validation needed
    }

    final selected = schedules.firstWhere(
      (s) => s['name'] == selectedSchedule,
      orElse: () => {},
    );
    if (selected.isEmpty ||
        selected['sport'] == null ||
        selected['sport'] == 'None') {
      return true; // No sport associated with the schedule
    }

    final scheduleSport = selected['sport'] as String;
    final templateSport = template!.sport?.toLowerCase() ?? '';
    if (scheduleSport.toLowerCase() != templateSport) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'The selected schedule\'s sport ($scheduleSport) does not match the template\'s sport (${template!.sport ?? "Not set"}). Please select a different schedule.'),
        ),
      );
      return false;
    }
    return true;
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
            return IconButton(
              icon: Icon(
                Icons.sports,
                color: themeProvider.isDarkMode
                    ? colorScheme.primary // Yellow in dark mode
                    : Colors.black, // Black in light mode
                size: 32,
              ),
              onPressed: () async {
                // Navigate to user home screen
                final authService = AuthService();
                final homeRoute = await authService.getHomeRoute();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  homeRoute,
                  (route) => false, // Remove all routes
                );
              },
              tooltip: 'Home',
            );
          },
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Select Schedule',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose an existing schedule or create a new one',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Select a schedule',
                                        labelStyle: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                      ),
                                      initialValue: selectedSchedule,
                                      hint: Text(
                                        'Choose from existing schedules',
                                        style: TextStyle(
                                            color:
                                                colorScheme.onSurfaceVariant),
                                      ),
                                      dropdownColor: colorScheme.surface,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 16,
                                      ),
                                      onChanged: (newValue) {
                                        setState(() {
                                          selectedSchedule = newValue;
                                          if (newValue ==
                                              '+ Create new schedule') {
                                            // Reset selectedSchedule to ensure the dropdown updates correctly
                                            selectedSchedule = null;
                                            Navigator.pushNamed(
                                              context,
                                              '/select-sport',
                                              arguments: {
                                                'fromTemplate': true,
                                                'sport': template?.sport,
                                              },
                                            ).then((result) async {
                                              if (result != null) {
                                                // Refresh schedules from Firebase to ensure the newly created schedule is included
                                                await _fetchSchedules();

                                                // Handle the new schedule object
                                                if (result
                                                    is Map<String, dynamic>) {
                                                  // Find and select the newly created schedule
                                                  final newScheduleName =
                                                      result['name'] as String;
                                                  if (schedules.any((s) =>
                                                      s['name'] ==
                                                      newScheduleName)) {
                                                    setState(() {
                                                      selectedSchedule =
                                                          newScheduleName;
                                                    });
                                                  }
                                                }
                                              }
                                            });
                                          }
                                        });
                                      },
                                      items: schedules.map((schedule) {
                                        final scheduleName =
                                            schedule['name'] as String;

                                        return DropdownMenuItem(
                                          value: scheduleName,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    scheduleName,
                                                    style: TextStyle(
                                                      color: scheduleName ==
                                                              'No schedules available'
                                                          ? Colors.red
                                                          : colorScheme
                                                              .onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 400,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (selectedSchedule == null ||
                                      selectedSchedule ==
                                          'No schedules available' ||
                                      selectedSchedule ==
                                          '+ Create new schedule')
                                  ? null
                                  : () async {
                                      // Validate sport match if a template is used
                                      if (!_validateSportMatch()) {
                                        return;
                                      }
                                      final selected = schedules.firstWhere(
                                          (s) => s['name'] == selectedSchedule);

                                      // If viewOnly mode (from hamburger menu), navigate to schedule details
                                      if (viewOnly) {
                                        debugPrint(
                                            '📅 SELECT_SCHEDULE: View-only mode, navigating to schedule details');
                                        Navigator.pushNamed(
                                          context,
                                          '/schedule_details',
                                          arguments: {
                                            'scheduleName': selectedSchedule,
                                            'scheduleId': selected['id'],
                                          },
                                        );
                                        return;
                                      }

                                      // Get home team from scheduler's profile
                                      String? homeTeam;

                                      // Ensure we have the current user loaded
                                      UserModel? currentUser = _currentUser;
                                      if (currentUser == null) {
                                        // Try to load current user synchronously if not already loaded
                                        try {
                                          currentUser = await _userService
                                              .getCurrentUser();
                                          _currentUser = currentUser;
                                        } catch (e) {
                                          debugPrint(
                                              '🏈 SELECT_SCHEDULE: Error loading current user: $e');
                                        }
                                      }

                                      if (currentUser?.schedulerProfile !=
                                          null) {
                                        final profile =
                                            currentUser!.schedulerProfile!;
                                        if (profile.type ==
                                            'Athletic Director') {
                                          homeTeam = profile.teamName;
                                          debugPrint(
                                              '🏈 SELECT_SCHEDULE: Setting homeTeam to AD profile team: $homeTeam');
                                        } else {
                                          debugPrint(
                                              '🏈 SELECT_SCHEDULE: User is ${profile.type}, not setting homeTeam');
                                        }
                                      } else {
                                        // Fallback: try to get team name from regular profile if it's an AD
                                        if (currentUser?.role ==
                                                'athletic_director' ||
                                            currentUser?.role == 'scheduler') {
                                          if (currentUser?.schedulerProfile !=
                                              null) {
                                            homeTeam = currentUser!
                                                .schedulerProfile!.teamName;
                                            debugPrint(
                                                '🏈 SELECT_SCHEDULE: Found schedulerProfile for ${currentUser.role}, homeTeam: $homeTeam');
                                          } else {
                                            debugPrint(
                                                '🏈 SELECT_SCHEDULE: User role is ${currentUser?.role} but no schedulerProfile found');
                                          }
                                        }
                                        if (homeTeam == null) {
                                          debugPrint(
                                              '🏈 SELECT_SCHEDULE: No scheduler profile found and no fallback available');
                                        }
                                      }

                                      Navigator.pushNamed(
                                        context,
                                        '/date-time',
                                        arguments: {
                                          'scheduleName': selectedSchedule,
                                          'scheduleId': selected[
                                              'id'], // Add the schedule ID
                                          'sport': selected['sport'],
                                          'homeTeam': homeTeam,
                                          'template': template,
                                          'prepopulateTime': template != null &&
                                              template!.includeTime &&
                                              template!.time != null,
                                          'time': template?.time,
                                          'skipLocation': template != null &&
                                              template!.includeLocation &&
                                              template!.location != null &&
                                              template!.location!.isNotEmpty,
                                        },
                                      );
                                      debugPrint(
                                          '🎯 SELECT_SCHEDULE: Navigation to date-time');
                                      debugPrint(
                                          '🎯 SELECT_SCHEDULE: prepopulateTime: ${template != null && template!.includeTime && template!.time != null}');
                                      debugPrint(
                                          '🎯 SELECT_SCHEDULE: skipLocation: ${template != null && template!.includeLocation && template!.location != null && template!.location!.isNotEmpty}');
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (selectedSchedule == null ||
                                        selectedSchedule ==
                                            'No schedules available' ||
                                        selectedSchedule ==
                                            '+ Create new schedule')
                                    ? colorScheme.surfaceVariant
                                    : colorScheme.primary,
                                foregroundColor: (selectedSchedule == null ||
                                        selectedSchedule ==
                                            'No schedules available' ||
                                        selectedSchedule ==
                                            '+ Create new schedule')
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: (selectedSchedule == null ||
                                          selectedSchedule ==
                                              'No schedules available' ||
                                          selectedSchedule ==
                                              '+ Create new schedule')
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          selectedSchedule != null &&
                                  selectedSchedule !=
                                      'No schedules available' &&
                                  selectedSchedule != '+ Create new schedule'
                              ? SizedBox(
                                  width: 400,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final selected = schedules.firstWhere(
                                          (s) => s['name'] == selectedSchedule);
                                      _showDeleteConfirmationDialog(
                                          selectedSchedule!,
                                          selected['id'] as String);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String scheduleName, String scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Confirm Delete',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$scheduleName"?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondDeleteConfirmationDialog(scheduleName, scheduleId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecondDeleteConfirmationDialog(
      String scheduleName, String scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Second Confirmation',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Deleting a schedule will erase all games associated with the schedule. Are you sure you want to delete this schedule?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showThirdDeleteConfirmationDialog(scheduleName, scheduleId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Continue',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showThirdDeleteConfirmationDialog(
      String scheduleName, String scheduleId) async {
    // Get game count and affected officials count
    final gameService = GameService();
    int gameCount = 0;
    Set<String> affectedOfficials = {};
    
    try {
      final games = await gameService.getGamesByScheduleId(scheduleId);
      gameCount = games.length;
      
      // Count unique officials across all games
      for (var game in games) {
        final selectedOfficials = game['selectedOfficials'] as List?;
        if (selectedOfficials != null) {
          for (var official in selectedOfficials) {
            if (official is Map && official['id'] != null) {
              affectedOfficials.add(official['id'] as String);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting game details: $e');
    }

    if (!mounted) return;
    
    // Use showDialog with a result to handle the confirmation
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _FinalDeleteConfirmationDialog(
        scheduleName: scheduleName,
        gameCount: gameCount,
        affectedOfficialsCount: affectedOfficials.length,
      ),
    );
    
    // If user confirmed deletion
    if (result == true && mounted) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Deleting schedule and notifying officials...'),
            ],
          ),
          duration: Duration(seconds: 5),
        ),
      );
      
      // Delete and navigate back
      await _deleteSchedule(scheduleName, scheduleId);
    }
  }

  Future<void> _deleteSchedule(String scheduleName, String scheduleId) async {
    try {
      debugPrint('🗑️ SELECT_SCHEDULE: Starting deletion of schedule: $scheduleName');
      
      // Delete the schedule from Firestore (this also deletes associated games and notifies officials)
      final gameService = GameService();
      await gameService.deleteSchedule(scheduleId);
      
      debugPrint('✅ SELECT_SCHEDULE: Schedule deleted successfully');

      // Navigate back immediately without setState to avoid accessing disposed controllers
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule "$scheduleName" deleted successfully. Officials have been notified.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Return a result to notify the calling screen to refresh
        // Pop immediately without setState since we're leaving this screen anyway
        Navigator.pop(context, {'scheduleDeleted': true});
      }
    } catch (e) {
      debugPrint('❌ SELECT_SCHEDULE: Error deleting schedule: $e');
      debugPrint('❌ SELECT_SCHEDULE: Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting schedule: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }
}

/// Separate StatefulWidget for the final delete confirmation dialog
/// This properly manages the TextEditingController lifecycle
class _FinalDeleteConfirmationDialog extends StatefulWidget {
  final String scheduleName;
  final int gameCount;
  final int affectedOfficialsCount;

  const _FinalDeleteConfirmationDialog({
    required this.scheduleName,
    required this.gameCount,
    required this.affectedOfficialsCount,
  });

  @override
  State<_FinalDeleteConfirmationDialog> createState() =>
      _FinalDeleteConfirmationDialogState();
}

class _FinalDeleteConfirmationDialogState
    extends State<_FinalDeleteConfirmationDialog> {
  late TextEditingController _confirmationController;

  @override
  void initState() {
    super.initState();
    _confirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'FINAL CONFIRMATION',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to permanently delete:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Schedule: "${widget.scheduleName}"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${widget.gameCount} game${widget.gameCount != 1 ? 's' : ''} will be deleted',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ${widget.affectedOfficialsCount} official${widget.affectedOfficialsCount != 1 ? 's' : ''} will be notified',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This action CANNOT be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmationController,
              decoration: InputDecoration(
                hintText: 'Type DELETE here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false); // Return false - cancelled
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_confirmationController.text == 'DELETE') {
              Navigator.pop(context, true); // Return true - confirmed
            } else {
              // Show error if text doesn't match
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
    );
  }
}
