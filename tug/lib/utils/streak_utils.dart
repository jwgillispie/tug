// lib/utils/streak_utils.dart
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/models/vice_model.dart';
import 'package:tug/models/indulgence_model.dart';

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

  /// Calculate clean streak data for a vice based on indulgence history
  /// Assumes clean days until an indulgence is recorded (inverted from values)
  static ViceStreakData calculateViceStreak(
    String viceId,
    List<IndulgenceModel> indulgences,
    DateTime? viceCreatedDate,
  ) {
    // Filter indulgences for this specific vice
    final viceIndulgences = indulgences
        .where((indulgence) => indulgence.viceId == viceId)
        .toList();

    // Sort indulgences by date
    viceIndulgences.sort((a, b) => a.date.compareTo(b.date));

    // Get unique calendar days with indulgences (sorted)
    final indulgenceDays = _getUniqueCalendarDaysFromIndulgences(viceIndulgences);
    
    // Use vice creation date as start date, or today if no creation date
    final startDate = viceCreatedDate ?? DateTime.now();
    final today = _toCalendarDay(DateTime.now());
    
    // Calculate current clean streak
    final currentStreak = _calculateCurrentCleanStreak(indulgenceDays, today, startDate);
    
    // Calculate longest clean streak ever
    final longestStreak = _calculateLongestCleanStreak(indulgenceDays, startDate);
    
    // Get last indulgence date
    final lastIndulgenceDate = indulgenceDays.isNotEmpty ? indulgenceDays.last : null;

    return ViceStreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastIndulgenceDate: lastIndulgenceDate,
      totalIndulgences: viceIndulgences.length,
      daysSinceLastIndulgence: lastIndulgenceDate != null 
          ? today.difference(lastIndulgenceDate).inDays 
          : (viceCreatedDate != null ? today.difference(_toCalendarDay(viceCreatedDate)).inDays : 0),
    );
  }

  /// Debug method to provide detailed streak calculation information (frontend)
  /// Useful for comparing frontend vs backend calculations
  static Map<String, dynamic> debugViceStreakCalculation(
    String viceId,
    String viceName,
    List<IndulgenceModel> indulgences,
    DateTime? viceCreatedDate,
  ) {
    final now = DateTime.now();
    final streakData = calculateViceStreak(viceId, indulgences, viceCreatedDate);
    
    return {
      'vice_id': viceId,
      'vice_name': viceName,
      'created_at': viceCreatedDate?.toIso8601String(),
      'last_indulgence_date': streakData.lastIndulgenceDate?.toIso8601String(),
      'current_streak_calculated': streakData.currentStreak,
      'longest_streak_calculated': streakData.longestStreak,
      'total_indulgences': streakData.totalIndulgences,
      'calculation_timestamp': now.toIso8601String(),
      'calculation_method': 'calendar_days_frontend',
      'timezone': now.timeZoneName,
      'days_since_last_indulgence': streakData.daysSinceLastIndulgence,
    };
  }

  /// Calculate current clean streak from today backwards until last indulgence
  /// Uses calendar days (midnight to midnight) for consistency with backend
  static int _calculateCurrentCleanStreak(List<DateTime> indulgenceDays, DateTime today, DateTime startDate) {
    if (indulgenceDays.isEmpty) {
      // No indulgences recorded - streak is calendar days from start date to now
      final startDay = _toCalendarDay(startDate);
      final todayCalendar = _toCalendarDay(today);
      return todayCalendar.difference(startDay).inDays;
    }

    final lastIndulgenceDay = indulgenceDays.last;
    final todayCalendar = _toCalendarDay(today);
    
    // Current streak is calendar days since last indulgence
    final daysSinceLastIndulgence = todayCalendar.difference(lastIndulgenceDay).inDays;
    
    // Return days since last indulgence (clean days), minimum 0
    return daysSinceLastIndulgence >= 0 ? daysSinceLastIndulgence : 0;
  }

  /// Calculate the longest clean streak in the entire history
  static int _calculateLongestCleanStreak(List<DateTime> indulgenceDays, DateTime startDate) {
    if (indulgenceDays.isEmpty) {
      // No indulgences ever - streak is from start date to now
      final today = _toCalendarDay(DateTime.now());
      final startDay = _toCalendarDay(startDate);
      return today.difference(startDay).inDays;
    }

    int longestStreak = 0;
    DateTime previousDate = _toCalendarDay(startDate);
    
    // Calculate streak from start to first indulgence
    if (indulgenceDays.isNotEmpty) {
      final firstIndulgenceDay = indulgenceDays.first;
      final initialStreak = firstIndulgenceDay.difference(previousDate).inDays;
      longestStreak = initialStreak > longestStreak ? initialStreak : longestStreak;
    }
    
    // Calculate streaks between indulgences
    for (int i = 0; i < indulgenceDays.length - 1; i++) {
      final currentIndulgenceDay = indulgenceDays[i];
      final nextIndulgenceDay = indulgenceDays[i + 1];
      
      // Clean days between indulgences (subtract 1 because we don't count indulgence days)
      final streakLength = nextIndulgenceDay.difference(currentIndulgenceDay).inDays - 1;
      longestStreak = streakLength > longestStreak ? streakLength : longestStreak;
    }
    
    // Calculate current streak from last indulgence to now
    if (indulgenceDays.isNotEmpty) {
      final lastIndulgenceDay = indulgenceDays.last;
      final today = _toCalendarDay(DateTime.now());
      final currentStreak = today.difference(lastIndulgenceDay).inDays;
      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
    }

    return longestStreak;
  }

  /// Extract unique calendar days from indulgences and sort them
  static List<DateTime> _getUniqueCalendarDaysFromIndulgences(List<IndulgenceModel> indulgences) {
    final uniqueDays = <DateTime>{};
    
    for (final indulgence in indulgences) {
      uniqueDays.add(_toCalendarDay(indulgence.date));
    }
    
    final sortedDays = uniqueDays.toList()..sort();
    return sortedDays;
  }

  /// Update a ViceModel with calculated streak data
  static ViceModel updateViceWithStreak(
    ViceModel vice,
    List<IndulgenceModel> indulgences,
  ) {
    final streakData = calculateViceStreak(vice.id!, indulgences, vice.createdAt);
    
    return vice.copyWith(
      currentStreak: streakData.currentStreak,
      longestStreak: streakData.longestStreak,
      lastIndulgenceDate: streakData.lastIndulgenceDate,
      totalIndulgences: streakData.totalIndulgences,
      indulgenceDates: indulgences
          .where((i) => i.viceId == vice.id)
          .map((i) => i.date)
          .toList(),
    );
  }

  /// Calculate streak data for multiple vices at once
  static List<ViceModel> updateVicesWithStreaks(
    List<ViceModel> vices,
    List<IndulgenceModel> indulgences,
  ) {
    return vices.map((vice) {
      if (vice.id != null) {
        return updateViceWithStreak(vice, indulgences);
      }
      return vice;
    }).toList();
  }

  /// Get vice streak overview statistics for all vices
  static ViceStreakOverview getViceStreakOverview(List<ViceModel> vices) {
    final activeStreaks = vices.where((v) => v.currentStreak > 0).toList();
    
    final totalActiveStreaks = activeStreaks.length;
    final totalStreakDays = activeStreaks.fold<int>(
      0, 
      (sum, vice) => sum + vice.currentStreak
    );
    
    final topStreak = activeStreaks.isNotEmpty 
        ? activeStreaks.reduce((a, b) => a.currentStreak > b.currentStreak ? a : b).currentStreak
        : 0;
    
    final longestEverStreak = vices.isNotEmpty
        ? vices.reduce((a, b) => a.longestStreak > b.longestStreak ? a : b).longestStreak
        : 0;

    final totalIndulgences = vices.fold<int>(
      0,
      (sum, vice) => sum + vice.totalIndulgences
    );

    return ViceStreakOverview(
      totalActiveStreaks: totalActiveStreaks,
      totalStreakDays: totalStreakDays,
      topCurrentStreak: topStreak,
      longestEverStreak: longestEverStreak,
      totalIndulgences: totalIndulgences,
      averageStreak: activeStreaks.isNotEmpty 
          ? (totalStreakDays / activeStreaks.length).round()
          : 0,
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

/// Data class to hold calculated vice streak information
class ViceStreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastIndulgenceDate;
  final int totalIndulgences;
  final int daysSinceLastIndulgence;

  const ViceStreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastIndulgenceDate,
    required this.totalIndulgences,
    required this.daysSinceLastIndulgence,
  });
}

/// Data class to hold overview statistics for all vice streaks
class ViceStreakOverview {
  final int totalActiveStreaks;
  final int totalStreakDays;
  final int topCurrentStreak;
  final int longestEverStreak;
  final int totalIndulgences;
  final int averageStreak;

  const ViceStreakOverview({
    required this.totalActiveStreaks,
    required this.totalStreakDays,
    required this.topCurrentStreak,
    required this.longestEverStreak,
    required this.totalIndulgences,
    required this.averageStreak,
  });
}