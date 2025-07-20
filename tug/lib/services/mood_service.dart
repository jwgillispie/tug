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

  /// Create mood entries for existing activities (retroactive mood assignment)
  Future<void> createRetroactiveMoodEntries(List<Map<String, dynamic>> activityMoodPairs) async {
    print('DEBUG: Creating ${activityMoodPairs.length} retroactive mood entries');
    
    for (final pair in activityMoodPairs) {
      try {
        final activityId = pair['activityId'] as String;
        final moodType = pair['moodType'] as MoodType;
        final recordedAt = pair['recordedAt'] as DateTime;
        
        final moodEntry = MoodEntry(
          moodType: moodType,
          positivityScore: _getMoodPositivityScore(moodType),
          recordedAt: recordedAt,
          activityId: activityId,
        );
        
        await createMoodEntry(moodEntry);
        print('DEBUG: Created mood entry for activity $activityId: ${moodType.name}');
      } catch (e) {
        print('DEBUG: Failed to create mood entry for ${pair['activityId']}: $e');
      }
    }
  }
  
  int _getMoodPositivityScore(MoodType mood) {
    switch (mood) {
      case MoodType.ecstatic: return 10;
      case MoodType.joyful: return 9;
      case MoodType.confident: return 8;
      case MoodType.content: return 7;
      case MoodType.focused: return 6;
      case MoodType.neutral: return 5;
      case MoodType.restless: return 4;
      case MoodType.tired: return 3;
      case MoodType.frustrated: return 2;
      case MoodType.anxious: return 2;
      case MoodType.sad: return 1;
      case MoodType.overwhelmed: return 1;
      case MoodType.angry: return 1;
      case MoodType.defeated: return 0;
      case MoodType.depressed: return 0;
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