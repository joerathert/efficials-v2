import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';

class AssignerProfileScreen extends StatefulWidget {
  const AssignerProfileScreen({super.key});

  @override
  State<AssignerProfileScreen> createState() => _AssignerProfileScreenState();
}

class _AssignerProfileScreenState extends State<AssignerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  Map<String, dynamic>? profileData;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  String? _selectedSport;

  final List<String> sports = [
    'Baseball',
    'Basketball',
    'Football',
    'Soccer',
    'Softball',
    'Volleyball'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    profileData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
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
      print('DEBUG: Starting assigner account creation process');
      print('DEBUG: Profile data keys: ${profileData?.keys}');

      // Create profile data
      final profile = ProfileData(
        firstName: profileData!['firstName'],
        lastName: profileData!['lastName'],
        phone: profileData!['phone'],
      );
      print('DEBUG: Profile created successfully');

      // Create address data for assigner
      final homeAddress = AddressData(
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        zipCode: _zipController.text.trim(),
      );

      // Create assigner profile
      final assignerProfile = SchedulerProfile.assigner(
        organizationName: _organizationNameController.text.trim(),
        sport: _selectedSport!,
        homeAddress: homeAddress,
      );
      print('DEBUG: Assigner profile created successfully');

      // Create user account
      print('DEBUG: Calling signUpWithEmailAndPassword...');
      final result = await _authService.signUpWithEmailAndPassword(
        email: profileData!['email'],
        password: profileData!['password'],
        profile: profile,
        role: 'scheduler',
        schedulerProfile: assignerProfile,
      );
      print(
          'DEBUG: SignUp result - success: ${result.success}, error: ${result.error}');

      if (result.success && result.user != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to Assigner home
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/assigner-home',
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
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
                  'Assigner Setup',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? colorScheme.primary // Yellow in dark mode
                        : colorScheme.onBackground, // Dark in light mode
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your organization information to get started',
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
                      // Organization Name Field
                      TextFormField(
                        controller: _organizationNameController,
                        decoration: InputDecoration(
                          labelText: 'Organization Name',
                          hintText: 'e.g., Metro Basketball League',
                          helperText:
                              'The league or association you assign officials for',
                        ),
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            _validateRequired(value, 'Organization name'),
                      ),
                      const SizedBox(height: 20),

                      // Sport Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Primary Sport',
                        ),
                        hint: const Text(
                          'Select your primary sport',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: const TextStyle(color: Colors.white),
                        dropdownColor: Colors.grey[800],
                        iconEnabledColor: colorScheme.primary,
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
                      const SizedBox(height: 30),

                      // Assignment Area Address Section
                      Text(
                        'Assignment Area Address',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This helps us find officials in your area. Use your league office, school, or primary location where games are typically held.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
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
                      backgroundColor: colorScheme.primary,
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
