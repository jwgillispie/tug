// lib/repositories/base_repository.dart
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/service_locator.dart';
import '../utils/cache_utils.dart';

abstract class BaseRepository<T> {
  final ApiService apiService;
  final CacheService cacheService;
  
  BaseRepository({
    ApiService? apiService,
    CacheService? cacheService,
  }) : 
    apiService = apiService ?? ServiceLocator.apiService,
    cacheService = cacheService ?? ServiceLocator.cacheService;

  // Abstract methods that must be implemented by subclasses
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);
  String get cacheKey;

  // Generic cache service methods using CacheUtils
  Future<List<T>?> getFromCacheService(String key) async {
    try {
      final cachedItems = await cacheService.get<List<dynamic>>(key);
      if (cachedItems != null) {
        return cachedItems
            .map((itemData) => fromJson(Map<String, dynamic>.from(itemData)))
            .toList();
      }
    } catch (e) {
      // Silently handle cache read errors
    }
    return null;
  }

  Future<void> setInCacheService(String key, List<dynamic> data, {
    CacheDataType dataType = CacheDataType.standardData,
  }) async {
    await cacheService.set(
      key, 
      data,
      memoryCacheDuration: CacheUtils.getCacheDuration(dataType),
      diskCacheDuration: CacheUtils.getDiskCacheDuration(dataType),
    );
  }

  // Generic cache invalidation
  Future<void> invalidateCache([String? specificKey]) async {
    if (specificKey != null) {
      await cacheService.remove(specificKey);
    } else {
      await cacheService.remove(cacheKey);
    }
  }

  Future<void> invalidateCacheByPrefix(String prefix) async {
    await cacheService.clearByPrefix(prefix);
  }

  // Helper for generating temporary IDs
  String generateTempId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}';
  }
}