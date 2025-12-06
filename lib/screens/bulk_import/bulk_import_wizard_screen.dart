import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../app_theme.dart';
import '../../services/bulk_import_service.dart';
import '../../services/user_repository.dart';
import '../../services/location_service.dart';
import '../../services/official_list_service.dart';

class BulkImportWizardScreen extends StatefulWidget {
  const BulkImportWizardScreen({super.key});

  @override
  State<BulkImportWizardScreen> createState() => _BulkImportWizardScreenState();
}

class _BulkImportWizardScreenState extends State<BulkImportWizardScreen> {
  final PageController _pageController = PageController();
  int currentStep = 0;

  // Step 1: Number of schedules
  int numberOfSchedules = 1;

  // Step 2: Global settings
  Map<String, bool> globalSettings = {
    'gender': false,
    'competitionLevel': false,
    'officialsRequired': false,
    'gameFee': false,
    'method': false,
    'hireAutomatically': false,
    'location': false,
    'time': false,
  };

  // Global values
  Map<String, dynamic> globalValues = {};

  // Available options
  List<Map<String, dynamic>> availableLocations = [];
  List<Map<String, dynamic>> availableLists = [];
  List<Map<String, dynamic>> availableCrewLists = [];

  // Selected lists for Multiple Lists method
  List<Map<String, dynamic>> selectedMultipleLists = [];

  String? currentUserSport;
  bool isLoading = true;

  final UserRepository _userRepository = UserRepository();
  final LocationService _locationService = LocationService();
  final OfficialListService _officialListService = OfficialListService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadUserSport(),
        _loadLocations(),
        _loadOfficialsLists(),
        _loadCrewLists(),
      ]);

      // Initialize global values
      globalValues = {
        'gender': null,
        'competitionLevel': null,
        'officialsRequired': null,
        'gameFee': null,
        'method': null,
        'hireAutomatically': null,
        'location': null,
        'time': null,
        'selectedList': null,
        'selectedCrewList': null,
        'selectedMultipleLists': <Map<String, dynamic>>[],
      };

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserSport() async {
    try {
      final currentUser = await _userRepository.getCurrentUser();
      setState(() {
        currentUserSport = currentUser?.schedulerProfile?.sport ?? 'Unknown';
      });
    } catch (e) {
      debugPrint('Error loading user sport: $e');
    }
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _locationService.getLocations();
      setState(() {
        availableLocations = List<Map<String, dynamic>>.from(locations);
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  Future<void> _loadOfficialsLists() async {
    try {
      final lists = await _officialListService.fetchOfficialLists();
      setState(() {
        availableLists = List<Map<String, dynamic>>.from(lists);
      });
    } catch (e) {
      debugPrint('Error loading officials lists: $e');
    }
  }

  Future<void> _loadCrewLists() async {
    // TODO: Load crew lists when implemented
    setState(() {
      availableCrewLists = [];
    });
  }

  void nextStep() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToGenerate() {
    // Build schedule configs
    final scheduleConfigs = <ScheduleConfig>[];
    for (int i = 0; i < numberOfSchedules; i++) {
      scheduleConfigs.add(ScheduleConfig(
        scheduleName: '', // Will be set in generate screen
        teamName: '',
        numberOfGames: 4, // Default
      ));
    }

    final config = BulkImportConfig(
      numberOfSchedules: numberOfSchedules,
      sport: currentUserSport ?? 'Unknown',
      globalSettings: globalSettings,
      globalValues: globalValues,
      scheduleConfigs: scheduleConfigs,
    );

    Navigator.pushNamed(
      context,
      '/bulk_import_generate',
      arguments: config,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: Text(
          'Step ${currentStep + 1} of 3',
          style: const TextStyle(color: AppColors.efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: currentStep == 0 ? () => Navigator.pop(context) : previousStep,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.efficialsYellow))
          : PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
      bottomNavigationBar: isLoading
          ? null
          : Container(
              color: AppColors.efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: TextButton(
                        onPressed: previousStep,
                        child: const Text(
                          'Back',
                          style: TextStyle(color: AppColors.efficialsYellow, fontSize: 16),
                        ),
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: currentStep == 2 ? goToGenerate : nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.efficialsYellow,
                        foregroundColor: AppColors.efficialsBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        currentStep == 2 ? 'Configure Schedules' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How many schedules?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.efficialsYellow,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each schedule will get its own sheet in the Excel file.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 40),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed:
                          numberOfSchedules > 1 ? () => setState(() => numberOfSchedules--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: numberOfSchedules > 1 ? AppColors.efficialsYellow : Colors.grey,
                      iconSize: 40,
                    ),
                    Column(
                      children: [
                        Text(
                          numberOfSchedules.toString(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.efficialsYellow,
                          ),
                        ),
                        Text(
                          'schedule${numberOfSchedules == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: numberOfSchedules < 50
                          ? () => setState(() => numberOfSchedules++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: numberOfSchedules < 50 ? AppColors.efficialsYellow : Colors.grey,
                      iconSize: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.efficialsYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.efficialsYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sport: ${currentUserSport ?? 'Unknown'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.efficialsYellow,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check any settings that are the same for ALL games. Leave unchecked to set per-game in Excel.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 30),

          _buildGlobalSettingTile(
            'gender',
            'Gender',
            globalValues['gender']?.toString() ?? '',
            onValueChanged: (value) => globalValues['gender'] = value,
            options: BulkImportService.genderOptions,
          ),

          _buildGlobalSettingTile(
            'competitionLevel',
            'Competition Level',
            globalValues['competitionLevel']?.toString() ?? '',
            onValueChanged: (value) => globalValues['competitionLevel'] = value,
            options: BulkImportService.competitionLevels,
          ),

          _buildGlobalSettingTile(
            'officialsRequired',
            'Officials Required',
            globalValues['officialsRequired']?.toString() ?? '',
            onValueChanged: (value) => globalValues['officialsRequired'] = int.parse(value),
            options: ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
          ),

          _buildGlobalSettingTile(
            'gameFee',
            'Game Fee per Official',
            globalValues['gameFee']?.toString() ?? '',
            onValueChanged: (value) => globalValues['gameFee'] = value.replaceAll('\$', ''),
            isTextField: true,
          ),

          _buildGlobalSettingTile(
            'method',
            'Officials Assignment Method',
            globalValues['method']?.toString() ?? '',
            onValueChanged: (value) {
              setState(() {
                globalValues['method'] = value;
                globalValues['selectedList'] = null;
                globalValues['selectedCrewList'] = null;
                if (value == 'Multiple Lists') {
                  selectedMultipleLists = [
                    {'list': null, 'min': 0, 'max': 1},
                    {'list': null, 'min': 0, 'max': 1},
                  ];
                } else {
                  selectedMultipleLists.clear();
                }
              });
            },
            options: BulkImportService.methodOptions,
            hasSecondaryDropdown: true,
          ),

          _buildGlobalSettingTile(
            'location',
            'Home Location',
            globalValues['location']?.toString() ?? '',
            onValueChanged: (value) => globalValues['location'] = value,
            options: availableLocations.map((loc) => loc['name'] as String).toList(),
          ),

          _buildGlobalSettingTile(
            'time',
            'Game Time',
            globalValues['time']?.toString() ?? '',
            onValueChanged: (value) => globalValues['time'] = value,
            isTimePicker: true,
          ),

          _buildGlobalSettingTile(
            'hireAutomatically',
            'Hire Automatically',
            globalValues['hireAutomatically'] == null
                ? ''
                : (globalValues['hireAutomatically'] as bool ? 'Yes' : 'No'),
            onValueChanged: (value) => globalValues['hireAutomatically'] = value == 'Yes',
            options: BulkImportService.yesNoOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    // Get list of settings that are NOT set globally
    final unsetSettings = <String>[];
    if (!(globalSettings['gender'] ?? false)) unsetSettings.add('Gender');
    if (!(globalSettings['competitionLevel'] ?? false)) unsetSettings.add('Competition Level');
    if (!(globalSettings['officialsRequired'] ?? false)) unsetSettings.add('Officials Required');
    if (!(globalSettings['gameFee'] ?? false)) unsetSettings.add('Game Fee');
    if (!(globalSettings['method'] ?? false)) unsetSettings.add('Officials Method');
    if (!(globalSettings['hireAutomatically'] ?? false)) unsetSettings.add('Hire Automatically');
    if (!(globalSettings['location'] ?? false)) unsetSettings.add('Location');
    if (!(globalSettings['time'] ?? false)) unsetSettings.add('Time');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Excel Summary',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.efficialsYellow,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review what will be in your Excel file.',
            style: TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 30),

          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.efficialsYellow),
                    const SizedBox(width: 12),
                    Text(
                      '$numberOfSchedules Schedule${numberOfSchedules == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Each schedule will have its own sheet in the Excel file.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Global settings summary
          if (globalSettings.values.any((v) => v)) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text(
                        'Pre-filled for All Games',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._buildGlobalSettingsSummary(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Columns to fill
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.efficialsYellow.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.efficialsYellow),
                    SizedBox(width: 12),
                    Text(
                      'Columns to Fill in Excel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.efficialsYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Date (required)\n'
                  '• Opponent (required)\n'
                  '• Away Game (Yes/No)\n'
                  '• Link Group (for linked games)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (unsetSettings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    unsetSettings.map((s) => '• $s').join('\n'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Linked games info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.link, color: Colors.blue),
                    SizedBox(width: 12),
                    Text(
                      'Linking Games',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Use the "Link Group" column to link games together. Games with the same link group value (A, B, C, etc.) will be offered to officials as a package.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGlobalSettingsSummary() {
    final widgets = <Widget>[];

    if (globalSettings['gender'] == true && globalValues['gender'] != null) {
      widgets.add(_buildSummaryItem('Gender', globalValues['gender'].toString()));
    }
    if (globalSettings['competitionLevel'] == true && globalValues['competitionLevel'] != null) {
      widgets.add(_buildSummaryItem('Competition Level', globalValues['competitionLevel'].toString()));
    }
    if (globalSettings['officialsRequired'] == true && globalValues['officialsRequired'] != null) {
      widgets.add(_buildSummaryItem('Officials Required', globalValues['officialsRequired'].toString()));
    }
    if (globalSettings['gameFee'] == true && globalValues['gameFee'] != null) {
      widgets.add(_buildSummaryItem('Game Fee', '\$${globalValues['gameFee']}'));
    }
    if (globalSettings['method'] == true && globalValues['method'] != null) {
      widgets.add(_buildSummaryItem('Method', globalValues['method'].toString()));
    }
    if (globalSettings['hireAutomatically'] == true && globalValues['hireAutomatically'] != null) {
      widgets.add(_buildSummaryItem(
          'Hire Automatically', globalValues['hireAutomatically'] == true ? 'Yes' : 'No'));
    }
    if (globalSettings['location'] == true && globalValues['location'] != null) {
      widgets.add(_buildSummaryItem('Location', globalValues['location'].toString()));
    }
    if (globalSettings['time'] == true && globalValues['time'] != null) {
      widgets.add(_buildSummaryItem('Time', globalValues['time'].toString()));
    }

    return widgets;
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSettingTile(
    String key,
    String title,
    String currentValue, {
    bool enabled = true,
    List<String>? options,
    bool isTextField = false,
    bool isTimePicker = false,
    bool hasSecondaryDropdown = false,
    Function(String)? onValueChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (globalSettings[key] ?? false)
              ? AppColors.efficialsYellow.withOpacity(0.5)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: globalSettings[key] ?? false,
                onChanged: enabled
                    ? (value) {
                        setState(() {
                          globalSettings[key] = value ?? false;
                        });
                      }
                    : null,
                activeColor: AppColors.efficialsYellow,
                checkColor: AppColors.efficialsBlack,
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: enabled ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if ((globalSettings[key] ?? false) && onValueChanged != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: isTimePicker
                  ? _buildTimePickerField(currentValue, onValueChanged)
                  : isTextField
                      ? TextField(
                          decoration: InputDecoration(
                            hintText: key == 'gameFee' ? 'Enter fee (e.g., 75)' : 'Enter value',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: AppColors.darkBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            ),
                            prefixText: key == 'gameFee' ? '\$ ' : null,
                            prefixStyle: const TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType:
                              key == 'gameFee' ? TextInputType.number : TextInputType.text,
                          onChanged: onValueChanged,
                        )
                      : DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            ),
                          ),
                          hint: Text(
                            'Select $title',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          value: currentValue.isEmpty ? null : currentValue,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          dropdownColor: AppColors.darkSurface,
                          isExpanded: true,
                          onChanged: (value) => setState(() => onValueChanged(value ?? '')),
                          items: (options ?? []).map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(option, style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                        ),
            ),
          ],
          // Secondary dropdown for method
          if (hasSecondaryDropdown &&
              key == 'method' &&
              (globalSettings[key] ?? false) &&
              currentValue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: _buildSecondaryMethodDropdown(currentValue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerField(String currentValue, Function(String) onValueChanged) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay? initialTime;
        if (currentValue.isNotEmpty) {
          final parts = currentValue.split(' ');
          final timeParts = parts[0].split(':');
          if (timeParts.length == 2) {
            int hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour != 12) {
              hour += 12;
            } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
              hour = 0;
            }
            initialTime = TimeOfDay(hour: hour, minute: minute);
          }
        }

        final pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime ?? const TimeOfDay(hour: 19, minute: 0),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.efficialsYellow,
                  onPrimary: Colors.black,
                  surface: AppColors.darkSurface,
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          final hour = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
          final minute = pickedTime.minute.toString().padLeft(2, '0');
          final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
          final formattedTime = '$hour:$minute $period';
          setState(() => onValueChanged(formattedTime));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              currentValue.isNotEmpty ? currentValue : 'Select Game Time',
              style: TextStyle(
                color: currentValue.isNotEmpty ? Colors.white : Colors.grey,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryMethodDropdown(String method) {
    switch (method) {
      case 'Single List':
        if (availableLists.isEmpty) {
          return const Text(
            'No officials lists available. Create a list first.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          );
        }
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
          ),
          hint: const Text('Select Officials List', style: TextStyle(color: Colors.grey)),
          value: globalValues['selectedList'] as String?,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: AppColors.darkSurface,
          onChanged: (value) {
            setState(() {
              globalValues['selectedList'] = value;
            });
          },
          items: availableLists.map((list) {
            final listName = list['name'] as String;
            return DropdownMenuItem(
              value: listName,
              child: Text(listName, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );

      case 'Multiple Lists':
        if (availableLists.isEmpty) {
          return const Text(
            'No officials lists available. Create multiple lists first.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          );
        }
        return _buildMultipleListsConfiguration();

      case 'Hire a Crew':
        if (availableCrewLists.isEmpty) {
          return const Text(
            'No crew lists available. Crew functionality coming soon.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          );
        }
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
          ),
          hint: const Text('Select Crew List', style: TextStyle(color: Colors.grey)),
          value: globalValues['selectedCrewList'] as String?,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: AppColors.darkSurface,
          onChanged: (value) {
            setState(() {
              globalValues['selectedCrewList'] = value;
            });
          },
          items: availableCrewLists.map((crewList) {
            final listName = crewList['name'] as String;
            return DropdownMenuItem(
              value: listName,
              child: Text(listName, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMultipleListsConfiguration() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Configure Multiple Lists',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (selectedMultipleLists.length < 3)
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedMultipleLists.add({'list': null, 'min': 0, 'max': 1});
                    });
                  },
                  icon: const Icon(Icons.add_circle, color: AppColors.efficialsYellow),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...selectedMultipleLists.asMap().entries.map((entry) {
            final listIndex = entry.key;
            final listConfig = entry.value;
            return _buildMultipleListItem(listIndex, listConfig);
          }),
        ],
      ),
    );
  }

  Widget _buildMultipleListItem(int listIndex, Map<String, dynamic> listConfig) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'List ${listIndex + 1}',
                style: const TextStyle(
                  color: AppColors.efficialsYellow,
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
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.darkSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            hint: const Text('Select Officials List', style: TextStyle(color: Colors.grey)),
            value: listConfig['list'] as String?,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: AppColors.darkSurface,
            onChanged: (value) {
              setState(() {
                listConfig['list'] = value;
              });
            },
            items: availableLists.map((list) {
              return DropdownMenuItem(
                value: list['name'] as String,
                child: Text(
                  list['name'] as String,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Min',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  value: listConfig['min'] as int?,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: AppColors.darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['min'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(num.toString(), style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Max',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ),
                  value: listConfig['max'] as int?,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  dropdownColor: AppColors.darkSurface,
                  onChanged: (value) {
                    setState(() {
                      listConfig['max'] = value;
                    });
                  },
                  items: List.generate(10, (i) => i + 1).map((num) {
                    return DropdownMenuItem(
                      value: num,
                      child: Text(num.toString(), style: const TextStyle(color: Colors.white)),
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
}

