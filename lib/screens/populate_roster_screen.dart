import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
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
    if (args != null) {
      sport = args['sport'] as String?;
      listName = args['listName'] as String?;
      isFromGameCreation = args['fromGameCreation'] == true;
      // Also handle lists screen flow
      final fromListsScreen = args['fromListsScreen'] == true;
      if (fromListsScreen && !isFromGameCreation) {
        isFromGameCreation =
            false; // Not from game creation, but from lists screen
      }
    }
  }

  void _applyFilters(Map<String, dynamic>? filterSettings) {
    if (filterSettings != null) {
      setState(() {
        isLoading = true;
        hasAppliedFilters = true;
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
        if (mounted) {
          setState(() {
            officials = results;
            filteredOfficials = List.from(results);
            isLoading = false;
          });

          if (results.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('No officials found matching the selected filters.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }).catchError((error) {
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

    final reviewArgs = {
      ...args,
      'selectedOfficials': selected,
      'listName': listName,
      'sport': sport,
    };

    if (fromListsScreen) {
      // Coming from lists screen - navigate to review list screen
      Navigator.pushNamed(context, '/review-list', arguments: reviewArgs);
    } else {
      // Coming from game creation - navigate to review list screen
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int selectedCount =
        selectedOfficials.values.where((selected) => selected).length;

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
        child: Column(
          children: [
            // Header with list name
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      Text(
                        listName ?? 'Populate Roster',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select officials for your $sport list',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search field (only show after filters are applied)
            if (hasAppliedFilters) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search officials...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search,
                          color: colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(color: colorScheme.onSurface),
                    onChanged: filterOfficials,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Officials list
            Expanded(
              child: _buildOfficialsList(),
            ),
            // Bottom section with selected count and continue button
            (hasAppliedFilters && filteredOfficials.isNotEmpty)
                ? Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$selectedCount selected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 400,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    selectedCount > 0 ? _handleContinue : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  disabledBackgroundColor:
                                      colorScheme.surfaceVariant,
                                  disabledForegroundColor:
                                      colorScheme.onSurfaceVariant,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: selectedCount > 0
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
