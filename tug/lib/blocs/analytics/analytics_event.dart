// lib/blocs/analytics/analytics_event.dart
import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Load comprehensive analytics dashboard
class LoadAnalyticsDashboard extends AnalyticsEvent {
  final int daysBack;
  final String analyticsType;
  final bool forceRefresh;

  const LoadAnalyticsDashboard({
    this.daysBack = 30,
    this.analyticsType = 'monthly',
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [daysBack, analyticsType, forceRefresh];
}

/// Load insights for a specific value
class LoadValueInsights extends AnalyticsEvent {
  final String valueId;
  final int daysBack;
  final bool forceRefresh;

  const LoadValueInsights({
    required this.valueId,
    this.daysBack = 90,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [valueId, daysBack, forceRefresh];
}

/// Load activity trends
class LoadActivityTrends extends AnalyticsEvent {
  final int daysBack;
  final String analyticsType;
  final bool forceRefresh;

  const LoadActivityTrends({
    this.daysBack = 30,
    this.analyticsType = 'daily',
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [daysBack, analyticsType, forceRefresh];
}

/// Load streak analytics
class LoadStreakAnalytics extends AnalyticsEvent {
  final bool forceRefresh;

  const LoadStreakAnalytics({
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [forceRefresh];
}

/// Load AI predictions
class LoadPredictions extends AnalyticsEvent {
  final bool forceRefresh;

  const LoadPredictions({
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [forceRefresh];
}

/// Load value breakdown
class LoadValueBreakdown extends AnalyticsEvent {
  final int daysBack;
  final bool forceRefresh;

  const LoadValueBreakdown({
    this.daysBack = 30,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [daysBack, forceRefresh];
}

/// Load analytics summary
class LoadAnalyticsSummary extends AnalyticsEvent {
  const LoadAnalyticsSummary();
}

/// Export analytics data
class ExportAnalyticsData extends AnalyticsEvent {
  final String format;
  final int daysBack;

  const ExportAnalyticsData({
    this.format = 'json',
    this.daysBack = 90,
  });

  @override
  List<Object?> get props => [format, daysBack];
}

/// Clear analytics cache
class ClearAnalyticsCache extends AnalyticsEvent {
  const ClearAnalyticsCache();
}

/// Show premium upgrade prompt
class ShowPremiumUpgrade extends AnalyticsEvent {
  const ShowPremiumUpgrade();
}

/// Reset analytics state
class ResetAnalytics extends AnalyticsEvent {
  const ResetAnalytics();
}