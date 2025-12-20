import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/user_service.dart';
import '../models/crew_model.dart';

class ReviewGameInfoScreen extends StatefulWidget {
  const ReviewGameInfoScreen({super.key});

  @override
  State<ReviewGameInfoScreen> createState() => _ReviewGameInfoScreenState();
}

class _ReviewGameInfoScreenState extends State<ReviewGameInfoScreen> {
  late Map<String, dynamic> args;
  late Map<String, dynamic> originalArgs;
  bool isEditMode = false;
  bool isFromGameInfo = false;
  bool isAwayGame = false;
  bool fromScheduleDetails = false;
  String? scheduleId;
  bool? isCoachScheduler;
  String? teamName;
  bool isUsingTemplate = false;
  final GameService _gameService = GameService();
  bool _isPublishing = false;
  bool _showButtonLoading = false;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      final newArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      setState(() {
        args = Map<String, dynamic>.from(newArgs);
        originalArgs = Map<String, dynamic>.from(newArgs);
        isEditMode = newArgs['isEdit'] == true;
        isFromGameInfo = newArgs['isFromGameInfo'] == true;
        isAwayGame = newArgs['isAway'] == true;
        fromScheduleDetails = newArgs['fromScheduleDetails'] == true;
        scheduleId = newArgs['scheduleId'] as String?;
        isUsingTemplate = newArgs['template'] != null;
        if (args['officialsRequired'] != null) {
          args['officialsRequired'] =
              int.tryParse(args['officialsRequired'].toString()) ?? 0;
        }
        _hasInitialized = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    args = {};
    originalArgs = {};
    _hasInitialized = false;
  }

  Future<bool?> _showCreateTemplateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final dontAskAgain = prefs.getBool('dont_ask_create_template') ?? false;

    if (dontAskAgain) {
      return false; // Don't create template if user opted out
    }

    bool checkboxValue = false;

    if (!mounted) return false;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text('Create Game Template?',
              style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Would you like to create a Game Template using the information from this game?',
                  style: TextStyle(color: colorScheme.onSurface)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: checkboxValue,
                    onChanged: (value) {
                      setDialogState(() {
                        checkboxValue = value ?? false;
                      });
                    },
                    activeColor: colorScheme.primary,
                    checkColor: colorScheme.onPrimary,
                  ),
                  Expanded(
                    child: Text('Do not ask me again',
                        style: TextStyle(color: colorScheme.onSurface)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (checkboxValue) {
                  await prefs.setBool('dont_ask_create_template', true);
                }
                if (mounted) {
                  Navigator.pop(context, false);
                }
              },
              child: Text('No', style: TextStyle(color: colorScheme.primary)),
            ),
            TextButton(
              onPressed: () async {
                if (checkboxValue) {
                  await prefs.setBool('dont_ask_create_template', true);
                }
                if (mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: Text('Yes', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _publishGame() async {
    debugPrint('🎯 PUBLISH_GAME: Starting game publish process');

    if (_isPublishing) {
      debugPrint('🎯 PUBLISH_GAME: Already publishing, returning');
      return;
    }

    setState(() {
      _isPublishing = true;
      _showButtonLoading = true;
    });

    try {
      debugPrint('🎯 PUBLISH_GAME: Entered try block');
      debugPrint('🎯 PUBLISH_GAME: Checking time: ${args['time']}');
      if (args['time'] == null) {
        debugPrint('🎯 PUBLISH_GAME: No time set, showing error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please set a game time before publishing.')),
        );
        return;
      }

      // Check if we have a valid method configuration or selected officials
      bool hasValidConfiguration = false;

      if (args['hireAutomatically'] == true) {
        hasValidConfiguration = true; // Hiring automatically is valid
      } else if (args['method'] == 'hire_crew' &&
          (args['selectedCrews'] != null || args['selectedCrew'] != null)) {
        hasValidConfiguration = true; // Crew selection is valid
      } else if (args['method'] == 'use_list' &&
          args['selectedListName'] != null) {
        hasValidConfiguration = true; // List selection is valid
      } else if (args['method'] == 'multiple_lists' &&
          args['selectedLists'] != null) {
        hasValidConfiguration = true; // Multiple lists configuration is valid
      } else if (args['method'] == 'advanced' &&
          args['selectedLists'] != null) {
        hasValidConfiguration = true; // Advanced method configuration is valid
      } else if (args['selectedOfficials'] != null &&
          (args['selectedOfficials'] as List).isNotEmpty) {
        hasValidConfiguration = true; // Individual officials selected
      }

      if (!isAwayGame && !hasValidConfiguration) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select at least one official or configure a selection method for non-away games.')),
        );
        return;
      }

      debugPrint('🎯 PUBLISH_GAME: Validation passed, preparing game data');

      final gameData = Map<String, dynamic>.from(args);
      gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
      gameData['createdAt'] = DateTime.now().toIso8601String();
      gameData['officialsHired'] = gameData['officialsHired'] ?? 0;
      gameData['status'] = 'Published';

      debugPrint(
          '🎯 PUBLISH_GAME: Game data prepared: ${gameData['method']}, crew: ${gameData['selectedCrew']?.name ?? 'none'}');

      // Get current user ID and profile
      final authService = AuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        debugPrint('🎯 PUBLISH_GAME: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🎯 PUBLISH_GAME: User authenticated: ${currentUser.uid}');
      debugPrint(
          '🎯 REVIEW_GAME_INFO: Saving game with homeTeam: ${gameData['homeTeam']}');

      // Get user profile to determine scheduler type and derive awayTeam
      final userService = UserService();
      final userProfile = await userService.getCurrentUser();
      if (userProfile?.schedulerProfile != null) {
        final schedulerProfile = userProfile!.schedulerProfile!;
        final isAway = gameData['isAway'] ?? false;
        final opponent = gameData['opponent'];
        final homeTeam = gameData['homeTeam'];

        debugPrint(
            '🎯 REVIEW_GAME_INFO: User type: ${schedulerProfile.type}, isAway: $isAway, homeTeam: $homeTeam, opponent: $opponent');

        if (schedulerProfile.type == 'Athletic Director') {
          // For Athletic Directors, derive awayTeam based on isAway flag
          if (isAway) {
            // Away game: AD's team is the away team
            gameData['awayTeam'] = homeTeam;
          } else {
            // Home game: opponent is the away team
            gameData['awayTeam'] = opponent;
          }
          debugPrint(
              '🎯 REVIEW_GAME_INFO: Set awayTeam to: ${gameData['awayTeam']}');
        }
        // For Assigners, awayTeam should be set manually in the UI
        // (this logic assumes it's already in gameData)
      }

      if (gameData['scheduleName'] == null) {
        gameData['scheduleName'] = 'Team Schedule';
      }

      // Save the game to Firestore
      try {
        final gameDataForDB = {
          'schedulerId': currentUser.uid,
          'scheduleId': args['scheduleId'],
          'scheduleName': gameData['scheduleName'],
          'sport': gameData['sport'],
          'date': gameData['date']?.toIso8601String(),
          'time': gameData['time'] != null
              ? '${gameData['time'].hour}:${gameData['time'].minute.toString().padLeft(2, '0')}'
              : null,
          'location': gameData['location'] is Map<String, dynamic>
              ? gameData['location']['name']
              : gameData['location'],
          'locationAddress': gameData['location'] is Map<String, dynamic>
              ? gameData['location']['address']
              : null,
          'opponent': gameData['opponent'],
          'officialsRequired': gameData['officialsRequired'],
          'gameFee': gameData['gameFee'],
          'gender': gameData['gender'],
          'levelOfCompetition': gameData['levelOfCompetition'],
          'hireAutomatically': gameData['hireAutomatically'],
          'method': gameData['method'],
          'selectedOfficials': gameData['selectedOfficials'],
          'selectedCrews': gameData['selectedCrews'] is List<Crew>
              ? gameData['selectedCrews'].map((crew) => crew.id).toList()
              : gameData['selectedCrews'],
          'selectedCrew': gameData['selectedCrew'] is Crew
              ? gameData['selectedCrew'].id
              : gameData['selectedCrew'],
          'selectedListName': gameData['selectedListName'],
          'selectedLists': gameData['selectedLists'],
          'officialsHired': gameData['officialsHired'],
          'status': gameData['status'],
          'createdAt': gameData['createdAt'],
          'isAway': gameData['isAway'] ?? false,
          'homeTeam': gameData['homeTeam'],
          'awayTeam': gameData['awayTeam'],
        };

        debugPrint('🎯 PUBLISH_GAME: About to save to Firestore');

        // Save to Firestore games collection
        final firestore = FirebaseFirestore.instance;
        final gameRef = await firestore.collection('games').add(gameDataForDB);

        debugPrint(
            '🎯 PUBLISH_GAME: Game saved to Firestore with ID: ${gameRef.id}');
      } catch (e) {
        debugPrint('🎯 PUBLISH_GAME: Error saving game to Firestore: $e');
        throw Exception('Failed to save game: $e');
      }

      if (mounted) {
        // Hide button loading before showing dialog
        setState(() {
          _showButtonLoading = false;
        });

        // Skip template creation dialog if game was already created from a template
        bool createTemplate = false;
        if (isUsingTemplate) {
          debugPrint(
              '🎯 REVIEW_GAME_INFO: Game was created from template, skipping template creation dialog');
        } else {
          // Show template creation dialog
          final shouldCreateTemplate = await _showCreateTemplateDialog();
          debugPrint('Template dialog result: $shouldCreateTemplate');

          // Treat null as false (user dismissed dialog)
          createTemplate = shouldCreateTemplate == true;
        }

        if (createTemplate && !isAwayGame) {
          debugPrint('Navigating to template creation screen');
          if (mounted) {
            // Prepare data for template creation (convert DateTime and TimeOfDay to strings)
            final templateData = Map<String, dynamic>.from(gameData);
            if (templateData['date'] != null) {
              templateData['date'] =
                  (templateData['date'] as DateTime).toIso8601String();
            }
            if (templateData['time'] != null) {
              final time = templateData['time'] as TimeOfDay;
              templateData['time'] = '${time.hour}:${time.minute}';
            }

            Navigator.pushNamed(
              context,
              '/create_game_template',
              arguments: templateData,
            ).then((result) {
              if (result == true && mounted) {
                // Template created successfully
              }
              _navigateBack();
            });
          }
        } else {
          debugPrint('Navigating directly back to home screen');
          // AD home screen will show the success message, no need to duplicate here
          // Ensure navigation happens even if not mounted
          Future.delayed(Duration.zero, () {
            if (mounted) {
              _navigateBack();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('🎯 PUBLISH_GAME: Exception during publish: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing game: $e')),
        );
      }
    } finally {
      debugPrint('🎯 PUBLISH_GAME: Finally block executed');
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _showButtonLoading = false;
        });
      }
    }
  }

  Future<void> _publishUpdate() async {
    // TODO: Implement publish update functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publish update not yet implemented')),
    );
  }

  Future<void> _publishLater() async {
    if (_isPublishing) return;

    setState(() {
      _isPublishing = true;
      _showButtonLoading = true;
    });

    try {
      if (args['time'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please set a game time before saving.')),
        );
        return;
      }

      final gameData = Map<String, dynamic>.from(args);
      gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
      gameData['createdAt'] = DateTime.now().toIso8601String();
      gameData['officialsHired'] = gameData['officialsHired'] ?? 0;
      gameData['status'] = 'Unpublished';

      // Get user profile to determine scheduler type and derive awayTeam
      final userService = UserService();
      final userProfile = await userService.getCurrentUser();
      if (userProfile?.schedulerProfile != null) {
        final schedulerProfile = userProfile!.schedulerProfile!;
        final isAway = gameData['isAway'] ?? false;
        final opponent = gameData['opponent'];
        final homeTeam = gameData['homeTeam'];

        debugPrint(
            '🎯 REVIEW_GAME_INFO: Saving unpublished game with homeTeam: ${gameData['homeTeam']}');

        if (schedulerProfile.type == 'Athletic Director') {
          // For Athletic Directors, derive awayTeam based on isAway flag
          if (isAway) {
            // Away game: AD's team is the away team
            gameData['awayTeam'] = homeTeam;
          } else {
            // Home game: opponent is the away team
            gameData['awayTeam'] = opponent;
          }
          debugPrint(
              '🎯 REVIEW_GAME_INFO: Set awayTeam to: ${gameData['awayTeam']}');
        }
        // For Assigners, awayTeam should be set manually in the UI
        // (this logic assumes it's already in gameData)
      }

      if (gameData['scheduleName'] == null) {
        gameData['scheduleName'] = 'Team Schedule';
      }

      // Prepare game data for saving
      final gameDataForDB = {
        'scheduleId': args['scheduleId'],
        'scheduleName': gameData['scheduleName'],
        'sport': gameData['sport'],
        'date': gameData['date']?.toIso8601String(),
        'time': gameData['time'] != null
            ? '${gameData['time'].hour}:${gameData['time'].minute.toString().padLeft(2, '0')}'
            : null,
        'location': gameData['location'],
        'opponent': gameData['opponent'],
        'officialsRequired': gameData['officialsRequired'],
        'gameFee': gameData['gameFee'],
        'gender': gameData['gender'],
        'levelOfCompetition': gameData['levelOfCompetition'],
        'hireAutomatically': gameData['hireAutomatically'],
        'method': gameData['method'],
        'selectedOfficials': gameData['selectedOfficials'],
        'selectedCrews': gameData['selectedCrews'],
        'selectedCrew': gameData['selectedCrew'],
        'selectedListName': gameData['selectedListName'],
        'selectedLists': gameData['selectedLists'],
        'officialsHired': gameData['officialsHired'],
        'status': gameData['status'],
        'createdAt': gameData['createdAt'],
        'isAway': gameData['isAway'] ?? false,
        'homeTeam': gameData['homeTeam'],
        'awayTeam': gameData['awayTeam'],
      };

      // Save using GameService
      final success = await _gameService.saveUnpublishedGame(gameDataForDB);

      if (!success) {
        throw Exception('Failed to save game to unpublished games');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Game saved to Unpublished Games list!')),
        );
        // Navigate to unpublished games screen instead of going back
        Navigator.pushNamed(context, '/unpublished-games');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _showButtonLoading = false;
        });
      }
    }
  }

  void _navigateBack() async {
    debugPrint(
        '_navigateBack called. fromScheduleDetails: $fromScheduleDetails');
    if (fromScheduleDetails) {
      // Navigate back to schedule details (calendar view) showing the month of the published game
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/schedule_details',
        (route) => false, // Clear navigation stack
        arguments: {
          'scheduleName': args['scheduleName'],
          'scheduleId': scheduleId,
          'initialDate':
              args['date'], // Pass the game date to focus the calendar
          'gamePublished': true, // Flag to indicate a game was just published
        },
      );
    } else {
      debugPrint('Navigating back to user home screen');
      // Get the appropriate home route based on user type
      final authService = AuthService();
      final homeRoute = await authService.getHomeRoute();

      // Replace the current navigation stack with a fresh home screen
      // This ensures the screen refreshes and shows the newly published game
      Navigator.of(context).pushNamedAndRemoveUntil(
        homeRoute,
        (route) => false, // Remove all routes
        arguments: {'refresh': true, 'gamePublished': true},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Create gameDetails map
    final gameDetails = <String, String>{
      'Sport': args['sport'] as String? ?? 'Unknown',
      'Schedule Name': args['scheduleName'] as String? ?? 'Unnamed',
      'Date': args['date'] != null
          ? '${(args['date'] as DateTime).month}/${(args['date'] as DateTime).day}/${(args['date'] as DateTime).year}'
          : 'Not set',
      'Time': args['time'] != null
          ? (args['time'] as TimeOfDay).format(context)
          : 'Not set',
      'Location': args['location'] is Map<String, dynamic>
          ? args['location']['name'] as String? ?? 'Not set'
          : (args['location'] as String? ?? 'Not set'),
      'Opponent': args['opponent'] as String? ?? 'Not set',
    };

    final additionalDetails = !isAwayGame
        ? {
            'Officials Required': (args['officialsRequired'] ?? 0).toString(),
            'Fee per Official':
                args['gameFee'] != null ? '\$${args['gameFee']}' : 'Not set',
            'Gender': args['gender'] as String? ?? 'Not set',
            'Competition Level':
                args['levelOfCompetition'] as String? ?? 'Not set',
            'Hire Automatically':
                args['hireAutomatically'] == true ? 'Yes' : 'No',
          }
        : {};

    final allDetails = {
      ...gameDetails,
      if (!isAwayGame) ...additionalDetails,
    };

    final isPublished = args['status'] == 'Published';

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
              onPressed: () async {
                // Navigate to user home screen
                final authService = AuthService();
                final homeRoute = await authService.getHomeRoute();
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
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Review Game Info',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Edit button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Game Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/edit_game_info',
                                    arguments: {
                                      ...args,
                                      'isEdit': true,
                                      'isFromGameInfo': true,
                                      'fromScheduleDetails':
                                          fromScheduleDetails,
                                      'scheduleId': scheduleId,
                                    }).then((result) {
                                  if (result != null &&
                                      result is Map<String, dynamic>) {
                                    setState(() {
                                      args = result;
                                      fromScheduleDetails =
                                          result['fromScheduleDetails'] == true;
                                      scheduleId =
                                          result['scheduleId'] as String?;
                                      isAwayGame = result['isAway'] == true;
                                    });
                                  }
                                }),
                                child: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Game details
                          ...allDetails.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      '${e.key}:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Only show Selected Officials section for non-away games
                          if (!isAwayGame) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Selected Officials',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (args['method'] == 'hire_crew' &&
                                (args['selectedCrews'] != null ||
                                    args['selectedCrew'] != null)) ...[
                              if (args['selectedCrews'] != null) ...[
                                ...((args['selectedCrews'] as List<dynamic>)
                                    .map((crewData) {
                                  // Handle both Crew objects and Map data
                                  final crewName =
                                      crewData is Map<String, dynamic>
                                          ? crewData['name'] as String? ??
                                              'Unknown Crew'
                                          : (crewData as dynamic).name ??
                                              'Unknown Crew';
                                  final memberCount = crewData
                                          is Map<String, dynamic>
                                      ? crewData['memberCount'] as int? ?? 0
                                      : (crewData as Crew).members?.length ?? 0;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'Crew: $crewName ($memberCount officials)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                })),
                              ] else if (args['selectedCrew'] != null) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Crew: ${(args['selectedCrew'] as Crew).name} (${(args['selectedCrew'] as Crew).members?.length ?? 0} officials)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ] else if (args['method'] == 'use_list' &&
                                args['selectedListName'] != null) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'List Used: ${args['selectedListName']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ] else if (args['method'] == 'advanced' &&
                                args['selectedLists'] != null) ...[
                              ...((args['selectedLists']
                                      as List<Map<String, dynamic>>)
                                  .map(
                                (list) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '${list['list']}: Min ${list['min']}, Max ${list['max']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              )),
                            ] else if (args['method'] == 'multiple_lists' &&
                                args['selectedLists'] != null) ...[
                              ...((args['selectedLists']
                                      as List<Map<String, dynamic>>)
                                  .where((list) =>
                                      list['list'] != null &&
                                      list['list'].toString().isNotEmpty)
                                  .map(
                                    (list) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Text(
                                        '${list['list']}: Min ${list['min']}, Max ${list['max']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  )),
                            ] else if (args['selectedOfficials'] == null ||
                                (args['selectedOfficials'] as List).isEmpty)
                              Text(
                                'No officials selected.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            else ...[
                              ...(args['selectedOfficials'] as List<dynamic>)
                                  .map((item) => item as Map<String, dynamic>)
                                  .map(
                                    (official) => ListTile(
                                      title: Text(
                                        official['name'] as String,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    if (isPublished) ...[
                      ElevatedButton(
                        onPressed: _publishUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text(
                          'Publish Update',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: _isPublishing ? null : _publishGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _showButtonLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Publish Game',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isPublishing ? null : _publishLater,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.surfaceVariant,
                          foregroundColor: colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _showButtonLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Publish Later',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
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
