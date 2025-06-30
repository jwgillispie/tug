import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_model.dart';
import '../models/value_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/activity_service.dart';

abstract class IActivityRepository {
  Future<List<ActivityModel>> getActivities({String? valueId, DateTime? startDate, DateTime? endDate, bool forceRefresh = false});
  Future<ActivityModel> addActivity(ActivityModel activity, {bool shareToSocial = true, ValueModel? valueModel});
  Future<ActivityModel> updateActivity(ActivityModel activity);
  Future<void> deleteActivity(String id);
}

class ActivityRepository implements IActivityRepository {
  final ApiService _apiService;
  final CacheService _cacheService;
  final ActivityService _activityService;
  late final SharedPreferences _prefs;

  // Cache keys
  static const String _activitiesCacheKeyPrefix = 'activities';
  static const Duration _cacheValidity = Duration(minutes: 15);

  ActivityRepository({
    ApiService? apiService,
    CacheService? cacheService,
    ActivityService? activityService,
    SharedPreferences? prefs,
  }) : 
    _apiService = apiService ?? ApiService(),
    _cacheService = cacheService ?? CacheService(),
    _activityService = activityService ?? ActivityService() {
    // Initialize SharedPreferences
    _initializePrefs(prefs);
  }

  Future<void> _initializePrefs(SharedPreferences? prefs) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
  }

  // Generate a cache key based on filter parameters
  String _generateCacheKey({String? valueId, DateTime? startDate, DateTime? endDate}) {
    final parts = [_activitiesCacheKeyPrefix];
    
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

  @override
  Future<List<ActivityModel>> getActivities({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateCacheKey(
      valueId: valueId,
      startDate: startDate,
      endDate: endDate
    );
    
    // If not force refresh, try to get from cache
    if (!forceRefresh) {
      try {
        final cachedActivities = await _cacheService.get<List<dynamic>>(cacheKey);
        
        if (cachedActivities != null) {
          return cachedActivities
              .map((activityData) => ActivityModel.fromJson(Map<String, dynamic>.from(activityData)))
              .toList();
        }
      } catch (e) {
      }
    } else {
    }

    try {
      // Build query parameters
      final Map<String, dynamic> queryParams = {};
      
      if (valueId != null) {
        queryParams['value_id'] = valueId;
      }
      
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      // Try to get activities from API
      final response = await _apiService.get(
        '/api/v1/activities/',
        queryParameters: queryParams,
      );

      if (response != null) {
        final List<dynamic> activitiesData = response;
        final activities = activitiesData
            .map((activityData) => ActivityModel.fromJson(activityData))
            .toList();

        // Cache the activities
        await _cacheService.set(
          cacheKey, 
          activitiesData,
          memoryCacheDuration: _cacheValidity,
          diskCacheDuration: Duration(hours: 3),
        );

        return activities;
      }
    } catch (e) {
    }

    // If API call fails or no data, return cached activities from SharedPreferences
    return await _getCachedActivities(
      valueId: valueId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<ActivityModel> addActivity(
    ActivityModel activity, {
    bool shareToSocial = true,
    ValueModel? valueModel,
  }) async {
    try {
      // Use the enhanced activity service with social sharing
      final newActivity = await _activityService.createActivity(
        activity,
        shareToSocial: shareToSocial,
        valueModel: valueModel,
      );

      // Invalidate all activities caches
      await _cacheService.clearByPrefix(_activitiesCacheKeyPrefix);

      // Add to shared preferences cache as well
      final cachedActivities = await _getCachedActivities();
      cachedActivities.add(newActivity);
      await _cacheActivities(cachedActivities);

      return newActivity;
    } catch (e) {
      // Store locally if offline
      if (activity.id == null) {
        // Generate a temporary ID
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempActivity = activity.copyWith(
          id: tempId, 
          createdAt: DateTime.now(),
        );

        // Add to cache
        final cachedActivities = await _getCachedActivities();
        cachedActivities.add(tempActivity);
        await _cacheActivities(cachedActivities);

        return tempActivity;
      }
      
      throw Exception('Failed to add activity: $e');
    }
  }

  @override
  Future<ActivityModel> updateActivity(ActivityModel activity) async {
    try {
      if (activity.id == null) {
        throw Exception('Cannot update activity without ID');
      }

      final response = await _apiService.patch(
        '/api/v1/activities/${activity.id}',
        data: activity.toJson(),
      );

      if (response != null) {
        final updatedActivity = ActivityModel.fromJson(response);

        // Invalidate all activities caches
        await _cacheService.clearByPrefix(_activitiesCacheKeyPrefix);

        // Update shared preferences cache as well
        final cachedActivities = await _getCachedActivities();
        final index = cachedActivities.indexWhere((a) => a.id == activity.id);
        if (index != -1) {
          cachedActivities[index] = updatedActivity;
          await _cacheActivities(cachedActivities);
        }

        return updatedActivity;
      }
    } catch (e) {

      // Update locally if offline
      final cachedActivities = await _getCachedActivities();
      final index = cachedActivities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        cachedActivities[index] = activity;
        await _cacheActivities(cachedActivities);
      }
    }

    // Return original activity if all else fails
    return activity;
  }

  @override
  Future<void> deleteActivity(String id) async {
    try {
      await _apiService.delete('/api/v1/activities/$id');

      // Invalidate all activities caches
      await _cacheService.clearByPrefix(_activitiesCacheKeyPrefix);

      // Remove from shared preferences cache
      final cachedActivities = await _getCachedActivities();
      cachedActivities.removeWhere((activity) => activity.id == id);
      await _cacheActivities(cachedActivities);
    } catch (e) {

      // Just remove locally if offline (will need to handle sync conflicts later)
      final cachedActivities = await _getCachedActivities();
      cachedActivities.removeWhere((activity) => activity.id == id);
      await _cacheActivities(cachedActivities);
    }
  }

  // Helper methods for local caching using SharedPreferences
  Future<List<ActivityModel>> _getCachedActivities({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _ensurePrefsInitialized();
      final cachedData = _prefs.getString('activities');
      if (cachedData != null) {
        final List<dynamic> activitiesData = jsonDecode(cachedData);
        var activities = activitiesData
            .map((activityData) => ActivityModel.fromJson(activityData))
            .toList();

        // Apply filters if provided
        if (valueId != null) {
          activities = activities.where((a) => a.valueId == valueId).toList();
        }
        
        if (startDate != null) {
          activities = activities.where((a) => 
            a.date.isAfter(startDate) || a.date.isAtSameMomentAs(startDate)
          ).toList();
        }
        
        if (endDate != null) {
          activities = activities.where((a) => a.date.isBefore(endDate)).toList();
        }

        // Sort by date (newest first)
        activities.sort((a, b) => b.date.compareTo(a.date));
        
        return activities;
      }
    } catch (e) {
    }
    return [];
  }

  Future<void> _cacheActivities(List<ActivityModel> activities) async {
    try {
      await _ensurePrefsInitialized();
      final activitiesJson = activities.map((activity) => activity.toJson()).toList();
      await _prefs.setString('activities', jsonEncode(activitiesJson));
    } catch (e) {
    }
  }

  Future<void> _ensurePrefsInitialized() async {
    
  }
}