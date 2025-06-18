import '../models/value_model.dart';
import '../utils/cache_utils.dart';
import '../utils/streak_utils.dart';
import '../services/activity_service.dart';
import 'base_repository.dart';

abstract class IValuesRepository {
  Future<List<ValueModel>> getValues({bool forceRefresh = false});
  Future<ValueModel> addValue(ValueModel value);
  Future<ValueModel> updateValue(ValueModel value);
  Future<void> deleteValue(String id);
  Future<Map<String, dynamic>> getStreakStats({String? valueId, bool forceRefresh = false});
}

class ValuesRepository extends BaseRepository<ValueModel> implements IValuesRepository {
  // Cache keys
  static const String _valuesCacheKey = 'values_list';
  
  late final ActivityService _activityService;

  ValuesRepository({
    super.apiService,
    super.cacheService,
    ActivityService? activityService,
  }) {
    _activityService = activityService ?? ActivityService();
  }

  @override
  ValueModel fromJson(Map<String, dynamic> json) => ValueModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(ValueModel value) => value.toJson();

  @override
  String get cacheKey => _valuesCacheKey;


  @override
  Future<List<ValueModel>> getValues({bool forceRefresh = false}) async {
    // If force refresh is requested, don't use cache
    if (!forceRefresh) {
      final cachedValues = await getFromCacheService(_valuesCacheKey);
      if (cachedValues != null) {
        // Still need to recalculate streaks with current activity data
        return await _updateValuesWithCalculatedStreaks(cachedValues);
      }
    }

    try {
      // Fetch from API if cache didn't work or force refresh was requested
      final response = await apiService.get('/api/v1/values');

      if (response != null) {
        final List<dynamic> valuesData = response;
        final values = valuesData
            .map((valueData) => ValueModel.fromJson(valueData))
            .toList();

        // Cache the values (without streak data, as that will be calculated fresh)
        await setInCacheService(_valuesCacheKey, valuesData);

        // Calculate streaks based on calendar days using current activities
        return await _updateValuesWithCalculatedStreaks(values);
      }
    } catch (e) {
      // Silently handle API errors
    }

    // If API call fails or no data, return empty list (CacheService already handles persistent storage)
    return [];
  }

  @override
  Future<ValueModel> addValue(ValueModel value) async {
    try {
      final response = await apiService.post(
        '/api/v1/values',
        data: value.toJson(),
      );

      if (response != null) {
        final newValue = ValueModel.fromJson(response);

        // Invalidate cache
        await invalidateCache();

        // Calculate streak data for the new value
        final activities = await _activityService.getActivities();
        final valueWithStreak = StreakUtils.updateValueWithStreak(newValue, activities);

        return valueWithStreak;
      }
    } catch (e) {
      // Store locally if offline
      if (value.id == null) {
        // For offline support, we'd need to implement a proper offline storage strategy
        // For now, just return the original value with a temp ID
        return value.copyWith(id: generateTempId());
      }
    }

    // Return original value if all else fails
    return value;
  }

  @override
  Future<ValueModel> updateValue(ValueModel value) async {
    try {
      if (value.id == null) {
        throw Exception('Cannot update value without ID');
      }

      final response = await apiService.patch(
        '/api/v1/values/${value.id}',
        data: value.toJson(),
      );

      if (response != null) {
        final updatedValue = ValueModel.fromJson(response);

        // Invalidate cache
        await invalidateCache();

        // Calculate streak data for the updated value
        final activities = await _activityService.getActivities();
        final valueWithStreak = StreakUtils.updateValueWithStreak(updatedValue, activities);

        return valueWithStreak;
      }
    } catch (e) {
      // For offline support, we'd implement proper conflict resolution
      // For now, just return the original value
    }

    // Return original value if all else fails
    return value;
  }

  @override
  Future<void> deleteValue(String id) async {
    try {
      await apiService.delete('/api/v1/values/$id');

      // Invalidate cache
      await invalidateCache();
    } catch (e) {
      // For offline support, we'd implement proper deletion queue
      // For now, just silently handle the error
    }
  }
  
  @override
  Future<Map<String, dynamic>> getStreakStats({String? valueId, bool forceRefresh = false}) async {
    // Generate a cache key based on value ID
    final cacheKey = 'streak_stats_${valueId ?? "all"}';

    // Try to get from cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        final cachedStats = await cacheService.get<Map<String, dynamic>>(cacheKey);
        if (cachedStats != null) {
          return cachedStats;
        }
      } catch (e) {
        // Silently handle cache errors
      }
    }

    try {
      String url = '/api/v1/values/stats/streaks';

      if (valueId != null) {
        url = '$url?value_id=$valueId';
      }

      final response = await apiService.get(url);

      if (response != null) {
        final stats = Map<String, dynamic>.from(response);

        // Cache the streak stats
        await cacheService.set(
          cacheKey,
          stats,
          memoryCacheDuration: CacheUtils.getCacheDuration(CacheDataType.standardData),
          diskCacheDuration: CacheUtils.getDiskCacheDuration(CacheDataType.standardData),
        );

        return stats;
      }
    } catch (e) {
      // Silently handle API errors
    }

    // Return empty map if API fails and no cache is available
    return {};
  }
  
  /// Update values with calculated streaks based on calendar days
  Future<List<ValueModel>> _updateValuesWithCalculatedStreaks(List<ValueModel> values) async {
    try {
      // Fetch all activities to calculate streaks
      final activities = await _activityService.getActivities();
      
      // Use StreakUtils to calculate streaks based on calendar days
      return StreakUtils.updateValuesWithStreaks(values, activities);
    } catch (e) {
      // If we can't fetch activities, return values with their existing streak data
      return values;
    }
  }
}