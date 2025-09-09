import '../models/game_template_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../constants/firebase_constants.dart';
import 'base_service.dart';

// Add this typedef for clarity
typedef ScheduleData = Map<String, Object>;

class GameService extends BaseService {
  // Singleton pattern
  static final GameService _instance = GameService._internal();
  GameService._internal();
  factory GameService() => _instance;

  // Debug flag - set to false to reduce console noise
  static const bool _debugEnabled = false;

  // Helper method for conditional debug prints
  @override
  void debugPrint(String message) {
    if (_debugEnabled) {
      print(message);
    }
  }

  Future<List<GameTemplateModel>> getTemplates() async {
    try {
      // Get the current authenticated user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return [];
      }

      debugPrint(
          '🔍 GAME SERVICE: Fetching templates for user: $currentUserId');

      // Query Firebase for templates created by the current user
      final querySnapshot = await firestore
          .collection(FirebaseCollections.gameTemplates)
          .where(FirebaseFields.createdBy, isEqualTo: currentUserId)
          .orderBy(FirebaseFields.createdAt, descending: true)
          .get();

      debugPrint(
          '✅ GAME SERVICE: Found ${querySnapshot.docs.length} templates');

      // Convert to GameTemplateModel objects
      final templates = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return GameTemplateModel.fromJson({
          'id': doc.id,
          ...data,
          'createdAt': (data[FirebaseFields.createdAt] as Timestamp)
              .toDate()
              .toIso8601String(),
        });
      }).toList();

      debugPrint(
          '✅ GAME SERVICE: Successfully parsed ${templates.length} templates');
      return templates;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to fetch templates: $e');
      return [];
    }
  }

  Future<bool> deleteTemplate(String templateId) async {
    try {
      debugPrint('🗑️ GAME SERVICE: Deleting template: $templateId');

      // Delete the template from Firestore
      await firestore
          .collection(FirebaseCollections.gameTemplates)
          .doc(templateId)
          .delete();

      debugPrint('✅ GAME SERVICE: Successfully deleted template: $templateId');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to delete template: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createTemplate(
      Map<String, dynamic> templateData) async {
    try {
      // Get the current authenticated user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return null;
      }

      debugPrint(
          '🔄 GAME SERVICE: Creating template: ${templateData['name']} for user: $currentUserId');

      // Prepare the template data for Firestore
      final templateDataForFirestore = {
        ...templateData,
        FirebaseFields.createdBy: currentUserId,
        FirebaseFields.createdAt: FieldValue.serverTimestamp(),
        FirebaseFields.updatedAt: FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      final docRef = await firestore
          .collection(FirebaseCollections.gameTemplates)
          .add(templateDataForFirestore);

      debugPrint('✅ GAME SERVICE: Template created with ID: ${docRef.id}');
      return {
        'id': docRef.id,
        ...templateData,
        'createdAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to create template: $e');
      return null;
    }
  }

  Future<bool> updateTemplate(Map<String, dynamic> templateData) async {
    try {
      final templateId = templateData['id'] as String;
      debugPrint('🔄 GAME SERVICE: Updating template: $templateId');

      // Prepare the update data (remove id from the data to update)
      final updateData = Map<String, dynamic>.from(templateData);
      updateData.remove('id');
      updateData[FirebaseFields.updatedAt] = FieldValue.serverTimestamp();

      // Update in Firestore
      await firestore
          .collection(FirebaseCollections.gameTemplates)
          .doc(templateId)
          .update(updateData);

      debugPrint('✅ GAME SERVICE: Template updated successfully');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to update template: $e');
      return false;
    }
  }

  Future<List<ScheduleData>> getSchedules() async {
    try {
      // Get the current authenticated user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      print('DEBUG: Current user ID: $currentUserId');

      if (currentUserId == null) {
        print('DEBUG: No authenticated user found');
        return []; // Return empty list if no user is authenticated
      }

      // Query Firebase for schedules created by the current user
      // Using a simpler query that doesn't require a composite index for now
      print('DEBUG: Querying schedules for user: $currentUserId');
      final querySnapshot = await firestore
          .collection(FirebaseCollections.schedules)
          .where(FirebaseFields.createdBy, isEqualTo: currentUserId)
          .get();

      print('DEBUG: Query returned ${querySnapshot.docs.length} documents');

      // Debug: Print all document data
      for (var doc in querySnapshot.docs) {
        print('DEBUG: Document ${doc.id}: ${doc.data()}');
      }

      // Sort in memory since we can't use orderBy without an index
      final docs = querySnapshot.docs;
      docs.sort((a, b) {
        final aTime =
            (a.data()[FirebaseFields.createdAt] as Timestamp).toDate();
        final bTime =
            (b.data()[FirebaseFields.createdAt] as Timestamp).toDate();
        return bTime.compareTo(aTime); // Descending order
      });

      // Convert to the expected format
      final result = docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data[FirebaseFields.name] as String,
          'sport': data[FirebaseFields.sport] as String,
          'createdAt': (data[FirebaseFields.createdAt] as Timestamp).toDate(),
        };
      }).toList();

      print('DEBUG: Returning ${result.length} schedules');
      return result;
    } catch (e) {
      // If Firebase query fails, return empty list
      print('Error fetching schedules: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createSchedule(String name, String sport) async {
    try {
      // Get the current authenticated user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception('No authenticated user found. Please sign in first.');
      }

      // Check if a schedule with the same name already exists for this user
      final existingSchedulesQuery = await firestore
          .collection(FirebaseCollections.schedules)
          .where(FirebaseFields.createdBy, isEqualTo: currentUserId)
          .where(FirebaseFields.name, isEqualTo: name)
          .get();

      if (existingSchedulesQuery.docs.isNotEmpty) {
        throw Exception(
            'A schedule with the name "$name" already exists. Please choose a different name.');
      }

      // Save to Firebase Firestore
      final docRef =
          await firestore.collection(FirebaseCollections.schedules).add({
        FirebaseFields.name: name,
        FirebaseFields.sport: sport,
        FirebaseFields.createdAt: DateTime.now(),
        FirebaseFields.createdBy:
            currentUserId, // Use actual authenticated user ID
      });

      // Return the created schedule with the document ID
      return {
        'id': docRef.id,
        'name': name,
        'sport': sport,
        'createdAt': DateTime.now(),
      };
    } catch (e) {
      // If Firebase fails, throw the error
      throw Exception('Failed to save schedule to Firebase: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGames() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': '1',
        'scheduleName': 'Varsity Basketball',
        'sport': 'Basketball',
        'date': DateTime.now().add(const Duration(days: 7)),
        'time': '7:00 PM',
        'opponent': 'Lincoln High',
        'location': 'Home Gym',
        'officialsRequired': 3,
        'officialsHired': 2,
        'isAway': false,
      },
      {
        'id': '2',
        'scheduleName': 'JV Soccer',
        'sport': 'Soccer',
        'date': DateTime.now().add(const Duration(days: 3)),
        'time': '4:30 PM',
        'opponent': 'Washington Prep',
        'location': 'Away Field',
        'officialsRequired': 2,
        'officialsHired': 0,
        'isAway': true,
      },
    ];
  }

  // Game Information Screen Methods

  Future<Map<String, dynamic>?> getGameByIdWithOfficials(int gameId) async {
    try {
      debugPrint('🔍 GAME SERVICE: Looking up game ID: $gameId');

      // For now, return mock data - in a real implementation, this would query Firestore
      final games = await getGames();
      final game = games.firstWhere(
        (g) => int.tryParse(g['id'].toString()) == gameId,
        orElse: () => <String, dynamic>{},
      );

      if (game.isNotEmpty) {
        debugPrint('✅ GAME SERVICE: Found game: ${game['scheduleName']}');
        // Add mock officials data
        game['confirmedOfficials'] = [
          {
            'id': 1,
            'name': 'John Smith',
            'email': 'john@example.com',
            'phone': '555-123-4567'
          },
          {
            'id': 2,
            'name': 'Jane Doe',
            'email': 'jane@example.com',
            'phone': '555-987-6543'
          },
        ];
        game['interestedOfficials'] = [
          {'id': 3, 'name': 'Bob Johnson', 'distance': 5.2},
          {'id': 4, 'name': 'Alice Wilson', 'distance': 8.1},
        ];
        return game;
      }

      debugPrint('⚠️ GAME SERVICE: Game not found: $gameId');
      return null;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Error getting game: $e');
      throw Exception('Failed to get game: $e');
    }
  }

  Future<bool> isGameLinked(int gameId) async {
    // Mock implementation - in real app, this would check for linked games in Firestore
    return false; // No games are linked for now
  }

  Future<List<Map<String, dynamic>>> getLinkedGames(int gameId) async {
    // Mock implementation - return empty list for now
    return [];
  }

  Future<bool> updateOfficialsHired(int gameId, int officialsHired) async {
    try {
      debugPrint(
          '🔄 GAME SERVICE: Updating officials hired for game $gameId to $officialsHired');
      // Mock implementation - in real app, this would update Firestore
      await Future.delayed(
          const Duration(milliseconds: 200)); // Simulate network delay
      debugPrint('✅ GAME SERVICE: Successfully updated officials hired');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to update officials hired: $e');
      return false;
    }
  }

  Future<bool> removeOfficialFromGame(int gameId, int officialId) async {
    try {
      debugPrint(
          '🗑️ GAME SERVICE: Removing official $officialId from game $gameId');
      // Mock implementation - in real app, this would update Firestore
      await Future.delayed(
          const Duration(milliseconds: 200)); // Simulate network delay
      debugPrint('✅ GAME SERVICE: Successfully removed official');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to remove official: $e');
      return false;
    }
  }

  Future<bool> deleteGame(int gameId) async {
    try {
      debugPrint('🗑️ GAME SERVICE: Deleting game $gameId');
      // Mock implementation - in real app, this would delete from Firestore
      await Future.delayed(
          const Duration(milliseconds: 200)); // Simulate network delay
      debugPrint('✅ GAME SERVICE: Successfully deleted game');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to delete game: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getInterestedOfficialsForGame(
      int gameId) async {
    try {
      debugPrint(
          '🔍 GAME SERVICE: Getting interested officials for game $gameId');
      // Mock implementation - in real app, this would query Firestore
      await Future.delayed(const Duration(milliseconds: 100));
      return [
        {
          'id': 3,
          'name': 'Bob Johnson',
          'distance': 5.2,
          'email': 'bob@example.com'
        },
        {
          'id': 4,
          'name': 'Alice Wilson',
          'distance': 8.1,
          'email': 'alice@example.com'
        },
      ];
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to get interested officials: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getInterestedCrewsForGame(
      int gameId) async {
    try {
      debugPrint('🔍 GAME SERVICE: Getting interested crews for game $gameId');
      // Mock implementation - return empty for now
      return [];
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to get interested crews: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getConfirmedOfficialsForGame(
      int gameId) async {
    try {
      debugPrint(
          '🔍 GAME SERVICE: Getting confirmed officials for game $gameId');
      // Mock implementation - in real app, this would query Firestore
      await Future.delayed(const Duration(milliseconds: 100));
      return [
        {
          'id': 1,
          'name': 'John Smith',
          'email': 'john@example.com',
          'phone': '555-123-4567'
        },
        {
          'id': 2,
          'name': 'Jane Doe',
          'email': 'jane@example.com',
          'phone': '555-987-6543'
        },
      ];
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to get confirmed officials: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGamesByScheduleName(
      String scheduleName) async {
    try {
      debugPrint('🔄 GAME SERVICE: Getting games for schedule: $scheduleName');
      // Get all games and filter by schedule name
      final allGames = await getGames();
      final filteredGames = allGames
          .where((game) => game['scheduleName'] == scheduleName)
          .toList();

      debugPrint(
          '✅ GAME SERVICE: Found ${filteredGames.length} games for schedule $scheduleName');
      return filteredGames;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to get games by schedule name: $e');
      return [];
    }
  }
}
