import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class OfficialStep2Screen extends StatefulWidget {
  const OfficialStep2Screen({super.key});

  @override
  State<OfficialStep2Screen> createState() => _OfficialStep2ScreenState();
}

class _OfficialStep2ScreenState extends State<OfficialStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _maxDistanceController = TextEditingController();

  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _appNotifications = true;
  String? _selectedMinRate;

  late Map<String, dynamic> previousData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previousData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _maxDistanceController.dispose();
    super.dispose();
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Street address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a complete address';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    if (value.trim().length != 2) {
      return 'Please enter state abbreviation (e.g., IL, CA)';
    }
    return null;
  }

  String? _validateZip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ZIP code is required';
    }
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value)) {
      return 'Please enter a valid ZIP code';
    }
    return null;
  }

  String? _validateMaxDistance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Maximum travel distance is required';
    }
    final distance = double.tryParse(value);
    if (distance == null || distance <= 0) {
      return 'Please enter a valid distance greater than 0';
    }
    if (distance > 500) {
      return 'Maximum distance cannot exceed 500 miles';
    }
    return null;
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final maxDistance = double.parse(_maxDistanceController.text.trim());

    final updatedData = {
      ...previousData,
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim().toUpperCase(),
      'zipCode': _zipController.text.trim(),
      'maxTravelDistance': maxDistance,
      'minRatePerGame': _selectedMinRate,
      'emailNotifications': _emailNotifications,
      'smsNotifications': _smsNotifications,
      'appNotifications': _appNotifications,
    };

    // Navigate to step 3 (officiating preferences)
    Navigator.pushNamed(
      context,
      '/official-step3',
      arguments: updatedData,
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

                    // Title - Location & Preferences
                    Center(
                      child: Text(
                        'Location & Preferences',
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

                    // Subtitle - Step 2 of 4: Work Preferences
                    Center(
                      child: Text(
                        'Step 2 of 4: Work Preferences',
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
                            // Home Address Section
                            Text(
                              'Home Address',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.primary // Yellow in dark mode
                                    : colorScheme
                                        .onBackground, // Dark in light mode
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Street Address Field
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Street Address',
                                hintText: 'Enter your street address',
                                prefixIcon: Icon(
                                  Icons.home,
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
                              textInputAction: TextInputAction.next,
                              validator: _validateAddress,
                            ),
                            const SizedBox(height: 16),

                            // City, State, ZIP Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: InputDecoration(
                                      labelText: 'City',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[
                                                  500]! // Subtle gray for dark mode
                                              : colorScheme.outline.withOpacity(
                                                  0.5), // Theme-aware for light mode
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? colorScheme
                                                  .primary // Yellow for dark mode
                                              : Colors
                                                  .black, // Black for light mode
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: theme.brightness ==
                                              Brightness.dark
                                          ? Colors.grey[
                                              700] // Dark fill for dark mode
                                          : colorScheme
                                              .surface, // Theme-aware fill for light mode
                                    ),
                                    style: TextStyle(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors
                                              .white // White text for dark mode
                                          : colorScheme
                                              .onSurface, // Theme-aware text for light mode
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: _validateCity,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(minWidth: 80),
                                    child: TextFormField(
                                      controller: _stateController,
                                      decoration: InputDecoration(
                                        labelText: 'ST',
                                        hintText: 'State',
                                        hintStyle: TextStyle(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade400
                                              : colorScheme.onSurfaceVariant
                                                  .withOpacity(0.6),
                                        ),
                                        labelStyle: TextStyle(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurface,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[
                                                    500]! // Subtle gray for dark mode
                                                : colorScheme.outline.withOpacity(
                                                    0.5), // Theme-aware for light mode
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: theme.brightness ==
                                                    Brightness.dark
                                                ? colorScheme
                                                    .primary // Yellow for dark mode
                                                : Colors
                                                    .black, // Black for light mode
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: theme.brightness ==
                                                Brightness.dark
                                            ? Colors.grey[
                                                700] // Dark fill for dark mode
                                            : colorScheme
                                                .surface, // Theme-aware fill for light mode
                                      ),
                                      style: TextStyle(
                                        color: theme.brightness ==
                                                Brightness.dark
                                            ? Colors
                                                .white // White text for dark mode
                                            : colorScheme
                                                .onSurface, // Theme-aware text for light mode
                                      ),
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      textInputAction: TextInputAction.next,
                                      validator: _validateState,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _zipController,
                                    decoration: InputDecoration(
                                      labelText: 'ZIP',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[
                                                  500]! // Subtle gray for dark mode
                                              : colorScheme.outline.withOpacity(
                                                  0.5), // Theme-aware for light mode
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? colorScheme
                                                  .primary // Yellow for dark mode
                                              : Colors
                                                  .black, // Black for light mode
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: theme.brightness ==
                                              Brightness.dark
                                          ? Colors.grey[
                                              700] // Dark fill for dark mode
                                          : colorScheme
                                              .surface, // Theme-aware fill for light mode
                                    ),
                                    style: TextStyle(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors
                                              .white // White text for dark mode
                                          : colorScheme
                                              .onSurface, // Theme-aware text for light mode
                                    ),
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateZip,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Preferences Section
                            Text(
                              'Preferences',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.primary // Yellow in dark mode
                                    : colorScheme
                                        .onBackground, // Dark in light mode
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Max Travel Subheading
                            Text(
                              'Max Travel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.primary // Yellow in dark mode
                                    : colorScheme
                                        .onBackground, // Dark in light mode
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Max Travel Distance Field
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                controller: _maxDistanceController,
                                decoration: InputDecoration(
                                  labelText: 'Max Distance (miles)',
                                  prefixIcon: Icon(
                                    Icons.directions_car,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[
                                            400] // Light gray for dark mode
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
                                          : Colors
                                              .black, // Black for light mode
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
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                validator: _validateMaxDistance,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Minimum Pay Subheading
                            Text(
                              'Minimum Pay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.primary // Yellow in dark mode
                                    : colorScheme
                                        .onBackground, // Dark in light mode
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Minimum Pay Input
                            SizedBox(
                              width: 250,
                              child: TextFormField(
                                initialValue: _selectedMinRate != null &&
                                        _selectedMinRate != 'Not specified'
                                    ? _selectedMinRate!.replaceAll('\$', '')
                                    : '',
                                decoration: InputDecoration(
                                  labelText: 'Minimum Pay (\$)',
                                  hintText: 'Enter amount',
                                  prefixText: '\$',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: theme.brightness == Brightness.dark
                                          ? colorScheme
                                              .primary // Yellow for dark mode
                                          : Colors
                                              .black, // Black for light mode
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: theme.brightness == Brightness.dark
                                      ? Colors.grey[700]
                                      : colorScheme.surface,
                                ),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMinRate =
                                        value.isNotEmpty ? '\$${value}' : null;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Notifications Subheading
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.primary // Yellow in dark mode
                                    : colorScheme
                                        .onBackground, // Dark in light mode
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Email Notifications
                            CheckboxListTile(
                              title: Text(
                                'Email Notifications',
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white // White text for dark mode
                                      : colorScheme
                                          .onSurface, // Theme-aware text for light mode
                                ),
                              ),
                              value: _emailNotifications,
                              onChanged: (value) => setState(
                                  () => _emailNotifications = value ?? true),
                              activeColor: theme.brightness == Brightness.dark
                                  ? colorScheme.primary // Yellow in dark mode
                                  : Colors.black, // Black in light mode
                              checkColor: theme.brightness == Brightness.dark
                                  ? Colors
                                      .black // Black checkmark on yellow background
                                  : Colors
                                      .white, // White checkmark on black background
                              tileColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),

                            // SMS Notifications
                            CheckboxListTile(
                              title: Text(
                                'SMS Notifications',
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white // White text for dark mode
                                      : colorScheme
                                          .onSurface, // Theme-aware text for light mode
                                ),
                              ),
                              value: _smsNotifications,
                              onChanged: (value) => setState(
                                  () => _smsNotifications = value ?? false),
                              activeColor: theme.brightness == Brightness.dark
                                  ? colorScheme.primary // Yellow in dark mode
                                  : Colors.black, // Black in light mode
                              checkColor: theme.brightness == Brightness.dark
                                  ? Colors
                                      .black // Black checkmark on yellow background
                                  : Colors
                                      .white, // White checkmark on black background
                              tileColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),

                            // App Notifications
                            CheckboxListTile(
                              title: Text(
                                'App Notifications',
                                style: TextStyle(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white // White text for dark mode
                                      : colorScheme
                                          .onSurface, // Theme-aware text for light mode
                                ),
                              ),
                              value: _appNotifications,
                              onChanged: (value) => setState(
                                  () => _appNotifications = value ?? true),
                              activeColor: theme.brightness == Brightness.dark
                                  ? colorScheme.primary // Yellow in dark mode
                                  : Colors.black, // Black in light mode
                              checkColor: theme.brightness == Brightness.dark
                                  ? Colors
                                      .black // Black checkmark on yellow background
                                  : Colors
                                      .white, // White checkmark on black background
                              tileColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Continue Button
                    Center(
                      child: SizedBox(
                        width: 300,
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
