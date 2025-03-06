// lib/config/env_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static bool _isInitialized = false;

  static String get mongoDbUrl {
    _checkInitialized();
    return dotenv.env['MONGODB_URL'] ?? 'http://localhost:8000';
  }
  
  static String get apiUrl {
    _checkInitialized();
    // Use a more reliable default in case .env isn't loaded
    final url = dotenv.env['API_URL'];
    if (url != null && url.isNotEmpty) {
      debugPrint('Using configured API URL: $url');
      return url;
    }
    
    // Default value for development
    const defaultUrl = 'http://10.0.2.2:8000'; // Android emulator default
    debugPrint('No API_URL found in .env, using default: $defaultUrl');
    return defaultUrl;
  }
  
  static Future<void> load() async {
    try {
      await dotenv.load();
      _isInitialized = true;
      
      // Print loaded environment variables for debugging
      debugPrint('Environment variables loaded:');
      debugPrint('API_URL: ${dotenv.env['API_URL']}');
      debugPrint('MONGODB_URL: ${dotenv.env['MONGODB_URL']}');
    } catch (e) {
      debugPrint('Warning: .env file not found. Using default values. Error: $e');
      _isInitialized = true; // Still mark as initialized to prevent crashes
    }
  }

  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('EnvConfig has not been initialized. Call EnvConfig.load() first.');
    }
  }
}