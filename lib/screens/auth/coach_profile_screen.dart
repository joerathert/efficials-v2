import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../providers/theme_provider.dart';

class CoachProfileScreen extends StatefulWidget {
  const CoachProfileScreen({super.key});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  Map<String, dynamic>? profileData;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final GameService _gameService = GameService();

  String? _selectedSport;
  String? _selectedGrade;
  String? _selectedGender;
  bool _isSchoolAffiliated = false;

  final List<String> sports = [
    'Baseball',
    'Basketball',
    'Football',
    'Soccer',
    'Softball',
    'Volleyball'
  ];

  // Age-based competition levels (current system)
  final List<String> ageBasedGrades = [
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
    'Adult'
  ];

  // School grade-based competition levels
  final List<String> schoolBasedGrades = [
    '3rd Grade',
    '4th Grade',
    '5th Grade',
    '6th Grade',
    '7th Grade',
    '8th Grade',
    'Freshmen',
    'Sophomore',
    'JV',
    'Varsity'
  ];

  // Get current grade options based on school affiliation
  List<String> get grades =>
      _isSchoolAffiliated ? schoolBasedGrades : ageBasedGrades;

  List<String> genders = ['Boys', 'Girls', 'Co-ed'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    profileData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _updateGenderOptions(String? grade) {
    setState(() {
      if (_isSchoolAffiliated) {
        // School-based system: Freshmen, Sophomore, JV, Varsity are typically high school
        if (grade == 'Freshmen' ||
            grade == 'Sophomore' ||
            grade == 'JV' ||
            grade == 'Varsity') {
          genders = ['Boys', 'Girls', 'Co-ed'];
        } else {
          genders = ['Boys', 'Girls', 'Co-ed'];
        }
      } else {
        // Age-based system: Adult teams have different gender options
        if (grade == 'Adult') {
          genders = ['Men', 'Women', 'Co-ed'];
        } else {
          genders = ['Boys', 'Girls', 'Co-ed'];
        }
      }
      _selectedGender = null; // Reset gender selection
    });
  }

  void _onSchoolAffiliationChanged(bool isAffiliated) {
    setState(() {
      _isSchoolAffiliated = isAffiliated;
      _selectedGrade = null; // Reset grade selection when switching systems
      _updateGenderOptions(null); // Update gender options for new system
    });
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    if (value.trim().length != 2) {
      return 'State must be 2 letters (e.g., IL)';
    }
    return null;
  }

  String? _validateZip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zip code is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a valid zip code';
    }
    return null;
  }

  String? _validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName';
    }
    return null;
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (profileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile data missing. Please start over.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Starting coach account creation process');
      print('DEBUG: Profile data keys: ${profileData?.keys}');

      // Create profile data
      final profile = ProfileData(
        firstName: profileData!['firstName'],
        lastName: profileData!['lastName'],
        phone: profileData!['phone'],
      );
      print('DEBUG: Profile created successfully');

      // Create full address for default location
      final fullAddress =
          '${_addressController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim().toUpperCase()} ${_zipController.text.trim()}';

      // Create location identifier with name and address
      final locationName = _locationNameController.text.trim();
      final defaultLocationId = locationName.isNotEmpty
          ? '$locationName - $fullAddress'
          : fullAddress;

      // Create coach profile
      final coachProfile = SchedulerProfile.coach(
        teamName: _teamNameController.text.trim(),
        sport: _selectedSport!,
        levelOfCompetition: _selectedGrade!,
        gender: _selectedGender!,
        defaultLocationId: defaultLocationId,
      );
      print('DEBUG: Coach profile created successfully');

      // Create user account
      print('DEBUG: Calling signUpWithEmailAndPassword...');
      final result = await _authService.signUpWithEmailAndPassword(
        email: profileData!['email'],
        password: profileData!['password'],
        profile: profile,
        role: 'scheduler',
        schedulerProfile: coachProfile,
      );
      print(
          'DEBUG: SignUp result - success: ${result.success}, error: ${result.error}');

      if (result.success && result.user != null) {
        try {
          // Create a schedule for the coach using their team name
          debugPrint(
              '📅 COACH SIGNUP: Creating schedule for team: ${_teamNameController.text.trim()}');
          await _gameService.createSchedule(
            _teamNameController.text.trim(),
            _selectedSport!,
            homeTeamName: _teamNameController.text.trim(),
          );
          debugPrint('✅ COACH SIGNUP: Schedule created successfully');
        } catch (e) {
          debugPrint('❌ COACH SIGNUP: Error creating schedule: $e');
          // Don't block account creation if schedule creation fails
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to Coach home
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/coach-home',
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to create account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Full error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Icon(
              Icons.sports,
              color: themeProvider.isDarkMode
                  ? Theme.of(context).colorScheme.primary // Yellow in dark mode
                  : Colors.black, // Black in light mode
              size: 32,
            );
          },
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Team Setup',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .primary // Yellow in dark mode
                        : Theme.of(context)
                            .colorScheme
                            .onBackground, // Dark in light mode
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your team information to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team Name Field
                      TextFormField(
                        controller: _teamNameController,
                        decoration: InputDecoration(
                          labelText: 'Team Name',
                          hintText: 'e.g., JV Basketball',
                          helperText: 'How your team will appear on schedules',
                        ),
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            _validateRequired(value, 'Team name'),
                      ),
                      const SizedBox(height: 20),

                      // Sport Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Sport',
                        ),
                        hint: const Text(
                          'Select your sport',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[800],
                        iconEnabledColor: Theme.of(context).colorScheme.primary,
                        value: _selectedSport,
                        items: sports.map((sport) {
                          return DropdownMenuItem(
                            value: sport,
                            child: Text(sport,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        validator: (value) => _validateDropdown(value, 'sport'),
                        onChanged: (value) {
                          setState(() {
                            _selectedSport = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // School Affiliation Toggle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Is this team affiliated with a school?',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Switch(
                                value: _isSchoolAffiliated,
                                onChanged: _onSchoolAffiliationChanged,
                                activeThumbColor:
                                    Theme.of(context).colorScheme.primary,
                                activeTrackColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isSchoolAffiliated ? 'Yes' : 'No',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSchoolAffiliated
                                ? 'Using school grade levels (3rd Grade - Varsity)'
                                : 'Using age-based levels (6U - 18U, Adult)',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Level of Competition Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Level of Competition',
                        ),
                        hint: Text(
                          _isSchoolAffiliated
                              ? 'Select grade level'
                              : 'Select age level',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[800],
                        iconEnabledColor: Theme.of(context).colorScheme.primary,
                        value: _selectedGrade,
                        items: grades.map((grade) {
                          return DropdownMenuItem(
                            value: grade,
                            child: Text(grade,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        validator: (value) =>
                            _validateDropdown(value, 'level of competition'),
                        onChanged: (value) {
                          setState(() {
                            _selectedGrade = value;
                            _updateGenderOptions(value);
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Gender',
                        ),
                        hint: const Text(
                          'Select gender',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[800],
                        iconEnabledColor: Theme.of(context).colorScheme.primary,
                        value: _selectedGender,
                        items: genders.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        validator: (value) =>
                            _validateDropdown(value, 'gender'),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      // Home Games Location Section
                      Text(
                        'Where are your home games played?',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This helps us show you officials within a reasonable distance',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location Name Field
                      TextFormField(
                        controller: _locationNameController,
                        decoration: InputDecoration(
                          labelText: 'Location Name',
                          hintText: 'Ex. Maryville Sports Complex',
                        ),
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            _validateRequired(value, 'Location Name'),
                      ),
                      const SizedBox(height: 20),

                      // Address Field
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Street address',
                        ),
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            _validateRequired(value, 'Address'),
                      ),
                      const SizedBox(height: 20),

                      // City Field
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'City',
                        ),
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _validateRequired(value, 'City'),
                      ),
                      const SizedBox(height: 20),

                      // State and Zip Row
                      Row(
                        children: [
                          // State Field
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _stateController,
                              decoration: InputDecoration(
                                labelText: 'ST',
                                hintText: 'ST',
                              ),
                              style: const TextStyle(color: Colors.white),
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.next,
                              maxLength: 2,
                              buildCounter: (context,
                                      {required currentLength,
                                      required isFocused,
                                      maxLength}) =>
                                  null, // Hide counter
                              validator: _validateState,
                              onChanged: (value) {
                                // Auto-uppercase state input
                                if (value != value.toUpperCase()) {
                                  _stateController.value =
                                      _stateController.value.copyWith(
                                    text: value.toUpperCase(),
                                    selection: TextSelection.collapsed(
                                        offset: value.length),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Zip Field
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _zipController,
                              decoration: InputDecoration(
                                labelText: 'Zip Code',
                                hintText: 'Zip Code',
                              ),
                              style: const TextStyle(color: Colors.white),
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.number,
                              validator: _validateZip,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Create Account Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
  }
}
