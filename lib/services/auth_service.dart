import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  final UserModel? user;

  AuthResult._({
    required this.success,
    this.error,
    this.user,
  });

  factory AuthResult.success(UserModel user) => AuthResult._(
        success: true,
        user: user,
      );

  factory AuthResult.failure(String error) => AuthResult._(
        success: false,
        error: error,
      );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// Get current Firebase Auth user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up a new user with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required ProfileData profile,
    required String role,
    SchedulerProfile? schedulerProfile,
    OfficialProfile? officialProfile,
  }) async {
    try {
      // Validate inputs
      if (role == 'scheduler' && schedulerProfile == null) {
        return AuthResult.failure('Scheduler profile is required for scheduler role');
      }
      if (role == 'official' && officialProfile == null) {
        return AuthResult.failure('Official profile is required for official role');
      }

      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to create authentication account');
      }

      // Create user model
      final userModel = role == 'scheduler'
          ? UserModel.scheduler(
              id: credential.user!.uid,
              email: email.trim().toLowerCase(),
              profile: profile,
              schedulerProfile: schedulerProfile!,
            )
          : UserModel.official(
              id: credential.user!.uid,
              email: email.trim().toLowerCase(),
              profile: profile,
              officialProfile: officialProfile!,
            );

      // Create user document in Firestore
      try {
        await _userService.createUser(userModel);
        print('DEBUG: User created in Firestore successfully');
      } catch (e) {
        print('DEBUG: Firestore creation error: $e');
        // For now, continue even if Firestore fails to isolate the auth issue
      }

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String errorMessage = 'Sign up failed';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'email-already-in-use':
          errorMessage = 'Email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
      }
      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Sign in failed');
      }

      // Get user profile from Firestore
      final userModel = await _userService.getUserById(credential.user!.uid);
      if (userModel == null) {
        return AuthResult.failure('User profile not found');
      }

      return AuthResult.success(userModel);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign in failed';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later';
          break;
      }
      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure('Sign in failed: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    if (!isSignedIn) return null;
    return await _userService.getUserById(currentUser!.uid);
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user password
  Future<bool> updatePassword(String newPassword) async {
    try {
      if (!isSignedIn) return false;
      await currentUser!.updatePassword(newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user email
  Future<bool> updateEmail(String newEmail) async {
    try {
      if (!isSignedIn) return false;
      await currentUser!.updateEmail(newEmail.trim().toLowerCase());
      
      // Update email in Firestore as well
      final userModel = await getCurrentUserProfile();
      if (userModel != null) {
        await _userService.updateUser(
          userModel.copyWith(email: newEmail.trim().toLowerCase()),
        );
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete current user account
  Future<bool> deleteAccount() async {
    try {
      if (!isSignedIn) return false;
      
      final userId = currentUser!.uid;
      
      // Delete user document from Firestore
      await _userService.deleteUser(userId);
      
      // Delete Firebase Auth account
      await currentUser!.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reauthenticate user (required for sensitive operations)
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      if (!isSignedIn) return false;
      
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );
      
      await currentUser!.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if email is available for registration
  Future<bool> isEmailAvailable(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(
        email.trim().toLowerCase(),
      );
      return methods.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get user role without full profile (for routing)
  Future<String?> getUserRole() async {
    if (!isSignedIn) return null;
    
    final userModel = await getCurrentUserProfile();
    return userModel?.role;
  }

  /// Get scheduler type without full profile (for routing)
  Future<String?> getSchedulerType() async {
    if (!isSignedIn) return null;
    
    final userModel = await getCurrentUserProfile();
    return userModel?.schedulerType;
  }
}