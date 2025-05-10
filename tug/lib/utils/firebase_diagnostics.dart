// lib/utils/firebase_diagnostics.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseDiagnostics {
  // Singleton pattern
  static final FirebaseDiagnostics _instance = FirebaseDiagnostics._internal();
  factory FirebaseDiagnostics() => _instance;
  FirebaseDiagnostics._internal();

  // Check Firebase initialization status
  Future<Map<String, dynamic>> checkFirebaseStatus() async {
    final status = <String, dynamic>{};
    
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        status['initialized'] = false;
        status['message'] = 'Firebase is not initialized';
        return status;
      }
      
      status['initialized'] = true;
      status['apps_count'] = Firebase.apps.length;
      
      // Get current app details
      final app = Firebase.app();
      status['app_name'] = app.name;
      status['options'] = {
        'apiKey': app.options.apiKey,
        'projectId': app.options.projectId,
        'messagingSenderId': app.options.messagingSenderId,
        'appId': app.options.appId,
      };
      
      // Check auth
      final auth = FirebaseAuth.instance;
      // ignore: unnecessary_null_comparison
      status['auth_initialized'] = auth != null;
      status['current_user'] = auth.currentUser?.uid;
      
      status['status'] = 'success';
    } catch (e) {
      status['status'] = 'error';
      status['error'] = e.toString();
    }
    
    return status;
  }

  // Test Firebase Auth
  Future<Map<String, dynamic>> testAuth(String email, String password) async {
    final result = <String, dynamic>{};
    
    try {
      // Test sign in
      final auth = FirebaseAuth.instance;
      
      // Try signing out first to ensure clean state
      try {
        await auth.signOut();
        result['signout_success'] = true;
      } catch (e) {
        result['signout_success'] = false;
        result['signout_error'] = e.toString();
      }
      
      // Now try signing in
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        
        result['signin_success'] = true;
        result['user'] = {
          'uid': credential.user?.uid,
          'email': credential.user?.email,
          'emailVerified': credential.user?.emailVerified,
          'displayName': credential.user?.displayName,
        };
      } on FirebaseAuthException catch (e) {
        result['signin_success'] = false;
        result['signin_error'] = '${e.code}: ${e.message}';
      } catch (e) {
        result['signin_success'] = false;
        result['signin_error'] = e.toString();
      }
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }
    
    return result;
  }

  // Print everything about the current user
  Future<Map<String, dynamic>> getCurrentUserDetails() async {
    final result = <String, dynamic>{};
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        result['signed_in'] = false;
        result['message'] = 'No user is currently signed in';
        return result;
      }
      
      result['signed_in'] = true;
      
      // Basic properties
      result['uid'] = user.uid;
      result['email'] = user.email;
      result['display_name'] = user.displayName;
      result['email_verified'] = user.emailVerified;
      result['phone_number'] = user.phoneNumber;
      result['photo_url'] = user.photoURL;
      result['tenant_id'] = user.tenantId;
      result['refresh_token'] = user.refreshToken;
      result['is_anonymous'] = user.isAnonymous;
      
      // Provider data
      result['provider_data'] = user.providerData.map((info) => {
        'provider_id': info.providerId,
        'uid': info.uid,
        'display_name': info.displayName,
        'email': info.email,
        'phone_number': info.phoneNumber,
        'photo_url': info.photoURL,
      }).toList();
      
      // Get ID token
      try {
        final idToken = await user.getIdToken();
        result['id_token_length'] = idToken?.length;
        result['id_token_preview'] = '${idToken?.substring(0, 10)}...';
      } catch (e) {
        result['id_token_error'] = e.toString();
      }
      
      // Get ID token result
      try {
        final idTokenResult = await user.getIdTokenResult();
        result['token_expiration'] = idTokenResult.expirationTime?.toIso8601String();
        result['token_issued_at'] = idTokenResult.issuedAtTime?.toIso8601String();
        result['token_auth_time'] = idTokenResult.authTime?.toIso8601String();
        result['token_sign_in_provider'] = idTokenResult.signInProvider;
      } catch (e) {
        result['token_result_error'] = e.toString();
      }
    } catch (e) {
      result['status'] = 'error';
      result['error'] = e.toString();
    }
    
    return result;
  }

  // Print all Firebase diagnostic info
  Future<void> printAllDiagnostics(String email, String password) async {
    try {
      debugPrint('\n---------- FIREBASE DIAGNOSTICS ----------');
      
      // Check Firebase status
      final status = await checkFirebaseStatus();
      debugPrint('Firebase Status:');
      status.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      
      // Test auth
      final authTest = await testAuth(email, password);
      debugPrint('\nAuth Test:');
      authTest.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      
      // Get current user details
      final userDetails = await getCurrentUserDetails();
      debugPrint('\nCurrent User Details:');
      userDetails.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      
      debugPrint('\n------ END FIREBASE DIAGNOSTICS ------\n');
    } catch (e) {
      debugPrint('Error running diagnostics: $e');
    }
  }
}