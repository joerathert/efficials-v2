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

      debugPrint('🔍 GAME SERVICE: Current user: ${authService.currentUser}');
      debugPrint('🔍 GAME SERVICE: Current user ID: $currentUserId');

      if (currentUserId == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return [];
      }

      debugPrint(
          '🔍 GAME SERVICE: Fetching templates for user: $currentUserId');

      // Query Firebase for templates created by the current user
      // Note: This query requires a composite index on (createdBy, createdAt)
      // For now, let's try fetching all templates and filtering in memory to debug
      debugPrint('🔍 GAME SERVICE: Trying composite index query first...');
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await firestore
            .collection(FirebaseCollections.gameTemplates)
            .where(FirebaseFields.createdBy, isEqualTo: currentUserId)
            .orderBy(FirebaseFields.createdAt, descending: true)
            .get();
        debugPrint('✅ GAME SERVICE: Composite index query succeeded');
      } catch (e) {
        debugPrint('⚠️ GAME SERVICE: Composite index query failed: $e');
        debugPrint('🔄 GAME SERVICE: Falling back to in-memory filtering...');

        // Fallback: fetch all templates and filter in memory
        querySnapshot =
            await firestore.collection(FirebaseCollections.gameTemplates).get();

        debugPrint(
            '📊 GAME SERVICE: Fetched ${querySnapshot.docs.length} total templates for filtering');
      }

      debugPrint(
          '✅ GAME SERVICE: Found ${querySnapshot.docs.length} raw documents');

      // Filter documents by createdBy if we did the fallback query
      List<QueryDocumentSnapshot> filteredDocs = querySnapshot.docs;

      // Check if we got results from the composite index query
      bool usedCompositeIndex = querySnapshot.docs.isNotEmpty &&
          (querySnapshot.docs.first.data() as Map<String, dynamic>)
              .containsKey(FirebaseFields.createdBy);

      if (!usedCompositeIndex) {
        // This means we did the fallback query, so filter in memory
        filteredDocs = querySnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final docCreatedBy = data[FirebaseFields.createdBy];
          return docCreatedBy == currentUserId;
        }).toList();
        debugPrint(
            '🎯 GAME SERVICE: After in-memory filtering: ${filteredDocs.length} documents');
      }

      // Log each document for debugging
      for (var doc in filteredDocs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint(
            '📄 DOC: ID=${doc.id}, createdBy=${data[FirebaseFields.createdBy]}');
      }

      // Convert to GameTemplateModel objects
      final templates = filteredDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        debugPrint('🔄 Converting doc ${doc.id} to GameTemplateModel');
        try {
          // Handle createdAt field - could be Timestamp or already a string
          final rawCreatedAt = data[FirebaseFields.createdAt];
          String createdAtString;

          if (rawCreatedAt is Timestamp) {
            createdAtString = rawCreatedAt.toDate().toIso8601String();
          } else if (rawCreatedAt is String) {
            createdAtString = rawCreatedAt;
          } else {
            throw Exception(
                'Invalid createdAt format for template ${doc.id}: ${rawCreatedAt.runtimeType}');
          }

          final templateData = <String, dynamic>{
            'id': doc.id,
            ...data,
            'createdAt': createdAtString,
          };

          final template = GameTemplateModel.fromJson(templateData);
          debugPrint('✅ Successfully converted template: ${template.name}');
          debugPrint('✅ Template location: ${template.location}');
          return template;
        } catch (e) {
          debugPrint('❌ Failed to convert template ${doc.id}: $e');
          rethrow;
        }
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

      // Query by userId only (single field query) to avoid composite index requirement
      final querySnapshot = await firestore
          .collection('template_associations')
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Find the association that matches the scheduleName
      final associations = querySnapshot.docs
          .where((doc) => doc.data()['scheduleName'] == scheduleName)
          .toList();

      if (associations.isNotEmpty) {
        final associationToDelete = associations.first;
        // Delete the association
        await associationToDelete.reference.delete();
        debugPrint('✅ GAME SERVICE: Template association removed successfully');
        return true;
      } else {
        debugPrint('⚠️ GAME SERVICE: No template association found to remove for schedule: $scheduleName');
        return false;
      }
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error removing template association: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateTemplate(
      Map<String, dynamic> templateData) async {
    try {
      final templateId = templateData['id'] as String;
      debugPrint('🔄 GAME SERVICE: Updating template: $templateId');
      debugPrint(
          '🔄 GAME SERVICE: Update data keys: ${templateData.keys.toList()}');
      debugPrint(
          '🔄 GAME SERVICE: Location value: ${templateData['location']}');
      debugPrint(
          '🔄 GAME SERVICE: includeLocation: ${templateData['includeLocation']}');

      // Prepare the update data (remove id and createdAt from the data to update)
      final updateData = Map<String, dynamic>.from(templateData);
      updateData.remove('id');
      updateData.remove('createdAt'); // Don't update createdAt timestamp
      updateData[FirebaseFields.updatedAt] = FieldValue.serverTimestamp();

      debugPrint('🔄 GAME SERVICE: Final update data: $updateData');

      // Update in Firestore
      await firestore
          .collection(FirebaseCollections.gameTemplates)
          .doc(templateId)
          .update(updateData);

      debugPrint('✅ GAME SERVICE: Template updated successfully in Firestore');

      // Verify the update by fetching the document
      final updatedDoc = await firestore
          .collection(FirebaseCollections.gameTemplates)
          .doc(templateId)
          .get();

      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data();
        debugPrint(
            '✅ GAME SERVICE: Verified updated document: ${updatedData?['location']}');
        debugPrint(
            '✅ GAME SERVICE: Document has location: ${updatedData?.containsKey('location')}');
      } else {
        debugPrint('❌ GAME SERVICE: Document not found after update');
      }

      // Return the updated template data (preserve createdAt, add/update updatedAt)
      final result = Map<String, dynamic>.from(templateData);
      result['id'] = templateId; // Ensure ID is set
      result['updatedAt'] = DateTime.now().toIso8601String();
      // createdAt should already be in templateData

      debugPrint(
          '✅ GAME SERVICE: Returning updated template data: ${result['name']}');
      debugPrint('✅ GAME SERVICE: Result location: ${result['location']}');
      return result;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to update template: $e');
      return null;
    }
  }

  Future<ScheduleData?> getSchedule(String scheduleId) async {
    try {
      // Get the current authenticated user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        print('DEBUG: No authenticated user found');
        return null;
      }

      print('DEBUG: Getting schedule $scheduleId for user: $currentUserId');
      final doc = await firestore
          .collection(FirebaseCollections.schedules)
          .doc(scheduleId)
          .get();

      if (!doc.exists) {
        print('DEBUG: Schedule $scheduleId not found');
        return null;
      }

      final data = doc.data()!;
      if (data[FirebaseFields.createdBy] != currentUserId) {
        print('DEBUG: Schedule $scheduleId does not belong to current user');
        return null;
      }

      return {
        'id': doc.id,
        'name': data[FirebaseFields.name] as String,
        'sport': data[FirebaseFields.sport] as String,
        'createdAt': (data[FirebaseFields.createdAt] as Timestamp).toDate(),
      };
    } catch (e) {
      print('Error getting schedule: $e');
      return null;
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

  /// Get games by schedule ID
  Future<List<Map<String, dynamic>>> getGamesByScheduleId(
      String scheduleId) async {
    try {
      final gamesQuery = await firestore
          .collection(FirebaseCollections.games)
          .where(FirebaseFields.scheduleId, isEqualTo: scheduleId)
          .get();

      final games = <Map<String, dynamic>>[];
      for (var doc in gamesQuery.docs) {
        final data = doc.data();
        games.add({
          'id': doc.id,
          ...data,
        });
      }

      return games;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Error getting games by schedule ID: $e');
      return [];
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    try {
      // Get the current authenticated user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception('No authenticated user found. Please sign in first.');
      }

      // Check if the schedule exists and belongs to the current user
      final scheduleDoc = await firestore
          .collection(FirebaseCollections.schedules)
          .doc(scheduleId)
          .get();

      if (!scheduleDoc.exists) {
        throw Exception('Schedule not found.');
      }

      final scheduleData = scheduleDoc.data();
      if (scheduleData?[FirebaseFields.createdBy] != currentUserId) {
        throw Exception('You do not have permission to delete this schedule.');
      }

      // Get scheduler information for notifications
      String schedulerName = 'The Scheduler';
      String schedulerEmail = '';
      String schedulerPhone = '';
      String schedulerType = 'Scheduler';
      String schedulerOrganization = '';
      
      try {
        final schedulerDoc =
            await firestore.collection('users').doc(currentUserId).get();
        final schedulerData = schedulerDoc.data();
        
        if (schedulerData != null) {
          final profile = schedulerData['profile'] as Map<String, dynamic>?;
          if (profile != null) {
            final firstName = profile['firstName'] as String? ?? '';
            final lastName = profile['lastName'] as String? ?? '';
            schedulerName = '$firstName $lastName'.trim();
            if (schedulerName.isEmpty) schedulerName = 'The Scheduler';
            schedulerPhone = profile['phone'] as String? ?? '';
          }
          schedulerEmail = schedulerData['email'] as String? ?? '';
          
          final schedulerProfile =
              schedulerData['schedulerProfile'] as Map<String, dynamic>?;
          if (schedulerProfile != null) {
            schedulerType = schedulerProfile['type'] as String? ?? 'Scheduler';
            
            // Get organization name based on scheduler type
            if (schedulerType == 'Athletic Director') {
              schedulerOrganization = schedulerProfile['schoolName'] as String? ?? '';
            } else if (schedulerType == 'Coach') {
              schedulerOrganization = schedulerProfile['teamName'] as String? ?? '';
            } else if (schedulerType == 'Assigner') {
              schedulerOrganization = schedulerProfile['organizationName'] as String? ?? '';
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ GAME SERVICE: Error loading scheduler info: $e');
        // Continue with default values
      }

      // Get all games associated with this schedule
      final gamesQuery = await firestore
          .collection(FirebaseCollections.games)
          .where(FirebaseFields.scheduleId, isEqualTo: scheduleId)
          .get();

      // Collect all affected officials and their game details
      final Map<String, List<Map<String, dynamic>>> officialGames = {};
      
      for (var gameDoc in gamesQuery.docs) {
        try {
          final gameData = gameDoc.data();
          final selectedOfficials = gameData['selectedOfficials'];
          
          if (selectedOfficials is List) {
            for (var official in selectedOfficials) {
              if (official is Map && official['id'] != null) {
                final officialId = official['id'] as String;
                
                // Parse game date
                DateTime? gameDate;
                if (gameData['date'] != null) {
                  try {
                    if (gameData['date'] is String) {
                      gameDate = DateTime.parse(gameData['date'] as String);
                    } else if (gameData['date'] is DateTime) {
                      gameDate = gameData['date'] as DateTime;
                    }
                  } catch (e) {
                    debugPrint('⚠️ Error parsing game date: $e');
                  }
                }
                
                // Parse game time
                String gameTime = 'TBD';
                if (gameData['time'] != null) {
                  gameTime = gameData['time'].toString();
                }
                
                final gameInfo = {
                  'gameId': gameDoc.id,
                  'sport': gameData['sport'] as String? ?? 'Unknown',
                  'date': gameDate,
                  'time': gameTime,
                  'opponent': gameData['opponent'] as String? ?? 'Unknown',
                  'location': gameData['location'] as String? ?? 'Unknown',
                };
                
                if (!officialGames.containsKey(officialId)) {
                  officialGames[officialId] = [];
                }
                officialGames[officialId]!.add(gameInfo);
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ GAME SERVICE: Error processing game ${gameDoc.id}: $e');
          // Continue with next game
          continue;
        }
      }

      // Create notifications for all affected officials
      final batch = firestore.batch();
      final now = DateTime.now();
      
      for (var entry in officialGames.entries) {
        try {
          final officialId = entry.key;
          final games = entry.value;
          
          // Create a notification for each game (officials need to know which specific games were removed)
          for (var game in games) {
            try {
              final notificationRef = firestore.collection('notifications').doc();
              
              final gameDate = game['date'] as DateTime?;
              final gameDetails = <String, dynamic>{
                'sport': game['sport'] as String? ?? 'Unknown',
                'time': game['time'] as String? ?? 'TBD',
                'opponent': game['opponent'] as String? ?? 'Unknown',
                'location': game['location'] as String? ?? 'Unknown',
              };
              
              // Only add date if it's not null
              if (gameDate != null) {
                gameDetails['date'] = gameDate.toIso8601String();
              }
              
              batch.set(notificationRef, {
                'userId': officialId,
                'type': 'game_removed',
                'title': 'Game Removed',
                'message':
                    'A game you were hired for has been removed from Efficials.',
                'gameDetails': gameDetails,
                'schedulerInfo': {
                  'name': schedulerName,
                  'email': schedulerEmail,
                  'phone': schedulerPhone,
                  'type': schedulerType,
                  'organization': schedulerOrganization,
                },
                'createdAt': Timestamp.fromDate(now),
                'read': false,
              });
            } catch (e) {
              debugPrint(
                  '⚠️ GAME SERVICE: Error creating notification for game ${game['gameId']}: $e');
              // Continue with next game
              continue;
            }
          }
        } catch (e) {
          debugPrint(
              '⚠️ GAME SERVICE: Error processing notifications for official ${entry.key}: $e');
          // Continue with next official
          continue;
        }
      }

      // Delete all games
      for (var gameDoc in gamesQuery.docs) {
        batch.delete(gameDoc.reference);
      }

      // Delete the schedule document
      batch.delete(scheduleDoc.reference);

      // Commit the batch (includes notifications and deletions)
      await batch.commit();

      debugPrint(
          '✅ GAME SERVICE: Schedule $scheduleId and ${gamesQuery.docs.length} games deleted successfully');
      debugPrint(
          '✅ GAME SERVICE: Created notifications for ${officialGames.length} affected officials');
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Error deleting schedule: $e');
      throw Exception('Failed to delete schedule: $e');
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

  Future<List<Map<String, dynamic>>> getPublishedGames() async {
    try {
      debugPrint(
          '🔄 GAME SERVICE: Getting published games from Firestore (will sort by game date/time)');

      // Get current user
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;

      if (currentUserId == null) {
        debugPrint('⚠️ GAME SERVICE: No authenticated user found');
        return [];
      }

      // Query Firestore for published games by current user
      // Use single field query and filter in memory to avoid composite index requirement
      final querySnapshot = await firestore
          .collection('games')
          .where('userId', isEqualTo: currentUserId)
          .get();

      debugPrint(
          '✅ GAME SERVICE: Retrieved ${querySnapshot.docs.length} games from Firestore for user');

      // Filter published games and sort in memory
      final publishedGames = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
            };
          })
          .where((game) => game['status'] == 'Published')
          .toList();

      // Sort by game date and time in ascending order (earliest first)
      publishedGames.sort((a, b) {
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
          '🎯 GAME SERVICE: Filtered and sorted ${publishedGames.length} published games by game date/time (ascending)');
      return publishedGames;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error fetching published games: $e');
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

  Future<bool> updateGame(
      String gameId, Map<String, dynamic> updatedData) async {
    try {
      debugPrint('🔄 GAME SERVICE: Updating game $gameId');

      // Get current user for authorization
      final authService = AuthService();
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        debugPrint('❌ GAME SERVICE: No authenticated user');
        return false;
      }

      // Check if user owns this game
      final gameDoc = await firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        debugPrint('❌ GAME SERVICE: Game not found');
        return false;
      }

      final gameData = gameDoc.data();
      if (gameData?['schedulerId'] != currentUser.uid &&
          gameData?['userId'] != currentUser.uid) {
        debugPrint('❌ GAME SERVICE: User not authorized to update this game');
        return false;
      }

      // Convert TimeOfDay objects to strings for Firestore storage
      final dataToUpdate = Map<String, dynamic>.from(updatedData);
      if (dataToUpdate['time'] is TimeOfDay) {
        final time = dataToUpdate['time'] as TimeOfDay;
        dataToUpdate['time'] =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }

      await firestore.collection('games').doc(gameId).update(dataToUpdate);

      debugPrint('✅ GAME SERVICE: Successfully updated game $gameId');
      return true;
    } catch (e) {
      debugPrint('❌ GAME SERVICE: Error updating game: $e');
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

  Future<bool> updateOfficialsHired(String gameId, int officialsHired) async {
    try {
      debugPrint(
          '🔄 GAME SERVICE: Updating officials hired for game $gameId to $officialsHired');

      final docRef = firestore.collection('games').doc(gameId);
      await docRef.update({'officialsHired': officialsHired});

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
      String gameId) async {
    try {
      debugPrint(
          '🔍 GAME SERVICE: Getting interested officials for game $gameId');

      final doc = await firestore.collection('games').doc(gameId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>;
      final interestedOfficials =
          data['interestedOfficials'] as List<dynamic>? ?? [];

      return interestedOfficials.map((official) {
        if (official is Map) {
          return Map<String, dynamic>.from(official);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to get interested officials: $e');
      return [];
    }
  }

  Future<bool> addInterestedOfficial(
      String gameId, Map<String, dynamic> officialData) async {
    try {
      debugPrint('➕ GAME SERVICE: Adding interested official to game $gameId');

      final docRef = firestore.collection('games').doc(gameId);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('🔴 GAME SERVICE: Game $gameId does not exist');
        return false;
      }

      // Get current interested officials
      final data = doc.data() as Map<String, dynamic>;
      final interestedOfficials =
          List<Map<String, dynamic>>.from(data['interestedOfficials'] ?? []);

      // Check if official is already interested
      final existingIndex = interestedOfficials
          .indexWhere((official) => official['id'] == officialData['id']);

      if (existingIndex >= 0) {
        debugPrint(
            '🔴 GAME SERVICE: Official already interested in game $gameId');
        return true; // Already interested, consider this success
      }

      // Add the official
      interestedOfficials.add(officialData);

      // Update the document
      await docRef.update({'interestedOfficials': interestedOfficials});

      debugPrint(
          '✅ GAME SERVICE: Successfully added interested official to game $gameId');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to add interested official: $e');
      return false;
    }
  }

  Future<bool> removeInterestedOfficial(
      String gameId, String officialId) async {
    try {
      debugPrint(
          '➖ GAME SERVICE: Removing interested official from game $gameId');

      final docRef = firestore.collection('games').doc(gameId);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('🔴 GAME SERVICE: Game $gameId does not exist');
        return false;
      }

      // Get current interested officials
      final data = doc.data() as Map<String, dynamic>;
      final interestedOfficials =
          List<Map<String, dynamic>>.from(data['interestedOfficials'] ?? []);

      // Remove the official
      interestedOfficials
          .removeWhere((official) => official['id'] == officialId);

      // Update the document
      await docRef.update({'interestedOfficials': interestedOfficials});

      debugPrint(
          '✅ GAME SERVICE: Successfully removed interested official from game $gameId');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to remove interested official: $e');
      return false;
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
      String gameId) async {
    try {
      debugPrint(
          '🔍 GAME SERVICE: Getting confirmed officials for game $gameId');

      final doc = await firestore.collection('games').doc(gameId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>;
      final confirmedOfficials =
          data['confirmedOfficials'] as List<dynamic>? ?? [];

      return confirmedOfficials.map((official) {
        if (official is Map) {
          return Map<String, dynamic>.from(official);
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to get confirmed officials: $e');
      return [];
    }
  }

  Future<bool> addConfirmedOfficial(
      String gameId, Map<String, dynamic> officialData) async {
    try {
      debugPrint('✅ GAME SERVICE: Adding confirmed official to game $gameId');

      final docRef = firestore.collection('games').doc(gameId);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('🔴 GAME SERVICE: Game $gameId does not exist');
        return false;
      }

      // Get current confirmed officials
      final data = doc.data() as Map<String, dynamic>;
      final confirmedOfficials =
          List<Map<String, dynamic>>.from(data['confirmedOfficials'] ?? []);

      // Check if official is already confirmed
      final existingIndex = confirmedOfficials
          .indexWhere((official) => official['id'] == officialData['id']);

      if (existingIndex >= 0) {
        debugPrint(
            '🔴 GAME SERVICE: Official already confirmed for game $gameId');
        return true; // Already confirmed, consider this success
      }

      // Add the official
      confirmedOfficials.add(officialData);

      // Update the document with both confirmed officials and updated count
      final newOfficialsHired = confirmedOfficials.length;
      await docRef.update({
        'confirmedOfficials': confirmedOfficials,
        'officialsHired': newOfficialsHired
      });

      // Update the official's totalAcceptedGames count
      final officialId = officialData['id'] as String;
      final userDoc =
          await firestore.collection('users').doc(officialId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final officialProfile =
              userData['officialProfile'] as Map<String, dynamic>?;
          if (officialProfile != null) {
            final totalAcceptedGames =
                (officialProfile['totalAcceptedGames'] ?? 0) + 1;

            await firestore.collection('users').doc(officialId).update({
              'officialProfile.totalAcceptedGames': totalAcceptedGames,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            debugPrint(
                '✅ GAME SERVICE: Updated totalAcceptedGames for official $officialId to $totalAcceptedGames');
          }
        }
      }

      debugPrint(
          '✅ GAME SERVICE: Successfully added confirmed official to game $gameId');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to add confirmed official: $e');
      return false;
    }
  }

  Future<bool> removeConfirmedOfficial(String gameId, String officialId) async {
    try {
      debugPrint(
          '🗑️ GAME SERVICE: Removing confirmed official from game $gameId');

      final docRef = firestore.collection('games').doc(gameId);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('🔴 GAME SERVICE: Game $gameId does not exist');
        return false;
      }

      // Get current confirmed officials
      final data = doc.data() as Map<String, dynamic>;
      final confirmedOfficials =
          List<Map<String, dynamic>>.from(data['confirmedOfficials'] ?? []);

      // Remove the official
      confirmedOfficials
          .removeWhere((official) => official['id'] == officialId);

      // Update the document with updated confirmed officials and count
      final newOfficialsHired = confirmedOfficials.length;
      await docRef.update({
        'confirmedOfficials': confirmedOfficials,
        'officialsHired': newOfficialsHired
      });

      debugPrint(
          '✅ GAME SERVICE: Successfully removed confirmed official from game $gameId');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to remove confirmed official: $e');
      return false;
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

  /// Back out of a game assignment
  Future<bool> backOutOfGame(
      String gameId, String officialId, String reason) async {
    try {
      debugPrint(
          '🔄 GAME SERVICE: Official $officialId backing out of game $gameId');
      debugPrint('🔄 GAME SERVICE: Reason: $reason');

      // Get game details for notification
      final gameDoc = await firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        debugPrint('🔴 GAME SERVICE: Game $gameId not found');
        return false;
      }
      final gameData = gameDoc.data() as Map<String, dynamic>;

      // Get schedule name if not in game data
      String scheduleName = gameData['scheduleName'] ?? 'Unknown Schedule';
      if (scheduleName == 'Unknown Schedule' && gameData['scheduleId'] != null) {
        try {
          final scheduleDoc = await firestore.collection('schedules').doc(gameData['scheduleId']).get();
          if (scheduleDoc.exists) {
            final scheduleData = scheduleDoc.data();
            if (scheduleData != null && scheduleData['name'] != null) {
              scheduleName = scheduleData['name'] as String;
              debugPrint('✅ GAME SERVICE: Retrieved schedule name from schedules collection: $scheduleName');
            }
          }
        } catch (e) {
          debugPrint('⚠️ GAME SERVICE: Error fetching schedule name: $e');
        }
      }

      // Remove the official from confirmed officials
      final success = await removeConfirmedOfficial(gameId, officialId);

      if (success) {
        // Get the scheduler ID (check both field names for backwards compatibility)
        final schedulerId = gameData['schedulerId'] ?? gameData['userId'];
        
        if (schedulerId == null) {
          debugPrint('⚠️ GAME SERVICE: No scheduler ID found in game data');
        }
        
        // Get official info for notification
        String officialName = 'Unknown Official';
        final officialDoc = await firestore.collection('users').doc(officialId).get();
        if (officialDoc.exists) {
          final officialData = officialDoc.data();
          if (officialData != null) {
            final profile = officialData['profile'] as Map<String, dynamic>?;
            if (profile != null) {
              final firstName = profile['firstName'] ?? '';
              final lastName = profile['lastName'] ?? '';
              officialName = '$firstName $lastName'.trim();
              if (officialName.isEmpty) officialName = 'Unknown Official';
            }
          }
        }
        
        // Update the official's follow-through stats
        if (officialDoc.exists) {
          final userData = officialDoc.data();
          if (userData != null) {
            // Remove the game from the user's confirmed games list
            final confirmedGameIds =
                List<String>.from(userData['confirmedGameIds'] ?? []);
            debugPrint('   Before removal: $confirmedGameIds');
            confirmedGameIds.remove(gameId);
            debugPrint('   After removal: $confirmedGameIds');

            // Update backed out games count
            final officialProfile =
                userData['officialProfile'] as Map<String, dynamic>?;
            if (officialProfile != null) {
              final totalBackedOutGames =
                  (officialProfile['totalBackedOutGames'] ?? 0) + 1;

              // Recalculate follow-through rate
              final totalAcceptedGames =
                  officialProfile['totalAcceptedGames'] ?? 0;
              double followThroughRate = 100.0;
              if (totalAcceptedGames > 0) {
                final successfulGames = totalAcceptedGames - totalBackedOutGames;
                followThroughRate = (successfulGames / totalAcceptedGames) * 100.0;
                followThroughRate = followThroughRate.clamp(0.0, 100.0);
              }

              await firestore.collection('users').doc(officialId).update({
                'confirmedGameIds': confirmedGameIds,
                'officialProfile.totalBackedOutGames': totalBackedOutGames,
                'officialProfile.followThroughRate': followThroughRate,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              debugPrint('✅ GAME SERVICE: Updated Firestore with confirmedGameIds: $confirmedGameIds');

              debugPrint(
                  '✅ GAME SERVICE: Updated follow-through stats for official $officialId');
              debugPrint('   Total accepted: $totalAcceptedGames');
              debugPrint('   Total backed out: $totalBackedOutGames');
              debugPrint(
                  '   Follow-through rate: ${followThroughRate.toStringAsFixed(1)}%');
            } else {
              // Just remove from confirmed games if no official profile
              await firestore.collection('users').doc(officialId).update({
                'confirmedGameIds': confirmedGameIds,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }

        // Store the back out in a collection for tracking
        final backOutId = await firestore.collection('back_outs').add({
          'gameId': gameId,
          'officialId': officialId,
          'officialName': officialName,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
          'excused': false, // Track whether this backout has been excused
          'reviewed': false, // Track whether scheduler has reviewed but not excused
          'gameSport': gameData['sport'],
          'gameDate': gameData['date'],
          'gameTime': gameData['time'],
          'gameOpponent': gameData['opponent'],
          'gameLocation': gameData['location'],
          'scheduleName': scheduleName,
          'schedulerId': schedulerId, // The scheduler who created the game
        });

        // Create a notification for the scheduler
        if (schedulerId != null) {
          await firestore.collection('notifications').add({
            'userId': schedulerId,
            'type': 'official_backed_out',
            'title': 'Official Backed Out',
            'message':
                '$officialName has backed out of your ${gameData['sport']} game vs ${gameData['opponent'] ?? 'TBD'}. You can excuse this backout to restore their follow-through rate.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': {
              'gameId': gameId,
              'officialId': officialId,
              'officialName': officialName,
              'backOutId': backOutId.id,
              'reason': reason,
              'gameSport': gameData['sport'],
              'gameDate': gameData['date'],
              'gameTime': gameData['time'],
              'gameOpponent': gameData['opponent'],
              'gameLocation': gameData['location'],
              'scheduleName': scheduleName,
            },
          });
        }

        debugPrint('✅ GAME SERVICE: Successfully backed out of game $gameId');
      }

      return success;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to back out of game: $e');
      return false;
    }
  }

  /// Excuse an official's backout and restore their follow-through rate
  Future<bool> excuseBackout(
      String backOutId, String schedulerId, String excuseReason) async {
    try {
      debugPrint('🔄 GAME SERVICE: Excusing backout $backOutId');

      // Get the backout details
      final backOutDoc =
          await firestore.collection('back_outs').doc(backOutId).get();
      if (!backOutDoc.exists) {
        debugPrint('🔴 GAME SERVICE: Backout $backOutId not found');
        return false;
      }

      final backOutData = backOutDoc.data() as Map<String, dynamic>;
      final officialId = backOutData['officialId'] as String;
      final gameId = backOutData['gameId'] as String;

      // Update the backout record to mark it as excused
      await firestore.collection('back_outs').doc(backOutId).update({
        'excused': true,
        'excusedBy': schedulerId,
        'excuseReason': excuseReason,
        'excusedAt': FieldValue.serverTimestamp(),
      });

      // Update the official's follow-through stats
      // When excused, both totalAcceptedGames and totalBackedOutGames are decremented
      // so the game doesn't count in the calculation at all
      final userDoc =
          await firestore.collection('users').doc(officialId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final officialProfile =
              userData['officialProfile'] as Map<String, dynamic>?;
          if (officialProfile != null) {
            final totalAcceptedGames =
                (officialProfile['totalAcceptedGames'] ?? 0) - 1;
            final totalBackedOutGames =
                (officialProfile['totalBackedOutGames'] ?? 0) - 1;

            // Recalculate follow-through rate
            double followThroughRate = 100.0;
            if (totalAcceptedGames > 0) {
              final successfulGames = totalAcceptedGames - totalBackedOutGames;
              followThroughRate = (successfulGames / totalAcceptedGames) * 100.0;
              followThroughRate = followThroughRate.clamp(0.0, 100.0);
            }

            await firestore.collection('users').doc(officialId).update({
              'officialProfile.totalAcceptedGames': totalAcceptedGames.clamp(0, double.infinity).toInt(),
              'officialProfile.totalBackedOutGames': totalBackedOutGames.clamp(0, double.infinity).toInt(),
              'officialProfile.followThroughRate': followThroughRate,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            debugPrint(
                '✅ GAME SERVICE: Restored follow-through stats for official $officialId');
            debugPrint('   Total accepted: $totalAcceptedGames');
            debugPrint('   Total backed out: $totalBackedOutGames');
            debugPrint(
                '   Follow-through rate: ${followThroughRate.toStringAsFixed(1)}%');

            // Get scheduler info for the notification
            final schedulerDoc =
                await firestore.collection('users').doc(schedulerId).get();
            String schedulerName = 'The scheduler';
            if (schedulerDoc.exists) {
              final schedulerData = schedulerDoc.data();
              if (schedulerData != null) {
                final profile =
                    schedulerData['profile'] as Map<String, dynamic>?;
                if (profile != null) {
                  final firstName = profile['firstName'] ?? '';
                  final lastName = profile['lastName'] ?? '';
                  schedulerName = '$firstName $lastName'.trim();
                  if (schedulerName.isEmpty) schedulerName = 'The scheduler';
                }
              }
            }

            // Create a notification for the official
            await firestore.collection('notifications').add({
              'userId': officialId,
              'type': 'backout_excused',
              'title': 'Backout Excused - Follow-Through Rate Restored',
              'message':
                  'Your backout for the ${backOutData['gameSport']} game (${backOutData['gameOpponent']}) has been excused by $schedulerName. Your follow-through rate has been restored. Reason: $excuseReason',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
              'data': {
                'gameId': gameId,
                'backOutId': backOutId,
                'schedulerId': schedulerId,
                'schedulerName': schedulerName,
              },
            });
          }
        }
      }

      debugPrint('✅ GAME SERVICE: Successfully excused backout $backOutId');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to excuse backout: $e');
      return false;
    }
  }

  /// Get all pending (unexcused and not reviewed) backouts for games created by the scheduler
  Future<List<Map<String, dynamic>>> getPendingBackouts(
      String schedulerId) async {
    try {
      debugPrint(
          '🔍 GAME SERVICE: Getting pending backouts for scheduler $schedulerId');

      // Query for backouts where the scheduler matches and not excused
      // We'll filter out reviewed ones in memory since we can't do multiple inequality filters
      final querySnapshot = await firestore
          .collection('back_outs')
          .where('schedulerId', isEqualTo: schedulerId)
          .where('excused', isEqualTo: false)
          .get();

      final backouts = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Skip if already reviewed
        if (data['reviewed'] == true) continue;
        
        // Use officialName from stored data first, fall back to lookup if needed
        String officialName = data['officialName'] as String? ?? '';
        
        if (officialName.isEmpty) {
          // Get official info if not stored
          final officialId = data['officialId'] as String;
          final officialDoc =
              await firestore.collection('users').doc(officialId).get();
          
          if (officialDoc.exists) {
            final officialData = officialDoc.data();
            if (officialData != null) {
              final profile =
                  officialData['profile'] as Map<String, dynamic>?;
              if (profile != null) {
                final firstName = profile['firstName'] ?? '';
                final lastName = profile['lastName'] ?? '';
                officialName = '$firstName $lastName'.trim();
              }
            }
          }
          if (officialName.isEmpty) officialName = 'Unknown Official';
        }

        backouts.add({
          ...data,
          'id': doc.id,
          'officialName': officialName,
        });
      }

      // Sort by timestamp (most recent first)
      backouts.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      debugPrint(
          '✅ GAME SERVICE: Found ${backouts.length} pending backouts for scheduler');
      return backouts;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to get pending backouts: $e');
      return [];
    }
  }

  /// Mark a backout as reviewed (but not excused) - it won't show in notifications anymore
  Future<bool> markBackoutAsReviewed(String backOutId) async {
    try {
      debugPrint('🔄 GAME SERVICE: Marking backout $backOutId as reviewed');

      await firestore.collection('back_outs').doc(backOutId).update({
        'reviewed': true,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ GAME SERVICE: Successfully marked backout as reviewed');
      return true;
    } catch (e) {
      debugPrint('🔴 GAME SERVICE: Failed to mark backout as reviewed: $e');
      return false;
    }
  }
}
