// lib/services/activity_service.dart
import 'package:flutter/foundation.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/services/cache_service.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _apiService;
  final CacheService _cacheService;

  // Cache keys and durations
  static const String _activitiesCachePrefix = 'api_activities';
  static const String _statisticsCachePrefix = 'api_statistics';
  static const String _summaryCachePrefix = 'api_summary';
  static const Duration _cacheValidity = Duration(minutes: 15);

  ActivityService({
    ApiService? apiService,
    CacheService? cacheService,
  }) : 
    _apiService = apiService ?? ApiService(),
    _cacheService = cacheService ?? CacheService();

  // Generate cache keys based on filter parameters
  String _generateActivitiesCacheKey({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final parts = [_activitiesCachePrefix];
    
    if (valueId != null) {
      parts.add('value_$valueId');
    }
    
    if (startDate != null) {
      parts.add('start_${startDate.toIso8601String().split('T')[0]}');
    }
    
    if (endDate != null) {
      parts.add('end_${endDate.toIso8601String().split('T')[0]}');
    }
    
    return parts.join('_');
  }

  String _generateStatisticsCacheKey({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final parts = [_statisticsCachePrefix];
    
    if (valueId != null) {
      parts.add('value_$valueId');
    }
    
    if (startDate != null) {
      parts.add('start_${startDate.toIso8601String().split('T')[0]}');
    }
    
    if (endDate != null) {
      parts.add('end_${endDate.toIso8601String().split('T')[0]}');
    }
    
    return parts.join('_');
  }

  String _generateSummaryCacheKey({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final parts = [_summaryCachePrefix];
    
    if (startDate != null) {
      parts.add('start_${startDate.toIso8601String().split('T')[0]}');
    }
    
    if (endDate != null) {
      parts.add('end_${endDate.toIso8601String().split('T')[0]}');
    }
    
    return parts.join('_');
  }

  // Fetch activities with optional filtering
  Future<List<ActivityModel>> getActivities({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateActivitiesCacheKey(
      valueId: valueId,
      startDate: startDate,
      endDate: endDate,
    );

    // Try to get from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        debugPrint('Activities retrieved from cache: $cacheKey');
        return cachedData
            .map((json) => ActivityModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    }

    try {
      final queryParams = <String, dynamic>{};

      if (valueId != null) {
        queryParams['value_id'] = valueId;
      }

      if (startDate != null) {
        queryParams['start_date'] = _formatDateForApi(startDate);
      }

      if (endDate != null) {
        queryParams['end_date'] = _formatDateForApi(endDate);
      }

      final response = await _apiService.get(
        '/api/v1/activities',
        queryParameters: queryParams,
      );

      if (response is List) {
        // Cache the results
        await _cacheService.set(
          cacheKey,
          response,
          memoryCacheDuration: _cacheValidity,
          diskCacheDuration: Duration(hours: 2),
        );
        debugPrint('Activities cached with key: $cacheKey');

        return response.map((json) => ActivityModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      rethrow;
    }
  }

  // Create a new activity
  Future<ActivityModel> createActivity(ActivityModel activity) async {
    try {
      final response = await _apiService.post(
        '/api/v1/activities',
        data: activity.toJson(),
      );

      // Invalidate relevant caches
      await _invalidateActivityCaches();

      return ActivityModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating activity: $e');
      rethrow;
    }
  }

  // Update an existing activity
  Future<ActivityModel> updateActivity(ActivityModel activity) async {
    try {
      if (activity.id == null) {
        throw Exception('Cannot update activity without ID');
      }

      final response = await _apiService.patch(
        '/api/v1/activities/${activity.id}',
        data: activity.toJson(),
      );

      // Invalidate relevant caches
      await _invalidateActivityCaches();

      return ActivityModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updating activity: $e');
      rethrow;
    }
  }

  // Delete an activity
  Future<bool> deleteActivity(String activityId) async {
    try {
      await _apiService.delete('/api/v1/activities/$activityId');

      // Invalidate relevant caches
      await _invalidateActivityCaches();

      return true;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      rethrow;
    }
  }

  // Get activity statistics with date range support
  Future<Map<String, dynamic>> getActivityStatistics({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateStatisticsCacheKey(
      valueId: valueId,
      startDate: startDate,
      endDate: endDate,
    );

    // Try to get from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        debugPrint('Activity statistics retrieved from cache: $cacheKey');
        return cachedData;
      }
    }

    try {
      final queryParams = <String, dynamic>{};

      if (valueId != null) {
        queryParams['value_id'] = valueId;
      }

      if (startDate != null) {
        queryParams['start_date'] = _formatDateForApi(startDate);
      }

      if (endDate != null) {
        queryParams['end_date'] = _formatDateForApi(endDate);
      }

      final response = await _apiService.get(
        '/api/v1/activities/statistics',
        queryParameters: queryParams,
      );

      // Prepare the result with all required fields
      final result = {
        'total_activities': response['total_activities'] ?? 0,
        'total_duration_minutes': response['total_duration_minutes'] ?? 0,
        'total_duration_hours': response['total_duration_hours'] ?? 0.0,
        'average_duration_minutes': response['average_duration_minutes'] ?? 0.0,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };

      // Cache the results
      await _cacheService.set(
        cacheKey,
        result,
        memoryCacheDuration: _cacheValidity,
        diskCacheDuration: Duration(hours: 2),
      );
      debugPrint('Activity statistics cached with key: $cacheKey');

      return result;
    } catch (e) {
      debugPrint('Error getting activity statistics: $e');
      // Return a default statistics object with date info
      return {
        "total_activities": 0,
        "total_duration_minutes": 0,
        "total_duration_hours": 0.0,
        "average_duration_minutes": 0.0,
        "start_date": startDate?.toIso8601String(),
        "end_date": endDate?.toIso8601String(),
      };
    }
  }

  // Get activity summary by value with date range support
  Future<Map<String, dynamic>> getActivitySummary({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateSummaryCacheKey(
      startDate: startDate,
      endDate: endDate,
    );

    // Try to get from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        debugPrint('Activity summary retrieved from cache: $cacheKey');
        return cachedData;
      }
    }

    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) {
        queryParams['start_date'] = _formatDateForApi(startDate);
      }

      if (endDate != null) {
        queryParams['end_date'] = _formatDateForApi(endDate);
      }

      final response = await _apiService.get(
        '/api/v1/activities/summary',
        queryParameters: queryParams,
      );

      // Prepare the result with all required fields
      final result = {
        'values': response['values'] ?? [],
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };

      // Cache the results
      await _cacheService.set(
        cacheKey,
        result,
        memoryCacheDuration: _cacheValidity,
        diskCacheDuration: Duration(hours: 2),
      );
      debugPrint('Activity summary cached with key: $cacheKey');

      return result;
    } catch (e) {
      debugPrint('Error getting activity summary: $e');
      // Return a default summary with date info
      return {
        "values": [],
        "start_date": startDate?.toIso8601String(),
        "end_date": endDate?.toIso8601String(),
      };
    }
  }

  // Helper method to invalidate all activity-related caches
  Future<void> _invalidateActivityCaches() async {
    await _cacheService.clearByPrefix(_activitiesCachePrefix);
    await _cacheService.clearByPrefix(_statisticsCachePrefix);
    await _cacheService.clearByPrefix(_summaryCachePrefix);
    debugPrint('All activity-related caches invalidated');
  }

  // Helper method to format dates consistently for API
  String _formatDateForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}