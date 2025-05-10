// lib/services/achievement_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tug/models/achievement_model.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/services/activity_service.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/services/cache_service.dart';

class AchievementService {
  final ActivityService _activityService;
  final CacheService _cacheService;
  final ApiService _apiService;

  // Cache keys
  static const String _achievementsCacheKey = 'achievements_data';
  static const Duration _cacheValidity = Duration(minutes: 15);

  AchievementService({
    ActivityService? activityService,
    CacheService? cacheService,
    ApiService? apiService,
  })  : _activityService = activityService ?? ActivityService(),
        _cacheService = cacheService ?? CacheService(),
        _apiService = apiService ?? ApiService();

  /// Gets all achievements with calculated progress based on user data
  Future<List<AchievementModel>> getAchievements({bool forceRefresh = false}) async {
    // Try to get from cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        final cachedAchievements = await _cacheService.get<List<dynamic>>(_achievementsCacheKey);
        if (cachedAchievements != null) {
          debugPrint('Achievements retrieved from cache');
          return cachedAchievements
              .map((data) => AchievementModel.fromJson(Map<String, dynamic>.from(data)))
              .toList();
        }
      } catch (e) {
        debugPrint('Error retrieving achievements from cache: $e');
      }
    }

    try {
      // Try to get achievements from backend API first
      final achievementsData = await _fetchAchievementsFromApi();
      if (achievementsData.isNotEmpty) {
        debugPrint('Achievements retrieved from API');
        // Cache the achievements
        await _cacheService.set(
          _achievementsCacheKey,
          achievementsData.map((a) => a.toJson()).toList(),
          memoryCacheDuration: _cacheValidity,
        );
        return achievementsData;
      }
    } catch (e) {
      debugPrint('Error fetching achievements from API: $e');
      // Fall back to local calculation if API fails
    }

    // If API fails or returns empty, fall back to local calculation
    return await _calculateAchievementsLocally(forceRefresh: forceRefresh);
  }

  /// Fetch achievements from the backend API
  Future<List<AchievementModel>> _fetchAchievementsFromApi() async {
    try {
      final response = await _apiService.get('/achievements');

      if (response.statusCode == 200) {
        final List<dynamic> achievementsJson = json.decode(response.body);
        return achievementsJson
          .map((json) => AchievementModel.fromJson(json))
          .toList();
      } else {
        debugPrint('API returned status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching achievements from API: $e');
      return [];
    }
  }

  /// Check for new achievements and sync with the backend
  Future<List<AchievementModel>> checkForNewAchievements() async {
    try {
      final response = await _apiService.get('/achievements/check');

      if (response.statusCode == 200) {
        final List<dynamic> newlyUnlockedJson = json.decode(response.body);
        final newlyUnlocked = newlyUnlockedJson
          .map((json) => AchievementModel.fromJson(json))
          .toList();

        // If we have new achievements, invalidate cache
        if (newlyUnlocked.isNotEmpty) {
          await _cacheService.remove(_achievementsCacheKey);
          debugPrint('Unlocked ${newlyUnlocked.length} new achievements');
        }

        return newlyUnlocked;
      } else {
        debugPrint('API returned status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error checking for new achievements: $e');
      return [];
    }
  }

  /// Calculate achievements locally when offline or as fallback
  Future<List<AchievementModel>> _calculateAchievementsLocally({bool forceRefresh = false}) async {
    debugPrint('Calculating achievements locally');

    // Get base achievements
    final baseAchievements = AchievementModel.getPredefinedAchievements();

    try {
      // Fetch the data we need to calculate achievement progress
      final activities = await _activityService.getActivities(forceRefresh: forceRefresh);

      // Calculate achievements based on the data
      final calculatedAchievements = await _calculateAchievementProgress(
        baseAchievements,
        activities,
      );

      // Cache the calculated achievements
      await _cacheService.set(
        _achievementsCacheKey,
        calculatedAchievements.map((a) => a.toJson()).toList(),
        memoryCacheDuration: _cacheValidity,
      );

      return calculatedAchievements;
    } catch (e) {
      debugPrint('Error calculating achievements locally: $e');
      // Return base achievements with no progress in case of error
      return baseAchievements;
    }
  }

  /// Sync achievements with the backend API
  Future<bool> syncAchievements(List<AchievementModel> achievements) async {
    try {
      // Check if any achievements are newly unlocked since last sync
      final newlyUnlocked = achievements.where((a) =>
        a.isUnlocked &&
        (a.unlockedAt?.isAfter(DateTime.now().subtract(const Duration(hours: 1))) ?? false)
      ).toList();

      if (newlyUnlocked.isEmpty) {
        debugPrint('No newly unlocked achievements to sync');
        return true;
      }

      // Sync each newly unlocked achievement
      for (var achievement in newlyUnlocked) {
        try {
          await _apiService.patch(
            '/achievements/${achievement.id}',
            data: json.encode({
              'is_unlocked': achievement.isUnlocked,
              'progress': achievement.progress,
              'unlocked_at': achievement.unlockedAt?.toIso8601String(),
            }),
          );
          debugPrint('Synced achievement: ${achievement.id}');
        } catch (e) {
          debugPrint('Error syncing achievement ${achievement.id}: $e');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error syncing achievements: $e');
      return false;
    }
  }

  /// Calculate the progress of all achievements based on user data
  Future<List<AchievementModel>> _calculateAchievementProgress(
    List<AchievementModel> baseAchievements,
    List<ActivityModel> activities,
  ) async {
    // Get values for streak calculations
    List<ValueModel> values = [];
    try {
      // This would typically come from a ValuesRepository
      // Using a placeholder implementation for now
      values = await _activityService.getValuesByActivities(activities);
    } catch (e) {
      debugPrint('Error fetching values: $e');
    }

    return baseAchievements.map((achievement) {
      switch (achievement.type) {
        case AchievementType.streak:
          return _calculateStreakAchievement(achievement, values);

        case AchievementType.balance:
          return _calculateBalanceAchievement(achievement, activities, values);

        case AchievementType.frequency:
          return _calculateFrequencyAchievement(achievement, activities);

        case AchievementType.milestone:
          return _calculateMilestoneAchievement(achievement, activities);

        case AchievementType.special:
          return _calculateSpecialAchievement(achievement, activities, values);
      }
    }).toList();
  }

  /// Calculate progress for streak-based achievements
  AchievementModel _calculateStreakAchievement(
    AchievementModel achievement,
    List<ValueModel> values,
  ) {
    // Find the maximum streak among all values
    int maxStreak = 0;
    for (var value in values) {
      if (value.currentStreak > maxStreak) {
        maxStreak = value.currentStreak;
      }

      // Also check the longest streak
      if (value.longestStreak > maxStreak) {
        maxStreak = value.longestStreak;
      }
    }

    // Check if we've achieved the required streak
    final isUnlocked = maxStreak >= achievement.requiredValue;

    // Calculate progress - cap at 1.0
    final progress = isUnlocked
        ? 1.0
        : (maxStreak / achievement.requiredValue).clamp(0.0, 1.0);

    // Return updated achievement
    return achievement.copyWith(
      isUnlocked: isUnlocked,
      progress: progress,
      unlockedAt: isUnlocked ? DateTime.now() : null,
    );
  }

  /// Calculate progress for balance-based achievements
  AchievementModel _calculateBalanceAchievement(
    AchievementModel achievement,
    List<ActivityModel> activities,
    List<ValueModel> values,
  ) {
    // For balance achievements, we need to check how long the user
    // has maintained balanced values

    // This is a placeholder implementation. In a real app, you'd need to track
    // balance history over time, probably in a separate data structure

    // For now, calculate a simple balance score based on activity distribution
    if (values.isEmpty || activities.isEmpty) {
      return achievement.copyWith(progress: 0.0, isUnlocked: false);
    }

    // Calculate activity counts per value
    final Map<String, int> activityCountsByValue = {};
    for (final activity in activities) {
      final valueId = activity.valueId;
      activityCountsByValue[valueId] = (activityCountsByValue[valueId] ?? 0) + 1;
    }

    // Calculate average activity count
    final avgActivities = activities.length / values.length;

    // Calculate standard deviation as a measure of imbalance
    double sumSquaredDiff = 0;
    int countValues = 0;

    for (final value in values) {
      if (value.active) {
        final count = activityCountsByValue[value.id] ?? 0;
        sumSquaredDiff += (count - avgActivities) * (count - avgActivities);
        countValues++;
      }
    }

    if (countValues == 0) {
      return achievement.copyWith(progress: 0.0, isUnlocked: false);
    }

    final stdDev = (sumSquaredDiff / countValues);

    // Lower stdDev means better balance. Convert to a 0-1 score
    final balanceScore = 1.0 - (stdDev / (avgActivities * 2)).clamp(0.0, 1.0);

    // For days maintained, use a rough estimate based on activity dates
    int daysWithActivities = 0;
    if (activities.isNotEmpty) {
      // Get unique dates
      final activityDates = activities
          .map((a) => DateTime(a.date.year, a.date.month, a.date.day))
          .toSet()
          .toList();

      activityDates.sort();
      daysWithActivities = activityDates.length;
    }

    // Combine balance score with duration
    final balanceDays = (daysWithActivities * balanceScore).round();

    // Check if the achievement is unlocked
    final isUnlocked = balanceDays >= achievement.requiredValue;

    // Calculate progress
    final progress = isUnlocked
        ? 1.0
        : (balanceDays / achievement.requiredValue).clamp(0.0, 1.0);

    return achievement.copyWith(
      isUnlocked: isUnlocked,
      progress: progress,
      unlockedAt: isUnlocked ? DateTime.now() : null,
    );
  }

  /// Calculate progress for frequency-based achievements
  AchievementModel _calculateFrequencyAchievement(
    AchievementModel achievement,
    List<ActivityModel> activities,
  ) {
    // Frequency achievements are based on total number of activities logged
    final activityCount = activities.length;

    // Check if the achievement is unlocked
    final isUnlocked = activityCount >= achievement.requiredValue;

    // Calculate progress
    final progress = isUnlocked
        ? 1.0
        : (activityCount / achievement.requiredValue).clamp(0.0, 1.0);

    return achievement.copyWith(
      isUnlocked: isUnlocked,
      progress: progress,
      unlockedAt: isUnlocked ? DateTime.now() : null,
    );
  }

  /// Calculate progress for milestone-based achievements
  AchievementModel _calculateMilestoneAchievement(
    AchievementModel achievement,
    List<ActivityModel> activities,
  ) {
    // Milestone achievements are based on total time spent
    int totalMinutes = 0;
    for (final activity in activities) {
      totalMinutes += activity.duration;
    }

    // Check if the achievement is unlocked
    final isUnlocked = totalMinutes >= achievement.requiredValue;

    // Calculate progress
    final progress = isUnlocked
        ? 1.0
        : (totalMinutes / achievement.requiredValue).clamp(0.0, 1.0);

    return achievement.copyWith(
      isUnlocked: isUnlocked,
      progress: progress,
      unlockedAt: isUnlocked ? DateTime.now() : null,
    );
  }

  /// Calculate progress for special achievements
  AchievementModel _calculateSpecialAchievement(
    AchievementModel achievement,
    List<ActivityModel> activities,
    List<ValueModel> values,
  ) {
    switch (achievement.id) {
      case 'special_balanced_all':
        return _calculatePerfectHarmonyAchievement(achievement, activities, values);

      case 'special_comeback':
        return _calculateComebackAchievement(achievement, activities);

      default:
        // Default case for any new special achievements
        return achievement.copyWith(progress: 0.0, isUnlocked: false);
    }
  }

  /// Calculate the "Perfect Harmony" achievement
  AchievementModel _calculatePerfectHarmonyAchievement(
    AchievementModel achievement,
    List<ActivityModel> activities,
    List<ValueModel> values,
  ) {
    if (values.isEmpty || activities.isEmpty) {
      return achievement.copyWith(progress: 0.0, isUnlocked: false);
    }

    // Calculate activity minutes per value
    final Map<String, int> minutesByValue = {};
    for (final activity in activities) {
      final valueId = activity.valueId;
      minutesByValue[valueId] = (minutesByValue[valueId] ?? 0) + activity.duration;
    }

    // Count values that have activities
    int valuesWithActivities = 0;
    int totalActiveValues = 0;

    for (final value in values) {
      if (value.active) {
        totalActiveValues++;
        if ((minutesByValue[value.id] ?? 0) > 0) {
          valuesWithActivities++;
        }
      }
    }

    if (totalActiveValues == 0) {
      return achievement.copyWith(progress: 0.0, isUnlocked: false);
    }

    // Perfect harmony achieved when all active values have activities
    final isUnlocked = valuesWithActivities == totalActiveValues && totalActiveValues >= 3;

    // Calculate progress
    final progress = totalActiveValues > 0
        ? (valuesWithActivities / totalActiveValues).clamp(0.0, 1.0)
        : 0.0;

    return achievement.copyWith(
      isUnlocked: isUnlocked,
      progress: progress,
      unlockedAt: isUnlocked ? DateTime.now() : null,
    );
  }

  /// Calculate the "Comeback Kid" achievement
  AchievementModel _calculateComebackAchievement(
    AchievementModel achievement,
    List<ActivityModel> activities,
  ) {
    if (activities.isEmpty) {
      return achievement.copyWith(progress: 0.0, isUnlocked: false);
    }

    // Sort activities by date
    final sortedActivities = [...activities]..sort((a, b) => a.date.compareTo(b.date));

    // Check for gaps of at least 14 days followed by new activity
    bool foundComeback = false;
    double longestBreakProgress = 0.0;

    // Need at least 2 activities to have a comeback
    if (sortedActivities.length >= 2) {
      DateTime? lastActivityDate;

      for (int i = 0; i < sortedActivities.length; i++) {
        final currentDate = sortedActivities[i].date;

        if (lastActivityDate != null) {
          final gap = currentDate.difference(lastActivityDate).inDays;

          // Update the longest break progress
          final gapProgress = (gap / 14).clamp(0.0, 1.0);
          if (gapProgress > longestBreakProgress) {
            longestBreakProgress = gapProgress;
          }

          // Check if this is a comeback (gap of 14+ days)
          if (gap >= 14) {
            foundComeback = true;
          }
        }

        lastActivityDate = currentDate;
      }
    }

    return achievement.copyWith(
      isUnlocked: foundComeback,
      progress: longestBreakProgress,
      unlockedAt: foundComeback ? DateTime.now() : null,
    );
  }
}