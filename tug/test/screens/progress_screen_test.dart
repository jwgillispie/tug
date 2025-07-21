// test/screens/progress_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tug/models/activity_model.dart';

void main() {
  group('Progress Screen Calculations', () {
    test('should calculate total minutes correctly for daily timeframe', () {
      // Sample activities for today
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Morning Exercise',
          valueIds: ['exercise_value'],
          duration: 30,
          date: todayStart.add(const Duration(hours: 8)),
          notes: 'Morning workout',
        ),
        ActivityModel(
          id: '2',
          name: 'Evening Exercise',
          valueIds: ['exercise_value'],
          duration: 45,
          date: todayStart.add(const Duration(hours: 18)),
          notes: 'Evening workout',
        ),
        ActivityModel(
          id: '3',
          name: 'Reading',
          valueIds: ['learning_value'],
          duration: 60,
          date: todayStart.add(const Duration(hours: 20)),
          notes: 'Book reading',
        ),
      ];

      // Filter activities for exercise value
      final exerciseActivities = activities.where(
        (activity) => activity.primaryValueId == 'exercise_value'
      ).toList();
      
      final totalMinutes = exerciseActivities.fold<int>(
        0, 
        (sum, activity) => sum + activity.duration
      );

      // Should be 30 + 45 = 75 minutes
      expect(totalMinutes, equals(75));
    });

    test('should calculate community averages correctly for different timeframes', () {
      // Test community average calculation logic
      int calculateCommunityAverage(String valueName, String timeframe) {
        int baseDailyAvg;
        
        final lowerName = valueName.toLowerCase();
        if (lowerName.contains('exercise')) {
          baseDailyAvg = 45;
        } else if (lowerName.contains('read')) {
          baseDailyAvg = 60;
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

      // Test exercise value
      expect(calculateCommunityAverage('Exercise', 'daily'), equals(45));
      expect(calculateCommunityAverage('Exercise', 'weekly'), equals(315)); // 45 * 7
      expect(calculateCommunityAverage('Exercise', 'monthly'), equals(1350)); // 45 * 30

      // Test reading value
      expect(calculateCommunityAverage('Reading', 'daily'), equals(60));
      expect(calculateCommunityAverage('Reading', 'weekly'), equals(420)); // 60 * 7
      expect(calculateCommunityAverage('Reading', 'monthly'), equals(1800)); // 60 * 30
    });

    test('should filter activities correctly by date range', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Today Exercise',
          valueIds: ['exercise_value'],
          duration: 30,
          date: today.add(const Duration(hours: 8)),
          notes: 'Today',
        ),
        ActivityModel(
          id: '2',
          name: 'Yesterday Exercise',
          valueIds: ['exercise_value'],
          duration: 45,
          date: yesterday.add(const Duration(hours: 8)),
          notes: 'Yesterday',
        ),
        ActivityModel(
          id: '3',
          name: 'Old Exercise',
          valueIds: ['exercise_value'],
          duration: 60,
          date: twoDaysAgo.add(const Duration(hours: 8)),
          notes: 'Two days ago',
        ),
      ];

      // Filter for daily (just today)
      final dailyActivities = activities.where((activity) {
        final activityDate = DateTime(
          activity.date.year, 
          activity.date.month, 
          activity.date.day
        );
        return activityDate.isAtSameMomentAs(today);
      }).toList();

      expect(dailyActivities.length, equals(1));
      expect(dailyActivities.first.duration, equals(30));

      // Filter for weekly (last 7 days)
      final weekStart = now.subtract(const Duration(days: 7));
      final weeklyActivities = activities.where((activity) {
        return activity.date.isAfter(weekStart) || 
               activity.date.isAtSameMomentAs(weekStart);
      }).toList();

      expect(weeklyActivities.length, equals(3)); // All activities within a week
    });
  });
}