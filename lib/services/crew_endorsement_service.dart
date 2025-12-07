import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firebase_constants.dart';

/// Service for managing crew endorsements
/// Only schedulers (Coaches, Assigners, ADs) can endorse crews
class CrewEndorsementService {
  // Singleton pattern
  static final CrewEndorsementService _instance = CrewEndorsementService._internal();
  CrewEndorsementService._internal();
  factory CrewEndorsementService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection name for crew endorsements
  static const String _crewEndorsementsCollection = 'crew_endorsements';

  /// Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Add an endorsement to a crew
  /// [endorsedCrewId] - The crew ID being endorsed
  /// Only schedulers can endorse crews
  Future<void> addCrewEndorsement({
    required String endorsedCrewId,
  }) async {
    final endorserUserId = currentUserId;
    if (endorserUserId == null) {
      throw Exception('User not logged in');
    }

    // Verify the current user is a scheduler
    final userDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(endorserUserId)
        .get();

    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    final userData = userDoc.data()!;
    final userRole = userData['role'] as String?;

    if (userRole != 'scheduler') {
      throw Exception('Only schedulers can endorse crews');
    }

    // Check if already endorsed
    final hasEndorsed = await hasUserEndorsedCrew(endorsedCrewId);
    if (hasEndorsed) {
      throw Exception('You have already endorsed this crew');
    }

    // Get scheduler type for the endorsement record
    final schedulerProfile = userData['schedulerProfile'] as Map<String, dynamic>?;
    final schedulerType = schedulerProfile?['type'] as String? ?? 'scheduler';

    // Create endorsement document
    final endorsementData = {
      'endorsedCrewId': endorsedCrewId,
      'endorserUserId': endorserUserId,
      'schedulerType': schedulerType, // 'Athletic Director', 'Coach', or 'Assigner'
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add to crew endorsements collection
    await _firestore.collection(_crewEndorsementsCollection).add(endorsementData);

    // Update the crew's endorsement counts
    await _updateCrewEndorsementCounts(endorsedCrewId);
  }

  /// Remove an endorsement from a crew
  Future<void> removeCrewEndorsement({
    required String endorsedCrewId,
  }) async {
    final endorserUserId = currentUserId;
    if (endorserUserId == null) {
      throw Exception('User not logged in');
    }

    // Find and delete the endorsement document
    final query = await _firestore
        .collection(_crewEndorsementsCollection)
        .where('endorsedCrewId', isEqualTo: endorsedCrewId)
        .where('endorserUserId', isEqualTo: endorserUserId)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No endorsement found to remove');
    }

    // Delete the endorsement
    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    // Update the crew's endorsement counts
    await _updateCrewEndorsementCounts(endorsedCrewId);
  }

  /// Check if the current user has endorsed a crew
  Future<bool> hasUserEndorsedCrew(String endorsedCrewId) async {
    final endorserUserId = currentUserId;
    if (endorserUserId == null) return false;

    final query = await _firestore
        .collection(_crewEndorsementsCollection)
        .where('endorsedCrewId', isEqualTo: endorsedCrewId)
        .where('endorserUserId', isEqualTo: endorserUserId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Get endorsement counts for a crew
  Future<Map<String, int>> getCrewEndorsementCounts(String crewId) async {
    try {
      final allEndorsements = await _firestore
          .collection(_crewEndorsementsCollection)
          .where('endorsedCrewId', isEqualTo: crewId)
          .get();

      int athleticDirectorCount = 0;
      int coachCount = 0;
      int assignerCount = 0;
      int totalCount = 0;

      for (var doc in allEndorsements.docs) {
        final data = doc.data();
        final schedulerType = data['schedulerType'] as String?;
        totalCount++;

        if (schedulerType == 'Athletic Director') {
          athleticDirectorCount++;
        } else if (schedulerType == 'Coach') {
          coachCount++;
        } else if (schedulerType == 'Assigner') {
          assignerCount++;
        }
      }

      return {
        'athleticDirectorEndorsements': athleticDirectorCount,
        'coachEndorsements': coachCount,
        'assignerEndorsements': assignerCount,
        'totalEndorsements': totalCount,
      };
    } catch (e) {
      print('Error getting crew endorsement counts: $e');
      return {
        'athleticDirectorEndorsements': 0,
        'coachEndorsements': 0,
        'assignerEndorsements': 0,
        'totalEndorsements': 0,
      };
    }
  }

  /// Get list of endorsers for a crew
  Future<List<Map<String, dynamic>>> getCrewEndorsers(
    String crewId, {
    String? schedulerType,
  }) async {
    try {
      Query query = _firestore
          .collection(_crewEndorsementsCollection)
          .where('endorsedCrewId', isEqualTo: crewId);

      if (schedulerType != null) {
        query = query.where('schedulerType', isEqualTo: schedulerType);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      List<Map<String, dynamic>> endorsers = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final endorserUserId = data['endorserUserId'] as String?;

        if (endorserUserId != null) {
          // Fetch endorser's name from users collection
          final userDoc = await _firestore
              .collection(FirebaseCollections.users)
              .doc(endorserUserId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final profile = userData['profile'] as Map<String, dynamic>? ?? {};
            final firstName = profile['firstName'] ?? '';
            final lastName = profile['lastName'] ?? '';

            endorsers.add({
              'id': endorserUserId,
              'name': '$firstName $lastName'.trim(),
              'schedulerType': data['schedulerType'],
              'date': (data['createdAt'] as Timestamp?)?.toDate(),
            });
          }
        }
      }

      return endorsers;
    } catch (e) {
      print('Error getting crew endorsers: $e');
      return [];
    }
  }

  /// Update the endorsement counts in the crew document
  Future<void> _updateCrewEndorsementCounts(String crewId) async {
    try {
      final counts = await getCrewEndorsementCounts(crewId);

      await _firestore
          .collection('crews')
          .doc(crewId)
          .update({
        'athleticDirectorEndorsements': counts['athleticDirectorEndorsements'],
        'coachEndorsements': counts['coachEndorsements'],
        'assignerEndorsements': counts['assignerEndorsements'],
        'totalEndorsements': counts['totalEndorsements'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating crew endorsement counts: $e');
    }
  }

  /// Stream of endorsement counts for real-time updates
  Stream<Map<String, int>> watchCrewEndorsementCounts(String crewId) {
    return _firestore
        .collection(_crewEndorsementsCollection)
        .where('endorsedCrewId', isEqualTo: crewId)
        .snapshots()
        .map((snapshot) {
      int athleticDirectorCount = 0;
      int coachCount = 0;
      int assignerCount = 0;
      int totalCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final schedulerType = data['schedulerType'] as String?;
        totalCount++;

        if (schedulerType == 'Athletic Director') {
          athleticDirectorCount++;
        } else if (schedulerType == 'Coach') {
          coachCount++;
        } else if (schedulerType == 'Assigner') {
          assignerCount++;
        }
      }

      return {
        'athleticDirectorEndorsements': athleticDirectorCount,
        'coachEndorsements': coachCount,
        'assignerEndorsements': assignerCount,
        'totalEndorsements': totalCount,
      };
    });
  }
}
