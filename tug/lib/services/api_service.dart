// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:tug/config/env_confg.dart';
import '../utils/api_error.dart';

class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: EnvConfig.apiUrl, // This will use your Render URL
              connectTimeout: const Duration(seconds: 8), // Reduced timeouts for better UX
              receiveTimeout: const Duration(seconds: 10),
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
      } else {
      }
    } catch (e) {
    }
  }

  Future<bool> syncUserWithMongoDB() async {
    try {
      await _setAuthHeader();

      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Use the exact path without modifying it
      String path = '/api/v1/users/sync';

      // Debug the full API URL we're trying to reach
      final fullUrl = '${_dio.options.baseUrl}$path';

      final userData = {
        'display_name': user.displayName ?? '',
        'email': user.email ?? '',
        'photo_url': user.photoURL,
        'phone_number': user.phoneNumber,
        'uid': user.uid,
      };

      final response = await _dio.post(path, data: userData);


      // Check if the status code indicates an error
      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }

      return true;
    } catch (e) {
      if (e is DioException) {
      } else {
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

      // For GET requests, always include trailing slash to avoid redirects
      final response =
          await _dio.get('$path/', queryParameters: queryParameters);

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
      _handleDioError(e);
    } catch (e) {
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
      
      // Special handling for activity data to preserve user's intended date context
      if (path.contains('/activities') && data is Map) {
        Map<String, dynamic> processedData = Map<String, dynamic>.from(data);
        
        // For activity dates, send the local date in ISO format to preserve user intent
        if (processedData.containsKey('date')) {
          try {
            final dateStr = processedData['date'];
            if (dateStr is String && dateStr.contains('T')) {
              // Parse the ISO8601 string and preserve local time context
              final parsedDate = DateTime.parse(dateStr);
              // Send as local datetime to preserve user's intended time
              processedData['date'] = parsedDate.toLocal().toIso8601String();
            }
          } catch (e) {
            // If parsing fails, leave the date as-is
          }
        }
        
        // Apply the processed data
        data = processedData;
      }

      final response = await _dio.post('$path/', data: data);


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
      _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic PUT request with proper error handling
  Future<dynamic> put(String path, {dynamic data}) async {
    // Normalize path
    path = _normalizeUrl(path);

    try {
      await _setAuthHeader();
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
      _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to complete request: $e');
    }
  }

  // Generic PATCH request with proper error handling
  Future<dynamic> patch(String path, {dynamic data}) async {
    // Normalize path
    path = _normalizeUrl(path);

    try {
      await _setAuthHeader();

      // Special handling for activity data to preserve user's intended date context
      if (path.contains('/activities') && data is Map) {
        Map<String, dynamic> processedData = Map<String, dynamic>.from(data);
        
        // For activity dates, send the local date in ISO format to preserve user intent
        if (processedData.containsKey('date')) {
          try {
            final dateStr = processedData['date'];
            if (dateStr is String && dateStr.contains('T')) {
              // Parse the ISO8601 string and preserve local time context
              final parsedDate = DateTime.parse(dateStr);
              // Send as local datetime to preserve user's intended time
              processedData['date'] = parsedDate.toLocal().toIso8601String();
            }
          } catch (e) {
            // If parsing fails, leave the date as-is
          }
        }
        
        // Apply the processed data
        data = processedData;
      }

      // Make the request
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
      _handleDioError(e);
    } catch (e) {
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


      // For DELETE requests, always include trailing slash to avoid redirects
      var requestUrl = path;

      final response = await _dio.delete(requestUrl);

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
      _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to complete request: $e');
    }
  }

  void _handleDioError(DioException e) {
    final apiError = ApiError.fromException(e);
    throw apiError;
  }
}