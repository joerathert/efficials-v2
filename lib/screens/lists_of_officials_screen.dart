import 'package:flutter/material.dart';
import '../models/game_template_model.dart';
import '../services/official_list_service.dart';

class ListsOfOfficialsScreen extends StatefulWidget {
  const ListsOfOfficialsScreen({super.key});

  @override
  State<ListsOfOfficialsScreen> createState() => _ListsOfOfficialsScreenState();
}

class _ListsOfOfficialsScreenState extends State<ListsOfOfficialsScreen> {
  String? selectedList;
  List<Map<String, dynamic>> lists = [];
  bool isLoading = true;
  bool isFromGameCreation = false;
  bool isFromInsufficientLists = false;
  String? insufficientListsSport;
  Map<String, dynamic>? gameArgs;
  GameTemplateModel? template;
  final OfficialListService _listService = OfficialListService();
  Map<String, dynamic>? _savedGameCreationArgs; // Store original game creation args

  @override
  void initState() {
    super.initState();
    lists = [
      {'name': 'No saved lists', 'id': -1},
      {'name': '+ Create new list', 'id': 0},
    ];
    _fetchLists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    print(
        '📱 ListsOfOfficialsScreen: didChangeDependencies called with args=$args');
    if (args != null) {
      final isEdit = args['isEdit'] == true;

      setState(() {
        // Show green arrow during game creation flow (unless explicitly from hamburger menu)
        // For edit mode, show a different indicator (we'll use a different approach)
        isFromGameCreation = args['fromGameCreation'] == true &&
            args['fromHamburgerMenu'] != true &&
            !isEdit;

        // Handle Insufficient Lists navigation context
        isFromInsufficientLists = args['fromInsufficientLists'] == true;
        gameArgs = args['gameArgs'] as Map<String, dynamic>?;

        // For Insufficient Lists, use the sport from gameArgs (game creation context)
        // Otherwise use the sport from args (direct navigation)
        if (isFromInsufficientLists && gameArgs != null) {
          insufficientListsSport = gameArgs!['sport'] as String?;
        } else {
          insufficientListsSport = args['sport'] as String?;
        }

        template = args['template'] as GameTemplateModel?;
        
        // IMPORTANT: Store the original game creation args when first arriving
        // This ensures we have all the game data (date, time, location, etc.) available
        // even after going through the list creation flow
        if (_savedGameCreationArgs == null && isFromGameCreation) {
          _savedGameCreationArgs = Map<String, dynamic>.from(args);
          print('🎯 ListsOfOfficialsScreen: Saved game creation args: $_savedGameCreationArgs');
          print('🎯 ListsOfOfficialsScreen: Saved args keys: ${_savedGameCreationArgs?.keys.toList()}');
          print('🎯 ListsOfOfficialsScreen: sport = ${_savedGameCreationArgs?['sport']}');
          print('🎯 ListsOfOfficialsScreen: date = ${_savedGameCreationArgs?['date']}');
          print('🎯 ListsOfOfficialsScreen: time = ${_savedGameCreationArgs?['time']}');
          print('🎯 ListsOfOfficialsScreen: location = ${_savedGameCreationArgs?['location']}');
          print('🎯 ListsOfOfficialsScreen: opponent = ${_savedGameCreationArgs?['opponent']}');
        }

        print(
            '🎯 ListsOfOfficialsScreen: Initial context - fromInsufficientLists: $isFromInsufficientLists, insufficientListsSport: $insufficientListsSport, gameArgs: ${gameArgs != null ? 'present' : 'null'}');
      });

      print(
          '📱 ListsOfOfficialsScreen: Navigation context - fromInsufficientLists: $isFromInsufficientLists, sport: $insufficientListsSport');

      // Handle pre-selected list from template
      if (args['preSelectedList'] != null && args['method'] == 'use_list') {
        final preSelectedListName = args['preSelectedList'] as String;
        print(
            '🎯 ListsOfOfficialsScreen: Pre-selected list: $preSelectedListName');

        // Wait for lists to be fetched, then find and select the pre-selected list
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectPreSelectedList(preSelectedListName, args);
        });
      }

      // Handle new list creation from review_list_screen
      if (args['newListCreated'] != null) {
        final newListData = args['newListCreated'] as Map<String, dynamic>;
        print(
            '🎯 ListsOfOfficialsScreen: Handling newListCreated: ${newListData['listName']}');

        // Check if Insufficient Lists context is embedded in the result OR at top level
        final embeddedFromInsufficientLists =
            newListData['fromInsufficientLists'] as bool?;
        final embeddedGameArgs =
            newListData['gameArgs'] as Map<String, dynamic>?;

        final topLevelFromInsufficientLists =
            args['fromInsufficientLists'] as bool?;
        final topLevelGameArgs = args['gameArgs'] as Map<String, dynamic>?;

        if ((embeddedFromInsufficientLists == true &&
                embeddedGameArgs != null) ||
            (topLevelFromInsufficientLists == true &&
                topLevelGameArgs != null)) {
          print(
              '🎯 ListsOfOfficialsScreen: Found Insufficient Lists context (embedded or top-level)');
          isFromInsufficientLists = true;
          insufficientListsSport =
              (embeddedGameArgs ?? topLevelGameArgs)?['sport'] as String?;
          gameArgs = embeddedGameArgs ?? topLevelGameArgs;
          print(
              '🎯 ListsOfOfficialsScreen: Set isFromInsufficientLists=$isFromInsufficientLists, sport=$insufficientListsSport');
        }

        // Handle game creation context when newListCreated is present
        final isEdit = args['isEdit'] == true;
        isFromGameCreation = args['fromGameCreation'] == true &&
            args['fromHamburgerMenu'] != true &&
            !isEdit;

        _handleNewListFromReview(newListData);
      } else {
        // Refresh lists when coming from other routes
        _fetchLists();
      }
    } else {
      // No arguments (coming from hamburger menu) - fetch lists and hide green arrow
      print(
          '📱 ListsOfOfficialsScreen: No arguments detected (hamburger menu navigation)');
      setState(() {
        isFromGameCreation = false;
      });
      _fetchLists();
    }
  }

  Future<void> _selectPreSelectedList(
      String listName, Map<String, dynamic> originalArgs) async {
    // Wait a bit for the lists to be fetched and rendered
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Find the list in the current lists
    final listIndex = lists.indexWhere((list) => list['name'] == listName);

    if (listIndex != -1) {
      print(
          '✅ ListsOfOfficialsScreen: Found pre-selected list at index $listIndex');

      // Simulate selecting this list and navigating to review
      final selectedList = lists[listIndex];
      final result = {
        ...originalArgs,
        'selectedList': selectedList,
        'method': 'use_list',
        'officials': selectedList['officials'] ?? [],
      };

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/review-game-info',
          arguments: result,
        );
      }
    } else {
      print(
          '❌ ListsOfOfficialsScreen: Pre-selected list "$listName" not found in current lists');
      // If list not found, show an error and continue with normal flow
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Template list "$listName" not found. Please select a list manually.'),
          ),
        );
      }
    }
  }

  Future<void> _fetchLists() async {
    try {
      print('🔍 ListsOfOfficialsScreen: Starting to fetch lists...');
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final fetchedLists = await _listService.fetchOfficialLists();
      print(
          '✅ ListsOfOfficialsScreen: Fetched ${fetchedLists.length} lists from database');

      if (mounted) {
        setState(() {
          lists.clear();

          // Add the fetched lists
          lists.addAll(fetchedLists);
          print(
              '📋 ListsOfOfficialsScreen: Added ${fetchedLists.length} lists to display');

          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ListsOfOfficialsScreen: Error fetching lists: $e');
      if (mounted) {
        setState(() {
          lists = [];
          isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmationDialog(String listName, String listId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Confirm Delete',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$listName"?',
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
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _listService.deleteOfficialList(listId);
                await _fetchLists(); // Refresh the list
                selectedList = null;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('List deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting list: $e')),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
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
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown Sport';
    final fromTemplateCreation = args?['fromTemplateCreation'] == true;
    final isEdit = args?['isEdit'] == true;

    print(
        '🔍 ListsOfOfficialsScreen: build() called, sport="$sport", args=$args');

    // Filter out special items for the main list display
    List<Map<String, dynamic>> actualLists =
        lists.where((list) => list['id'] != '0' && list['id'] != '-1').toList();

    // If coming from template creation or game creation, filter by sport
    if ((fromTemplateCreation || isFromGameCreation) && sport != 'Unknown Sport') {
      actualLists = actualLists.where((list) {
        final listSport = list['sport'] as String?;
        return listSport == null || listSport.isEmpty || listSport == sport;
      }).toList();
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: IconButton(
          icon: Icon(
            Icons.sports, // Whistle-like sports icon
            color: colorScheme.primary,
            size: 32,
          ),
          onPressed: () {
            // Navigate back to Athletic Director home screen
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/ad-home',
              (route) => false, // Remove all routes
            );
          },
          tooltip: 'Back to Home',
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Completely disable automatic back arrow
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Lists of Officials',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Manage your saved lists of officials',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                        children: [
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : actualLists.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.people,
                                            size: 80,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No lists of officials found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Create your first list to get started',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            height: 50,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                // Re-evaluate sport from current args at button press time
                                                final currentArgs = ModalRoute
                                                            .of(context)!
                                                        .settings
                                                        .arguments
                                                    as Map<String, dynamic>?;
                                                final currentSport =
                                                    currentArgs?['sport']
                                                            as String? ??
                                                        'Unknown Sport';
                                                print(
                                                    '🔍 ListsOfOfficials: Create New List pressed');
                                                print(
                                                    '   - Build time sport: "$sport"');
                                                print(
                                                    '   - Current sport: "$currentSport"');
                                                print(
                                                    '   - Current args: $currentArgs');

                                                if (currentSport ==
                                                    'Unknown Sport') {
                                                  // Not in game creation flow - need to select sport first
                                                  print(
                                                      '🔄 ListsOfOfficials: Navigating to select sport screen');
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/select-sport',
                                                    arguments: {
                                                      'fromListsScreen': true,
                                                      'existingLists':
                                                          <String>[],
                                                    },
                                                  ).then((sportResult) {
                                                    if (sportResult != null &&
                                                        sportResult is String &&
                                                        mounted) {
                                                      // Now navigate to name list with the selected sport
                                                      Navigator.pushNamed(
                                                        context,
                                                        '/name-list',
                                                        arguments: {
                                                          'sport': sportResult,
                                                          'existingLists':
                                                              <String>[],
                                                          'fromListsScreen':
                                                              true,
                                                        },
                                                      ).then((result) {
                                                        if (result != null &&
                                                            mounted) {
                                                          _handleNewListFromReview(
                                                              result as Map<
                                                                  String,
                                                                  dynamic>);
                                                        }
                                                      });
                                                    }
                                                  });
                                                } else {
                                                  // Already in game creation flow with sport selected - go directly to name list
                                                  print(
                                                      '🔄 ListsOfOfficials: Going directly to name list with sport="$currentSport"');
                                                  final topNameListArgs = {
                                                    'sport': currentSport,
                                                    'existingLists': <String>[],
                                                    ...?args,
                                                    // Explicitly ensure fromGameCreation is passed
                                                    'fromGameCreation': isFromGameCreation || args?['fromGameCreation'] == true,
                                                  };

                                                  debugPrint(
                                                      '🎯 ListsOfOfficialsScreen: Top button passing to name_list_screen - fromGameCreation: ${topNameListArgs['fromGameCreation']}, fromInsufficientLists: ${args?['fromInsufficientLists']}, gameArgs: ${args?['gameArgs'] != null ? 'present' : 'null'}');
                                                  debugPrint(
                                                      '🎯 ListsOfOfficialsScreen: TopNameListArgs keys: ${topNameListArgs.keys.toList()}');

                                                  Navigator.pushNamed(
                                                    context,
                                                    '/name-list',
                                                    arguments: topNameListArgs,
                                                  ).then((result) {
                                                    if (result != null &&
                                                        mounted) {
                                                      // Restore contexts if they were lost
                                                      if (result is Map<String, dynamic>) {
                                                        // Restore game creation context
                                                        if (isFromGameCreation) {
                                                          result['fromGameCreation'] = true;
                                                          print('🎯 Restored game creation context to result');
                                                        }
                                                        // Restore Insufficient Lists context if it was lost
                                                        if (isFromInsufficientLists) {
                                                          result['fromInsufficientLists'] = true;
                                                          result['gameArgs'] = gameArgs;
                                                          print('🎯 Restored Insufficient Lists context to result');
                                                        }
                                                      }
                                                      _handleNewListFromReview(
                                                          result as Map<String,
                                                              dynamic>);
                                                    }
                                                  });
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    colorScheme.primary,
                                                foregroundColor:
                                                    colorScheme.onPrimary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 15,
                                                  horizontal: 32,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.add,
                                                color: colorScheme.onPrimary,
                                              ),
                                              label: Text(
                                                'Create New List',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: actualLists.length,
                                      itemBuilder: (context, index) {
                                        final list = actualLists[index];
                                        final listName = list['name'] as String;
                                        final officialCount =
                                            list['official_count'] as int? ??
                                                (list['officials']
                                                            as List<dynamic>? ??
                                                        [])
                                                    .length;

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.shadow
                                                      .withOpacity(0.1),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primary
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      Icons.people,
                                                      color:
                                                          colorScheme.primary,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            listName,
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: colorScheme
                                                                  .onSurface,
                                                            ),
                                                            softWrap: true,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          '$officialCount official${officialCount == 1 ? '' : 's'}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            '/edit-list',
                                                            arguments: {
                                                              'listName':
                                                                  listName,
                                                              'listId':
                                                                  list['id'],
                                                              'officials': list[
                                                                      'officials'] ??
                                                                  [],
                                                              'isEdit': true,
                                                            },
                                                          ).then((result) {
                                                            if (result !=
                                                                    null &&
                                                                mounted) {
                                                              // Refresh the lists to show any updates
                                                              _fetchLists();
                                                            }
                                                          });
                                                        },
                                                        icon: Icon(
                                                          Icons.edit,
                                                          color: colorScheme
                                                              .primary,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Edit List',
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          _showDeleteConfirmationDialog(
                                                              listName,
                                                              list['id']
                                                                  as String);
                                                        },
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color: Colors
                                                              .red.shade600,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Delete List',
                                                      ),
                                                      if (isFromGameCreation ||
                                                          isEdit)
                                                        IconButton(
                                                          onPressed: () {
                                                            if (!isEdit) {
                                                              setState(() {
                                                                selectedList =
                                                                    listName;
                                                              });
                                                            }
                                                            // Navigate to Review Game Info screen or return result for edit
                                                            _navigateToReviewGameInfo(
                                                                list);
                                                          },
                                                          icon: Icon(
                                                            isEdit
                                                                ? Icons.check
                                                                : Icons
                                                                    .arrow_forward,
                                                            color: isEdit
                                                                ? Colors.blue
                                                                : Colors.green,
                                                            size: 20,
                                                          ),
                                                          tooltip: isEdit
                                                              ? 'Select This List'
                                                              : 'Use This List',
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          if (!isLoading && actualLists.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Re-evaluate sport from current args at button press time
                                    final currentArgs = ModalRoute.of(context)!
                                        .settings
                                        .arguments as Map<String, dynamic>?;
                                    final currentSport =
                                        currentArgs?['sport'] as String? ??
                                            'Unknown Sport';
                                    print(
                                        '🔍 ListsOfOfficials: Bottom Create New List pressed');
                                    print('   - Build time sport: "$sport"');
                                    print(
                                        '   - Current sport: "$currentSport"');
                                    print('   - Current args: $currentArgs');

                                    if (currentSport == 'Unknown Sport') {
                                      // Not in game creation flow - need to select sport first
                                      print(
                                          '🔄 ListsOfOfficials: Bottom button - Navigating to select sport screen');
                                      Navigator.pushNamed(
                                        context,
                                        '/select-sport',
                                        arguments: {
                                          'fromListsScreen': true,
                                          'existingLists': actualLists
                                              .map((list) =>
                                                  list['name'] as String)
                                              .toList(),
                                        },
                                      ).then((sportResult) {
                                        if (sportResult != null &&
                                            sportResult is String &&
                                            mounted) {
                                          // Now navigate to name list with the selected sport
                                          Navigator.pushNamed(
                                            context,
                                            '/name-list',
                                            arguments: {
                                              'sport': sportResult,
                                              'existingLists': actualLists
                                                  .map((list) =>
                                                      list['name'] as String)
                                                  .toList(),
                                              'fromListsScreen': true,
                                            },
                                          ).then((result) {
                                            if (result != null && mounted) {
                                              _handleNewListFromReview(result
                                                  as Map<String, dynamic>);
                                            }
                                          });
                                        }
                                      });
                                    } else {
                                      // Already in game creation flow with sport selected - go directly to name list
                                      print(
                                          '🔄 ListsOfOfficials: Bottom button - Going directly to name list with sport="$currentSport"');
                                      final nameListArgs = {
                                        'sport': currentSport,
                                        'existingLists': actualLists
                                            .map((list) =>
                                                list['name'] as String)
                                            .toList(),
                                        ...?currentArgs,
                                        // Explicitly ensure fromGameCreation is passed
                                        'fromGameCreation': isFromGameCreation || currentArgs?['fromGameCreation'] == true,
                                      };

                                      debugPrint(
                                          '🎯 ListsOfOfficialsScreen: Bottom button passing to name_list_screen - fromGameCreation: ${nameListArgs['fromGameCreation']}, fromInsufficientLists: ${currentArgs?['fromInsufficientLists']}, gameArgs: ${currentArgs?['gameArgs'] != null ? 'present' : 'null'}');
                                      debugPrint(
                                          '🎯 ListsOfOfficialsScreen: NameListArgs keys: ${nameListArgs.keys.toList()}');

                                      Navigator.pushNamed(
                                        context,
                                        '/name-list',
                                        arguments: nameListArgs,
                                      ).then((result) {
                                        if (result != null && mounted) {
                                          // Restore contexts if they were lost
                                          if (result is Map<String, dynamic>) {
                                            // Restore game creation context
                                            if (isFromGameCreation) {
                                              result['fromGameCreation'] = true;
                                              print('🎯 Bottom button: Restored game creation context to result');
                                            }
                                          }
                                          _handleNewListFromReview(
                                              result as Map<String, dynamic>);
                                        }
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.add,
                                    color: colorScheme.onPrimary,
                                  ),
                                  label: Text(
                                    'Create New List',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  void _handleNewListFromReview(Map<String, dynamic> newListData) async {
    print('🎯 _handleNewListFromReview: Called with newListData: $newListData');

    // Check if we should maintain game creation context from multiple sources
    final currentArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Check all possible sources for game creation context
    final fromCurrentArgs = currentArgs?['fromGameCreation'] == true;
    final fromNewListData = newListData['fromGameCreation'] == true;
    final fromInstanceVariable = isFromGameCreation; // Check our instance variable
    
    final notFromHamburgerMenu = currentArgs?['fromHamburgerMenu'] != true && 
                                   newListData['fromHamburgerMenu'] != true;
    final isNotEdit = currentArgs?['isEdit'] != true && 
                      newListData['isEdit'] != true;
    
    // Determine if we're in game creation context from ANY source
    final shouldMaintainGameCreationContext = (fromCurrentArgs || fromNewListData || fromInstanceVariable) && 
                                               notFromHamburgerMenu && 
                                               isNotEdit;
    
    print('🎯 _handleNewListFromReview: Game creation context check:');
    print('   - fromCurrentArgs: $fromCurrentArgs');
    print('   - fromNewListData: $fromNewListData');
    print('   - fromInstanceVariable: $fromInstanceVariable');
    print('   - notFromHamburgerMenu: $notFromHamburgerMenu');
    print('   - isNotEdit: $isNotEdit');
    print('   - shouldMaintainGameCreationContext: $shouldMaintainGameCreationContext');

    // Refresh the lists to show the newly created list
    await _fetchLists();

    if (mounted) {
      setState(() {
        selectedList = newListData['listName'] as String;
        
        // IMPORTANT: Maintain the game creation context after creating a new list
        if (shouldMaintainGameCreationContext) {
          isFromGameCreation = true;
          print('🎯 _handleNewListFromReview: Setting isFromGameCreation = true');
          
          // DON'T overwrite saved game creation args with newListData
          // newListData only contains the list information, not the full game data
          // We want to KEEP the saved game args as they are
          print('🎯 _handleNewListFromReview: Keeping original saved game creation args intact');
          print('🎯 _handleNewListFromReview: _savedGameCreationArgs keys: ${_savedGameCreationArgs?.keys.toList()}');
        }
      });
    }

    if (mounted) {
      print('🎯 _handleNewListFromReview: SHOWING SNACKBAR');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your list was created successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
      print('🎯 _handleNewListFromReview: SNACKBAR SHOWN');
    }

    // Special handling for Insufficient Lists flow
    print('🎯 _handleNewListFromReview: Checking Insufficient Lists');
    print(
        '🎯 _handleNewListFromReview: - isFromInsufficientLists: $isFromInsufficientLists');
    print(
        '🎯 _handleNewListFromReview: - insufficientListsSport: $insufficientListsSport');
    print('🎯 _handleNewListFromReview: - gameArgs: $gameArgs');
    print(
        '🎯 _handleNewListFromReview: - current route args: ${ModalRoute.of(context)?.settings.arguments}');

    if (isFromInsufficientLists && insufficientListsSport != null) {
      print('🎯 _handleNewListFromReview: Triggering Insufficient Lists flow');
      // Add a small delay to ensure the UI is updated before showing the prompt
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleInsufficientListsFlow(newListData);
        }
      });
    } else {
      print(
          '🎯 _handleNewListFromReview: NOT triggering Insufficient Lists flow');
    }
  }

  Future<void> _handleInsufficientListsFlow(
      Map<String, dynamic> newListData) async {
    print('🎯 Insufficient Lists Flow: Starting flow check');
    print(
        '🎯 Insufficient Lists Flow: isFromInsufficientLists = $isFromInsufficientLists');
    print(
        '🎯 Insufficient Lists Flow: insufficientListsSport = $insufficientListsSport');
    print('🎯 Insufficient Lists Flow: gameArgs = $gameArgs');
    print(
        '🎯 Insufficient Lists Flow: Total lists in memory = ${lists.length}');

    // Count lists for the specific sport
    final sportLists = lists.where((list) {
      final listSport = list['sport'] as String?;
      final listName = list['name'] as String?;
      final isValidList =
          listName != 'No saved lists' && listName != '+ Create new list';
      final matchesSport = listSport == insufficientListsSport;

      print(
          '🎯 Checking list: "$listName", sport: "$listSport", valid: $isValidList, matches sport: $matchesSport');

      return matchesSport && isValidList;
    }).toList();

    final listCount = sportLists.length;

    print(
        '🎯 Insufficient Lists Flow: Created ${newListData['listName']} for $insufficientListsSport, now have $listCount valid lists for this sport');
    print(
        '🎯 Insufficient Lists Flow: Sport lists: ${sportLists.map((l) => l['name']).toList()}');

    if (listCount >= 2) {
      // We now have 2+ lists, navigate to Multiple Lists Setup
      print(
          '🎯 Insufficient Lists Flow: Have $listCount lists, navigating to Multiple Lists Setup');
      await _navigateToMultipleListsSetup();
    } else if (listCount == 1) {
      // We have exactly 1 list, show prompt to create second list
      print(
          '🎯 Insufficient Lists Flow: Have exactly 1 list, showing prompt to create second');
      await _showCreateSecondListPrompt();
    } else {
      print(
          '🎯 Insufficient Lists Flow: Have $listCount lists (should be 1 or 2+) - unexpected state');
    }
  }

  Future<void> _navigateToMultipleListsSetup() async {
    print('🎯 Navigating to Multiple Lists Setup');
    print('🎯 gameArgs: $gameArgs');
    print('🎯 insufficientListsSport: $insufficientListsSport');

    if (gameArgs == null) {
      print(
          '🎯 ERROR: gameArgs is null, cannot navigate to Multiple Lists Setup');
      return;
    }

    // Prepare arguments for Multiple Lists Setup screen
    final setupArgs = {
      ...gameArgs!,
      'sport': insufficientListsSport,
    };

    print('🎯 Multiple Lists Setup args: $setupArgs');

    // Navigate to Multiple Lists Setup screen
    Navigator.pushNamed(
      context,
      '/multiple-lists-setup',
      arguments: setupArgs,
    ).then((result) {
      if (result != null && mounted) {
        print(
            '🎯 Multiple Lists Setup returned result, navigating to review screen');
        // Navigate to review screen with multiple lists configuration
        Navigator.pushNamed(
          context,
          '/review-game-info',
          arguments: result,
        );
      }
    });
  }

  Future<void> _showCreateSecondListPrompt() async {
    print('🎯 Showing Create Second List Prompt');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Create Second List',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You now have 1 $insufficientListsSport list. The Multiple Lists method requires at least 2 lists. Would you like to create a second list?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('🎯 User chose "Maybe Later" - dismissing dialog');
              Navigator.pop(
                  context, false); // Return false to indicate no action
            },
            child: Text(
              'Maybe Later',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              print(
                  '🎯 User chose to create second list - closing dialog and starting creation flow');
              Navigator.pop(
                  context, true); // Return true to indicate create second list
            },
            child: Text(
              'Create Second List',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    print('🎯 Create Second List Prompt dialog result: $result');

    // Handle the user's choice
    if (result == true) {
      // User wants to create second list - navigate to name list screen
      _navigateToCreateSecondList();
    }
    // If result is false or null, do nothing (user chose "Maybe Later" or dismissed dialog)
  }

  void _navigateToCreateSecondList() {
    print('🎯 Navigating to create second list');
    print(
        '🎯 Create Second List: instance vars - isFromGameCreation: $isFromGameCreation, isFromInsufficientLists: $isFromInsufficientLists, insufficientListsSport: $insufficientListsSport, gameArgs: $gameArgs');

    final nameListArgs = {
      'sport': insufficientListsSport ?? 'Unknown Sport',
      'existingLists':
          <String>[], // Start with empty since we're creating second list
      // Explicitly pass game creation and Insufficient Lists context from instance variables
      'fromGameCreation': isFromGameCreation,
      'fromInsufficientLists': isFromInsufficientLists,
      'gameArgs': gameArgs,
    };

    print('🎯 Create Second List: final args for navigation: $nameListArgs');
    print(
        '🎯 Create Second List: sport = ${insufficientListsSport ?? 'Unknown Sport'}');
    print('🎯 Create Second List: context mounted = $mounted');

    if (mounted) {
      Navigator.pushNamed(
        context,
        '/name-list',
        arguments: nameListArgs,
      ).then((result) {
        print('🎯 Create Second List: navigation completed, result = $result');
        if (result != null && mounted) {
          print('🎯 Create Second List: returned from name-list with result');
          // Restore game creation context if needed
          if (result is Map<String, dynamic> && isFromGameCreation) {
            result['fromGameCreation'] = true;
            print('🎯 Create Second List: Restored game creation context to result');
          }
          _handleNewListFromReview(result as Map<String, dynamic>);
        } else {
          print('🎯 Create Second List: no result or not mounted');
        }
      });
    } else {
      print('🎯 Create Second List: context not mounted, skipping navigation');
    }
  }

  void _navigateToReviewGameInfo(Map<String, dynamic> list) {
    // Use saved game creation args if available, otherwise fall back to current route args
    final args = _savedGameCreationArgs ?? 
        (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {});

    print('🎯 _navigateToReviewGameInfo: ========== START ==========');
    print('🎯 _navigateToReviewGameInfo: _savedGameCreationArgs = $_savedGameCreationArgs');
    print('🎯 _navigateToReviewGameInfo: Current route args = ${ModalRoute.of(context)!.settings.arguments}');
    print('🎯 _navigateToReviewGameInfo: Using args keys: ${args.keys.toList()}');
    print('🎯 _navigateToReviewGameInfo: List: ${list['name']}');
    print('🎯 _navigateToReviewGameInfo: sport = ${args['sport']}');
    print('🎯 _navigateToReviewGameInfo: date = ${args['date']}');
    print('🎯 _navigateToReviewGameInfo: time = ${args['time']}');
    print('🎯 _navigateToReviewGameInfo: location = ${args['location']}');
    print('🎯 _navigateToReviewGameInfo: opponent = ${args['opponent']}');
    print('🎯 _navigateToReviewGameInfo: scheduleName = ${args['scheduleName']}');

    // Check if this is edit mode
    final isEdit = args['isEdit'] == true;

    if (isEdit) {
      // In edit mode, return the selected list data back to the calling screen
      final result = {
        ...args,
        'method': 'use_list',
        'selectedListName': list['name'],
        'selectedOfficials': list['officials'] ?? [],
      };

      print('🎯 _navigateToReviewGameInfo: Returning result for edit mode');
      Navigator.pop(context, result);
    } else {
      // Normal game creation flow
      final gameData = {
        ...args,
        'method': 'use_list',
        'selectedListName': list['name'],
        'selectedOfficials': list['officials'] ?? [],
      };

      print('🎯 _navigateToReviewGameInfo: Navigating to review with gameData keys: ${gameData.keys.toList()}');
      print('🎯 _navigateToReviewGameInfo: gameData sport = ${gameData['sport']}');
      print('🎯 _navigateToReviewGameInfo: gameData date = ${gameData['date']}');
      print('🎯 _navigateToReviewGameInfo: gameData time = ${gameData['time']}');
      print('🎯 _navigateToReviewGameInfo: ========== END ==========');
      
      Navigator.pushNamed(
        context,
        '/review-game-info',
        arguments: gameData,
      );
    }
  }
}
