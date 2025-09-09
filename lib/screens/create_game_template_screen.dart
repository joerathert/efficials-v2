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
  String? levelOfCompetition;
  String? gender;
  int? officialsRequired;
  bool hireAutomatically = false;
  String? method;

  // Include checkboxes for template fields (all start checked)
  bool includeSport = true;
  bool includeScheduleName =
      false; // Optional since templates can be used across schedules
  bool includeTime = true;
  bool includeLocation = true;
  bool includeLevelOfCompetition = true;
  bool includeGender = true;
  bool includeOfficialsRequired = true;
  bool includeGameFee = true;
  bool includeHireAutomatically = true;

  // Dropdown data
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> officialLists = [];
  bool isLoadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
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

      // Load schedules
      final scheduleData = await GameService().getSchedules();
      schedules = scheduleData
          .map((schedule) => {
                'id': schedule['id'],
                'name': schedule['name'],
                'sport': schedule['sport'],
              })
          .toList();
      print('📅 CreateGameTemplate: Loaded ${schedules.length} schedules');

      // Load official lists
      officialLists = await OfficialListService().fetchOfficialLists();
      print(
          '📋 CreateGameTemplate: Loaded ${officialLists.length} official lists');
      if (officialLists.isNotEmpty) {
        print('📋 CreateGameTemplate: First list: ${officialLists.first}');
      }

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
    'Varsity',
    'JV',
    'Freshman',
    'Sophomore',
    'Club'
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

    // Prepare template data
    final templateData = {
      'name': _nameController.text,
      'includeSport': includeSport,
      if (includeSport) 'sport': sport,
      'includeScheduleName': includeScheduleName,
      'includeTime': includeTime,
      if (includeTime && selectedTime != null)
        'time': {'hour': selectedTime!.hour, 'minute': selectedTime!.minute},
      'includeLocation': includeLocation,
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
    };

    try {
      final result = await GameService().createTemplate(templateData);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template saved successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save template. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving template: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Icon(Icons.sports, color: Colors.yellow, size: 32),
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
                  const Center(
                    child: Text('Template Configuration',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow)),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Template Name',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Sport',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
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

                  // Schedule Name - Dropdown (Optional)
                  Row(
                    children: [
                      Checkbox(
                        value: includeScheduleName,
                        onChanged: (value) => setState(
                            () => includeScheduleName = value ?? false),
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Schedule Name',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: null,
                          hint: const Text('Select Schedule (Optional)',
                              style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: Colors.grey[900],
                          onChanged: (newValue) => setState(() {}),
                          items: schedules.map((schedule) {
                            return DropdownMenuItem<String>(
                              value: schedule['name'] as String,
                              child: Text(schedule['name'] as String,
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
                        activeColor: Colors.yellow,
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
                                  Border.all(color: Colors.yellow, width: 1.5),
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
                                const Icon(Icons.access_time,
                                    color: Colors.yellow),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          value: null,
                          hint: const Text('Select Location',
                              style: TextStyle(color: Colors.grey)),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          dropdownColor: Colors.grey[800],
                          onChanged: (newValue) => setState(() {}),
                          items: locations.map((location) {
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Level of Competition',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: '# of Officials Required',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _gameFeeController,
                          decoration: InputDecoration(
                            labelText: 'Game Fee per Official',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      const Text('Hire Automatically',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(width: 16),
                      Switch(
                        value: hireAutomatically,
                        onChanged: (value) =>
                            setState(() => hireAutomatically = value),
                        activeColor: Colors.yellow,
                        activeTrackColor: Colors.yellow.withOpacity(0.3),
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
                        activeColor: Colors.yellow,
                        checkColor: Colors.black,
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Selection Method',
                            labelStyle: const TextStyle(color: Colors.white),
                            border: const OutlineInputBorder(),
                            enabledBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 1.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.yellow, width: 2),
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
                        const SizedBox(width: 24), // Align with checkbox space
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Official List',
                              labelStyle: const TextStyle(color: Colors.white),
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.yellow, width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.yellow, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[900],
                            ),
                            value: null,
                            hint: const Text('Choose a saved list',
                                style: TextStyle(color: Colors.grey)),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            dropdownColor: Colors.grey[900],
                            onChanged: (newValue) => setState(() {}),
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
                                          child: Text('No official lists found',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        )
                                      ]
                                    : officialLists.map((list) {
                                        print(
                                            '📋 Dropdown item: ${list['name']}');
                                        return DropdownMenuItem<String>(
                                          value: list['name'] as String,
                                          child: Text(list['name'] as String,
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                        );
                                      }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ] else if (method == 'advanced') ...[
                    Row(
                      children: [
                        const SizedBox(width: 24), // Align with checkbox space
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              border:
                                  Border.all(color: Colors.yellow, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Advanced list configuration coming soon',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.access_time, color: Colors.yellow),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (method == 'hire_crew') ...[
                    Row(
                      children: [
                        const SizedBox(width: 24), // Align with checkbox space
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              border:
                                  Border.all(color: Colors.yellow, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Crew hiring configuration coming soon',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.group, color: Colors.yellow),
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
                  backgroundColor: Colors.yellow,
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
