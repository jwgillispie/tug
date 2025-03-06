// lib/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract class IAuthRepository {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String name, String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> reloadUser();
  Stream<User?> authStateChanges();
  User? getCurrentUser();
}

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;

  // Constructor with optional FirebaseAuth instance for testing
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      debugPrint('AuthRepo: Attempting login with email: ${email.trim()}');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Check if user is null before returning
      final user = userCredential.user;
      if (user != null) {
        debugPrint('AuthRepo: Login successful, user: ${user.uid}');

        // Force reload to get updated profile
        await user.reload();
        return _firebaseAuth.currentUser;
      } else {
        debugPrint('AuthRepo: Login succeeded but user is null');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepo: Login error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthRepo: Unexpected login error: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signUp(String name, String email, String password) async {
    try {
      debugPrint('AuthRepo: Attempting signup with email: ${email.trim()}');

      // Create user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update profile with name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name.trim());

        // Force reload to get updated profile
        await userCredential.user!.reload();
        final updatedUser = _firebaseAuth.currentUser;

        debugPrint('AuthRepo: Signup successful, user: ${updatedUser?.uid}');
        return updatedUser;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepo: Signup error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthRepo: Unexpected signup error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      debugPrint('AuthRepo: User signed out');
    } catch (e) {
      debugPrint('AuthRepo: Signout error: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      debugPrint('AuthRepo: Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthRepo: Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthRepo: Unexpected password reset error: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('AuthRepo: Email verification sent to ${user.email}');
      } else if (user == null) {
        throw Exception('User not authenticated');
      } else if (user.emailVerified) {
        debugPrint('AuthRepo: Email already verified');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'AuthRepo: Email verification error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthRepo: Unexpected email verification error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      // Force refresh to get the latest value
      await user.reload();
      return _firebaseAuth.currentUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint('AuthRepo: Error checking email verification: $e');
      return false;
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        debugPrint('AuthRepo: User reloaded: ${user.uid}');
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      debugPrint('AuthRepo: Error reloading user: $e');
      rethrow;
    }
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
