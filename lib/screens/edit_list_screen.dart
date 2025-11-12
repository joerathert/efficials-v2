import 'package:flutter/material.dart';
import '../services/official_list_service.dart';
import 'populate_roster_screen.dart';

class EditListScreen extends StatefulWidget {
  const EditListScreen({super.key});

  @override
  State<EditListScreen> createState() => _EditListScreenState();
}

class _EditListScreenState extends State<EditListScreen> {
  late Map<String, dynamic> args;
  String searchQuery = '';
  late List<Map<String, dynamic>> selectedOfficialsList;
  late List<Map<String, dynamic>> filteredOfficials;
  Map<String, bool> selectedOfficials = {};
  bool isInitialized = false;
  String? listName;
  String? listId;
  final TextEditingController _listNameController = TextEditingController();
  final OfficialListService _listService = OfficialListService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      try {
        final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        if (arguments == null) {
          throw Exception('No arguments provided to EditListScreen');
        }

        args = arguments; // Store args as class field
        listName = arguments['listName'] as String? ?? 'Unknown List';
        listId = arguments['listId'] as String?;
        final officialsRaw = arguments['officials'];

        print('🎯 EditListScreen: Received arguments: $arguments');
        print('🎯 EditListScreen: officials raw: $officialsRaw, type: ${officialsRaw?.runtimeType}');

        // Safely convert officials list
        if (officialsRaw is List) {
          selectedOfficialsList = officialsRaw.map((official) {
            if (official is Map<String, dynamic>) {
              return official;
            } else if (official is Map) {
              return Map<String, dynamic>.from(official);
            } else {
              print('⚠️ EditListScreen: Unexpected official type: ${official.runtimeType}');
              return <String, dynamic>{'name': 'Unknown Official', 'id': 'unknown'};
            }
          }).toList();
        } else {
          selectedOfficialsList = [];
        }

        print('🎯 EditListScreen: Converted ${selectedOfficialsList.length} officials');

        filteredOfficials = List.from(selectedOfficialsList);
        _listNameController.text = listName ?? 'Unnamed List';

        // Initialize selected officials map
        for (var official in selectedOfficialsList) {
          final officialId = official['id'];
          if (officialId != null) {
            final idString = officialId.toString();
            selectedOfficials[idString] = true;
            print('🎯 EditListScreen: Selected official: $idString - ${official['name']}');
          } else {
            print('⚠️ EditListScreen: Official missing ID: ${official['name']}');
          }
        }

        isInitialized = true;
        print('✅ EditListScreen: Initialization complete');
      } catch (e, stackTrace) {
        print('❌ EditListScreen: Error in didChangeDependencies: $e');
        print('❌ EditListScreen: Stack trace: $stackTrace');
        // Don't rethrow - let the UI handle it gracefully
      }
    }
  }

  void filterOfficials(String query) {
    setState(() {
      searchQuery = query;
      filteredOfficials = List.from(selectedOfficialsList);
      if (query.isNotEmpty) {
        filteredOfficials = filteredOfficials
            .where((official) => (official['name'] as String?)?.toLowerCase().contains(query.toLowerCase()) ?? false)
            .toList();
      }
    });
  }

  Future<void> _saveList() async {
    try {
      print('🎯 EditListScreen: Starting save process');

      final updatedOfficials = selectedOfficialsList
          .where((official) {
            final officialId = official['id']?.toString();
            final isSelected = officialId != null && (selectedOfficials[officialId] ?? false);
            print('🎯 EditListScreen: Checking official ${official['name']}, ID: $officialId, selected: $isSelected');
            return isSelected;
          })
          .toList();

      print('🎯 EditListScreen: ${updatedOfficials.length} officials selected for saving');

      final newListName = _listNameController.text.trim();

      // Check for duplicate names (excluding the current list)
      final existingLists = await _listService.fetchOfficialLists();
      final nameExists = existingLists.any((list) =>
          list['name'] == newListName && list['id'] != listId);
      if (nameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A list with this name already exists!')),
          );
        }
        return;
      }

      // Update list name if changed
      if (listId != null && newListName != listName) {
        print('🎯 EditListScreen: Updating list name from "$listName" to "$newListName"');
        await _listService.updateListName(listId!, newListName);
      }

      // Update officials in list
      if (listId != null) {
        print('🎯 EditListScreen: Updating officials in list $listId');
        await _listService.updateListOfficials(listId!, updatedOfficials);
      }

      final updatedList = {
        'name': newListName,
        'officials': updatedOfficials,
        'id': listId,
      };

      print('🎯 EditListScreen: Save complete, returning updated list');

      if (mounted) {
        // Return the updated list data to the previous screen
        Navigator.pop(context, updatedList);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('List updated!'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e, stackTrace) {
      print('❌ EditListScreen: Error saving list: $e');
      print('❌ EditListScreen: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating list: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int selectedCount = selectedOfficials.values.where((selected) => selected).length;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: IconButton(
          icon: Icon(
            Icons.sports,
            color: colorScheme.primary,
            size: 32,
          ),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/ad-home',
              (route) => false,
            );
          },
          tooltip: 'Home',
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Edit List',
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
                  TextField(
                    controller: _listNameController,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'List Name',
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Search Officials',
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
                    onChanged: (value) => filterOfficials(value),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: filteredOfficials.isEmpty
                          ? Center(
                              child: Text(
                                'No officials in this list.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: filteredOfficials.isNotEmpty &&
                                          filteredOfficials.every((official) {
                                            final officialId = official['id']?.toString();
                                            return officialId != null && (selectedOfficials[officialId] ?? false);
                                          }),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            for (final official in filteredOfficials) {
                                              final officialId = official['id']?.toString();
                                              if (officialId != null) {
                                                selectedOfficials[officialId] = true;
                                              }
                                            }
                                          } else {
                                            for (final official in filteredOfficials) {
                                              final officialId = official['id']?.toString();
                                              if (officialId != null) {
                                                selectedOfficials.remove(officialId);
                                              }
                                            }
                                          }
                                        });
                                      },
                                      activeColor: colorScheme.primary,
                                      checkColor: colorScheme.onPrimary,
                                    ),
                                    Text(
                                      'Select all',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: filteredOfficials.length,
                                    itemBuilder: (context, index) {
                                      final official = filteredOfficials[index];
                                      final officialId = official['id']?.toString();
                                      final isSelected = officialId != null && (selectedOfficials[officialId] ?? false);

                                      return ListTile(
                                        key: ValueKey(officialId ?? 'unknown-$index'),
                                        leading: IconButton(
                                          icon: Icon(
                                            isSelected ? Icons.check_circle : Icons.add_circle,
                                            color: isSelected ? Colors.green : colorScheme.primary,
                                            size: 36,
                                          ),
                                          onPressed: () {
                                            if (officialId != null) {
                                              setState(() {
                                                final wasSelected = selectedOfficials[officialId] ?? false;
                                                selectedOfficials[officialId] = !wasSelected;
                                                if (selectedOfficials[officialId] == false) {
                                                  selectedOfficials.remove(officialId);
                                                }
                                              });
                                            }
                                          },
                                        ),
                                        title: Text(
                                          '${official['name'] ?? 'Unknown'} (${official['cityState'] ?? 'Unknown'})',
                                          style: TextStyle(color: colorScheme.onSurface),
                                        ),
                                        subtitle: Text(
                                          'Distance: ${official['distance'] != null ? (official['distance'] as num).toStringAsFixed(1) : '0.0'} mi, Experience: ${official['yearsExperience'] ?? 0} yrs',
                                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
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
                        Center(
                          child: Text(
                            '($selectedCount) Selected',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 400,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final currentlySelected = selectedOfficialsList.where((official) {
                                final officialId = official['id']?.toString();
                                return officialId != null && (selectedOfficials[officialId] ?? false);
                              }).toList();

                          // Get sport from the first selected official, or fall back to args sport, or default to 'Football'
                          final sport = currentlySelected.isNotEmpty
                              ? currentlySelected.first['sport'] ?? args['sport'] ?? 'Football'
                              : args['sport'] ?? 'Football';

                              print('🎯 EditListScreen: Navigating to populate_roster with sport: $sport, selected: ${currentlySelected.length}');

                              // Use MaterialPageRoute to avoid route table issues
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => PopulateRosterScreen(),
                                  settings: RouteSettings(
                                    arguments: {
                                      'sport': sport,
                                      'listName': listName,
                                      'listId': listId,
                                      'selectedOfficialIds': currentlySelected.map((o) => o['id']).toList(),
                                      'isEdit': true,
                                      'isFromEditList': true,
                                    },
                                  ),
                                ),
                              ).then((result) {
                                print('🎯 EditListScreen: Returned from populate_roster with result: ${result != null ? "success" : "null"}');
                                if (result != null && mounted) {
                                  final resultList = result as List<Map<String, dynamic>>;

                                  setState(() {
                                    selectedOfficialsList = resultList;
                                    filteredOfficials = List.from(selectedOfficialsList);
                                    selectedOfficials.clear();
                                    for (var official in selectedOfficialsList) {
                                      final officialId = official['id']?.toString();
                                      if (officialId != null) {
                                        selectedOfficials[officialId] = true;
                                      }
                                    }
                                  });
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Add Official(s)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 400,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: selectedCount > 0 ? _saveList : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedCount > 0
                                  ? colorScheme.primary
                                  : colorScheme.surfaceVariant,
                              foregroundColor: selectedCount > 0
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Save List',
                              style: TextStyle(
                                color: selectedCount > 0
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
    );
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }
}
