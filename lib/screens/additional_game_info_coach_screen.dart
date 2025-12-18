import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';
import '../services/game_service.dart';
import '../services/official_list_service.dart';

class AdditionalGameInfoCoachScreen extends StatefulWidget {
  const AdditionalGameInfoCoachScreen({super.key});

  @override
  State<AdditionalGameInfoCoachScreen> createState() =>
      _AdditionalGameInfoCoachScreenState();
}

class _AdditionalGameInfoCoachScreenState
    extends State<AdditionalGameInfoCoachScreen> {
  int? _officialsRequired;
  final TextEditingController _gameFeeController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  bool _hireAutomatically = false;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  GameTemplateModel? template;
  final OfficialListService _listService = OfficialListService();
  final GameService _gameService = GameService();

  final List<int> _officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  void _showHireInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Hire Automatically',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'When checked, the system will automatically assign officials based on your preferences and availability. Uncheck to manually select officials.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeAsync();
      _isInitialized = true;
    }
  }

  Future<void> _initializeAsync() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      template = args['template'] as GameTemplateModel?;
      _isFromEdit = args['isFromGameInfo'] as bool? ?? false;

      // Pre-populate from template if available
      if (template != null) {
        if (template!.includeOfficialsRequired) {
          _officialsRequired = template!.officialsRequired;
        }
        if (template!.includeGameFee) {
          _gameFeeController.text = template!.gameFee?.toString() ?? '';
        }
        if (template!.includeOpponent) {
          _opponentController.text = template!.opponent ?? '';
        }
        if (template!.includeHireAutomatically) {
          _hireAutomatically = template!.hireAutomatically ?? false;
        }
      }

      // Pre-populate from edit arguments if editing
      if (_isFromEdit) {
        _officialsRequired = args['officialsRequired'] as int?;
        _gameFeeController.text = args['gameFee']?.toString() ?? '';
        _opponentController.text = args['opponent']?.toString() ?? '';
        _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      }

      setState(() {});
    }
  }

  @override
  void dispose() {
    _gameFeeController.dispose();
    _opponentController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;

    try {
      // Get or create schedule for coach
      final scheduleName = args['scheduleName'] as String?;
      final sport = args['sport'] as String?;

      if (scheduleName == null || sport == null) {
        throw Exception('Schedule name and sport are required for coach games');
      }

      // Get all schedules for the current user
      final schedules = await _gameService.getSchedules();
      debugPrint(
          '🏆 COACH GAME CREATION: Found ${schedules.length} schedules for user');

      // Find existing schedule with matching name
      String? scheduleId;
      final existingSchedule = schedules.firstWhere(
        (schedule) => schedule['name'] == scheduleName,
        orElse: () => <String, dynamic>{},
      );

      if (existingSchedule.isNotEmpty) {
        scheduleId = existingSchedule['id'] as String?;
        debugPrint(
            '🏆 COACH GAME CREATION: Found existing schedule: $scheduleId');
      } else {
        // Create new schedule for coach
        debugPrint(
            '🏆 COACH GAME CREATION: Creating new schedule for team: $scheduleName');
        final newSchedule = await _gameService.createSchedule(
          scheduleName,
          sport,
          homeTeamName: scheduleName, // Use team name as home team
        );
        scheduleId = newSchedule['id'] as String?;
        debugPrint('🏆 COACH GAME CREATION: Created new schedule: $scheduleId');
      }

      if (scheduleId == null) {
        throw Exception('Failed to get or create schedule for coach');
      }

      final gameData = {
        'scheduleName': scheduleName,
        'scheduleId': scheduleId,
        'sport': sport,
        'homeTeam': args['homeTeam'] as String?,
        'date': args['date'] as DateTime?,
        'time': args['time'] as TimeOfDay?,
        'location': args['location'] as Map<String, dynamic>?,
        'isAwayGame': args['isAwayGame'] as bool? ?? false,
        'isAway': args['isAway'] as bool? ?? false,
        'officialsRequired': _officialsRequired,
        'gameFee': double.tryParse(_gameFeeController.text.trim()),
        'opponent': _opponentController.text.trim().isEmpty
            ? null
            : _opponentController.text.trim(),
        'hireAutomatically': _hireAutomatically,
        'sourceScreen': 'coach_home',
      };

      debugPrint('🏆 COACH GAME CREATION: Creating game with data: $gameData');
      debugPrint(
          '🏆 COACH GAME CREATION: scheduleName: ${gameData['scheduleName']}');
      debugPrint(
          '🏆 COACH GAME CREATION: date: ${gameData['date']} (type: ${gameData['date']?.runtimeType})');

      final success = await _gameService.saveUnpublishedGame(gameData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate based on hire automatically preference
        final gameArgs = {
          ...args,
          'scheduleName': scheduleName,
          'scheduleId': scheduleId,
          'sport': sport,
          'homeTeam': scheduleName, // Coach's team name
          'officialsRequired': _officialsRequired,
          'gameFee': double.tryParse(_gameFeeController.text.trim()),
          'opponent': _opponentController.text.trim().isEmpty
              ? null
              : _opponentController.text.trim(),
          'hireAutomatically': _hireAutomatically,
          'sourceScreen': 'coach_home',
        };

        if (_hireAutomatically) {
          // Skip select officials and go directly to review with automatic hiring
          Navigator.pushNamed(
            context,
            '/review-game-info',
            arguments: {
              ...gameArgs,
              'method': 'hire_automatically',
              'selectedOfficials': [], // No specific officials selected
            },
          );
        } else {
          // Go to select officials screen for manual selection
          Navigator.pushNamed(
            context,
            '/select-officials',
            arguments: gameArgs,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create game. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ COACH GAME CREATION: Error creating game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                Icons.sports,
                color: themeProvider.isDarkMode
                    ? colorScheme.primary
                    : Colors.black,
                size: 32,
              ),
              onPressed: () async {
                // Navigate to coach home
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/coach-home',
                  (route) => false,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Game Details',
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
                      'Add final details for your game',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Officials Required Dropdown
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Officials Required',
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
                      value: _officialsRequired,
                      hint: Text(
                        'Select number of officials',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      dropdownColor: colorScheme.surface,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      items: _officialsOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child:
                              Text('$option official${option > 1 ? 's' : ''}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _officialsRequired = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Game Fee Field
                    TextFormField(
                      controller: _gameFeeController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Game Fee per Official',
                        hintText: 'e.g., 75.00',
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
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 20),

                    // Opponent Field
                    TextFormField(
                      controller: _opponentController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Opponent',
                        hintText: 'e.g., Lincoln High School',
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
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 20),

                    // Hire Automatically Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _hireAutomatically,
                          onChanged: (value) => setState(
                              () => _hireAutomatically = value ?? false),
                          activeColor: colorScheme.primary,
                          checkColor: colorScheme.onPrimary,
                        ),
                        Text(
                          'Hire Automatically',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        IconButton(
                          icon: Icon(Icons.help_outline,
                              color: colorScheme.primary),
                          onPressed: _showHireInfoDialog,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Create Game Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_officialsRequired != null &&
                                _gameFeeController.text.trim().isNotEmpty &&
                                double.tryParse(
                                        _gameFeeController.text.trim()) !=
                                    null &&
                                _opponentController.text.trim().isNotEmpty)
                            ? _createGame
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_officialsRequired != null &&
                                  _gameFeeController.text.trim().isNotEmpty &&
                                  double.tryParse(
                                          _gameFeeController.text.trim()) !=
                                      null &&
                                  _opponentController.text.trim().isNotEmpty)
                              ? colorScheme.primary
                              : colorScheme.surfaceVariant,
                          foregroundColor: (_officialsRequired != null &&
                                  _gameFeeController.text.trim().isNotEmpty &&
                                  double.tryParse(
                                          _gameFeeController.text.trim()) !=
                                      null &&
                                  _opponentController.text.trim().isNotEmpty)
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Create Game',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
