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
  Map<int, bool> selectedOfficials = {};
  bool isFromGameCreation = false;
  String? listName;
  String? sport;
  bool hasAppliedFilters = false;

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

  void _showFilterDialog() {
    Navigator.pushNamed(context, '/filter-settings').then((result) {
      if (result != null && mounted) {
        _applyFilters(result as Map<String, dynamic>);
      }
    });
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
      final officialId = o['id'];
      return officialId is int && (selectedOfficials[officialId] ?? false);
    }).toList();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final updatedArgs = {
      ...args,
      'selectedOfficials': selected,
      'listName': listName,
      'sport': sport,
    };

    // For now, just pop back with the results
    Navigator.pop(context, updatedArgs);
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
                  constraints: const BoxConstraints(maxWidth: 600),
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
                  constraints: const BoxConstraints(maxWidth: 600),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !hasAppliedFilters
                      ? Center(
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
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showFilterDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 32,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.filter_list,
                                  color: colorScheme.onPrimary,
                                ),
                                label: Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredOfficials.isEmpty
                          ? Center(
                              child: Text(
                                'No officials found.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                // Select All checkbox
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: filteredOfficials.every((o) {
                                          final officialId = o['id'] as int;
                                          return selectedOfficials[
                                                  officialId] ??
                                              false;
                                        }),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              for (final o
                                                  in filteredOfficials) {
                                                final officialId =
                                                    o['id'] as int;
                                                selectedOfficials[officialId] =
                                                    true;
                                              }
                                            } else {
                                              for (final o
                                                  in filteredOfficials) {
                                                final officialId =
                                                    o['id'] as int;
                                                selectedOfficials
                                                    .remove(officialId);
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
                                          fontSize: 16,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(20.0),
                                    itemCount: filteredOfficials.length,
                                    itemBuilder: (context, index) {
                                      final official = filteredOfficials[index];
                                      final officialId = official['id'] as int;
                                      final isSelected =
                                          selectedOfficials[officialId] ??
                                              false;

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8.0),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceVariant,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.outline
                                                    .withOpacity(0.3),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.all(16),
                                          leading: IconButton(
                                            icon: Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons.add_circle,
                                              color: isSelected
                                                  ? Colors.green
                                                  : colorScheme.primary,
                                              size: 28,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                selectedOfficials[officialId] =
                                                    !isSelected;
                                                if (isSelected) {
                                                  selectedOfficials
                                                      .remove(officialId);
                                                }
                                              });
                                            },
                                          ),
                                          title: Text(
                                            official['name'] as String,
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${official['cityState'] ?? 'Unknown location'}',
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Distance: ${official['distance']?.toStringAsFixed(1) ?? '0.0'} mi • Experience: ${official['yearsExperience'] ?? 0} yrs',
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),

            // Bottom section with selected count and continue button
            if (hasAppliedFilters && filteredOfficials.isNotEmpty)
              Container(
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
                          width: double.infinity,
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
              ),
          ],
        ),
      ),
    );
  }
}
