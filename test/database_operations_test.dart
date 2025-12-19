import 'package:flutter_test/flutter_test.dart';
import 'package:efficials_v2/models/user_model.dart';
import 'package:efficials_v2/constants/firebase_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserModel Data Mapping Tests', () {
    test('UserModel scheduler creation and mapping works correctly', () {
      // Create a scheduler user
      final schedulerProfile = SchedulerProfile.athleticDirector(
        schoolName: 'Test High School',
        teamName: 'Test Tigers',
        schoolAddress: AddressData(
          address: '123 Main St',
          city: 'Test City',
          state: 'TS',
          zipCode: '12345',
        ),
      );

      final profile = ProfileData(
        firstName: 'John',
        lastName: 'Doe',
        phone: '5551234567',
      );

      final user = UserModel.scheduler(
        id: 'test-user-id',
        email: 'john.doe@test.com',
        profile: profile,
        schedulerProfile: schedulerProfile,
      );

      // Verify basic properties
      expect(user.id, 'test-user-id');
      expect(user.email, 'john.doe@test.com');
      expect(user.role, 'scheduler');
      expect(user.isScheduler, true);
      expect(user.isOfficial, false);
      expect(user.schedulerType, 'Athletic Director');
      expect(user.fullName, 'John Doe');

      // Test toMap conversion
      final map = user.toMap();

      // Verify map structure
      expect(map['id'], 'test-user-id');
      expect(map['email'], 'john.doe@test.com');
      expect(map['role'], 'scheduler');
      expect(map['profile']['firstName'], 'John');
      expect(map['profile']['lastName'], 'Doe');
      expect(map['profile']['phone'], '5551234567');
      expect(map['schedulerProfile']['type'], 'Athletic Director');
      expect(map['schedulerProfile']['schoolName'], 'Test High School');
      expect(map['schedulerProfile']['teamName'], 'Test Tigers');
      expect(
          map['schedulerProfile']['schoolAddress']['address'], '123 Main St');
      expect(map['schedulerProfile']['schoolAddress']['city'], 'Test City');
      expect(map['schedulerProfile']['schoolAddress']['state'], 'TS');
      expect(map['schedulerProfile']['schoolAddress']['zipCode'], '12345');

      // Test fromMap conversion
      final userFromMap = UserModel.fromMap(map);

      // Verify round-trip conversion
      expect(userFromMap.id, user.id);
      expect(userFromMap.email, user.email);
      expect(userFromMap.role, user.role);
      expect(userFromMap.profile.firstName, user.profile.firstName);
      expect(userFromMap.profile.lastName, user.profile.lastName);
      expect(userFromMap.profile.phone, user.profile.phone);
      expect(userFromMap.schedulerProfile?.type, user.schedulerProfile?.type);
      expect(userFromMap.schedulerProfile?.schoolName,
          user.schedulerProfile?.schoolName);
      expect(userFromMap.schedulerProfile?.teamName,
          user.schedulerProfile?.teamName);
    });

    test('UserModel official creation and mapping works correctly', () {
      // Create an official user
      final officialProfile = OfficialProfile(
        city: 'Test City',
        state: 'TS',
        experienceYears: 5,
        certificationLevel: 'Level 1',
        availabilityStatus: 'available',
        followThroughRate: 95.0,
        totalAcceptedGames: 25,
        totalBackedOutGames: 1,
        bio: 'Experienced referee with 5 years of experience',
        ratePerGame: 75.0,
        maxTravelDistance: 50,
        schedulerEndorsements: 3,
        officialEndorsements: 7,
      );

      final profile = ProfileData(
        firstName: 'Jane',
        lastName: 'Smith',
        phone: '5559876543',
      );

      final user = UserModel.official(
        id: 'test-official-id',
        email: 'jane.smith@test.com',
        profile: profile,
        officialProfile: officialProfile,
      );

      // Verify basic properties
      expect(user.id, 'test-official-id');
      expect(user.email, 'jane.smith@test.com');
      expect(user.role, 'official');
      expect(user.isScheduler, false);
      expect(user.isOfficial, true);
      expect(user.fullName, 'Jane Smith');

      // Test toMap conversion
      final map = user.toMap();

      // Verify map structure
      expect(map['id'], 'test-official-id');
      expect(map['email'], 'jane.smith@test.com');
      expect(map['role'], 'official');
      expect(map['profile']['firstName'], 'Jane');
      expect(map['profile']['lastName'], 'Smith');
      expect(map['profile']['phone'], '5559876543');
      expect(map['officialProfile']['city'], 'Test City');
      expect(map['officialProfile']['state'], 'TS');
      expect(map['officialProfile']['experienceYears'], 5);
      expect(map['officialProfile']['certificationLevel'], 'Level 1');
      expect(map['officialProfile']['availabilityStatus'], 'available');
      expect(map['officialProfile']['followThroughRate'], 95.0);
      expect(map['officialProfile']['totalAcceptedGames'], 25);
      expect(map['officialProfile']['totalBackedOutGames'], 1);
      expect(map['officialProfile']['bio'],
          'Experienced referee with 5 years of experience');
      expect(map['officialProfile']['ratePerGame'], 75.0);
      expect(map['officialProfile']['maxTravelDistance'], 50);
      expect(map['officialProfile']['schedulerEndorsements'], 3);
      expect(map['officialProfile']['officialEndorsements'], 7);

      // Test fromMap conversion
      final userFromMap = UserModel.fromMap(map);

      // Verify round-trip conversion
      expect(userFromMap.id, user.id);
      expect(userFromMap.email, user.email);
      expect(userFromMap.role, user.role);
      expect(userFromMap.profile.firstName, user.profile.firstName);
      expect(userFromMap.profile.lastName, user.profile.lastName);
      expect(userFromMap.profile.phone, user.profile.phone);
      expect(userFromMap.officialProfile?.city, user.officialProfile?.city);
      expect(userFromMap.officialProfile?.state, user.officialProfile?.state);
      expect(userFromMap.officialProfile?.experienceYears,
          user.officialProfile?.experienceYears);
      expect(userFromMap.officialProfile?.certificationLevel,
          user.officialProfile?.certificationLevel);
    });

    test('ProfileData mapping works correctly', () {
      final profile = ProfileData(
        firstName: 'Test',
        lastName: 'User',
        phone: '5555555555',
        profileImageUrl: 'https://example.com/image.jpg',
      );

      final map = profile.toMap();
      expect(map['firstName'], 'Test');
      expect(map['lastName'], 'User');
      expect(map['phone'], '5555555555');
      expect(map['profileImageUrl'], 'https://example.com/image.jpg');

      final profileFromMap = ProfileData.fromMap(map);
      expect(profileFromMap.firstName, profile.firstName);
      expect(profileFromMap.lastName, profile.lastName);
      expect(profileFromMap.phone, profile.phone);
      expect(profileFromMap.profileImageUrl, profile.profileImageUrl);
    });

    test('SchedulerProfile factory constructors work correctly', () {
      // Test Athletic Director
      final adProfile = SchedulerProfile.athleticDirector(
        schoolName: 'School A',
        teamName: 'Team A',
        schoolAddress: AddressData(
          address: 'Address A',
          city: 'City A',
          state: 'ST',
          zipCode: '12345',
        ),
      );

      expect(adProfile.type, 'Athletic Director');
      expect(adProfile.schoolName, 'School A');
      expect(adProfile.teamName, 'Team A');
      expect(adProfile.schoolAddress?.address, 'Address A');
      expect(adProfile.schoolAddress?.city, 'City A');

      // Test Coach
      final coachProfile = SchedulerProfile.coach(
        teamName: 'Team B',
        sport: 'Basketball',
        levelOfCompetition: 'Varsity',
        gender: 'Boys',
        defaultLocationName: 'Location B',
        defaultLocationAddress: '123 Location St, City B, ST 12345',
      );

      expect(coachProfile.type, 'Coach');
      expect(coachProfile.teamName, 'Team B');
      expect(coachProfile.sport, 'Basketball');
      expect(coachProfile.levelOfCompetition, 'Varsity');
      expect(coachProfile.gender, 'Boys');
      expect(coachProfile.defaultLocationName, 'Location B');
      expect(coachProfile.defaultLocationAddress,
          '123 Location St, City B, ST 12345');

      // Test Assigner
      final assignerProfile = SchedulerProfile.assigner(
        organizationName: 'Org C',
        sport: 'Soccer',
        homeAddress: AddressData(
          address: '123 Main St',
          city: 'City C',
          state: 'ST',
          zipCode: '12345',
        ),
      );

      expect(assignerProfile.type, 'Assigner');
      expect(assignerProfile.organizationName, 'Org C');
      expect(assignerProfile.sport, 'Soccer');
      expect(assignerProfile.homeAddress?.address, '123 Main St');
      expect(assignerProfile.homeAddress?.city, 'City C');
    });

    test('SchedulerProfile helper methods work correctly', () {
      // Test Athletic Director home team name
      final adProfile = SchedulerProfile.athleticDirector(
        schoolName: 'School A',
        teamName: 'Tigers',
        schoolAddress: AddressData(
          address: 'Address A',
          city: 'City A',
          state: 'ST',
          zipCode: '12345',
        ),
      );
      expect(adProfile.getHomeTeamName(), 'Tigers');

      // Test Coach home team name
      final coachProfile = SchedulerProfile.coach(
        teamName: 'JV Basketball',
        sport: 'Basketball',
        levelOfCompetition: 'JV',
        gender: 'Boys',
        defaultLocationName: 'Location 123',
        defaultLocationAddress: '123 Location St, City, ST 12345',
      );
      expect(coachProfile.getHomeTeamName(), 'JV Basketball');

      // Test Assigner home team name (should be null)
      final assignerProfile = SchedulerProfile.assigner(
        organizationName: 'Org C',
        sport: 'Soccer',
        homeAddress: AddressData(
          address: '123 Main St',
          city: 'City C',
          state: 'ST',
          zipCode: '12345',
        ),
      );
      expect(assignerProfile.getHomeTeamName(), null);
    });

    test('OfficialProfile mapping works correctly', () {
      final officialProfile = OfficialProfile(
        address: '123 Referee St',
        city: 'Ref City',
        state: 'RS',
        experienceYears: 10,
        certificationLevel: 'Senior',
        availabilityStatus: 'busy',
        followThroughRate: 98.5,
        totalAcceptedGames: 150,
        totalBackedOutGames: 2,
        bio: 'Senior referee with extensive experience',
        sportsData: {
          'basketball': {
            'experience': 'expert',
            'certification': 'Level 3',
            'competitionLevels': ['Varsity', 'JV'],
          }
        },
        ratePerGame: 100.0,
        maxTravelDistance: 75,
        schedulerEndorsements: 12,
        officialEndorsements: 25,
        showCareerStats: false,
      );

      final map = officialProfile.toMap();
      final profileFromMap = OfficialProfile.fromMap(map);

      // Verify all fields are preserved
      expect(profileFromMap.address, officialProfile.address);
      expect(profileFromMap.city, officialProfile.city);
      expect(profileFromMap.state, officialProfile.state);
      expect(profileFromMap.experienceYears, officialProfile.experienceYears);
      expect(profileFromMap.certificationLevel,
          officialProfile.certificationLevel);
      expect(profileFromMap.availabilityStatus,
          officialProfile.availabilityStatus);
      expect(
          profileFromMap.followThroughRate, officialProfile.followThroughRate);
      expect(profileFromMap.totalAcceptedGames,
          officialProfile.totalAcceptedGames);
      expect(profileFromMap.totalBackedOutGames,
          officialProfile.totalBackedOutGames);
      expect(profileFromMap.bio, officialProfile.bio);
      expect(profileFromMap.sportsData, officialProfile.sportsData);
      expect(profileFromMap.ratePerGame, officialProfile.ratePerGame);
      expect(
          profileFromMap.maxTravelDistance, officialProfile.maxTravelDistance);
      expect(profileFromMap.schedulerEndorsements,
          officialProfile.schedulerEndorsements);
      expect(profileFromMap.officialEndorsements,
          officialProfile.officialEndorsements);
      expect(profileFromMap.showCareerStats, officialProfile.showCareerStats);
    });

    test('AddressData mapping works correctly', () {
      final address = AddressData(
        address: '123 Test St',
        city: 'Test City',
        state: 'TC',
        zipCode: '12345',
      );

      final map = address.toMap();
      final addressFromMap = AddressData.fromMap(map);

      expect(addressFromMap.address, address.address);
      expect(addressFromMap.city, address.city);
      expect(addressFromMap.state, address.state);
      expect(addressFromMap.zipCode, address.zipCode);
    });

    test('UserModel handles Timestamps correctly', () {
      final now = DateTime.now();

      final user = UserModel.scheduler(
        id: 'test-id',
        email: 'test@test.com',
        profile: ProfileData(
          firstName: 'Test',
          lastName: 'User',
          phone: '5555555555',
        ),
        schedulerProfile: SchedulerProfile.athleticDirector(
          schoolName: 'Test School',
          teamName: 'Test Team',
          schoolAddress: AddressData(
            address: 'Test Address',
            city: 'Test City',
            state: 'TS',
            zipCode: '12345',
          ),
        ),
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();

      // Verify timestamps are stored as Firestore Timestamps
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());

      // Verify they convert back correctly
      final userFromMap = UserModel.fromMap(map);
      expect(userFromMap.createdAt, now);
      expect(userFromMap.updatedAt, now);
    });
  });

  group('Firebase Constants Tests', () {
    test('FirebaseCollections contains expected collections', () {
      expect(FirebaseCollections.users, 'users');
      expect(FirebaseCollections.games, 'games');
      expect(FirebaseCollections.locations, 'locations');
      expect(FirebaseCollections.officialLists, 'official_lists');
      expect(FirebaseCollections.schedules, 'schedules');
      expect(FirebaseCollections.gameTemplates, 'game_templates');
      expect(FirebaseCollections.notifications, 'notifications');
    });

    test('FirebaseFields contains expected user fields', () {
      expect(FirebaseFields.userId, 'id');
      expect(FirebaseFields.email, 'email');
      expect(FirebaseFields.role, 'role');
      expect(FirebaseFields.profile, 'profile');
      expect(FirebaseFields.schedulerProfile, 'schedulerProfile');
      expect(FirebaseFields.officialProfile, 'officialProfile');
    });

    test('FirebaseFields contains expected game fields', () {
      expect(FirebaseFields.gameId, 'id');
      expect(FirebaseFields.scheduleId, 'scheduleId');
      expect(FirebaseFields.sport, 'sport');
      expect(FirebaseFields.date, 'date');
      expect(FirebaseFields.time, 'time');
      expect(FirebaseFields.location, 'location');
      expect(FirebaseFields.opponent, 'opponent');
      expect(FirebaseFields.officialsRequired, 'officialsRequired');
      expect(FirebaseFields.gameFee, 'gameFee');
      expect(FirebaseFields.status, 'status');
      expect(FirebaseFields.homeTeam, 'homeTeam');
      expect(FirebaseFields.awayTeam, 'awayTeam');
    });

    test('FirebaseValues contains expected role values', () {
      expect(FirebaseValues.roleScheduler, 'scheduler');
      expect(FirebaseValues.roleOfficial, 'official');
      expect(FirebaseValues.schedulerTypeAthleticDirector, 'Athletic Director');
      expect(FirebaseValues.schedulerTypeCoach, 'Coach');
      expect(FirebaseValues.schedulerTypeAssigner, 'Assigner');
    });

    test('FirebaseValues contains expected status values', () {
      expect(FirebaseValues.statusPublished, 'Published');
      expect(FirebaseValues.statusUnpublished, 'Unpublished');
    });
  });
}
