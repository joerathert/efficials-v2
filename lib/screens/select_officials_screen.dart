import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';

class SelectOfficialsScreen extends StatefulWidget {
  const SelectOfficialsScreen({super.key});

  @override
  State<SelectOfficialsScreen> createState() => _SelectOfficialsScreenState();
}

class _SelectOfficialsScreenState extends State<SelectOfficialsScreen> {
  bool _defaultChoice = false;
  GameTemplateModel? template;
  List<Map<String, dynamic>> _selectedOfficials = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      template = args['template'] as GameTemplateModel?;

      // Check for template with crew selection first
      if (template != null &&
          template!.method == 'hire_crew' &&
          template!.selectedCrews != null &&
          template!.selectedCrews!.isNotEmpty) {
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
          template!.selectedOfficials!.isNotEmpty) {
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

  void _showInsufficientListsDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Baseball';

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
          'The Advanced method requires at least two lists of officials. Would you like to create a new list?',
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
              // TODO: Navigate to create list screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Create list functionality not yet implemented for $sport',
                  ),
                ),
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
      backgroundColor: colorScheme.surface,
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
                                    // Navigate to review screen with selected officials
                                    Navigator.pushNamed(
                                      context,
                                      '/review-game-info',
                                      arguments: result,
                                    );
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
                              onPressed: () {
                                // Check if user has enough lists for advanced method
                                // For now, just show insufficient lists dialog
                                _showInsufficientListsDialog();
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
                                  '/select_crew',
                                  arguments: <String, dynamic>{
                                    ...?args,
                                    'sport': sport,
                                    'method': 'hire_crew',
                                    'template': template,
                                  },
                                );
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
