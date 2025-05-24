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
      debugPrint('Using configured API URL: $url');
      return url;
    }

    // Default value for production
    const defaultUrl = 'https://tug-backend.onrender.com'; 
    debugPrint('Using backend URL: $defaultUrl');
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

      // Print loaded environment variables for debugging
      debugPrint('Environment variables loaded:');
      debugPrint('API_URL: ${dotenv.env['API_URL']}');
      debugPrint('MONGODB_URL: ${dotenv.env['MONGODB_URL']}');
      // Don't print the full API key for security reasons
      final rcApiKey = dotenv.env['REVENUECAT_API_KEY'] ?? '';
      final maskedKey = rcApiKey.isNotEmpty ? '${rcApiKey.substring(0, 4)}...${rcApiKey.substring(rcApiKey.length - 4)}' : 'Not set';
      debugPrint('REVENUECAT_API_KEY: $maskedKey');
      debugPrint('REVENUECAT_OFFERING_ID: ${dotenv.env['REVENUECAT_OFFERING_ID'] ?? 'ofrngc4b82cdba4 (default)'}');
      debugPrint('REVENUECAT_PREMIUM_ENTITLEMENT_ID: ${dotenv.env['REVENUECAT_PREMIUM_ENTITLEMENT_ID'] ?? 'entl0a93ea6b23 (default)'}');
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