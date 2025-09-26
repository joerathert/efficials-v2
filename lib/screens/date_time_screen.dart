import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';

class DateTimeScreen extends StatefulWidget {
  const DateTimeScreen({super.key});

  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  GameTemplateModel? template;
  String? scheduleName;
  String? sport;
  bool prepopulateTime = false;
  bool skipLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route != null) {
      final args = route.settings.arguments;
      if (args is Map<String, dynamic>) {
        scheduleName = args['scheduleName'] as String?;
        sport = args['sport'] as String?;
        template = args['template'] as GameTemplateModel?;
        prepopulateTime = args['prepopulateTime'] as bool? ?? false;
        skipLocation = args['skipLocation'] as bool? ?? false;

        // Pre-populate time from template if available, or from edit arguments
        if (args['time'] is TimeOfDay) {
          selectedTime = args['time'] as TimeOfDay;
          debugPrint(
              '⏰ Pre-populated time: ${selectedTime!.format(context)} (from ${prepopulateTime ? 'template' : 'edit'})');
        }

        // Pre-populate date from template if available, or from edit arguments
        if (args['date'] is DateTime) {
          selectedDate = args['date'] as DateTime;
          debugPrint('📅 Pre-populated date: $selectedDate (from edit)');
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Set Date & Time',
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
                      'Choose when this game will take place',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
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
                          Text(
                            'Schedule: ${scheduleName ?? "Not set"}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sport: ${sport ?? "Not set"}',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Select Date',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    selectedDate != null
                                        ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                                        : 'Select a date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selectedDate != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Select Time',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.outline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    selectedTime != null
                                        ? selectedTime!.format(context)
                                        : 'Select a time',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selectedTime != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 400,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (selectedDate != null)
                                  ? () {
                                      // Use selectedTime if user chose it, otherwise use pre-populated time
                                      TimeOfDay? finalTime = selectedTime;
                                      if (finalTime == null &&
                                          prepopulateTime) {
                                        final args = ModalRoute.of(context)
                                            ?.settings
                                            .arguments as Map<String, dynamic>?;
                                        finalTime = args?['time'] as TimeOfDay?;
                                      }

                                      debugPrint(
                                          '📅 Final date/time selection - Date: $selectedDate, Time: ${finalTime?.format(context)}');

                                      if (skipLocation) {
                                        // Location is already set in template, skip to additional game info
                                        debugPrint(
                                            '✅ Skipping location selection, going to additional game info');
                                        final templateLocation =
                                            template?.location;
                                        final isAwayGame =
                                            templateLocation == 'Away Game';

                                        Navigator.pushNamed(
                                          context,
                                          isAwayGame
                                              ? '/additional-game-info-condensed'
                                              : '/additional-game-info',
                                          arguments: {
                                            'scheduleName': scheduleName,
                                            'sport': sport,
                                            'template': template,
                                            'date': selectedDate,
                                            'time': finalTime,
                                            'location': templateLocation,
                                            'isAwayGame': isAwayGame,
                                            'isAway': isAwayGame,
                                          },
                                        );
                                      } else {
                                        // Go to location selection as normal
                                        debugPrint(
                                            '📍 Going to location selection');
                                        Navigator.pushNamed(
                                          context,
                                          '/choose-location',
                                          arguments: {
                                            'scheduleName': scheduleName,
                                            'sport': sport,
                                            'template': template,
                                            'date': selectedDate,
                                            'time': finalTime,
                                          },
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedDate != null
                                    ? colorScheme.primary
                                    : colorScheme.surfaceVariant,
                                foregroundColor: selectedDate != null
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
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
                                  color: selectedDate != null
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
