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
    debugPrint('🎯 UPDATE LISTS: Opening lists screen for editing');

    // Always route to lists screen for editing lists, regardless of original method
    final routeArgs = {
      ...args,
      'isEdit': true,
      'isFromGameInfo': args['isFromGameInfo'] ?? false,
      'fromGameCreation': false, // Not creating a new game
    };

    debugPrint('🎯 UPDATE LISTS: Routing to lists screen');

    Navigator.pushNamed(context, '/lists-of-officials', arguments: routeArgs).then((result) {
      if (result != null && mounted) {
        final updatedArgs = result as Map<String, dynamic>;
        final finalArgs = {
          ...updatedArgs,
          'isEdit': true,
          'isFromGameInfo': args['isFromGameInfo'] ?? false,
        };

        debugPrint('🎯 UPDATE LISTS: Received result, returning to game info screen');

        // For edits from Game Information screen, return the updated args
        // so that the Game Information screen can reload fresh data from database
        Navigator.pop(context, finalArgs);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                  Container(
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
                                  debugPrint('🎯 EDIT_GAME_INFO: Received result from choose_location: $result');
                                  if (result != null) {
                                    final updatedArgs =
                                        result as Map<String, dynamic>;
                                    debugPrint('🎯 EDIT_GAME_INFO: Location from choose_location: ${updatedArgs['location']}');
                                    final finalArgs = {
                                      ...updatedArgs,
                                      'isEdit': true,
                                      'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                    };
                                    debugPrint('🎯 EDIT_GAME_INFO: Popping with final location: ${finalArgs['location']}');
                                    Navigator.pop(context, finalArgs);
                                  } else {
                                    debugPrint('🎯 EDIT_GAME_INFO: No result from choose_location');
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
                                  debugPrint('🎯 EDIT_GAME_INFO: Received result from date-time: $result');
                                  if (result != null) {
                                    final updatedArgs = result as Map<String, dynamic>;
                                    debugPrint('🎯 EDIT_GAME_INFO: Updated date: ${updatedArgs['date']}, time: ${updatedArgs['time']}');
                                    final finalArgs = {
                                      ...updatedArgs,
                                      'isEdit': true,
                                      'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                    };
                                    debugPrint('🎯 EDIT_GAME_INFO: Popping with final date/time: ${finalArgs['date']}, ${finalArgs['time']}');
                                    Navigator.pop(context, finalArgs);
                                  } else {
                                    debugPrint('🎯 EDIT_GAME_INFO: No result from date-time');
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
                                  debugPrint('🎯 EDIT_GAME_INFO: Received result from additional-game-info: $result');
                                  if (result != null) {
                                    final updatedArgs = result as Map<String, dynamic>;
                                    debugPrint('🎯 EDIT_GAME_INFO: Updated additional game info: ${updatedArgs['gameFee']}, ${updatedArgs['levelOfCompetition']}, etc.');
                                    final finalArgs = {
                                      ...updatedArgs,
                                      'isEdit': true,
                                      'isFromGameInfo': args['isFromGameInfo'] ?? false,
                                    };
                                    debugPrint('🎯 EDIT_GAME_INFO: Popping with final additional game info: ${finalArgs['gameFee']}');
                                    Navigator.pop(context, finalArgs);
                                  } else {
                                    debugPrint('🎯 EDIT_GAME_INFO: No result from additional-game-info');
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
                                            '/game-information',
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
                              text: 'Update Lists',
                              onPressed: _isAwayGame
                                  ? null // Disable for away games
                                  : () => _handleEditOfficials(args),
                            ),
                            const SizedBox(height: 20),
                          ],
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
