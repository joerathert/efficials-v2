import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_service.dart';
import '../services/location_service.dart';
import '../services/official_list_service.dart';
import '../services/auth_service.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize from arguments if available
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _initializeFromArgs(args);
    }

    _loadDropdownData();
  }

  void _initializeFromArgs(Map<String, dynamic> args) {
    print('🎯 CreateGameTemplate: Initializing from args: $args');
    print('🎯 CreateGameTemplate: Args keys: ${args.keys.toList()}');
    print('🎯 CreateGameTemplate: Args types: ${args.map((k, v) => MapEntry(k, v.runtimeType))}');

    // Leave template name blank - user will fill it in
    // _nameController.text remains empty

    // Pre-populate sport
    if (args['sport'] != null) {
      sport = args['sport'] as String;
      includeSport = true;
    }

    // Pre-populate time (convert from string back to TimeOfDay)
    if (args['time'] != null) {
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
    if (args['location'] != null) {
      selectedLocation = args['location'] as String;
      includeLocation = true;
    }

    // Pre-populate level of competition
    if (args['levelOfCompetition'] != null) {
      levelOfCompetition = args['levelOfCompetition'] as String;
      includeLevelOfCompetition = true;
    }

    // Pre-populate gender
    if (args['gender'] != null) {
      gender = args['gender'] as String;
      includeGender = true;
    }

    // Pre-populate officials required
    if (args['officialsRequired'] != null) {
      officialsRequired = args['officialsRequired'] is int
          ? args['officialsRequired'] as int
          : int.tryParse(args['officialsRequired'].toString());
      includeOfficialsRequired = true;
    }

    // Pre-populate game fee
    if (args['gameFee'] != null) {
      _gameFeeController.text = args['gameFee'].toString();
      includeGameFee = true;
    }

    // Pre-populate hire automatically
    if (args['hireAutomatically'] != null) {
      hireAutomatically = args['hireAutomatically'] as bool? ?? false;
      includeHireAutomatically = true;
    }

    // Pre-populate method and related data
    if (args['method'] != null) {
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

    // Force UI update to reflect pre-populated values
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      setState(() => isLoadingDropdowns = true);

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

      setState(() => isLoadingDropdowns = false);
    } catch (e) {
      print('❌ CreateGameTemplate: Error loading dropdown data: $e');
      setState(() => isLoadingDropdowns = false);
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

    // Prepare template data
    final templateData = {
      'name': _nameController.text,
      'includeSport': includeSport,
      if (includeSport) 'sport': sport,
      'includeTime': includeTime,
      if (includeTime && selectedTime != null)
        'time': {'hour': selectedTime!.hour, 'minute': selectedTime!.minute},
      'includeLocation': includeLocation,
      if (includeLocation && selectedLocation != null)
        'location': selectedLocation,
      'includeLevelOfCompetition': includeLevelOfCompetition,
      if (includeLevelOfCompetition) 'levelOfCompetition': levelOfCompetition,
      'includeGender': includeGender,
      if (includeGender) 'gender': gender,
      'includeOfficialsRequired': includeOfficialsRequired,
      if (includeOfficialsRequired) 'officialsRequired': officialsRequired,
      'includeGameFee': includeGameFee,
      if (includeGameFee && _gameFeeController.text.isNotEmpty)
        'gameFee': _gameFeeController.text,
      'includeHireAutomatically': includeHireAutomatically,
      if (includeHireAutomatically) 'hireAutomatically': hireAutomatically,
      'method': method,
      'includeOfficialsList': method == 'use_list',
      'includeSelectedOfficials': method == 'standard',
      'includeSelectedLists': method == 'advanced',
      'includeSelectedCrews': method == 'hire_crew',
      if (method == 'use_list') 'officialsListName': selectedOfficialList,
      if (method == 'advanced' && includeSelectedLists)
        'selectedLists': selectedMultipleLists
            .where((list) => list['list'] != null)
            .map((list) => {
                  'list': list['list'],
                  'min': list['min'] ?? 0,
                  'max': list['max'] ?? 1,
                })
            .toList(),
    };

    try {
      debugPrint(
          '🎯 CREATE TEMPLATE: About to save template: ${templateData['name']}');
      debugPrint('🎯 CREATE TEMPLATE: Selected location: $selectedLocation');
      debugPrint('🎯 CREATE TEMPLATE: Include location: $includeLocation');
      debugPrint('🎯 CREATE TEMPLATE: Method: $method');
      debugPrint(
          '🎯 CREATE TEMPLATE: Selected officials list: $selectedOfficialList');
      debugPrint('🎯 CREATE TEMPLATE: Template data: $templateData');

      final result = await GameService().createTemplate(templateData);

      if (result != null) {
        debugPrint(
            '✅ CREATE TEMPLATE: Template saved successfully with ID: ${result['id']}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully!')),
        );
        Navigator.pop(context, result); // Return the result
      } else {
        debugPrint(
            '❌ CREATE TEMPLATE: Failed to save template - result was null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save template. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('🔴 CREATE TEMPLATE: Error saving template: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving template: $e')),
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
                    child: Text('Template Configuration',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                        'Create a game template with your preferred settings',
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
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
                        onChanged: (value) =>
                            setState(() => includeSport = value ?? false),
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: sport,
                          hint: const Text('Select Sport',
                              style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: Colors.grey[900],
                          onChanged: (newValue) =>
                              setState(() => sport = newValue),
                          items: availableSports.map((sportName) {
                            return DropdownMenuItem(
                              value: sportName,
                              child: Text(sportName,
                                  style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
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
                              border:
                                  Border.all(color: colorScheme.primary, width: 1.5),
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: selectedLocation,
                          hint: const Text('Select Location',
                              style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: Colors.grey[800],
                          onChanged: (newValue) =>
                              setState(() => selectedLocation = newValue),
                          items: isLoadingDropdowns
                              ? [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Loading locations...',
                                        style: TextStyle(color: Colors.grey)),
                                  )
                                ]
                              : locations.isEmpty
                                  ? [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('No locations found',
                                            style: TextStyle(color: Colors.grey)),
                                      )
                                    ]
                                  : locations.map((location) {
                                      print(
                                          '🏠 Location dropdown item: ${location['name']}');
                                      return DropdownMenuItem<String>(
                                        value: location['name'] as String,
                                        child: Text(location['name'] as String,
                                            style: const TextStyle(color: Colors.white)),
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
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
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary, width: 2),
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
                                borderSide:
                                    BorderSide(color: colorScheme.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[900],
                            ),
                            value: selectedOfficialList,
                            hint: const Text('Choose a saved list',
                                style: TextStyle(color: Colors.grey)),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            dropdownColor: Colors.grey[900],
                            onChanged: (newValue) =>
                                setState(() => selectedOfficialList = newValue),
                            items: isLoadingDropdowns
                                ? [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Loading lists...',
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
                                        final listName = list['name'] as String;
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
                              border:
                                  Border.all(color: colorScheme.primary, width: 1.5),
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
                                          onChanged: (value) {
                                            setState(() {
                                              listConfig['list'] = value;
                                            });
                                          },
                                          items: officialLists.isEmpty
                                              ? [
                                                  const DropdownMenuItem<
                                                      String>(
                                                    value: null,
                                                    child: Text(
                                                        'No lists available',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.grey)),
                                                  )
                                                ]
                                              : officialLists.map((list) {
                                                  final listName =
                                                      list['name'] as String;
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: listName,
                                                    child: Text(listName,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white)),
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
                                                    borderSide:
                                                        BorderSide(
                                                            color:
                                                                colorScheme.primary,
                                                            width: 1),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide:
                                                        BorderSide(
                                                            color:
                                                                colorScheme.primary,
                                                            width: 1),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide:
                                                        BorderSide(
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
                                                    borderSide:
                                                        BorderSide(
                                                            color:
                                                                colorScheme.primary,
                                                            width: 1),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide:
                                                        BorderSide(
                                                            color:
                                                                colorScheme.primary,
                                                            width: 1),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    borderSide:
                                                        BorderSide(
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
                              border:
                                  Border.all(color: colorScheme.primary, width: 1.5),
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
                child: const Text('Save Template',
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