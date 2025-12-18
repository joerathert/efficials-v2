import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';
import '../widgets/link_games_dialog.dart';

class GameInformationScreen extends StatefulWidget {
  const GameInformationScreen({super.key});

  @override
  State<GameInformationScreen> createState() => _GameInformationScreenState();
}

class _GameInformationScreenState extends State<GameInformationScreen> {
  late Map<String, dynamic> args;
  late ColorScheme colorScheme;
  bool _hasUpdatedArgs = false;

  // Game details
  late String scheduleName;
  late String sport;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late String location;
  late String levelOfCompetition;
  late String gender;
  late int officialsRequired;
  late String gameFee;
  late bool hireAutomatically;
  late bool isAwayGame;
  late String opponent;
  late int officialsHired;

  // State management
  List<Map<String, dynamic>> selectedOfficials = [];
  List<Map<String, dynamic>> interestedOfficials = [];
  List<Map<String, dynamic>> confirmedOfficials = [];
  List<Map<String, dynamic>> selectedLists = [];
  Map<String, dynamic> gameDetails = {};
  bool isGameLinked = false;
  List<Map<String, dynamic>> linkedGames = [];
  bool _hasEligibleGames = false;
  Map<String, bool> selectedForHire = {};
  List<String> dismissedOfficials = [];

  // Services
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null) return;

    final newArgs = route.settings.arguments as Map<String, dynamic>?;
    if (newArgs == null) return;

    // Only update args if we haven't already updated them from an edit operation
    if (!_hasUpdatedArgs) {
      args = newArgs;
      _initializeData();
    }
  }

  Future<void> _saveUpdatedOfficialsData(
      String gameId, Map<String, dynamic> updatedData) async {
    try {
      debugPrint(
          '🎯 GAME_INFO: Saving updated officials data for game $gameId');

      // Only save the officials-related fields that can be changed
      final dataToSave = {
        'method': updatedData['method'],
        'selectedListName': updatedData['selectedListName'],
        'selectedLists': updatedData['selectedLists'],
        'selectedCrews': updatedData['selectedCrews'],
        'selectedCrew': updatedData['selectedCrew'],
        'selectedOfficials': updatedData['selectedOfficials'],
      };

      final success = await _gameService.updateGame(gameId, dataToSave);

      if (success && mounted) {
        debugPrint('🎯 GAME_INFO: Successfully saved updated officials data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Officials selection updated successfully')),
        );
      } else if (mounted) {
        debugPrint('🎯 GAME_INFO: Failed to save updated officials data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update officials selection')),
        );
      }
    } catch (e) {
      debugPrint('🎯 GAME_INFO: Error saving updated officials data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating officials selection: $e')),
        );
      }
    }
  }

  Future<void> _saveUpdatedGameData(
      String gameId, Map<String, dynamic> updatedData) async {
    try {
      debugPrint('🎯 GAME_INFO: Saving updated game data for game $gameId');

      // Only save the fields that can be edited
      final dataToSave = {
        'location': updatedData['location'],
        'date': updatedData['date'] != null
            ? (updatedData['date'] as DateTime).toIso8601String()
            : null,
        'time': updatedData['time'] != null
            ? '${(updatedData['time'] as TimeOfDay).hour.toString().padLeft(2, '0')}:${(updatedData['time'] as TimeOfDay).minute.toString().padLeft(2, '0')}'
            : null,
        'levelOfCompetition': updatedData['levelOfCompetition'],
        'gender': updatedData['gender'],
        'officialsRequired': updatedData['officialsRequired'],
        'gameFee': updatedData['gameFee'],
        'opponent': updatedData['opponent'],
        'hireAutomatically': updatedData['hireAutomatically'],
      };

      final success = await _gameService.updateGame(gameId, dataToSave);

      if (success && mounted) {
        debugPrint('🎯 GAME_INFO: Successfully saved updated game data');

        // Check if officialsRequired changed and selection method was reset
        if (updatedData['method'] == null && args['method'] != null) {
          debugPrint(
              '🎯 GAME_INFO: Selection method was reset due to officialsRequired change');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Officials selection reset due to required officials change. Please re-select officials.'),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game updated successfully')),
          );
        }
      } else if (mounted) {
        debugPrint('🎯 GAME_INFO: Failed to save updated game data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update game')),
        );
      }
    } catch (e) {
      debugPrint('🎯 GAME_INFO: Error saving updated game data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating game: $e')),
        );
      }
    }
  }

  void _initializeData() {
    debugPrint(
        '🎯 GAME_INFO: _initializeData called with location: ${args['location']}');
    scheduleName = args['scheduleName'] as String? ?? '';
    sport = args['sport'] as String? ?? '';
    selectedDate = args['date'] != null
        ? (args['date'] is String
            ? DateTime.parse(args['date'] as String)
            : args['date'] as DateTime)
        : DateTime.now();
    selectedTime = args['time'] != null
        ? (args['time'] is String
            ? () {
                final timeParts = (args['time'] as String).split(':');
                return TimeOfDay(
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1]),
                );
              }()
            : args['time'] as TimeOfDay)
        : const TimeOfDay(hour: 19, minute: 0);
    // Handle location - it can be a string or a map with name/address
    if (args['location'] != null) {
      if (args['location'] is String) {
        location = args['location'] as String;
      } else if (args['location'] is Map && args['location']['name'] != null) {
        location = args['location']['name'] as String;
      } else {
        location = '';
      }
    } else {
      location = '';
    }
    debugPrint('🎯 GAME_INFO: _initializeData set location to: $location');
    levelOfCompetition = args['levelOfCompetition'] as String? ?? '';
    gender = args['gender'] as String? ?? '';
    officialsRequired = args['officialsRequired'] != null
        ? (int.tryParse(args['officialsRequired'].toString()) ?? 5)
        : 5;
    gameFee = args['gameFee']?.toString() ?? 'Not set';
    hireAutomatically = args['hireAutomatically'] as bool? ?? false;
    isAwayGame =
        args['isAwayGame'] as bool? ?? args['isAway'] as bool? ?? false;
    opponent = args['opponent'] as String? ?? '';
    officialsHired = args['officialsHired'] as int? ?? 0;

    selectedOfficials =
        (args['selectedOfficials'] as List<dynamic>? ?? []).map((official) {
      if (official is Map) {
        return Map<String, dynamic>.from(official);
      }
      return <String, dynamic>{'name': 'Unknown Official', 'distance': 0.0};
    }).toList();

    selectedLists = (args['selectedLists'] as List<dynamic>? ?? []).map((list) {
      if (list is Map) {
        return Map<String, dynamic>.from(list);
      }
      return <String, dynamic>{
        'name': 'Unknown List',
        'minOfficials': 0,
        'maxOfficials': 0,
        'officials': <Map<String, dynamic>>[],
      };
    }).toList();

    _loadGameDetails();
    _loadInterestedOfficials();
    _checkGameLinkStatus();

    // Trigger UI rebuild with updated data
    if (mounted) {
      setState(() {});
    }
  }

  void _loadGameDetails() {
    gameDetails = {
      'Sport': sport,
      'Schedule Name': scheduleName,
      'Date': selectedDate != null
          ? DateFormat('EEEE, MMM d, yyyy').format(selectedDate!)
          : 'Not set',
      'Time': selectedTime != null
          ? _formatTimeConsistently(selectedTime!)
          : 'Not set',
      'Location': location,
      'Opponent': opponent,
      'Competition Level': levelOfCompetition,
      'Gender': gender,
      'Officials Required': officialsRequired?.toString() ?? '0',
      'Hire Automatically': hireAutomatically ? 'Yes' : 'No',
      'Game Fee': gameFee != 'Not set' ? '\$$gameFee' : 'Not set',
    };
  }

  Future<void> _loadInterestedOfficials() async {
    try {
      final gameId = args['id'];
      if (gameId != null) {
        final officials =
            await _gameService.getInterestedOfficialsForGame(gameId);
        final confirmed =
            await _gameService.getConfirmedOfficialsForGame(gameId);

        // Update officialsHired from confirmed count
        final confirmedCount = confirmed.length;

        if (mounted) {
          setState(() {
            interestedOfficials = officials;
            confirmedOfficials = confirmed;
            officialsHired = confirmedCount;
            args['officialsHired'] = officialsHired;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading officials: $e');
    }
  }

  String _formatTimeConsistently(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () async {
            final authService = AuthService();
            final homeRoute = await authService.getHomeRoute();
            Navigator.pushNamedAndRemoveUntil(
              context,
              homeRoute,
              (route) => false,
            );
          },
          child: Icon(
            Icons.sports,
            color: colorScheme.primary,
            size: 32,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  child: Container(
                    color: colorScheme.surfaceContainerHighest,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        // Edit button on the left
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/edit_game_info',
                            arguments: {
                              ...args,
                              'date': selectedDate,
                              'time': selectedTime,
                              'isEdit': true,
                              'isFromGameInfo': true,
                              'sourceScreen': args['sourceScreen'],
                              'scheduleName': args['scheduleName'],
                              'scheduleId': args['scheduleId'],
                            },
                          ).then((result) {
                            debugPrint(
                                '🎯 GAME_INFO: Received result from edit: $result');
                            if (result != null && mounted) {
                              final updatedArgs =
                                  result as Map<String, dynamic>;
                              debugPrint(
                                  '🎯 GAME_INFO: Updated location: ${updatedArgs['location']}');
                              // Update the screen with the edited data
                              setState(() {
                                args = updatedArgs;
                                _hasUpdatedArgs = true;
                              });
                              _initializeData();

                              // Save the updated game data to Firestore
                              final gameId = args['id'] as String?;
                              if (gameId != null) {
                                _saveUpdatedGameData(gameId, updatedArgs);
                              }
                            } else {
                              debugPrint(
                                  '🎯 GAME_INFO: No result received or not mounted');
                            }
                          }),
                          child: Text('Edit',
                              style: TextStyle(
                                  color: colorScheme.primary, fontSize: 14)),
                        ),
                        // Centered title
                        Expanded(
                          child: Center(
                            child: Text('Game Details',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary)),
                          ),
                        ),
                        // Action buttons on the right
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _createTemplateFromGame(),
                              icon: Icon(Icons.content_copy,
                                  color: colorScheme.primary),
                              tooltip: 'Create Template from Game',
                            ),
                            if (_isDatabaseGame(args['id']) &&
                                _hasEligibleGames)
                              IconButton(
                                onPressed: () => _showLinkGamesDialog(),
                                icon: Icon(
                                  isGameLinked ? Icons.link_off : Icons.link,
                                  color: colorScheme.primary,
                                ),
                                tooltip: isGameLinked
                                    ? 'Manage Game Links'
                                    : 'Link Games',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Game details section
                      ...gameDetails.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text(
                                  '${e.key}:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              Expanded(
                                child: e.key == 'Schedule Name'
                                    ? GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/schedule_details',
                                            arguments: {
                                              'scheduleName': e.value,
                                              'scheduleId': args[
                                                  'scheduleId'], // Pass if available
                                            },
                                          );
                                        },
                                        child: Text(
                                          e.value,
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                colorScheme.primary,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        e.value,
                                        style: TextStyle(color: Colors.white),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Officials sections
                      if (!isAwayGame) ...[
                        _buildOfficialsSection(),
                      ],

                      const SizedBox(height: 20),

                      // Selected Officials Section
                      Text(
                        'Selected Officials',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary),
                      ),
                      const SizedBox(height: 10),
                      _buildSelectedOfficialsSection(),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _deleteGame(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                              ),
                              child: const Text('Delete Game'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmed Officials (${confirmedOfficials.length}/$officialsRequired)',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary),
        ),
        const SizedBox(height: 8),
        if (confirmedOfficials.isEmpty)
          Text('No officials confirmed.',
              style: TextStyle(color: colorScheme.onSurfaceVariant))
        else
          Column(
            children: confirmedOfficials.map((official) {
              final officialName = official is Map
                  ? official['name'] as String? ?? 'Unknown Official'
                  : official.toString();
              final officialId =
                  official is Map ? official['id'] as String? ?? '' : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToOfficialProfile(officialId),
                        child: Text(
                          officialName,
                          style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: colorScheme.primary),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showRemoveOfficialDialog(officialName),
                      icon: Icon(Icons.remove_circle, color: colorScheme.error),
                      iconSize: 20,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        if (!hireAutomatically &&
            (officialsHired < officialsRequired ||
                interestedOfficials.isNotEmpty)) ...[
          Text(
            'Interested Officials',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          if (interestedOfficials.isEmpty)
            _buildNoOfficialsMessage()
          else
            Column(
              children: interestedOfficials.map((official) {
                return CheckboxListTile(
                  title: GestureDetector(
                    onTap: () => _navigateToOfficialProfile(
                        official['id'] as String? ?? ''),
                    child: Text(
                      official['name'] as String,
                      style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary),
                    ),
                  ),
                  subtitle: Text(
                    'Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  value: selectedForHire[official['id']] ?? false,
                  onChanged: (value) {
                    final officialId = official['id'] as String;
                    final currentSelected =
                        selectedForHire.values.where((v) => v).length;

                    if (value == true &&
                        currentSelected <
                            (officialsRequired - confirmedOfficials.length)) {
                      setState(() {
                        selectedForHire[officialId] = true;
                      });
                    } else if (value == false) {
                      setState(() {
                        selectedForHire[officialId] = false;
                      });
                    }
                  },
                  activeColor: colorScheme.primary,
                  checkColor: colorScheme.onPrimary,
                );
              }).toList(),
            ),
          if (interestedOfficials.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _confirmHires(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Confirm Hire(s)'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildNoOfficialsMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'No interested officials yet.',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildSelectedOfficialsSection() {
    // Check if method is null (officials selection was reset)
    final method = args['method'] as String?;
    if (method == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.error.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Officials Selection Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The number of required officials has changed. Please re-select your officials method.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/select-officials',
                    arguments: {
                      ...args,
                      'isEdit': true,
                      'isFromGameInfo': true,
                    },
                  ).then((result) {
                    if (result != null && mounted) {
                      final updatedArgs = result as Map<String, dynamic>;
                      setState(() {
                        args = updatedArgs;
                        _hasUpdatedArgs = true;
                      });
                      _initializeData();
                      // Save the updated officials selection to Firestore
                      final gameId = args['id'] as String?;
                      if (gameId != null) {
                        _saveUpdatedOfficialsData(gameId, updatedArgs);
                      }
                    }
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('Select Officials'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check for multiple lists first (Multiple Lists method)
    final selectedLists = args['selectedLists'] as List<dynamic>?;
    if (selectedLists != null && selectedLists.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Multiple Lists Used:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          ...selectedLists.map((list) {
            if (list is Map<String, dynamic>) {
              final listName = list['list'] as String? ?? 'Unknown List';
              final min = list['min'] ?? 0;
              final max = list['max'] ?? 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: GestureDetector(
                  onTap: () => _showListOfficials(listName),
                  child: Text(
                    '$listName: Min $min, Max $max',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: colorScheme.primary,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ],
      );
    }

    // Check for single list (Single List method)
    final selectedListName = args['selectedListName'] as String?;
    if (selectedListName == null || selectedListName.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No list selected',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () => _showListOfficials(selectedListName),
        child: Text(
          'List Used: $selectedListName',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _createTemplateFromGame() async {
    // Implementation for creating template from game
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Create template functionality coming soon')),
    );
  }

  void _showListOfficials(String listName) async {
    // Show popup with list of officials
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Officials in "$listName"',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView(
            children: [
              // Mock data for demonstration - in real app, get from selectedList data
              Text('• John Smith (2.3 mi)',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Text('• Sarah Johnson (3.1 mi)',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Text('• Mike Davis (1.8 mi)',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Text('• Lisa Wilson (4.2 mi)',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Text('• Tom Anderson (2.9 mi)',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToOfficialProfile(String officialId) {
    if (officialId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot view profile: Official ID not available')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/view-official-profile',
      arguments: {'officialId': officialId},
    );
  }

  Future<void> _confirmHires() async {
    final selectedCount = selectedForHire.values.where((v) => v).length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No officials selected')),
      );
      return;
    }

    final newTotalHired = officialsHired + selectedCount;
    if (newTotalHired > officialsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Cannot hire more than $officialsRequired officials')),
      );
      return;
    }

    final gameId = args['id'];
    if (gameId != null && _isDatabaseGame(gameId)) {
      try {
        // Add each selected official to confirmed list and remove from interested
        bool allSuccessful = true;
        for (final entry in selectedForHire.entries) {
          if (entry.value) {
            // if selected for hire
            final official = interestedOfficials.firstWhere(
              (o) => o['id'] == entry.key,
              orElse: () => <String, dynamic>{},
            );

            if (official.isNotEmpty) {
              final officialId = official['id'] as String;
              final officialData = {
                'id': officialId,
                'name': official['name'],
                'distance': official['distance'] ?? 0.0,
              };

              // Add to confirmed officials
              final addSuccess =
                  await _gameService.addConfirmedOfficial(gameId, officialData);
              // Remove from interested officials
              final removeSuccess = await _gameService.removeInterestedOfficial(
                  gameId, officialId);

              if (!addSuccess || !removeSuccess) {
                allSuccessful = false;
              }
            }
          }
        }

        if (allSuccessful && mounted) {
          setState(() {
            selectedForHire.clear();
          });

          await _loadInterestedOfficials();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Successfully hired $selectedCount official(s)')),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update some officials')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHighest,
        title: Text('Delete Game',
            style: TextStyle(
                color: colorScheme.primary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this game?',
            style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final gameId = args['id'];
      if (gameId != null && _isDatabaseGame(gameId)) {
        try {
          final success = await _gameService.deleteGame(gameId);
          if (success && mounted) {
            // Don't show SnackBar here - let the home screen handle it to avoid duplicates
            Navigator.pop(context, true);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete game')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting game: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _showLinkGamesDialog() async {
    final gameId = args['id'];
    if (gameId == null || !_isDatabaseGame(gameId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game linking is not available for legacy games'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final eligibleGames =
          await _gameService.getEligibleGamesForLinking(gameId.toString());
      final isCurrentlyLinked =
          await _gameService.isGameLinked(gameId.toString());

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => LinkGamesDialog(
            currentGameId: gameId.toString(),
            eligibleGames: eligibleGames,
            isCurrentlyLinked: isCurrentlyLinked,
            gameService: _gameService,
            onLinkCreated: () {
              // Refresh the screen to show linked status and update eligible games
              _checkGameLinkStatus();
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading linkable games: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRemoveOfficialDialog(String officialName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHighest,
        title: Text('Remove Official',
            style: TextStyle(
                color: colorScheme.primary, fontWeight: FontWeight.bold)),
        content: Text('Remove $officialName from this game?',
            style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final gameId = args['id'];
      if (gameId != null && _isDatabaseGame(gameId)) {
        try {
          // Find the official ID from the confirmed officials list
          final official = confirmedOfficials.firstWhere(
            (o) => o['name'] == officialName,
            orElse: () => <String, dynamic>{},
          );

          if (official.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Official not found')),
              );
            }
            return;
          }

          final officialId = official['id'] as String;
          final success =
              await _gameService.removeConfirmedOfficial(gameId, officialId);
          if (success && mounted) {
            await _loadInterestedOfficials();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$officialName removed from game')),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to remove official')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error removing official: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _checkGameLinkStatus() async {
    try {
      final gameId = args['id'];
      if (gameId != null && _isDatabaseGame(gameId)) {
        isGameLinked = await _gameService.isGameLinked(gameId.toString());
        if (isGameLinked) {
          linkedGames = await _gameService.getLinkedGames(gameId.toString());
        } else {
          linkedGames = [];
        }

        // Check for eligible games
        final eligibleGames =
            await _gameService.getEligibleGamesForLinking(gameId.toString());
        _hasEligibleGames = eligibleGames.isNotEmpty;

        debugPrint(
            '🔗 Game link status checked: isLinked=$isGameLinked, linkedGames=${linkedGames.length}, hasEligible=${_hasEligibleGames}');

        // Trigger UI rebuild with updated link status
        if (mounted) {
          setState(() {});
        }
      } else {
        isGameLinked = false;
        linkedGames = [];
        _hasEligibleGames = false;
      }
    } catch (e) {
      debugPrint('🔴 Error checking game link status: $e');
      isGameLinked = false;
      linkedGames = [];
      _hasEligibleGames = false;
    }
  }

  bool _isDatabaseGame(dynamic gameId) {
    return gameId != null && gameId is! int;
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
