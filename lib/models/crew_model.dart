// Simplified Crew model for v2.0 - adapted from crew app
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/crew_endorsement_service.dart';
class Crew {
  final String? id;
  final String name;
  final int crewTypeId;
  final String crewChiefId;
  final String createdBy;
  final bool isActive;
  final String paymentMethod;
  final double? crewFeePerGame;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Endorsement counts
  int athleticDirectorEndorsements;
  int coachEndorsements;
  int assignerEndorsements;
  int totalEndorsements;

  // Joined data (mutable for repository to set after loading)
  String? sportName;
  String? levelOfCompetition;
  int? requiredOfficials;
  String? crewChiefName;
  String? crewChiefCity;
  String? crewChiefState;
  List<CrewMember>? members;
  List<String>? competitionLevels;

  Crew({
    this.id,
    required this.name,
    required this.crewTypeId,
    required this.crewChiefId,
    required this.createdBy,
    required this.isActive,
    required this.paymentMethod,
    this.crewFeePerGame,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.athleticDirectorEndorsements = 0,
    this.coachEndorsements = 0,
    this.assignerEndorsements = 0,
    this.totalEndorsements = 0,
    this.sportName,
    this.levelOfCompetition,
    this.requiredOfficials,
    this.crewChiefName,
    this.crewChiefCity,
    this.crewChiefState,
    this.members,
    this.competitionLevels,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Crew.fromMap(Map<String, dynamic> map) {
    return Crew(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      crewTypeId: map['crew_type_id'] as int? ?? 1,
      crewChiefId: map['crew_chief_id'] as String? ?? '',
      createdBy: map['created_by'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      paymentMethod: map['payment_method'] as String? ?? 'equal_split',
      crewFeePerGame: (map['crew_fee_per_game'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? (map['created_at'] is Timestamp
              ? (map['created_at'] as Timestamp).toDate()
              : DateTime.parse(map['created_at'] as String))
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] is Timestamp
              ? (map['updated_at'] as Timestamp).toDate()
              : DateTime.parse(map['updated_at'] as String))
          : DateTime.now(),
      athleticDirectorEndorsements: (map['athleticDirectorEndorsements'] ?? map['athletic_director_endorsements'] ?? 0).toInt(),
      coachEndorsements: (map['coachEndorsements'] ?? map['coach_endorsements'] ?? 0).toInt(),
      assignerEndorsements: (map['assignerEndorsements'] ?? map['assigner_endorsements'] ?? 0).toInt(),
      totalEndorsements: (map['totalEndorsements'] ?? map['total_endorsements'] ?? 0).toInt(),
      sportName: map['sport_name'] as String?,
      levelOfCompetition: map['level_of_competition'] as String?,
      requiredOfficials: map['required_officials'] as int?,
      crewChiefName: map['crew_chief_name'] as String?,
      crewChiefCity: map['crew_chief_city'] as String?,
      crewChiefState: map['crew_chief_state'] as String?,
      members: map['members'] != null
          ? (map['members'] as List).map((m) => CrewMember.fromMap(m as Map<String, dynamic>)).toList()
          : null,
      competitionLevels: map['competition_levels'] != null
          ? (map['competition_levels'] is String
              ? (map['competition_levels'] as String).split(',')
              : List<String>.from(map['competition_levels'] as List<dynamic>))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'crew_type_id': crewTypeId,
      'crew_chief_id': crewChiefId,
      'created_by': createdBy,
      'is_active': isActive,
      'payment_method': paymentMethod,
      'crew_fee_per_game': crewFeePerGame,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'athletic_director_endorsements': athleticDirectorEndorsements,
      'coach_endorsements': coachEndorsements,
      'assigner_endorsements': assignerEndorsements,
      'total_endorsements': totalEndorsements,
      'competition_levels': competitionLevels?.join(','),
    };
  }

  // Computed properties
  bool get isFullyStaffed {
    final memberCount = members?.length ?? 0;
    final required = requiredOfficials ?? 0;
    return memberCount >= required;
  }

  bool get canBeHired {
    return isActive && isFullyStaffed;
  }
}

class CrewMember {
  final String? id;
  final String crewId;
  final String officialId;
  final String position;
  final String? gamePosition;
  final DateTime joinedAt;
  final String status;

  // Joined data
  final String? officialName;
  final String? phone;
  final String? email;
  final String? city;
  final String? state;

  CrewMember({
    this.id,
    required this.crewId,
    required this.officialId,
    this.position = 'member',
    this.gamePosition,
    DateTime? joinedAt,
    this.status = 'active',
    this.officialName,
    this.phone,
    this.email,
    this.city,
    this.state,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory CrewMember.fromMap(Map<String, dynamic> map) {
    return CrewMember(
      id: map['id'] as String?,
      crewId: map['crew_id'] as String? ?? '',
      officialId: map['official_id'] as String? ?? '',
      position: map['position'] as String? ?? 'member',
      gamePosition: map['game_position'] as String?,
      joinedAt: map['joined_at'] != null
          ? (map['joined_at'] is Timestamp
              ? (map['joined_at'] as Timestamp).toDate()
              : DateTime.parse(map['joined_at'] as String))
          : DateTime.now(),
      status: map['status'] as String? ?? 'active',
      officialName: map['official_name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'crew_id': crewId,
      'official_id': officialId,
      'position': position,
      'game_position': gamePosition,
      'joined_at': Timestamp.fromDate(joinedAt),
      'status': status,
    };
  }
}

// Crew Invitation Model
class CrewInvitation {
  final String? id;
  final String crewId;
  final String? crewName;
  final String invitedOfficialId;
  final String? invitedOfficialName;
  final String invitedBy;
  final String? inviterName;
  final String? position;
  final String? gamePosition;
  final String? sportName;
  final String? levelOfCompetition;
  final String status;
  final DateTime? invitedAt;
  final DateTime? respondedAt;
  final String? responseNotes;

  CrewInvitation({
    this.id,
    required this.crewId,
    this.crewName,
    required this.invitedOfficialId,
    this.invitedOfficialName,
    required this.invitedBy,
    this.inviterName,
    this.position,
    this.gamePosition,
    this.sportName,
    this.levelOfCompetition,
    required this.status,
    this.invitedAt,
    this.respondedAt,
    this.responseNotes,
  });

  factory CrewInvitation.fromMap(Map<String, dynamic> map) {
    return CrewInvitation(
      id: map['id'] as String?,
      crewId: map['crew_id'] as String? ?? '',
      crewName: map['crew_name'] as String?,
      invitedOfficialId: map['invited_official_id'] as String? ?? '',
      invitedOfficialName: map['invited_official_name'] as String?,
      invitedBy: map['invited_by'] as String? ?? '',
      inviterName: map['inviter_name'] as String?,
      position: map['position'] as String?,
      gamePosition: map['game_position'] as String?,
      sportName: map['sport_name'] as String?,
      levelOfCompetition: map['level_of_competition'] as String?,
      status: map['status'] as String? ?? 'pending',
      invitedAt: map['invited_at'] != null
          ? (map['invited_at'] as Timestamp).toDate()
          : null,
      respondedAt: map['responded_at'] != null
          ? (map['responded_at'] as Timestamp).toDate()
          : null,
      responseNotes: map['response_notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'crew_id': crewId,
      'crew_name': crewName,
      'invited_official_id': invitedOfficialId,
      'invited_official_name': invitedOfficialName,
      'invited_by': invitedBy,
      'inviter_name': inviterName,
      'position': position,
      'game_position': gamePosition,
      'sport_name': sportName,
      'level_of_competition': levelOfCompetition,
      'status': status,
      'invited_at': invitedAt != null ? Timestamp.fromDate(invitedAt!) : null,
      'responded_at': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'response_notes': responseNotes,
    };
  }
}

// CrewRepository for v2.0 - connects to Firebase
class CrewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Import the crew endorsement service
  static final CrewEndorsementService _endorsementService = CrewEndorsementService();

  // Get all active crews
  Future<List<Crew>> getAllCrews() async {
    try {
      print('🔍 CREW REPO: Querying crews collection with is_active = true');
      final querySnapshot = await _firestore
          .collection('crews')
          .where('is_active', isEqualTo: true)
          .orderBy('name')
          .get();

      print('✅ CREW REPO: Found ${querySnapshot.docs.length} active crews');
      if (querySnapshot.docs.isNotEmpty) {
        print('📋 CREW REPO: Crew names: ${querySnapshot.docs.map((doc) => doc.data()['name']).toList()}');
      }

      final crews = <Crew>[];
      for (final doc in querySnapshot.docs) {
        final crewData = {...doc.data(), 'id': doc.id};
        final crew = Crew.fromMap(crewData);

        // Load crew members (same as other methods)
        crew.members = await getCrewMembers(crew.id!);

        // Load crew type information
        final crewTypeData = await getCrewTypeById(crew.crewTypeId);
        if (crewTypeData != null) {
          crew.sportName = crewTypeData['sport_name'];
          crew.levelOfCompetition = crewTypeData['level_of_competition'];
          crew.requiredOfficials = crewTypeData['required_officials'];
        }

        // Load endorsement data
        final endorsementCounts = await _endorsementService.getCrewEndorsementCounts(crew.id!);
        crew.athleticDirectorEndorsements = endorsementCounts['athleticDirectorEndorsements'] ?? 0;
        crew.coachEndorsements = endorsementCounts['coachEndorsements'] ?? 0;
        crew.assignerEndorsements = endorsementCounts['assignerEndorsements'] ?? 0;
        crew.totalEndorsements = endorsementCounts['totalEndorsements'] ?? 0;

        // Get crew chief name
        final chiefDoc = await _firestore.collection('users').doc(crew.crewChiefId).get();
        if (chiefDoc.exists && chiefDoc.data() != null) {
          final chiefData = chiefDoc.data()!;
          // Construct full name from profile data
          final profile = chiefData['profile'] as Map<String, dynamic>? ?? {};
          final firstName = profile['firstName'] as String? ?? '';
          final lastName = profile['lastName'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          crew.crewChiefName = fullName.isNotEmpty ? fullName : 'Unknown';
        } else {
          crew.crewChiefName = 'Unknown';
        }

        crews.add(crew);
      }

      print('📋 CREW REPO: Final crew list with members loaded: ${crews.map((c) => '${c.name} (${c.members?.length ?? 0} members)').toList()}');
      return crews;
    } catch (e) {
      print('❌ CREW REPO: Error getting all crews: $e');
      return [];
    }
  }

  // Get crews where user is the crew chief
  Future<List<Crew>> getCrewsWhereChief(String officialId) async {
    try {
      final querySnapshot = await _firestore
          .collection('crews')
          .where('crew_chief_id', isEqualTo: officialId)
          .where('is_active', isEqualTo: true)
          .orderBy('name')
          .get();

      final crews = <Crew>[];
      for (final doc in querySnapshot.docs) {
        final crewData = {...doc.data(), 'id': doc.id};
        final crew = Crew.fromMap(crewData);

        // Load crew members
        crew.members = await getCrewMembers(crew.id!);

          // Load crew type information
          final crewTypeData = await getCrewTypeById(crew.crewTypeId);
          if (crewTypeData != null) {
            crew.sportName = crewTypeData['sport_name'];
            crew.levelOfCompetition = crewTypeData['level_of_competition'];
            crew.requiredOfficials = crewTypeData['required_officials'];
          }

          // Load endorsement data
          final endorsementCounts = await _endorsementService.getCrewEndorsementCounts(crew.id!);
          crew.athleticDirectorEndorsements = endorsementCounts['athleticDirectorEndorsements'] ?? 0;
          crew.coachEndorsements = endorsementCounts['coachEndorsements'] ?? 0;
          crew.assignerEndorsements = endorsementCounts['assignerEndorsements'] ?? 0;
          crew.totalEndorsements = endorsementCounts['totalEndorsements'] ?? 0;

          // Get crew chief name
          final chiefDoc = await _firestore.collection('users').doc(crew.crewChiefId).get();
          if (chiefDoc.exists && chiefDoc.data() != null) {
            final chiefData = chiefDoc.data()!;
            // Construct full name from profile data
            final profile = chiefData['profile'] as Map<String, dynamic>? ?? {};
            final firstName = profile['firstName'] as String? ?? '';
            final lastName = profile['lastName'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();
            crew.crewChiefName = fullName.isNotEmpty ? fullName : 'Unknown';
          } else {
            crew.crewChiefName = 'Unknown';
          }

          crews.add(crew);
      }

      return crews;
    } catch (e) {
      print('Error getting crews where chief: $e');
      return [];
    }
  }

  // Get crews where user is a member
  Future<List<Crew>> getCrewsForOfficial(String officialId) async {
    try {
      // First get crew member records for this official
      final memberQuery = await _firestore
          .collection('crew_members')
          .where('official_id', isEqualTo: officialId)
          .where('status', isEqualTo: 'active')
          .get();

      final crewIds = memberQuery.docs
          .map((doc) => doc.data()['crew_id'] as String)
          .toSet()
          .toList();

      if (crewIds.isEmpty) return [];

      // Get the crew documents
      final crews = <Crew>[];
      for (final crewId in crewIds) {
        final crewDoc = await _firestore.collection('crews').doc(crewId).get();
        if (crewDoc.exists && crewDoc.data() != null) {
          final crewData = {...crewDoc.data()!, 'id': crewDoc.id};
          final crew = Crew.fromMap(crewData);

          // Load crew members
          crew.members = await getCrewMembers(crew.id!);

          // Load crew type information
          final crewTypeData = await getCrewTypeById(crew.crewTypeId);
          if (crewTypeData != null) {
            crew.sportName = crewTypeData['sport_name'];
            crew.levelOfCompetition = crewTypeData['level_of_competition'];
            crew.requiredOfficials = crewTypeData['required_officials'];
          }

          // Load endorsement data
          final endorsementCounts = await _endorsementService.getCrewEndorsementCounts(crew.id!);
          crew.athleticDirectorEndorsements = endorsementCounts['athleticDirectorEndorsements'] ?? 0;
          crew.coachEndorsements = endorsementCounts['coachEndorsements'] ?? 0;
          crew.assignerEndorsements = endorsementCounts['assignerEndorsements'] ?? 0;
          crew.totalEndorsements = endorsementCounts['totalEndorsements'] ?? 0;

          // Get crew chief name
          final chiefDoc = await _firestore.collection('users').doc(crew.crewChiefId).get();
          if (chiefDoc.exists && chiefDoc.data() != null) {
            final chiefData = chiefDoc.data()!;
            // Construct full name from profile data
            final profile = chiefData['profile'] as Map<String, dynamic>? ?? {};
            final firstName = profile['firstName'] as String? ?? '';
            final lastName = profile['lastName'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();
            crew.crewChiefName = fullName.isNotEmpty ? fullName : 'Unknown';
          } else {
            crew.crewChiefName = 'Unknown';
          }

          crews.add(crew);
        }
      }

      return crews;
    } catch (e) {
      print('Error getting crews for official: $e');
      return [];
    }
  }

  // Get crew members for a specific crew
  Future<List<CrewMember>> getCrewMembers(String crewId) async {
    try {
      print('👥 CREW MEMBERS: Loading members for crew $crewId');

      // First, let's see if there are ANY documents in crew_members collection
      final allMembersQuery = await _firestore.collection('crew_members').get();
      print('👥 CREW MEMBERS: Total crew member documents in collection: ${allMembersQuery.docs.length}');

      // Log a few examples
      if (allMembersQuery.docs.isNotEmpty) {
        print('👥 CREW MEMBERS: Sample member docs:');
        for (var i = 0; i < min(3, allMembersQuery.docs.length); i++) {
          final doc = allMembersQuery.docs[i];
          print('👥 CREW MEMBERS: Doc ${doc.id}: crew_id=${doc.data()['crew_id']}, official_id=${doc.data()['official_id']}, status=${doc.data()['status']}');
        }
      }

      final querySnapshot = await _firestore
          .collection('crew_members')
          .where('crew_id', isEqualTo: crewId)
          .where('status', isEqualTo: 'active')
          .orderBy('joined_at')
          .get();

      print('👥 CREW MEMBERS: Found ${querySnapshot.docs.length} member documents for crew $crewId');

      // Log each member document found
      for (final doc in querySnapshot.docs) {
        print('👥 CREW MEMBERS: Member doc ${doc.id}: ${doc.data()}');
      }

      final members = <CrewMember>[];
      for (final doc in querySnapshot.docs) {
        final memberData = {...doc.data(), 'id': doc.id};

        // Get official details
        final officialId = memberData['official_id'] as String;
        final officialDoc = await _firestore.collection('users').doc(officialId).get();
        if (officialDoc.exists && officialDoc.data() != null) {
          final officialData = officialDoc.data()!;
          // Construct full name from profile data
          final profile = officialData['profile'] as Map<String, dynamic>? ?? {};
          final firstName = profile['firstName'] as String? ?? '';
          final lastName = profile['lastName'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          memberData['official_name'] = fullName.isNotEmpty ? fullName : 'Unknown';
          memberData['email'] = officialData['email'] ?? '';
          memberData['phone'] = officialData['phone'] ?? '';
          memberData['city'] = profile['city'] as String?;
          memberData['state'] = profile['state'] as String?;
        }

        members.add(CrewMember.fromMap(memberData));
      }

      return members;
    } catch (e) {
      print('Error getting crew members: $e');
      return [];
    }
  }

  // Get pending invitations for an official
  Future<List<CrewInvitation>> getPendingInvitations(String officialId) async {
    try {
      final querySnapshot = await _firestore
          .collection('crew_invitations')
          .where('invited_official_id', isEqualTo: officialId)
          .where('status', isEqualTo: 'pending')
          .orderBy('invited_at', descending: true)
          .get();

      final invitations = <CrewInvitation>[];
      for (final doc in querySnapshot.docs) {
        final invitationData = {...doc.data(), 'id': doc.id};

        // Get crew details
        final crewId = invitationData['crew_id'] as String;
        final crewDoc = await _firestore.collection('crews').doc(crewId).get();
        if (crewDoc.exists && crewDoc.data() != null) {
          final crewData = crewDoc.data()!;
          invitationData['crew_name'] = crewData['name'] ?? 'Unknown Crew';

          // Get crew type info
          final crewTypeData = await getCrewTypeById(crewData['crew_type_id']);
          if (crewTypeData != null) {
            invitationData['sport_name'] = crewTypeData['sport_name'];
            invitationData['level_of_competition'] = crewTypeData['level_of_competition'];
          }
        }

        // Get inviter details
        final inviterId = invitationData['invited_by'] as String;
        final inviterDoc = await _firestore.collection('users').doc(inviterId).get();
        if (inviterDoc.exists && inviterDoc.data() != null) {
          final inviterData = inviterDoc.data()!;
          // Construct full name from profile data
          final profile = inviterData['profile'] as Map<String, dynamic>? ?? {};
          final firstName = profile['firstName'] as String? ?? '';
          final lastName = profile['lastName'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          invitationData['inviter_name'] = fullName.isNotEmpty ? fullName : 'Unknown';
        }

        invitations.add(CrewInvitation.fromMap(invitationData));
      }

      return invitations;
    } catch (e) {
      print('Error getting pending invitations: $e');
      return [];
    }
  }

  // Get crew invitations for a crew (for crew chief)
  Future<List<CrewInvitation>> getCrewInvitations(String crewId) async {
    try {
      final querySnapshot = await _firestore
          .collection('crew_invitations')
          .where('crew_id', isEqualTo: crewId)
          .where('status', isEqualTo: 'pending')
          .orderBy('invited_at', descending: true)
          .get();

      final invitations = <CrewInvitation>[];
      for (final doc in querySnapshot.docs) {
        final invitationData = {...doc.data(), 'id': doc.id};

        // Get invited official details
        final officialId = invitationData['invited_official_id'] as String;
        final officialDoc = await _firestore.collection('users').doc(officialId).get();
        if (officialDoc.exists && officialDoc.data() != null) {
          final officialData = officialDoc.data()!;
          // Construct full name from profile data
          final profile = officialData['profile'] as Map<String, dynamic>? ?? {};
          final firstName = profile['firstName'] as String? ?? '';
          final lastName = profile['lastName'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          invitationData['invited_official_name'] = fullName.isNotEmpty ? fullName : 'Unknown';
        }

        // Get inviter details
        final inviterId = invitationData['invited_by'] as String;
        final inviterDoc = await _firestore.collection('users').doc(inviterId).get();
        if (inviterDoc.exists && inviterDoc.data() != null) {
          final inviterData = inviterDoc.data()!;
          // Construct full name from profile data
          final profile = inviterData['profile'] as Map<String, dynamic>? ?? {};
          final firstName = profile['firstName'] as String? ?? '';
          final lastName = profile['lastName'] as String? ?? '';
          final fullName = '$firstName $lastName'.trim();
          invitationData['inviter_name'] = fullName.isNotEmpty ? fullName : 'Unknown';
        }

        invitations.add(CrewInvitation.fromMap(invitationData));
      }

      return invitations;
    } catch (e) {
      print('Error getting crew invitations: $e');
      return [];
    }
  }

  // Create a new crew
  Future<String?> createCrew(Crew crew) async {
    try {
      final crewData = crew.toMap();
      crewData.remove('id'); // Remove id for new document
      crewData['created_at'] = FieldValue.serverTimestamp();
      crewData['updated_at'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('crews').add(crewData);
      return docRef.id;
    } catch (e) {
      print('Error creating crew: $e');
      return null;
    }
  }

  // Create crew with members and invitations
  Future<String?> createCrewWithMembersAndInvitations({
    required Crew crew,
    required List<Map<String, dynamic>> selectedMembers,
    required String crewChiefId,
  }) async {
    try {
      print('🏗️ CREW CREATION: Creating crew "${crew.name}" with chief ID: $crewChiefId');
      print('🏗️ CREW CREATION: Crew data: ${crew.toMap()}');

      final batch = _firestore.batch();

      // Create the crew
      final crewRef = _firestore.collection('crews').doc();
      final crewData = crew.toMap();
      crewData['id'] = crewRef.id;
      crewData.remove('id'); // Remove from map since it's the document ID
      crewData['created_at'] = FieldValue.serverTimestamp();
      crewData['updated_at'] = FieldValue.serverTimestamp();

      print('🏗️ CREW CREATION: Final crew data to save: $crewData');
      batch.set(crewRef, crewData);

      // Add crew chief as member
      final chiefMemberRef = _firestore.collection('crew_members').doc();
      batch.set(chiefMemberRef, {
        'crew_id': crewRef.id,
        'official_id': crewChiefId,
        'position': 'crew_chief',
        'game_position': 'Crew Chief',
        'status': 'active',
        'joined_at': FieldValue.serverTimestamp(),
      });

      // Create invitations for selected members
      for (final member in selectedMembers) {
        if (member['id'] != crewChiefId) {
          final invitationRef = _firestore.collection('crew_invitations').doc();
          batch.set(invitationRef, {
            'crew_id': crewRef.id,
            'invited_official_id': member['id'],
            'invited_by': crewChiefId,
            'position': 'member',
            'status': 'pending',
            'invited_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      return crewRef.id;
    } catch (e) {
      print('Error creating crew with members: $e');
      return null;
    }
  }

  // Add crew member
  Future<bool> addCrewMember(String crewId, String officialId, String position, String? gamePosition) async {
    try {
      // Check if crew has space
      final crewDoc = await _firestore.collection('crews').doc(crewId).get();
      if (!crewDoc.exists) return false;

      final crewData = crewDoc.data();
      final crewTypeId = crewData?['crew_type_id'];
      final crewTypeData = await getCrewTypeById(crewTypeId);

      if (crewTypeData != null) {
        final requiredOfficials = crewTypeData['required_officials'] as int;
        final currentMembers = await getCrewMembers(crewId);

        if (currentMembers.length >= requiredOfficials) {
          throw Exception('Crew is already at full capacity ($requiredOfficials members)');
        }
      }

      await _firestore.collection('crew_members').add({
        'crew_id': crewId,
        'official_id': officialId,
        'position': position,
        'game_position': gamePosition,
        'status': 'active',
        'joined_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding crew member: $e');
      return false;
    }
  }

  // Remove crew member
  Future<bool> removeCrewMember(String crewId, String officialId) async {
    try {
      final querySnapshot = await _firestore
          .collection('crew_members')
          .where('crew_id', isEqualTo: crewId)
          .where('official_id', isEqualTo: officialId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'status': 'inactive'});
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error removing crew member: $e');
      return false;
    }
  }

  // Create crew invitation
  Future<bool> createCrewInvitation(CrewInvitation invitation) async {
    try {
      // Check for existing pending invitation
      final existingQuery = await _firestore
          .collection('crew_invitations')
          .where('crew_id', isEqualTo: invitation.crewId)
          .where('invited_official_id', isEqualTo: invitation.invitedOfficialId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingQuery.docs.isNotEmpty) {
        throw Exception('Official already has a pending invitation to this crew');
      }

      // Check if official is already a member
      final memberQuery = await _firestore
          .collection('crew_members')
          .where('crew_id', isEqualTo: invitation.crewId)
          .where('official_id', isEqualTo: invitation.invitedOfficialId)
          .where('status', isEqualTo: 'active')
          .get();

      if (memberQuery.docs.isNotEmpty) {
        throw Exception('Official is already a member of this crew');
      }

      await _firestore.collection('crew_invitations').add(invitation.toMap());
      return true;
    } catch (e) {
      print('Error creating crew invitation: $e');
      return false;
    }
  }

  // Respond to crew invitation
  Future<bool> respondToInvitation(String invitationId, String status, String? notes, String respondingOfficialId) async {
    try {
      final invitationDoc = await _firestore.collection('crew_invitations').doc(invitationId).get();
      if (!invitationDoc.exists) return false;

      final invitationData = invitationDoc.data();
      if (invitationData?['invited_official_id'] != respondingOfficialId) {
        return false; // Not authorized
      }

      final batch = _firestore.batch();

      // Update invitation
      batch.update(invitationDoc.reference, {
        'status': status,
        'responded_at': FieldValue.serverTimestamp(),
        'response_notes': notes,
      });

      // If accepted, add to crew members
      if (status == 'accepted') {
        final crewId = invitationData!['crew_id'];
        final position = invitationData['position'] ?? 'member';
        final gamePosition = invitationData['game_position'];

        print('👥 CREW MEMBERS: Adding member to crew $crewId - official: $respondingOfficialId, position: $position');

        batch.set(_firestore.collection('crew_members').doc(), {
          'crew_id': crewId,
          'official_id': respondingOfficialId,
          'position': position,
          'game_position': gamePosition,
          'status': 'active',
          'joined_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error responding to invitation: $e');
      return false;
    }
  }

  // Check if official is crew chief
  Future<bool> isCrewChief(String officialId, String crewId) async {
    try {
      final doc = await _firestore.collection('crews').doc(crewId).get();
      return doc.exists && doc.data()?['crew_chief_id'] == officialId;
    } catch (e) {
      print('Error checking crew chief: $e');
      return false;
    }
  }

  // ===== CREW MEMBER GAME PREFERENCES METHODS =====

  /// Set a crew member's preference for a game offered to their crew
  Future<bool> setCrewMemberGamePreference(
      String gameId, String crewId, String crewMemberId, String preference) async {
    try {
      final preferenceData = {
        'game_id': gameId,
        'crew_id': crewId,
        'crew_member_id': crewMemberId,
        'preference': preference,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('crew_member_game_preferences')
          .doc('${gameId}_${crewId}_${crewMemberId}')
          .set(preferenceData);

      print('✅ CREW PREFERENCE: Set preference $preference for member $crewMemberId on game $gameId');
      return true;
    } catch (e) {
      print('❌ CREW PREFERENCE: Error setting preference: $e');
      return false;
    }
  }

  /// Get crew member preferences for a specific game and crew
  Future<List<Map<String, dynamic>>> getCrewMemberPreferencesForGame(
      String gameId, String crewId) async {
    try {
      final querySnapshot = await _firestore
          .collection('crew_member_game_preferences')
          .where('game_id', isEqualTo: gameId)
          .where('crew_id', isEqualTo: crewId)
          .orderBy('updated_at', descending: true)
          .get();

      final preferences = <Map<String, dynamic>>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Get member name
        final memberId = data['crew_member_id'] as String;
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          final profile = userData['profile'] as Map<String, dynamic>? ?? {};
          final firstName = profile['firstName'] as String? ?? '';
          final lastName = profile['lastName'] as String? ?? '';
          data['member_name'] = '$firstName $lastName'.trim();
        } else {
          data['member_name'] = 'Unknown';
        }
        preferences.add(data);
      }

      print('✅ CREW PREFERENCE: Found ${preferences.length} preferences for game $gameId, crew $crewId');
      return preferences;
    } catch (e) {
      print('❌ CREW PREFERENCE: Error getting preferences: $e');
      return [];
    }
  }

  /// Get a crew member's preference for a specific game
  Future<String?> getCrewMemberPreference(
      String gameId, String crewId, String crewMemberId) async {
    try {
      final doc = await _firestore
          .collection('crew_member_game_preferences')
          .doc('${gameId}_${crewId}_${crewMemberId}')
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['preference'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ CREW PREFERENCE: Error getting preference: $e');
      return null;
    }
  }

  /// Get crew member preference summary for a game (counts of thumbs up/down)
  Future<Map<String, int>> getCrewMemberPreferenceSummary(String gameId, String crewId) async {
    try {
      final preferences = await getCrewMemberPreferencesForGame(gameId, crewId);
      final summary = <String, int>{
        'thumbs_up': 0,
        'thumbs_down': 0,
        'neutral': 0,
      };

      for (final pref in preferences) {
        final preference = pref['preference'] as String? ?? 'neutral';
        summary[preference] = (summary[preference] ?? 0) + 1;
      }

      print('✅ CREW PREFERENCE: Summary for game $gameId, crew $crewId: $summary');
      print('✅ CREW PREFERENCE: Preferences list: $preferences');
      return summary;
    } catch (e) {
      print('❌ CREW PREFERENCE: Error getting summary: $e');
      return {'thumbs_up': 0, 'thumbs_down': 0, 'neutral': 0};
    }
  }

  // Get crew by ID
  Future<Crew?> getCrewById(String crewId) async {
    try {
      final doc = await _firestore.collection('crews').doc(crewId).get();
      if (!doc.exists || doc.data() == null) return null;

      final crewData = {...doc.data()!, 'id': doc.id};
      final crew = Crew.fromMap(crewData);

      // Load additional data
      crew.members = await getCrewMembers(crewId);

      final crewTypeData = await getCrewTypeById(crew.crewTypeId);
      if (crewTypeData != null) {
        crew.sportName = crewTypeData['sport_name'];
        crew.levelOfCompetition = crewTypeData['level_of_competition'];
        crew.requiredOfficials = crewTypeData['required_officials'];
      }

      // Get crew chief name
      print('👤 CREW LOADING: Loading crew chief name for crew ${crew.id}, chief ID: ${crew.crewChiefId}');
      final chiefDoc = await _firestore.collection('users').doc(crew.crewChiefId).get();
      print('👤 CREW LOADING: Chief doc exists: ${chiefDoc.exists}');

      if (chiefDoc.exists && chiefDoc.data() != null) {
        final chiefData = chiefDoc.data()!;
        print('👤 CREW LOADING: Chief data: $chiefData');

        // Construct full name from profile data
        final profile = chiefData['profile'] as Map<String, dynamic>? ?? {};
        final firstName = profile['firstName'] as String? ?? '';
        final lastName = profile['lastName'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        print('👤 CREW LOADING: Chief name: first="$firstName", last="$lastName", full="$fullName"');

        crew.crewChiefName = fullName.isNotEmpty ? fullName : 'Unknown';
      } else {
        print('👤 CREW LOADING: Chief document not found or empty');
        crew.crewChiefName = 'Unknown';
      }

      // Load endorsement data
      final endorsementCounts = await _endorsementService.getCrewEndorsementCounts(crewId);
      crew.athleticDirectorEndorsements = endorsementCounts['athleticDirectorEndorsements'] ?? 0;
      crew.coachEndorsements = endorsementCounts['coachEndorsements'] ?? 0;
      crew.assignerEndorsements = endorsementCounts['assignerEndorsements'] ?? 0;
      crew.totalEndorsements = endorsementCounts['totalEndorsements'] ?? 0;

      return crew;
    } catch (e) {
      print('Error getting crew by ID: $e');
      return null;
    }
  }

  // Get crew type by ID
  Future<Map<String, dynamic>?> getCrewTypeById(int crewTypeId) async {
    try {
      final doc = await _firestore.collection('crew_types').doc(crewTypeId.toString()).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Get sport name
        final sportId = data['sport_id'];
        final sportDoc = await _firestore.collection('sports').doc(sportId.toString()).get();
        if (sportDoc.exists && sportDoc.data() != null) {
          data['sport_name'] = sportDoc.data()!['name'] ?? 'Unknown Sport';
        }
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting crew type: $e');
      return null;
    }
  }


  // Get all crew types
  Future<List<Map<String, dynamic>>> getAllCrewTypes() async {
    try {
      print('🔍 CREW MODEL: Querying crew_types collection');
      final querySnapshot = await _firestore.collection('crew_types').get();
      print('✅ CREW MODEL: Found ${querySnapshot.docs.length} documents in crew_types collection');
      final crewTypes = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = {...doc.data(), 'id': int.parse(doc.id)};

        // Get sport name
        final sportId = data['sport_id'];
        final sportDoc = await _firestore.collection('sports').doc(sportId.toString()).get();
        if (sportDoc.exists && sportDoc.data() != null) {
          data['sport_name'] = sportDoc.data()!['name'] ?? 'Unknown Sport';
        }

        crewTypes.add(data);
      }

      return crewTypes;
    } catch (e) {
      print('Error getting crew types: $e');
      return [];
    }
  }

  // Save default crew types to database
  Future<void> saveDefaultCrewTypes(List<Map<String, dynamic>> crewTypes) async {
    try {
      final batch = _firestore.batch();

      for (final crewType in crewTypes) {
        final docId = crewType['id'].toString();
        final data = Map<String, dynamic>.from(crewType);
        data.remove('id'); // Remove id from data since it's the document ID
        batch.set(_firestore.collection('crew_types').doc(docId), data);
      }

      await batch.commit();
      print('✅ CREW TYPES: Successfully saved ${crewTypes.length} crew types to database');
    } catch (e) {
      print('Error saving default crew types: $e');
      rethrow;
    }
  }

  // Get crew types by sport
  Future<List<Map<String, dynamic>>> getCrewTypesBySport(int sportId) async {
    try {
      final querySnapshot = await _firestore
          .collection('crew_types')
          .where('sport_id', isEqualTo: sportId)
          .orderBy('required_officials')
          .get();

      final crewTypes = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = {...doc.data(), 'id': int.parse(doc.id)};

        // Get sport name
        final sportDoc = await _firestore.collection('sports').doc(sportId.toString()).get();
        if (sportDoc.exists && sportDoc.data() != null) {
          data['sport_name'] = sportDoc.data()!['name'] ?? 'Unknown Sport';
        }

        crewTypes.add(data);
      }

      return crewTypes;
    } catch (e) {
      print('Error getting crew types by sport: $e');
      return [];
    }
  }

  // Get all sports
  Future<List<Map<String, dynamic>>> getAllSports() async {
    try {
      final querySnapshot = await _firestore.collection('sports').get();
      return querySnapshot.docs.map((doc) {
        return {...doc.data(), 'id': int.parse(doc.id)};
      }).toList();
    } catch (e) {
      print('Error getting sports: $e');
      return [];
    }
  }

  // Update crew competition levels
  Future<bool> updateCrewCompetitionLevels(String crewId, List<String> competitionLevels) async {
    try {
      await _firestore.collection('crews').doc(crewId).update({
        'competition_levels': competitionLevels.join(','),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating crew competition levels: $e');
      return false;
    }
  }

  // Delete crew
  Future<bool> deleteCrew(String crewId, String crewChiefId) async {
    try {
      print('🗑️ CREW DELETE: Attempting to delete crew $crewId by user $crewChiefId');

      // Verify crew chief
      final isChief = await isCrewChief(crewChiefId, crewId);
      print('🗑️ CREW DELETE: Is user crew chief? $isChief');

      if (!isChief) {
        print('🗑️ CREW DELETE: User is not crew chief, cannot delete');
        return false;
      }

      // Check for active assignments
      final assignmentsQuery = await _firestore
          .collection('crew_assignments')
          .where('crew_id', isEqualTo: crewId)
          .where('status', isEqualTo: 'accepted')
          .get();

      print('🗑️ CREW DELETE: Found ${assignmentsQuery.docs.length} accepted assignments');

      if (assignmentsQuery.docs.isNotEmpty) {
        print('🗑️ CREW DELETE: Cannot delete crew with active assignments');
        throw Exception('Cannot delete crew with accepted game assignments');
      }

      final batch = _firestore.batch();

      // Delete crew invitations
      final invitationsQuery = await _firestore
          .collection('crew_invitations')
          .where('crew_id', isEqualTo: crewId)
          .get();
      for (final doc in invitationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete crew members
      final membersQuery = await _firestore
          .collection('crew_members')
          .where('crew_id', isEqualTo: crewId)
          .get();
      for (final doc in membersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete crew availability
      final availabilityQuery = await _firestore
          .collection('crew_availability')
          .where('crew_id', isEqualTo: crewId)
          .get();
      for (final doc in availabilityQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete pending crew assignments
      final pendingAssignmentsQuery = await _firestore
          .collection('crew_assignments')
          .where('crew_id', isEqualTo: crewId)
          .where('status', whereIn: ['pending', 'declined'])
          .get();
      for (final doc in pendingAssignmentsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete the crew
      batch.delete(_firestore.collection('crews').doc(crewId));

      await batch.commit();
      print('🗑️ CREW DELETE: Successfully deleted crew $crewId');
      return true;
    } catch (e) {
      print('Error deleting crew: $e');
      return false;
    }
  }

  // Get filtered crews for game assignment
  Future<List<Crew>> getFilteredCrews({
    List<String>? ihsaCertifications,
    List<String>? competitionLevels,
    List<String>? crewSizes,
    int? maxDistanceMiles,
    Map<String, dynamic>? gameLocation,
  }) async {
    try {
      // Start with all active crews
      final allCrews = await getAllCrews();
      List<Crew> filteredCrews = List.from(allCrews);

      print('🎯 CREW FILTERING: Starting with ${allCrews.length} crews');
      print('🎯 CREW FILTERING: Filters - IHSA: $ihsaCertifications, Levels: $competitionLevels, Sizes: $crewSizes, Distance: $maxDistanceMiles');

      // Filter by IHSA certification level
      if (ihsaCertifications != null && ihsaCertifications.isNotEmpty) {
        print('🎯 CREW FILTERING: Applying IHSA certification filter');
        filteredCrews = await _filterByCertification(filteredCrews, ihsaCertifications);
        print('🎯 CREW FILTERING: After IHSA filter: ${filteredCrews.length} crews');
      }

      // Filter by competition levels
      if (competitionLevels != null && competitionLevels.isNotEmpty) {
        print('🎯 CREW FILTERING: Applying competition level filter: $competitionLevels');
        filteredCrews = filteredCrews.where((crew) {
          print('🎯 CREW FILTERING: Checking crew ${crew.name} - levels: ${crew.competitionLevels}');
          if (crew.competitionLevels == null || crew.competitionLevels!.isEmpty) {
            print('🎯 CREW FILTERING: Crew ${crew.name} has no competition levels');
            return false;
          }
          final hasMatchingLevel = crew.competitionLevels!.any((level) => competitionLevels.contains(level));
          print('🎯 CREW FILTERING: Crew ${crew.name} has matching level: $hasMatchingLevel');
          return hasMatchingLevel;
        }).toList();
        print('🎯 CREW FILTERING: After competition filter: ${filteredCrews.length} crews');
      }

      // Filter by crew size
      if (crewSizes != null && crewSizes.isNotEmpty) {
        print('🎯 CREW FILTERING: Applying crew size filter: $crewSizes');
        filteredCrews = filteredCrews.where((crew) {
          final memberCount = crew.members?.length ?? 0;
          final requiredCount = crew.requiredOfficials ?? 0;
          print('🎯 CREW FILTERING: Crew ${crew.name} - members: $memberCount, required: $requiredCount');

          // Check if the crew size matches any of the selected sizes
          for (final sizeFilter in crewSizes) {
            // Parse the size filter (e.g., "5-person crew" -> 5)
            final sizeMatch = RegExp(r'(\d+)-person crew').firstMatch(sizeFilter);
            if (sizeMatch != null) {
              final targetSize = int.parse(sizeMatch.group(1)!);
              final matches = memberCount == targetSize && memberCount == requiredCount;
              print('🎯 CREW FILTERING: Crew ${crew.name} - checking size $targetSize, matches: $matches');
              if (matches) {
                return true;
              }
            }
          }
          return false;
        }).toList();
        print('🎯 CREW FILTERING: After crew size filter: ${filteredCrews.length} crews');
      }

      // Filter by distance
      if (maxDistanceMiles != null && gameLocation != null) {
        filteredCrews = await _filterByDistance(filteredCrews, maxDistanceMiles, gameLocation);
      }

      // Only return crews that can be hired (fully staffed and active)
      final originalCount = filteredCrews.length;
      filteredCrews = filteredCrews.where((crew) => crew.canBeHired).toList();
      print('🎯 CREW FILTERING: After canBeHired filter: ${filteredCrews.length}/${originalCount} crews');
      print('🎯 CREW FILTERING: Final result: ${filteredCrews.map((c) => c.name).toList()}');

      return filteredCrews;
    } catch (e) {
      print('Error filtering crews: $e');
      return [];
    }
  }

  // Helper method to filter crews by certification level
  Future<List<Crew>> _filterByCertification(List<Crew> crews, List<String> requiredCertifications) async {
    final filteredCrews = <Crew>[];

    // Get the minimum certification level required
    String minRequiredLevel = _getMinRequiredCertificationLevel(requiredCertifications);
    print('🎯 CREW FILTERING: Minimum required certification level: $minRequiredLevel');

    for (final crew in crews) {
      if (crew.members == null || crew.members!.isEmpty) {
        print('🎯 CREW FILTERING: Crew ${crew.name} has no members, skipping');
        continue;
      }

      print('🎯 CREW FILTERING: Checking crew ${crew.name} with ${crew.members!.length} members');

      // Check if all crew members meet or exceed this certification level
      bool allMembersQualified = true;

      for (final member in crew.members!) {
        final memberCertification = await _getOfficialCertificationLevel(member.officialId);
        final meetsRequirement = _meetsCertificationRequirement(memberCertification, minRequiredLevel);
        print('🎯 CREW FILTERING: Member ${member.officialName} - cert: $memberCertification, meets: $meetsRequirement');

        if (!meetsRequirement) {
          allMembersQualified = false;
          break;
        }
      }

      print('🎯 CREW FILTERING: Crew ${crew.name} - all members qualified: $allMembersQualified');

      if (allMembersQualified) {
        filteredCrews.add(crew);
      }
    }

    return filteredCrews;
  }

  // Helper method to filter crews by distance
  Future<List<Crew>> _filterByDistance(List<Crew> crews, int maxDistanceMiles, Map<String, dynamic> gameLocation) async {
    final filteredCrews = <Crew>[];

    for (final crew in crews) {
      final crewChiefAddress = await _getCrewChiefAddress(crew.crewChiefId);
      if (crewChiefAddress == null) continue;

      // Simple distance calculation (in a real app, you'd use geocoding and proper distance calculation)
      // For now, we'll do a basic approximation
      final distance = _calculateApproximateDistance(crewChiefAddress, gameLocation);

      if (distance <= maxDistanceMiles) {
        filteredCrews.add(crew);
      }
    }

    return filteredCrews;
  }

  // Get the minimum required certification level from the filter
  String _getMinRequiredCertificationLevel(List<String> certifications) {
    // Order: Registered < Recognized < Certified
    if (certifications.contains('IHSA Certified')) {
      return 'Certified';
    } else if (certifications.contains('IHSA Recognized')) {
      return 'Recognized';
    } else if (certifications.contains('IHSA Registered')) {
      return 'Registered';
    }
    return 'Registered'; // Default
  }

  // Check if a certification level meets the requirement
  bool _meetsCertificationRequirement(String? actualLevel, String requiredLevel) {
    if (actualLevel == null) return false;

    // Normalize the actual level by removing "IHSA " prefix if present
    String normalizedActual = actualLevel;
    if (actualLevel.startsWith('IHSA ')) {
      normalizedActual = actualLevel.substring(5); // Remove "IHSA " prefix
    }

    final levels = ['Registered', 'Recognized', 'Certified'];
    final actualIndex = levels.indexOf(normalizedActual);
    final requiredIndex = levels.indexOf(requiredLevel);

    return actualIndex >= requiredIndex;
  }

  // Get official's certification level
  Future<String?> _getOfficialCertificationLevel(String officialId) async {
    try {
      final doc = await _firestore.collection('users').doc(officialId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final officialProfile = data['officialProfile'] as Map<String, dynamic>?;
        return officialProfile?['certificationLevel'] as String?;
      }
    } catch (e) {
      print('Error getting official certification: $e');
    }
    return null;
  }

  // Get crew chief's address
  Future<Map<String, dynamic>?> _getCrewChiefAddress(String crewChiefId) async {
    try {
      final doc = await _firestore.collection('users').doc(crewChiefId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final profile = data['profile'] as Map<String, dynamic>?;
        final schedulerProfile = data['schedulerProfile'] as Map<String, dynamic>?;

        // Try to get address from scheduler profile first, then basic profile
        if (schedulerProfile != null && schedulerProfile['homeAddress'] != null) {
          return schedulerProfile['homeAddress'] as Map<String, dynamic>;
        } else if (profile != null && profile['city'] != null) {
          return {
            'city': profile['city'],
            'state': profile['state'],
            'address': profile['address'],
          };
        }
      }
    } catch (e) {
      print('Error getting crew chief address: $e');
    }
    return null;
  }

  // Simple distance calculation (approximation)
  double _calculateApproximateDistance(Map<String, dynamic> address1, Map<String, dynamic> address2) {
    // This is a very basic approximation - in production, you'd use proper geocoding
    // For now, return a random distance between 0-100 miles for testing
    // Replace with actual distance calculation using lat/lng coordinates

    final city1 = address1['city']?.toString().toLowerCase() ?? '';
    final city2 = address2['city']?.toString().toLowerCase() ?? '';

    // If same city, assume 0 miles
    if (city1 == city2 && city1.isNotEmpty) {
      return 0.0;
    }

    // Same state, assume 25-75 miles
    final state1 = address1['state']?.toString().toLowerCase() ?? '';
    final state2 = address2['state']?.toString().toLowerCase() ?? '';
    if (state1 == state2 && state1.isNotEmpty) {
      return 25.0 + (50.0 * (city1.hashCode % 100) / 100); // Pseudo-random distance
    }

    // Different states, assume 50-150 miles
    return 50.0 + (100.0 * ((city1 + city2).hashCode % 100) / 100);
  }
}
