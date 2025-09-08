import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class OfficialProfileScreen extends StatefulWidget {
  const OfficialProfileScreen({super.key});

  @override
  State<OfficialProfileScreen> createState() => _OfficialProfileScreenState();
}

class _OfficialProfileScreenState extends State<OfficialProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String _formatPhoneNumber(String value) {
    // Remove all non-digits
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 10 digits
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Format based on length
    if (digitsOnly.length >= 6) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length >= 3) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
    } else if (digitsOnly.isNotEmpty) {
      return '($digitsOnly';
    }
    return '';
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please accept the Terms of Service and Privacy Policy')),
      );
      return;
    }

    // Clean phone number (digits only)
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final profileData = {
      'email': _emailController.text.trim().toLowerCase(),
      'password': _passwordController.text,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': cleanPhone,
      'role': 'official',
    };

    // Navigate to next step in official registration
    Navigator.pushNamed(
      context,
      '/official-step2',
      arguments: profileData,
    );
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
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Title - Official Registration
                    Center(
                      child: Text(
                        'Official Registration',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.primary // Yellow in dark mode
                              : colorScheme.onBackground, // Dark in light mode
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle - Step 1 of 4: Basic Information
                    Center(
                      child: Text(
                        'Step 1 of 4: Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form Fields Container
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 500),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[800] // Dark gray for dark mode
                              : Colors.grey[300], // Light gray for light mode
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.black.withOpacity(
                                      0.3) // Dark shadow for dark mode
                                  : colorScheme.shadow.withOpacity(
                                      0.1), // Light shadow for light mode
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors
                                          .grey[400] // Light gray for dark mode
                                      : colorScheme
                                          .onSurfaceVariant, // Theme-aware for light mode
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            500]! // Subtle gray for dark mode
                                        : colorScheme.outline.withOpacity(
                                            0.5), // Theme-aware for light mode
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme
                                            .primary // Yellow for dark mode
                                        : Colors.black, // Black for light mode
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors
                                        .grey[700] // Dark fill for dark mode
                                    : colorScheme
                                        .surface, // Theme-aware fill for light mode
                              ),
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white // White text for dark mode
                                    : colorScheme
                                        .onSurface, // Theme-aware text for light mode
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors
                                          .grey[400] // Light gray for dark mode
                                      : colorScheme
                                          .onSurfaceVariant, // Theme-aware for light mode
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            400] // Light gray for dark mode
                                        : colorScheme
                                            .onSurfaceVariant, // Theme-aware for light mode
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            500]! // Subtle gray for dark mode
                                        : colorScheme.outline.withOpacity(
                                            0.5), // Theme-aware for light mode
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme
                                            .primary // Yellow for dark mode
                                        : Colors.black, // Black for light mode
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors
                                        .grey[700] // Dark fill for dark mode
                                    : colorScheme
                                        .surface, // Theme-aware fill for light mode
                              ),
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white // White text for dark mode
                                    : colorScheme
                                        .onSurface, // Theme-aware text for light mode
                              ),
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.next,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Confirm your password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors
                                          .grey[400] // Light gray for dark mode
                                      : colorScheme
                                          .onSurfaceVariant, // Theme-aware for light mode
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            400] // Light gray for dark mode
                                        : colorScheme
                                            .onSurfaceVariant, // Theme-aware for light mode
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showConfirmPassword =
                                          !_showConfirmPassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            500]! // Subtle gray for dark mode
                                        : colorScheme.outline.withOpacity(
                                            0.5), // Theme-aware for light mode
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme
                                            .primary // Yellow for dark mode
                                        : Colors.black, // Black for light mode
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors
                                        .grey[700] // Dark fill for dark mode
                                    : colorScheme
                                        .surface, // Theme-aware fill for light mode
                              ),
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white // White text for dark mode
                                    : colorScheme
                                        .onSurface, // Theme-aware text for light mode
                              ),
                              obscureText: !_showConfirmPassword,
                              textInputAction: TextInputAction.next,
                              validator: _validateConfirmPassword,
                            ),
                            const SizedBox(height: 20),

                            // First Name Field
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                hintText: 'Enter your first name',
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors
                                          .grey[400] // Light gray for dark mode
                                      : colorScheme
                                          .onSurfaceVariant, // Theme-aware for light mode
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            500]! // Subtle gray for dark mode
                                        : colorScheme.outline.withOpacity(
                                            0.5), // Theme-aware for light mode
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme
                                            .primary // Yellow for dark mode
                                        : Colors.black, // Black for light mode
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors
                                        .grey[700] // Dark fill for dark mode
                                    : colorScheme
                                        .surface, // Theme-aware fill for light mode
                              ),
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white // White text for dark mode
                                    : colorScheme
                                        .onSurface, // Theme-aware text for light mode
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: _validateName,
                            ),
                            const SizedBox(height: 20),

                            // Last Name Field
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                hintText: 'Enter your last name',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors
                                          .grey[400] // Light gray for dark mode
                                      : colorScheme
                                          .onSurfaceVariant, // Theme-aware for light mode
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            500]! // Subtle gray for dark mode
                                        : colorScheme.outline.withOpacity(
                                            0.5), // Theme-aware for light mode
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme
                                            .primary // Yellow for dark mode
                                        : Colors.black, // Black for light mode
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors
                                        .grey[700] // Dark fill for dark mode
                                    : colorScheme
                                        .surface, // Theme-aware fill for light mode
                              ),
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white // White text for dark mode
                                    : colorScheme
                                        .onSurface, // Theme-aware text for light mode
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: _validateName,
                            ),
                            const SizedBox(height: 20),

                            // Phone Field
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: '(555) 123-4567',
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors
                                          .grey[400] // Light gray for dark mode
                                      : colorScheme
                                          .onSurfaceVariant, // Theme-aware for light mode
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            500]! // Subtle gray for dark mode
                                        : colorScheme.outline.withOpacity(
                                            0.5), // Theme-aware for light mode
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme
                                            .primary // Yellow for dark mode
                                        : Colors.black, // Black for light mode
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme.brightness == Brightness.dark
                                    ? Colors
                                        .grey[700] // Dark fill for dark mode
                                    : colorScheme
                                        .surface, // Theme-aware fill for light mode
                              ),
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white // White text for dark mode
                                    : colorScheme
                                        .onSurface, // Theme-aware text for light mode
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              validator: _validatePhone,
                              onChanged: (value) {
                                // Format phone number as user types
                                String formatted = _formatPhoneNumber(value);
                                if (formatted != value) {
                                  _phoneController.value =
                                      _phoneController.value.copyWith(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 30),

                            // Terms and Conditions Checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptedTerms = value ?? false;
                                    });
                                  },
                                  activeColor:
                                      theme.brightness == Brightness.dark
                                          ? colorScheme
                                              .primary // Yellow in dark mode
                                          : Colors.black, // Black in light mode
                                  checkColor: theme.brightness ==
                                          Brightness.dark
                                      ? Colors
                                          .black // Black checkmark on yellow background
                                      : Colors
                                          .white, // White checkmark on black background
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'I accept the Terms of Service and Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors
                                              .white // White text for dark mode
                                          : colorScheme
                                              .onSurface, // Theme-aware text for light mode
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Continue Button
                    Center(
                      child: SizedBox(
                        width: 400,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
        ),
      ),
    );
  }
}
