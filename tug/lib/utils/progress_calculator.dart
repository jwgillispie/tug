// lib/utils/progress_calculator.dart
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';

/// Utility class for calculating progress screen data
class ProgressCalculator {
  /// Calculate progress data for all values given activities and timeframe
  static Map<String, Map<String, dynamic>> calculateProgressData({
    required List<ValueModel> values,
    required List<ActivityModel> activities,
    required String timeframe,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final Map<String, Map<String, dynamic>> result = {};

    // Pre-filter activities by date range once
    final filteredActivities = activities.where((activity) =>
      (activity.date.isAfter(startDate) || activity.date.isAtSameMomentAs(startDate)) &&
      (activity.date.isBefore(endDate) || activity.date.isAtSameMomentAs(endDate))
    ).toList();

    // Group activities by value ID for efficient lookup
    final Map<String, List<ActivityModel>> activitiesByValue = {};
    for (final activity in filteredActivities) {
      if (!activitiesByValue.containsKey(activity.valueId)) {
        activitiesByValue[activity.valueId] = [];
      }
      activitiesByValue[activity.valueId]!.add(activity);
    }

    // Process only active values
    final activeValues = values.where((v) => v.active).toList();
    
    for (final value in activeValues) {
      // Get pre-grouped activities for this value
      final valueActivities = activitiesByValue[value.id] ?? [];

      // Calculate total minutes
      final totalMinutes = valueActivities.fold<int>(
        0,
        (sum, activity) => sum + activity.duration,
      );

      // Calculate community average (cached per timeframe)
      final communityAvg = _calculateCommunityAverage(value.name, timeframe);

      result[value.name] = {
        'minutes': totalMinutes,
        'community_avg': communityAvg,
        'activities_count': valueActivities.length,
        'value_id': value.id,
      };
    }

    return result;
  }

  /// Calculate community average based on value type and timeframe
  static int _calculateCommunityAverage(String valueName, String timeframe) {
    int baseDailyAvg;
    
    final lowerName = valueName.toLowerCase();
    if (lowerName.contains('exercise') || lowerName.contains('fitness') || lowerName.contains('workout')) {
      baseDailyAvg = 45;
    } else if (lowerName.contains('read') || lowerName.contains('study') || lowerName.contains('learn')) {
      baseDailyAvg = 60;
    } else if (lowerName.contains('family') || lowerName.contains('social') || lowerName.contains('friend')) {
      baseDailyAvg = 90;
    } else if (lowerName.contains('work') || lowerName.contains('career') || lowerName.contains('professional')) {
      baseDailyAvg = 480;
    } else if (lowerName.contains('creative') || lowerName.contains('art') || lowerName.contains('music')) {
      baseDailyAvg = 60;
    } else if (lowerName.contains('meditation') || lowerName.contains('mindful') || lowerName.contains('spiritual')) {
      baseDailyAvg = 20;
    } else {
      baseDailyAvg = 60;
    }
    
    switch (timeframe) {
      case 'daily':
        return baseDailyAvg;
      case 'weekly':
        return baseDailyAvg * 7;
      case 'monthly':
        return baseDailyAvg * 30;
      default:
        return baseDailyAvg;
    }
  }

  /// Get start date for timeframe
  static DateTime getStartDate(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case 'daily':
        return DateTime(now.year, now.month, now.day); // Start of today
      case 'weekly':
        return now.subtract(const Duration(days: 7));
      case 'monthly':
        return now.subtract(const Duration(days: 30));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }
}