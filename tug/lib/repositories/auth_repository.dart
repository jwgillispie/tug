// lib/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:tug/config/env_confg.dart';

// Abstract class for auth repository
abstract class IAuthRepository {
  Future<User?> signIn(String email, String password);
  Future<User?> signUp(String name, String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  User? getCurrentUser();
}

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;
  final Dio _dio;
  
  // Static getter for baseUrl
  static String get _baseUrl => EnvConfig.mongoDbUrl;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    Dio? dio,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // If successful, sync with MongoDB
      if (credential.user != null) {
        await _syncUserWithMongoDB(credential.user!);
      }
      
      return credential.user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User?> signUp(String name, String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);
        
        // Create user in MongoDB
        await _createUserInMongoDB(
          credential.user!.uid,
          name,
          email,
        );
      }
      
      return credential.user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Helper method to sync user with MongoDB
  Future<void> _syncUserWithMongoDB(User user) async {
    try {
      await _dio.post(
        '/users/sync',
        data: {
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName,
          'lastLogin': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error syncing user with MongoDB: $e');
      // We might not want to throw here as this is a background sync
    }
  }

  // Helper method to create user in MongoDB
  Future<void> _createUserInMongoDB(
    String uid,
    String name,
    String email,
  ) async {
    try {
      await _dio.post(
        '/users',
        data: {
          'uid': uid,
          'email': email,
          'name': name,
          'createdAt': DateTime.now().toIso8601String(),
          'lastLogin': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error creating user in MongoDB: $e');
      // Consider if you want to delete the Firebase user if MongoDB creation fails
      throw Exception('Failed to create user profile');
    }
  }

  // Helper method to handle Firebase Auth errors
  Exception _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email');
        case 'wrong-password':
          return Exception('Wrong password');
        case 'email-already-in-use':
          return Exception('Email is already registered');
        case 'weak-password':
          return Exception('Password is too weak');
        case 'invalid-email':
          return Exception('Invalid email address');
        default:
          return Exception(e.message ?? 'Authentication failed');
      }
    }
    return Exception('Something went wrong');
  }
}