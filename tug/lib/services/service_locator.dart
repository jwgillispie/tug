// lib/services/service_locator.dart
import 'api_service.dart';
import 'cache_service.dart';
import 'analytics_service.dart';

class ServiceLocator {
  static bool _isInitialized = false;
  static ApiService? _apiService;
  static CacheService? _cacheService;
  static AnalyticsService? _analyticsService;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize singleton services
    _apiService = ApiService();
    _cacheService = CacheService();
    _analyticsService = AnalyticsService();
    
    // Initialize cache service
    await _cacheService!.initialize();
    
    _isInitialized = true;
  }

  // Singleton getters
  static ApiService get apiService {
    if (_apiService == null) {
      throw StateError('ServiceLocator not initialized. Call ServiceLocator.initialize() first.');
    }
    return _apiService!;
  }

  static CacheService get cacheService {
    if (_cacheService == null) {
      throw StateError('ServiceLocator not initialized. Call ServiceLocator.initialize() first.');
    }
    return _cacheService!;
  }

  static AnalyticsService get analyticsService {
    if (_analyticsService == null) {
      throw StateError('ServiceLocator not initialized. Call ServiceLocator.initialize() first.');
    }
    return _analyticsService!;
  }

  // Reset for testing
  static void reset() {
    _isInitialized = false;
    _apiService = null;
    _cacheService = null;
    _analyticsService = null;
  }
}