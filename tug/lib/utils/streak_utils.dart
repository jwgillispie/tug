// lib/utils/streak_utils.dart
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';

/// Utility class for calculating streaks based on calendar days
/// instead of 24-hour periods
class StreakUtils {
  /// Calculate streak data for a specific value based on its activities
  /// Uses calendar days (until 11:59 PM) instead of 24-hour periods
  static StreakData calculateValueStreak(
    String valueId, 
    List<ActivityModel> activities
  ) {
    // Filter activities for this specific value
    final valueActivities = activities
        .where((activity) => activity.valueId == valueId)
        .toList();

    if (valueActivities.isEmpty) {
      return StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
        streakDates: [],
      );
    }

    // Get unique calendar days with activities (sorted)
    final activityDays = _getUniqueCalendarDays(valueActivities);
    
    if (activityDays.isEmpty) {
      return StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
        streakDates: [],
      );
    }

    // Calculate current streak (from most recent day backwards)
    final currentStreak = _calculateCurrentStreak(activityDays);
    
    // Calculate longest streak ever
    final longestStreak = _calculateLongestStreak(activityDays);
    
    // Get the dates that make up the current streak
    final streakDates = _getCurrentStreakDates(activityDays, currentStreak);

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActivityDate: activityDays.isNotEmpty ? activityDays.last : null,
      streakDates: streakDates,
    );
  }

  /// Calculate current streak from the most recent day backwards
  static int _calculateCurrentStreak(List<DateTime> activityDays) {
    if (activityDays.isEmpty) return 0;

    final today = _toCalendarDay(DateTime.now());
    final mostRecentActivityDay = activityDays.last;
    
    // If the most recent activity was not today or yesterday, streak is broken
    final daysSinceLastActivity = today.difference(mostRecentActivityDay).inDays;
    if (daysSinceLastActivity > 1) {
      return 0;
    }

    // Count consecutive days backwards from the most recent activity
    int streak = 0;
    DateTime expectedDay = mostRecentActivityDay;
    
    for (int i = activityDays.length - 1; i >= 0; i--) {
      final activityDay = activityDays[i];
      
      if (activityDay.isAtSameMomentAs(expectedDay)) {
        streak++;
        expectedDay = expectedDay.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate the longest streak in the entire history
  static int _calculateLongestStreak(List<DateTime> activityDays) {
    if (activityDays.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < activityDays.length; i++) {
      final previousDay = activityDays[i - 1];
      final currentDay = activityDays[i];
      
      // Check if current day is exactly one day after the previous day
      final dayDifference = currentDay.difference(previousDay).inDays;
      
      if (dayDifference == 1) {
        // Consecutive day - extend current streak
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        // Gap in streak - reset current streak
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  /// Get the dates that make up the current streak
  static List<DateTime> _getCurrentStreakDates(List<DateTime> activityDays, int currentStreak) {
    if (activityDays.isEmpty || currentStreak == 0) {
      return [];
    }

    // Return the last N days where N is the current streak length
    final startIndex = activityDays.length - currentStreak;
    return activityDays.sublist(startIndex);
  }

  /// Extract unique calendar days from activities and sort them
  static List<DateTime> _getUniqueCalendarDays(List<ActivityModel> activities) {
    final uniqueDays = <DateTime>{};
    
    for (final activity in activities) {
      uniqueDays.add(_toCalendarDay(activity.date));
    }
    
    final sortedDays = uniqueDays.toList()..sort();
    return sortedDays;
  }

  /// Convert a DateTime to a calendar day (midnight of that day)
  static DateTime _toCalendarDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Check if a streak is active (last activity was today or yesterday)
  static bool isStreakActive(DateTime? lastActivityDate) {
    if (lastActivityDate == null) return false;
    
    final today = _toCalendarDay(DateTime.now());
    final lastActivityDay = _toCalendarDay(lastActivityDate);
    final daysSinceLastActivity = today.difference(lastActivityDay).inDays;
    
    return daysSinceLastActivity <= 1;
  }

  /// Update a ValueModel with calculated streak data
  static ValueModel updateValueWithStreak(
    ValueModel value,
    List<ActivityModel> activities,
  ) {
    final streakData = calculateValueStreak(value.id!, activities);
    
    return value.copyWith(
      currentStreak: streakData.currentStreak,
      longestStreak: streakData.longestStreak,
      lastActivityDate: streakData.lastActivityDate,
      streakDates: streakData.streakDates,
    );
  }

  /// Calculate streak data for multiple values at once
  static List<ValueModel> updateValuesWithStreaks(
    List<ValueModel> values,
    List<ActivityModel> activities,
  ) {
    return values.map((value) {
      if (value.id != null) {
        return updateValueWithStreak(value, activities);
      }
      return value;
    }).toList();
  }

  /// Get streak overview statistics for all values
  static StreakOverview getStreakOverview(List<ValueModel> values) {
    final activeStreaks = values.where((v) => v.currentStreak > 0).toList();
    
    final totalActiveStreaks = activeStreaks.length;
    final totalStreakDays = activeStreaks.fold<int>(
      0, 
      (sum, value) => sum + value.currentStreak
    );
    
    final topStreak = activeStreaks.isNotEmpty 
        ? activeStreaks.reduce((a, b) => a.currentStreak > b.currentStreak ? a : b).currentStreak
        : 0;
    
    final longestEverStreak = values.isNotEmpty
        ? values.reduce((a, b) => a.longestStreak > b.longestStreak ? a : b).longestStreak
        : 0;

    return StreakOverview(
      totalActiveStreaks: totalActiveStreaks,
      totalStreakDays: totalStreakDays,
      topCurrentStreak: topStreak,
      longestEverStreak: longestEverStreak,
    );
  }
}

/// Data class to hold calculated streak information
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final List<DateTime> streakDates;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
    required this.streakDates,
  });
}

/// Data class to hold overview statistics for all streaks
class StreakOverview {
  final int totalActiveStreaks;
  final int totalStreakDays;
  final int topCurrentStreak;
  final int longestEverStreak;

  const StreakOverview({
    required this.totalActiveStreaks,
    required this.totalStreakDays,
    required this.topCurrentStreak,
    required this.longestEverStreak,
  });
}