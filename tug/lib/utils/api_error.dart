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
        return ApiError(
          message: response!.data['detail'],
          code: 'api_error',
          statusCode: statusCode,
        );
      }
      
      switch (exception.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiError(
            message: 'Connection timeout. Please check your internet connection.',
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
            message: 'No internet connection',
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