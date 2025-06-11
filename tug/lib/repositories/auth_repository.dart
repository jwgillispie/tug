// lib/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';

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
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Check if user is null before returning
      final user = userCredential.user;
      if (user != null) {
        // Force reload to get updated profile
        await user.reload();
        return _firebaseAuth.currentUser;
      } else {
        return null;
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<User?> signUp(String name, String email, String password) async {
    try {
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
        return updatedUser;
      }

      return null;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else if (user == null) {
        throw Exception('User not authenticated');
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
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
      return false;
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
      } else {
        throw Exception('User not authenticated');
      }
    } catch (_) {
      rethrow;
    }
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
