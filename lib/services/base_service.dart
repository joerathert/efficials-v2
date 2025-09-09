import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Base service class providing common functionality for all services
abstract class BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Get FirebaseAuth instance
  FirebaseAuth get auth => _auth;

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user ID or throw exception if not authenticated
  String get requireUserId {
    final user = currentUser;
    if (user == null) {
      throw ServiceException('User must be authenticated');
    }
    return user.uid;
  }

  /// Execute a Firestore operation with error handling
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String operationName = 'operation',
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      throw ServiceException(
          'Firebase error during $operationName: ${e.message}');
    } on ServiceException {
      rethrow;
    } catch (e) {
      throw ServiceException('Unexpected error during $operationName: $e');
    }
  }

  /// Validate required authentication
  void validateAuthentication() {
    if (!isAuthenticated) {
      throw ServiceException('Authentication required');
    }
  }

  /// Validate that a string is not empty
  void validateNotEmpty(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ServiceException('$fieldName cannot be empty');
    }
  }

  /// Validate that a list is not empty
  void validateNotEmptyList(List list, String fieldName) {
    if (list.isEmpty) {
      throw ServiceException('$fieldName cannot be empty');
    }
  }

  /// Debug print helper (can be overridden by subclasses)
  void debugPrint(String message) {
    // Override in subclasses to enable/disable debug logging
    // print(message);
  }
}

/// Custom exception for service operations
class ServiceException implements Exception {
  final String message;

  ServiceException(this.message);

  @override
  String toString() => 'ServiceException: $message';
}

