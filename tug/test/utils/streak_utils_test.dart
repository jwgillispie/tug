// test/utils/streak_utils_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/utils/streak_utils.dart';

void main() {
  group('StreakUtils', () {
    test('should calculate current streak correctly with calendar days', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBeforeYesterday = today.subtract(const Duration(days: 2));
      
      // Create activities for consecutive calendar days but at different times
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Exercise',
          valueId: 'value1',
          duration: 30,
          date: dayBeforeYesterday.add(const Duration(hours: 8)), // 2 days ago, 8 AM
          notes: 'Morning workout',
        ),
        ActivityModel(
          id: '2',
          name: 'Exercise',
          valueId: 'value1',
          duration: 45,
          date: yesterday.add(const Duration(hours: 23, minutes: 30)), // Yesterday, 11:30 PM
          notes: 'Late evening workout',
        ),
        ActivityModel(
          id: '3',
          name: 'Exercise',
          valueId: 'value1',
          duration: 60,
          date: today.add(const Duration(hours: 7, minutes: 15)), // Today, 7:15 AM
          notes: 'Early morning workout',
        ),
      ];

      final streakData = StreakUtils.calculateValueStreak('value1', activities);

      // Should show 3-day streak regardless of times within each day
      expect(streakData.currentStreak, equals(3));
      expect(streakData.longestStreak, equals(3));
      expect(streakData.streakDates.length, equals(3));
    });

    test('should handle gap in days correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      final fourDaysAgo = today.subtract(const Duration(days: 4));
      
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Exercise',
          valueId: 'value1',
          duration: 30,
          date: fourDaysAgo.add(const Duration(hours: 8)), // 4 days ago
          notes: 'Day 1',
        ),
        ActivityModel(
          id: '2',
          name: 'Exercise',
          valueId: 'value1',
          duration: 45,
          date: threeDaysAgo.add(const Duration(hours: 20)), // 3 days ago
          notes: 'Day 2',
        ),
        // Skip yesterday - streak broken
        ActivityModel(
          id: '3',
          name: 'Exercise',
          valueId: 'value1',
          duration: 60,
          date: yesterday.add(const Duration(hours: 10)), // Yesterday
          notes: 'Day 4',
        ),
        ActivityModel(
          id: '4',
          name: 'Exercise',
          valueId: 'value1',
          duration: 30,
          date: today.add(const Duration(hours: 15)), // Today
          notes: 'Day 5',
        ),
      ];

      final streakData = StreakUtils.calculateValueStreak('value1', activities);

      // Current streak should be 2 (yesterday-today), longest should be 2 (both streaks are same length)
      expect(streakData.currentStreak, equals(2));
      expect(streakData.longestStreak, equals(2));
    });

    test('should handle multiple activities on same day', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Exercise',
          valueId: 'value1',
          duration: 30,
          date: yesterday.add(const Duration(hours: 8)), // Yesterday, morning
          notes: 'Morning workout',
        ),
        ActivityModel(
          id: '2',
          name: 'Exercise',
          valueId: 'value1',
          duration: 45,
          date: yesterday.add(const Duration(hours: 18)), // Yesterday, evening
          notes: 'Evening workout',
        ),
        ActivityModel(
          id: '3',
          name: 'Exercise',
          valueId: 'value1',
          duration: 60,
          date: today.add(const Duration(hours: 10)), // Today
          notes: 'Next day workout',
        ),
      ];

      final streakData = StreakUtils.calculateValueStreak('value1', activities);

      // Should count as 2-day streak (multiple activities on same day = 1 day)
      expect(streakData.currentStreak, equals(2));
      expect(streakData.longestStreak, equals(2));
      expect(streakData.streakDates.length, equals(2));
    });

    test('should show broken streak when last activity was more than 1 day ago', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Exercise',
          valueId: 'value1',
          duration: 30,
          date: threeDaysAgo,
          notes: 'Old workout',
        ),
      ];

      final streakData = StreakUtils.calculateValueStreak('value1', activities);

      // Streak should be broken (0) since last activity was 3 days ago
      expect(streakData.currentStreak, equals(0));
    });

    test('should maintain streak when last activity was yesterday', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 10, 0);
      
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Exercise',
          valueId: 'value1',
          duration: 30,
          date: yesterday,
          notes: 'Yesterday workout',
        ),
      ];

      final streakData = StreakUtils.calculateValueStreak('value1', activities);

      // Streak should be active (1) since last activity was yesterday
      expect(streakData.currentStreak, equals(1));
    });

    test('should handle empty activities list', () {
      final streakData = StreakUtils.calculateValueStreak('value1', []);

      expect(streakData.currentStreak, equals(0));
      expect(streakData.longestStreak, equals(0));
      expect(streakData.lastActivityDate, isNull);
      expect(streakData.streakDates, isEmpty);
    });

    test('should filter activities by value ID', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Exercise',
          valueId: 'value1',
          duration: 30,
          date: yesterday,
          notes: 'Value 1 activity',
        ),
        ActivityModel(
          id: '2',
          name: 'Reading',
          valueId: 'value2',
          duration: 45,
          date: yesterday,
          notes: 'Value 2 activity',
        ),
        ActivityModel(
          id: '3',
          name: 'Exercise',
          valueId: 'value1',
          duration: 60,
          date: today,
          notes: 'Value 1 activity day 2',
        ),
      ];

      final streakData = StreakUtils.calculateValueStreak('value1', activities);

      // Should only count activities for value1 (2 consecutive days)
      expect(streakData.currentStreak, equals(2));
      expect(streakData.longestStreak, equals(2));
    });
  });
}