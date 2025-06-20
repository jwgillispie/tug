// test/utils/progress_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';
import 'package:tug/utils/progress_calculator.dart';

void main() {
  group('ProgressCalculator', () {
    test('should calculate progress data correctly for daily timeframe', () {
      // Create test data
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final values = [
        ValueModel(
          id: 'exercise_id',
          name: 'Exercise',
          importance: 5,
          color: '#FF5722',
          active: true,
        ),
        ValueModel(
          id: 'reading_id',
          name: 'Reading',
          importance: 4,
          color: '#2196F3',
          active: true,
        ),
      ];

      final activities = [
        ActivityModel(
          id: '1',
          name: 'Morning Exercise',
          valueId: 'exercise_id',
          duration: 45,
          date: todayStart.add(const Duration(hours: 8)),
          notes: 'Workout',
        ),
        ActivityModel(
          id: '2',
          name: 'Reading',
          valueId: 'reading_id',
          duration: 30,
          date: todayStart.add(const Duration(hours: 20)),
          notes: 'Book',
        ),
      ];

      // Calculate progress data
      final result = ProgressCalculator.calculateProgressData(
        values: values,
        activities: activities,
        timeframe: 'daily',
        startDate: todayStart,
        endDate: today,
      );

      // Verify results
      expect(result.length, equals(2));
      
      expect(result['Exercise']!['minutes'], equals(45));
      expect(result['Exercise']!['community_avg'], equals(45)); // Exercise base
      
      expect(result['Reading']!['minutes'], equals(30));
      expect(result['Reading']!['community_avg'], equals(60)); // Reading base
    });

    test('should scale community averages correctly for different timeframes', () {
      final values = [
        ValueModel(
          id: 'exercise_id',
          name: 'Exercise',
          importance: 5,
          color: '#FF5722',
          active: true,
        ),
      ];

      final activities = <ActivityModel>[];
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);

      // Test daily
      final dailyResult = ProgressCalculator.calculateProgressData(
        values: values,
        activities: activities,
        timeframe: 'daily',
        startDate: startDate,
        endDate: today,
      );
      expect(dailyResult['Exercise']!['community_avg'], equals(45));

      // Test weekly
      final weeklyResult = ProgressCalculator.calculateProgressData(
        values: values,
        activities: activities,
        timeframe: 'weekly',
        startDate: startDate,
        endDate: today,
      );
      expect(weeklyResult['Exercise']!['community_avg'], equals(315)); // 45 * 7

      // Test monthly
      final monthlyResult = ProgressCalculator.calculateProgressData(
        values: values,
        activities: activities,
        timeframe: 'monthly',
        startDate: startDate,
        endDate: today,
      );
      expect(monthlyResult['Exercise']!['community_avg'], equals(1350)); // 45 * 30
    });

    test('should filter activities by date range correctly', () {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final yesterday = todayStart.subtract(const Duration(days: 1));
      final twoDaysAgo = todayStart.subtract(const Duration(days: 2));

      final values = [
        ValueModel(
          id: 'exercise_id',
          name: 'Exercise',
          importance: 5,
          color: '#FF5722',
          active: true,
        ),
      ];

      final activities = [
        ActivityModel(
          id: '1',
          name: 'Today Exercise',
          valueId: 'exercise_id',
          duration: 30,
          date: todayStart.add(const Duration(hours: 8)),
          notes: 'Today',
        ),
        ActivityModel(
          id: '2',
          name: 'Yesterday Exercise',
          valueId: 'exercise_id',
          duration: 45,
          date: yesterday.add(const Duration(hours: 8)),
          notes: 'Yesterday',
        ),
        ActivityModel(
          id: '3',
          name: 'Old Exercise',
          valueId: 'exercise_id',
          duration: 60,
          date: twoDaysAgo.add(const Duration(hours: 8)),
          notes: 'Two days ago',
        ),
      ];

      // Test daily (should only include today's activity)
      final dailyResult = ProgressCalculator.calculateProgressData(
        values: values,
        activities: activities,
        timeframe: 'daily',
        startDate: todayStart,
        endDate: today,
      );
      expect(dailyResult['Exercise']!['minutes'], equals(30));
      expect(dailyResult['Exercise']!['activities_count'], equals(1));

      // Test weekly (should include yesterday and today)
      final weeklyStartDate = today.subtract(const Duration(days: 7));
      final weeklyResult = ProgressCalculator.calculateProgressData(
        values: values,
        activities: activities,
        timeframe: 'weekly',
        startDate: weeklyStartDate,
        endDate: today,
      );
      expect(weeklyResult['Exercise']!['minutes'], equals(135)); // 30 + 45 + 60
      expect(weeklyResult['Exercise']!['activities_count'], equals(3));
    });
  });
}