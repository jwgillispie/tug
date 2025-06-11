// lib/services/firebase_service.dart
// Basic Firebase service without App Check

import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  // Singleton instance
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Initialize Firebase (basic initialization only)
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // If Firebase initialization fails with a specific error, try to recover
      if (e is FirebaseException) {
        if (e.code == 'duplicate-app') {
          return;
        }
      }
      
      // Re-throw the error for the caller to handle
      rethrow;
    }
  }
}