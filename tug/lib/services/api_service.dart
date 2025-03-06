// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:tug/config/env_confg.dart';
//config 


class ApiService {
  final Dio _dio;
  
  


  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: EnvConfig.apiUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  // Get Firebase token and set auth header
  Future<void> _setAuthHeader() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get fresh token
        final token = await user.getIdToken(true);
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('Error setting auth header: $e');
    }
  }

// In your ApiService class
Future<void> syncUserWithMongoDB() async {
  try {
    await _setAuthHeader();
    
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    debugPrint('Syncing user with MongoDB: ${user.uid}');
    debugPrint('API URL: ${_dio.options.baseUrl}');
    
    // Check your API URL and make sure it's correct
    // If your API uses a prefix, include it (e.g., /api/v1/users/sync)
    final response = await _dio.post('/api/v1/users/sync', data: {
      'display_name': user.displayName,
      'email': user.email,
      'photo_url': user.photoURL,
      'phone_number': user.phoneNumber,
      'uid': user.uid,
    });
    
    debugPrint('User sync response: ${response.statusCode}');
  } catch (e) {
    debugPrint('Error syncing user with MongoDB: $e');
  }
}

  // Generic GET request
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      debugPrint('GET request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during GET request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('POST request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during POST request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic PUT request
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('PUT request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during PUT request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic PATCH request
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      debugPrint('PATCH request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during PATCH request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String path) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      debugPrint('DELETE request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during DELETE request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Error handling for Dio errors
  void _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      // Handle specific status codes
      switch (statusCode) {
        case 401:
          throw Exception('Authentication required. Please log in again.');
        case 403:
          throw Exception('You do not have permission to perform this action.');
        case 404:
          throw Exception('Resource not found.');
        case 500:
          throw Exception('Server error. Please try again later.');
        default:
          if (data is Map && data.containsKey('detail')) {
            throw Exception(data['detail']);
          } else {
            throw Exception('Request failed with status: $statusCode');
          }
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception(
          'Connection timeout. Please check your internet connection.');
    } else {
      throw Exception('Network error: ${e.message}');
    }
  }
}
