// lib/models/analytics_models.dart
import 'package:equatable/equatable.dart';

/// Comprehensive analytics data for premium users
class AnalyticsData extends Equatable {
  final AnalyticsOverview overview;
  final List<ValueBreakdown> valueBreakdown;
  final List<TrendData> trends;
  final ActivityPatterns patterns;
  final Map<String, StreakAnalytics> streaks;
  final PredictionData predictions;
  final DateTime generatedAt;

  const AnalyticsData({
    required this.overview,
    required this.valueBreakdown,
    required this.trends,
    required this.patterns,
    required this.streaks,
    required this.predictions,
    required this.generatedAt,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      overview: AnalyticsOverview.fromJson(json['overview'] ?? {}),
      valueBreakdown: (json['value_breakdown'] as List<dynamic>? ?? [])
          .map((item) => ValueBreakdown.fromJson(item))
          .toList(),
      trends: (json['trends'] as List<dynamic>? ?? [])
          .map((item) => TrendData.fromJson(item))
          .toList(),
      patterns: ActivityPatterns.fromJson(json['patterns'] ?? {}),
      streaks: (json['streaks'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, StreakAnalytics.fromJson(value))),
      predictions: PredictionData.fromJson(json['predictions'] ?? {}),
      generatedAt: DateTime.parse(json['generated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overview': overview.toJson(),
      'value_breakdown': valueBreakdown.map((item) => item.toJson()).toList(),
      'trends': trends.map((item) => item.toJson()).toList(),
      'patterns': patterns.toJson(),
      'streaks': streaks.map((key, value) => MapEntry(key, value.toJson())),
      'predictions': predictions.toJson(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        overview,
        valueBreakdown,
        trends,
        patterns,
        streaks,
        predictions,
        generatedAt,
      ];
}

/// High-level overview metrics
class AnalyticsOverview extends Equatable {
  final int totalActivities;
  final int totalDurationMinutes;
  final double totalDurationHours;
  final double avgDailyActivities;
  final double avgDailyDurationMinutes;
  final int activeDays;
  final int totalDays;
  final double consistencyPercentage;
  final double productivityScore;
  final double avgSessionDuration;

  const AnalyticsOverview({
    required this.totalActivities,
    required this.totalDurationMinutes,
    required this.totalDurationHours,
    required this.avgDailyActivities,
    required this.avgDailyDurationMinutes,
    required this.activeDays,
    required this.totalDays,
    required this.consistencyPercentage,
    required this.productivityScore,
    required this.avgSessionDuration,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalActivities: (json['total_activities'] ?? 0).toInt(),
      totalDurationMinutes: (json['total_duration_minutes'] ?? 0).toInt(),
      totalDurationHours: (json['total_duration_hours'] ?? 0.0).toDouble(),
      avgDailyActivities: (json['avg_daily_activities'] ?? 0.0).toDouble(),
      avgDailyDurationMinutes: (json['avg_daily_duration_minutes'] ?? 0.0).toDouble(),
      activeDays: (json['active_days'] ?? 0).toInt(),
      totalDays: (json['total_days'] ?? 0).toInt(),
      consistencyPercentage: (json['consistency_percentage'] ?? 0.0).toDouble(),
      productivityScore: (json['productivity_score'] ?? 0.0).toDouble(),
      avgSessionDuration: (json['avg_session_duration'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_activities': totalActivities,
      'total_duration_minutes': totalDurationMinutes,
      'total_duration_hours': totalDurationHours,
      'avg_daily_activities': avgDailyActivities,
      'avg_daily_duration_minutes': avgDailyDurationMinutes,
      'active_days': activeDays,
      'total_days': totalDays,
      'consistency_percentage': consistencyPercentage,
      'productivity_score': productivityScore,
      'avg_session_duration': avgSessionDuration,
    };
  }

  @override
  List<Object?> get props => [
        totalActivities,
        totalDurationMinutes,
        totalDurationHours,
        avgDailyActivities,
        avgDailyDurationMinutes,
        activeDays,
        totalDays,
        consistencyPercentage,
        productivityScore,
        avgSessionDuration,
      ];
}

/// Breakdown of activities by value
class ValueBreakdown extends Equatable {
  final String valueId;
  final String valueName;
  final String valueColor;
  final int activityCount;
  final int totalDuration;
  final double avgSessionDuration;
  final int minSessionDuration;
  final int maxSessionDuration;
  final int daysActive;
  final double consistencyScore;

  const ValueBreakdown({
    required this.valueId,
    required this.valueName,
    required this.valueColor,
    required this.activityCount,
    required this.totalDuration,
    required this.avgSessionDuration,
    required this.minSessionDuration,
    required this.maxSessionDuration,
    required this.daysActive,
    required this.consistencyScore,
  });

  factory ValueBreakdown.fromJson(Map<String, dynamic> json) {
    return ValueBreakdown(
      valueId: json['value_id'] ?? '',
      valueName: json['value_name'] ?? '',
      valueColor: json['value_color'] ?? '#3B82F6',
      activityCount: (json['activity_count'] ?? 0).toInt(),
      totalDuration: (json['total_duration'] ?? 0).toInt(),
      avgSessionDuration: (json['avg_session_duration'] ?? 0.0).toDouble(),
      minSessionDuration: (json['min_session_duration'] ?? 0).toInt(),
      maxSessionDuration: (json['max_session_duration'] ?? 0).toInt(),
      daysActive: (json['days_active'] ?? 0).toInt(),
      consistencyScore: (json['consistency_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value_id': valueId,
      'value_name': valueName,
      'value_color': valueColor,
      'activity_count': activityCount,
      'total_duration': totalDuration,
      'avg_session_duration': avgSessionDuration,
      'min_session_duration': minSessionDuration,
      'max_session_duration': maxSessionDuration,
      'days_active': daysActive,
      'consistency_score': consistencyScore,
    };
  }

  @override
  List<Object?> get props => [
        valueId,
        valueName,
        valueColor,
        activityCount,
        totalDuration,
        avgSessionDuration,
        minSessionDuration,
        maxSessionDuration,
        daysActive,
        consistencyScore,
      ];
}

/// Trend data for time-series charts
class TrendData extends Equatable {
  final String period;
  final int activityCount;
  final int totalDuration;
  final double avgDuration;

  const TrendData({
    required this.period,
    required this.activityCount,
    required this.totalDuration,
    required this.avgDuration,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      period: json['period'] ?? '',
      activityCount: (json['activity_count'] ?? 0).toInt(),
      totalDuration: (json['total_duration'] ?? 0).toInt(),
      avgDuration: (json['avg_duration'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'activity_count': activityCount,
      'total_duration': totalDuration,
      'avg_duration': avgDuration,
    };
  }

  @override
  List<Object?> get props => [period, activityCount, totalDuration, avgDuration];
}

/// Activity patterns for optimization
class ActivityPatterns extends Equatable {
  final List<DayPattern> bestDaysOfWeek;
  final List<HourPattern> bestHours;
  final DurationStats durationStats;

  const ActivityPatterns({
    required this.bestDaysOfWeek,
    required this.bestHours,
    required this.durationStats,
  });

  factory ActivityPatterns.fromJson(Map<String, dynamic> json) {
    return ActivityPatterns(
      bestDaysOfWeek: (json['best_days_of_week'] as List<dynamic>? ?? [])
          .map((item) => DayPattern.fromJson(item))
          .toList(),
      bestHours: (json['best_hours'] as List<dynamic>? ?? [])
          .map((item) => HourPattern.fromJson(item))
          .toList(),
      durationStats: DurationStats.fromJson(json['duration_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'best_days_of_week': bestDaysOfWeek.map((item) => item.toJson()).toList(),
      'best_hours': bestHours.map((item) => item.toJson()).toList(),
      'duration_stats': durationStats.toJson(),
    };
  }

  @override
  List<Object?> get props => [bestDaysOfWeek, bestHours, durationStats];
}

class DayPattern extends Equatable {
  final String day;
  final int count;
  final double percentage;

  const DayPattern({
    required this.day,
    required this.count,
    required this.percentage,
  });

  factory DayPattern.fromJson(Map<String, dynamic> json) {
    return DayPattern(
      day: json['day'] ?? '',
      count: (json['count'] ?? 0).toInt(),
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'count': count,
      'percentage': percentage,
    };
  }

  @override
  List<Object?> get props => [day, count, percentage];
}

class HourPattern extends Equatable {
  final int hour;
  final int count;
  final String timeLabel;

  const HourPattern({
    required this.hour,
    required this.count,
    required this.timeLabel,
  });

  factory HourPattern.fromJson(Map<String, dynamic> json) {
    return HourPattern(
      hour: (json['hour'] ?? 0).toInt(),
      count: (json['count'] ?? 0).toInt(),
      timeLabel: json['time_label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'count': count,
      'time_label': timeLabel,
    };
  }

  @override
  List<Object?> get props => [hour, count, timeLabel];
}

class DurationStats extends Equatable {
  final double average;
  final double median;
  final int mode;
  final double stdDev;

  const DurationStats({
    required this.average,
    required this.median,
    required this.mode,
    required this.stdDev,
  });

  factory DurationStats.fromJson(Map<String, dynamic> json) {
    return DurationStats(
      average: (json['average'] ?? 0.0).toDouble(),
      median: (json['median'] ?? 0.0).toDouble(),
      mode: (json['mode'] ?? 0).toInt(),
      stdDev: (json['std_dev'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'median': median,
      'mode': mode,
      'std_dev': stdDev,
    };
  }

  @override
  List<Object?> get props => [average, median, mode, stdDev];
}

/// Streak analytics for a specific value
class StreakAnalytics extends Equatable {
  final String valueName;
  final int currentStreak;
  final int longestStreak;
  final int totalStreaks;
  final double avgStreakLength;
  final Map<String, int> streakDistribution;

  const StreakAnalytics({
    required this.valueName,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalStreaks,
    required this.avgStreakLength,
    required this.streakDistribution,
  });

  factory StreakAnalytics.fromJson(Map<String, dynamic> json) {
    return StreakAnalytics(
      valueName: json['value_name'] ?? '',
      currentStreak: (json['current_streak'] ?? 0).toInt(),
      longestStreak: (json['longest_streak'] ?? 0).toInt(),
      totalStreaks: (json['total_streaks'] ?? 0).toInt(),
      avgStreakLength: (json['avg_streak_length'] ?? 0.0).toDouble(),
      streakDistribution: (json['streak_distribution'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as int? ?? 0))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value_name': valueName,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_streaks': totalStreaks,
      'avg_streak_length': avgStreakLength,
      'streak_distribution': streakDistribution,
    };
  }

  @override
  List<Object?> get props => [
        valueName,
        currentStreak,
        longestStreak,
        totalStreaks,
        avgStreakLength,
        streakDistribution,
      ];
}

/// AI-powered predictions and recommendations
class PredictionData extends Equatable {
  final String trendDirection;
  final double trendPercentage;
  final List<int> recommendedActivityHours;
  final double weeklyGoalProbability;
  final List<String> consistencyImprovementTips;
  final bool hasInsufficientData;

  const PredictionData({
    required this.trendDirection,
    required this.trendPercentage,
    required this.recommendedActivityHours,
    required this.weeklyGoalProbability,
    required this.consistencyImprovementTips,
    this.hasInsufficientData = false,
  });

  factory PredictionData.fromJson(Map<String, dynamic> json) {
    return PredictionData(
      trendDirection: json['trend_direction'] ?? 'stable',
      trendPercentage: (json['trend_percentage'] ?? 0.0).toDouble(),
      recommendedActivityHours: (json['recommended_activity_hours'] as List<dynamic>? ?? [])
          .map((item) => (item as int? ?? 0))
          .toList(),
      weeklyGoalProbability: (json['weekly_goal_probability'] ?? 0.0).toDouble(),
      consistencyImprovementTips: (json['consistency_improvement_tips'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      hasInsufficientData: json['insufficient_data'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trend_direction': trendDirection,
      'trend_percentage': trendPercentage,
      'recommended_activity_hours': recommendedActivityHours,
      'weekly_goal_probability': weeklyGoalProbability,
      'consistency_improvement_tips': consistencyImprovementTips,
      'insufficient_data': hasInsufficientData,
    };
  }

  @override
  List<Object?> get props => [
        trendDirection,
        trendPercentage,
        recommendedActivityHours,
        weeklyGoalProbability,
        consistencyImprovementTips,
        hasInsufficientData,
      ];
}

/// Value-specific insights
class ValueInsights extends Equatable {
  final String valueName;
  final int totalActivities;
  final ActivityPatterns patterns;
  final int streaks;
  final List<String> optimizationSuggestions;
  final ProgressForecast progressForecast;

  const ValueInsights({
    required this.valueName,
    required this.totalActivities,
    required this.patterns,
    required this.streaks,
    required this.optimizationSuggestions,
    required this.progressForecast,
  });

  factory ValueInsights.fromJson(Map<String, dynamic> json) {
    return ValueInsights(
      valueName: json['value_name'] ?? '',
      totalActivities: (json['total_activities'] ?? 0).toInt(),
      patterns: ActivityPatterns.fromJson(json['patterns'] ?? {}),
      streaks: (json['streaks'] ?? 0).toInt(),
      optimizationSuggestions: (json['optimization_suggestions'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      progressForecast: ProgressForecast.fromJson(json['progress_forecast'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value_name': valueName,
      'total_activities': totalActivities,
      'patterns': patterns.toJson(),
      'streaks': streaks,
      'optimization_suggestions': optimizationSuggestions,
      'progress_forecast': progressForecast.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        valueName,
        totalActivities,
        patterns,
        streaks,
        optimizationSuggestions,
        progressForecast,
      ];
}

class ProgressForecast extends Equatable {
  final int currentWeeklyAverage;
  final String trend;
  final int projectedNextWeek;
  final double confidence;
  final bool hasInsufficientData;

  const ProgressForecast({
    required this.currentWeeklyAverage,
    required this.trend,
    required this.projectedNextWeek,
    required this.confidence,
    this.hasInsufficientData = false,
  });

  factory ProgressForecast.fromJson(Map<String, dynamic> json) {
    return ProgressForecast(
      currentWeeklyAverage: (json['current_weekly_average'] ?? 0).toInt(),
      trend: json['trend'] ?? 'stable',
      projectedNextWeek: (json['projected_next_week'] ?? 0).toInt(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      hasInsufficientData: json['insufficient_data'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_weekly_average': currentWeeklyAverage,
      'trend': trend,
      'projected_next_week': projectedNextWeek,
      'confidence': confidence,
      'insufficient_data': hasInsufficientData,
    };
  }

  @override
  List<Object?> get props => [
        currentWeeklyAverage,
        trend,
        projectedNextWeek,
        confidence,
        hasInsufficientData,
      ];
}