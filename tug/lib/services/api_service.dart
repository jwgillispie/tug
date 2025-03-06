// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:tug/config/env_confg.dart';

class ApiService {
  final Dio _dio;
  
  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: EnvConfig.apiUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              // Don't throw exceptions automatically for response status
              validateStatus: (status) => true, // Accept all status codes for logging
            ));

  // Get Firebase token and set auth header
  Future<void> _setAuthHeader() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get fresh token
        final token = await user.getIdToken(true);
        _dio.options.headers['Authorization'] = 'Bearer $token';
        debugPrint('Auth header set successfully with token');
      } else {
        debugPrint('Cannot set auth header: No current user');
      }
    } catch (e) {
      debugPrint('Error setting auth header: $e');
    }
  }

  Future<bool> syncUserWithMongoDB() async {
    try {
      await _setAuthHeader();
      
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Cannot sync user: No current user');
        return false;
      }
      
      // Debug the full API URL we're trying to reach
      final fullUrl = '${_dio.options.baseUrl}/api/v1/users/sync';
      debugPrint('Syncing user with MongoDB: ${user.uid}');
      debugPrint('Full API URL: $fullUrl');
      
      final userData = {
        'display_name': user.displayName ?? '',
        'email': user.email ?? '',
        'photo_url': user.photoURL,
        'phone_number': user.phoneNumber,
        'uid': user.uid,
      };
      
      debugPrint('Sending user data: $userData');
      
      final response = await _dio.post('/api/v1/users/sync', data: userData);
      
      debugPrint('User sync response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      
      // Check if the status code indicates an error
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Error syncing user with MongoDB: HTTP ${response.statusCode}');
        return false;
      }
      
      return true;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Error syncing user with MongoDB: $e');
        debugPrint('Request URL: ${e.requestOptions.uri}');
        debugPrint('Request headers: ${e.requestOptions.headers}');
        debugPrint('Request data: ${e.requestOptions.data}');
        if (e.response != null) {
          debugPrint('Response status: ${e.response?.statusCode}');
          debugPrint('Response data: ${e.response?.data}');
        }
      } else {
        debugPrint('Unexpected error syncing user: $e');
      }
      return false;
    }
  }

  // Generic GET request with proper error handling
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.get(path, queryParameters: queryParameters);
      
      // Check status code before returning data
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('GET request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during GET request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic POST request with proper error handling
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      await _setAuthHeader();
      final fullUrl = '${_dio.options.baseUrl}$path';
      debugPrint('POST request to: $fullUrl');
      
      final response = await _dio.post(path, data: data);
      
      // Log the response regardless of status
      debugPrint('POST response status: ${response.statusCode}');
      debugPrint('POST response data: ${response.data}');
      
      // Check status code before returning data
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('POST request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during POST request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic PUT request with proper error handling
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.put(path, data: data);
      
      // Check status code before returning data
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('PUT request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during PUT request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic PATCH request with proper error handling
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      await _setAuthHeader();
      final response = await _dio.patch(path, data: data);
      
      // Check status code before returning data
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('PATCH request error: $e');
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during PATCH request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic DELETE request with proper error handling
  Future<dynamic> delete(String path) async {
    try {
      await _setAuthHeader();
      final response = await _dio.delete(path);
      
      // Check status code before returning data
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
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
          throw Exception('Resource not found. URL: ${e.requestOptions.uri}');
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