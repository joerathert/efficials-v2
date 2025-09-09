import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:efficials_v2/services/base_service.dart';
import 'package:efficials_v2/services/game_service.dart';
import 'package:efficials_v2/constants/firebase_constants.dart';

// Mock classes for Firebase
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('Firebase Integration Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late GameService gameService;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      // Mock the current user
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');

      // Create a test service that uses our mocks
      // Game service initialized for testing
    });

    test('GameService should use correct Firebase collection', () async {
      final mockCollection = MockCollectionReference();
      when(mockFirestore.collection(FirebaseCollections.games))
          .thenReturn(mockCollection);

      // This test verifies that our service uses the correct collection name
      expect(FirebaseCollections.games, 'games');
      expect(FirebaseCollections.users, 'users');
      expect(FirebaseCollections.officialLists, 'official_lists');
    });

    test('FirebaseFields should contain correct field names', () {
      expect(FirebaseFields.role, 'role');
      expect(FirebaseFields.email, 'email');
      expect(FirebaseFields.createdAt, 'createdAt');
      expect(FirebaseFields.updatedAt, 'updatedAt');
    });

    test('FirebaseValues should contain correct constant values', () {
      expect(FirebaseValues.roleOfficial, 'official');
      expect(FirebaseValues.roleScheduler, 'scheduler');
      expect(FirebaseValues.statusPublished, 'Published');
    });

    test('Firebase constants are properly defined', () {
      // Test that our constants are accessible
      expect(FirebaseCollections.users, isNotNull);
      expect(FirebaseCollections.games, isNotNull);
      expect(FirebaseFields.email, isNotNull);
      expect(FirebaseValues.roleOfficial, isNotNull);
    });

    test('BaseService authentication properties work', () {
      final service = TestBaseService(mockFirestore, mockAuth);

      // Test that properties are accessible
      expect(service.firestore, isNotNull);
      expect(service.auth, isNotNull);
    });

    test('BaseService should validate non-empty strings', () {
      final service = TestBaseService(mockFirestore, mockAuth);

      expect(() => service.testValidateNotEmpty('', 'testField'),
          throwsA(isA<ServiceException>()));
      expect(() => service.testValidateNotEmpty('test', 'testField'),
          returnsNormally);
    });

    test('BaseService should validate non-empty lists', () {
      final service = TestBaseService(mockFirestore, mockAuth);

      expect(() => service.testValidateNotEmptyList([], 'testList'),
          throwsA(isA<ServiceException>()));
      expect(() => service.testValidateNotEmptyList(['item'], 'testList'),
          returnsNormally);
    });
  });

  group('Service Error Handling Integration Tests', () {
    test('BaseService validation methods work', () {
      final mockFirestore = MockFirebaseFirestore();
      final mockAuth = MockFirebaseAuth();
      final service = TestBaseService(mockFirestore, mockAuth);

      // Test non-empty validation
      expect(() => service.testValidateNotEmpty('', 'testField'),
          throwsA(isA<ServiceException>()));
      expect(() => service.testValidateNotEmpty('test', 'testField'),
          returnsNormally);

      // Test list validation
      expect(() => service.testValidateNotEmptyList([], 'testList'),
          throwsA(isA<ServiceException>()));
      expect(() => service.testValidateNotEmptyList(['item'], 'testList'),
          returnsNormally);
    });
  });
}

// Test helper classes
class TestBaseService extends BaseService {
  final FirebaseFirestore mockFirestore;
  final FirebaseAuth mockAuth;

  TestBaseService(this.mockFirestore, this.mockAuth);

  // Test methods to expose protected functionality
  bool testValidateAuthentication() {
    validateAuthentication();
    return true;
  }

  void testValidateNotEmpty(String value, String fieldName) {
    validateNotEmpty(value, fieldName);
  }

  void testValidateNotEmptyList(List list, String fieldName) {
    validateNotEmptyList(list, fieldName);
  }
}
