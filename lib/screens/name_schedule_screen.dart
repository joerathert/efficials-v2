import 'package:flutter/material.dart';
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
    final scheduleName = _scheduleNameController.text.trim();
    final isValidName = scheduleName.isNotEmpty &&
        !existingScheduleNames.contains(scheduleName);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: IconButton(
          icon: Icon(
            Icons.sports,
            color: theme.brightness == Brightness.dark
                ? colorScheme.primary
                : Colors.black,
            size: 32,
          ),
          onPressed: () {
            // Navigate to Athletic Director home screen
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/ad-home',
              (route) => false, // Remove all routes
            );
          },
          tooltip: 'Home',
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Enter schedule details',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _scheduleNameController,
                          decoration: InputDecoration(
                            labelText: 'Schedule Name',
                            hintText: 'e.g., Varsity Basketball',
                            labelStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            errorText:
                                existingScheduleNames.contains(scheduleName) &&
                                        scheduleName.isNotEmpty
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
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.red,
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
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 400,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isValidName ? _createSchedule : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValidName
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant,
                        foregroundColor: isValidName
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Create Schedule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isValidName
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createSchedule() async {
    if (_scheduleNameController.text.trim().isEmpty ||
        existingScheduleNames.contains(_scheduleNameController.text.trim())) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final gameService = GameService();
      final scheduleName = _scheduleNameController.text.trim();

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
          (route) => route.settings.name == '/athletic-director-home',
          arguments: newSchedule,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating schedule: $e')),
        );
      }
    }
  }
}
