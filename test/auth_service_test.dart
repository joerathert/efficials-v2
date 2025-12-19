import 'package:flutter_test/flutter_test.dart';
import 'package:efficials_v2/services/auth_service.dart';
import 'package:efficials_v2/models/user_model.dart';

void main() {
  group('AuthService Tests', () {
    test('AuthService is singleton', () {
      final instance1 = AuthService();
      final instance2 = AuthService();
      expect(identical(instance1, instance2), true);
    });

    test('AuthResult.success creates success result', () {
      final profile = ProfileData(
        firstName: 'Test',
        lastName: 'User',
        phone: '5555555555',
      );

      final schedulerProfile = SchedulerProfile.athleticDirector(
        schoolName: 'Test School',
        teamName: 'Test Team',
        schoolAddress: 'Test Address',
      );

      final user = UserModel.scheduler(
        id: 'test-id',
        email: 'test@test.com',
        profile: profile,
        schedulerProfile: schedulerProfile,
      );

      final result = AuthResult.success(user);

      expect(result.success, true);
      expect(result.error, null);
      expect(result.user, user);
    });

    test('AuthResult.failure creates failure result', () {
      const errorMessage = 'Test error';
      final result = AuthResult.failure(errorMessage);

      expect(result.success, false);
      expect(result.error, errorMessage);
      expect(result.user, null);
    });

    test('UserModel factory constructors create correct user types', () {
      // Test scheduler user creation
      final schedulerUser = UserModel.scheduler(
        id: 'scheduler-id',
        email: 'scheduler@test.com',
        profile: ProfileData(
          firstName: 'Scheduler',
          lastName: 'User',
          phone: '5551111111',
        ),
        schedulerProfile: SchedulerProfile.athleticDirector(
          schoolName: 'Test School',
          teamName: 'Test Team',
          schoolAddress: 'Test Address',
        ),
      );

      expect(schedulerUser.role, 'scheduler');
      expect(schedulerUser.isScheduler, true);
      expect(schedulerUser.isOfficial, false);
      expect(schedulerUser.schedulerType, 'Athletic Director');

      // Test official user creation
      final officialUser = UserModel.official(
        id: 'official-id',
        email: 'official@test.com',
        profile: ProfileData(
          firstName: 'Official',
          lastName: 'User',
          phone: '5552222222',
        ),
        officialProfile: OfficialProfile(
          city: 'Test City',
          state: 'TS',
        ),
      );

      expect(officialUser.role, 'official');
      expect(officialUser.isScheduler, false);
      expect(officialUser.isOfficial, true);
      expect(officialUser.schedulerType, null);
    });

    test('UserModel copyWith creates modified copy', () {
      final originalUser = UserModel.scheduler(
        id: 'original-id',
        email: 'original@test.com',
        profile: ProfileData(
          firstName: 'Original',
          lastName: 'User',
          phone: '5550000000',
        ),
        schedulerProfile: SchedulerProfile.athleticDirector(
          schoolName: 'Original School',
          teamName: 'Original Team',
          schoolAddress: 'Original Address',
        ),
      );

      final updatedUser = originalUser.copyWith(
        email: 'updated@test.com',
        profile: ProfileData(
          firstName: 'Updated',
          lastName: 'User',
          phone: '5559999999',
        ),
      );

      // Original user unchanged
      expect(originalUser.email, 'original@test.com');
      expect(originalUser.profile.firstName, 'Original');

      // Updated user has changes
      expect(updatedUser.email, 'updated@test.com');
      expect(updatedUser.profile.firstName, 'Updated');
      expect(updatedUser.profile.lastName, 'User');
      expect(updatedUser.profile.phone, '5559999999');

      // ID remains the same
      expect(updatedUser.id, 'original-id');
    });

    test('UserModel fullName property works correctly', () {
      final user = UserModel.scheduler(
        id: 'test-id',
        email: 'test@test.com',
        profile: ProfileData(
          firstName: 'John',
          lastName: 'Doe',
          phone: '5555555555',
        ),
        schedulerProfile: SchedulerProfile.athleticDirector(
          schoolName: 'Test School',
          teamName: 'Test Team',
          schoolAddress: 'Test Address',
        ),
      );

      expect(user.fullName, 'John Doe');
    });
  });

  group('Data Flow Integration Tests', () {
    test('Complete scheduler signup data flow works end-to-end', () {
      // Simulate the complete signup flow from role selection to user creation

      // Step 1: Role selection (UI only, no data)
      const selectedRole = 'scheduler';

      // Step 2: Basic profile collection
      final basicProfileData = {
        'email': 'john.doe@example.com',
        'password': 'securePassword123',
        'firstName': 'John',
        'lastName': 'Doe',
        'phone': '5551234567',
        'role': selectedRole,
      };

      // Step 3: Scheduler type selection
      const schedulerType = 'Athletic Director';
      final schedulerProfileData = {
        'type': schedulerType,
        'schoolName': 'Example High School',
        'teamName': 'Example Eagles',
        'schoolAddress': '123 School St, Example City, EX 12345',
      };

      // Step 4: Create ProfileData object
      final profile = ProfileData(
        firstName: basicProfileData['firstName'] as String,
        lastName: basicProfileData['lastName'] as String,
        phone: basicProfileData['phone'] as String,
      );

      // Step 5: Create SchedulerProfile object
      final schedulerProfile = SchedulerProfile(
        type: schedulerProfileData['type'] as String,
        schoolName: schedulerProfileData['schoolName'] as String,
        teamName: schedulerProfileData['teamName'] as String,
        schoolAddress: schedulerProfileData['schoolAddress'] as String,
      );

      // Step 6: Create UserModel
      final userId = 'firebase-auth-generated-id';
      final user = UserModel.scheduler(
        id: userId,
        email: basicProfileData['email'] as String,
        profile: profile,
        schedulerProfile: schedulerProfile,
      );

      // Step 7: Verify the complete user object
      expect(user.id, userId);
      expect(user.email, 'john.doe@example.com');
      expect(user.role, 'scheduler');
      expect(user.isScheduler, true);
      expect(user.schedulerType, 'Athletic Director');
      expect(user.fullName, 'John Doe');
      expect(user.profile.phone, '5551234567');
      expect(user.schedulerProfile?.schoolName, 'Example High School');
      expect(user.schedulerProfile?.teamName, 'Example Eagles');

      // Step 8: Test serialization to Firestore format
      final userMap = user.toMap();

      // Verify Firestore document structure
      expect(userMap['id'], userId);
      expect(userMap['email'], 'john.doe@example.com');
      expect(userMap['role'], 'scheduler');
      expect(userMap['profile']['firstName'], 'John');
      expect(userMap['profile']['lastName'], 'Doe');
      expect(userMap['profile']['phone'], '5551234567');
      expect(userMap['schedulerProfile']['type'], 'Athletic Director');
      expect(userMap['schedulerProfile']['schoolName'], 'Example High School');
      expect(userMap['schedulerProfile']['teamName'], 'Example Eagles');
      expect(userMap['schedulerProfile']['schoolAddress'],
          '123 School St, Example City, EX 12345');

      // Step 9: Test deserialization from Firestore
      final userFromFirestore = UserModel.fromMap(userMap);
      expect(userFromFirestore.id, user.id);
      expect(userFromFirestore.email, user.email);
      expect(userFromFirestore.fullName, user.fullName);
      expect(userFromFirestore.schedulerProfile?.schoolName,
          user.schedulerProfile?.schoolName);

      print('✅ Complete scheduler signup data flow test passed!');
      print('User ID: ${user.id}');
      print('Email: ${user.email}');
      print('Role: ${user.role} (${user.schedulerType})');
      print('Name: ${user.fullName}');
      print('Phone: ${user.profile.phone}');
      print('School: ${user.schedulerProfile?.schoolName}');
      print('Team: ${user.schedulerProfile?.teamName}');
    });

    test('Official signup data flow works end-to-end', () {
      // Step 1: Role selection
      const selectedRole = 'official';

      // Step 2: Basic profile collection
      final basicProfileData = {
        'email': 'jane.smith@example.com',
        'password': 'securePassword456',
        'firstName': 'Jane',
        'lastName': 'Smith',
        'phone': '5559876543',
        'role': selectedRole,
      };

      // Step 3: Official profile collection with sport-specific data
      final officialProfileData = {
        'address': '456 Referee Ave',
        'city': 'Referee City',
        'state': 'RC',
        'bio': 'Enthusiastic referee looking to officiate games',
        'ratePerGame': 50.0,
        'maxTravelDistance': 25,
      };

      // Step 4: Sports-specific data (per sport as collected in official_step4_screen)
      final selectedSports = {
        'Basketball': {
          'certification': 'Certified',
          'experience': 5,
          'competitionLevels': ['Varsity', 'JV'],
        },
        'Football': {
          'certification': 'Recognized',
          'experience': 3,
          'competitionLevels': ['Varsity'],
        },
      };

      // Step 5: Create ProfileData object
      final profile = ProfileData(
        firstName: basicProfileData['firstName'] as String,
        lastName: basicProfileData['lastName'] as String,
        phone: basicProfileData['phone'] as String,
      );

      // Step 6: Convert selectedSports to sportsData format (as done in official_step4_screen)
      final sportsData = <String, Map<String, dynamic>>{};
      for (final entry in selectedSports.entries) {
        final sportName = entry.key;
        final sportData = entry.value;
        sportsData[sportName] = {
          'certificationLevel':
              sportData['certification'] ?? 'No Certification',
          'yearsExperience': sportData['experience'] ?? 0,
          'competitionLevels': sportData['competitionLevels'] ?? [],
        };
      }

      // Calculate max experience from all sports
      int maxExperience = 0;
      for (final sportData in selectedSports.values) {
        final experience = sportData['experience'] as int? ?? 0;
        if (experience > maxExperience) {
          maxExperience = experience;
        }
      }

      // Step 7: Create OfficialProfile object
      final officialProfile = OfficialProfile(
        address: officialProfileData['address'] as String,
        city: officialProfileData['city'] as String,
        state: officialProfileData['state'] as String,
        experienceYears: maxExperience, // Overall max experience
        certificationLevel: 'Certified', // Highest certification level
        bio: officialProfileData['bio'] as String,
        sportsData: sportsData, // Per-sport detailed data
        ratePerGame: officialProfileData['ratePerGame'] as double,
        maxTravelDistance: officialProfileData['maxTravelDistance'] as int,
      );

      // Step 6: Create UserModel
      final userId = 'official-firebase-auth-id';
      final user = UserModel.official(
        id: userId,
        email: basicProfileData['email'] as String,
        profile: profile,
        officialProfile: officialProfile,
      );

      // Step 8: Verify the complete user object
      expect(user.id, userId);
      expect(user.email, 'jane.smith@example.com');
      expect(user.role, 'official');
      expect(user.isOfficial, true);
      expect(user.isScheduler, false);
      expect(user.fullName, 'Jane Smith');
      expect(user.profile.phone, '5559876543');
      expect(user.officialProfile?.city, 'Referee City');
      expect(user.officialProfile?.experienceYears,
          5); // Max experience from Basketball
      expect(user.officialProfile?.ratePerGame, 50.0);

      // Verify sports-specific data
      expect(user.officialProfile?.sportsData, isNotNull);
      expect(user.officialProfile?.sportsData?.length, 2);

      // Check Basketball data
      final basketballData = user.officialProfile?.sportsData?['Basketball'];
      expect(basketballData, isNotNull);
      expect(basketballData?['certificationLevel'], 'Certified');
      expect(basketballData?['yearsExperience'], 5);
      expect(basketballData?['competitionLevels'], ['Varsity', 'JV']);

      // Check Football data
      final footballData = user.officialProfile?.sportsData?['Football'];
      expect(footballData, isNotNull);
      expect(footballData?['certificationLevel'], 'Recognized');
      expect(footballData?['yearsExperience'], 3);
      expect(footballData?['competitionLevels'], ['Varsity']);

      // Step 8: Test serialization to Firestore format
      final userMap = user.toMap();

      // Verify Firestore document structure
      expect(userMap['id'], userId);
      expect(userMap['email'], 'jane.smith@example.com');
      expect(userMap['role'], 'official');
      expect(userMap['profile']['firstName'], 'Jane');
      expect(userMap['profile']['lastName'], 'Smith');
      expect(userMap['profile']['phone'], '5559876543');
      expect(userMap['officialProfile']['address'], '456 Referee Ave');
      expect(userMap['officialProfile']['city'], 'Referee City');
      expect(userMap['officialProfile']['state'], 'RC');
      expect(
          userMap['officialProfile']['experienceYears'], 5); // Max experience
      expect(userMap['officialProfile']['certificationLevel'],
          'Certified'); // Highest certification
      expect(userMap['officialProfile']['bio'],
          'Enthusiastic referee looking to officiate games');
      expect(userMap['officialProfile']['ratePerGame'], 50.0);
      expect(userMap['officialProfile']['maxTravelDistance'], 25);

      // Verify sportsData structure in Firestore
      expect(userMap['officialProfile']['sportsData'], isNotNull);
      expect(
          userMap['officialProfile']['sportsData']['Basketball']
              ['certificationLevel'],
          'Certified');
      expect(
          userMap['officialProfile']['sportsData']['Basketball']
              ['yearsExperience'],
          5);
      expect(
          userMap['officialProfile']['sportsData']['Basketball']
              ['competitionLevels'],
          ['Varsity', 'JV']);
      expect(
          userMap['officialProfile']['sportsData']['Football']
              ['certificationLevel'],
          'Recognized');
      expect(
          userMap['officialProfile']['sportsData']['Football']
              ['yearsExperience'],
          3);
      expect(
          userMap['officialProfile']['sportsData']['Football']
              ['competitionLevels'],
          ['Varsity']);

      // Step 9: Test deserialization from Firestore
      final userFromFirestore = UserModel.fromMap(userMap);
      expect(userFromFirestore.id, user.id);
      expect(userFromFirestore.email, user.email);
      expect(userFromFirestore.fullName, user.fullName);
      expect(
          userFromFirestore.officialProfile?.city, user.officialProfile?.city);

      print('✅ Complete official signup data flow test passed!');
      print('User ID: ${user.id}');
      print('Email: ${user.email}');
      print('Role: ${user.role}');
      print('Name: ${user.fullName}');
      print('Phone: ${user.profile.phone}');
      print('City: ${user.officialProfile?.city}');
      print(
          'Overall Experience: ${user.officialProfile?.experienceYears} years (max across all sports)');
      print(
          'Highest Certification: ${user.officialProfile?.certificationLevel}');
      print('Rate: \$${user.officialProfile?.ratePerGame}/game');
      print('Sports Data:');
      user.officialProfile?.sportsData?.forEach((sport, data) {
        print(
            '  $sport: ${data['yearsExperience']} years, ${data['certificationLevel']}, ${data['competitionLevels'].join(', ')}');
      });
    });

    test(
        'AuthService signUpWithEmailAndPassword method exists and has correct signature',
        () {
      final authService = AuthService();

      // Verify the method exists and can be called (though we can't test it without mocks)
      // This test mainly ensures the method signature is correct
      expect(authService, isNotNull);

      // Test that we can access the method (compile-time check)
      final method = authService.signUpWithEmailAndPassword;
      expect(method, isNotNull);
    });

    test(
        'AuthService signInWithEmailAndPassword method exists and has correct signature',
        () {
      final authService = AuthService();

      // Verify the method exists and can be called
      expect(authService, isNotNull);

      // Test that we can access the method (compile-time check)
      final method = authService.signInWithEmailAndPassword;
      expect(method, isNotNull);
    });

    test('AuthService authStateChanges stream exists', () {
      final authService = AuthService();

      // Verify the stream exists
      final stream = authService.authStateChanges;
      expect(stream, isNotNull);
    });

    test('AuthService currentUser getter exists', () {
      final authService = AuthService();

      // Verify the getter exists
      final user = authService.currentUser;
      // user can be null, so we just check it doesn't throw an error
      expect(() => authService.currentUser, returnsNormally);
    });
  });
}
