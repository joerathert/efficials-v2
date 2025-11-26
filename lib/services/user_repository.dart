import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      debugPrint('🔍 USER REPOSITORY: Looking up user ID: ${currentUser.uid}');

      final doc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!doc.exists) {
        debugPrint('❌ USER REPOSITORY: Document does not exist for user ${currentUser.uid}');
        return null;
      }

      final data = doc.data()!;
      debugPrint('🔍 USER REPOSITORY: Document exists: true');
      debugPrint('🔍 USER REPOSITORY: Document data: $data');

      final user = UserModel.fromMap(data);
      debugPrint('✅ USER REPOSITORY: Successfully parsed user: ${user.profile.firstName}');
      debugPrint('✅ USER REPOSITORY: User type: ${user.schedulerProfile?.type}');

      return user;
    } catch (e) {
      debugPrint('❌ USER REPOSITORY: Error fetching current user: $e');
      return null;
    }
  }
}
