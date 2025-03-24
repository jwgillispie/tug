// lib/repositories/activity_repository.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity_model.dart';
import '../services/api_service.dart';

abstract class IActivityRepository {
  Future<List<ActivityModel>> getActivities({String? valueId, DateTime? startDate, DateTime? endDate});
  Future<ActivityModel> addActivity(ActivityModel activity);
  Future<ActivityModel> updateActivity(ActivityModel activity);
  Future<void> deleteActivity(String id);
}

class ActivityRepository implements IActivityRepository {
  final ApiService _apiService;
  final Box<String> _localActivitiesBox;

  ActivityRepository({
    ApiService? apiService,
    Box<String>? localActivitiesBox,
  })  : _apiService = apiService ?? ApiService(),
        _localActivitiesBox = localActivitiesBox ?? Hive.box<String>('activities');

  @override
  Future<List<ActivityModel>> getActivities({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

        // Cache the activities locally
        _cacheActivities(activities);

        return activities;
      }
    } catch (e) {
      debugPrint('Error fetching activities from API: $e');
    }

    // If API call fails or no data, return cached activities
    return _getCachedActivities(valueId: valueId, startDate: startDate, endDate: endDate);
  }

  @override
  Future<ActivityModel> addActivity(ActivityModel activity) async {
    try {
      final response = await _apiService.post(
        '/api/v1/activities/',
        data: activity.toJson(),
      );

      if (response != null) {
        final newActivity = ActivityModel.fromJson(response);

        // Update cache
        final cachedActivities = _getCachedActivities();
        cachedActivities.add(newActivity);
        _cacheActivities(cachedActivities);

        return newActivity;
      }
    } catch (e) {
      debugPrint('Error adding activity to API: $e');

      // Store locally if offline
      if (activity.id == null) {
        // Generate a temporary ID
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempActivity = activity.copyWith(
          id: tempId, 
          createdAt: DateTime.now(),
        );

        // Add to cache
        final cachedActivities = _getCachedActivities();
        cachedActivities.add(tempActivity);
        _cacheActivities(cachedActivities);

        return tempActivity;
      }
    }

    // Return original activity if all else fails
    return activity;
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

        // Update cache
        final cachedActivities = _getCachedActivities();
        final index = cachedActivities.indexWhere((a) => a.id == activity.id);
        if (index != -1) {
          cachedActivities[index] = updatedActivity;
          _cacheActivities(cachedActivities);
        }

        return updatedActivity;
      }
    } catch (e) {
      debugPrint('Error updating activity on API: $e');

      // Update locally if offline
      final cachedActivities = _getCachedActivities();
      final index = cachedActivities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        cachedActivities[index] = activity;
        _cacheActivities(cachedActivities);
      }
    }

    // Return original activity if all else fails
    return activity;
  }

  @override
  Future<void> deleteActivity(String id) async {
    try {
      await _apiService.delete('/api/v1/activities/$id');

      // Remove from cache
      final cachedActivities = _getCachedActivities();
      cachedActivities.removeWhere((activity) => activity.id == id);
      _cacheActivities(cachedActivities);
    } catch (e) {
      debugPrint('Error deleting activity from API: $e');

      // Just remove locally if offline (will need to handle sync conflicts later)
      final cachedActivities = _getCachedActivities();
      cachedActivities.removeWhere((activity) => activity.id == id);
      _cacheActivities(cachedActivities);
    }
  }

  // Helper methods for local caching
  List<ActivityModel> _getCachedActivities({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      final cachedData = _localActivitiesBox.get('activities');
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
          activities = activities.where((a) => a.date.isAfter(startDate) || a.date.isAtSameMomentAs(startDate)).toList();
        }
        
        if (endDate != null) {
          activities = activities.where((a) => a.date.isBefore(endDate)).toList();
        }

        // Sort by date (newest first)
        activities.sort((a, b) => b.date.compareTo(a.date));
        
        return activities;
      }
    } catch (e) {
      debugPrint('Error getting cached activities: $e');
    }
    return [];
  }

  void _cacheActivities(List<ActivityModel> activities) {
    try {
      final activitiesJson = activities.map((activity) => activity.toJson()).toList();
      _localActivitiesBox.put('activities', jsonEncode(activitiesJson));
    } catch (e) {
      debugPrint('Error caching activities: $e');
    }
  }
}