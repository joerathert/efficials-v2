import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';

class SelectScheduleScreen extends StatefulWidget {
  const SelectScheduleScreen({super.key});

  @override
  State<SelectScheduleScreen> createState() => _SelectScheduleScreenState();
}

class _SelectScheduleScreenState extends State<SelectScheduleScreen> {
  String? selectedSchedule;
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  GameTemplateModel? template;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the arguments from the current route
    final args = ModalRoute.of(context)!.settings.arguments;

    // Handle the case when args is a Map (coming from HomeScreen with a template)
    if (args is Map<String, dynamic>?) {
      if (args != null && args.containsKey('template')) {
        template = args['template'] as GameTemplateModel?;
      }
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      // Start with empty schedules - we'll replace with actual service calls later
      setState(() {
        schedules = [];

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
            return Icon(
              Icons.sports,
              color: themeProvider.isDarkMode
                  ? colorScheme.primary // Yellow in dark mode
                  : Colors.black, // Black in light mode
              size: 32,
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
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
                      : colorScheme.onBackground,
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
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: SizedBox(
                              width: double.infinity,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Select a schedule',
                                  labelStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                ),
                                value: selectedSchedule,
                                hint: Text(
                                  'Choose from existing schedules',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                                dropdownColor: colorScheme.surface,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedSchedule = newValue;
                                    if (newValue == '+ Create new schedule') {
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
                                          await _fetchSchedules();

                                          // Handle both schedule objects and schedule names
                                          String? scheduleName;
                                          if (result is Map<String, dynamic>) {
                                            // Result is a schedule object from database
                                            scheduleName =
                                                result['name'] as String?;
                                          } else if (result is String) {
                                            // Result is a schedule name from SharedPreferences
                                            scheduleName = result;
                                          }

                                          setState(() {
                                            if (scheduleName != null &&
                                                schedules.any((s) =>
                                                    s['name'] ==
                                                    scheduleName)) {
                                              selectedSchedule = scheduleName;
                                            } else {
                                              // Fallback: Select the first schedule if the new one isn't found
                                              if (schedules.isNotEmpty &&
                                                  schedules.first['name'] !=
                                                      'No schedules available') {
                                                selectedSchedule = schedules
                                                    .first['name'] as String;
                                              }
                                            }
                                          });
                                        } else {
                                          // Fallback: Refresh schedules in case the new schedule was created
                                          await _fetchSchedules();
                                        }
                                      });
                                    }
                                  });
                                },
                                items: schedules.map((schedule) {
                                  final scheduleName =
                                      schedule['name'] as String;
                                  final sport =
                                      schedule['sport'] as String? ?? 'Unknown';

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
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                            if (sport != 'None' &&
                                                sport != 'Unknown')
                                              Text(
                                                sport,
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12,
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
                    const Spacer(),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (selectedSchedule == null ||
                                  selectedSchedule ==
                                      'No schedules available' ||
                                  selectedSchedule == '+ Create new schedule')
                              ? null
                              : () {
                                  // Validate sport match if a template is used
                                  if (!_validateSportMatch()) {
                                    return;
                                  }
                                  final selected = schedules.firstWhere(
                                      (s) => s['name'] == selectedSchedule);
                                  Navigator.pushNamed(
                                    context,
                                    '/date-time',
                                    arguments: {
                                      'scheduleName': selectedSchedule,
                                      'sport': selected['sport'],
                                      'template': template,
                                    },
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor: Colors.grey[600],
                            disabledForegroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    selectedSchedule != null &&
                            selectedSchedule != 'No schedules available' &&
                            selectedSchedule != '+ Create new schedule'
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final selected = schedules.firstWhere(
                                      (s) => s['name'] == selectedSchedule);
                                  _showDeleteConfirmationDialog(
                                      selectedSchedule!, selected['id'] as int);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
    );
  }

  void _showDeleteConfirmationDialog(String scheduleName, int scheduleId) {
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
      String scheduleName, int scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Final Confirmation',
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
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSchedule(scheduleName, scheduleId);
              setState(() {
                selectedSchedule = schedules.isNotEmpty
                    ? schedules[0]['name'] as String
                    : null;
              });
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

  Future<void> _deleteSchedule(String scheduleName, int scheduleId) async {
    // For now, just remove from local list - we'll replace with actual service call
    setState(() {
      schedules.removeWhere((s) => s['name'] == scheduleName);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Schedule "$scheduleName" deleted successfully')),
      );
    }
  }
}
