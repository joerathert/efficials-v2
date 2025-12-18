import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../models/crew_model.dart';
import '../services/user_service.dart';

class CrewDashboardScreen extends StatefulWidget {
  const CrewDashboardScreen({super.key});

  @override
  State<CrewDashboardScreen> createState() => _CrewDashboardScreenState();
}

class _CrewDashboardScreenState extends State<CrewDashboardScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final UserService _userService = UserService();

  List<Crew> _allCrews = [];
  List<CrewInvitation> _pendingInvitations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCrews();
  }

  Future<void> _loadCrews() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentUserId = user.uid;
      if (_currentUserId == null) return;

      // Load crews where user is chief
      final crewsAsChief = await _crewRepo.getCrewsWhereChief(_currentUserId!);
      print(
          '👥 CREW DASHBOARD: Found ${crewsAsChief.length} crews where user is chief');
      for (final crew in crewsAsChief) {
        print('👥 CREW DASHBOARD: Chief crew: "${crew.name}" (ID: ${crew.id})');
      }

      // Load crews where user is member
      final crewsAsMember =
          await _crewRepo.getCrewsForOfficial(_currentUserId!);
      print(
          '👥 CREW DASHBOARD: Found ${crewsAsMember.length} crews where user is member');
      for (final crew in crewsAsMember) {
        print(
            '👥 CREW DASHBOARD: Member crew: "${crew.name}" (ID: ${crew.id})');
      }

      // Combine and remove duplicates
      final allCrews = <Crew>[];
      allCrews.addAll(crewsAsChief);

      for (final memberCrew in crewsAsMember) {
        if (!crewsAsChief.any((chiefCrew) => chiefCrew.id == memberCrew.id)) {
          allCrews.add(memberCrew);
        }
      }

      print(
          '👥 CREW DASHBOARD: Final crew count after deduplication: ${allCrews.length}');

      // Load pending invitations
      final pendingInvitations =
          await _crewRepo.getPendingInvitations(_currentUserId!);

      if (mounted) {
        setState(() {
          _allCrews = allCrews;
          _pendingInvitations = pendingInvitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading crews: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
          'My Crews',
          style: TextStyle(color: AppColors.efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: AppColors.efficialsWhite),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.efficialsYellow),
            onPressed: _loadCrews,
            tooltip: 'Refresh Crews',
          ),
          IconButton(
            icon: const Icon(Icons.mail, color: AppColors.efficialsYellow),
            onPressed: () => Navigator.pushNamed(context, '/crew_invitations'),
            tooltip: 'View Invitations',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.efficialsYellow),
                  SizedBox(height: 16),
                  Text(
                    'Loading crews...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCrews,
              color: AppColors.efficialsYellow,
              child: _buildCrewsList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/create_crew').then((result) {
          if (result == true) {
            _loadCrews(); // Refresh the crew list when returning from successful creation
          }
        }),
        backgroundColor: AppColors.efficialsYellow,
        foregroundColor: AppColors.efficialsBlack,
        tooltip: 'Create New Crew',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCrewsList() {
    final hasCrews = _allCrews.isNotEmpty;
    final hasInvitations = _pendingInvitations.isNotEmpty;

    if (!hasCrews && !hasInvitations) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pending Invitations Section
        if (hasInvitations) ...[
          _buildSectionHeader('Crew Invitations', _pendingInvitations.length),
          const SizedBox(height: 8),
          ..._pendingInvitations
              .map((invitation) => _buildInvitationCard(invitation)),
          if (hasCrews) const SizedBox(height: 24),
        ],

        // My Crews Section
        if (hasCrews) ...[
          _buildSectionHeader('My Crews', _allCrews.length),
          const SizedBox(height: 8),
          ..._allCrews.map((crew) {
            final isChief = crew.crewChiefId == _currentUserId;
            return _buildCrewCard(crew, isChief: isChief);
          }),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.efficialsYellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.efficialsYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: AppColors.efficialsYellow,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewCard(Crew crew, {required bool isChief}) {
    final memberCount = crew.members?.length ?? 0;
    final requiredCount = crew.requiredOfficials ?? 0;
    final isFullyStaffed = memberCount >= requiredCount;

    return Card(
      color: AppColors.efficialsBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/crew_details',
          arguments: crew,
        ).then((result) {
          // Refresh the crew list when returning from crew details
          // This handles cases where crew was deleted or modified
          if (result == true || mounted) {
            _loadCrews();
          }
        }),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      crew.name,
                      style: const TextStyle(
                        color: AppColors.efficialsWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isChief)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.efficialsYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'CHIEF',
                        style: TextStyle(
                          color: AppColors.efficialsBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.sports,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${crew.sportName ?? 'Unknown Sport'}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$memberCount of $requiredCount members',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Crew Chief: ${crew.crewChiefName ?? 'Unknown'}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFullyStaffed
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFullyStaffed ? 'READY TO WORK' : 'INCOMPLETE',
                  style: TextStyle(
                    color: isFullyStaffed ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(CrewInvitation invitation) {
    return Card(
      color: AppColors.efficialsBlack,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.crewName ?? 'Unknown Crew',
                        style: const TextStyle(
                          color: AppColors.efficialsWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Invited by ${invitation.inviterName ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
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
            const SizedBox(height: 12),
            if (invitation.sportName != null ||
                (invitation.competitionLevels != null &&
                    invitation.competitionLevels!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    if (invitation.sportName != null) ...[
                      Icon(Icons.sports, color: Colors.grey[400], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        invitation.sportName!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                    if (invitation.sportName != null &&
                        invitation.competitionLevels != null &&
                        invitation.competitionLevels!.isNotEmpty)
                      Text(' • ', style: TextStyle(color: Colors.grey[400])),
                    if (invitation.competitionLevels != null &&
                        invitation.competitionLevels!.isNotEmpty) ...[
                      Icon(Icons.emoji_events,
                          color: Colors.grey[400], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        invitation.competitionLevels!.join(', '),
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _respondToInvitation(invitation, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
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
                    ),
                    child: const Text('Decline'),
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
              Icons.groups,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No Crews Yet',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first crew',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
        // Refresh the crew list to show updated state
        await _loadCrews();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error responding to invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
