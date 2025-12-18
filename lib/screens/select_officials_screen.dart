import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';
import '../services/official_list_service.dart';

class SelectOfficialsScreen extends StatefulWidget {
  const SelectOfficialsScreen({super.key});

  @override
  State<SelectOfficialsScreen> createState() => _SelectOfficialsScreenState();
}

class _SelectOfficialsScreenState extends State<SelectOfficialsScreen> {
  bool _defaultChoice = false;
  bool _isFromEdit = false;
  GameTemplateModel? template;
  List<Map<String, dynamic>> _selectedOfficials = [];
  final OfficialListService _listService = OfficialListService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      template = args['template'] as GameTemplateModel?;
      _isFromEdit = args['isEdit'] == true || args['isFromGameInfo'] == true;

      debugPrint('🎯 SELECT_OFFICIALS: Received template: ${template?.name}');
      debugPrint('🎯 SELECT_OFFICIALS: Template method: ${template?.method}');
      debugPrint(
          '🎯 SELECT_OFFICIALS: Template includeOfficialsList: ${template?.includeOfficialsList}');
      debugPrint(
          '🎯 SELECT_OFFICIALS: Template officialsListName: ${template?.officialsListName}');

      // Check for template with crew selection first
      if (template != null &&
          template!.method == 'hire_crew' &&
          template!.selectedCrews != null &&
          template!.selectedCrews!.isNotEmpty &&
          !_isFromEdit) {
        // Only auto-navigate if not in edit mode
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/review_game_info',
              arguments: <String, dynamic>{
                ...args,
                'method': 'hire_crew',
                'selectedCrews': template!.selectedCrews,
                'selectedCrew': template!.selectedCrews!.first,
                'template': template,
              },
            );
          }
        });
      }
      // If the template includes an officials list, pre-fill the selection and navigate
      else if (template != null &&
          template!.includeSelectedOfficials &&
          template!.selectedOfficials != null &&
          template!.selectedOfficials!.isNotEmpty &&
          !_isFromEdit) {
        // Only auto-navigate if not in edit mode
        setState(() {
          _selectedOfficials = template!.selectedOfficials!;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/review_game_info',
              arguments: <String, dynamic>{
                ...args,
                'method': 'use_list',
                'selectedOfficials': _selectedOfficials,
                'template': template,
              },
            );
          }
        });
      }
      // If the template uses single list method, navigate directly to review
      else if (template != null &&
          template!.method == 'use_list' &&
          template!.officialsListName != null &&
          template!.officialsListName!.isNotEmpty &&
          !_isFromEdit) {
        // Only auto-navigate if not in edit mode
        debugPrint(
            '🎯 SELECT_OFFICIALS: Single list template routing triggered!');
        debugPrint('🎯 SELECT_OFFICIALS: Template method: ${template!.method}');
        debugPrint(
            '🎯 SELECT_OFFICIALS: Template officialsListName: ${template!.officialsListName}');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/review_game_info',
              arguments: <String, dynamic>{
                ...args,
                'method': 'use_list',
                'selectedListName': template!.officialsListName,
                'template': template,
              },
            );
          }
        });
      }
      // If the template uses multiple lists method with pre-configured lists, navigate directly to review
      else if (template != null &&
          template!.method == 'advanced' &&
          template!.selectedLists != null &&
          template!.selectedLists!.isNotEmpty &&
          !_isFromEdit) {
        // Only auto-navigate if not in edit mode
        debugPrint(
            '🎯 SELECT_OFFICIALS: Multiple lists template with pre-configured lists - routing to review!');
        debugPrint('🎯 SELECT_OFFICIALS: Template method: ${template!.method}');
        debugPrint(
            '🎯 SELECT_OFFICIALS: Template selectedLists: ${template!.selectedLists}');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/review_game_info',
              arguments: <String, dynamic>{
                ...args,
                'method': 'advanced',
                'selectedLists': template!.selectedLists,
                'template': template,
              },
            );
          }
        });
      }
      // If the template uses multiple lists method but no pre-configured lists, go to setup
      else if (template != null &&
          template!.method == 'advanced' &&
          !_isFromEdit) {
        // Only auto-navigate if not in edit mode
        debugPrint(
            '🎯 SELECT_OFFICIALS: Multiple lists template without pre-configured lists - routing to setup!');
        debugPrint('🎯 SELECT_OFFICIALS: Template method: ${template!.method}');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/multiple-lists-setup',
              arguments: <String, dynamic>{
                ...args,
                'sport': args['sport'] ?? 'Football',
                'template': template,
                'preSelectedLists': template!.selectedLists,
              },
            );
          }
        });
      }
    }
  }

  void _showDifferenceDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Selection Methods',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '• Single List: Select all officials from one saved list\n\n• Multiple Lists: Combine and filter across multiple saved lists\n\n• Hire a Crew: Select an entire pre-formed crew',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<int> _getListsCountForSport(String sport) async {
    try {
      // For now, return a mock count - in a real implementation,
      // this would query the database for lists of the specific sport
      final allLists = await _listService.fetchOfficialLists();
      // Filter lists by sport - this is a simplified implementation
      final sportLists = allLists.where((list) {
        final listSport = list['sport'] as String?;
        return listSport == null || listSport.isEmpty || listSport == sport;
      }).toList();
      return sportLists.length;
    } catch (e) {
      debugPrint('Error getting lists count for sport $sport: $e');
      return 0;
    }
  }

  void _showInsufficientListsDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown Sport';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Insufficient Lists',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'The Multiple Lists method requires at least two lists of officials for $sport. Would you like to create a new list?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to lists screen to create new list
              Navigator.pushNamed(
                context,
                '/lists-of-officials',
                arguments: {
                  'sport': sport,
                  'fromGameCreation': false,
                  'fromTemplateCreation': false,
                  'fromInsufficientLists': true,
                  'gameArgs': args, // Pass the game creation context
                },
              );
            },
            child: Text(
              'Create List',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Baseball';

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
                // Navigate to appropriate home screen based on user type
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                final sourceScreen = args?['sourceScreen'] as String?;
                final homeRoute =
                    sourceScreen == 'coach_home' ? '/coach-home' : '/ad-home';

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Select Officials',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
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
                          Text(
                            'Choose a method for finding your officials.',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: 250,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to Lists of Officials screen
                                Navigator.pushNamed(
                                  context,
                                  '/lists-of-officials',
                                  arguments: <String, dynamic>{
                                    ...?args,
                                    'sport': sport,
                                    'fromGameCreation': true,
                                    'template': template,
                                  },
                                ).then((result) {
                                  if (result != null && mounted) {
                                    if (_isFromEdit) {
                                      // Return result to calling screen (game_information_screen)
                                      Navigator.pop(context, result);
                                    } else {
                                      // Navigate to review screen with selected officials
                                      Navigator.pushNamed(
                                        context,
                                        '/review-game-info',
                                        arguments: result,
                                      );
                                    }
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Single List',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 250,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () async {
                                // Check if user has enough lists for multiple lists method
                                final listsCount =
                                    await _getListsCountForSport(sport);
                                if (listsCount >= 2) {
                                  // Navigate to Multiple Lists setup screen
                                  Navigator.pushNamed(
                                    context,
                                    '/multiple-lists-setup',
                                    arguments: <String, dynamic>{
                                      ...?args,
                                      'sport': sport,
                                    },
                                  ).then((result) {
                                    if (result != null && mounted) {
                                      if (_isFromEdit) {
                                        // Return result to calling screen (game_information_screen)
                                        Navigator.pop(context, result);
                                      } else {
                                        // Navigate to review screen with multiple lists configuration
                                        Navigator.pushNamed(
                                          context,
                                          '/review-game-info',
                                          arguments: result,
                                        );
                                      }
                                    }
                                  });
                                } else {
                                  // Show insufficient lists dialog
                                  _showInsufficientListsDialog();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Multiple Lists',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 250,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to hire crew
                                Navigator.pushNamed(
                                  context,
                                  '/select_crew_screen',
                                  arguments: <String, dynamic>{
                                    ...?args,
                                    'sport': sport,
                                    'method': 'hire_crew',
                                    'template': template,
                                  },
                                ).then((result) {
                                  if (result != null && mounted) {
                                    if (_isFromEdit) {
                                      // Return result to calling screen (game_information_screen)
                                      Navigator.pop(context, result);
                                    } else {
                                      // Navigate to review screen with crew selection
                                      Navigator.pushNamed(
                                        context,
                                        '/review-game-info',
                                        arguments: result,
                                      );
                                    }
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Hire a Crew',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _showDifferenceDialog,
                            child: Text(
                              'What\'s the difference?',
                              style: TextStyle(
                                color: colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _defaultChoice,
                                onChanged: (value) => setState(
                                    () => _defaultChoice = value ?? false),
                                activeColor: colorScheme.primary,
                                checkColor: colorScheme.onPrimary,
                              ),
                              Text(
                                'Make this my default choice',
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            ],
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
