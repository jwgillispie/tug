// lib/utils/cache_utils.dart

/// Centralized cache configuration and key generation utilities
class CacheUtils {
  // Standardized cache durations
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration standardCacheDuration = Duration(minutes: 15);
  static const Duration longCacheDuration = Duration(hours: 1);
  static const Duration diskCacheDuration = Duration(hours: 3);
  static const Duration extendedDiskCacheDuration = Duration(hours: 24);

  // Cache key prefixes
  static const String _activitiesPrefix = 'activities';
  static const String _valuesPrefix = 'values';
  static const String _rankingsPrefix = 'rankings';
  static const String _achievementsPrefix = 'achievements';
  static const String _statisticsPrefix = 'statistics';
  static const String _summaryPrefix = 'summary';
  static const String _progressPrefix = 'progress';
  static const String _streakStatsPrefix = 'streak_stats';

  /// Generate cache key for activities with optional filters
  static String activitiesKey({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _generateFilteredKey(
      _activitiesPrefix,
      valueId: valueId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate cache key for values
  static String valuesKey() => _valuesPrefix;

  /// Generate cache key for rankings
  static String rankingsKey({
    String rankBy = 'activities',
    int days = 30,
    int limit = 20,
  }) {
    return '${_rankingsPrefix}_${rankBy}_${days}_$limit';
  }

  /// Generate cache key for user rank
  static String userRankKey({int days = 30}) {
    return 'user_rank_$days';
  }

  /// Generate cache key for achievements
  static String achievementsKey() => _achievementsPrefix;

  /// Generate cache key for activity statistics
  static String statisticsKey({
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _generateFilteredKey(
      _statisticsPrefix,
      valueId: valueId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate cache key for activity summary
  static String summaryKey({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _generateFilteredKey(
      _summaryPrefix,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate cache key for combined progress data
  static String progressKey({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _generateFilteredKey(
      _progressPrefix,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate cache key for streak statistics
  static String streakStatsKey({String? valueId}) {
    return '${_streakStatsPrefix}_${valueId ?? "all"}';
  }

  /// Generate cache key for insight data
  static String insightKey({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _generateFilteredKey(
      '${_progressPrefix}_insights',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Helper method to generate filtered cache keys
  static String _generateFilteredKey(
    String prefix, {
    String? valueId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final parts = [prefix];
    
    if (valueId != null && valueId.isNotEmpty) {
      parts.add('value_$valueId');
    }
    
    if (startDate != null) {
      parts.add('start_${_formatDateForKey(startDate)}');
    }
    
    if (endDate != null) {
      parts.add('end_${_formatDateForKey(endDate)}');
    }
    
    return parts.join('_');
  }

  /// Format date consistently for cache keys
  static String _formatDateForKey(DateTime date) {
    return date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
  }

  /// Get appropriate cache duration based on data type
  static Duration getCacheDuration(CacheDataType dataType) {
    switch (dataType) {
      case CacheDataType.realTimeData:
        return shortCacheDuration;
      case CacheDataType.standardData:
        return standardCacheDuration;
      case CacheDataType.staticData:
        return longCacheDuration;
    }
  }

  /// Get appropriate disk cache duration based on data type
  static Duration getDiskCacheDuration(CacheDataType dataType) {
    switch (dataType) {
      case CacheDataType.realTimeData:
        return diskCacheDuration;
      case CacheDataType.standardData:
        return diskCacheDuration;
      case CacheDataType.staticData:
        return extendedDiskCacheDuration;
    }
  }
}

/// Enum to categorize different types of cached data
enum CacheDataType {
  realTimeData,    // Rankings, live stats (5 min cache)
  standardData,    // Activities, values (15 min cache)
  staticData,      // Achievements, settings (1 hour cache)
}