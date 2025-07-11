// lib/utils/api_error.dart
import 'package:dio/dio.dart';

class ApiError implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  ApiError({
    required this.message,
    this.code = 'unknown',
    this.statusCode,
  });

  factory ApiError.fromException(dynamic exception) {
    if (exception is DioException) {
      final response = exception.response;
      final statusCode = response?.statusCode;
      
      if (response?.data is Map && response?.data['detail'] != null) {
        // Safely handle the detail field
        final detail = response!.data['detail'];
        String message;
        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          // Extract the error messages from validation errors
          message = detail.map((error) {
            if (error is Map && error['msg'] != null) {
              return error['msg'].toString();
            }
            return error.toString();
          }).join(', ');
        } else {
          message = detail.toString();
        }
        
        return ApiError(
          message: message,
          code: 'api_error',
          statusCode: statusCode,
        );
      }
      
      // Handle Render-specific errors
      if (statusCode == 503) {
        return ApiError(
          message: 'Backend service temporarily unavailable. The server might be starting up if it was idle.',
          code: 'server_unavailable',
          statusCode: statusCode,
        );
      }
      
      switch (exception.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiError(
            message: 'Connection timeout. Please check your internet connection or try again later.',
            code: 'timeout',
          );
        case DioExceptionType.badResponse:
          return ApiError(
            message: 'Server error (${statusCode ?? "unknown"})',
            code: 'server_error',
            statusCode: statusCode,
          );
        case DioExceptionType.connectionError:
          return ApiError(
            message: 'No internet connection or server is unreachable',
            code: 'no_connection',
          );
        default:
          return ApiError(
            message: exception.message ?? 'An unexpected error occurred',
            code: 'dio_error',
          );
      }
    }
    
    return ApiError(
      message: exception.toString(),
      code: 'unknown',
    );
  }

  @override
  String toString() => 'ApiError: $message (code: $code, statusCode: $statusCode)';
}