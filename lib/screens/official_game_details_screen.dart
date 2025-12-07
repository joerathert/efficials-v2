import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../services/game_service.dart';
import '../services/user_service.dart';

class OfficialGameDetailsScreen extends StatefulWidget {
  const OfficialGameDetailsScreen({super.key});

  @override
  State<OfficialGameDetailsScreen> createState() =>
      _OfficialGameDetailsScreenState();
}

class _OfficialGameDetailsScreenState extends State<OfficialGameDetailsScreen> {
  late Map<String, dynamic> game;
  List<Map<String, dynamic>> otherOfficials = [];
  Map<String, dynamic>? schedulerInfo;
  bool _isLoading = true;

  final GameService _gameService = GameService();
  final UserService _userService = UserService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final routeArgs = ModalRoute.of(context)!.settings.arguments;
    game = routeArgs as Map<String, dynamic>;

    print('OfficialGameDetailsScreen loaded - Game ID: ${game['id']}');
    print('Game sport: ${game['sport']}');

    _loadGameDetails();
  }

  Future<void> _loadGameDetails() async {
    try {
      setState(() => _isLoading = true);

      if (game['id'] != null) {
        // Get other officials for this game
        final officials = await _gameService
            .getConfirmedOfficialsForGame(game['id'] as String);

        // Get scheduler information from schedulerId in game data
        Map<String, dynamic>? scheduler;
        final schedulerId = game['schedulerId'] as String?;
        if (schedulerId != null) {
          final schedulerUser = await _userService.getUserById(schedulerId);
          if (schedulerUser != null) {
            scheduler = {
              'name': schedulerUser.fullName,
              'email': schedulerUser.email,
              'phone': schedulerUser.profile.phone,
            };
          }
        }

        setState(() {
          otherOfficials = officials
              .where((official) => official['id'] != _getCurrentUserId())
              .toList();
          schedulerInfo = scheduler;
        });
      }
    } catch (e) {
      print('Error loading game details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _getCurrentUserId() {
    // Get the current user's ID from Firebase Auth
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.efficialsYellow),
          SizedBox(height: 16),
          Text(
            'Loading game details...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameHeader(),
          const SizedBox(height: 24),
          _buildGameDetails(),
          const SizedBox(height: 24),
          _buildOtherOfficials(),
          const SizedBox(height: 24),
          _buildSchedulerInfo(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGameHeader() {
    final sportName = game['sport'] ?? 'Sport';
    final gameTitle = _formatGameTitle(game);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getSportColor(sportName).withOpacity(0.1),
            AppColors.darkSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getSportColor(sportName).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSportColor(sportName).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getSportIcon(sportName),
                  color: _getSportColor(sportName),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sportName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.efficialsYellow,
                      ),
                    ),
                    Text(
                      gameTitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CONFIRMED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[300],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameDetails() {
    final gameDate = _formatGameDate(game);
    final gameTime = _formatGameTime(game);
    final locationName = game['location'] ?? 'TBD';
    final locationAddress = game['locationAddress'] as String?;
    final locationDisplay = locationAddress != null && locationAddress.isNotEmpty
        ? '$locationName\n$locationAddress'
        : locationName;
    final fee = _parseFee(game['gameFee']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.efficialsYellow,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              Icons.schedule, 'Date & Time', '$gameDate at $gameTime'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on, 'Location', locationDisplay),
          const SizedBox(height: 12),
          _buildDetailRow(
              Icons.attach_money, 'Fee', '\$${fee.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherOfficials() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people,
                  color: AppColors.efficialsYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Other Officials (${otherOfficials.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.efficialsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (otherOfficials.isEmpty)
            Text(
              'No other officials have been confirmed for this game.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            )
          else
            ...otherOfficials
                .map((official) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _navigateToOfficialProfile(
                            official['id'] as String? ?? ''),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.efficialsYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.efficialsYellow,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    official['name'] as String? ??
                                        'Unknown Official',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.efficialsYellow,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  Text(
                                    _formatOfficialLocation(official),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildSchedulerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle,
                  color: AppColors.efficialsYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Scheduler Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.efficialsYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (schedulerInfo == null)
            Text(
              'Scheduler information not available.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            )
          else
            Column(
              children: [
                _buildContactRow(Icons.person, 'Name',
                    schedulerInfo!['name'] as String? ?? 'Unknown'),
                const SizedBox(height: 12),
                if (schedulerInfo!['email'] != null)
                  _buildContactRow(
                      Icons.email, 'Email', schedulerInfo!['email'] as String),
                if (schedulerInfo!['phone'] != null) ...[
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.phone, 'Phone',
                      _formatPhoneNumber(schedulerInfo!['phone'] as String)),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _getDirections,
            icon: const Icon(Icons.directions, size: 20),
            label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.efficialsYellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _contactScheduler,
            icon: const Icon(Icons.message, size: 20),
            label: const Text('Contact Scheduler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.efficialsYellow,
              side: const BorderSide(color: AppColors.efficialsYellow),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showBackOutDialog,
            icon: const Icon(Icons.exit_to_app, size: 20),
            label: const Text('Back Out of Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _getDirections() async {
    final locationName = game['location'];
    final address = game['locationAddress']; // May not be available

    if (locationName == null && address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use address if available, otherwise use location name
    final query = Uri.encodeComponent(address ?? locationName!);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _contactScheduler() async {
    if (schedulerInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduler contact information not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final email = schedulerInfo!['email'] as String?;
    final phone = schedulerInfo!['phone'] as String?;
    final name = schedulerInfo!['name'] as String? ?? 'Scheduler';

    if (email == null && phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No contact information available for scheduler'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Always show the contact options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.contact_phone,
                color: AppColors.efficialsYellow, size: 24),
            const SizedBox(width: 8),
            Text(
              'Contact $name',
              style: const TextStyle(
                  color: AppColors.efficialsYellow,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone != null) ...[
              ListTile(
                leading:
                    const Icon(Icons.message, color: AppColors.efficialsYellow),
                title: const Text('Send Text Message',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(_formatPhoneNumber(phone),
                    style: TextStyle(color: Colors.grey[400])),
                onTap: () {
                  Navigator.pop(context);
                  _launchSMS(phone, name);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.phone, color: AppColors.efficialsYellow),
                title:
                    const Text('Call', style: TextStyle(color: Colors.white)),
                subtitle: Text(_formatPhoneNumber(phone),
                    style: TextStyle(color: Colors.grey[400])),
                onTap: () {
                  Navigator.pop(context);
                  _launchPhone(phone);
                },
              ),
            ],
            if (email != null)
              ListTile(
                leading:
                    const Icon(Icons.email, color: AppColors.efficialsYellow),
                title: const Text('Send Email',
                    style: TextStyle(color: Colors.white)),
                subtitle:
                    Text(email, style: TextStyle(color: Colors.grey[400])),
                onTap: () {
                  Navigator.pop(context);
                  _launchEmail(email, name);
                },
              ),
            if (phone == null && email == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No contact information available',
                  style: TextStyle(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email, String schedulerName) async {
    final gameTitle = _formatGameTitle(game);
    final subject =
        Uri.encodeComponent('Game Assignment: ${game['sport']} - $gameTitle');
    final url = 'mailto:$email?subject=$subject';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch email');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final url = 'tel:$phone';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch phone');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchSMS(String phone, String schedulerName) async {
    final gameTitle = _formatGameTitle(game);
    final message = Uri.encodeComponent(
        'Hi $schedulerName, this is regarding the ${game['sport']} game: $gameTitle');
    final url = 'sms:$phone?body=$message';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch SMS');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open messaging: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBackOutDialog() async {
    final sportName = game['sport'] ?? 'Sport';
    final gameDate = _formatGameDate(game);
    final gameTime = _formatGameTime(game);
    final locationName = game['location'] ?? 'TBD';
    final gameTitle = _formatGameTitle(game);

    final gameSummary =
        '$sportName: $gameTitle\n$gameDate at $gameTime\n$locationName';

    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Back Out of Game',
              style: TextStyle(
                color: AppColors.efficialsYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to back out of this game?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.efficialsBlack,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  gameSummary,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please provide a reason:',
                style: TextStyle(
                  color: AppColors.efficialsYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your reason for backing out...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: AppColors.efficialsBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.efficialsYellow),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: The scheduler will be notified of your withdrawal.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for backing out'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              // Return the reason from the dialog
              Navigator.pop(context, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Back Out'),
          ),
        ],
      ),
    );

    // If user confirmed (result contains the reason), perform the backout
    if (result != null && result.isNotEmpty) {
      // Wait for the backout operation to complete before navigating
      await _handleBackOut(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully backed out of game'),
            backgroundColor: Colors.green,
          ),
        );
        // Return to previous screen AFTER backout is complete
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _handleBackOut(String reason) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final gameId = game['id'] as String?;
      if (gameId == null) {
        throw Exception('Game ID not found');
      }

      final success =
          await _gameService.backOutOfGame(gameId, currentUserId, reason);

      if (!success) {
        throw Exception('Failed to back out of game');
      }

      // Add a small delay to ensure Firestore propagation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error backing out of game: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Re-throw to prevent navigation on error
        rethrow;
      }
    }
  }

  // Helper methods for sports
  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Icons.sports_basketball;
      case 'football':
        return Icons.sports_football;
      case 'baseball':
        return Icons.sports_baseball;
      case 'volleyball':
        return Icons.sports_volleyball;
      default:
        return Icons.sports;
    }
  }

  Color _getSportColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'basketball':
        return Colors.orange;
      case 'football':
        return Colors.brown;
      case 'baseball':
        return Colors.blue;
      case 'volleyball':
        return Colors.purple;
      default:
        return AppColors.efficialsYellow;
    }
  }

  String _formatGameTitle(Map<String, dynamic> game) {
    final opponent = game['opponent'] as String?;
    final scheduleHomeTeam = game['schedule_home_team_name'] as String?;
    final queryHomeTeam = game['home_team'] as String?;
    final camelCaseHomeTeam = game['homeTeam'] as String?;

    final homeTeam = (scheduleHomeTeam != null &&
            scheduleHomeTeam.trim().isNotEmpty)
        ? scheduleHomeTeam
        : (queryHomeTeam != null && queryHomeTeam.trim().isNotEmpty)
            ? queryHomeTeam
            : (camelCaseHomeTeam != null && camelCaseHomeTeam.trim().isNotEmpty)
                ? camelCaseHomeTeam
                : 'Home Team';

    if (opponent != null && homeTeam != 'Home Team') {
      return '$opponent @ $homeTeam';
    } else if (opponent != null) {
      return opponent;
    } else {
      return 'TBD';
    }
  }

  String _formatGameDate(Map<String, dynamic> game) {
    if (game['date'] == null) return 'TBD';
    try {
      final date = DateTime.parse(game['date']);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      final dayName = days[date.weekday - 1];
      final monthName = months[date.month - 1];

      return '$dayName, $monthName ${date.day}';
    } catch (e) {
      return 'TBD';
    }
  }

  String _formatGameTime(Map<String, dynamic> game) {
    if (game['time'] == null) return 'TBD';
    try {
      final timeString = game['time'] as String;
      // Handle "H:MM" or "HH:MM" format (e.g., "9:00", "14:30")
      final parts = timeString.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format: $timeString');
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'TBD';
    }
  }

  String _formatOfficialLocation(Map<String, dynamic> official) {
    final city = official['city']?.toString().trim() ?? '';
    final state = official['state']?.toString().trim() ?? '';

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    } else if (city.isNotEmpty) {
      return city;
    } else if (state.isNotEmpty) {
      return state;
    } else {
      return 'Location not specified';
    }
  }

  void _navigateToOfficialProfile(String officialId) {
    if (officialId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot view profile: Official ID not available')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/view-official-profile',
      arguments: {'officialId': officialId},
    );
  }

  double _parseFee(dynamic feeValue) {
    if (feeValue == null) return 0.0;

    if (feeValue is double) return feeValue;
    if (feeValue is int) return feeValue.toDouble();
    if (feeValue is String) {
      try {
        return double.parse(feeValue);
      } catch (e) {
        return 0.0;
      }
    }

    return 0.0;
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if we have exactly 10 digits (US phone number format)
    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }

    // If it's not 10 digits, return the original (could be international or malformed)
    return phone;
  }
}
