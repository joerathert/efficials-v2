import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class MultipleListsSetupScreen extends StatefulWidget {
  const MultipleListsSetupScreen({super.key});

  @override
  State<MultipleListsSetupScreen> createState() =>
      _MultipleListsSetupScreenState();
}

class _MultipleListsSetupScreenState extends State<MultipleListsSetupScreen> {
  List<Map<String, dynamic>> availableLists = [
    {'id': '1', 'name': 'Veteran Officials', 'member_count': 5},
    {'id': '2', 'name': 'Experienced Officials', 'member_count': 8},
    {'id': '3', 'name': 'New Officials', 'member_count': 12},
    {'id': '4', 'name': 'Rookie Officials', 'member_count': 15},
  ]; // Initialize with mock data
  List<Map<String, dynamic>> selectedMultipleLists = [
    {'list': null, 'min': 0, 'max': 1},
    {'list': null, 'min': 0, 'max': 1},
  ];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoadedData = true; // Mark as loaded since we have mock data

  int? gameId;
  String? sportName;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 MULTIPLE_LISTS: initState called');
    // Initialize data here to ensure it persists through hot reload
    availableLists = [
      {'id': '1', 'name': 'Veteran Officials', 'member_count': 5},
      {'id': '2', 'name': 'Experienced Officials', 'member_count': 8},
      {'id': '3', 'name': 'New Officials', 'member_count': 12},
      {'id': '4', 'name': 'Rookie Officials', 'member_count': 15},
    ];
    selectedMultipleLists = [
      {'list': null, 'min': 0, 'max': 1},
      {'list': null, 'min': 0, 'max': 1},
    ];
    _hasLoadedData = true;
    debugPrint(
        '🎯 MULTIPLE_LISTS: initState completed, availableLists.length: ${availableLists.length}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && !_hasLoadedData) {
      debugPrint(
          '🎯 MULTIPLE_LISTS: didChangeDependencies called, loading data');
      gameId = args['id'] as int?;
      sportName = args['sport'] as String?;
      _loadData();
    } else {
      debugPrint(
          '🎯 MULTIPLE_LISTS: didChangeDependencies called, data already loaded or no args');
    }
  }

  Future<void> _loadData() async {
    debugPrint('🎯 MULTIPLE_LISTS: _loadData called, gameId: $gameId');
    if (gameId == null) {
      debugPrint('🎯 MULTIPLE_LISTS: _loadData returning early - no gameId');
      return;
    }

    try {
      debugPrint('🎯 MULTIPLE_LISTS: Setting loading to true');
      setState(() => _isLoading = true);

      // For now, we'll mock the available lists - in a real implementation,
      // this would query Firestore for official lists for the specific sport
      // and check existing quotas for this game

      // Mock available lists for the sport
      availableLists = [
        {'id': '1', 'name': 'Veteran Officials', 'member_count': 5},
        {'id': '2', 'name': 'Experienced Officials', 'member_count': 8},
        {'id': '3', 'name': 'New Officials', 'member_count': 12},
        {'id': '4', 'name': 'Rookie Officials', 'member_count': 15},
      ];

      // Mock existing quotas - in a real implementation, this would load from Firestore
      selectedMultipleLists = [
        {'list': null, 'min': 0, 'max': 1},
        {'list': null, 'min': 0, 'max': 1},
      ];

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
    if (gameId == null) return;

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

      // In a real implementation, this would save to Firestore
      // For now, we'll just simulate saving
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Multiple Lists quotas saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to the game creation/review screen
      Navigator.pop(context, {
        'method': 'multiple_lists',
        'selectedLists': selectedMultipleLists,
      });
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

    int totalMax = 0;
    int configuredListsCount = 0;

    for (final listConfig in selectedMultipleLists) {
      final listName = listConfig['list'] as String?;
      final min = listConfig['min'] as int;
      final max = listConfig['max'] as int;

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

    // Initialize data if it's empty (handles hot reload)
    if (availableLists.isEmpty) {
      debugPrint('🎯 MULTIPLE_LISTS: Initializing data in build method');
      availableLists = [
        {'id': '1', 'name': 'Veteran Officials', 'member_count': 5},
        {'id': '2', 'name': 'Experienced Officials', 'member_count': 8},
        {'id': '3', 'name': 'New Officials', 'member_count': 12},
        {'id': '4', 'name': 'Rookie Officials', 'member_count': 15},
      ];
      selectedMultipleLists = [
        {'list': null, 'min': 0, 'max': 1},
        {'list': null, 'min': 0, 'max': 1},
      ];
      _hasLoadedData = true;
      debugPrint(
          '🎯 MULTIPLE_LISTS: Data initialized, availableLists.length: ${availableLists.length}');
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                'Total Officials Required: ${_calculateTotalOfficials()}',
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
                          .add({'list': null, 'min': 0, 'max': 1});
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
                  decoration: _textFieldDecoration('Min'),
                  value: listConfig['min'] is int
                      ? listConfig['min']
                      : int.tryParse(listConfig['min'].toString()),
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
                  decoration: _textFieldDecoration('Max'),
                  value: listConfig['max'] is int
                      ? listConfig['max']
                      : int.tryParse(listConfig['max'].toString()),
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
