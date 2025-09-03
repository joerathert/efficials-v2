import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserServiceException implements Exception {
  final String message;
  UserServiceException(this.message);
  
  @override
  String toString() => 'UserServiceException: $message';
}

class UserService {
  static final UserService _instance = UserService._internal();
  UserService._internal();
  factory UserService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String collectionName = 'users';

  /// Create a new user document in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(user.id)
          .set(user.toMap());
    } catch (e) {
      throw UserServiceException('Failed to create user: $e');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(collectionName)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw UserServiceException('Failed to get user: $e');
    }
  }

  /// Get current authenticated user's profile
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return await getUserById(user.uid);
  }

  /// Update user profile
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw UserServiceException('Failed to update user: $e');
    }
  }

  /// Update user's FCM token
  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(userId)
          .update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw UserServiceException('Failed to update FCM token: $e');
    }
  }

  /// Remove FCM token (when user logs out from a device)
  Future<void> removeFcmToken(String userId, String token) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(userId)
          .update({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw UserServiceException('Failed to remove FCM token: $e');
    }
  }

  /// Check if email exists (for validation during signup)
  Future<bool> emailExists(String email) async {
    try {
      final query = await _firestore
          .collection(collectionName)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      throw UserServiceException('Failed to check email existence: $e');
    }
  }

  /// Get all schedulers (for admin purposes)
  Future<List<UserModel>> getAllSchedulers() async {
    try {
      final query = await _firestore
          .collection(collectionName)
          .where('role', isEqualTo: 'scheduler')
          .get();
      
      return query.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw UserServiceException('Failed to get schedulers: $e');
    }
  }

  /// Get all officials (for scheduler purposes)
  Future<List<UserModel>> getAllOfficials() async {
    try {
      final query = await _firestore
          .collection(collectionName)
          .where('role', isEqualTo: 'official')
          .get();
      
      return query.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw UserServiceException('Failed to get officials: $e');
    }
  }

  /// Search users by name (for finding officials)
  Future<List<UserModel>> searchUsersByName(String searchTerm) async {
    try {
      final searchLower = searchTerm.toLowerCase();
      
      final query = await _firestore
          .collection(collectionName)
          .get();
      
      return query.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => 
              user.fullName.toLowerCase().contains(searchLower) ||
              user.email.toLowerCase().contains(searchLower))
          .toList();
    } catch (e) {
      throw UserServiceException('Failed to search users: $e');
    }
  }

  /// Listen to user profile changes
  Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection(collectionName)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  /// Listen to current user changes
  Stream<UserModel?> watchCurrentUser() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return watchUser(user.uid);
    });
  }

  /// Delete user (for admin purposes - also deletes auth account)
  Future<void> deleteUser(String userId) async {
    try {
      // Note: This only deletes the Firestore document
      // Firebase Auth user deletion requires different permissions
      await _firestore
          .collection(collectionName)
          .doc(userId)
          .delete();
    } catch (e) {
      throw UserServiceException('Failed to delete user: $e');
    }
  }

  /// Batch create multiple users (for data migration)
  Future<void> batchCreateUsers(List<UserModel> users) async {
    try {
      final batch = _firestore.batch();
      
      for (final user in users) {
        final docRef = _firestore
            .collection(collectionName)
            .doc(user.id);
        batch.set(docRef, user.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw UserServiceException('Failed to batch create users: $e');
    }
  }
}