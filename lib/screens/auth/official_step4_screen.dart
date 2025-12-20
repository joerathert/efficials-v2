import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class OfficialStep4Screen extends StatefulWidget {
  const OfficialStep4Screen({super.key});

  @override
  State<OfficialStep4Screen> createState() => _OfficialStep4ScreenState();
}

class _OfficialStep4ScreenState extends State<OfficialStep4Screen> {
  late Map<String, dynamic> previousData;
  bool _isCompletingRegistration = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previousData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  }

  void _handleAddAnotherSport() {
    _showAddSportDialog();
  }

  void _showAddSportDialog() {
    final availableSports = [
      'Baseball',
      'Basketball',
      'Football',
      'Soccer',
      'Softball',
      'Volleyball'
    ];

    final selectedSports =
        previousData['selectedSports'] as Map<String, Map<String, dynamic>>;
    final availableToAdd = availableSports
        .where((sport) => !selectedSports.containsKey(sport))
        .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You have already added all available sports')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Select a Sport',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableToAdd.length,
              itemBuilder: (context, index) {
                final sport = availableToAdd[index];
                return ListTile(
                  title: Text(
                    sport,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addSportToData(sport);
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSportToData(String sport) {
    final selectedSports =
        previousData['selectedSports'] as Map<String, Map<String, dynamic>>;

    if (!selectedSports.containsKey(sport)) {
      selectedSports[sport] = {
        'certification': null,
        'experience':
            null, // Changed from 0 to null for proper empty field handling
        'competitionLevels': <String>[],
      };

      // Navigate to step 3 to configure the new sport
      Navigator.pushNamed(
        context,
        '/official-step3',
        arguments: previousData,
      );
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
          onPressed:
              _isCompletingRegistration ? null : () => Navigator.pop(context),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Title - Profile & Verification
                  Center(
                    child: Text(
                      'Profile & Verification',
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

                  // Subtitle - Step 4 of 4: Complete Your Profile
                  Center(
                    child: Text(
                      'Step 4 of 4: Complete Your Profile',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form Fields Container
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, top: 24, bottom: 4),
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Registration Summary
                            _buildRegistrationSummary(),
                            const SizedBox(height: 32),

                            // Account Verification Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.surfaceVariant
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.brightness == Brightness.dark
                                      ? colorScheme.primary.withOpacity(0.3)
                                      : colorScheme.outline,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? colorScheme.primary
                                                : colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Account Verification',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? colorScheme.primary
                                              : colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '• Your email will need to be verified\n'
                                    '• Your profile will be reviewed by administrators\n'
                                    '• You\'ll receive notification when approved\n'
                                    '• You can then start receiving game assignments',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Add Another Sport Button
                            SizedBox(
                              width: 300,
                              child: OutlinedButton(
                                onPressed: _handleAddAnotherSport,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme.primary
                                        : Colors.black,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Add Another Sport',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: theme.brightness == Brightness.dark
                                        ? colorScheme.primary
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Complete Registration Button
                            SizedBox(
                              width: 300,
                              child: ElevatedButton(
                                onPressed: _isCompletingRegistration
                                    ? null
                                    : _handleCompleteReal,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isCompletingRegistration
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Creating Account...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Complete Registration',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationSummary() {
    final selectedSports =
        previousData['selectedSports'] as Map<String, Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registration Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Name:',
              '${previousData['firstName']} ${previousData['lastName']}'),
          _buildSummaryRow('Email:', previousData['email']),
          if (previousData['phone']?.isNotEmpty == true)
            _buildSummaryRow(
                'Phone:', _formatPhoneNumber(previousData['phone'])),
          _buildSummaryRow(
              'Location:', '${previousData['city']}, ${previousData['state']}'),
          _buildSummaryRow(
              'Max Travel:', '${previousData['maxTravelDistance']} miles'),
          if (previousData['minRatePerGame'] != null)
            _buildSummaryRow('Min Rate:', previousData['minRatePerGame']),
          // Display detailed sports information
          ...selectedSports.entries.map((entry) {
            final sportName = entry.key;
            final sportData = entry.value;
            final experience = sportData['experience'] ?? 0;
            final certification =
                sportData['certification'] ?? 'No Certification';
            final competitionLevels =
                (sportData['competitionLevels'] as List<dynamic>?)
                        ?.join(', ') ??
                    'None';
            return _buildSummaryRow('$sportName:',
                'Exp: ${experience}yrs, Cert: $certification, Levels: $competitionLevels');
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCompleteReal() async {
    setState(() {
      _isCompletingRegistration = true;
    });

    try {
      final authService = AuthService();

      // Calculate total experience years and highest certification from all sports
      final selectedSports =
          previousData['selectedSports'] as Map<String, Map<String, dynamic>>;
      int maxExperience = 0;
      String? highestCertification;

      // Convert selectedSports data to match the expected format for the profile
      final sportsData = <String, Map<String, dynamic>>{};
      for (final entry in selectedSports.entries) {
        final sportName = entry.key;
        final sportData = entry.value;
        sportsData[sportName] = {
          'certificationLevel':
              sportData['certification'] ?? 'No Certification',
          'yearsExperience': sportData['experience'] ?? 0,
          'competitionLevels': sportData['competitionLevels'] ?? [],
        };
      }

      for (final sportData in selectedSports.values) {
        final experience = sportData['experience'] as int? ?? 0;
        if (experience > maxExperience) {
          maxExperience = experience;
        }

        final certification = sportData['certification'] as String?;
        if (certification != null && certification != 'No Certification') {
          // Determine highest certification level
          if (highestCertification == null ||
              _getCertificationPriority(certification) >
                  _getCertificationPriority(highestCertification)) {
            highestCertification = certification;
          }
        }
      }

      // Parse work preferences
      double? ratePerGame;
      if (previousData['minRatePerGame'] != null) {
        final rateString =
            previousData['minRatePerGame'].toString().replaceAll('\$', '');
        ratePerGame = double.tryParse(rateString);
      }
      // Handle maxTravelDistance which might come as int or double
      int? maxTravelDistance;
      if (previousData['maxTravelDistance'] != null) {
        final travelValue = previousData['maxTravelDistance'];
        if (travelValue is int) {
          maxTravelDistance = travelValue;
        } else if (travelValue is double) {
          maxTravelDistance = travelValue.toInt();
        } else if (travelValue is String) {
          maxTravelDistance = int.tryParse(travelValue);
        }
      }

      // Create official profile
      final officialProfile = OfficialProfile(
        address: previousData['address'],
        city: previousData['city'],
        state: previousData['state'],
        experienceYears: maxExperience > 0 ? maxExperience : null,
        certificationLevel: highestCertification,
        availabilityStatus: 'available',
        followThroughRate: 100.0,
        totalAcceptedGames: 0,
        totalBackedOutGames: 0,
        bio: null, // Bio field should be for actual biographical information
        sportsData:
            sportsData, // Save detailed sports data with experience, certification, and competition levels
        ratePerGame: ratePerGame,
        maxTravelDistance: maxTravelDistance,
      );

      // Create profile data
      final profile = ProfileData(
        firstName: previousData['firstName'],
        lastName: previousData['lastName'],
        phone: previousData['phone'],
      );

      // Create user account with Firebase Auth and Firestore
      final result = await authService.signUpWithEmailAndPassword(
        email: previousData['email'],
        password: previousData['password'],
        profile: profile,
        role: 'official',
        officialProfile: officialProfile,
      );

      if (mounted) {
        setState(() {
          _isCompletingRegistration = false;
        });

        if (result.success && result.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Efficials!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to official home screen (user is now automatically signed in)
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/official-home',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to create account'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompletingRegistration = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating account: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digits
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Format as (###) ###-####
    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }

    // Return original if not 10 digits
    return phone;
  }

  int _getCertificationPriority(String certification) {
    switch (certification) {
      case 'IHSA Registered':
        return 3;
      case 'IHSA Recognized':
        return 2;
      case 'IHSA Certified':
        return 1;
      default:
        return 0;
    }
  }
}
