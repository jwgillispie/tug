// lib/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static bool _isInitialized = false;

  static String get mongoDbUrl {
    _checkInitialized();
    return dotenv.env['MONGODB_URL'] ?? 'http://localhost:8000';
  }
  
  static String get apiUrl {
    _checkInitialized();
    return dotenv.env['API_URL'] ?? 'http://localhost:8000';
  }
  
  static Future<void> load() async {
    try {
      await dotenv.load();
      _isInitialized = true;
    } catch (e) {
      print('Warning: .env file not found. Using default values.');
      _isInitialized = true; // Still mark as initialized to prevent crashes
    }
  }

  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('EnvConfig has not been initialized. Call EnvConfig.load() first.');
    }
  }
}