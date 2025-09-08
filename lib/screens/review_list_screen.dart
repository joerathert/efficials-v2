import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/official_list_service.dart';

class ReviewListScreen extends StatefulWidget {
  const ReviewListScreen({super.key});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  String searchQuery = '';
  late List<Map<String, dynamic>> selectedOfficialsList;
  late List<Map<String, dynamic>> filteredOfficials;
  Map<String, bool> selectedOfficials = {};
  bool isInitialized = false;
  String? sport;
  String? listName;
  bool isEdit = false;
  int? listId;
  final OfficialListService _listService = OfficialListService();

  @override
  void initState() {
    super.initState();
    selectedOfficialsList = [];
    filteredOfficials = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      try {
        final arguments =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

        sport = arguments['sport'] as String? ?? 'Football';
        listName = arguments['listName'] as String? ?? 'Unnamed List';
        listId = arguments['listId'] as int?;
        isEdit = arguments['isEdit'] as bool? ?? false;

        final selectedOfficialsRaw = arguments['selectedOfficials'];

        if (selectedOfficialsRaw is List) {
          selectedOfficialsList = selectedOfficialsRaw.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              throw Exception(
                  'Invalid official data type: ${item.runtimeType}');
            }
          }).toList();
        } else {
          throw Exception(
              'selectedOfficials is not a List: ${selectedOfficialsRaw.runtimeType}');
        }

        filteredOfficials = List.from(selectedOfficialsList);

        for (var official in selectedOfficialsList) {
          final officialId = official['id'];
          if (officialId is String) {
            selectedOfficials[officialId] = true;
          }
        }

        isInitialized = true;
      } catch (e, stackTrace) {
        debugPrint('Error in ReviewListScreen didChangeDependencies: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    }
  }

  void filterOfficials(String query) {
    setState(() {
      searchQuery = query;
      filteredOfficials = List.from(selectedOfficialsList);
      if (query.isNotEmpty) {
        filteredOfficials = filteredOfficials
            .where((official) =>
                official['name'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _confirmList() async {
    final selectedOfficialsData = selectedOfficialsList
        .where(
            (official) => selectedOfficials[official['id'] as String] ?? false)
        .toList();

    if (selectedOfficialsData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one official')),
      );
      return;
    }

    try {
      // Save the list to Firestore
      final listId = await _listService.saveOfficialList(
        listName: listName!,
        sport: sport!,
        officials: selectedOfficialsData,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List saved successfully!')),
      );

      // Navigate back to Lists of Officials screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/lists-of-officials',
        (route) => route.settings.name == '/',
        arguments: {
          'newListCreated': {
            'listName': listName,
            'sport': sport,
            'officials': selectedOfficialsData,
            'id': listId,
          },
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving list: $e')),
      );
    }
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
              color:
                  themeProvider.isDarkMode ? colorScheme.primary : Colors.black,
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
                        'Review List',
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
                        'Review your selected officials',
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

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search officials...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon:
                        Icon(Icons.search, color: colorScheme.onSurfaceVariant),
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
                  onChanged: (value) => filterOfficials(value),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Officials list
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: filteredOfficials.isEmpty
                    ? Center(
                        child: Text(
                          'No officials selected.',
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
                          // Select All checkbox
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 400),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: filteredOfficials.isNotEmpty &&
                                          filteredOfficials.every((official) =>
                                              selectedOfficials[
                                                  official['id'] as String] ??
                                              false),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            for (final official
                                                in filteredOfficials) {
                                              selectedOfficials[official['id']
                                                  as String] = true;
                                            }
                                          } else {
                                            for (final official
                                                in filteredOfficials) {
                                              selectedOfficials.remove(
                                                  official['id'] as String);
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
                            ),
                          ),

                          // Officials list
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredOfficials.length,
                              itemBuilder: (context, index) {
                                final official = filteredOfficials[index];
                                final officialId = official['id'] as String;
                                final isSelected =
                                    selectedOfficials[officialId] ?? false;

                                return Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 500),
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 8.0),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.outline
                                                  .withOpacity(0.3),
                                          width: isSelected ? 2.0 : 1.0,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme.outline
                                                      .withOpacity(0.3),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Experience: ${official['yearsExperience'] ?? 0} years',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              'IHSA Level: ${official['ihsaLevel'] ?? 'registered'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              'Distance: ${official['distance']?.toStringAsFixed(1) ?? 'N/A'} miles',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          setState(() {
                                            final currentValue =
                                                selectedOfficials[officialId] ??
                                                    false;
                                            selectedOfficials[officialId] =
                                                !currentValue;
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
                      ),
              ),
            ),

            // Bottom section
            const SizedBox(height: 12),
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
                          onPressed: selectedCount > 0 ? _confirmList : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor: colorScheme.surfaceVariant,
                            disabledForegroundColor:
                                colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save List',
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
