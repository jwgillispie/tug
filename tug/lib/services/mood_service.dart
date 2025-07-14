// lib/services/mood_service.dart
import 'package:tug/models/mood_model.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/services/service_locator.dart';

class MoodService {
  final ApiService _apiService = ServiceLocator.apiService;

  /// Get all available mood options from the backend
  Future<List<MoodOption>> getMoodOptions() async {
    try {
      final response = await _apiService.get('/api/v1/mood/options');
      
      if (response['moods'] != null) {
        return (response['moods'] as List)
            .map((mood) => MoodOption.fromJson(mood))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to fetch mood options: $e');
    }
  }

  /// Create a new mood entry
  Future<MoodEntry> createMoodEntry(MoodEntry moodEntry) async {
    try {
      final response = await _apiService.post(
        '/api/v1/mood/entries',
        data: moodEntry.toJson(),
      );
      
      return MoodEntry.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create mood entry: $e');
    }
  }

  /// Get mood entries for the current user
  Future<List<MoodEntry>> getMoodEntries({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int skip = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'skip': skip,
      };
      
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      final response = await _apiService.get(
        '/api/v1/mood/entries',
        queryParameters: queryParams,
      );
      
      return (response as List)
          .map((entry) => MoodEntry.fromJson(entry))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch mood entries: $e');
    }
  }

  /// Get mood chart data for overlay on activity charts
  Future<MoodChartData> getMoodChartData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      
      final response = await _apiService.get(
        '/api/v1/mood/chart-data',
        queryParameters: queryParams,
      );
      
      return MoodChartData.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch mood chart data: $e');
    }
  }
}