import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_service.dart';
import '../services/location_service.dart';
import '../services/official_list_service.dart';
import '../services/auth_service.dart';
import '../models/game_template_model.dart';

class CreateGameTemplateScreen extends StatefulWidget {
  const CreateGameTemplateScreen({super.key});

  @override
  State<CreateGameTemplateScreen> createState() =>
      _CreateGameTemplateScreenState();
}

class _CreateGameTemplateScreenState extends State<CreateGameTemplateScreen> {
  final _nameController = TextEditingController();
  final _gameFeeController = TextEditingController();
  String? sport;
  TimeOfDay? selectedTime;
  String? selectedLocation; // Store the selected location
  String? levelOfCompetition;
  String? gender;
  int? officialsRequired;
  bool hireAutomatically = false;
  String? method;
  String? selectedOfficialList; // Store the selected officials list name

  // Edit mode variables
  bool _isEditMode = false;
  GameTemplateModel? _editingTemplate;

  // Include checkboxes for template fields (all start checked)
  bool includeSport = true;
  bool includeTime = true;
  bool includeLocation = true;
  bool includeLevelOfCompetition = true;
  bool includeGender = true;
  bool includeOfficialsRequired = true;
  bool includeGameFee = true;
  bool includeHireAutomatically = true;
  bool includeSelectedLists = true;

  // Advanced method configuration
  List<Map<String, dynamic>> selectedMultipleLists = [
    {'list': null, 'min': null, 'max': null},
    {'list': null, 'min': null, 'max': null},
  ];

  // Dropdown data
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> officialLists = [];
  bool isLoadingDropdowns = true;
  bool _hasLoadedDropdownData = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize from arguments if available (only once)
    if (!_isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _initializeFromArgs(args);
      }
      _isInitialized = true;
    }

    // Only load dropdown data once
    if (!_hasLoadedDropdownData) {
      _hasLoadedDropdownData = true;
      _loadDropdownData();
    }
  }

  void _initializeFromArgs(Map<String, dynamic> args) {
    print('🎯 CreateGameTemplate: Initializing from args: $args');
    print('🎯 CreateGameTemplate: Args keys: ${args.keys.toList()}');
    print(
        '🎯 CreateGameTemplate: Args types: ${args.map((k, v) => MapEntry(k, v.runtimeType))}');

    // Check if we're in edit mode
    _isEditMode = args['isEdit'] as bool? ?? false;
    if (_isEditMode) {
      _editingTemplate = args['template'] as GameTemplateModel?;
      print(
          '✏️ CreateGameTemplate: Edit mode enabled for template: ${_editingTemplate?.name}');
    }

    // Pre-populate template name for editing
    if (_isEditMode && _editingTemplate != null) {
      _nameController.text = _editingTemplate!.name;
    }

    // Pre-populate sport
    if (_isEditMode && _editingTemplate != null) {
      // Use template data for editing
      sport = _editingTemplate!.sport;
      includeSport = _editingTemplate!.includeSport;
    } else if (args['sport'] != null) {
      final passedSport = args['sport'] as String;
      // Only set the sport if it's a valid sport from our available list
      if (availableSports.contains(passedSport)) {
        sport = passedSport;
        includeSport = true;
      }
      // If the sport is not valid (like "Unknown"), don't pre-select anything
    }

    // Pre-populate time (convert from string back to TimeOfDay)
    if (_isEditMode && _editingTemplate != null) {
      // Use template data for editing
      selectedTime = _editingTemplate!.time;
      includeTime = _editingTemplate!.includeTime;
    } else if (args['time'] != null) {
      if (args['time'] is String) {
        final timeParts = (args['time'] as String).split(':');
        if (timeParts.length >= 2) {
          selectedTime = TimeOfDay(
            hour: int.tryParse(timeParts[0]) ?? 0,
            minute: int.tryParse(timeParts[1]) ?? 0,
          );
          includeTime = true;
        }
      } else if (args['time'] is TimeOfDay) {
        selectedTime = args['time'] as TimeOfDay;
        includeTime = true;
      }
    }

    // Pre-populate location
    if (_isEditMode && _editingTemplate != null) {
      selectedLocation = _editingTemplate!.location;
      includeLocation = _editingTemplate!.includeLocation;
    } else if (args['location'] != null) {
      selectedLocation = args['location'] as String;
      includeLocation = true;
    }

    // Pre-populate level of competition
    if (_isEditMode && _editingTemplate != null) {
      levelOfCompetition = _editingTemplate!.levelOfCompetition;
      includeLevelOfCompetition = _editingTemplate!.includeLevelOfCompetition;
    } else if (args['levelOfCompetition'] != null) {
      levelOfCompetition = args['levelOfCompetition'] as String;
      includeLevelOfCompetition = true;
    }

    // Pre-populate gender
    if (_isEditMode && _editingTemplate != null) {
      gender = _editingTemplate!.gender;
      includeGender = _editingTemplate!.includeGender;
    } else if (args['gender'] != null) {
      gender = args['gender'] as String;
      includeGender = true;
    }

    // Pre-populate officials required
    if (_isEditMode && _editingTemplate != null) {
      officialsRequired = _editingTemplate!.officialsRequired;
      includeOfficialsRequired = _editingTemplate!.includeOfficialsRequired;
    } else if (args['officialsRequired'] != null) {
      officialsRequired = args['officialsRequired'] is int
          ? args['officialsRequired'] as int
          : int.tryParse(args['officialsRequired'].toString());
      includeOfficialsRequired = true;
    }

    // Pre-populate game fee
    if (_isEditMode && _editingTemplate != null) {
      if (_editingTemplate!.gameFee != null) {
        _gameFeeController.text = _editingTemplate!.gameFee!;
      }
      includeGameFee = _editingTemplate!.includeGameFee;
    } else if (args['gameFee'] != null) {
      _gameFeeController.text = args['gameFee'].toString();
      includeGameFee = true;
    }

    // Pre-populate hire automatically
    if (_isEditMode && _editingTemplate != null) {
      hireAutomatically = _editingTemplate!.hireAutomatically ?? false;
      includeHireAutomatically = _editingTemplate!.includeHireAutomatically;
    } else if (args['hireAutomatically'] != null) {
      hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      includeHireAutomatically = true;
    }

    // Pre-populate method and related data
    if (_isEditMode && _editingTemplate != null) {
      // Use template data for editing
      method = _editingTemplate!.method;

      // Handle different methods
      if (method == 'use_list') {
        selectedOfficialList = _editingTemplate!.officialsListName;
      } else if (method == 'advanced') {
        includeSelectedLists = _editingTemplate!.selectedLists != null &&
            _editingTemplate!.selectedLists!.isNotEmpty;
        debugPrint(
            '🎯 Edit mode: method=advanced, includeSelectedLists=$includeSelectedLists');
        debugPrint(
            '🎯 Edit mode: selectedLists=${_editingTemplate!.selectedLists}');
        if (_editingTemplate!.selectedLists != null &&
            _editingTemplate!.selectedLists!.isNotEmpty) {
          // Pre-populate the multiple lists configuration
          selectedMultipleLists = _editingTemplate!.selectedLists!.map((list) {
            final listMap = list as Map<String, dynamic>;
            debugPrint('🎯 Edit mode: processing list: $listMap');
            return {
              'list': listMap['list'] as String?,
              'min': listMap['min'] as int?,
              'max': listMap['max'] as int?,
            };
          }).toList();
          debugPrint(
              '🎯 Edit mode: final selectedMultipleLists=$selectedMultipleLists');
        } else {
          // Reset to default empty state
          selectedMultipleLists = [
            {'list': null, 'min': null, 'max': null},
            {'list': null, 'min': null, 'max': null},
          ];
        }
      }
    } else if (args['method'] != null) {
      String gameMethod = args['method'] as String;

      // Map game methods to template methods
      if (gameMethod == 'multiple_lists') {
        method =
            'advanced'; // Multiple lists maps to advanced method in templates
      } else {
        method = gameMethod;
      }

      // Handle different methods
      if (method == 'use_list' && args['selectedListName'] != null) {
        selectedOfficialList = args['selectedListName'] as String;
      } else if (method == 'advanced' && args['selectedLists'] != null) {
        // Pre-populate the multiple lists configuration
        final gameLists = args['selectedLists'] as List<dynamic>;
        selectedMultipleLists = gameLists.map((list) {
          final listData = list as Map<String, dynamic>;
          return {
            'list': listData['list'] as String?,
            'min': listData['min'] as int?,
            'max': listData['max'] as int?,
          };
        }).toList();
      }
    }

    print('✅ CreateGameTemplate: Initialized fields from args');
    print('✅ CreateGameTemplate: Edit mode: $_isEditMode');
    print('✅ CreateGameTemplate: Method: $method');
    print('✅ CreateGameTemplate: Selected lists: $selectedMultipleLists');

    // Force UI update to reflect pre-populated values
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      // Store current selections to restore after loading
      final currentLocation = selectedLocation;
      final currentOfficialList = selectedOfficialList;
      final currentMultipleLists =
          List<Map<String, dynamic>>.from(selectedMultipleLists);

      // Clear selections when starting to load to prevent assertion failures
      setState(() {
        isLoadingDropdowns = true;
        selectedLocation = null;
        selectedOfficialList = null;
        selectedMultipleLists = [
          {'list': null, 'min': null, 'max': null},
          {'list': null, 'min': null, 'max': null},
        ];
      });

      // Debug: Check authentication
      final authService = AuthService();
      final currentUser = authService.currentUser;
      print(
          '👤 CreateGameTemplate: Current user: ${currentUser?.uid ?? 'null'}');
      print(
          '📧 CreateGameTemplate: User email: ${currentUser?.email ?? 'null'}');

      // Load locations
      locations = await LocationService().getLocations();
      print('📍 CreateGameTemplate: Loaded ${locations.length} locations');
      if (locations.isNotEmpty) {
        print('📍 CreateGameTemplate: First location: ${locations.first}');
      }

      // Load official lists
      officialLists = await OfficialListService().fetchOfficialLists();

      // Restore selections after loading
      setState(() {
        isLoadingDropdowns = false;
        // Restore selections if they were set before loading
        if (currentLocation != null) {
          // Check if the saved location still exists in the loaded locations
          final locationExists =
              locations.any((loc) => loc['name'] == currentLocation);
          if (locationExists) {
            selectedLocation = currentLocation;
          }
        }
        if (currentOfficialList != null) {
          selectedOfficialList = currentOfficialList;
        }
        // Restore multiple lists configuration
        if (currentMultipleLists.isNotEmpty &&
            currentMultipleLists.any((list) => list['list'] != null)) {
          selectedMultipleLists =
              List<Map<String, dynamic>>.from(currentMultipleLists);
        }
      });
    } catch (e) {
      print('❌ CreateGameTemplate: Error loading dropdown data: $e');
      // Clear selections on error to prevent assertion failures
      setState(() {
        isLoadingDropdowns = false;
        selectedLocation = null;
        selectedOfficialList = null;
        selectedMultipleLists = [
          {'list': null, 'min': null, 'max': null},
          {'list': null, 'min': null, 'max': null},
        ];
      });
    }
  }

  final List<String> availableSports = [
    'Football',
    'Basketball',
    'Baseball',
    'Soccer',
    'Volleyball'
  ];
  final List<String> competitionLevels = [
    '6U',
    '7U',
    '8U',
    '9U',
    '10U',
    '11U',
    '12U',
    '13U',
    '14U',
    '15U',
    '16U',
    '17U',
    '18U',
    'Grade School',
    'Middle School',
    'Underclass',
    'JV',
    'Varsity',
    'College',
    'Adult'
  ];
  final List<String> genders = ['Boys', 'Girls', 'Co-ed'];
  final List<int> officialsOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name!')),
      );
      return;
    }

    // Check if a template with this name already exists
    try {
      final existingTemplates = await GameService().getTemplates();
      final templateName = _nameController.text.trim();
      final duplicateTemplate = existingTemplates.where(
        (template) => template.name.toLowerCase() == templateName.toLowerCase(),
      ).toList();

      // If we're creating a new template and found duplicates
      if (!_isEditMode && duplicateTemplate.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A template with this name already exists!')),
        );
        return;
      }

      // If we're editing, make sure we're not conflicting with another template
      if (_isEditMode && duplicateTemplate.isNotEmpty &&
          _editingTemplate != null && duplicateTemplate.any((t) => t.id != _editingTemplate!.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A template with this name already exists!')),
        );
        return;
      }
    } catch (e) {
      debugPrint('Error checking for duplicate template names: $e');
      // Continue with template creation/update even if this check fails
    }

    if (includeGameFee &&
        _gameFeeController.text.isNotEmpty &&
        !RegExp(r'^\d+(\.\d+)?$').hasMatch(_gameFeeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid game fee')),
      );
      return;
    }

    // Validate required fields based on checkboxes
    if (includeSport && sport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sport')),
      );
      return;
    }

    if (includeTime && selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    if (includeLocation && selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    if (includeLevelOfCompetition && levelOfCompetition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a level of competition')),
      );
      return;
    }

    if (includeGender && gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
      return;
    }

    if (includeOfficialsRequired && officialsRequired == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select number of officials required')),
      );
      return;
    }

    if (method == 'use_list' && selectedOfficialList == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an officials list')),
      );
      return;
    }

    // Debug: Log current state before saving
    debugPrint(
        '🎯 SAVE TEMPLATE: Method: $method, includeSelectedLists: $includeSelectedLists');
    debugPrint(
        '🎯 SAVE TEMPLATE: selectedMultipleLists: $selectedMultipleLists');
    debugPrint('🎯 SAVE TEMPLATE: selectedLocation: $selectedLocation');
    debugPrint('🎯 SAVE TEMPLATE: includeLocation: $includeLocation');

    // Prepare template data
    final templateData = <String, dynamic>{
      'name': _nameController.text,
      'includeSport': includeSport,
      'includeTime': includeTime,
      'includeLocation': includeLocation,
      'includeLevelOfCompetition': includeLevelOfCompetition,
      'includeGender': includeGender,
      'includeOfficialsRequired': includeOfficialsRequired,
      'includeGameFee': includeGameFee,
      'includeHireAutomatically': includeHireAutomatically,
      'method': method,
      'includeOfficialsList': method == 'use_list',
      'includeSelectedOfficials': method == 'standard',
      'includeSelectedLists': method == 'advanced',
      'includeSelectedCrews': method == 'hire_crew',
    };

    // In edit mode, preserve the original createdAt timestamp
    if (_isEditMode && _editingTemplate != null) {
      templateData['createdAt'] = _editingTemplate!.createdAt.toIso8601String();
    }

    // Add optional fields
    if (includeSport && sport != null) templateData['sport'] = sport;
    if (includeTime && selectedTime != null) {
      templateData['time'] = {
        'hour': selectedTime!.hour,
        'minute': selectedTime!.minute
      };
    }
    if (includeLocation && selectedLocation != null)
      templateData['location'] = selectedLocation;
    if (includeLevelOfCompetition && levelOfCompetition != null)
      templateData['levelOfCompetition'] = levelOfCompetition;
    if (includeGender && gender != null) templateData['gender'] = gender;
    if (includeOfficialsRequired && officialsRequired != null)
      templateData['officialsRequired'] = officialsRequired;
    if (includeGameFee && _gameFeeController.text.isNotEmpty)
      templateData['gameFee'] = _gameFeeController.text;
    if (includeHireAutomatically && hireAutomatically != null)
      templateData['hireAutomatically'] = hireAutomatically;
    if (method == 'use_list' && selectedOfficialList != null)
      templateData['officialsListName'] = selectedOfficialList;

    // Handle selectedLists with proper error handling
    if (method == 'advanced' && includeSelectedLists) {
      try {
        final filteredLists = selectedMultipleLists
            .where((list) =>
                list['list'] != null &&
                list['list'] is String &&
                (list['list'] as String).isNotEmpty)
            .map((list) => {
                  'list': list['list'] as String,
                  'min': (list['min'] is int) ? list['min'] as int : 0,
                  'max': (list['max'] is int) ? list['max'] as int : 1,
                })
            .toList();
        debugPrint('🎯 SAVE TEMPLATE: Processed selectedLists: $filteredLists');
        templateData['selectedLists'] = filteredLists;
      } catch (e) {
        debugPrint('🔴 SAVE TEMPLATE: Error processing selectedLists: $e');
        // Don't include selectedLists if there's an error
      }
    }

    try {
      // If edit mode is set but no template exists, treat as create
      final isActuallyEditMode = _isEditMode && _editingTemplate != null;
      final action = isActuallyEditMode ? 'update' : 'create';
      debugPrint(
          '🎯 ${action.toUpperCase()} TEMPLATE: About to $action template: ${templateData['name']}');
      debugPrint(
          '🎯 ${action.toUpperCase()} TEMPLATE: Selected location: $selectedLocation');
      debugPrint(
          '🎯 ${action.toUpperCase()} TEMPLATE: Include location: $includeLocation');
      debugPrint('🎯 ${action.toUpperCase()} TEMPLATE: Method: $method');
      debugPrint(
          '🎯 ${action.toUpperCase()} TEMPLATE: Selected officials list: $selectedOfficialList');
      debugPrint(
          '🎯 ${action.toUpperCase()} TEMPLATE: Template data: $templateData');
      debugPrint('🎯 ${action.toUpperCase()} TEMPLATE: _isEditMode: $_isEditMode, _editingTemplate: ${_editingTemplate?.name ?? "null"}');

      // For updates, include the template ID in the data
      final dataToSave = isActuallyEditMode
          ? {...templateData, 'id': _editingTemplate!.id}
          : templateData;

      debugPrint(
          '🎯 ${action.toUpperCase()} TEMPLATE: Data to save: $dataToSave');

      final result = isActuallyEditMode
          ? await GameService().updateTemplate(dataToSave)
          : await GameService().createTemplate(dataToSave);

      if (result != null) {
        final resultMap = result as Map<String, dynamic>;
        debugPrint(
            '✅ ${action.toUpperCase()} TEMPLATE: Template ${action}d successfully with ID: ${resultMap['id']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Template ${(_isEditMode && _editingTemplate != null) ? 'updated' : 'saved'} successfully!')),
        );
        Navigator.pop(context, result); // Return the result
      } else {
        debugPrint(
            '❌ ${action.toUpperCase()} TEMPLATE: Failed to $action template - result was null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to ${(_isEditMode && _editingTemplate != null) ? 'update' : 'save'} template. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint(
          '🔴 ${(_isEditMode && _editingTemplate != null ? 'UPDATE' : 'CREATE')} TEMPLATE: Error ${(_isEditMode && _editingTemplate != null) ? 'updating' : 'saving'} template: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error ${(_isEditMode && _editingTemplate != null) ? 'updating' : 'saving'} template: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: IconButton(
          icon: Icon(Icons.sports, color: colorScheme.primary, size: 32),
          onPressed: () async {
            // Navigate to appropriate home screen based on user role
            final authService = AuthService();
            final homeRoute = await authService.getHomeRoute();
            Navigator.of(context).pushNamedAndRemoveUntil(
              homeRoute,
              (route) => false, // Remove all routes
            );
          },
          tooltip: 'Home',
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                        (_isEditMode && _editingTemplate != null)
                            ? 'Edit Template'
                            : 'Create Template',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                        _isEditMode
                            ? 'Modify your template settings'
                            : 'Create a game template with your preferred settings',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                  const SizedBox(height: 16),

                  // Template Name (always included)
                  Row(
                    children: [
                      Checkbox(
                        value:
                            true, // Always checked since template name is required
                        onChanged: null, // Disabled since it's always required
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Template Name',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sport - Dropdown
                  Row(
                    children: [
                      Checkbox(
                        value: includeSport,
                        onChanged: (value) {
                          final newValue = value ?? false;
                          setState(() {
                            includeSport = newValue;
                            if (!newValue) {
                              sport = null; // Clear sport when unchecked
                            }
                          });
                        },
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Sport',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: includeSport ? sport : null,
                          hint: const Text('Select Sport',
                              style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: Colors.grey[900],
                          onChanged: includeSport
                              ? (newValue) => setState(() => sport = newValue)
                              : null,
                          items: includeSport
                              ? availableSports.map((sportName) {
                                  return DropdownMenuItem(
                                    value: sportName,
                                    child: Text(sportName,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  );
                                }).toList()
                              : [],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time - Picker
                  Row(
                    children: [
                      Checkbox(
                        value: includeTime,
                        onChanged: (value) =>
                            setState(() => includeTime = value ?? false),
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedTime == null
                                      ? 'Select Time'
                                      : '${selectedTime!.format(context)}',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                Icon(Icons.access_time,
                                    color: colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location - Dropdown
                  Row(
                    children: [
                      Checkbox(
                        value: includeLocation,
                        onChanged: (value) =>
                            setState(() => includeLocation = value ?? false),
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: selectedLocation,
                          hint: isLoadingDropdowns
                              ? const Text('Loading...',
                                  style: TextStyle(color: Colors.grey))
                              : const Text('Select Location',
                                  style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: Colors.grey[800],
                          onChanged: isLoadingDropdowns
                              ? null
                              : (newValue) =>
                                  setState(() => selectedLocation = newValue),
                          items: isLoadingDropdowns
                              ? [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Loading...',
                                        style: TextStyle(color: Colors.grey)),
                                  )
                                ]
                              : locations.isEmpty
                                  ? [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('No locations found',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      )
                                    ]
                                  : locations.map((location) {
                                      final locationName =
                                          location['name'] as String? ??
                                              'Unnamed Location';
                                      print(
                                          '🏠 Location dropdown item: $locationName');
                                      return DropdownMenuItem<String>(
                                        value: locationName,
                                        child: Text(locationName,
                                            style: const TextStyle(
                                                color: Colors.white)),
                                      );
                                    }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Level of Competition - Dropdown
                  Row(
                    children: [
                      Checkbox(
                        value: includeLevelOfCompetition,
                        onChanged: (value) => setState(
                            () => includeLevelOfCompetition = value ?? false),
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Level of Competition',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: levelOfCompetition,
                          hint: const Text('Level of Competition',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          dropdownColor: Colors.grey[900],
                          onChanged: (value) =>
                              setState(() => levelOfCompetition = value),
                          items: competitionLevels.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(level,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gender - Dropdown
                  Row(
                    children: [
                      Checkbox(
                        value: includeGender,
                        onChanged: (value) =>
                            setState(() => includeGender = value ?? false),
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: gender,
                          hint: const Text('Gender',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          dropdownColor: Colors.grey[900],
                          onChanged: (value) => setState(() => gender = value),
                          items: genders.map((g) {
                            return DropdownMenuItem(
                              value: g,
                              child: Text(g,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // # of Officials Required - Dropdown
                  Row(
                    children: [
                      Checkbox(
                        value: includeOfficialsRequired,
                        onChanged: (value) => setState(
                            () => includeOfficialsRequired = value ?? false),
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: '# of Officials Required',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: officialsRequired,
                          hint: const Text('# of Officials Required',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                          dropdownColor: Colors.grey[900],
                          onChanged: (value) =>
                              setState(() => officialsRequired = value),
                          items: officialsOptions.map((num) {
                            return DropdownMenuItem(
                              value: num,
                              child: Text(num.toString(),
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Game Fee per Official - Text field with number input
                  Row(
                    children: [
                      Checkbox(
                        value: includeGameFee,
                        onChanged: (value) =>
                            setState(() => includeGameFee = value ?? false),
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _gameFeeController,
                          decoration: InputDecoration(
                            labelText: 'Game Fee per Official',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                            prefixText: '\$',
                            prefixStyle: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            hintText: 'Enter fee (e.g., 50 or 50.00)',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                            LengthLimitingTextInputFormatter(7),
                          ],
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hire Automatically - Toggle slider
                  Row(
                    children: [
                      Checkbox(
                        value: includeHireAutomatically,
                        onChanged: (value) => setState(
                            () => includeHireAutomatically = value ?? false),
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      const Text('Hire Automatically',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(width: 16),
                      Switch(
                        value: hireAutomatically,
                        onChanged: (value) =>
                            setState(() => hireAutomatically = value),
                        activeColor: colorScheme.primary,
                        activeTrackColor: colorScheme.primary.withOpacity(0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selection Method - Dropdown
                  Row(
                    children: [
                      Checkbox(
                        value:
                            true, // Selection method is always included when set
                        onChanged: null, // Disabled since it's always included
                        activeColor: colorScheme.primary,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Selection Method',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: method,
                          hint: const Text('Select officials method',
                              style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: Colors.grey[900],
                          onChanged: (value) => setState(() => method = value),
                          items: const [
                            DropdownMenuItem(
                              value: 'advanced',
                              child: Text('Multiple Lists',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'use_list',
                              child: Text('Single List',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'hire_crew',
                              child: Text('Hire a Crew',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Method-specific configuration
                  if (method == 'use_list') ...[
                    Row(
                      children: [
                        const SizedBox(
                            width:
                                36), // Slightly wider to the left for better alignment
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Official List',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[900],
                            ),
                            value: selectedOfficialList,
                            hint: isLoadingDropdowns
                                ? const Text('Loading...',
                                    style: TextStyle(color: Colors.grey))
                                : const Text('Choose a saved list',
                                    style: TextStyle(color: Colors.grey)),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            dropdownColor: Colors.grey[900],
                            onChanged: isLoadingDropdowns
                                ? null
                                : (newValue) => setState(
                                    () => selectedOfficialList = newValue),
                            items: isLoadingDropdowns
                                ? [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Loading...',
                                          style: TextStyle(color: Colors.grey)),
                                    )
                                  ]
                                : officialLists.isEmpty
                                    ? [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text(
                                              'No official lists found - Create one first!',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        )
                                      ]
                                    : officialLists.map((list) {
                                        final listName =
                                            list['name'] as String? ??
                                                'Unnamed List';
                                        return DropdownMenuItem<String>(
                                          value: listName,
                                          child: Text(listName,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                        );
                                      }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ] else if (method == 'advanced') ...[
                    // Advanced method configuration
                    Row(
                      children: [
                        Checkbox(
                          value: includeSelectedLists,
                          onChanged: (value) => setState(
                              () => includeSelectedLists = value ?? false),
                          activeColor: colorScheme.primary,
                          checkColor: Colors.black,
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              border: Border.all(
                                  color: colorScheme.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Multiple Lists Configuration',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                ...selectedMultipleLists
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final listIndex = entry.key;
                                  final listConfig = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'List ${listIndex + 1}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70),
                                            ),
                                            if (selectedMultipleLists.length >
                                                2)
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    selectedMultipleLists
                                                        .removeAt(listIndex);
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.remove_circle,
                                                    color: Colors.red,
                                                    size: 16),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            hintText: 'Select list',
                                            hintStyle: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                            filled: true,
                                            fillColor: Colors.grey[900],
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 1),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 1),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 1.5),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                          ),
                                          value: listConfig['list'] as String?,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                          dropdownColor: Colors.grey[900],
                                          onChanged: isLoadingDropdowns
                                              ? null
                                              : (value) {
                                                  setState(() {
                                                    listConfig['list'] = value;
                                                  });
                                                },
                                          items: isLoadingDropdowns
                                              ? [
                                                  const DropdownMenuItem<
                                                      String>(
                                                    value: null,
                                                    child: Text('Loading...',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.grey)),
                                                  )
                                                ]
                                              : officialLists.isEmpty
                                                  ? [
                                                      const DropdownMenuItem<
                                                          String>(
                                                        value: null,
                                                        child: Text(
                                                            'No lists available',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey)),
                                                      )
                                                    ]
                                                  : officialLists.map((list) {
                                                      final listName =
                                                          list['name']
                                                                  as String? ??
                                                              'Unnamed List';
                                                      return DropdownMenuItem<
                                                          String>(
                                                        value: listName,
                                                        child: Text(listName,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                      );
                                                    }).toList(),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  DropdownButtonFormField<int>(
                                                decoration: InputDecoration(
                                                  hintText: 'Min officials',
                                                  hintStyle: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                  filled: true,
                                                  fillColor: Colors.grey[900],
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide: BorderSide(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 1),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide: BorderSide(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 1),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide: BorderSide(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 1.5),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                ),
                                                value:
                                                    listConfig['min'] as int?,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                                dropdownColor: Colors.grey[900],
                                                onChanged: (value) {
                                                  setState(() {
                                                    listConfig['min'] = value;
                                                  });
                                                },
                                                items:
                                                    List.generate(10, (i) => i)
                                                        .map((num) {
                                                  return DropdownMenuItem(
                                                    value: num,
                                                    child: Text(num.toString(),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child:
                                                  DropdownButtonFormField<int>(
                                                decoration: InputDecoration(
                                                  hintText: 'Max officials',
                                                  hintStyle: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                  filled: true,
                                                  fillColor: Colors.grey[900],
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide: BorderSide(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 1),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide: BorderSide(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 1),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide: BorderSide(
                                                        color:
                                                            colorScheme.primary,
                                                        width: 1.5),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                ),
                                                value:
                                                    listConfig['max'] as int?,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                                dropdownColor: Colors.grey[900],
                                                onChanged: (value) {
                                                  setState(() {
                                                    listConfig['max'] = value;
                                                  });
                                                },
                                                items: List.generate(
                                                        10, (i) => i + 1)
                                                    .map((num) {
                                                  return DropdownMenuItem(
                                                    value: num,
                                                    child: Text(num.toString(),
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                if (selectedMultipleLists.length < 3)
                                  Center(
                                    child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedMultipleLists.add({
                                            'list': null,
                                            'min': null,
                                            'max': null
                                          });
                                        });
                                      },
                                      icon: Icon(Icons.add_circle,
                                          color: colorScheme.primary),
                                      tooltip: 'Add another list',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (method == 'hire_crew') ...[
                    Row(
                      children: [
                        const SizedBox(
                            width:
                                36), // Slightly wider to the left for better alignment
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              border: Border.all(
                                  color: colorScheme.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Crew hiring configuration coming soon',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.group, color: colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 400,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTemplate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text((_isEditMode && _editingTemplate != null) ? 'Update Template' : 'Save Template',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
