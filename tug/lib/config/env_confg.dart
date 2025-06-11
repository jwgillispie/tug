// lib/config/env_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static bool _isInitialized = false;

  static String get mongoDbUrl {
    _checkInitialized();
    return dotenv.env['MONGODB_URL'] ?? 'mongodb://localhost:27017';
  }

  static String get apiUrl {
    _checkInitialized();
    // Use a more reliable default in case .env isn't loaded
    final url = dotenv.env['API_URL'];
    if (url != null && url.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('Using configured API URL');
      }
      return url;
    }

    // Default value for production
    const defaultUrl = 'https://tug-backend.onrender.com'; 
    if (kDebugMode) {
      debugPrint('Using default backend URL');
    }
    return defaultUrl;
  }
  
  static String get revenueCatApiKey {
    _checkInitialized();
    final apiKey = dotenv.env['REVENUECAT_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      return apiKey;
    }
    
    // This is a placeholder - you must provide a real key in .env
    // Return an empty string to prevent crashes, but purchases won't work
    debugPrint('Warning: Missing RevenueCat API key');
    return '';
  }
  
  static String get revenueCatOfferingId {
    _checkInitialized();
    return dotenv.env['REVENUECAT_OFFERING_ID'] ?? 'ofrngc4b82cdba4';
  }
  
  static String get revenueCatPremiumEntitlementId {
    _checkInitialized();
    return dotenv.env['REVENUECAT_PREMIUM_ENTITLEMENT_ID'] ?? 'tug_pro';
  }

  static Future<void> load() async {
    try {
      await dotenv.load();
      _isInitialized = true;

      // Only log environment status in debug mode, without exposing sensitive values
      if (kDebugMode) {
        debugPrint('Environment variables loaded:');
        debugPrint('API_URL: ${dotenv.env['API_URL'] != null ? '[CONFIGURED]' : '[NOT SET]'}');
        debugPrint('MONGODB_URL: ${dotenv.env['MONGODB_URL'] != null ? '[CONFIGURED]' : '[NOT SET]'}');
        debugPrint('REVENUECAT_API_KEY: ${dotenv.env['REVENUECAT_API_KEY'] != null ? '[CONFIGURED]' : '[NOT SET]'}');
        debugPrint('REVENUECAT_OFFERING_ID: ${dotenv.env['REVENUECAT_OFFERING_ID'] ?? 'ofrngc4b82cdba4 (default)'}');
        debugPrint('REVENUECAT_PREMIUM_ENTITLEMENT_ID: ${dotenv.env['REVENUECAT_PREMIUM_ENTITLEMENT_ID'] ?? 'tug_pro (default)'}');
      }
    } catch (e) {
      debugPrint(
          'Warning: .env file not found. Using default values. Error: $e');
      _isInitialized = true; // Still mark as initialized to prevent crashes
    }
  }

  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'EnvConfig has not been initialized. Call EnvConfig.load() first.');
    }
  }
}