import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class NameListScreen extends StatefulWidget {
  const NameListScreen({super.key});

  @override
  State<NameListScreen> createState() => _NameListScreenState();
}

class _NameListScreenState extends State<NameListScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final creatingSecondList = args?['creatingSecondList'] as bool? ?? false;

      debugPrint('🎯 NameListScreen: RECEIVED ARGS:');
      debugPrint('🎯 NameListScreen: - fromInsufficientLists: ${args?['fromInsufficientLists']}');
      debugPrint('🎯 NameListScreen: - gameArgs present: ${args?['gameArgs'] != null}');
      debugPrint('🎯 NameListScreen: - all keys: ${args?.keys.toList()}');

      if (creatingSecondList) {
        _showSecondListExplanationDialog();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSecondListExplanationDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Creating Second List',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You need at least two lists to use the Multiple Lists method. Create your second list here, then you\'ll be able to use Multiple Lists to combine and filter across both lists.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
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
    String? sport = args?['sport'] as String?;
    final existingLists = args?['existingLists'] as List<String>? ?? [];
    final fromListsScreen = args?['fromListsScreen'] == true;

    // If no sport is provided and we're coming from lists screen, this shouldn't happen
    // but provide a fallback just in case
    if (sport == null && fromListsScreen) {
      sport = 'Football'; // Default fallback
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
        elevation: 0,
        centerTitle: true,
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
                      'Name List',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary
                            : colorScheme.onSurface,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            sport != null && sport != 'Unknown Sport'
                                ? 'Name your list of $sport officials'
                                : 'Name your list of officials',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText:
                                  sport != null && sport != 'Unknown Sport'
                                      ? 'Ex. Varsity $sport Officials'
                                      : 'Ex. Varsity Football Officials',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 400,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Please enter a list name!'),
                                backgroundColor: colorScheme.surfaceVariant,
                              ),
                            );
                          } else if (existingLists.contains(name)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text('List name must be unique!'),
                                backgroundColor: colorScheme.surfaceVariant,
                              ),
                            );
                          } else if (RegExp(r'^\s+$').hasMatch(name)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'List name cannot be just spaces!'),
                                backgroundColor: colorScheme.surfaceVariant,
                              ),
                            );
                          } else {
                            final populateArgs = {
                              'sport': sport,
                              'listName': name,
                              'fromGameCreation': true,
                              // Pass through ALL game creation context
                              ...?args,
                              // Explicitly exclude selectedOfficials to start with clean slate
                              'selectedOfficials': null,
                            };

                            debugPrint('🎯 NameListScreen: CREATING POPULATE ARGS:');
                            debugPrint('🎯 NameListScreen: - args fromInsufficientLists: ${args?['fromInsufficientLists']}');
                            debugPrint('🎯 NameListScreen: - args gameArgs present: ${args?['gameArgs'] != null}');
                            debugPrint('🎯 NameListScreen: - populateArgs keys: ${populateArgs.keys.toList()}');
                            debugPrint('🎯 NameListScreen: - populateArgs[fromInsufficientLists]: ${populateArgs['fromInsufficientLists']}');
                            debugPrint('🎯 NameListScreen: - populateArgs[gameArgs]: ${populateArgs['gameArgs']}');

                            Navigator.pushNamed(
                              context,
                              '/populate-roster',
                              arguments: populateArgs,
                            ).then((result) {
                              if (result != null && mounted) {
                                // Pass the result back to the lists screen
                                Navigator.pop(context, result);
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
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
      ),
    );
  }
}
