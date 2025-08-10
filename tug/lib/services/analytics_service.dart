// lib/services/analytics_service.dart
import 'package:logger/logger.dart';
import 'package:tug/models/analytics_models.dart';
import 'package:tug/services/cache_service.dart';
import 'package:tug/services/service_locator.dart';
import 'package:tug/services/subscription_service.dart';
import 'api_service.dart';

class AnalyticsService {
  final ApiService _apiService;
  final CacheService _cacheService;
  final SubscriptionService _subscriptionService;
  final Logger _logger = Logger();

  AnalyticsService({
    ApiService? apiService,
    CacheService? cacheService,
    SubscriptionService? subscriptionService,
  }) : 
    _apiService = apiService ?? ServiceLocator.apiService,
    _cacheService = cacheService ?? ServiceLocator.cacheService,
    _subscriptionService = subscriptionService ?? SubscriptionService();

  /// Check if user has premium access for analytics features
  bool get hasPremiumAccess => _subscriptionService.isPremium;

  /// Get comprehensive analytics dashboard
  Future<AnalyticsData?> getAnalyticsDashboard({
    int daysBack = 30,
    String analyticsType = 'monthly',
    bool forceRefresh = false,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('Analytics dashboard requires premium subscription');
      return null;
    }

    final cacheKey = 'analytics_dashboard_${daysBack}_$analyticsType';

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        try {
          return AnalyticsData.fromJson(cachedData['data']);
        } catch (e) {
          _logger.e('Error parsing cached analytics data: $e');
        }
      }
    }

    try {
      _logger.i('Fetching analytics dashboard: $daysBack days, type: $analyticsType');
      
      final response = await _apiService.get(
        '/analytics/dashboard',
        queryParameters: {
          'days_back': daysBack,
          'analytics_type': analyticsType,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final analyticsData = AnalyticsData.fromJson(response['data']);
        
        // Cache the result for 1 hour
        await _cacheService.set(
          cacheKey,
          response,
          memoryCacheDuration: const Duration(hours: 1),
          diskCacheDuration: const Duration(hours: 1),
        );
        
        _logger.i('Analytics dashboard fetched successfully');
        return analyticsData;
      } else {
        _logger.w('Analytics dashboard fetch failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching analytics dashboard: $e');
      return null;
    }
  }

  /// Get detailed insights for a specific value
  Future<ValueInsights?> getValueInsights(
    String valueId, {
    int daysBack = 90,
    bool forceRefresh = false,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('Value insights require premium subscription');
      return null;
    }

    final cacheKey = 'value_insights_${valueId}_$daysBack';

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        try {
          return ValueInsights.fromJson(cachedData['data']);
        } catch (e) {
          _logger.e('Error parsing cached value insights: $e');
        }
      }
    }

    try {
      _logger.i('Fetching value insights for: $valueId');
      
      final response = await _apiService.get(
        '/analytics/insights/value/$valueId',
        queryParameters: {
          'days_back': daysBack,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final insights = ValueInsights.fromJson(response['data']);
        
        // Cache the result for 30 minutes
        await _cacheService.set(
          cacheKey,
          response,
          memoryCacheDuration: const Duration(minutes: 30),
          diskCacheDuration: const Duration(minutes: 30),
        );
        
        _logger.i('Value insights fetched successfully for: $valueId');
        return insights;
      } else {
        _logger.w('Value insights fetch failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching value insights: $e');
      return null;
    }
  }

  /// Get activity trends over time
  Future<Map<String, dynamic>?> getActivityTrends({
    int daysBack = 30,
    String analyticsType = 'daily',
    bool forceRefresh = false,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('Activity trends require premium subscription');
      return null;
    }

    final cacheKey = 'activity_trends_${daysBack}_$analyticsType';

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData['data'];
      }
    }

    try {
      _logger.i('Fetching activity trends: $daysBack days, type: $analyticsType');
      
      final response = await _apiService.get(
        '/analytics/trends',
        queryParameters: {
          'days_back': daysBack,
          'analytics_type': analyticsType,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        // Cache the result for 15 minutes
        await _cacheService.set(
          cacheKey,
          response,
          memoryCacheDuration: const Duration(minutes: 15),
          diskCacheDuration: const Duration(minutes: 15),
        );
        
        _logger.i('Activity trends fetched successfully');
        return response['data'];
      } else {
        _logger.w('Activity trends fetch failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching activity trends: $e');
      return null;
    }
  }

  /// Get streak analytics for all values
  Future<Map<String, StreakAnalytics>?> getStreakAnalytics({
    bool forceRefresh = false,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('Streak analytics require premium subscription');
      return null;
    }

    const cacheKey = 'streak_analytics';

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        try {
          final data = cachedData['data'] as Map<String, dynamic>;
          return data.map((key, value) => MapEntry(key, StreakAnalytics.fromJson(value)));
        } catch (e) {
          _logger.e('Error parsing cached streak analytics: $e');
        }
      }
    }

    try {
      _logger.i('Fetching streak analytics');
      
      final response = await _apiService.get('/analytics/streaks');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final streakAnalytics = data.map((key, value) => 
            MapEntry(key, StreakAnalytics.fromJson(value)));
        
        // Cache the result for 10 minutes
        await _cacheService.set(
          cacheKey,
          response,
          memoryCacheDuration: const Duration(minutes: 10),
          diskCacheDuration: const Duration(minutes: 10),
        );
        
        _logger.i('Streak analytics fetched successfully');
        return streakAnalytics;
      } else {
        _logger.w('Streak analytics fetch failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching streak analytics: $e');
      return null;
    }
  }

  /// Get AI-powered predictions and recommendations
  Future<PredictionData?> getPredictions({
    bool forceRefresh = false,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('Predictions require premium subscription');
      return null;
    }

    const cacheKey = 'predictions';

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        try {
          return PredictionData.fromJson(cachedData['data']);
        } catch (e) {
          _logger.e('Error parsing cached predictions: $e');
        }
      }
    }

    try {
      _logger.i('Fetching AI predictions');
      
      final response = await _apiService.get('/analytics/predictions');

      if (response['success'] == true && response['data'] != null) {
        final predictions = PredictionData.fromJson(response['data']);
        
        // Cache the result for 1 hour (predictions don't change frequently)
        await _cacheService.set(
          cacheKey,
          response,
          memoryCacheDuration: const Duration(hours: 1),
          diskCacheDuration: const Duration(hours: 1),
        );
        
        _logger.i('AI predictions fetched successfully');
        return predictions;
      } else {
        _logger.w('Predictions fetch failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching predictions: $e');
      return null;
    }
  }

  /// Get value breakdown with detailed metrics
  Future<List<ValueBreakdown>?> getValueBreakdown({
    int daysBack = 30,
    bool forceRefresh = false,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('Value breakdown requires premium subscription');
      return null;
    }

    final cacheKey = 'value_breakdown_$daysBack';

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        try {
          final data = cachedData['data'] as List<dynamic>;
          return data.map((item) => ValueBreakdown.fromJson(item)).toList();
        } catch (e) {
          _logger.e('Error parsing cached value breakdown: $e');
        }
      }
    }

    try {
      _logger.i('Fetching value breakdown: $daysBack days');
      
      final response = await _apiService.get(
        '/analytics/value-breakdown',
        queryParameters: {
          'days_back': daysBack,
        },
      );

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        final valueBreakdown = data.map((item) => ValueBreakdown.fromJson(item)).toList();
        
        // Cache the result for 30 minutes
        await _cacheService.set(
          cacheKey,
          response,
          memoryCacheDuration: const Duration(minutes: 30),
          diskCacheDuration: const Duration(minutes: 30),
        );
        
        _logger.i('Value breakdown fetched successfully');
        return valueBreakdown;
      } else {
        _logger.w('Value breakdown fetch failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching value breakdown: $e');
      return null;
    }
  }

  /// Export analytics data in specified format
  Future<Map<String, dynamic>?> exportAnalyticsData({
    String format = 'json',
    int daysBack = 90,
    List<String> dataTypes = const ['all'],
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('Data export requires premium subscription');
      return null;
    }

    try {
      _logger.i('Exporting analytics data: format=$format, days=$daysBack, types=${dataTypes.join(',')}');
      
      final queryParams = <String, dynamic>{
        'format': format,
        'days_back': daysBack,
        'data_types': dataTypes.join(','),
      };
      
      // Add date range if provided
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      
      final response = await _apiService.get(
        '/analytics/export',
        queryParameters: queryParams,
      );

      if (response['success'] == true) {
        _logger.i('Analytics data exported successfully');
        return response;
      } else {
        _logger.w('Analytics export failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error exporting analytics data: $e');
      return null;
    }
  }

  /// Export analytics data as CSV files using dedicated CSV endpoint
  Future<Map<String, String>?> exportToCSV({
    int daysBack = 90,
    List<String> dataTypes = const ['all'],
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('CSV export requires premium subscription');
      return null;
    }

    try {
      _logger.i('Exporting analytics data to CSV: ${dataTypes.join(',')}');
      
      final queryParams = <String, dynamic>{
        'days_back': daysBack,
        'data_types': dataTypes.join(','),
      };
      
      // Add date range if provided
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      
      final response = await _apiService.get(
        '/analytics/export/csv',
        queryParameters: queryParams,
      );

      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        _logger.i('CSV export completed successfully');
        return Map<String, String>.from(response['data']);
      } else {
        _logger.w('CSV export failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error exporting CSV: $e');
      return null;
    }
  }

  /// Export analytics data as PDF using dedicated PDF endpoint
  Future<Map<String, dynamic>?> exportToPDF({
    int daysBack = 90,
    List<String> dataTypes = const ['all'],
    DateTime? startDate,
    DateTime? endDate,
    bool includeCharts = true,
  }) async {
    if (!hasPremiumAccess) {
      _logger.w('PDF export requires premium subscription');
      return null;
    }

    try {
      _logger.i('Exporting analytics data to PDF: ${dataTypes.join(',')}');
      
      final queryParams = <String, dynamic>{
        'days_back': daysBack,
        'data_types': dataTypes.join(','),
        'include_charts': includeCharts,
      };
      
      // Add date range if provided
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      
      final response = await _apiService.get(
        '/analytics/export/pdf',
        queryParameters: queryParams,
      );

      if (response['success'] == true && response['data'] is Map<String, dynamic>) {
        _logger.i('PDF export completed successfully');
        return Map<String, dynamic>.from(response['data']);
      } else {
        _logger.w('PDF export failed: ${response['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      _logger.e('Error exporting PDF: $e');
      return null;
    }
  }

  /// Clear analytics cache (useful when user data changes significantly)
  Future<void> clearAnalyticsCache() async {
    try {
      await _cacheService.remove('analytics_dashboard');
      await _cacheService.remove('value_insights');
      await _cacheService.remove('activity_trends');
      await _cacheService.remove('streak_analytics');
      await _cacheService.remove('predictions');
      await _cacheService.remove('value_breakdown');
      
      _logger.i('Analytics cache cleared');
    } catch (e) {
      _logger.e('Error clearing analytics cache: $e');
    }
  }

  /// Get analytics summary for quick overview (suitable for home screen widgets)
  Future<Map<String, dynamic>?> getAnalyticsSummary() async {
    if (!hasPremiumAccess) return null;

    try {
      final dashboard = await getAnalyticsDashboard(daysBack: 7, analyticsType: 'daily');
      if (dashboard == null) return null;

      return {
        'total_activities': dashboard.overview.totalActivities,
        'consistency_percentage': dashboard.overview.consistencyPercentage,
        'active_days': dashboard.overview.activeDays,
        'avg_daily_activities': dashboard.overview.avgDailyActivities,
        'top_value': dashboard.valueBreakdown.isNotEmpty 
            ? dashboard.valueBreakdown.first.valueName 
            : null,
        'trend_direction': dashboard.predictions.trendDirection,
      };
    } catch (e) {
      _logger.e('Error getting analytics summary: $e');
      return null;
    }
  }

  /// Show premium upgrade prompt for analytics features
  void showPremiumUpgradePrompt() {
    _logger.i('Premium upgrade required for analytics features');
    // This would typically show a dialog or navigate to subscription screen
    // Implementation depends on the app's navigation/dialog system
  }
}