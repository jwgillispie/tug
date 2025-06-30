// lib/services/activity_service.dart
import 'package:logger/logger.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/models/social_models.dart';
import 'package:tug/services/cache_service.dart';
import 'package:tug/services/service_locator.dart';
import 'package:tug/services/social_service.dart';
import 'package:tug/utils/cache_utils.dart';
import 'package:tug/utils/streak_utils.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _apiService;
  final CacheService _cacheService;
  final SocialService _socialService;
  final Logger _logger = Logger();

  ActivityService({
    ApiService? apiService,
    CacheService? cacheService,
    SocialService? socialService,
  }) : 
    _apiService = apiService ?? ServiceLocator.apiService,
    _cacheService = cacheService ?? ServiceLocator.cacheService,
    _socialService = socialService ?? SocialService();


  // Fetch activities with optional filtering
  Future<List<ActivityModel>> getActivities({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = CacheUtils.activitiesKey(
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
          memoryCacheDuration: CacheUtils.getCacheDuration(CacheDataType.standardData),
          diskCacheDuration: CacheUtils.getDiskCacheDuration(CacheDataType.standardData),
        );

        return response.map((json) => ActivityModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Create a new activity
  Future<ActivityModel> createActivity(
    ActivityModel activity, {
    bool shareToSocial = true,
    ValueModel? valueModel,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/v1/activities',
        data: activity.toJson(),
      );

      final createdActivity = ActivityModel.fromJson(response);

      // Invalidate relevant caches
      await _invalidateActivityCaches();

      // Auto-create social post if sharing is enabled
      if (shareToSocial) {
        try {
          await _createActivitySocialPost(createdActivity, valueModel);
        } catch (e) {
          // Don't fail the activity creation if social posting fails
          _logger.e('Failed to create social post for activity: $e');
          _logger.i('Activity completed successfully, but social post creation failed');
        }
      }

      return createdActivity;
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
    final cacheKey = CacheUtils.statisticsKey(
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
        memoryCacheDuration: CacheUtils.getCacheDuration(CacheDataType.standardData),
        diskCacheDuration: CacheUtils.getDiskCacheDuration(CacheDataType.standardData),
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
    final cacheKey = CacheUtils.summaryKey(
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
        memoryCacheDuration: CacheUtils.getCacheDuration(CacheDataType.standardData),
        diskCacheDuration: CacheUtils.getDiskCacheDuration(CacheDataType.standardData),
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
    final cacheKey = CacheUtils.progressKey(
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
        memoryCacheDuration: CacheUtils.getCacheDuration(CacheDataType.standardData),
        diskCacheDuration: CacheUtils.getDiskCacheDuration(CacheDataType.standardData),
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
    final insightCacheKey = CacheUtils.insightKey(
      startDate: startDate,
      endDate: endDate,
    );

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
    await _cacheService.clearByPrefix('activities');
    await _cacheService.clearByPrefix('statistics');
    await _cacheService.clearByPrefix('summary');
    await _cacheService.clearByPrefix('progress');
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

  /// Calculate streak data for a specific value based on calendar days
  Future<StreakData> calculateValueStreak(String valueId) async {
    try {
      final activities = await getActivities();
      return StreakUtils.calculateValueStreak(valueId, activities);
    } catch (e) {
      return const StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
        streakDates: [],
      );
    }
  }

  /// Update a value with recalculated streak data based on calendar days
  Future<ValueModel> updateValueWithStreak(ValueModel value) async {
    try {
      final activities = await getActivities();
      return StreakUtils.updateValueWithStreak(value, activities);
    } catch (e) {
      return value;
    }
  }

  /// Update multiple values with recalculated streak data based on calendar days
  Future<List<ValueModel>> updateValuesWithStreaks(List<ValueModel> values) async {
    try {
      final activities = await getActivities();
      return StreakUtils.updateValuesWithStreaks(values, activities);
    } catch (e) {
      return values;
    }
  }

  /// Create a social post for a completed activity
  Future<void> _createActivitySocialPost(ActivityModel activity, ValueModel? valueModel) async {
    if (activity.id == null) return;

    // Generate engaging content for the activity post
    final content = _generateActivityPostContent(activity, valueModel);
    
    final socialPostRequest = CreatePostRequest(
      content: content,
      postType: PostType.activityUpdate,
      activityId: activity.id,
      isPublic: false, // Only friends can see activity posts
    );

    await _socialService.createPost(socialPostRequest);
  }

  /// Generate engaging content for activity social posts
  String _generateActivityPostContent(ActivityModel activity, ValueModel? valueModel) {
    final valueName = valueModel?.name ?? 'personal growth';
    final durationText = _formatDuration(activity.duration);
    
    // Generate different post styles based on activity characteristics
    final postTemplates = [
      '🎯 Just completed $durationText of ${activity.name} for my $valueName journey!',
      '✨ Invested $durationText in ${activity.name} today - building my $valueName habits!',
      '💪 Another $durationText focused on ${activity.name} - staying consistent with $valueName!',
      '🚀 Dedicated $durationText to ${activity.name} - progress on my $valueName goals!',
      '⭐ Spent $durationText on ${activity.name} - nurturing my $valueName practice!',
    ];

    // Add milestone celebrations for longer activities
    if (activity.duration >= 120) { // 2+ hours
      return '🔥 Epic $durationText session of ${activity.name}! Absolutely crushing my $valueName goals today! 💯';
    } else if (activity.duration >= 60) { // 1+ hour  
      return '🎉 Solid $durationText of ${activity.name} completed! Really investing in my $valueName journey! 💪';
    }
    
    // Add notes if they exist
    String baseContent = postTemplates[DateTime.now().millisecond % postTemplates.length];
    
    if (activity.notes != null && activity.notes!.trim().isNotEmpty) {
      baseContent += '\n\n💭 "${activity.notes!.trim()}"';
    }
    
    return baseContent;
  }

  /// Format duration in a human-friendly way
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes < 120) {
      final remainingMins = minutes % 60;
      return remainingMins == 0 ? '1 hour' : '1 hour $remainingMins minutes';
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      return remainingMins == 0 ? '$hours hours' : '$hours hours $remainingMins minutes';
    }
  }
}