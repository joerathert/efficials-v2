import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';

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
  GameTemplateModel? template;

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
    if (args != null) {
      setState(() {
        isFromGameCreation = args['fromGameCreation'] == true;
        template = args['template'] as GameTemplateModel?;
      });

      // Handle new list creation from review_list_screen
      if (args['newListCreated'] != null) {
        final newListData = args['newListCreated'] as Map<String, dynamic>;
        _handleNewListFromReview(newListData);
      } else if (lists.length <= 2 && lists[0]['name'] == 'No saved lists') {
        _fetchLists();
      }
    }

    // Always refresh the lists when this screen becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchLists();
      }
    });
  }

  Future<void> _fetchLists() async {
    try {
      // TODO: Replace with actual Firebase query when Firebase services are implemented
      // For now, simulate querying Firestore and return empty result
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        lists.clear();

        // Simulate no lists in Firestore (empty result)
        // In real implementation, this would be:
        // final userLists = await FirebaseFirestore.instance
        //     .collection('official_lists')
        //     .where('userId', isEqualTo: currentUserId)
        //     .get();

        // For now, show empty state
        lists.add({'name': 'No saved lists', 'id': -1});
        lists.add({'name': '+ Create new list', 'id': 0});
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        lists = [
          {'name': 'No saved lists', 'id': -1},
          {'name': '+ Create new list', 'id': 0},
        ];
        isLoading = false;
      });
    }
  }

  void _showDeleteConfirmationDialog(String listName, int listId) {
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                lists.removeWhere((list) => list['id'] == listId);
                if (lists.isEmpty ||
                    (lists.length == 1 && lists[0]['id'] == 0)) {
                  lists.insert(0, {'name': 'No saved lists', 'id': -1});
                }
                selectedList = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('List deleted successfully')),
              );
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

  void _handleContinue() {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Game data not found')),
      );
      return;
    }
    final selected = lists.firstWhere((l) => l['name'] == selectedList);
    final officialsRaw = selected['officials'];
    List<Map<String, dynamic>> selectedOfficials = [];

    if (officialsRaw != null && officialsRaw is List) {
      selectedOfficials = (officialsRaw)
          .map((official) => Map<String, dynamic>.from(official as Map))
          .toList();
    }

    final updatedArgs = {
      ...args,
      'selectedOfficials': selectedOfficials,
      'method': 'use_list',
      'selectedListName': selectedList,
    };

    Navigator.pop(context, updatedArgs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown Sport';
    final fromTemplateCreation = args?['fromTemplateCreation'] == true;

    // Filter out special items for the main list display
    List<Map<String, dynamic>> actualLists =
        lists.where((list) => list['id'] != 0 && list['id'] != -1).toList();

    // If coming from template creation, filter by sport
    if (fromTemplateCreation && sport != 'Unknown Sport') {
      actualLists = actualLists.where((list) {
        final listSport = list['sport'] as String?;
        return listSport == null || listSport.isEmpty || listSport == sport;
      }).toList();
    }

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
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // TODO: Navigate to create list screen
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Create list functionality not yet implemented for $sport',
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  colorScheme.primary,
                                              foregroundColor:
                                                  colorScheme.onPrimary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 15,
                                                      horizontal: 32),
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
                                                      children: [
                                                        Text(
                                                          listName,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
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
                                                          // TODO: Navigate to edit list screen
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Edit functionality not yet implemented'),
                                                            ),
                                                          );
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
                                                                  as int);
                                                        },
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color: Colors
                                                              .red.shade600,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Delete List',
                                                      ),
                                                      if (isFromGameCreation)
                                                        IconButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              selectedList =
                                                                  listName;
                                                            });
                                                            _handleContinue();
                                                          },
                                                          icon: Icon(
                                                            Icons.arrow_forward,
                                                            color: Colors.green,
                                                            size: 20,
                                                          ),
                                                          tooltip:
                                                              'Use This List',
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
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Navigate to create list screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Create list functionality not yet implemented for $sport',
                                      ),
                                    ),
                                  );
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
    await _fetchLists();

    setState(() {
      selectedList = newListData['listName'] as String;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your list was created successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
