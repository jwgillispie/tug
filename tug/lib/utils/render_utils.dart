// lib/utils/render_utils.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:math';

/// Utility functions for handling Render backend specifics
class RenderUtils {
  /// Handles potential cold starts for Render backends
  /// with exponential backoff retries
  static Future<bool> pingBackend(Dio dio, {int maxRetries = 3}) async {
    int retryCount = 0;
    bool success = false;
    
    while (retryCount < maxRetries && !success) {
      try {
        debugPrint('Attempting to ping backend (attempt ${retryCount + 1}/${maxRetries})');
        
        // Simple health check endpoint
        final response = await dio.get('/health');
        
        if (response.statusCode == 200) {
          debugPrint('Backend is ready!');
          success = true;
        } else {
          debugPrint('Backend returned status code: ${response.statusCode}');
          await _exponentialBackoff(retryCount);
          retryCount++;
        }
      } catch (e) {
        debugPrint('Error pinging backend: $e');
        
        // Check if it's a 503 error (common during Render cold starts)
        if (e is DioException && e.response?.statusCode == 503) {
          debugPrint('Backend is starting up (503 Service Unavailable)');
        }
        
        await _exponentialBackoff(retryCount);
        retryCount++;
      }
    }
    
    return success;
  }
  
  /// Implements exponential backoff with jitter
  static Future<void> _exponentialBackoff(int retryCount) async {
    // Base delay is 1 second, with exponential increase
    final baseDelay = 1000; // ms
    final maxDelay = 10000; // 10 seconds max
    
    // Calculate delay with exponential backoff
    int delay = min(baseDelay * pow(2, retryCount).toInt(), maxDelay);
    
    // Add jitter (±20% randomization)
    final jitter = (delay * 0.2 * (Random().nextDouble() * 2 - 1)).toInt();
    delay += jitter;
    
    debugPrint('Waiting ${delay}ms before retrying...');
    await Future.delayed(Duration(milliseconds: delay));
  }
}