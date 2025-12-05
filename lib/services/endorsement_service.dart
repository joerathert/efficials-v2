import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firebase_constants.dart';

/// Service for managing official endorsements
/// Endorsements can be given by schedulers or other officials
class EndorsementService {
  // Singleton pattern
  static final EndorsementService _instance = EndorsementService._internal();
  EndorsementService._internal();
  factory EndorsementService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection name for endorsements
  static const String _endorsementsCollection = 'endorsements';

  /// Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Add an endorsement to an official
  /// [endorsedOfficialId] - The user ID of the official being endorsed
  /// [endorserType] - Either 'scheduler' or 'official'
  Future<void> addEndorsement({
    required String endorsedOfficialId,
    required String endorserType,
  }) async {
    final endorserUserId = currentUserId;
    if (endorserUserId == null) {
      throw Exception('User not logged in');
    }

    // Prevent self-endorsement
    if (endorserUserId == endorsedOfficialId) {
      throw Exception('You cannot endorse yourself');
    }

    // Check if already endorsed
    final hasEndorsed = await hasUserEndorsedOfficial(endorsedOfficialId);
    if (hasEndorsed) {
      throw Exception('You have already endorsed this official');
    }

    // Create endorsement document
    final endorsementData = {
      'endorsedOfficialId': endorsedOfficialId,
      'endorserUserId': endorserUserId,
      'endorserType': endorserType, // 'scheduler' or 'official'
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add to endorsements collection
    await _firestore.collection(_endorsementsCollection).add(endorsementData);

    // Update the endorsed official's endorsement counts
    await _updateEndorsementCounts(endorsedOfficialId);
  }

  /// Remove an endorsement from an official
  Future<void> removeEndorsement({
    required String endorsedOfficialId,
  }) async {
    final endorserUserId = currentUserId;
    if (endorserUserId == null) {
      throw Exception('User not logged in');
    }

    // Find and delete the endorsement document
    final query = await _firestore
        .collection(_endorsementsCollection)
        .where('endorsedOfficialId', isEqualTo: endorsedOfficialId)
        .where('endorserUserId', isEqualTo: endorserUserId)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No endorsement found to remove');
    }

    // Delete the endorsement
    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    // Update the endorsed official's endorsement counts
    await _updateEndorsementCounts(endorsedOfficialId);
  }

  /// Check if the current user has endorsed an official
  Future<bool> hasUserEndorsedOfficial(String endorsedOfficialId) async {
    final endorserUserId = currentUserId;
    if (endorserUserId == null) return false;

    final query = await _firestore
        .collection(_endorsementsCollection)
        .where('endorsedOfficialId', isEqualTo: endorsedOfficialId)
        .where('endorserUserId', isEqualTo: endorserUserId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Get endorsement counts for an official
  Future<Map<String, int>> getEndorsementCounts(String officialId) async {
    try {
      final allEndorsements = await _firestore
          .collection(_endorsementsCollection)
          .where('endorsedOfficialId', isEqualTo: officialId)
          .get();

      int schedulerCount = 0;
      int officialCount = 0;

      for (var doc in allEndorsements.docs) {
        final data = doc.data();
        final endorserType = data['endorserType'] as String?;
        if (endorserType == 'scheduler') {
          schedulerCount++;
        } else if (endorserType == 'official') {
          officialCount++;
        }
      }

      return {
        'schedulerEndorsements': schedulerCount,
        'officialEndorsements': officialCount,
      };
    } catch (e) {
      print('Error getting endorsement counts: $e');
      return {
        'schedulerEndorsements': 0,
        'officialEndorsements': 0,
      };
    }
  }

  /// Get list of endorsers for an official
  Future<List<Map<String, dynamic>>> getEndorsersForOfficial(
    String officialId, {
    String? endorserType,
  }) async {
    try {
      Query query = _firestore
          .collection(_endorsementsCollection)
          .where('endorsedOfficialId', isEqualTo: officialId);

      if (endorserType != null) {
        query = query.where('endorserType', isEqualTo: endorserType);
      }

      final snapshot = await query.get();

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
              'type': data['endorserType'],
              'date': (data['createdAt'] as Timestamp?)?.toDate(),
            });
          }
        }
      }

      return endorsers;
    } catch (e) {
      print('Error getting endorsers: $e');
      return [];
    }
  }

  /// Update the endorsement counts in the user's document
  Future<void> _updateEndorsementCounts(String officialId) async {
    try {
      final counts = await getEndorsementCounts(officialId);

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .update({
        'officialProfile.schedulerEndorsements': counts['schedulerEndorsements'],
        'officialProfile.officialEndorsements': counts['officialEndorsements'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating endorsement counts: $e');
    }
  }

  /// Stream of endorsement counts for real-time updates
  Stream<Map<String, int>> watchEndorsementCounts(String officialId) {
    return _firestore
        .collection(_endorsementsCollection)
        .where('endorsedOfficialId', isEqualTo: officialId)
        .snapshots()
        .map((snapshot) {
      int schedulerCount = 0;
      int officialCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final endorserType = data['endorserType'] as String?;
        if (endorserType == 'scheduler') {
          schedulerCount++;
        } else if (endorserType == 'official') {
          officialCount++;
        }
      }

      return {
        'schedulerEndorsements': schedulerCount,
        'officialEndorsements': officialCount,
      };
    });
  }
}

