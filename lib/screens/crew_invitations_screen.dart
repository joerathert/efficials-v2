import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../models/crew_model.dart';

class CrewInvitationsScreen extends StatefulWidget {
  const CrewInvitationsScreen({super.key});

  @override
  State<CrewInvitationsScreen> createState() => _CrewInvitationsScreenState();
}

class _CrewInvitationsScreenState extends State<CrewInvitationsScreen> {
  final CrewRepository _crewRepo = CrewRepository();

  List<CrewInvitation> _pendingInvitations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentUserId = user.uid;
      if (_currentUserId == null) return;

      final invitations =
          await _crewRepo.getPendingInvitations(_currentUserId!);

      if (mounted) {
        setState(() {
          _pendingInvitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading invitations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _respondToInvitation(
      CrewInvitation invitation, String response) async {
    try {
      setState(() => _isLoading = true);

      final success = await _crewRepo.respondToInvitation(
        invitation.id!,
        response,
        null,
        _currentUserId!,
      );

      if (success) {
        // Remove the invitation from the list
        setState(() {
          _pendingInvitations.removeWhere((inv) => inv.id == invitation.id);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have ${response == 'accepted' ? 'accepted' : 'declined'} the invitation to join ${invitation.crewName}',
              ),
              backgroundColor:
                  response == 'accepted' ? Colors.green : Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Failed to respond to invitation. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error responding to invitation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error responding to invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Crew Invitations',
          style: TextStyle(color: AppColors.efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: AppColors.efficialsWhite),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.efficialsYellow),
            onPressed: _loadInvitations,
            tooltip: 'Refresh Invitations',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.efficialsYellow),
            )
          : RefreshIndicator(
              onRefresh: _loadInvitations,
              color: AppColors.efficialsYellow,
              child: _buildInvitationsList(),
            ),
    );
  }

  Widget _buildInvitationsList() {
    if (_pendingInvitations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${_pendingInvitations.length}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.efficialsYellow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pending ${_pendingInvitations.length == 1 ? 'Invitation' : 'Invitations'}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Officials want you to join their crews',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Invitations List
        ..._pendingInvitations
            .map((invitation) => _buildInvitationCard(invitation)),

        const SizedBox(height: 100), // Space for bottom padding
      ],
    );
  }

  Widget _buildInvitationCard(CrewInvitation invitation) {
    return Card(
      color: AppColors.efficialsBlack,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with crew info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.efficialsYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: AppColors.efficialsYellow,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.crewName ?? 'Unknown Crew',
                        style: const TextStyle(
                          color: AppColors.efficialsWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Invited by ${invitation.inviterName ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      if (invitation.invitedAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Invited ${invitation.invitedAt!.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Crew details
            if (invitation.sportName != null ||
                (invitation.competitionLevels != null &&
                    invitation.competitionLevels!.isNotEmpty))
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (invitation.sportName != null) ...[
                      Row(
                        children: [
                          Icon(Icons.sports, color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Sport: ${invitation.sportName}',
                            style: const TextStyle(
                              color: AppColors.efficialsWhite,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (invitation.competitionLevels != null &&
                        invitation.competitionLevels!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.emoji_events,
                              color: Colors.grey[400], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Levels: ${invitation.competitionLevels!.join(', ')}',
                            style: const TextStyle(
                              color: AppColors.efficialsWhite,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _respondToInvitation(invitation, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _respondToInvitation(invitation, 'declined'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No Pending Invitations',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When officials invite you to join their crews, they\'ll appear here',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/create_crew'),
              icon: const Icon(Icons.add),
              label: const Text('Create Your Own Crew'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.efficialsYellow,
                foregroundColor: AppColors.efficialsBlack,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
