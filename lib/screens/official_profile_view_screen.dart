import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../services/endorsement_service.dart';
import '../models/user_model.dart';

class OfficialProfileViewScreen extends StatefulWidget {
  const OfficialProfileViewScreen({super.key});

  @override
  State<OfficialProfileViewScreen> createState() =>
      _OfficialProfileViewScreenState();
}

class _OfficialProfileViewScreenState extends State<OfficialProfileViewScreen> {
  final UserService _userService = UserService();
  final EndorsementService _endorsementService = EndorsementService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isVerificationExpanded = false;
  bool _showCareerStats = true;
  double _ratePerGame = 0.0;
  int _maxTravelDistance = 999;
  int _schedulerEndorsements = 0;
  int _officialEndorsements = 0;

  // Notification settings
  final Map<String, bool> _notificationSettings = {
    'emailNotifications': true,
    'smsNotifications': false,
    'appNotifications': true,
    'weeklyDigest': true,
    'marketingEmails': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _currentUser = await _userService.getCurrentUser();

      // Load endorsement counts
      if (_currentUser != null) {
        final counts =
            await _endorsementService.getEndorsementCounts(_currentUser!.id);
        _schedulerEndorsements = counts['schedulerEndorsements'] ?? 0;
        _officialEndorsements = counts['officialEndorsements'] ?? 0;
      }

      // Load notification settings from Firestore
      await _loadNotificationSettings();
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // Load notification settings
        final settings = data['notificationSettings'] as Map<String, dynamic>?;
        if (settings != null) {
          setState(() {
            _notificationSettings.clear();
            settings.forEach((key, value) {
              if (value is bool) {
                _notificationSettings[key] = value;
              }
            });
          });
        }
        
        // Load officialProfile settings
        final officialProfile = data['officialProfile'] as Map<String, dynamic>?;
        if (officialProfile != null) {
          setState(() {
            _showCareerStats = officialProfile['showCareerStats'] ?? true;
            _ratePerGame = (officialProfile['ratePerGame'] ?? 0.0).toDouble();
            _maxTravelDistance = (officialProfile['maxTravelDistance'] ?? 999).toInt();
          });
        }
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'notificationSettings': _notificationSettings,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving notification settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save notification settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    final initials =
        parts.where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase()).join();
    return initials.isNotEmpty ? initials : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: colorScheme.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(colorScheme),
                const SizedBox(height: 24),

                // Verification Status
                _buildVerificationStatus(colorScheme),
                const SizedBox(height: 24),

                // Career Statistics
                _buildStatsSection(colorScheme),
                const SizedBox(height: 24),

                // Career Stats Toggle
                _buildCareerStatsToggle(colorScheme),
                const SizedBox(height: 24),

                // Sports & Certifications
                _buildSportsSection(colorScheme),
                const SizedBox(height: 24),

                // Contact & Location
                _buildContactSection(colorScheme),
                const SizedBox(height: 24),

                // Work Preferences
                _buildPreferencesSection(colorScheme),
                const SizedBox(height: 24),

                // Notification Settings
                _buildNotificationSettings(colorScheme),
                const SizedBox(height: 24),

                // Account Actions
                _buildAccountActions(colorScheme),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    final officialProfile = _currentUser?.officialProfile;
    final fullName = _currentUser?.fullName ?? 'Unknown Official';
    final experienceYears = officialProfile?.experienceYears ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, Colors.orange],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(fullName),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: IconButton(
                    onPressed: _showEditProfilePhotoDialog,
                    icon: const Icon(Icons.edit, size: 14, color: Colors.black),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Name and Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showEditNameDialog,
                      icon: Icon(Icons.edit, size: 18, color: colorScheme.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$experienceYears years experience',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser?.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                // Endorsements section
                _buildEndorsementsSection(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndorsementsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Endorsements',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showEndorsersDialog('scheduler', colorScheme),
          child: Row(
            children: [
              Icon(Icons.thumb_up, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Schedulers: $_schedulerEndorsements',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () => _showEndorsersDialog('official', colorScheme),
          child: Row(
            children: [
              Icon(Icons.thumb_up, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Officials: $_officialEndorsements',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEndorsersDialog(String endorserType, ColorScheme colorScheme) {
    if (_currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          '${endorserType == 'scheduler' ? 'Scheduler' : 'Official'} Endorsements',
          style: TextStyle(color: colorScheme.primary),
        ),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: _endorsementService.getEndorsersForOfficial(
            _currentUser!.id,
            endorserType: endorserType,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No ${endorserType} endorsements found',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }

            final endorsers = snapshot.data!;
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: endorsers.length,
                itemBuilder: (context, index) {
                  final endorser = endorsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        _getInitials(endorser['name']),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    title: Text(
                      endorser['name'] ?? 'Unknown User',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(ColorScheme colorScheme) {
    // In v2.0, verification status is stored in Firestore user document
    // For now, we'll use placeholder values - this can be extended when needed
    final profileVerified = false;
    final emailVerified = _currentUser?.email.isNotEmpty ?? false;
    final phoneVerified = _currentUser?.profile.phone.isNotEmpty ?? false;
    final allVerified = profileVerified && emailVerified && phoneVerified;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isVerificationExpanded = !_isVerificationExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Verification Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      allVerified ? Icons.check_circle : Icons.cancel,
                      color: allVerified ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ],
                ),
                Icon(
                  _isVerificationExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
          if (_isVerificationExpanded) ...[
            const SizedBox(height: 12),
            _buildVerificationItem(
              'Profile Verified',
              profileVerified,
              'Your profile has been verified by administrators',
              colorScheme,
            ),
            _buildVerificationItem(
              'Email Verified',
              emailVerified,
              'Your email address has been confirmed',
              colorScheme,
            ),
            _buildVerificationItem(
              'Phone Verified',
              phoneVerified,
              'Your phone number has been confirmed',
              colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationItem(
    String title,
    bool isVerified,
    String description,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.cancel,
            color: isVerified ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified)
            TextButton(
              onPressed: () => _handleVerificationRequest(title),
              child: Text(
                'Verify',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ColorScheme colorScheme) {
    final officialProfile = _currentUser?.officialProfile;
    final totalGames = officialProfile?.totalAcceptedGames ?? 0;
    final experienceYears = officialProfile?.experienceYears ?? 0;
    final followThroughRate = officialProfile?.followThroughRate ?? 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Career Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Games',
                  '$totalGames',
                  colorScheme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Experience',
                  '$experienceYears years',
                  colorScheme,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showFollowThroughDetails(colorScheme),
                  child: _buildStatItem(
                    'Follow-Through',
                    '${followThroughRate.toStringAsFixed(1)}%',
                    colorScheme,
                    isHighlighted: true,
                    showInfoIcon: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isHighlighted = false,
    bool showInfoIcon = false,
  }) {
    return Container(
      decoration: isHighlighted
          ? BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            )
          : null,
      padding: isHighlighted ? const EdgeInsets.all(8) : null,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              if (showInfoIcon) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted
                  ? colorScheme.primary.withOpacity(0.8)
                  : colorScheme.onSurfaceVariant,
              fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          if (showInfoIcon)
            Text(
              'Tap for details',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.primary.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Future<void> _showFollowThroughDetails(ColorScheme colorScheme) async {
    final officialProfile = _currentUser?.officialProfile;
    final totalAcceptedGames = officialProfile?.totalAcceptedGames ?? 0;
    final totalBackedOutGames = officialProfile?.totalBackedOutGames ?? 0;
    final followThroughRate = officialProfile?.followThroughRate ?? 100.0;
    final completedGames = totalAcceptedGames - totalBackedOutGames;

    // Show loading indicator while fetching data
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FollowThroughDetailsSheet(
        userId: _currentUser?.id ?? '',
        totalAcceptedGames: totalAcceptedGames,
        totalBackedOutGames: totalBackedOutGames,
        completedGames: completedGames,
        followThroughRate: followThroughRate,
        colorScheme: colorScheme,
      ),
    );
  }

  Widget _buildCareerStatsToggle(ColorScheme colorScheme) {
    // showCareerStats is stored in Firestore, default to true
    final showCareerStats = _showCareerStats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          'Show Career Statistics',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Allow schedulers to see your career statistics',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        value: showCareerStats,
        onChanged: (value) => _saveCareerStatsSetting(value),
        activeColor: colorScheme.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSportsSection(ColorScheme colorScheme) {
    final officialProfile = _currentUser?.officialProfile;
    final sportsData = officialProfile?.sportsData ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sports & Certifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to edit sports screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit sports coming soon'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: Text(
                  'Edit',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sportsData.isEmpty)
            Text(
              'No sports added yet',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...sportsData.entries.map((entry) => _buildSportItem(
                  entry.key,
                  entry.value,
                  colorScheme,
                )),
        ],
      ),
    );
  }

  Widget _buildSportItem(
    String sportName,
    Map<String, dynamic> sportData,
    ColorScheme colorScheme,
  ) {
    final certificationLevel = sportData['certificationLevel'] as String? ?? 'No certification';
    final yearsExperience = sportData['yearsExperience'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sportName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  certificationLevel,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$yearsExperience years',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ColorScheme colorScheme) {
    final officialProfile = _currentUser?.officialProfile;
    final city = officialProfile?.city ?? '';
    final state = officialProfile?.state ?? '';
    final location = city.isNotEmpty && state.isNotEmpty
        ? '$city, $state'
        : (city.isNotEmpty ? city : (state.isNotEmpty ? state : 'Not provided'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact & Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to edit contact screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit contact coming soon'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: Text(
                  'Edit',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.email,
            'Email',
            _currentUser?.email ?? 'Not provided',
            colorScheme,
          ),
          _buildContactItem(
            Icons.phone,
            'Phone',
            _currentUser?.profile.phone ?? 'Not provided',
            colorScheme,
          ),
          _buildContactItem(
            Icons.location_on,
            'Location',
            location,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(ColorScheme colorScheme) {
    // These values are stored in Firestore but not in the model
    // Use defaults for now - they can be loaded from Firestore in a future update

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Work Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              IconButton(
                onPressed: _showEditWorkPreferencesDialog,
                icon: Icon(Icons.edit, color: colorScheme.primary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreferenceItem(
            'Rate per Game',
            '\$${_ratePerGame.toStringAsFixed(0)}',
            colorScheme,
          ),
          _buildPreferenceItem(
            'Max Travel Distance',
            '$_maxTravelDistance miles',
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              'Email Notifications',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Game assignments and updates',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: _notificationSettings['emailNotifications'] ?? true,
            onChanged: (value) async {
              setState(() {
                _notificationSettings['emailNotifications'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text(
              'SMS Notifications',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Text messages for urgent updates',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: _notificationSettings['smsNotifications'] ?? false,
            onChanged: (value) async {
              setState(() {
                _notificationSettings['smsNotifications'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text(
              'App Notifications',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Push notifications in the app',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: _notificationSettings['appNotifications'] ?? true,
            onChanged: (value) async {
              setState(() {
                _notificationSettings['appNotifications'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text(
              'Weekly Digest',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Weekly summary of your activity',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: _notificationSettings['weeklyDigest'] ?? true,
            onChanged: (value) async {
              setState(() {
                _notificationSettings['weeklyDigest'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: Text(
              'Marketing Emails',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Updates about new features and news',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: _notificationSettings['marketingEmails'] ?? false,
            onChanged: (value) async {
              setState(() {
                _notificationSettings['marketingEmails'] = value;
              });
              await _saveNotificationSettings();
            },
            activeColor: colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(ColorScheme colorScheme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Show help/support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Help & Support'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _showLogoutDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }

  // Dialog methods
  void _showEditProfilePhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Profile Photo',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: const Text(
          'Photo upload functionality will be implemented in a future update. For now, your profile displays your initials.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _currentUser?.fullName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Name',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name cannot be empty'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _updateProfileName(newName);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileName(String newName) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Split name into first and last
      final nameParts = newName.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profile.firstName': firstName,
        'profile.lastName': lastName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile name updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile name'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditWorkPreferencesDialog() {
    final rateController = TextEditingController(
      text: _ratePerGame.toStringAsFixed(0),
    );
    final distanceController = TextEditingController(
      text: _maxTravelDistance.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Work Preferences',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Rate per Game (\$)',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: distanceController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Max Travel Distance (miles)',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(rateController.text);
              final distance = int.tryParse(distanceController.text);

              if (rate == null || rate < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid rate amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (distance == null || distance < 0 || distance > 999) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Distance must be between 0 and 999 miles'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _updateWorkPreferences(rate, distance);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWorkPreferences(double rate, int distance) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'officialProfile.ratePerGame': rate,
        'officialProfile.maxTravelDistance': distance,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _ratePerGame = rate;
        _maxTravelDistance = distance;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work preferences updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating work preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update work preferences'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCareerStatsSetting(bool value) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'officialProfile.showCareerStats': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        _showCareerStats = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Career stats preference saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving career stats setting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save preference'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleVerificationRequest(String verificationType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Verification',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: Text(
          'Verification for "$verificationType" will be available in a future update.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Sign Out',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

/// Widget to show Follow-Through calculation details
class _FollowThroughDetailsSheet extends StatefulWidget {
  final String userId;
  final int totalAcceptedGames;
  final int totalBackedOutGames;
  final int completedGames;
  final double followThroughRate;
  final ColorScheme colorScheme;

  const _FollowThroughDetailsSheet({
    required this.userId,
    required this.totalAcceptedGames,
    required this.totalBackedOutGames,
    required this.completedGames,
    required this.followThroughRate,
    required this.colorScheme,
  });

  @override
  State<_FollowThroughDetailsSheet> createState() =>
      _FollowThroughDetailsSheetState();
}

class _FollowThroughDetailsSheetState extends State<_FollowThroughDetailsSheet> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _confirmedGames = [];
  final List<Map<String, dynamic>> _backedOutGames = [];
  final List<Map<String, dynamic>> _forgivenGames = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    try {
      // Load confirmed games from user's confirmedGameIds
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final confirmedGameIds =
            List<String>.from(userData?['confirmedGameIds'] ?? []);

        // Fetch game details for confirmed games
        for (String gameId in confirmedGameIds) {
          final gameDoc = await FirebaseFirestore.instance
              .collection('games')
              .doc(gameId)
              .get();
          if (gameDoc.exists) {
            _confirmedGames.add({
              'id': gameDoc.id,
              ...gameDoc.data()!,
            });
          }
        }
      }

      // Load backed out games from back_outs collection
      final backoutsQuery = await FirebaseFirestore.instance
          .collection('back_outs')
          .where('officialId', isEqualTo: widget.userId)
          .get();

      for (var doc in backoutsQuery.docs) {
        final data = doc.data();
        if (data['excused'] == true) {
          _forgivenGames.add({
            'id': doc.id,
            ...data,
          });
        } else {
          _backedOutGames.add({
            'id': doc.id,
            ...data,
          });
        }
      }

      // Sort games by date (most recent first)
      _confirmedGames.sort((a, b) {
        final aDate = _parseDate(a['date']);
        final bDate = _parseDate(b['date']);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      _backedOutGames.sort((a, b) {
        final aDate = _parseDate(a['gameDate']);
        final bDate = _parseDate(b['gameDate']);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      _forgivenGames.sort((a, b) {
        final aDate = _parseDate(a['excusedAt'] ?? a['gameDate']);
        final bDate = _parseDate(b['excusedAt'] ?? b['gameDate']);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading game details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is Timestamp) return date.toDate();
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String _formatDate(dynamic date) {
    final parsed = _parseDate(date);
    if (parsed == null) return 'Date TBD';
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Follow-Through Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Rate display
                    _buildRateDisplay(colorScheme),
                    const SizedBox(height: 16),
                    // Calculation explanation
                    _buildCalculationExplanation(colorScheme),
                  ],
                ),
              ),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab(0, 'Completed', _confirmedGames.length, colorScheme),
                    _buildTab(1, 'Backed Out', _backedOutGames.length, colorScheme),
                    _buildTab(2, 'Forgiven', _forgivenGames.length, colorScheme),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Game list
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : _buildGameList(scrollController, colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRateDisplay(ColorScheme colorScheme) {
    final rate = widget.followThroughRate;
    Color rateColor;
    if (rate >= 90) {
      rateColor = Colors.green;
    } else if (rate >= 70) {
      rateColor = Colors.orange;
    } else {
      rateColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rateColor.withOpacity(0.1),
            rateColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rateColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: rateColor,
                ),
              ),
              Text(
                'Follow-Through Rate',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Container(
            height: 60,
            width: 1,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          Column(
            children: [
              _buildStatMini('Completed', widget.completedGames, Colors.green, colorScheme),
              const SizedBox(height: 8),
              _buildStatMini('Backed Out', widget.totalBackedOutGames, Colors.red, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(String label, int value, Color color, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationExplanation(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'How is this calculated?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Follow-Through Rate = (Games Completed ÷ Total Games Accepted) × 100',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.completedGames} ÷ ${widget.totalAcceptedGames} × 100 = ${widget.followThroughRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          if (_forgivenGames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Note: Forgiven games are excluded from this calculation entirely.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count, ColorScheme colorScheme) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameList(ScrollController scrollController, ColorScheme colorScheme) {
    List<Map<String, dynamic>> currentList;
    String emptyMessage;
    IconData emptyIcon;

    switch (_selectedTabIndex) {
      case 0:
        currentList = _confirmedGames;
        emptyMessage = 'No completed games yet';
        emptyIcon = Icons.sports;
        break;
      case 1:
        currentList = _backedOutGames;
        emptyMessage = 'No backed out games - great job!';
        emptyIcon = Icons.check_circle_outline;
        break;
      case 2:
        currentList = _forgivenGames;
        emptyMessage = 'No forgiven games';
        emptyIcon = Icons.favorite_border;
        break;
      default:
        currentList = [];
        emptyMessage = 'No games';
        emptyIcon = Icons.sports;
    }

    if (currentList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        final game = currentList[index];
        return _buildGameCard(game, colorScheme);
      },
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, ColorScheme colorScheme) {
    // Determine if this is a backout or confirmed game based on available fields
    final isBackout = game.containsKey('gameSport');

    String sport, opponent, date, time, location;
    String? reason, excuseReason;

    if (isBackout) {
      // Backout record
      sport = game['gameSport'] ?? 'Unknown Sport';
      opponent = game['gameOpponent'] ?? 'Unknown Opponent';
      date = _formatDate(game['gameDate']);
      time = game['gameTime'] ?? 'Time TBD';
      location = '';
      reason = game['reason'];
      excuseReason = game['excuseReason'];
    } else {
      // Confirmed game
      sport = game['sport'] ?? 'Unknown Sport';
      opponent = game['opponent'] ?? 'Unknown Opponent';
      date = _formatDate(game['date']);
      time = game['time'] ?? 'Time TBD';
      location = game['location'] ?? '';
    }

    Color borderColor;
    IconData statusIcon;

    switch (_selectedTabIndex) {
      case 0:
        borderColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 1:
        borderColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 2:
        borderColor = Colors.blue;
        statusIcon = Icons.favorite;
        break;
      default:
        borderColor = Colors.grey;
        statusIcon = Icons.sports;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 18, color: borderColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sport,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.groups, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'vs $opponent',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: $reason',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (excuseReason != null && excuseReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Forgiven: $excuseReason',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

