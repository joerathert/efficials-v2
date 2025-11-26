import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';
import '../services/official_list_service.dart';

class AdditionalGameInfoScreen extends StatefulWidget {
  const AdditionalGameInfoScreen({super.key});

  @override
  State<AdditionalGameInfoScreen> createState() =>
      _AdditionalGameInfoScreenState();
}

class _AdditionalGameInfoScreenState extends State<AdditionalGameInfoScreen> {
  String? _levelOfCompetition;
  String? _gender;
  int? _officialsRequired;
  List<String> _currentGenders = ['Boys', 'Girls', 'Co-ed'];
  final TextEditingController _gameFeeController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  bool _hireAutomatically = false;
  bool _isFromEdit = false;
  bool _isInitialized = false;
  GameTemplateModel? template;
  final OfficialListService _listService = OfficialListService();

  final List<String> _competitionLevels = [
    '6U',
    '7U',
    '8U',
    '9U',
    '10U',
    '11U',
    '12U',
    '13U',
    '14U',
    '15U',
    '16U',
    '17U',
    '18U',
    'Grade School',
    'Middle School',
    'Underclass',
    'JV',
    'Varsity',
    'College',
    'Adult'
  ];
  final List<String> _youthGenders = ['Boys', 'Girls', 'Co-ed'];
  final List<String> _adultGenders = ['Men', 'Women', 'Co-ed'];
  final List<int> _officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  void _updateCurrentGenders() {
    if (_levelOfCompetition == null) {
      _currentGenders = _youthGenders;
    } else {
      _currentGenders =
          (_levelOfCompetition == 'College' || _levelOfCompetition == 'Adult')
              ? _adultGenders
              : _youthGenders;
    }
  }

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
    }
  }

  Future<void> _initializeAsync() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _isFromEdit = args['isEdit'] == true;

      template = args['template'] as GameTemplateModel?;
      debugPrint(
          '🎯 ADDITIONAL_GAME_INFO: Received template: ${template?.name}');
      debugPrint(
          '🎯 ADDITIONAL_GAME_INFO: Template includeLevelOfCompetition: ${template?.includeLevelOfCompetition}');
      debugPrint(
          '🎯 ADDITIONAL_GAME_INFO: Template levelOfCompetition: ${template?.levelOfCompetition}');
      debugPrint(
          '🎯 ADDITIONAL_GAME_INFO: Template includeGender: ${template?.includeGender}');
      debugPrint(
          '🎯 ADDITIONAL_GAME_INFO: Template gender: ${template?.gender}');

      // Pre-fill fields from the template if available, otherwise use args
      if (template != null) {
        _levelOfCompetition = template!.includeLevelOfCompetition &&
                template!.levelOfCompetition != null
            ? template!.levelOfCompetition
            : (args['levelOfCompetition'] as String?);
        _updateCurrentGenders();
        _gender = template!.includeGender && template!.gender != null
            ? template!.gender
            : (args['gender'] as String?);
        if (_gender != null && !_currentGenders.contains(_gender)) {
          _gender = null;
        }
        _officialsRequired = template!.includeOfficialsRequired &&
                template!.officialsRequired != null
            ? template!.officialsRequired
            : (args['officialsRequired'] != null
                ? int.tryParse(args['officialsRequired'].toString())
                : null);
        _gameFeeController.text =
            template!.includeGameFee && template!.gameFee != null
                ? template!.gameFee!
                : (args['gameFee']?.toString() ?? '');
        _hireAutomatically = template!.includeHireAutomatically &&
                template!.hireAutomatically != null
            ? template!.hireAutomatically!
            : (args['hireAutomatically'] as bool? ?? false);

        debugPrint('🎯 ADDITIONAL_GAME_INFO: Pre-filled values:');
        debugPrint('   - _levelOfCompetition: $_levelOfCompetition');
        debugPrint('   - _gender: $_gender');
        debugPrint('   - _officialsRequired: $_officialsRequired');
        debugPrint('   - _gameFeeController.text: ${_gameFeeController.text}');
        debugPrint('   - _hireAutomatically: $_hireAutomatically');
      } else {
        _levelOfCompetition = args['levelOfCompetition'] as String?;
        _updateCurrentGenders();
        _gender = args['gender'] as String?;
        _officialsRequired = args['officialsRequired'] != null
            ? int.tryParse(args['officialsRequired'].toString())
            : null;
        _gameFeeController.text = args['gameFee']?.toString() ?? '';
        _hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      }

      // Opponent field should only be populated from args during edit flow
      if (_isFromEdit) {
        _opponentController.text = args['opponent'] as String? ?? '';
      } else {
        _opponentController.text = '';
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _handleContinue() async {
    if (_levelOfCompetition == null ||
        _gender == null ||
        _officialsRequired == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select a level, gender, and number of officials')),
      );
      return;
    }
    final feeText = _gameFeeController.text.trim();
    if (feeText.isEmpty || !RegExp(r'^\d+(\.\d+)?$').hasMatch(feeText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid game fee (e.g., 50 or 50.00)')),
      );
      return;
    }
    final fee = double.parse(feeText);
    if (fee < 1 || fee > 99999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Game fee must be between 1 and 99,999')),
      );
      return;
    }

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    debugPrint('🎯 ADDITIONAL_GAME_INFO: Original homeTeam: ${args['homeTeam']}');

    final updatedArgs = {
      ...args,
      'id': args['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'levelOfCompetition': _levelOfCompetition,
      'gender': _gender,
      'officialsRequired': _officialsRequired,
      'gameFee': _gameFeeController.text.trim(),
      'opponent': _opponentController.text.trim(),
      'hireAutomatically': _hireAutomatically,
      'isAway': false,
      'officialsHired': args['officialsHired'] ?? 0,
      'selectedOfficials':
          args['selectedOfficials'] ?? <Map<String, dynamic>>[],
      'template': template,
    };

    debugPrint('🎯 ADDITIONAL_GAME_INFO: Updated homeTeam: ${updatedArgs['homeTeam']}');

    if (_isFromEdit) {
      // Check if officialsRequired has changed - if so, we need to reset selection method
      final originalOfficialsRequired = args['officialsRequired'];
      final officialsRequiredChanged = _officialsRequired != originalOfficialsRequired;

      if (officialsRequiredChanged) {
        debugPrint('🎯 ADDITIONAL_GAME_INFO: Officials required changed from $originalOfficialsRequired to $_officialsRequired, resetting selection method');

        // Clear any existing selection method data since it may no longer be valid
        updatedArgs.addAll({
          'method': null, // Reset to no method selected
          'selectedListName': null,
          'selectedLists': null,
          'selectedCrews': null,
          'selectedCrew': null,
          'selectedOfficials': [], // Clear any manually selected officials
        });
      }

      // When editing an existing game, return the updated data
      debugPrint('🎯 ADDITIONAL_GAME_INFO: Returning updated data for edit');
      Navigator.pop(context, updatedArgs);
    } else {
      // Check if template has pre-selected configuration - skip to review screen
      if (template != null &&
          template!.method == 'use_list' &&
          template!.officialsListName != null &&
          template!.officialsListName!.isNotEmpty) {
        debugPrint(
            '🎯 ADDITIONAL_GAME_INFO: Template has pre-selected list, fetching list data...');

        // Fetch all lists to find the one specified in the template
        _listService.fetchOfficialLists().then((lists) {
          final selectedList = lists.firstWhere(
            (list) => list['name'] == template!.officialsListName,
            orElse: () => <String, dynamic>{},
          );

          if (selectedList.isNotEmpty) {
            debugPrint(
                '✅ ADDITIONAL_GAME_INFO: Found list "${selectedList['name']}", navigating to review');

            final reviewArgs = {
              ...updatedArgs,
              'method': 'use_list',
              'selectedListName': template!.officialsListName,
              'selectedOfficials': selectedList['officials'] ?? [],
              'selectedList': selectedList,
            };

            if (mounted) {
              Navigator.pushNamed(
                context,
                '/review-game-info',
                arguments: reviewArgs,
              );
            }
          } else {
            debugPrint(
                '❌ ADDITIONAL_GAME_INFO: List "${template!.officialsListName}" not found');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Template list "${template!.officialsListName}" not found. Please select a list manually.')),
              );
              // Fall back to normal flow
              Navigator.pushNamed(
                context,
                '/select-officials',
                arguments: updatedArgs,
              );
            }
          }
        }).catchError((error) {
          debugPrint('❌ ADDITIONAL_GAME_INFO: Error fetching lists: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Error loading template list. Please select a list manually.')),
            );
            // Fall back to normal flow
            Navigator.pushNamed(
              context,
              '/select-officials',
              arguments: updatedArgs,
            );
          }
        });
      }
      // Check if template has pre-configured multiple lists - skip to review screen
      else if (template != null &&
          template!.method == 'advanced' &&
          template!.selectedLists != null &&
          template!.selectedLists!.isNotEmpty) {
        debugPrint(
            '🎯 ADDITIONAL_GAME_INFO: Template has pre-configured multiple lists, navigating to review');
        debugPrint('🎯 ADDITIONAL_GAME_INFO: Template method: ${template!.method}');
        debugPrint('🎯 ADDITIONAL_GAME_INFO: Template selectedLists: ${template!.selectedLists}');

        final reviewArgs = {
          ...updatedArgs,
          'method': 'advanced',
          'selectedLists': template!.selectedLists,
        };

        if (mounted) {
          Navigator.pushNamed(
            context,
            '/review-game-info',
            arguments: reviewArgs,
          );
        }
      }
      // Check if template has hire_crew method - skip to review screen
      else if (template != null &&
          template!.method == 'hire_crew' &&
          template!.selectedCrews != null &&
          template!.selectedCrews!.isNotEmpty) {
        debugPrint(
            '🎯 ADDITIONAL_GAME_INFO: Template has pre-selected crew, navigating to review');
        debugPrint('🎯 ADDITIONAL_GAME_INFO: Template method: ${template!.method}');
        debugPrint('🎯 ADDITIONAL_GAME_INFO: Template selectedCrews: ${template!.selectedCrews}');

        final reviewArgs = {
          ...updatedArgs,
          'method': 'hire_crew',
          'selectedCrews': template!.selectedCrews,
          'selectedCrew': template!.selectedCrews!.first,
        };

        if (mounted) {
          Navigator.pushNamed(
            context,
            '/review-game-info',
            arguments: reviewArgs,
          );
        }
      } else {
        // Normal game creation flow
        debugPrint(
            '🎯 ADDITIONAL_GAME_INFO: No pre-selected template, navigating to select officials');
        debugPrint(
            '🎯 ADDITIONAL_GAME_INFO: Template method: ${template?.method}');
        debugPrint(
            '🎯 ADDITIONAL_GAME_INFO: Template includeOfficialsList: ${template?.includeOfficialsList}');
        debugPrint(
            '🎯 ADDITIONAL_GAME_INFO: Template officialsListName: ${template?.officialsListName}');

        Navigator.pushNamed(
          context,
          '/select-officials',
          arguments: updatedArgs,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    _updateCurrentGenders();
    if (_gender != null && !_currentGenders.contains(_gender)) {
      _gender = null;
    }

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
              onPressed: () {
                // Navigate to Athletic Director home screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/ad-home',
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Additional Game Info',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary
                            : colorScheme.onSurface,
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
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Level of competition',
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
                                value: _levelOfCompetition,
                                hint: Text(
                                  'Level of competition',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                                dropdownColor: colorScheme.surface,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _levelOfCompetition = value;
                                    _updateCurrentGenders();
                                    if (_gender != null &&
                                        !_currentGenders.contains(_gender)) {
                                      _gender = null;
                                    }
                                  });
                                },
                                items: _competitionLevels
                                    .map((level) => DropdownMenuItem(
                                          value: level,
                                          child: Text(level),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Gender',
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
                                value: _gender,
                                hint: Text(
                                  'Select gender',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                                dropdownColor: colorScheme.surface,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                onChanged: (value) =>
                                    setState(() => _gender = value),
                                items: _currentGenders
                                    .map((gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Required number of officials',
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
                                  'Required number of officials',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant),
                                ),
                                dropdownColor: colorScheme.surface,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                onChanged: (value) =>
                                    setState(() => _officialsRequired = value),
                                items: _officialsOptions
                                    .map((num) => DropdownMenuItem(
                                          value: num,
                                          child: Text(num.toString()),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: TextField(
                                controller: _gameFeeController,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Game Fee per Official',
                                  labelStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  prefixText: '\$',
                                  prefixStyle: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 16,
                                  ),
                                  hintText: 'Enter fee (e.g., 50 or 50.00)',
                                  hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant),
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
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]')),
                                  LengthLimitingTextInputFormatter(
                                      7), // Allow for "99999.99"
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: TextField(
                                controller: _opponentController,
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Opponent',
                                  labelStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  hintText: 'Team Name and Mascot',
                                  hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant),
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
                                keyboardType: TextInputType.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Enter your opponent\'s team name and mascot. Ex - "Greenville Lancers"',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 400,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameFeeController.dispose();
    _opponentController.dispose();
    super.dispose();
  }
}
