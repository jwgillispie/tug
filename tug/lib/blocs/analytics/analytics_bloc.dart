// lib/blocs/analytics/analytics_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:tug/repositories/analytics_repository.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _analyticsRepository;
  final Logger _logger = Logger();

  AnalyticsBloc({
    required AnalyticsRepository analyticsRepository,
  }) : _analyticsRepository = analyticsRepository,
       super(AnalyticsInitial()) {
    
    // Register event handlers
    on<LoadAnalyticsDashboard>(_onLoadAnalyticsDashboard);
    on<LoadValueInsights>(_onLoadValueInsights);
    on<LoadActivityTrends>(_onLoadActivityTrends);
    on<LoadStreakAnalytics>(_onLoadStreakAnalytics);
    on<LoadPredictions>(_onLoadPredictions);
    on<LoadValueBreakdown>(_onLoadValueBreakdown);
    on<LoadAnalyticsSummary>(_onLoadAnalyticsSummary);
    on<ExportAnalyticsData>(_onExportAnalyticsData);
    on<ClearAnalyticsCache>(_onClearAnalyticsCache);
    on<ShowPremiumUpgrade>(_onShowPremiumUpgrade);
    on<ResetAnalytics>(_onResetAnalytics);
  }

  /// Check premium access
  bool get hasPremiumAccess => _analyticsRepository.hasPremiumAccess;

  /// Load comprehensive analytics dashboard
  Future<void> _onLoadAnalyticsDashboard(
    LoadAnalyticsDashboard event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('Analytics Dashboard'));
      return;
    }

    try {
      emit(AnalyticsDashboardLoading());
      _logger.i('Loading analytics dashboard: ${event.daysBack} days, type: ${event.analyticsType}');

      final dashboard = await _analyticsRepository.getAnalyticsDashboard(
        daysBack: event.daysBack,
        analyticsType: event.analyticsType,
        forceRefresh: event.forceRefresh,
      );

      if (dashboard != null) {
        emit(AnalyticsDashboardLoaded(dashboard));
        _logger.i('Analytics dashboard loaded successfully');
      } else {
        emit(const AnalyticsError('Failed to load analytics dashboard'));
      }
    } catch (e) {
      _logger.e('Error loading analytics dashboard: $e');
      emit(AnalyticsError('Failed to load analytics dashboard: ${e.toString()}'));
    }
  }

  /// Load value-specific insights
  Future<void> _onLoadValueInsights(
    LoadValueInsights event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('Value Insights'));
      return;
    }

    try {
      emit(ValueInsightsLoading(event.valueId));
      _logger.i('Loading value insights for: ${event.valueId}');

      final insights = await _analyticsRepository.getValueInsights(
        event.valueId,
        daysBack: event.daysBack,
        forceRefresh: event.forceRefresh,
      );

      if (insights != null) {
        if (insights.progressForecast.hasInsufficientData) {
          emit(const AnalyticsInsufficientData('Value Insights'));
        } else {
          emit(ValueInsightsLoaded(event.valueId, insights));
          _logger.i('Value insights loaded successfully for: ${event.valueId}');
        }
      } else {
        emit(const AnalyticsError('Failed to load value insights'));
      }
    } catch (e) {
      _logger.e('Error loading value insights: $e');
      emit(AnalyticsError('Failed to load value insights: ${e.toString()}'));
    }
  }

  /// Load activity trends
  Future<void> _onLoadActivityTrends(
    LoadActivityTrends event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('Activity Trends'));
      return;
    }

    try {
      emit(ActivityTrendsLoading());
      _logger.i('Loading activity trends: ${event.daysBack} days, type: ${event.analyticsType}');

      final trends = await _analyticsRepository.getActivityTrends(
        daysBack: event.daysBack,
        analyticsType: event.analyticsType,
        forceRefresh: event.forceRefresh,
      );

      if (trends != null) {
        emit(ActivityTrendsLoaded(trends));
        _logger.i('Activity trends loaded successfully');
      } else {
        emit(const AnalyticsError('Failed to load activity trends'));
      }
    } catch (e) {
      _logger.e('Error loading activity trends: $e');
      emit(AnalyticsError('Failed to load activity trends: ${e.toString()}'));
    }
  }

  /// Load streak analytics
  Future<void> _onLoadStreakAnalytics(
    LoadStreakAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('Streak Analytics'));
      return;
    }

    try {
      emit(StreakAnalyticsLoading());
      _logger.i('Loading streak analytics');

      final streaks = await _analyticsRepository.getStreakAnalytics(
        forceRefresh: event.forceRefresh,
      );

      if (streaks != null) {
        emit(StreakAnalyticsLoaded(streaks));
        _logger.i('Streak analytics loaded successfully');
      } else {
        emit(const AnalyticsError('Failed to load streak analytics'));
      }
    } catch (e) {
      _logger.e('Error loading streak analytics: $e');
      emit(AnalyticsError('Failed to load streak analytics: ${e.toString()}'));
    }
  }

  /// Load AI predictions
  Future<void> _onLoadPredictions(
    LoadPredictions event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('AI Predictions'));
      return;
    }

    try {
      emit(PredictionsLoading());
      _logger.i('Loading AI predictions');

      final predictions = await _analyticsRepository.getPredictions(
        forceRefresh: event.forceRefresh,
      );

      if (predictions != null) {
        if (predictions.hasInsufficientData) {
          emit(const AnalyticsInsufficientData('AI Predictions'));
        } else {
          emit(PredictionsLoaded(predictions));
          _logger.i('AI predictions loaded successfully');
        }
      } else {
        emit(const AnalyticsError('Failed to load AI predictions'));
      }
    } catch (e) {
      _logger.e('Error loading AI predictions: $e');
      emit(AnalyticsError('Failed to load AI predictions: ${e.toString()}'));
    }
  }

  /// Load value breakdown
  Future<void> _onLoadValueBreakdown(
    LoadValueBreakdown event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('Value Breakdown'));
      return;
    }

    try {
      emit(ValueBreakdownLoading());
      _logger.i('Loading value breakdown: ${event.daysBack} days');

      final breakdown = await _analyticsRepository.getValueBreakdown(
        daysBack: event.daysBack,
        forceRefresh: event.forceRefresh,
      );

      if (breakdown != null) {
        emit(ValueBreakdownLoaded(breakdown));
        _logger.i('Value breakdown loaded successfully');
      } else {
        emit(const AnalyticsError('Failed to load value breakdown'));
      }
    } catch (e) {
      _logger.e('Error loading value breakdown: $e');
      emit(AnalyticsError('Failed to load value breakdown: ${e.toString()}'));
    }
  }

  /// Load analytics summary
  Future<void> _onLoadAnalyticsSummary(
    LoadAnalyticsSummary event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('Analytics Summary'));
      return;
    }

    try {
      _logger.i('Loading analytics summary');

      final summary = await _analyticsRepository.getAnalyticsSummary();

      if (summary != null) {
        emit(AnalyticsSummaryLoaded(summary));
        _logger.i('Analytics summary loaded successfully');
      } else {
        emit(const AnalyticsError('Failed to load analytics summary'));
      }
    } catch (e) {
      _logger.e('Error loading analytics summary: $e');
      emit(AnalyticsError('Failed to load analytics summary: ${e.toString()}'));
    }
  }

  /// Export analytics data
  Future<void> _onExportAnalyticsData(
    ExportAnalyticsData event,
    Emitter<AnalyticsState> emit,
  ) async {
    if (!hasPremiumAccess) {
      emit(const PremiumRequired('Data Export'));
      return;
    }

    try {
      emit(AnalyticsExporting(event.format));
      _logger.i('Exporting analytics data: format=${event.format}, days=${event.daysBack}');

      final exportData = await _analyticsRepository.exportAnalyticsData(
        format: event.format,
        daysBack: event.daysBack,
      );

      if (exportData != null) {
        emit(AnalyticsExported(exportData, event.format));
        _logger.i('Analytics data exported successfully');
      } else {
        emit(const AnalyticsError('Failed to export analytics data'));
      }
    } catch (e) {
      _logger.e('Error exporting analytics data: $e');
      emit(AnalyticsError('Failed to export analytics data: ${e.toString()}'));
    }
  }

  /// Clear analytics cache
  Future<void> _onClearAnalyticsCache(
    ClearAnalyticsCache event,
    Emitter<AnalyticsState> emit,
  ) async {
    try {
      _logger.i('Clearing analytics cache');
      await _analyticsRepository.clearAnalyticsCache();
      emit(AnalyticsCacheCleared());
      _logger.i('Analytics cache cleared successfully');
    } catch (e) {
      _logger.e('Error clearing analytics cache: $e');
      emit(AnalyticsError('Failed to clear analytics cache: ${e.toString()}'));
    }
  }

  /// Show premium upgrade prompt
  Future<void> _onShowPremiumUpgrade(
    ShowPremiumUpgrade event,
    Emitter<AnalyticsState> emit,
  ) async {
    _analyticsRepository.showPremiumUpgradePrompt();
    emit(const PremiumRequired('Premium Features'));
  }

  /// Reset analytics state
  Future<void> _onResetAnalytics(
    ResetAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsInitial());
    _logger.i('Analytics state reset');
  }

  /// Convenience method to load all analytics data
  Future<void> loadFullAnalytics({
    int daysBack = 30,
    String analyticsType = 'monthly',
    bool forceRefresh = false,
  }) async {
    if (!hasPremiumAccess) {
      add(const ShowPremiumUpgrade());
      return;
    }

    // Load dashboard first
    add(LoadAnalyticsDashboard(
      daysBack: daysBack,
      analyticsType: analyticsType,
      forceRefresh: forceRefresh,
    ));

    // Load other analytics components
    add(LoadStreakAnalytics(forceRefresh: forceRefresh));
    add(LoadPredictions(forceRefresh: forceRefresh));
    add(LoadValueBreakdown(daysBack: daysBack, forceRefresh: forceRefresh));
  }

  /// Get readable error message
  String getErrorMessage(String defaultMessage) {
    if (!hasPremiumAccess) {
      return 'Premium subscription required for advanced analytics';
    }
    return defaultMessage;
  }
}