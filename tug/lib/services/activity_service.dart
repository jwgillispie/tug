// lib/services/activity_service.dart
import 'package:flutter/foundation.dart';
import 'package:tug/models/activity_model.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _apiService;

  ActivityService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Fetch activities with optional filtering
  Future<List<ActivityModel>> getActivities({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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
  }) async {
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

      // Ensure the response has all required fields
      return {
        'total_activities': response['total_activities'] ?? 0,
        'total_duration_minutes': response['total_duration_minutes'] ?? 0,
        'total_duration_hours': response['total_duration_hours'] ?? 0.0,
        'average_duration_minutes': response['average_duration_minutes'] ?? 0.0,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
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
  }) async {
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

      // Ensure the response has a values array
      return {
        'values': response['values'] ?? [],
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };
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

  // Helper method to format dates consistently for API
  String _formatDateForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}