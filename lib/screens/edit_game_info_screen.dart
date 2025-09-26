import 'package:flutter/material.dart';
import '../widgets/standard_button.dart';

class EditGameInfoScreen extends StatefulWidget {
  const EditGameInfoScreen({super.key});

  @override
  State<EditGameInfoScreen> createState() => _EditGameInfoScreenState();
}

class _EditGameInfoScreenState extends State<EditGameInfoScreen> {
  late Map<String, dynamic> args;
  bool _isAwayGame = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final newArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (newArgs != null) {
        args = newArgs;
        _isAwayGame =
            args['isAway'] as bool? ?? args['isAwayGame'] as bool? ?? false;
      }
      _isInitialized = true;
    }
  }

  void _handleEditOfficials(Map<String, dynamic> args) {
    final method = args['method'] as String? ?? 'standard';

    debugPrint('🎯 EDIT OFFICIALS: Method detected: $method');

    switch (method) {
      case 'use_list':
        // Single list was used - navigate to lists of officials screen
        debugPrint(
            '📋 EDIT OFFICIALS: Single list method - navigating to lists screen');
        Navigator.pushNamed(context, '/lists-of-officials', arguments: {
          ...args,
          'isEdit': true,
          'isFromGameInfo': args['isFromGameInfo'] ?? false,
          'fromGameCreation': false, // Not creating a new game
        }).then((result) {
          if (result != null && mounted) {
            final updatedArgs = result as Map<String, dynamic>;
            final finalArgs = {
              ...updatedArgs,
              'isEdit': true,
              'isFromGameInfo': args['isFromGameInfo'] ?? false,
            };
            Navigator.pop(context, finalArgs);
          }
        });
        break;

      case 'advanced':
        // Multiple lists were used - advanced method setup screen (not implemented yet)
        debugPrint(
            '🔧 EDIT OFFICIALS: Advanced method - showing coming soon message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Advanced method editing coming soon!'),
            duration: Duration(seconds: 3),
          ),
        );
        break;

      case 'standard':
      default:
        // Standard method was used
        debugPrint(
            '👥 EDIT OFFICIALS: Standard method - showing coming soon message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Standard method editing coming soon!'),
            duration: Duration(seconds: 3),
          ),
        );
        break;
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
        title: Icon(
          Icons.sports,
          color: colorScheme.primary,
          size: 32,
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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Edit Game Info',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            StandardButton(
                              text: 'Location',
                              onPressed: () {
                                Navigator.pushNamed(context, '/choose-location',
                                    arguments: {
                                      ...args,
                                      'isEdit': true,
                                      'isFromGameInfo':
                                          args['isFromGameInfo'] ?? false,
                                      // Ensure we preserve all existing args
                                      'opponent': args['opponent'] ?? '',
                                      'levelOfCompetition':
                                          args['levelOfCompetition'],
                                      'gender': args['gender'],
                                      'officialsRequired':
                                          args['officialsRequired'],
                                      'gameFee': args['gameFee'],
                                      'hireAutomatically':
                                          args['hireAutomatically'],
                                      'selectedOfficials':
                                          args['selectedOfficials'],
                                      'method': args['method'],
                                      'selectedListName':
                                          args['selectedListName'],
                                      'selectedLists': args['selectedLists'],
                                    }).then((result) {
                                  if (result != null) {
                                    final updatedArgs =
                                        result as Map<String, dynamic>;
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/review_game_info',
                                      arguments: {
                                        ...updatedArgs,
                                        'isEdit': true,
                                        'isFromGameInfo':
                                            args['isFromGameInfo'] ?? false,
                                      },
                                    );
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            StandardButton(
                              text: 'Date/Time',
                              onPressed: () {
                                Navigator.pushNamed(context, '/date-time',
                                    arguments: {
                                      ...args,
                                      'isEdit': true,
                                      'isFromGameInfo':
                                          args['isFromGameInfo'] ?? false,
                                    }).then((result) {
                                  if (result != null) {
                                    final updatedArgs =
                                        result as Map<String, dynamic>;
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/review_game_info',
                                      arguments: {
                                        ...updatedArgs,
                                        'isEdit': true,
                                        'isFromGameInfo':
                                            args['isFromGameInfo'] ?? false,
                                      },
                                    );
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            StandardButton(
                              text: 'Additional Game Info',
                              onPressed: () {
                                // Check if this is an Away Game or a coach flow
                                final isCoach = args['teamName'] != null;
                                final isAway = args['isAway'] == true ||
                                    args['isAwayGame'] == true;
                                final route = (isCoach || isAway)
                                    ? '/additional-game-info-condensed'
                                    : '/additional-game-info';

                                Navigator.pushNamed(context, route, arguments: {
                                  ...args,
                                  'isEdit': true,
                                  'isFromGameInfo':
                                      args['isFromGameInfo'] ?? false,
                                  // Ensure consistent away game flags
                                  'isAwayGame': isAway,
                                  'isAway': isAway,
                                }).then((result) {
                                  if (result != null) {
                                    final updatedArgs =
                                        result as Map<String, dynamic>;
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/review_game_info',
                                      arguments: {
                                        ...updatedArgs,
                                        'isEdit': true,
                                        'isFromGameInfo':
                                            args['isFromGameInfo'] ?? false,
                                      },
                                    );
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            StandardButton(
                              text: 'Selection Method',
                              onPressed: _isAwayGame
                                  ? null // Disable for away games
                                  : () {
                                      Navigator.pushNamed(
                                          context, '/select-officials',
                                          arguments: {
                                            ...args,
                                            'isEdit': true,
                                            'isFromGameInfo':
                                                args['isFromGameInfo'] ?? false,
                                          }).then((result) {
                                        if (result != null) {
                                          final updatedArgs =
                                              result as Map<String, dynamic>;
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/review_game_info',
                                            arguments: {
                                              ...updatedArgs,
                                              'isEdit': true,
                                              'isFromGameInfo':
                                                  args['isFromGameInfo'] ??
                                                      false,
                                            },
                                          );
                                        }
                                      });
                                    },
                            ),
                            const SizedBox(height: 20),
                            StandardButton(
                              text: 'Selected Officials',
                              onPressed: _isAwayGame
                                  ? null // Disable for away games
                                  : () => _handleEditOfficials(args),
                            ),
                            const SizedBox(height: 20),
                          ],
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
    );
  }
}
