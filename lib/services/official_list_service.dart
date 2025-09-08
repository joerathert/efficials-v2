import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OfficialListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Debug flag - set to false to reduce console noise
  static const bool _debugEnabled = false;

  // Helper method for conditional debug prints
  void _debugPrint(String message) {
    if (_debugEnabled) {
      print(message);
    }
  }

  /// Save a new official list to Firestore
  Future<String> saveOfficialList({
    required String listName,
    required String sport,
    required List<Map<String, dynamic>> officials,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to save lists');
      }

      final listData = {
        'name': listName,
        'sport': sport,
        'officials': officials,
        'official_count': officials.length,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'description': description ?? '',
      };

      final docRef =
          await _firestore.collection('official_lists').add(listData);

      _debugPrint('✅ Official list "$listName" saved with ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      _debugPrint('❌ Error saving official list: $e');
      throw Exception('Failed to save official list: $e');
    }
  }

  /// Fetch all official lists for the current user
  Future<List<Map<String, dynamic>>> fetchOfficialLists() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ OfficialListService: No authenticated user found!');
        throw Exception('User must be authenticated to fetch lists');
      }

      print(
          '🔍 OfficialListService: Fetching official lists for user: ${user.uid}');
      print('👤 OfficialListService: User email: ${user.email}');
      print('🔐 OfficialListService: User is authenticated: true');

      final snapshot = await _firestore
          .collection('official_lists')
          .where('userId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .get();

      print(
          '📊 OfficialListService: Firestore query returned ${snapshot.docs.length} documents');

      final lists = snapshot.docs.map((doc) {
        final data = doc.data();
        print(
            '📋 OfficialListService: Processing list "${data['name'] ?? 'Unknown'}" with ID: ${doc.id}');
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      print('✅ OfficialListService: Returning ${lists.length} official lists');

      return lists;
    } catch (e) {
      print('❌ OfficialListService: Error fetching official lists: $e');
      throw Exception('Failed to fetch official lists: $e');
    }
  }

  /// Delete an official list from Firestore
  Future<void> deleteOfficialList(String listId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete lists');
      }

      // Verify the list belongs to the current user before deleting
      final doc =
          await _firestore.collection('official_lists').doc(listId).get();

      if (!doc.exists) {
        throw Exception('List not found');
      }

      final data = doc.data()!;
      if (data['userId'] != user.uid) {
        throw Exception('Unauthorized to delete this list');
      }

      await _firestore.collection('official_lists').doc(listId).delete();

      _debugPrint('✅ Official list $listId deleted successfully');
    } catch (e) {
      _debugPrint('❌ Error deleting official list: $e');
      throw Exception('Failed to delete official list: $e');
    }
  }

  /// Update an existing official list
  Future<void> updateOfficialList({
    required String listId,
    String? listName,
    String? sport,
    List<Map<String, dynamic>>? officials,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to update lists');
      }

      // Verify the list belongs to the current user before updating
      final doc =
          await _firestore.collection('official_lists').doc(listId).get();

      if (!doc.exists) {
        throw Exception('List not found');
      }

      final data = doc.data()!;
      if (data['userId'] != user.uid) {
        throw Exception('Unauthorized to update this list');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (listName != null) updateData['name'] = listName;
      if (sport != null) updateData['sport'] = sport;
      if (officials != null) {
        updateData['officials'] = officials;
        updateData['official_count'] = officials.length;
      }
      if (description != null) updateData['description'] = description;

      await _firestore
          .collection('official_lists')
          .doc(listId)
          .update(updateData);

      _debugPrint('✅ Official list $listId updated successfully');
    } catch (e) {
      _debugPrint('❌ Error updating official list: $e');
      throw Exception('Failed to update official list: $e');
    }
  }

  /// Get a specific official list by ID
  Future<Map<String, dynamic>?> getOfficialList(String listId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to fetch list');
      }

      final doc =
          await _firestore.collection('official_lists').doc(listId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      if (data['userId'] != user.uid) {
        throw Exception('Unauthorized to access this list');
      }

      return {
        ...data,
        'id': doc.id,
      };
    } catch (e) {
      _debugPrint('❌ Error fetching official list: $e');
      throw Exception('Failed to fetch official list: $e');
    }
  }
}
