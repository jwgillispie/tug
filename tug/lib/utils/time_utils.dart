// lib/utils/time_utils.dart

class TimeUtils {
  /// Converts minutes to a human-readable format
  /// Examples:
  /// - 45 minutes → "45m"
  /// - 60 minutes → "1h"
  /// - 125 minutes → "2h 5m"
  /// - 0 minutes → "0m"
  static String formatMinutes(int minutes) {
    if (minutes == 0) {
      return '0m';
    }
    
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
  
  /// Converts minutes to a format with timeframe suffix
  /// Examples:
  /// - formatMinutesWithTimeframe(125, 'daily') → "2h 5m/day"
  /// - formatMinutesWithTimeframe(60, 'weekly') → "1h/week" 
  static String formatMinutesWithTimeframe(int minutes, String timeframe) {
    final formattedTime = formatMinutes(minutes);
    final timeframeSuffix = _getTimeframeSuffix(timeframe);
    return '$formattedTime$timeframeSuffix';
  }
  
  /// Helper method to get timeframe suffix
  static String _getTimeframeSuffix(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'daily':
        return '/day';
      case 'weekly':
        return '/week';
      case 'monthly':
        return '/month';
      default:
        return '/day';
    }
  }
}