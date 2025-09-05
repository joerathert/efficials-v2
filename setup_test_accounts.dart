import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efficials_v2/firebase_options.dart';
import 'package:efficials_v2/models/user_model.dart';
import 'package:efficials_v2/services/user_service.dart';

/// Setup script to create test user accounts for development
/// Run this once to create the test accounts in Firebase
Future<void> setupTestAccounts() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;
    final userService = UserService();

    print('Setting up test accounts...');

    // Test accounts data
    final testAccounts = [
      {
        'email': 'ad.test@efficials.com',
        'password': 'test123456',
        'firstName': 'Alex',
        'lastName': 'Director',
        'role': 'scheduler',
        'schedulerType': 'athletic_director',
        'school': 'Test High School',
      },
      {
        'email': 'coach.test@efficials.com',
        'password': 'test123456',
        'firstName': 'Chris',
        'lastName': 'Coach',
        'role': 'scheduler',
        'schedulerType': 'coach',
        'school': 'Test High School',
        'teamName': 'Varsity Football',
      },
      {
        'email': 'assigner.test@efficials.com',
        'password': 'test123456',
        'firstName': 'Andy',
        'lastName': 'Assigner',
        'role': 'scheduler',
        'schedulerType': 'assigner',
        'school': 'Test High School',
      },
      {
        'email': 'official.test@efficials.com',
        'password': 'test123456',
        'firstName': 'Olivia',
        'lastName': 'Official',
        'role': 'official',
        'school': 'Test High School',
      },
    ];

    for (final account in testAccounts) {
      try {
        // Create user profile
        final profile = ProfileData(
          firstName: account['firstName'] as String,
          lastName: account['lastName'] as String,
          school: account['school'] as String,
        );

        UserModel userModel;

        if (account['role'] == 'scheduler') {
          final schedulerProfile = SchedulerProfile(
            school: account['school'] as String,
            schedulerType: account['schedulerType'] as String,
            teamName: account['teamName'] as String?,
          );

          userModel = UserModel.scheduler(
            id: '', // Will be set by Firestore
            email: account['email'] as String,
            profile: profile,
            schedulerProfile: schedulerProfile,
          );
        } else {
          final officialProfile = OfficialProfile(
            school: account['school'] as String,
          );

          userModel = UserModel.official(
            id: '', // Will be set by Firestore
            email: account['email'] as String,
            profile: profile,
            officialProfile: officialProfile,
          );
        }

        // Note: This setup script is for reference only.
        // You'll need to manually create these accounts through the app's registration flow
        // or create them directly in Firebase Console.

        print('Test account setup reference:');
        print('Email: ${account['email']}');
        print('Password: ${account['password']}');
        print('Role: ${account['role']}');
        print('Type: ${account['schedulerType'] ?? 'official'}');
        print('---');
      } catch (e) {
        print('Error setting up account ${account['email']}: $e');
      }
    }

    print('\nTest accounts setup complete!');
    print('\nTo use these accounts:');
    print('1. Create accounts manually through the app registration flow');
    print('2. Or create them directly in Firebase Authentication Console');
    print(
        '3. Use the Quick Access buttons on the home screen for instant sign-in');
  } catch (e) {
    print('Error setting up test accounts: $e');
  }
}

void main() async {
  await setupTestAccounts();
}
