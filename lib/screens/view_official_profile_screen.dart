import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_service.dart';
import '../services/endorsement_service.dart';
import '../models/user_model.dart';

/// Screen for viewing another official's profile
/// Displays profile info, stats, and endorsement functionality
class ViewOfficialProfileScreen extends StatefulWidget {
  const ViewOfficialProfileScreen({super.key});

  @override
  State<ViewOfficialProfileScreen> createState() =>
      _ViewOfficialProfileScreenState();
}

class _ViewOfficialProfileScreenState extends State<ViewOfficialProfileScreen> {
  final UserService _userService = UserService();
  final EndorsementService _endorsementService = EndorsementService();

  UserModel? _official;
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _hasEndorsedThisOfficial = false;
  bool _isProcessingEndorsement = false;
  int _schedulerEndorsements = 0;
  int _officialEndorsements = 0;

  String? _officialId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the official ID from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _officialId = args['officialId'] as String?;
    } else if (args is String) {
      _officialId = args;
    }

    if (_officialId != null) {
      _loadData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load the official's profile
      _official = await _userService.getUserById(_officialId!);

      // Load current user to determine their role
      _currentUser = await _userService.getCurrentUser();

      // Get endorsement counts
      final counts =
          await _endorsementService.getEndorsementCounts(_officialId!);
      _schedulerEndorsements = counts['schedulerEndorsements'] ?? 0;
      _officialEndorsements = counts['officialEndorsements'] ?? 0;

      // Check if current user has endorsed this official
      _hasEndorsedThisOfficial =
          await _endorsementService.hasUserEndorsedOfficial(_officialId!);
    } catch (e) {
      print('Error loading official profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  bool get _isCurrentUserScheduler => _currentUser?.role == 'scheduler';

  bool get _isViewingOwnProfile {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == _officialId;
  }

  bool get _shouldShowCareerStats {
    // Always show if viewing own profile or if official allows it
    return _isViewingOwnProfile ||
        (_official?.officialProfile?.showCareerStats ?? true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (_official == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Official not found',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Official Profile',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                // Profile Header with endorsement
                _buildProfileHeader(colorScheme),
                const SizedBox(height: 24),

                // Career Statistics (if allowed)
                if (_shouldShowCareerStats) ...[
                  _buildStatsSection(colorScheme),
                  const SizedBox(height: 24),
                ],

                // Sports & Certifications
                _buildSportsSection(colorScheme),
                const SizedBox(height: 24),

                // Contact & Location
                _buildContactSection(colorScheme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    final officialProfile = _official?.officialProfile;
    final fullName = _official?.fullName ?? 'Unknown Official';
    final experienceYears = officialProfile?.experienceYears ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
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
              const SizedBox(width: 16),
              // Name and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$experienceYears years experience',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Endorsements section
                    _buildEndorsementsSection(colorScheme),
                  ],
                ),
              ),
              // Endorse button (only if not viewing own profile)
              if (!_isViewingOwnProfile) _buildEndorseButton(colorScheme),
            ],
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

  Widget _buildEndorseButton(ColorScheme colorScheme) {
    return IconButton(
      onPressed: _isProcessingEndorsement
          ? null
          : () {
              if (_hasEndorsedThisOfficial) {
                _showRemoveEndorsementDialog(colorScheme);
              } else {
                _showEndorsementDialog(colorScheme);
              }
            },
      icon: Icon(
        _hasEndorsedThisOfficial ? Icons.thumb_up : Icons.thumb_up_outlined,
        color: _hasEndorsedThisOfficial
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      tooltip:
          _hasEndorsedThisOfficial ? 'Remove endorsement' : 'Endorse this official',
    );
  }

  void _showEndorsementDialog(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Center(
          child: Text(
            'Endorse Official',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
        content: Text(
          'Do you want to endorse ${_official?.fullName ?? 'this official'}? This will add to their endorsement count.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleEndorsement(isRemoving: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: const Text(
              'Endorse',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveEndorsementDialog(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Center(
          child: Text(
            'Remove Endorsement',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
        content: Text(
          'Do you want to remove your endorsement of ${_official?.fullName ?? 'this official'}? This will decrease their endorsement count.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleEndorsement(isRemoving: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEndorsement({required bool isRemoving}) async {
    if (_officialId == null || _isProcessingEndorsement) return;

    setState(() {
      _isProcessingEndorsement = true;
    });

    try {
      if (isRemoving) {
        await _endorsementService.removeEndorsement(
          endorsedOfficialId: _officialId!,
        );
      } else {
        final endorserType = _isCurrentUserScheduler ? 'scheduler' : 'official';
        await _endorsementService.addEndorsement(
          endorsedOfficialId: _officialId!,
          endorserType: endorserType,
        );
      }

      // Update UI
      setState(() {
        _hasEndorsedThisOfficial = !isRemoving;
        if (_isCurrentUserScheduler) {
          _schedulerEndorsements += isRemoving ? -1 : 1;
        } else {
          _officialEndorsements += isRemoving ? -1 : 1;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRemoving
                  ? 'Endorsement removed successfully'
                  : 'Endorsement added successfully',
            ),
            backgroundColor: isRemoving ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error handling endorsement: $e');

      String errorMessage;
      if (e.toString().contains('already endorsed')) {
        errorMessage = 'You have already endorsed this official.';
      } else if (e.toString().contains('cannot endorse yourself')) {
        errorMessage = 'You cannot endorse yourself.';
      } else {
        errorMessage =
            'Failed to ${isRemoving ? 'remove' : 'add'} endorsement. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingEndorsement = false;
        });
      }
    }
  }

  void _showEndorsersDialog(String endorserType, ColorScheme colorScheme) {
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
            _officialId!,
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

  Widget _buildStatsSection(ColorScheme colorScheme) {
    final officialProfile = _official?.officialProfile;
    final totalGames = officialProfile?.totalAcceptedGames ?? 0;
    final experienceYears = officialProfile?.experienceYears ?? 0;
    final followThroughRate = officialProfile?.followThroughRate ?? 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
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
                child: _buildStatItem(
                  'Follow-Through',
                  '${followThroughRate.toStringAsFixed(1)}%',
                  colorScheme,
                  isHighlighted: _isCurrentUserScheduler,
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
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
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
        ],
      ),
    );
  }

  Widget _buildSportsSection(ColorScheme colorScheme) {
    final officialProfile = _official?.officialProfile;
    final sportsData = officialProfile?.sportsData ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sports & Certifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (sportsData.isEmpty)
            Text(
              'No sports listed',
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
    final certificationLevel =
        sportData['certificationLevel'] ?? sportData['certification'] ?? 'N/A';
    final yearsExperience =
        sportData['yearsExperience'] ?? sportData['experience'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                  certificationLevel.toString(),
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
    final officialProfile = _official?.officialProfile;
    final city = officialProfile?.city ?? '';
    final state = officialProfile?.state ?? '';
    final location = city.isNotEmpty && state.isNotEmpty
        ? '$city, $state'
        : (city.isNotEmpty
            ? city
            : (state.isNotEmpty ? state : 'Not provided'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact & Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.email,
            'Email',
            _official?.email ?? 'Not provided',
            colorScheme,
            isClickable: true,
          ),
          _buildContactItem(
            Icons.phone,
            'Phone',
            _official?.profile.phone ?? 'Not provided',
            colorScheme,
            isClickable: true,
          ),
          _buildContactItem(
            Icons.location_on,
            'Location',
            location,
            colorScheme,
            isClickable: false,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isClickable = false,
  }) {
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
                GestureDetector(
                  onTap: isClickable && value != 'Not provided'
                      ? () => _handleContactTap(label, value)
                      : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isClickable && value != 'Not provided'
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      decoration: isClickable && value != 'Not provided'
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContactTap(String label, String value) async {
    try {
      Uri uri;
      if (label == 'Phone') {
        uri = Uri(scheme: 'sms', path: value);
      } else if (label == 'Email') {
        uri = Uri(scheme: 'mailto', path: value);
      } else {
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch ${label.toLowerCase()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening ${label.toLowerCase()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

