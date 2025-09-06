import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/game_service.dart';

class NameScheduleScreen extends StatefulWidget {
  const NameScheduleScreen({super.key});

  @override
  State<NameScheduleScreen> createState() => _NameScheduleScreenState();
}

class _NameScheduleScreenState extends State<NameScheduleScreen> {
  final TextEditingController _scheduleNameController = TextEditingController();
  String? selectedSport;
  bool _isLoading = false;
  List<String> existingScheduleNames = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the sport from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['sport'] != null) {
      selectedSport = args['sport'] as String?;
    }

    // Load existing schedule names for validation
    _loadExistingScheduleNames();
  }

  Future<void> _loadExistingScheduleNames() async {
    try {
      final gameService = GameService();
      final schedules = await gameService.getSchedules();
      setState(() {
        existingScheduleNames =
            schedules.map((schedule) => schedule['name'] as String).toList();
      });
    } catch (e) {
      // If we can't load existing schedules, we'll just proceed without validation
      print('Could not load existing schedule names: $e');
    }
  }

  @override
  void dispose() {
    _scheduleNameController.dispose();
    super.dispose();
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
                'Name Your Schedule',
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
                selectedSport != null
                    ? 'Create a schedule name for $selectedSport'
                    : 'Create a schedule name',
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
                  children: [
                    TextFormField(
                      controller: _scheduleNameController,
                      decoration: InputDecoration(
                        labelText: 'Schedule Name',
                        hintText: 'e.g., Varsity Basketball',
                        labelStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        errorText: existingScheduleNames.contains(
                                    _scheduleNameController.text.trim()) &&
                                _scheduleNameController.text.trim().isNotEmpty
                            ? 'A schedule with this name already exists'
                            : null,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _scheduleNameController.text.trim().isNotEmpty &&
                        !_isLoading &&
                        !existingScheduleNames
                            .contains(_scheduleNameController.text.trim())
                    ? () async {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final gameService = GameService();
                          final scheduleName =
                              _scheduleNameController.text.trim();

                          // Save the schedule to Firebase
                          final newSchedule = await gameService.createSchedule(
                            scheduleName,
                            selectedSport ?? 'Unknown',
                          );

                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });

                            // Navigate directly back to SelectScheduleScreen with the new schedule
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/select-schedule',
                              (route) =>
                                  route.settings.name ==
                                  '/athletic-director-home',
                              arguments: newSchedule,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error creating schedule: $e')),
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: Colors.grey[600],
                  disabledForegroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 50,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Create Schedule',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
