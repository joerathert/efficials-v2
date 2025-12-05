import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../constants/firebase_constants.dart';

/// Service for admin operations
/// Provides functionality to manage users, reset stats, and log admin actions
class AdminService {
  // Singleton pattern
  static final AdminService _instance = AdminService._internal();
  AdminService._internal();
  factory AdminService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection names
  static const String _auditLogCollection = 'admin_audit_log';
  static const String _backOutsCollection = 'back_outs';

  /// Check if current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        return false;
      }

      // Small delay to ensure auth is fully synced
      await Future.delayed(const Duration(milliseconds: 500));

      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();

      final isAdminValue = data?['isAdmin'];

      // Handle potential type issues (e.g., if stored as int 1/0)
      final isAdmin = (isAdminValue is bool && isAdminValue) ||
                      (isAdminValue is int && isAdminValue == 1) ||
                      isAdminValue == 'true';

      return isAdmin;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final queryLower = query.toLowerCase().trim();

      // Get all users and filter in memory
      // (Firestore doesn't support case-insensitive or partial text search natively)
      final snapshot =
          await _firestore.collection(FirebaseCollections.users).get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) {
        final fullName = user.fullName.toLowerCase();
        final email = user.email.toLowerCase();
        return fullName.contains(queryLower) || email.contains(queryLower);
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Get all users (paginated)
  Future<List<UserModel>> getAllUsers({int limit = 50, String? lastUserId}) async {
    try {
      Query query = _firestore
          .collection(FirebaseCollections.users)
          .orderBy('profile.firstName')
          .limit(limit);

      if (lastUserId != null) {
        final lastDoc = await _firestore
            .collection(FirebaseCollections.users)
            .doc(lastUserId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Get all officials only
  Future<List<UserModel>> getAllOfficials() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('role', isEqualTo: 'official')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting officials: $e');
      return [];
    }
  }

  /// Reset an official's follow-through stats
  Future<bool> resetFollowThroughStats(String officialId, String reason) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Not authenticated');

      // Get current stats before reset (for audit log)
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .get();

      if (!userDoc.exists) throw Exception('User not found');

      final currentData = userDoc.data()!;
      final officialProfile = currentData['officialProfile'] as Map<String, dynamic>?;

      final previousStats = {
        'followThroughRate': officialProfile?['followThroughRate'] ?? 100.0,
        'totalAcceptedGames': officialProfile?['totalAcceptedGames'] ?? 0,
        'totalBackedOutGames': officialProfile?['totalBackedOutGames'] ?? 0,
      };

      // Reset the stats
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .update({
        'officialProfile.followThroughRate': 100.0,
        'officialProfile.totalAcceptedGames': 0,
        'officialProfile.totalBackedOutGames': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete all backouts for this user
      final backouts = await _firestore
          .collection(_backOutsCollection)
          .where('officialId', isEqualTo: officialId)
          .get();

      for (var doc in backouts.docs) {
        await doc.reference.delete();
      }

      // Log the action
      await _logAdminAction(
        action: 'RESET_FOLLOW_THROUGH',
        targetUserId: officialId,
        reason: reason,
        previousData: previousStats,
        newData: {
          'followThroughRate': 100.0,
          'totalAcceptedGames': 0,
          'totalBackedOutGames': 0,
          'backoutsDeleted': backouts.docs.length,
        },
      );

      return true;
    } catch (e) {
      print('Error resetting follow-through stats: $e');
      return false;
    }
  }

  /// Update an official's stats manually
  Future<bool> updateOfficialStats({
    required String officialId,
    required double followThroughRate,
    required int totalAcceptedGames,
    required int totalBackedOutGames,
    required String reason,
  }) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Not authenticated');

      // Get current stats before update (for audit log)
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .get();

      if (!userDoc.exists) throw Exception('User not found');

      final currentData = userDoc.data()!;
      final officialProfile = currentData['officialProfile'] as Map<String, dynamic>?;

      final previousStats = {
        'followThroughRate': officialProfile?['followThroughRate'] ?? 100.0,
        'totalAcceptedGames': officialProfile?['totalAcceptedGames'] ?? 0,
        'totalBackedOutGames': officialProfile?['totalBackedOutGames'] ?? 0,
      };

      // Update the stats
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .update({
        'officialProfile.followThroughRate': followThroughRate,
        'officialProfile.totalAcceptedGames': totalAcceptedGames,
        'officialProfile.totalBackedOutGames': totalBackedOutGames,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log the action
      await _logAdminAction(
        action: 'UPDATE_OFFICIAL_STATS',
        targetUserId: officialId,
        reason: reason,
        previousData: previousStats,
        newData: {
          'followThroughRate': followThroughRate,
          'totalAcceptedGames': totalAcceptedGames,
          'totalBackedOutGames': totalBackedOutGames,
        },
      );

      return true;
    } catch (e) {
      print('Error updating official stats: $e');
      return false;
    }
  }

  /// Reset an official's endorsements
  Future<bool> resetEndorsements(String officialId, String reason) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Not authenticated');

      // Get current endorsement counts
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .get();

      if (!userDoc.exists) throw Exception('User not found');

      final currentData = userDoc.data()!;
      final officialProfile = currentData['officialProfile'] as Map<String, dynamic>?;

      final previousStats = {
        'schedulerEndorsements': officialProfile?['schedulerEndorsements'] ?? 0,
        'officialEndorsements': officialProfile?['officialEndorsements'] ?? 0,
      };

      // Reset endorsement counts in user profile
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .update({
        'officialProfile.schedulerEndorsements': 0,
        'officialProfile.officialEndorsements': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete all endorsements for this user
      final endorsements = await _firestore
          .collection('endorsements')
          .where('endorsedOfficialId', isEqualTo: officialId)
          .get();

      for (var doc in endorsements.docs) {
        await doc.reference.delete();
      }

      // Log the action
      await _logAdminAction(
        action: 'RESET_ENDORSEMENTS',
        targetUserId: officialId,
        reason: reason,
        previousData: previousStats,
        newData: {
          'schedulerEndorsements': 0,
          'officialEndorsements': 0,
          'endorsementsDeleted': endorsements.docs.length,
        },
      );

      return true;
    } catch (e) {
      print('Error resetting endorsements: $e');
      return false;
    }
  }

  /// Update user admin status
  Future<bool> setUserAdminStatus(String userId, bool isAdmin, String reason) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Not authenticated');

      // Get current status
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) throw Exception('User not found');

      final currentData = userDoc.data()!;
      final previousAdmin = currentData['isAdmin'] ?? false;

      // Update admin status
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log the action
      await _logAdminAction(
        action: isAdmin ? 'GRANT_ADMIN' : 'REVOKE_ADMIN',
        targetUserId: userId,
        reason: reason,
        previousData: {'isAdmin': previousAdmin},
        newData: {'isAdmin': isAdmin},
      );

      return true;
    } catch (e) {
      print('Error setting admin status: $e');
      return false;
    }
  }

  /// Forgive a backout
  Future<bool> forgiveBackout(String backoutId, String reason) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Not authenticated');

      // Get the backout document
      final backoutDoc = await _firestore
          .collection(_backOutsCollection)
          .doc(backoutId)
          .get();

      if (!backoutDoc.exists) throw Exception('Backout not found');

      final backoutData = backoutDoc.data()!;
      final officialId = backoutData['officialId'] as String?;

      // Mark as excused/forgiven
      await _firestore
          .collection(_backOutsCollection)
          .doc(backoutId)
          .update({
        'excused': true,
        'excuseReason': reason,
        'excusedAt': FieldValue.serverTimestamp(),
        'excusedBy': adminId,
      });

      // If we have an official ID, update their stats
      if (officialId != null) {
        await _recalculateFollowThroughRate(officialId);
      }

      // Log the action
      await _logAdminAction(
        action: 'FORGIVE_BACKOUT',
        targetUserId: officialId ?? 'unknown',
        reason: reason,
        previousData: {'excused': backoutData['excused'] ?? false},
        newData: {'excused': true, 'backoutId': backoutId},
      );

      return true;
    } catch (e) {
      print('Error forgiving backout: $e');
      return false;
    }
  }

  /// Unforgive a backout (reverse forgiveness)
  Future<bool> unforgiveBackout(String backoutId, String reason) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Not authenticated');

      // Get the backout document
      final backoutDoc = await _firestore
          .collection(_backOutsCollection)
          .doc(backoutId)
          .get();

      if (!backoutDoc.exists) throw Exception('Backout not found');

      final backoutData = backoutDoc.data()!;
      final officialId = backoutData['officialId'] as String?;

      // Mark as not excused
      await _firestore
          .collection(_backOutsCollection)
          .doc(backoutId)
          .update({
        'excused': false,
        'excuseReason': null,
        'excusedAt': null,
        'excusedBy': null,
      });

      // If we have an official ID, update their stats
      if (officialId != null) {
        await _recalculateFollowThroughRate(officialId);
      }

      // Log the action
      await _logAdminAction(
        action: 'UNFORGIVE_BACKOUT',
        targetUserId: officialId ?? 'unknown',
        reason: reason,
        previousData: {'excused': true},
        newData: {'excused': false, 'backoutId': backoutId},
      );

      return true;
    } catch (e) {
      print('Error unforgiving backout: $e');
      return false;
    }
  }

  /// Get all backouts for a user
  Future<List<Map<String, dynamic>>> getBackoutsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_backOutsCollection)
          .where('officialId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting backouts: $e');
      return [];
    }
  }

  /// Get all backouts (for admin view)
  Future<List<Map<String, dynamic>>> getAllBackouts({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_backOutsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all backouts: $e');
      return [];
    }
  }

  /// Recalculate follow-through rate for a user
  Future<void> _recalculateFollowThroughRate(String officialId) async {
    try {
      // Get all backouts for this user
      final backoutsSnapshot = await _firestore
          .collection(_backOutsCollection)
          .where('officialId', isEqualTo: officialId)
          .get();

      int totalBackedOut = 0;
      int forgivenCount = 0;

      for (var doc in backoutsSnapshot.docs) {
        final data = doc.data();
        if (data['excused'] == true) {
          forgivenCount++;
        } else {
          totalBackedOut++;
        }
      }

      // Get current total accepted games
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final officialProfile = userData['officialProfile'] as Map<String, dynamic>?;
      final totalAccepted = officialProfile?['totalAcceptedGames'] ?? 0;

      // Calculate rate (excluding forgiven)
      final effectiveTotal = totalAccepted - forgivenCount;
      final completed = effectiveTotal - totalBackedOut;
      final rate = effectiveTotal > 0 ? (completed / effectiveTotal * 100).clamp(0.0, 100.0) : 100.0;

      // Update the user
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(officialId)
          .update({
        'officialProfile.followThroughRate': rate,
        'officialProfile.totalBackedOutGames': totalBackedOut,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recalculating follow-through rate: $e');
    }
  }

  /// Log an admin action for audit trail
  Future<void> _logAdminAction({
    required String action,
    required String targetUserId,
    String? reason,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) return;

      await _firestore.collection(_auditLogCollection).add({
        'action': action,
        'adminId': adminId,
        'targetUserId': targetUserId,
        'reason': reason,
        'previousData': previousData,
        'newData': newData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }

  /// Get audit log entries
  Future<List<Map<String, dynamic>>> getAuditLog({
    int limit = 100,
    String? filterByAdmin,
    String? filterByAction,
  }) async {
    try {
      Query query = _firestore
          .collection(_auditLogCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (filterByAdmin != null) {
        query = query.where('adminId', isEqualTo: filterByAdmin);
      }

      if (filterByAction != null) {
        query = query.where('action', isEqualTo: filterByAction);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting audit log: $e');
      return [];
    }
  }

  /// Delete a user (use with caution!)
  Future<bool> deleteUser(String userId, String reason) async {
    try {
      final adminId = _auth.currentUser?.uid;
      if (adminId == null) throw Exception('Not authenticated');

      // Prevent self-deletion
      if (userId == adminId) throw Exception('Cannot delete yourself');

      // Get user data for audit log
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data()!;

      // Log the action before deletion
      await _logAdminAction(
        action: 'DELETE_USER',
        targetUserId: userId,
        reason: reason,
        previousData: {
          'email': userData['email'],
          'role': userData['role'],
          'fullName': '${userData['profile']?['firstName'] ?? ''} ${userData['profile']?['lastName'] ?? ''}'.trim(),
        },
        newData: {'deleted': true},
      );

      // Delete user's backouts
      final backouts = await _firestore
          .collection(_backOutsCollection)
          .where('officialId', isEqualTo: userId)
          .get();

      for (var doc in backouts.docs) {
        await doc.reference.delete();
      }

      // Delete user's endorsements (given and received)
      final endorsementsGiven = await _firestore
          .collection('endorsements')
          .where('endorserUserId', isEqualTo: userId)
          .get();

      for (var doc in endorsementsGiven.docs) {
        await doc.reference.delete();
      }

      final endorsementsReceived = await _firestore
          .collection('endorsements')
          .where('endorsedOfficialId', isEqualTo: userId)
          .get();

      for (var doc in endorsementsReceived.docs) {
        await doc.reference.delete();
      }

      // Delete the user document
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}

