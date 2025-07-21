// test/progress_screen_manual_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/models/value_model.dart';

/// Manual test to verify progress screen calculation logic
void main() {
  group('Progress Screen Manual Test', () {
    test('verify progress calculations work as expected', () {
      // Create sample data that matches what you might have
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      // Sample activities for today
      final activities = [
        ActivityModel(
          id: '1',
          name: 'Morning Exercise',
          valueIds: ['exercise_value_id'],
          duration: 45, // 45 minutes today
          date: todayStart.add(const Duration(hours: 8)),
          notes: 'Morning workout',
        ),
        ActivityModel(
          id: '2',
          name: 'Reading',
          valueIds: ['learning_value_id'],
          duration: 30, // 30 minutes today
          date: todayStart.add(const Duration(hours: 20)),
          notes: 'Book reading',
        ),
      ];

      // Sample values
      final values = [
        ValueModel(
          id: 'exercise_value_id',
          name: 'Exercise',
          importance: 5,
          color: '#FF5722',
          active: true,
        ),
        ValueModel(
          id: 'learning_value_id',
          name: 'Learning',
          importance: 4,
          color: '#2196F3',
          active: true,
        ),
      ];

      print('\n=== PROGRESS SCREEN MANUAL TEST ===');
      print('Today\'s date: $todayStart');
      print('Sample activities: ${activities.length}');
      
      // Test the calculation logic for each timeframe
      for (final timeframe in ['daily', 'weekly', 'monthly']) {
        print('\n--- $timeframe TIMEFRAME ---');
        
        // Calculate date range (same logic as progress screen)
        DateTime startDate;
        switch (timeframe) {
          case 'daily':
            startDate = todayStart; // Start of today
            break;
          case 'weekly':
            startDate = today.subtract(const Duration(days: 7));
            break;
          case 'monthly':
            startDate = today.subtract(const Duration(days: 30));
            break;
          default:
            startDate = today.subtract(const Duration(days: 7));
        }
        
        final endDate = today;
        print('Date range: $startDate to $endDate');

        // Filter activities by date range
        final filteredActivities = activities.where((activity) {
          return activity.date.isAfter(startDate) || activity.date.isAtSameMomentAs(startDate);
        }).toList();
        
        print('Activities in range: ${filteredActivities.length}');

        // Calculate data for each value
        for (final value in values) {
          final valueActivities = filteredActivities.where(
            (activity) => activity.primaryValueId == value.id
          ).toList();

          final totalMinutes = valueActivities.fold<int>(
            0, 
            (sum, activity) => sum + activity.duration
          );

          // Calculate community average
          final communityAvg = calculateCommunityAverage(value.name, timeframe);

          print('${value.name}: ${totalMinutes}min (user) vs ${communityAvg}min (community avg)');
          
          // This is what should show in the UI
          final userDisplay = formatMinutesWithTimeframe(totalMinutes, timeframe);
          final communityDisplay = formatMinutesWithTimeframe(communityAvg, timeframe);
          print('  Display: $userDisplay vs $communityDisplay');
        }
      }
      
      print('\n=== END TEST ===\n');
    });
  });
}

/// Helper function that matches progress screen logic
int calculateCommunityAverage(String valueName, String timeframe) {
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

/// Helper function that matches TimeUtils
String formatMinutesWithTimeframe(int minutes, String timeframe) {
  String formattedTime;
  if (minutes == 0) {
    formattedTime = '0m';
  } else {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours == 0) {
      formattedTime = '${remainingMinutes}m';
    } else if (remainingMinutes == 0) {
      formattedTime = '${hours}h';
    } else {
      formattedTime = '${hours}h ${remainingMinutes}m';
    }
  }
  
  String timeframeSuffix;
  switch (timeframe.toLowerCase()) {
    case 'daily':
      timeframeSuffix = '/day';
      break;
    case 'weekly':
      timeframeSuffix = '/week';
      break;
    case 'monthly':
      timeframeSuffix = '/month';
      break;
    default:
      timeframeSuffix = '/day';
  }
  
  return '$formattedTime$timeframeSuffix';
}