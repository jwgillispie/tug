// lib/services/error_service.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

enum ErrorType {
  network,
  authentication,
  validation,
  business,
  unknown,
  crash,
  api,
  database,
  permission,
}

class AppError {
  final String message;
  final String userMessage;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? code;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final String? correlationId;

  AppError({
    required this.message,
    required this.userMessage,
    required this.type,
    required this.severity,
    this.code,
    this.stackTrace,
    this.context,
    DateTime? timestamp,
    this.correlationId,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppError.network({
    String? message,
    String? userMessage,
    String? code,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      message: message ?? 'Network error occurred',
      userMessage: userMessage ?? 'Please check your internet connection and try again.',
      type: ErrorType.network,
      severity: ErrorSeverity.medium,
      code: code,
      stackTrace: stackTrace,
      context: context,
    );
  }

  factory AppError.authentication({
    String? message,
    String? userMessage,
    String? code,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      message: message ?? 'Authentication error',
      userMessage: userMessage ?? 'Please log in again to continue.',
      type: ErrorType.authentication,
      severity: ErrorSeverity.high,
      code: code,
      stackTrace: stackTrace,
      context: context,
    );
  }

  factory AppError.validation({
    String? message,
    String? userMessage,
    String? code,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      message: message ?? 'Validation error',
      userMessage: userMessage ?? 'Please check your input and try again.',
      type: ErrorType.validation,
      severity: ErrorSeverity.low,
      code: code,
      stackTrace: stackTrace,
      context: context,
    );
  }

  factory AppError.business({
    String? message,
    String? userMessage,
    String? code,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      message: message ?? 'Business rule violation',
      userMessage: userMessage ?? 'This action cannot be completed.',
      type: ErrorType.business,
      severity: ErrorSeverity.medium,
      code: code,
      stackTrace: stackTrace,
      context: context,
    );
  }

  factory AppError.crash({
    String? message,
    String? userMessage,
    String? code,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      message: message ?? 'Unexpected error occurred',
      userMessage: userMessage ?? 'Something went wrong. Please restart the app.',
      type: ErrorType.crash,
      severity: ErrorSeverity.critical,
      code: code,
      stackTrace: stackTrace,
      context: context,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'userMessage': userMessage,
      'type': type.name,
      'severity': severity.name,
      'code': code,
      'timestamp': timestamp.toIso8601String(),
      'correlationId': correlationId,
      'context': context,
      'stackTrace': stackTrace?.toString(),
    };
  }

  @override
  String toString() {
    return 'AppError(type: $type, severity: $severity, message: $message)';
  }
}

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();
  final List<AppError> _errorHistory = [];
  final int _maxHistorySize = 100;

  Stream<AppError> get errorStream => _errorController.stream;
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  // Error reporting callbacks
  final List<Function(AppError)> _errorReporters = [];

  void addErrorReporter(Function(AppError) reporter) {
    _errorReporters.add(reporter);
  }

  void removeErrorReporter(Function(AppError) reporter) {
    _errorReporters.remove(reporter);
  }

  /// Report an error with automatic context detection
  void reportError(
    dynamic error, {
    StackTrace? stackTrace,
    String? userMessage,
    ErrorType? type,
    ErrorSeverity? severity,
    Map<String, dynamic>? context,
    String? correlationId,
  }) {
    final appError = _convertToAppError(
      error,
      stackTrace: stackTrace,
      userMessage: userMessage,
      type: type,
      severity: severity,
      context: context,
      correlationId: correlationId,
    );

    _addToHistory(appError);
    _logError(appError);
    _notifyReporters(appError);
    _errorController.add(appError);
  }

  /// Handle errors with automatic recovery
  Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    T? fallback,
    String? userMessage,
    ErrorType? errorType,
    bool retryOnFailure = false,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;
        
        final shouldRetry = retryOnFailure && 
                          attempts <= maxRetries && 
                          _isRetryableError(error);
        
        if (!shouldRetry) {
          reportError(
            error,
            stackTrace: stackTrace,
            userMessage: userMessage,
            type: errorType,
          );
          return fallback;
        }
        
        if (attempts <= maxRetries) {
          await Future.delayed(retryDelay * attempts);
        }
      }
    }
    
    return fallback;
  }

  /// Handle sync operations with error handling
  T? handleSync<T>(
    T Function() operation, {
    T? fallback,
    String? userMessage,
    ErrorType? errorType,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      reportError(
        error,
        stackTrace: stackTrace,
        userMessage: userMessage,
        type: errorType,
      );
      return fallback;
    }
  }

  /// Check if device is online (simplified version)
  Future<bool> isOnline() async {
    try {
      // TODO: Implement connectivity check or use connectivity_plus package
      // For now, assume online connectivity
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear error history
  void clearHistory() {
    _errorHistory.clear();
  }

  /// Get errors by type
  List<AppError> getErrorsByType(ErrorType type) {
    return _errorHistory.where((error) => error.type == type).toList();
  }

  /// Get errors by severity
  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorHistory.where((error) => error.severity == severity).toList();
  }

  AppError _convertToAppError(
    dynamic error, {
    StackTrace? stackTrace,
    String? userMessage,
    ErrorType? type,
    ErrorSeverity? severity,
    Map<String, dynamic>? context,
    String? correlationId,
  }) {
    if (error is AppError) {
      return error;
    }

    String message = error.toString();
    ErrorType errorType = type ?? _determineErrorType(error);
    ErrorSeverity errorSeverity = severity ?? _determineErrorSeverity(error);
    String defaultUserMessage = _getDefaultUserMessage(errorType);

    return AppError(
      message: message,
      userMessage: userMessage ?? defaultUserMessage,
      type: errorType,
      severity: errorSeverity,
      stackTrace: stackTrace,
      context: context,
      correlationId: correlationId,
    );
  }

  ErrorType _determineErrorType(dynamic error) {
    if (error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('connection') ||
        error.toString().toLowerCase().contains('socket')) {
      return ErrorType.network;
    }
    
    if (error.toString().toLowerCase().contains('auth') ||
        error.toString().toLowerCase().contains('unauthorized') ||
        error.toString().toLowerCase().contains('forbidden')) {
      return ErrorType.authentication;
    }
    
    if (error.toString().toLowerCase().contains('validation') ||
        error.toString().toLowerCase().contains('invalid')) {
      return ErrorType.validation;
    }
    
    return ErrorType.unknown;
  }

  ErrorSeverity _determineErrorSeverity(dynamic error) {
    if (error is Error || error.toString().toLowerCase().contains('fatal')) {
      return ErrorSeverity.critical;
    }
    
    if (error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('auth')) {
      return ErrorSeverity.high;
    }
    
    if (error.toString().toLowerCase().contains('validation')) {
      return ErrorSeverity.low;
    }
    
    return ErrorSeverity.medium;
  }

  String _getDefaultUserMessage(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'Please log in again to continue.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.business:
        return 'This action cannot be completed at this time.';
      case ErrorType.api:
        return 'Service is temporarily unavailable. Please try again later.';
      case ErrorType.database:
        return 'Data synchronization failed. Please try again.';
      case ErrorType.permission:
        return 'You don\'t have permission to perform this action.';
      case ErrorType.crash:
        return 'Something went wrong. Please restart the app.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  bool _isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket');
  }

  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    if (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  void _logError(AppError error) {
    if (kDebugMode) {
      developer.log(
        'AppError: ${error.message}',
        name: 'ErrorService',
        error: error.message,
        stackTrace: error.stackTrace,
      );
    }
  }

  void _notifyReporters(AppError error) {
    for (final reporter in _errorReporters) {
      try {
        reporter(error);
      } catch (e) {
        if (kDebugMode) {
          developer.log('Error reporter failed: $e', name: 'ErrorService');
        }
      }
    }
  }

  void dispose() {
    _errorController.close();
  }
}

/// Global error handling zone
class ErrorZone {
  static void runGuarded(Function() body) {
    runZonedGuarded(() {
      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        ErrorService().reportError(
          details.exception,
          stackTrace: details.stack,
          type: ErrorType.crash,
          severity: ErrorSeverity.critical,
          context: {
            'library': details.library,
            'context': details.context?.toString(),
          },
        );
      };
      
      body();
    }, (error, stackTrace) {
      // Handle uncaught async errors
      ErrorService().reportError(
        error,
        stackTrace: stackTrace,
        type: ErrorType.crash,
        severity: ErrorSeverity.critical,
      );
    });
  }
}

/// Extension for easy error handling
extension ErrorHandling on Future {
  Future<T?> handleError<T>({
    T? fallback,
    String? userMessage,
    ErrorType? errorType,
  }) {
    return ErrorService().handleAsync<T>(
      () => this as Future<T>,
      fallback: fallback,
      userMessage: userMessage,
      errorType: errorType,
    );
  }
}