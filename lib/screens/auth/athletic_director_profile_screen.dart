import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';

class AthleticDirectorProfileScreen extends StatefulWidget {
  const AthleticDirectorProfileScreen({super.key});

  @override
  State<AthleticDirectorProfileScreen> createState() =>
      _AthleticDirectorProfileScreenState();
}

class _AthleticDirectorProfileScreenState
    extends State<AthleticDirectorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _teamNameController = TextEditingController();

  Map<String, dynamic>? profileData;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    profileData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _teamNameController.dispose();
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
      print('DEBUG: Starting account creation process');
      print('DEBUG: Profile data keys: ${profileData?.keys}');

      // Create profile data
      final profile = ProfileData(
        firstName: profileData!['firstName'],
        lastName: profileData!['lastName'],
        phone: profileData!['phone'],
      );
      print('DEBUG: Profile created successfully');

      // Create scheduler profile
      final fullAddress =
          '${_addressController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim().toUpperCase()} ${_zipController.text.trim()}';
      final schedulerProfile = SchedulerProfile.athleticDirector(
        schoolName: _schoolNameController.text.trim(),
        teamName: _teamNameController.text.trim(),
        schoolAddress: fullAddress,
      );
      print('DEBUG: Scheduler profile created successfully');

      // Create user account
      print('DEBUG: Calling signUpWithEmailAndPassword...');
      final result = await _authService.signUpWithEmailAndPassword(
        email: profileData!['email'],
        password: profileData!['password'],
        profile: profile,
        role: 'scheduler',
        schedulerProfile: schedulerProfile,
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

          // Navigate to Athletic Director home
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/athletic-director-home',
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
      print('DEBUG: Full error details: $e'); // Add detailed logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // Show longer to read
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
                  ? Theme.of(context).colorScheme.primary // Yellow in dark mode
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
                  'School Information',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .primary // Yellow in dark mode
                        : colorScheme.onBackground, // Dark in light mode
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your school',
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
                      // School Name Field
                      TextFormField(
                        controller: _schoolNameController,
                        decoration: InputDecoration(
                          labelText: 'School Name',
                          hintText: 'e.g., Edwardsville High School',
                          prefixIcon:
                              const Icon(Icons.school, color: Colors.grey),
                          helperText: 'Official school name for records',
                        ),
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            _validateRequired(value, 'School name'),
                      ),
                      const SizedBox(height: 20),

                      // Address Field
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Address',
                          prefixIcon:
                              const Icon(Icons.home, color: Colors.grey),
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
                          prefixIcon: const Icon(Icons.location_city,
                              color: Colors.grey),
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
                                prefixIcon:
                                    const Icon(Icons.map, color: Colors.grey),
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
                                prefixIcon: const Icon(Icons.local_post_office,
                                    color: Colors.grey),
                              ),
                              style: const TextStyle(color: Colors.white),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              validator: _validateZip,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Team Name Field with explanation
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How would you like your school\'s team name to appear on schedules?',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Examples: "Edwardsville Tigers", "St. Mary\'s Redbirds"',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _teamNameController,
                            decoration: InputDecoration(
                              labelText: 'Team Name',
                              hintText: 'e.g., Edwardsville Tigers',
                              prefixIcon:
                                  const Icon(Icons.sports, color: Colors.grey),
                            ),
                            style: const TextStyle(color: Colors.white),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            validator: (value) =>
                                _validateRequired(value, 'Team name'),
                            onChanged: (value) =>
                                setState(() {}), // Update preview
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Preview Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule Preview',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _teamNameController.text.trim().isEmpty
                                  ? 'Troy Saints @ [Enter your team name]'
                                  : 'Troy Saints @ ${_teamNameController.text.trim()}',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
