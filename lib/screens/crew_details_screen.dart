import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_colors.dart';
import '../models/crew_model.dart';
import '../services/crew_endorsement_service.dart';

class CrewDetailsScreen extends StatefulWidget {
  const CrewDetailsScreen({super.key});

  @override
  State<CrewDetailsScreen> createState() => _CrewDetailsScreenState();
}

class _CrewDetailsScreenState extends State<CrewDetailsScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final CrewEndorsementService _endorsementService = CrewEndorsementService();

  Crew? _crew;
  bool _isLoading = true;
  bool _isCrewChief = false;
  bool _isScheduler = false;
  bool _hasEndorsedThisCrew = false;
  bool _isProcessingEndorsement = false;
  String? _currentUserId;
  List<CrewInvitation> _crewInvitations = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final crew = ModalRoute.of(context)?.settings.arguments as Crew?;
    if (crew != null && _crew == null) {
      _loadCrewDetails(crew);
    }
  }

  Future<void> _loadCrewDetails(Crew crew) async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentUserId = user.uid;
      if (_currentUserId == null) return;
      _isCrewChief = crew.crewChiefId == _currentUserId;

      // Check if current user is a scheduler
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        _isScheduler = userData['role'] == 'scheduler';
      }

      // Check if scheduler has endorsed this crew
      if (_isScheduler && _crew!.id != null) {
        _hasEndorsedThisCrew =
            await _endorsementService.hasUserEndorsedCrew(_crew!.id!);
      }

      // Load fresh crew data
      final updatedCrew = await _crewRepo.getCrewById(crew.id!);
      if (updatedCrew != null) {
        _crew = updatedCrew;
      } else {
        _crew = crew;
      }

      // Load crew invitations if crew chief
      if (_isCrewChief) {
        _crewInvitations = await _crewRepo.getCrewInvitations(_crew!.id!);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading crew details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEndorsement() async {
    if (!_isScheduler || _crew == null || _isProcessingEndorsement) return;

    setState(() => _isProcessingEndorsement = true);

    try {
      if (_hasEndorsedThisCrew) {
        // Remove endorsement
        await _endorsementService.removeCrewEndorsement(
            endorsedCrewId: _crew!.id!);
        setState(() => _hasEndorsedThisCrew = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Endorsement removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Add endorsement
        await _endorsementService.addCrewEndorsement(
            endorsedCrewId: _crew!.id!);
        setState(() => _hasEndorsedThisCrew = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crew endorsed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Refresh crew details to update endorsement counts
      await _refreshCrewDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${_hasEndorsedThisCrew ? 'removing' : 'adding'} endorsement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingEndorsement = false);
      }
    }
  }

  Future<void> _refreshCrewDetails() async {
    if (_crew != null) {
      await _loadCrewDetails(_crew!);
    }
  }

  Future<void> _addMembers() async {
    if (_crew == null || !_isCrewChief) {
      print('❌ Cannot add members: crew is null or user is not crew chief');
      return;
    }

    // Ensure crew data is fully loaded
    if (_crew!.sportName == null || _crew!.requiredOfficials == null) {
      print('❌ Crew data not fully loaded, refreshing...');
      await _refreshCrewDetails();
      if (_crew!.sportName == null || _crew!.requiredOfficials == null) {
        print('❌ Crew data still not loaded after refresh');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Crew data is still loading. Please try again.')),
        );
        return;
      }
    }

    final competitionLevelsText =
        _crew!.competitionLevels?.join(', ') ?? 'No levels specified';
    print(
        '✅ Opening AddCrewMembersScreen for crew: ${_crew!.sportName} (${_crew!.requiredOfficials} officials) - Levels: $competitionLevelsText');

    // Navigate to full add members screen (like v1.0)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCrewMembersScreen(crew: _crew!),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh crew details if members were added
        _refreshCrewDetails();
      }
    });
  }

  Future<void> _deleteCrew() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Delete Crew',
          style: TextStyle(color: AppColors.efficialsWhite),
        ),
        content: Text(
          'Are you sure you want to delete "${_crew!.name}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.efficialsWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _crewRepo.deleteCrew(_crew!.id!, _currentUserId!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crew deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return to dashboard
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Failed to delete crew. You may not be the crew chief or the crew has active assignments.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting crew: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMember(CrewMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Remove Member',
          style: TextStyle(color: AppColors.efficialsWhite),
        ),
        content: Text(
          'Remove ${member.officialName ?? 'this member'} from the crew?',
          style: const TextStyle(color: AppColors.efficialsWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success =
            await _crewRepo.removeCrewMember(_crew!.id!, member.officialId);
        if (success) {
          await _refreshCrewDetails();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Member removed successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_crew == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.efficialsBlack,
          title: const Text(
            'Crew Details',
            style: TextStyle(color: AppColors.efficialsWhite),
          ),
          iconTheme: const IconThemeData(color: AppColors.efficialsWhite),
        ),
        body: const Center(
          child: Text(
            'No crew data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: Text(
          _crew!.name,
          style: const TextStyle(color: AppColors.efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: AppColors.efficialsWhite),
        elevation: 0,
        actions: [
          if (_isCrewChief) ...[
            IconButton(
              icon: const Icon(Icons.person_add,
                  color: AppColors.efficialsYellow),
              onPressed: _addMembers,
              tooltip: 'Add Members',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteCrew,
              tooltip: 'Delete Crew',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.efficialsYellow),
            onPressed: _refreshCrewDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.efficialsYellow),
            )
          : RefreshIndicator(
              onRefresh: _refreshCrewDetails,
              color: AppColors.efficialsYellow,
              child: _buildCrewDetails(),
            ),
    );
  }

  Widget _buildCrewDetails() {
    final memberCount = _crew!.members?.length ?? 0;
    final requiredCount = _crew!.requiredOfficials ?? 0;
    final isFullyStaffed = memberCount >= requiredCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Crew Overview Card
        Card(
          color: AppColors.efficialsBlack,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _crew!.name,
                        style: const TextStyle(
                          color: AppColors.efficialsWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isCrewChief)
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
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.sports,
                  'Sport',
                  _crew!.sportName ?? 'Unknown Sport',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.emoji_events,
                  'Competition Levels',
                  _crew!.competitionLevels?.join(', ') ?? 'No levels specified',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.people,
                  'Members',
                  '$memberCount of $requiredCount officials',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.person,
                  'Crew Chief',
                  _crew!.crewChiefName ?? 'Unknown',
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFullyStaffed
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isFullyStaffed ? 'READY TO WORK' : 'INCOMPLETE',
                    style: TextStyle(
                      color: isFullyStaffed ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Endorsements section
                Row(
                  children: [
                    const Icon(
                      Icons.thumb_up,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Endorsements',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_crew!.athleticDirectorEndorsements > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.efficialsYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_crew!.athleticDirectorEndorsements} AD',
                          style: const TextStyle(
                            color: AppColors.efficialsYellow,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_crew!.coachEndorsements > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_crew!.coachEndorsements} Coach',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_crew!.assignerEndorsements > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_crew!.assignerEndorsements} Assigner',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_crew!.totalEndorsements == 0)
                      Text(
                        'No endorsements yet',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                // Endorsement button for schedulers
                if (_isScheduler) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isProcessingEndorsement ? null : _handleEndorsement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasEndorsedThisCrew
                            ? Colors.grey[700]
                            : AppColors.efficialsYellow,
                        foregroundColor: _hasEndorsedThisCrew
                            ? Colors.white
                            : AppColors.efficialsBlack,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessingEndorsement
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _hasEndorsedThisCrew
                                  ? 'Remove Endorsement'
                                  : 'Endorse This Crew',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Crew Members
        Card(
          color: AppColors.efficialsBlack,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Crew Members',
                      style: TextStyle(
                        color: AppColors.efficialsWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.efficialsYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_crew!.members?.length ?? 0}',
                        style: const TextStyle(
                          color: AppColors.efficialsYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_crew!.members != null && _crew!.members!.isNotEmpty)
                  ..._crew!.members!.map((member) => _buildMemberCard(member))
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No members yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Pending Invitations (Crew Chief Only)
        if (_isCrewChief && _crewInvitations.isNotEmpty) ...[
          const SizedBox(height: 24),
          Card(
            color: AppColors.efficialsBlack,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Invitations',
                    style: TextStyle(
                      color: AppColors.efficialsWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._crewInvitations
                      .map((invitation) => _buildInvitationCard(invitation)),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 100), // Space for bottom padding
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.efficialsWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(CrewMember member) {
    final isCrewChief = member.position == 'crew_chief';
    final canRemove = _isCrewChief && !isCrewChief;

    return GestureDetector(
      onTap: () {
        // Navigate to official's profile
        Navigator.pushNamed(
          context,
          '/view-official-profile',
          arguments: member.officialId,
        );
      },
      child: Card(
        color: AppColors.darkSurface,
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member.officialName ?? 'Unknown Official',
                          style: const TextStyle(
                            color: AppColors.efficialsWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isCrewChief) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.efficialsYellow,
                              borderRadius: BorderRadius.circular(8),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.gamePosition ?? member.position,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.city != null && member.state != null
                          ? '${member.city}, ${member.state}'
                          : 'Location not set',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeMember(member),
                  tooltip: 'Remove Member',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(CrewInvitation invitation) {
    return Card(
      color: AppColors.darkSurface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.invitedOfficialName ?? 'Unknown Official',
                    style: const TextStyle(
                      color: AppColors.efficialsWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Invited ${invitation.invitedAt?.toLocal().toString().split(' ')[0] ?? 'recently'}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

class AddCrewMembersScreen extends StatefulWidget {
  final Crew crew;

  const AddCrewMembersScreen({
    super.key,
    required this.crew,
  });

  @override
  State<AddCrewMembersScreen> createState() => _AddCrewMembersScreenState();
}

class _AddCrewMembersScreenState extends State<AddCrewMembersScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _availableOfficials = [];
  List<Map<String, dynamic>> _filteredOfficials = [];
  List<Map<String, dynamic>> _selectedMembers = [];
  List<String> _existingMemberIds = [];
  List<String> _pendingInvitationIds = [];
  bool _isLoading = true;
  bool _isInviting = false;
  String? _currentUserId;

  String _formatLocation(String? city, String? state) {
    final cityStr = city?.trim() ?? '';
    final stateStr = state?.trim() ?? '';
    if (cityStr.isNotEmpty && stateStr.isNotEmpty) {
      return '$cityStr, $stateStr';
    } else if (cityStr.isNotEmpty) {
      return cityStr;
    } else if (stateStr.isNotEmpty) {
      return stateStr;
    }
    return 'Location Unknown';
  }

  @override
  void initState() {
    super.initState();
    _loadAvailableOfficials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableOfficials() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentUserId = user.uid;

      print('🔍 Loading available officials for crew:');
      print('   Crew ID: ${widget.crew.id}');
      print('   Sport: ${widget.crew.sportName}');
      print(
          '   Competition Levels: ${widget.crew.competitionLevels?.join(', ')}');
      print('   Required officials: ${widget.crew.requiredOfficials}');

      // Get existing crew members to exclude them
      final crew = await _crewRepo.getCrewById(widget.crew.id!);
      if (crew != null && crew.members != null) {
        _existingMemberIds = crew.members!.map((m) => m.officialId).toList();

        // Get pending invitations to exclude those officials too
        final invitations = await _crewRepo.getCrewInvitations(widget.crew.id!);
        _pendingInvitationIds = invitations
            .where((inv) => inv.status == 'pending')
            .map((inv) => inv.invitedOfficialId)
            .toList();
      }

      // Get all officials from the database who match the crew's sport and competition level
      await _loadOfficialsBySportAndLevel(crew);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading available officials: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadOfficialsBySportAndLevel(Crew? crew) async {
    try {
      if (crew == null) return;

      // Query officials collection for users with official profiles
      final officialsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'official')
          .get();

      final matchingOfficials = <Map<String, dynamic>>[];

      for (final doc in officialsQuery.docs) {
        final userData = doc.data();
        final officialId = doc.id;
        final officialProfile =
            userData['officialProfile'] as Map<String, dynamic>?;

        // Skip if not current user, already a member, or has pending invitation
        if (officialId == _currentUserId ||
            _existingMemberIds.contains(officialId) ||
            _pendingInvitationIds.contains(officialId)) {
          continue;
        }

        // Check if official has the required sport and competition level
        if (officialProfile != null) {
          final sportsData =
              officialProfile['sportsData'] as Map<String, dynamic>? ?? {};

          // Check if official does the sport and has matching competition levels
          bool hasSportAndLevel = false;

          if (widget.crew.sportName != null &&
              widget.crew.competitionLevels != null &&
              widget.crew.competitionLevels!.isNotEmpty) {
            final sportData =
                sportsData[widget.crew.sportName!] as Map<String, dynamic>?;

            if (sportData != null) {
              final officialCompetitionLevels =
                  sportData['competitionLevels'] as List<dynamic>? ?? [];
              print(
                  'Checking official ${userData['fullName']}: sport=${widget.crew.sportName}, crew levels=${widget.crew.competitionLevels}');
              print(
                  'Official competition levels for ${widget.crew.sportName}: $officialCompetitionLevels');

              // Check if official has ANY of the crew's required competition levels
              hasSportAndLevel = widget.crew.competitionLevels!.any(
                  (crewLevel) => officialCompetitionLevels.any(
                      (officialLevel) => officialLevel
                          .toString()
                          .toLowerCase()
                          .contains(crewLevel.toLowerCase())));

              if (hasSportAndLevel) {
                print('✅ Match found for ${userData['fullName']}');
              }
            }
          } else {
            print(
                '❌ Crew missing data: sportName=${widget.crew.sportName}, competitionLevels=${widget.crew.competitionLevels}');
          }

          if (hasSportAndLevel) {
            // Construct full name from profile data
            final profile = userData['profile'] as Map<String, dynamic>? ?? {};
            final firstName = profile['firstName'] as String? ?? '';
            final lastName = profile['lastName'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();
            final displayName =
                fullName.isNotEmpty ? fullName : 'Unknown Official';

            matchingOfficials.add({
              'id': officialId,
              'name': displayName,
              'email': userData['email'] ?? '',
              'city': officialProfile['city'] ?? '',
              'state': officialProfile['state'] ?? '',
              'location': _formatLocation(
                  officialProfile['city'], officialProfile['state']),
            });
          }
        }
      }

      _availableOfficials = matchingOfficials;
      print(
          'Found ${matchingOfficials.length} available officials for ${crew.sportName} (${crew.competitionLevels?.join(', ')})');
      print('Total officials checked: ${officialsQuery.docs.length}');
      print(
          'Crew sport: ${crew.sportName}, competition levels: ${crew.competitionLevels}');
      print(
          'Matching officials: ${matchingOfficials.map((o) => o['name']).toList()}');
    } catch (e) {
      print('Error querying officials by sport and level: $e');
      _availableOfficials = [];
    }
  }

  Future<void> _sendInvitations() async {
    if (_selectedMembers.isEmpty) return;

    setState(() => _isInviting = true);

    try {
      int successCount = 0;
      int failCount = 0;

      for (final member in _selectedMembers) {
        try {
          final invitation = CrewInvitation(
            crewId: widget.crew.id!,
            crewName: widget.crew.name,
            invitedOfficialId: member['id'],
            invitedOfficialName: member['name'],
            invitedBy: _currentUserId!,
            inviterName: 'Crew Chief',
            status: 'pending',
            invitedAt: DateTime.now(),
          );

          final success = await _crewRepo.createCrewInvitation(invitation);
          if (success) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          print('Error sending invitation to ${member['name']}: $e');
          failCount++;
        }
      }

      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully sent $successCount invitation(s)'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Sent $successCount invitation(s), $failCount failed'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send invitations'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Return to crew details screen
        Navigator.pop(context, successCount > 0);
      }
    } catch (e) {
      print('Error sending invitations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('An unexpected error occurred while sending invitations'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isInviting = false);
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
          'Add Crew Members',
          style: TextStyle(color: AppColors.efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: AppColors.efficialsWhite),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.efficialsYellow),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildMembersList()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.efficialsBlack,
            AppColors.darkSurface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.crew.name,
            style: const TextStyle(
              color: AppColors.efficialsYellow,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add members to your ${widget.crew.sportName ?? 'crew'}',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Officials already in crew or with pending invitations are excluded',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_availableOfficials.length} available officials',
            style: const TextStyle(
              color: AppColors.efficialsYellow,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return Column(
      children: [
        // Search Field
        Container(
          padding: const EdgeInsets.all(20),
          child: TextFormField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.efficialsWhite),
            decoration: InputDecoration(
              hintText: 'Type official\'s name to search...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.efficialsYellow),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.efficialsYellow),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _filteredOfficials = [];
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.efficialsBlack,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.efficialsYellow),
              ),
            ),
            onChanged: (value) {
              setState(() {
                if (value.isEmpty) {
                  _filteredOfficials = [];
                } else {
                  _filteredOfficials = _availableOfficials
                      .where((official) => official['name']
                          .toString()
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList()
                    ..sort((a, b) => a['name']
                        .toString()
                        .toLowerCase()
                        .compareTo(b['name'].toString().toLowerCase()));
                }
              });
            },
          ),
        ),
        // Officials List
        Expanded(
          child: (_searchController.text.isEmpty
                      ? _availableOfficials
                      : _filteredOfficials)
                  .isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: (_searchController.text.isEmpty
                          ? _availableOfficials
                          : _filteredOfficials)
                      .length,
                  itemBuilder: (context, index) {
                    final official = (_searchController.text.isEmpty
                        ? _availableOfficials
                        : _filteredOfficials)[index];
                    final isSelected = _selectedMembers.contains(official);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.efficialsYellow.withOpacity(0.1)
                            : AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.efficialsYellow.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isSelected ? Icons.check_circle : Icons.add_circle,
                            color: isSelected
                                ? Colors.green
                                : AppColors.efficialsYellow,
                            size: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                _selectedMembers.remove(official);
                              } else {
                                _selectedMembers.add(official);
                              }
                            });
                          },
                        ),
                        title: Text(
                          official['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: AppColors.efficialsWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          official['location'] ?? 'Location Unknown',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No available officials to invite'
                : 'No officials found matching "${_searchController.text}"',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasSelectedMembers = _selectedMembers.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.efficialsBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSelectedMembers) ...[
            Text(
              '${_selectedMembers.length} official(s) selected',
              style: const TextStyle(
                color: AppColors.efficialsYellow,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  hasSelectedMembers && !_isInviting ? _sendInvitations : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelectedMembers
                    ? AppColors.efficialsYellow
                    : Colors.grey[700],
                foregroundColor: AppColors.efficialsBlack,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isInviting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      hasSelectedMembers
                          ? 'Send ${_selectedMembers.length} Invitation(s)'
                          : 'Select officials to invite',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
