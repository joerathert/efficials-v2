import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/official_list_service.dart';

class MultipleListsSetupScreen extends StatefulWidget {
  const MultipleListsSetupScreen({super.key});

  @override
  State<MultipleListsSetupScreen> createState() =>
      _MultipleListsSetupScreenState();
}

class _MultipleListsSetupScreenState extends State<MultipleListsSetupScreen> {
  List<Map<String, dynamic>> availableLists = [];
  List<Map<String, dynamic>> selectedMultipleLists = [
    {'list': null, 'min': null, 'max': null},
    {'list': null, 'min': null, 'max': null},
  ];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoadedData = false;
  final OfficialListService _listService = OfficialListService();

  int? gameId;
  String? sportName;
  int officialsRequired = 0;
  Map<String, dynamic>? originalArgs;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 MULTIPLE_LISTS: initState called');
    // Data will be loaded in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && !_hasLoadedData) {
      debugPrint(
          '🎯 MULTIPLE_LISTS: didChangeDependencies called, loading data');
      originalArgs = Map<String, dynamic>.from(args);
      // Handle both int and String game IDs (Firestore uses String)
      final idValue = args['id'];
      if (idValue is int) {
        gameId = idValue;
      } else if (idValue is String) {
        gameId = int.tryParse(idValue);
      } else {
        gameId = null;
      }
      sportName = args['sport'] as String?;
      officialsRequired = args['officialsRequired'] as int? ?? 0;
      debugPrint(
          '🎯 MULTIPLE_LISTS: officialsRequired set to: $officialsRequired');
      _loadData();
    } else {
      debugPrint(
          '🎯 MULTIPLE_LISTS: didChangeDependencies called, data already loaded or no args');
    }
  }

  Future<void> _loadData() async {
    debugPrint(
        '🎯 MULTIPLE_LISTS: _loadData called, gameId: $gameId, sportName: $sportName');

    try {
      debugPrint('🎯 MULTIPLE_LISTS: Setting loading to true');
      setState(() => _isLoading = true);

      // Fetch all official lists for the current user
      final allLists = await _listService.fetchOfficialLists();

      // Filter lists by sport if sportName is provided
      if (sportName != null && sportName!.isNotEmpty) {
        availableLists = allLists.where((list) {
          final listSport = list['sport'] as String?;
          return listSport == sportName;
        }).toList();
        debugPrint(
            '🎯 MULTIPLE_LISTS: Filtered ${availableLists.length} lists for sport: $sportName');
      } else {
        availableLists = allLists;
        debugPrint(
            '🎯 MULTIPLE_LISTS: Using all ${availableLists.length} lists (no sport filter)');
      }

      // Check for pre-selected lists from template
      final preSelectedLists = originalArgs?['preSelectedLists'] as List<dynamic>?;
      if (preSelectedLists != null && preSelectedLists.isNotEmpty) {
        selectedMultipleLists = preSelectedLists.map((list) {
          if (list is Map) {
            return Map<String, dynamic>.from(list);
          }
          return {'list': null, 'min': null, 'max': null};
        }).toList();
        debugPrint('🎯 MULTIPLE_LISTS: Pre-populated ${selectedMultipleLists.length} lists from template');
      } else {
        // Initialize selectedMultipleLists if not already set
        if (selectedMultipleLists.isEmpty) {
          selectedMultipleLists = [
            {'list': null, 'min': null, 'max': null},
            {'list': null, 'min': null, 'max': null},
          ];
        }
      }

      debugPrint(
          '🎯 MULTIPLE_LISTS: Setting loading to false, hasLoadedData to true (success)');
      setState(() {
        _isLoading = false;
        _hasLoadedData = true;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      debugPrint(
          '🎯 MULTIPLE_LISTS: Setting loading to false, hasLoadedData to true (error)');
      setState(() {
        _isLoading = false;
        _hasLoadedData = true;
      });
      _showErrorDialog('Error loading data: $e');
    }
  }

  Future<void> _saveQuotas() async {
    // Check if we're in edit mode (no gameId means we're in edit mode)
    final isEditMode = originalArgs?['isEdit'] == true || originalArgs?['isFromGameInfo'] == true;

    if (gameId == null && !isEditMode) return;

    // Validate quotas
    final validationError = _validateQuotas();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      if (isEditMode) {
        // In edit mode, just return the configuration without saving to database
        debugPrint('🎯 MULTIPLE_LISTS: Edit mode - returning configuration without saving to DB');
        final result = Map<String, dynamic>.from(originalArgs ?? {});
        result.addAll({
          'method': 'advanced',
          'selectedLists': selectedMultipleLists,
        });
        Navigator.pop(context, result);
        return;
      }

      // In a real implementation, this would save to Firestore
      // For now, we'll just simulate saving
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Multiple Lists quotas saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to the game creation/review screen with original args plus multiple lists data
      final result = Map<String, dynamic>.from(originalArgs ?? {});
      result.addAll({
        'method': 'multiple_lists',
        'selectedLists': selectedMultipleLists,
      });
      Navigator.pop(context, result);
    } catch (e) {
      _showErrorDialog('Error saving quotas: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String? _validateQuotas() {
    if (availableLists.isEmpty) {
      return 'No official lists available. Please create official lists first.';
    }

    int totalMin = 0;
    int totalMax = 0;
    int configuredListsCount = 0;

    for (final listConfig in selectedMultipleLists) {
      final listName = listConfig['list'] as String?;
      final min = listConfig['min'] as int? ?? 0;
      final max = listConfig['max'] as int? ?? 0;

      if (listName != null && listName.isNotEmpty) {
        configuredListsCount++;

        if (min < 0) {
          return 'Minimum officials cannot be negative for $listName';
        }

        if (max < min) {
          return 'Maximum cannot be less than minimum for $listName';
        }

        // Only count if this quota is actually used (max > 0)
        if (max > 0) {
          totalMin += min;
          totalMax += max;
        }
      }
    }

    if (configuredListsCount == 0) {
      return 'Please select at least one officials list';
    }

    if (totalMax == 0) {
      return 'At least one list must have a maximum greater than 0';
    }

    // Ensure the total maximum is at least the required officials
    if (totalMax < officialsRequired) {
      return 'Total maximum officials ($totalMax) must be at least equal to required officials ($officialsRequired)';
    }

    // Ensure the total minimum doesn't exceed the required officials
    if (totalMin > officialsRequired) {
      return 'Total minimum officials ($totalMin) cannot exceed required officials ($officialsRequired)';
    }

    return null; // No validation errors
  }

  int _calculateTotalOfficials() {
    int total = 0;
    for (final listConfig in selectedMultipleLists) {
      final listName = listConfig['list'] as String?;
      final max = listConfig['max'] as int;

      // Only count if this list is selected and configured
      if (listName != null && listName.isNotEmpty && max > 0) {
        total += max;
      }
    }
    return total;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '🎯 MULTIPLE_LISTS: Build called - isLoading: $_isLoading, hasLoadedData: $_hasLoadedData');

    // Data should be loaded in didChangeDependencies, but handle hot reload case
    if (availableLists.isEmpty && !_hasLoadedData && !_isLoading) {
      debugPrint(
          '🎯 MULTIPLE_LISTS: Triggering data load in build method (hot reload case)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (args != null) {
            originalArgs = Map<String, dynamic>.from(args);
            gameId = args['id'] as int?;
            sportName = args['sport'] as String?;
            officialsRequired = args['officialsRequired'] as int? ?? 0;
            _loadData();
          }
        }
      });
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              onPressed: () {
                // Navigate to Athletic Director home screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/ad-home',
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
        child: () {
          debugPrint(
              '🎯 MULTIPLE_LISTS: Body condition - isLoading: $_isLoading');
          if (_isLoading) {
            debugPrint('🎯 MULTIPLE_LISTS: Showing loading spinner');
            return const Center(child: CircularProgressIndicator());
          } else {
            debugPrint('🎯 MULTIPLE_LISTS: Showing _buildContent');
            return _buildContent();
          }
        }(),
      ),
    );
  }

  Widget _buildContent() {
    debugPrint(
        '🎯 MULTIPLE_LISTS: _buildContent called, availableLists.length: ${availableLists.length}');
    debugPrint('🎯 MULTIPLE_LISTS: availableLists: $availableLists');
    try {
      if (availableLists.isEmpty) {
        debugPrint(
            '🎯 MULTIPLE_LISTS: _buildContent - showing no lists message');
        return _buildNoListsMessage();
      }

      debugPrint('🎯 MULTIPLE_LISTS: _buildContent - showing main content');
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildMultipleListsConfiguration(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 400,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveQuotas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        disabledBackgroundColor: Colors.grey[600],
                        disabledForegroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Multiple Lists Setup',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('🎯 MULTIPLE_LISTS: Exception in _buildContent: $e');
      return Container(
        color: Colors.red,
        child: Center(
          child: Text(
            'CONTENT ERROR: $e',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildNoListsMessage() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Official Lists Found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sportName != null
                      ? 'You need to create official lists for $sportName before using the Multiple Lists method.'
                      : 'You need to create official lists before using the Multiple Lists method.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/lists-of-officials',
                        arguments: {
                          'sport': sportName ?? 'Unknown Sport',
                          'fromGameCreation': false,
                          'fromTemplateCreation': false,
                        });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Create Official Lists'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Multiple Lists Setup',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onBackground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure minimum and maximum officials from each list. This ensures proper experience distribution.',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Total Officials Required: $officialsRequired',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleListsConfiguration() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row with title and + button
          Row(
            children: [
              Text(
                'Configure Multiple Lists',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedMultipleLists.length < 3)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMultipleLists
                          .add({'list': null, 'min': null, 'max': null});
                    });
                  },
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // List items
          ...selectedMultipleLists.asMap().entries.map((entry) {
            final listIndex = entry.key;
            final listConfig = entry.value;
            return _buildMultipleListItem(listIndex, listConfig);
          }),
        ],
      ),
    );
  }

  Widget _buildMultipleListItem(
      int listIndex, Map<String, dynamic> listConfig) {
    final validLists = availableLists
        .where((list) =>
            list['name'] != null &&
            list['name'] != 'No saved lists' &&
            list['name'] != '+ Create new list')
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'List ${listIndex + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (selectedMultipleLists.length > 2)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMultipleLists.removeAt(listIndex);
                    });
                  },
                  icon: const Icon(Icons.remove_circle,
                      color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // List selection dropdown
          DropdownButtonFormField<String>(
            decoration: _textFieldDecoration('Select Officials List'),
            value: listConfig['list'],
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
            dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
            onChanged: (value) {
              setState(() {
                listConfig['list'] = value;
              });
            },
            items: validLists.map((list) {
              return DropdownMenuItem(
                value: list['name'] as String,
                child: Text(
                  list['name'] as String,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Min/Max configuration
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: _textFieldDecoration('Min Officials'),
                  value: listConfig['min'] as int?,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14),
                  dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
                  onChanged: (value) {
                    setState(() {
                      listConfig['min'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(
                        num.toString(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: _textFieldDecoration('Max Officials'),
                  value: listConfig['max'] as int?,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14),
                  dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
                  onChanged: (value) {
                    setState(() {
                      listConfig['max'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i + 1).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(
                        num.toString(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _textFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
