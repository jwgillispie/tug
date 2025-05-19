// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:tug/config/env_confg.dart';
import '../utils/api_error.dart';

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: EnvConfig.apiUrl, // This will use your Render URL
              connectTimeout: const Duration(seconds: 15), // Increased timeouts for potential API latency
              receiveTimeout: const Duration(seconds: 15),
              // Don't throw exceptions automatically for response status
              validateStatus: (status) => true,
              followRedirects: true,
            ));

  // Helper method to ensure consistent URL format
  String _normalizeUrl(String path) {
    // Remove trailing slash if present
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    // Ensure leading slash
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    return path;
  }

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

      // Use the exact path without modifying it
      String path = '/api/v1/users/sync';

      // Debug the full API URL we're trying to reach
      final fullUrl = '${_dio.options.baseUrl}$path';
      debugPrint('Syncing user with MongoDB: ${user.uid}');
      debugPrint('Full API URL: $fullUrl');

      final userData = {
        'display_name': user.displayName ?? '',
        'email': user.email ?? '',
        'photo_url': user.photoURL,
        'phone_number': user.phoneNumber,
        'uid': user.uid,
      };

      final response = await _dio.post(path, data: userData);

      debugPrint('User sync response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      // Check if the status code indicates an error
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
            'Error syncing user with MongoDB: HTTP ${response.statusCode}');
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
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    // Normalize path
    path = _normalizeUrl(path);

    try {
      await _setAuthHeader();
      debugPrint('GET request to: ${_dio.options.baseUrl}$path');

      // For GET requests, always include trailing slash to avoid redirects
      final response =
          await _dio.get('$path/', queryParameters: queryParameters);

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
    // Normalize path
    path = _normalizeUrl(path);

    try {
      await _setAuthHeader();
      final fullUrl = '${_dio.options.baseUrl}$path/';
      debugPrint('POST request to: $fullUrl');
      
      // Log request data to debug datetime issues
      debugPrint('Request data before processing: $data');
      
      // Special handling for activity data to solve datetime issues
      // Convert ISO8601 timestamps with timezone to simple YYYY-MM-DD format
      if (path.contains('/activities') && data is Map) {
        Map<String, dynamic> processedData = Map<String, dynamic>.from(data);
        
        // Process date fields to strip timezone information
        if (processedData.containsKey('date')) {
          try {
            final dateStr = processedData['date'];
            if (dateStr is String && dateStr.contains('T')) {
              // Parse the ISO8601 string
              final parsedDate = DateTime.parse(dateStr);
              // Format as YYYY-MM-DD
              final dateOnly = "${parsedDate.year.toString().padLeft(4, '0')}-"
                  "${parsedDate.month.toString().padLeft(2, '0')}-"
                  "${parsedDate.day.toString().padLeft(2, '0')}";
              processedData['date'] = dateOnly;
              debugPrint('Converted date from $dateStr to $dateOnly');
            }
          } catch (e) {
            debugPrint('Error processing date field: $e');
          }
        }
        
        // Apply the processed data
        data = processedData;
        debugPrint('Request data after processing: $data');
      }

      final response = await _dio.post('$path/', data: data);

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
    // Normalize path
    path = _normalizeUrl(path);

    try {
      await _setAuthHeader();
      debugPrint('PUT request to: ${_dio.options.baseUrl}$path/');
      final response = await _dio.put('$path/', data: data);

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
    // Normalize path
    path = _normalizeUrl(path);

    try {
      await _setAuthHeader();
      // Log the exact URL and headers
      debugPrint('PATCH request to: ${_dio.options.baseUrl}$path');
      debugPrint('PATCH headers: ${_dio.options.headers}');
      debugPrint('PATCH data before processing: $data');

      // Special handling for activity data to solve datetime issues
      // Convert ISO8601 timestamps with timezone to simple YYYY-MM-DD format
      if (path.contains('/activities') && data is Map) {
        Map<String, dynamic> processedData = Map<String, dynamic>.from(data);
        
        // Process date fields to strip timezone information
        if (processedData.containsKey('date')) {
          try {
            final dateStr = processedData['date'];
            if (dateStr is String && dateStr.contains('T')) {
              // Parse the ISO8601 string
              final parsedDate = DateTime.parse(dateStr);
              // Format as YYYY-MM-DD
              final dateOnly = "${parsedDate.year.toString().padLeft(4, '0')}-"
                  "${parsedDate.month.toString().padLeft(2, '0')}-"
                  "${parsedDate.day.toString().padLeft(2, '0')}";
              processedData['date'] = dateOnly;
              debugPrint('Converted date from $dateStr to $dateOnly');
            }
          } catch (e) {
            debugPrint('Error processing date field: $e');
          }
        }
        
        // Apply the processed data
        data = processedData;
        debugPrint('PATCH data after processing: $data');
      }

      // Make the request
      final response = await _dio.patch(path, data: data);
      debugPrint('PATCH response status: ${response.statusCode}');
      debugPrint('PATCH response data: ${response.data}');

      // Check status code before returning data
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        debugPrint('PATCH Error: ${response.statusCode}');
        debugPrint('PATCH Response data: ${response.data}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      debugPrint('PATCH request error: $e');
      if (e.response != null) {
        debugPrint('Response status: ${e.response?.statusCode}');
        debugPrint('Response data: ${e.response?.data}');
      }
      _handleDioError(e);
    } catch (e) {
      debugPrint('Unexpected error during PATCH request: $e');
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic DELETE request with proper error handling
  Future<dynamic> delete(String path) async {
    // Normalize path
    path = _normalizeUrl(path);

    try {
      await _setAuthHeader();
      if (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }

      debugPrint('DELETE request to: ${_dio.options.baseUrl}$path');

      // For DELETE requests, always include trailing slash to avoid redirects
      var requestUrl = path;
      debugPrint('DELETE request to: ${_dio.options.baseUrl}$requestUrl');

      final response = await _dio.delete(requestUrl);

      // Check status code before returning data
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        debugPrint('DELETE Error: ${response.statusCode}');
        debugPrint('Response data: ${response.data}');
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

  void _handleDioError(DioException e) {
    final apiError = ApiError.fromException(e);
    throw apiError;
  }
}