// lib/blocs/analytics/analytics_state.dart
import 'package:equatable/equatable.dart';
import 'package:tug/models/analytics_models.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AnalyticsInitial extends AnalyticsState {}

/// Loading states
class AnalyticsLoading extends AnalyticsState {}

class AnalyticsDashboardLoading extends AnalyticsState {}

class ValueInsightsLoading extends AnalyticsState {
  final String valueId;

  const ValueInsightsLoading(this.valueId);

  @override
  List<Object?> get props => [valueId];
}

class ActivityTrendsLoading extends AnalyticsState {}

class StreakAnalyticsLoading extends AnalyticsState {}

class PredictionsLoading extends AnalyticsState {}

class ValueBreakdownLoading extends AnalyticsState {}

class AnalyticsExporting extends AnalyticsState {
  final String format;

  const AnalyticsExporting(this.format);

  @override
  List<Object?> get props => [format];
}

/// Success states
class AnalyticsDashboardLoaded extends AnalyticsState {
  final AnalyticsData data;

  const AnalyticsDashboardLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ValueInsightsLoaded extends AnalyticsState {
  final String valueId;
  final ValueInsights insights;

  const ValueInsightsLoaded(this.valueId, this.insights);

  @override
  List<Object?> get props => [valueId, insights];
}

class ActivityTrendsLoaded extends AnalyticsState {
  final Map<String, dynamic> trends;

  const ActivityTrendsLoaded(this.trends);

  @override
  List<Object?> get props => [trends];
}

class StreakAnalyticsLoaded extends AnalyticsState {
  final Map<String, StreakAnalytics> streaks;

  const StreakAnalyticsLoaded(this.streaks);

  @override
  List<Object?> get props => [streaks];
}

class PredictionsLoaded extends AnalyticsState {
  final PredictionData predictions;

  const PredictionsLoaded(this.predictions);

  @override
  List<Object?> get props => [predictions];
}

class ValueBreakdownLoaded extends AnalyticsState {
  final List<ValueBreakdown> breakdown;

  const ValueBreakdownLoaded(this.breakdown);

  @override
  List<Object?> get props => [breakdown];
}

class AnalyticsSummaryLoaded extends AnalyticsState {
  final Map<String, dynamic> summary;

  const AnalyticsSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class AnalyticsExported extends AnalyticsState {
  final Map<String, dynamic> data;
  final String format;

  const AnalyticsExported(this.data, this.format);

  @override
  List<Object?> get props => [data, format];
}

/// Cache cleared state
class AnalyticsCacheCleared extends AnalyticsState {}

/// Error states
class AnalyticsError extends AnalyticsState {
  final String message;
  final String? errorCode;

  const AnalyticsError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class PremiumRequired extends AnalyticsState {
  final String feature;

  const PremiumRequired(this.feature);

  @override
  List<Object?> get props => [feature];
}

class AnalyticsInsufficientData extends AnalyticsState {
  final String feature;

  const AnalyticsInsufficientData(this.feature);

  @override
  List<Object?> get props => [feature];
}

/// Combined state for comprehensive analytics view
class AnalyticsFullyLoaded extends AnalyticsState {
  final AnalyticsData? dashboard;
  final Map<String, ValueInsights> valueInsights;
  final Map<String, dynamic>? trends;
  final Map<String, StreakAnalytics>? streaks;
  final PredictionData? predictions;
  final List<ValueBreakdown>? valueBreakdown;
  final Map<String, dynamic>? summary;

  const AnalyticsFullyLoaded({
    this.dashboard,
    this.valueInsights = const {},
    this.trends,
    this.streaks,
    this.predictions,
    this.valueBreakdown,
    this.summary,
  });

  AnalyticsFullyLoaded copyWith({
    AnalyticsData? dashboard,
    Map<String, ValueInsights>? valueInsights,
    Map<String, dynamic>? trends,
    Map<String, StreakAnalytics>? streaks,
    PredictionData? predictions,
    List<ValueBreakdown>? valueBreakdown,
    Map<String, dynamic>? summary,
  }) {
    return AnalyticsFullyLoaded(
      dashboard: dashboard ?? this.dashboard,
      valueInsights: valueInsights ?? this.valueInsights,
      trends: trends ?? this.trends,
      streaks: streaks ?? this.streaks,
      predictions: predictions ?? this.predictions,
      valueBreakdown: valueBreakdown ?? this.valueBreakdown,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [
        dashboard,
        valueInsights,
        trends,
        streaks,
        predictions,
        valueBreakdown,
        summary,
      ];
}