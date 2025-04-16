// lib/services/email_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  final FirebaseFirestore _firestore;

  EmailService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save an email to Firestore
  Future<bool> saveEmail(String email) async {
    try {
      // Add validation here if needed
      if (email.isEmpty || !email.contains('@')) {
        return false;
      }

      // Save to Firestore
      await _firestore.collection('emails').add({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Email saved successfully: $email');
      return true;
    } catch (e) {
      debugPrint('Error saving email to Firestore: $e');
      return false;
    }
  }
}