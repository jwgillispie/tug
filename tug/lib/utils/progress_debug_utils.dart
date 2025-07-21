// lib/utils/progress_debug_utils.dart
import 'package:tug/models/activity_model.dart';

/// Utility class for debugging progress calculations
class ProgressDebugUtils {
  /// Debug print activity summary for a given timeframe
  static void printActivitySummary(
    List<ActivityModel> activities,
    String timeframe,
    DateTime startDate,
    DateTime endDate,
  ) {
    // print('=== Activity Summary ($timeframe) ===');
    // print('Date range: ${startDate.toLocal()} to ${endDate.toLocal()}');
    // print('Total activities: ${activities.length}');
    
    if (activities.isEmpty) {
      // print('No activities found in this timeframe');
      return;
    }
    
    // Group by value
    final Map<String, List<ActivityModel>> groupedActivities = {};
    for (final activity in activities) {
      if (!groupedActivities.containsKey(activity.valueId)) {
        groupedActivities[activity.valueId] = [];
      }
      groupedActivities[activity.valueId]!.add(activity);
    }
    
    // Print summary for each value
    groupedActivities.forEach((valueId, valueActivities) {
      final totalMinutes = valueActivities.fold<int>(
        0, 
        (sum, activity) => sum + activity.duration
      );
      
      // print('Value: $valueId');
      // print('  Activities: ${valueActivities.length}');
      // print('  Total minutes: $totalMinutes');
      // print('  Activities: ${valueActivities.map((a) => '${a.name} (${a.duration}m)').join(', ')}');
    });
    
    // print('==============================\n');
  }
  
  /// Debug print community average calculations
  static void printCommunityAverages(
    Map<String, String> valueNames,
    String timeframe,
  ) {
    // print('=== Community Averages ($timeframe) ===');
    
    valueNames.forEach((valueId, valueName) {
      final avg = _calculateCommunityAverage(valueName, timeframe);
      // print('$valueName: ${_formatMinutes(avg)}');
    });
    
    // print('=====================================\n');
  }
  
  /// Helper method to calculate community average (matches progress screen logic)
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
  
  /// Helper method to format minutes
  static String _formatMinutes(int minutes) {
    if (minutes == 0) return '0m';
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours == 0) {
      return '${remainingMinutes}m';
    } else if (remainingMinutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${remainingMinutes}m';
    }
  }
}