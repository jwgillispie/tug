// lib/services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService;

  UserService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Fetch current user profile from backend
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiService.get('/api/v1/users/me');
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/api/v1/users/me', data: data);
      return response;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Complete onboarding process
  Future<bool> completeOnboarding() async {
    try {
      await _apiService
          .patch('/api/v1/users/me', data: {'onboarding_completed': true});
      return true;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      return false;
    }
  }

  // Check if user exists in backend
  Future<bool> checkUserExists() async {
    try {
      final response = await _apiService.get('/api/v1/users/me');
      return response != null;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

// Add to lib/services/user_service.dart

// Delete user account
  Future<bool> deleteAccount() async {
    try {
      await _apiService.delete('/api/v1/users/me');
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw e;
    }
  }
}
