// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:tug/config/env_confg.dart';
import '../utils/api_error.dart';
import 'rate_limiter.dart';

class ApiService {
  final Dio _dio;
  final RateLimiter _rateLimiter;

  ApiService({Dio? dio, RateLimiter? rateLimiter})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: EnvConfig.apiUrl, // This will use your Render URL
              connectTimeout: const Duration(seconds: 8), // Reduced timeouts for better UX
              receiveTimeout: const Duration(seconds: 10),
              // Don't throw exceptions automatically for response status
              validateStatus: (status) => true,
              followRedirects: true,
            )),
        _rateLimiter = rateLimiter ?? RateLimiter();

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
    return await _executeRequest(
      path: path,
      method: 'GET',
      queryParameters: queryParameters,
    );
  }

  // Generic POST request with proper error handling
  Future<dynamic> post(String path, {dynamic data}) async {
    return await _executeRequest(
      path: path,
      method: 'POST',
      data: data,
    );
  }

  // Generic PUT request with proper error handling
  Future<dynamic> put(String path, {dynamic data}) async {
    return await _executeRequest(
      path: path,
      method: 'PUT',
      data: data,
    );
  }

  // Generic PATCH request with proper error handling
  Future<dynamic> patch(String path, {dynamic data}) async {
    return await _executeRequest(
      path: path,
      method: 'PATCH',
      data: data,
    );
  }

  // Generic DELETE request with proper error handling
  Future<dynamic> delete(String path) async {
    return await _executeRequest(
      path: path,
      method: 'DELETE',
    );
  }

  // Shared method to execute HTTP requests with common error handling
  Future<dynamic> _executeRequest({
    required String path,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    // Normalize path
    path = _normalizeUrl(path);

    return await _rateLimiter.throttle(path, () async {
      try {
        await _setAuthHeader();
        
        // Process data for date handling if needed
        if (data != null) {
          data = _processDateData(path, data);
        }

        Response response;
        
        switch (method.toLowerCase()) {
          case 'get':
            // For GET requests, always include trailing slash to avoid redirects
            response = await _dio.get('$path/', queryParameters: queryParameters);
            break;
          case 'post':
            // Don't add trailing slash for specific endpoints to avoid redirects
            final postUrl = path.contains('profile-picture') ? path : '$path/';
            response = await _dio.post(postUrl, data: data);
            break;
          case 'put':
            response = await _dio.put('$path/', data: data);
            break;
          case 'patch':
            response = await _dio.patch(path, data: data);
            break;
          case 'delete':
            // Remove trailing slash for DELETE
            if (path.endsWith('/')) {
              path = path.substring(0, path.length - 1);
            }
            response = await _dio.delete(path);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

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
    });
  }

  // Helper method to process date data for activities
  dynamic _processDateData(String path, dynamic data) {
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
      
      return processedData;
    }
    return data;
  }

  void _handleDioError(DioException e) {
    final apiError = ApiError.fromException(e);
    throw apiError;
  }

  Map<String, dynamic> getRateLimiterStats() {
    return _rateLimiter.getStats();
  }

  void resetRateLimiter() {
    _rateLimiter.reset();
  }
}