import '../models/game_template_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import '../constants/firebase_constants.dart';

// Add this typedef for clarity
typedef ScheduleData = Map<String, Object>;

class GameService {
  // Mock data for development - replace with actual Firebase/database calls

  Future<List<GameTemplateModel>> getTemplates() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      GameTemplateModel(
        id: '1',
        name: 'Varsity Basketball Game',
        sport: 'Basketball',
        includeSport: true,
        description:
            'Standard varsity basketball game template with 3 officials',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        includeScheduleName: true,
        includeDate: true,
        includeTime: true,
        includeLocation: true,
        includeOpponent: true,
        includeOfficialsRequired: true,
        officialsRequired: 3,
        includeGameFee: true,
        gameFee: '150.00',
      ),
      GameTemplateModel(
        id: '2',
        name: 'JV Soccer Match',
        sport: 'Soccer',
        includeSport: true,
        description: 'Junior varsity soccer game template with 2 officials',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        includeScheduleName: true,
        includeDate: true,
        includeTime: true,
        includeLocation: true,
        includeOpponent: true,
        includeOfficialsRequired: true,
        officialsRequired: 2,
        includeGameFee: true,
        gameFee: '100.00',
      ),
      GameTemplateModel(
        id: '3',
        name: 'Football Championship',
        sport: 'Football',
        includeSport: true,
        description: 'Championship football game template with 7 officials',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        includeScheduleName: true,
        includeDate: true,
        includeTime: true,
        includeLocation: true,
        includeOpponent: true,
        includeLevelOfCompetition: true,
        levelOfCompetition: 'Championship',
        includeOfficialsRequired: true,
        officialsRequired: 7,
        includeGameFee: true,
        gameFee: '300.00',
      ),
    ];
  }

  Future<bool> deleteTemplate(String templateId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    // In a real implementation, this would make an API call to delete the template
    // For now, just return success
    return true;
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
      final querySnapshot = await FirebaseFirestore.instance
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
      final existingSchedulesQuery = await FirebaseFirestore.instance
          .collection(FirebaseCollections.schedules)
          .where(FirebaseFields.createdBy, isEqualTo: currentUserId)
          .where(FirebaseFields.name, isEqualTo: name)
          .get();

      if (existingSchedulesQuery.docs.isNotEmpty) {
        throw Exception(
            'A schedule with the name "$name" already exists. Please choose a different name.');
      }

      // Save to Firebase Firestore
      final docRef = await FirebaseFirestore.instance
          .collection(FirebaseCollections.schedules)
          .add({
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
}
