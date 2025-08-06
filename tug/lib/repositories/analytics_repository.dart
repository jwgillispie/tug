// lib/repositories/analytics_repository.dart
import 'package:tug/models/analytics_models.dart';
import 'package:tug/services/analytics_service.dart';
import 'package:tug/services/service_locator.dart';

class AnalyticsRepository {
  final AnalyticsService _analyticsService;

  AnalyticsRepository({
    AnalyticsService? analyticsService,
  }) : _analyticsService = analyticsService ?? ServiceLocator.analyticsService;

  /// Check if user has premium access for analytics features
  bool get hasPremiumAccess => _analyticsService.hasPremiumAccess;

  /// Get comprehensive analytics dashboard
  Future<AnalyticsData?> getAnalyticsDashboard({
    int daysBack = 30,
    String analyticsType = 'monthly',
    bool forceRefresh = false,
  }) async {
    try {
      return await _analyticsService.getAnalyticsDashboard(
        daysBack: daysBack,
        analyticsType: analyticsType,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      // Log error and return null
      return null;
    }
  }

  /// Get detailed insights for a specific value
  Future<ValueInsights?> getValueInsights(
    String valueId, {
    int daysBack = 90,
    bool forceRefresh = false,
  }) async {
    try {
      return await _analyticsService.getValueInsights(
        valueId,
        daysBack: daysBack,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get activity trends over time
  Future<Map<String, dynamic>?> getActivityTrends({
    int daysBack = 30,
    String analyticsType = 'daily',
    bool forceRefresh = false,
  }) async {
    try {
      return await _analyticsService.getActivityTrends(
        daysBack: daysBack,
        analyticsType: analyticsType,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get streak analytics for all values
  Future<Map<String, StreakAnalytics>?> getStreakAnalytics({
    bool forceRefresh = false,
  }) async {
    try {
      return await _analyticsService.getStreakAnalytics(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get AI-powered predictions and recommendations
  Future<PredictionData?> getPredictions({
    bool forceRefresh = false,
  }) async {
    try {
      return await _analyticsService.getPredictions(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get value breakdown with detailed metrics
  Future<List<ValueBreakdown>?> getValueBreakdown({
    int daysBack = 30,
    bool forceRefresh = false,
  }) async {
    try {
      return await _analyticsService.getValueBreakdown(
        daysBack: daysBack,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      return null;
    }
  }

  /// Export analytics data in specified format
  Future<Map<String, dynamic>?> exportAnalyticsData({
    String format = 'json',
    int daysBack = 90,
  }) async {
    try {
      return await _analyticsService.exportAnalyticsData(
        format: format,
        daysBack: daysBack,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get analytics summary for quick overview
  Future<Map<String, dynamic>?> getAnalyticsSummary() async {
    try {
      return await _analyticsService.getAnalyticsSummary();
    } catch (e) {
      return null;
    }
  }

  /// Clear analytics cache
  Future<void> clearAnalyticsCache() async {
    await _analyticsService.clearAnalyticsCache();
  }

  /// Show premium upgrade prompt
  void showPremiumUpgradePrompt() {
    _analyticsService.showPremiumUpgradePrompt();
  }
}