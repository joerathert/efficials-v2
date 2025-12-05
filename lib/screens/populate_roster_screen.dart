import 'package:flutter/material.dart';
import '../services/official_service.dart';

class PopulateRosterScreen extends StatefulWidget {
  const PopulateRosterScreen({super.key});

  @override
  State<PopulateRosterScreen> createState() => _PopulateRosterScreenState();
}

class _PopulateRosterScreenState extends State<PopulateRosterScreen> {
  String searchQuery = '';
  List<Map<String, dynamic>> officials = [];
  List<Map<String, dynamic>> filteredOfficials = [];
  bool isLoading = false;
  Map<String, bool> selectedOfficials = {};
  bool isFromGameCreation = false;
  bool fromInsufficientLists = false;
  Map<String, dynamic>? gameArgs;
  String? listName;
  String? sport;
  bool hasAppliedFilters = false;
  Map<String, dynamic> filters = {};

  @override
  void initState() {
    super.initState();
    // No initial loading - wait for filters
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    print(
        '🎯 PopulateRosterScreen: didChangeDependencies called with args: ${args != null ? "present" : "null"}');

    if (args != null) {
      print('🎯 PopulateRosterScreen: Processing arguments...');
      sport = args['sport'] as String?;
      listName = args['listName'] as String?;
      isFromGameCreation = args['fromGameCreation'] == true;
      fromInsufficientLists = args['fromInsufficientLists'] as bool? ?? false;
      gameArgs = args['gameArgs'] as Map<String, dynamic>?;

      debugPrint('🎯 PopulateRosterScreen: RECEIVED ARGS:');
      debugPrint(
          '🎯 PopulateRosterScreen: - fromInsufficientLists: $fromInsufficientLists');
      debugPrint(
          '🎯 PopulateRosterScreen: - gameArgs present: ${gameArgs != null}');
      debugPrint('🎯 PopulateRosterScreen: - all keys: ${args.keys.toList()}');
      // Also handle lists screen flow
      final fromListsScreen = args['fromListsScreen'] == true;
      if (fromListsScreen && !isFromGameCreation) {
        isFromGameCreation =
            false; // Not from game creation, but from lists screen
      }

      // Handle selected officials from arguments (when editing existing list)
      final selectedOfficialsFromArgs =
          args['selectedOfficials'] as List<Map<String, dynamic>>?;
      final selectedOfficialIds = args['selectedOfficialIds'] as List<dynamic>?;

      if (selectedOfficialsFromArgs != null) {
        selectedOfficials.clear();
        for (var official in selectedOfficialsFromArgs) {
          final officialId = official['id'] as String?;
          if (officialId != null) {
            selectedOfficials[officialId] = true;
          }
        }
        print(
            '🎯 PopulateRosterScreen: Pre-selected ${selectedOfficialsFromArgs.length} officials from full objects');
      } else if (selectedOfficialIds != null) {
        selectedOfficials.clear();
        for (var id in selectedOfficialIds) {
          final officialId = id?.toString();
          if (officialId != null) {
            selectedOfficials[officialId] = true;
          }
        }
        print(
            '🎯 PopulateRosterScreen: Pre-selected ${selectedOfficialIds.length} officials from IDs');
      }

      // Handle coming from edit list screen - automatically load officials
      final isFromEditList = args['isFromEditList'] == true;
      print(
          '🎯 PopulateRosterScreen: isFromEditList = $isFromEditList, sport = $sport');
      if (isFromEditList && sport != null && mounted) {
        print(
            '🎯 PopulateRosterScreen: Coming from edit list, auto-loading officials for sport: $sport');
        // Auto-apply default filters to load officials immediately
        final defaultFilters = {
          'sport': sport,
          // Add any other default filters as needed
        };
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyFilters(defaultFilters);
        });
      }
    } else {
      print('🎯 PopulateRosterScreen: No arguments received');
    }
  }

  void _applyFilters(Map<String, dynamic>? filterSettings) {
    if (filterSettings != null) {
      print('🎯 PopulateRosterScreen: Applying filters: $filterSettings');

      setState(() {
        isLoading = true;
        hasAppliedFilters = true;
        filters = filterSettings; // Store the filters
      });

      // Query the database with filters
      final officialService = OfficialService();
      officialService
          .getFilteredOfficials(
        sport: filterSettings['sport'] ?? 'Football',
        ihsaLevel: filterSettings['ihsaLevel'],
        minYears: filterSettings['minYears'],
        levels: filterSettings['levels']?.cast<String>(),
        radius: filterSettings['radius'],
        locationData: filterSettings['locationData'],
      )
          .then((results) {
        print(
            '🎯 PopulateRosterScreen: Filter results received: ${results.length} officials');

        if (mounted) {
          setState(() {
            officials = results;
            filteredOfficials = List.from(results);
            isLoading = false;
          });

          // Clear any selections that are no longer in the filtered results
          final validIds = results.map((o) => o['id'] as String).toSet();
          selectedOfficials.removeWhere((id, _) => !validIds.contains(id));

          print(
              '🎯 PopulateRosterScreen: After filtering, ${selectedOfficials.length} officials still selected');

          if (results.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('No officials found matching the selected filters.'),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Found ${results.length} officials matching your filters.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }).catchError((error) {
        print('❌ PopulateRosterScreen: Error applying filters: $error');

        if (mounted) {
          setState(() {
            officials = [];
            filteredOfficials = [];
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading officials: $error'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  void filterOfficials(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredOfficials = List.from(officials);
      } else {
        filteredOfficials = officials
            .where((official) => official['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _handleContinue() {
    final selected = officials.where((o) {
      final officialId = o['id'] as String;
      return selectedOfficials[officialId] ?? false;
    }).toList();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final fromListsScreen = args['fromListsScreen'] == true;
    final isFromEditList = args['isFromEditList'] == true;

    if (isFromEditList) {
      // Coming from edit list screen - return selected officials back
      print(
          '🎯 PopulateRosterScreen: Returning selected officials to edit list screen');
      Navigator.pop(context, selected);
      return;
    }

    final reviewArgs = {
      ...args,
      'selectedOfficials': selected,
      'listName': listName,
      'sport': sport,
      // Explicitly preserve Insufficient Lists context
      'fromInsufficientLists': fromInsufficientLists,
      'gameArgs': gameArgs,
    };

    debugPrint('🎯 PopulateRosterScreen: CREATING REVIEW ARGS:');
    debugPrint(
        '🎯 PopulateRosterScreen: - fromInsufficientLists: $fromInsufficientLists');
    debugPrint(
        '🎯 PopulateRosterScreen: - gameArgs present: ${gameArgs != null}');
    debugPrint(
        '🎯 PopulateRosterScreen: - reviewArgs keys: ${reviewArgs.keys.toList()}');
    debugPrint(
        '🎯 PopulateRosterScreen: - reviewArgs[fromInsufficientLists]: ${reviewArgs['fromInsufficientLists']}');
    debugPrint(
        '🎯 PopulateRosterScreen: - reviewArgs[gameArgs]: ${reviewArgs['gameArgs']}');

    print('🎯 PopulateRosterScreen: About to navigate to ReviewListScreen');
    print(
        '🎯 PopulateRosterScreen: reviewArgs keys: ${reviewArgs.keys.toList()}');
    print(
        '🎯 PopulateRosterScreen: reviewArgs[fromInsufficientLists]: ${reviewArgs['fromInsufficientLists']}');

    if (fromListsScreen) {
      // Coming from lists screen - navigate to review list screen
      print(
          '🎯 PopulateRosterScreen: Navigating to ReviewListScreen from lists screen');
      Navigator.pushNamed(context, '/review-list', arguments: reviewArgs);
    } else {
      // Coming from game creation - navigate to review list screen
      print(
          '🎯 PopulateRosterScreen: Navigating to ReviewListScreen from game creation');
      Navigator.pushNamed(context, '/review-list', arguments: reviewArgs);
    }
  }

  Widget _buildOfficialsList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasAppliedFilters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list,
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Apply filters to populate the roster',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/filter-settings',
                  arguments: {
                    'sport': sport,
                    'previousFilters': filters,
                  },
                ).then((filterResult) {
                  if (filterResult != null &&
                      filterResult is Map<String, dynamic>) {
                    _applyFilters(filterResult);
                  }
                });
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: Icon(
                Icons.filter_list,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Adjust Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (filteredOfficials.isEmpty && hasAppliedFilters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No officials meet the current filter parameters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try broadening your search criteria',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/filter-settings',
                  arguments: {
                    'sport': sport,
                    'previousFilters': filters,
                  },
                ).then((filterResult) {
                  if (filterResult != null &&
                      filterResult is Map<String, dynamic>) {
                    _applyFilters(filterResult);
                  }
                });
              },
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: Icon(
                Icons.filter_list,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'Adjust Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // When filters are applied, also show the filter button
    return Column(
      children: [
        // Select All checkbox
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Row(
                children: [
                  Checkbox(
                    value: filteredOfficials.every((o) {
                      final officialId = o['id'] as String;
                      return selectedOfficials[officialId] ?? false;
                    }),
                    onChanged: (value) {
                      if (value == true) {
                        // Select all
                        setState(() {
                          for (final official in filteredOfficials) {
                            final officialId = official['id'] as String;
                            selectedOfficials[officialId] = true;
                          }
                        });
                      } else {
                        // Deselect all
                        setState(() {
                          for (final official in filteredOfficials) {
                            final officialId = official['id'] as String;
                            selectedOfficials[officialId] = false;
                          }
                        });
                      }
                    },
                    activeColor: colorScheme.primary,
                    checkColor: colorScheme.onPrimary,
                  ),
                  Text(
                    'Select all',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: filteredOfficials.length,
            itemBuilder: (context, index) {
              final official = filteredOfficials[index];
              final officialId = official['id'] as String;
              final isSelected = selectedOfficials[officialId] ?? false;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: colorScheme.onPrimary,
                                size: 20,
                              )
                            : Icon(
                                Icons.add,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                      ),
                      title: Text(
                        official['name'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Experience: ${official['yearsExperience'] ?? 0} years',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'IHSA Level: ${official['ihsaLevel'] ?? 'registered'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Distance: ${official['distance']?.toStringAsFixed(1) ?? 'N/A'} miles',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Follow-Through: ${(official['followThroughRate'] ?? 100.0).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          final currentValue =
                              selectedOfficials[officialId] ?? false;
                          selectedOfficials[officialId] = !currentValue;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Continue button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      selectedOfficials.values.any((selected) => selected)
                          ? _handleContinue
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedOfficials.values.any((selected) => selected)
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant,
                    foregroundColor:
                        selectedOfficials.values.any((selected) => selected)
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue (${selectedOfficials.values.where((selected) => selected).length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            // Navigate to Athletic Director home screen
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/ad-home',
              (route) => false, // Remove all routes
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
        child: _buildOfficialsList(),
      ),
      floatingActionButton: hasAppliedFilters
          ? Stack(
              children: [
                Positioned(
                  bottom: 40,
                  right: (MediaQuery.of(context).size.width -
                              (MediaQuery.of(context).size.width > 550
                                  ? 550
                                  : MediaQuery.of(context).size.width)) /
                          2 +
                      20, // Position FAB 20px from the right edge of the constrained content area
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/filter-settings',
                        arguments: {
                          'sport': sport,
                          'previousFilters': filters,
                        },
                      ).then((filterResult) {
                        if (filterResult != null &&
                            filterResult is Map<String, dynamic>) {
                          _applyFilters(filterResult);
                        }
                      });
                    },
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    child: const Icon(
                      Icons.filter_list,
                      size: 28,
                    ),
                    tooltip: 'Filter Officials',
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
