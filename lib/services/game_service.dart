import 'package:flutter/material.dart';
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

  // Debug flag - temporarily enabled for debugging template issues
  static const bool _debugEnabled = true;

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
      // Note: This query requires a composite index on (createdBy, createdAt)
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

  Future<void> saveTemplateAssociation(String scheduleName, String templateId,
      Map<String, dynamic> templateData) async {
    try {
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception(
            'User must be authenticated to save template associations');
      }

      final associationData = {
        'scheduleName': scheduleName,
        'templateId': templateId,
        'templateData': templateData,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firestore.collection('template_associations').add(associationData);

      debugPrint(
          '✅ GAME SERVICE: Template association saved for schedule: $scheduleName');
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error saving template association: $e');
      throw Exception('Failed to save template association: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTemplateAssociations(
      String scheduleName) async {
    try {
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return [];
      }

      debugPrint(
          '🔍 GAME SERVICE: Fetching template associations for user (will filter by schedule: $scheduleName)');

      // Query by userId only (single field query) to avoid composite index requirement
      final querySnapshot = await firestore
          .collection('template_associations')
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Filter by scheduleName and sort by createdAt in memory
      final associations = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
            };
          })
          .where((association) => association['scheduleName'] == scheduleName)
          .toList()
        // Sort by createdAt descending to get most recent first
        ..sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending order
        });

      debugPrint(
          '✅ GAME SERVICE: Found ${associations.length} template associations for schedule: $scheduleName (filtered from ${querySnapshot.docs.length} total user associations)');
      return associations;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error fetching template associations: $e');
      return [];
    }
  }

  Future<bool> removeTemplateAssociation(String scheduleName) async {
    try {
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return false;
      }

      debugPrint(
          '🔄 GAME SERVICE: Removing template association for schedule: $scheduleName');

      // Query for the association to delete
      final querySnapshot = await firestore
          .collection('template_associations')
          .where('userId', isEqualTo: currentUserId)
          .where('scheduleName', isEqualTo: scheduleName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Delete the association
        await querySnapshot.docs.first.reference.delete();
        debugPrint('✅ GAME SERVICE: Template association removed successfully');
        return true;
      } else {
        debugPrint('⚠️ GAME SERVICE: No template association found to remove');
        return false;
      }
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error removing template association: $e');
      return false;
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
    try {
      debugPrint('🔄 GAME SERVICE: Getting all games from Firestore');

      // Query Firestore for all games
      final querySnapshot = await firestore.collection('games').get();

      debugPrint(
          '✅ GAME SERVICE: Retrieved ${querySnapshot.docs.length} games from Firestore');

      final games = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      debugPrint('🎯 GAME SERVICE: Processed ${games.length} games');
      return games;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error fetching games: $e');
      // Return empty list on error instead of mock data
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUnpublishedGames() async {
    try {
      debugPrint(
          '🔄 GAME SERVICE: Getting unpublished games from Firestore (will sort by game date/time)');

      // Get current user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return [];
      }

      // Query Firestore for unpublished games by current user
      // Use single field query and filter in memory to avoid composite index requirement
      final querySnapshot = await firestore
          .collection('games')
          .where('userId', isEqualTo: currentUserId)
          .get();

      debugPrint(
          '✅ GAME SERVICE: Retrieved ${querySnapshot.docs.length} games from Firestore for user');

      // Filter unpublished games and sort in memory
      final unpublishedGames = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
            };
          })
          .where((game) => game['status'] == 'Unpublished')
          .toList();

      // Sort by game date and time in ascending order (earliest first)
      unpublishedGames.sort((a, b) {
        final aDate = a['date'];
        final bDate = b['date'];
        final aTime = a['time'];
        final bTime = b['time'];

        // Handle null dates - games without dates go to the end
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        try {
          // Parse dates
          final aDateTime = aDate is DateTime ? aDate : DateTime.parse(aDate);
          final bDateTime = bDate is DateTime ? bDate : DateTime.parse(bDate);

          // Compare dates first
          final dateComparison = aDateTime.compareTo(bDateTime);
          if (dateComparison != 0) return dateComparison;

          // If dates are the same, compare times
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          // Parse time strings (format: "HH:MM AM/PM" or "HH:MM")
          final aTimeStr = aTime.toString();
          final bTimeStr = bTime.toString();

          try {
            // Try to parse as TimeOfDay format
            final aTimeOfDay = _parseTimeString(aTimeStr);
            final bTimeOfDay = _parseTimeString(bTimeStr);

            if (aTimeOfDay != null && bTimeOfDay != null) {
              final aMinutes = aTimeOfDay.hour * 60 + aTimeOfDay.minute;
              final bMinutes = bTimeOfDay.hour * 60 + bTimeOfDay.minute;
              return aMinutes.compareTo(bMinutes);
            }
          } catch (e) {
            debugPrint('⚠️ GAME SERVICE: Error parsing time: $e');
          }

          // Fallback to string comparison
          return aTimeStr.compareTo(bTimeStr);
        } catch (e) {
          debugPrint('⚠️ GAME SERVICE: Error parsing game date: $e');
          return 0;
        }
      });

      debugPrint(
          '🎯 GAME SERVICE: Filtered and sorted ${unpublishedGames.length} unpublished games by game date/time (ascending)');
      return unpublishedGames;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error fetching unpublished games: $e');
      return [];
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Handle various time formats
      final cleanTime = timeStr.trim().toUpperCase();

      // Handle "HH:MM AM/PM" format (e.g., "2:30 PM")
      final amPmRegex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
      final amPmMatch = amPmRegex.firstMatch(cleanTime);
      if (amPmMatch != null) {
        final hour = int.parse(amPmMatch.group(1)!);
        final minute = int.parse(amPmMatch.group(2)!);
        final isPm = amPmMatch.group(3) == 'PM';

        final adjustedHour = isPm && hour != 12
            ? hour + 12
            : !isPm && hour == 12
                ? 0
                : hour;

        return TimeOfDay(hour: adjustedHour, minute: minute);
      }

      // Handle "HH:MM" format (24-hour)
      final hourMinRegex = RegExp(r'^(\d{1,2}):(\d{2})$');
      final hourMinMatch = hourMinRegex.firstMatch(cleanTime);
      if (hourMinMatch != null) {
        final hour = int.parse(hourMinMatch.group(1)!);
        final minute = int.parse(hourMinMatch.group(2)!);
        return TimeOfDay(hour: hour, minute: minute);
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ GAME SERVICE: Error parsing time string "$timeStr": $e');
      return null;
    }
  }

  Future<bool> publishGames(List<String> gameIds) async {
    try {
      debugPrint('🔄 GAME SERVICE: Publishing ${gameIds.length} games');

      // Update each game to published status
      for (final gameId in gameIds) {
        await firestore
            .collection('games')
            .doc(gameId)
            .update({'status': 'Published'});
      }

      debugPrint(
          '✅ GAME SERVICE: Successfully published ${gameIds.length} games');
      return true;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error publishing games: $e');
      return false;
    }
  }

  Future<bool> deleteGame(String gameId) async {
    try {
      debugPrint('🔄 GAME SERVICE: Deleting game $gameId');

      await firestore.collection('games').doc(gameId).delete();

      debugPrint('✅ GAME SERVICE: Successfully deleted game $gameId');
      return true;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error deleting game: $e');
      return false;
    }
  }

  Future<bool> saveUnpublishedGame(Map<String, dynamic> gameData) async {
    try {
      debugPrint('🔄 GAME SERVICE: Saving unpublished game');

      // Get current user
      final authService = AuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return false;
      }

      // Prepare game data for unpublished status
      final unpublishedGameData = {
        ...gameData,
        'userId': currentUser.uid,
        'status': 'Unpublished',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Remove id if it exists (let Firestore generate it)
      unpublishedGameData.remove('id');

      // Save to games collection
      await firestore.collection('games').add(unpublishedGameData);

      debugPrint('✅ GAME SERVICE: Successfully saved unpublished game');
      return true;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error saving unpublished game: $e');
      return false;
    }
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
