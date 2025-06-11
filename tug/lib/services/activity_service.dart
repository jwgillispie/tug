// lib/services/activity_service.dart
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/services/cache_service.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _apiService;
  final CacheService _cacheService;

  // Cache keys and durations
  static const String _activitiesCachePrefix = 'api_activities';
  static const String _statisticsCachePrefix = 'api_statistics';
  static const String _summaryCachePrefix = 'api_summary';
  static const String _progressCachePrefix = 'api_progress_combined';
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

        return response.map((json) => ActivityModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
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

      return result;
    } catch (e) {
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

      return result;
    } catch (e) {
      // Return a default summary with date info
      return {
        "values": [],
        "start_date": startDate?.toIso8601String(),
        "end_date": endDate?.toIso8601String(),
      };
    }
  }

  // Combined method to fetch both statistics and summary efficiently
  Future<Map<String, dynamic>> getProgressData({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${_progressCachePrefix}_${startDate?.toIso8601String().split('T')[0] ?? 'all'}_${endDate?.toIso8601String().split('T')[0] ?? 'all'}';

    // Try to get from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    try {
      // Fetch both statistics and summary in parallel
      final results = await Future.wait([
        getActivityStatistics(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: forceRefresh,
        ),
        getActivitySummary(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: forceRefresh,
        ),
      ]);

      final combinedData = {
        'statistics': results[0],
        'summary': results[1],
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Cache the combined results
      await _cacheService.set(
        cacheKey,
        combinedData,
        memoryCacheDuration: _cacheValidity,
        diskCacheDuration: Duration(hours: 2),
      );

      return combinedData;
    } catch (e) {
      // Return default data structure
      return {
        'statistics': {
          "total_activities": 0,
          "total_duration_minutes": 0,
          "total_duration_hours": 0.0,
          "average_duration_minutes": 0.0,
        },
        'summary': {"values": []},
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Get enhanced data for AI insights including individual activities
  Future<Map<String, dynamic>> getInsightData({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final insightCacheKey = '${_progressCachePrefix}_insights_${startDate?.toIso8601String().split('T')[0] ?? 'all'}_${endDate?.toIso8601String().split('T')[0] ?? 'all'}';

    // Try to get from cache if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(insightCacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    try {
      // Fetch progress data and individual activities in parallel
      final results = await Future.wait([
        getProgressData(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: forceRefresh,
        ),
        getActivities(
          startDate: startDate,
          endDate: endDate,
          forceRefresh: forceRefresh,
        ),
      ]);

      final progressData = results[0] as Map<String, dynamic>;
      final activities = results[1] as List<ActivityModel>;

      // Group activities by value for easier analysis
      final Map<String, List<Map<String, dynamic>>> activitiesByValue = {};
      for (final activity in activities) {
        final key = activity.valueId;
        if (!activitiesByValue.containsKey(key)) {
          activitiesByValue[key] = [];
        }
        activitiesByValue[key]!.add({
          'name': activity.name,
          'duration': activity.duration,
          'date': activity.date.toIso8601String(),
          'notes': activity.notes,
        });
      }

      final combinedData = {
        'statistics': progressData['statistics'],
        'summary': progressData['summary'],
        'individual_activities': activities.map((a) => {
          'name': a.name,
          'value_id': a.valueId,
          'duration': a.duration,
          'date': a.date.toIso8601String(),
          'notes': a.notes,
        }).toList(),
        'activities_by_value': activitiesByValue,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Cache the results for shorter duration since this is more detailed data
      await _cacheService.set(
        insightCacheKey,
        combinedData,
        memoryCacheDuration: Duration(minutes: 10),
        diskCacheDuration: Duration(hours: 1),
      );

      return combinedData;
    } catch (e) {
      // Fallback to basic progress data if enhanced data fails
      final progressData = await getProgressData(
        startDate: startDate,
        endDate: endDate,
        forceRefresh: forceRefresh,
      );
      
      return {
        'statistics': progressData['statistics'],
        'summary': progressData['summary'],
        'individual_activities': [],
        'activities_by_value': {},
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Helper method to invalidate all activity-related caches
  Future<void> _invalidateActivityCaches() async {
    await _cacheService.clearByPrefix(_activitiesCachePrefix);
    await _cacheService.clearByPrefix(_statisticsCachePrefix);
    await _cacheService.clearByPrefix(_summaryCachePrefix);
    await _cacheService.clearByPrefix(_progressCachePrefix);
  }

  // Helper method to format dates consistently for API
  String _formatDateForApi(DateTime date) {
    // Format the date as YYYY-MM-DD to avoid timezone issues
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // Get values associated with activities
  Future<List<ValueModel>> getValuesByActivities(List<ActivityModel> activities) async {
    try {
      // Extract unique value IDs from activities
      final valueIds = activities
          .map((activity) => activity.valueId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (valueIds.isEmpty) {
        return [];
      }

      // Fetch values by IDs (you'd normally do a single API call, but here we're mocking it)
      final List<ValueModel> values = [];

      for (final valueId in valueIds) {
        try {
          final response = await _apiService.get('/api/v1/values/$valueId');
          if (response != null) {
            values.add(ValueModel.fromJson(response));
          }
        } catch (e) {
        }
      }

      return values;
    } catch (e) {
      return [];
    }
  }
}