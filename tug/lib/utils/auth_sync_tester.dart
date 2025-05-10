// lib/utils/auth_sync_tester.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class AuthSyncTester {
  final ApiService _apiService;
  final FirebaseAuth _auth;

  AuthSyncTester({
    ApiService? apiService,
    FirebaseAuth? firebaseAuth,
  })  : _apiService = apiService ?? ApiService(),
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  Future<Map<String, dynamic>> testSync() async {
    final result = <String, dynamic>{
      'success': false,
      'firebase_auth': false,
      'mongodb_sync': false,
      'token_valid': false,
      'errors': <String>[],
    };

    try {
      // Check Firebase Auth
      final user = _auth.currentUser;
      if (user == null) {
        result['errors'].add('No user signed in to Firebase');
        return result;
      }

      result['firebase_auth'] = true;
      result['firebase_user'] = {
        'uid': user.uid,
        'email': user.email,
        'display_name': user.displayName,
      };

      // Test token generation
      try {
        final token = await user.getIdToken(true);
        result['token_valid'] = token?.isNotEmpty;
      } catch (e) {
        result['errors'].add('Failed to get Firebase token: $e');
        return result;
      }

      // Test MongoDB sync
      try {
        final syncResult = await _apiService.syncUserWithMongoDB();
        result['mongodb_sync'] = syncResult;
        
        if (!syncResult) {
          result['errors'].add('MongoDB sync failed');
        }
      } catch (e) {
        result['errors'].add('Error during MongoDB sync: $e');
        return result;
      }

      // Test fetching user profile from backend
      try {
        final userProfile = await _apiService.get('/api/v1/users/me');
        result['backend_profile'] = userProfile;
        result['success'] = true;
      } catch (e) {
        result['errors'].add('Failed to fetch user profile: $e');
      }

      return result;
    } catch (e) {
      result['errors'].add('Unexpected error: $e');
      return result;
    }
  }
}