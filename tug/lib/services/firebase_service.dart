// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  // Singleton instance
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Initialize Firebase
  Future<void> initialize() async {
    try {
      debugPrint('Initializing Firebase...');
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      
      // If Firebase initialization fails with a specific error, try to recover
      if (e is FirebaseException) {
        if (e.code == 'duplicate-app') {
          debugPrint('Firebase app already exists, continuing...');
          return;
        }
      }
      
      // Re-throw the error for the caller to handle
      rethrow;
    }
  }
}