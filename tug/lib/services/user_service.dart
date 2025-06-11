// lib/services/user_service.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../utils/api_error.dart';

class UserService {
  final ApiService _apiService;

  UserService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Fetch current user profile from backend
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiService.get('/api/v1/users/me');
      
      // Check if the response has a values field to determine if user has values
      if (response is Map && !response.containsKey('has_values')) {
        // Determine has_values based on values count from API
        if (response.containsKey('values_count')) {
          response['has_values'] = (response['values_count'] ?? 0) > 0;
        } else {
          // Try to fetch values specifically to determine if user has any
          try {
            final valuesResponse = await _apiService.get('/api/v1/values');
            // Check if values exist
            response['has_values'] = valuesResponse is List && valuesResponse.isNotEmpty;
          } catch (e) {
            response['has_values'] = false;
          }
        }
      }
      
      return response;
    } catch (e) {
      // Default profile with has_values set to false
      return {'has_values': false};
    }
  }

  // Set user values completion status - call this after adding first value
  Future<bool> setHasValues() async {
    try {
      await _apiService.patch('/api/v1/users/me', data: {'has_values': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('/api/v1/users/me', data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sync profile picture URL with backend
  Future<bool> syncProfilePictureUrl(String profilePictureUrl) async {
    try {
      await _apiService.patch('/api/v1/users/me', 
          data: {'profile_picture_url': profilePictureUrl});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Complete onboarding process
  Future<bool> completeOnboarding() async {
    try {
      await _apiService
          .patch('/api/v1/users/me', data: {'onboarding_completed': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user exists in backend
  Future<bool> checkUserExists() async {
    try {
      final response = await _apiService.get('/api/v1/users/me');
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Delete user account with all associated data
  Future<bool> deleteAccount() async {
    try {
      
      // This will trigger cascading deletion on the server (values, activities, etc.)
      await _apiService.delete('/api/v1/users/me');
      
      return true;
    } on DioException catch (e) {
      final ApiError apiError = ApiError.fromException(e);
      
      // Log detailed error for debugging
      
      if (e.response?.statusCode == 401) {
        // Handle authentication error
        throw Exception('Authentication failed. Please sign in again before deleting your account.');
      } else if (e.response?.statusCode == 404) {
        // User not found - treat as success since we're trying to delete it anyway
        return true;
      } else if (e.type == DioExceptionType.connectionError) {
        // Network error
        throw Exception('Network error. Please check your internet connection and try again.');
      } else {
        // Rethrow with more descriptive message
        throw Exception('Error deleting account: ${apiError.message}');
      }
    } catch (e) {
      // Generic error handling
      throw Exception('An unexpected error occurred while deleting your account. Please try again.');
    }
  }
  
  // Helper method to check if connection to backend is available
  Future<bool> checkBackendConnection() async {
    try {
      await _apiService.get('/health');
      return true;
    } catch (e) {
      return false;
    }
  }
}