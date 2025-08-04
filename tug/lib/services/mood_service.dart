// lib/services/mood_service.dart
import 'package:tug/models/mood_model.dart';
import 'package:tug/services/api_service.dart';
import 'package:tug/services/service_locator.dart';

class MoodService {
  final ApiService _apiService = ServiceLocator.apiService;

  /// Get all available mood options from the backend or fallback to defaults
  Future<List<MoodOption>> getMoodOptions() async {
    try {
      final response = await _apiService.get('/api/v1/mood/options');
      
      if (response['moods'] != null) {
        return (response['moods'] as List)
            .map((mood) => MoodOption.fromJson(mood))
            .toList();
      }
      
      return _getDefaultMoodOptions();
    } catch (e) {
      // If API is unavailable, return default mood options
      print('Mood API unavailable, using default options: $e');
      return _getDefaultMoodOptions();
    }
  }

  /// Get default mood options when API is unavailable
  List<MoodOption> _getDefaultMoodOptions() {
    return [
      const MoodOption(
        moodType: MoodType.ecstatic,
        displayName: "Ecstatic",
        positivityScore: 10,
        description: "Peak positive energy, euphoric",
        emoji: "🤩",
      ),
      const MoodOption(
        moodType: MoodType.joyful,
        displayName: "Joyful",
        positivityScore: 9,
        description: "Very happy, delighted",
        emoji: "😊",
      ),
      const MoodOption(
        moodType: MoodType.confident,
        displayName: "Confident",
        positivityScore: 8,
        description: "Self-assured, empowered",
        emoji: "💪",
      ),
      const MoodOption(
        moodType: MoodType.content,
        displayName: "Content",
        positivityScore: 7,
        description: "Satisfied, peaceful",
        emoji: "😌",
      ),
      const MoodOption(
        moodType: MoodType.focused,
        displayName: "Focused",
        positivityScore: 6,
        description: "Clear-minded, determined",
        emoji: "🎯",
      ),
      const MoodOption(
        moodType: MoodType.neutral,
        displayName: "Neutral",
        positivityScore: 5,
        description: "Balanced, neither positive nor negative",
        emoji: "😐",
      ),
      const MoodOption(
        moodType: MoodType.restless,
        displayName: "Restless",
        positivityScore: 4,
        description: "Agitated, unsettled",
        emoji: "😣",
      ),
      const MoodOption(
        moodType: MoodType.tired,
        displayName: "Tired",
        positivityScore: 3,
        description: "Fatigued, low energy",
        emoji: "😴",
      ),
      const MoodOption(
        moodType: MoodType.frustrated,
        displayName: "Frustrated",
        positivityScore: 2,
        description: "Annoyed, blocked",
        emoji: "😤",
      ),
      const MoodOption(
        moodType: MoodType.anxious,
        displayName: "Anxious",
        positivityScore: 2,
        description: "Worried, stressed",
        emoji: "😰",
      ),
      const MoodOption(
        moodType: MoodType.sad,
        displayName: "Sad",
        positivityScore: 1,
        description: "Down, melancholy",
        emoji: "😢",
      ),
      const MoodOption(
        moodType: MoodType.overwhelmed,
        displayName: "Overwhelmed",
        positivityScore: 1,
        description: "Too much to handle",
        emoji: "😵",
      ),
      const MoodOption(
        moodType: MoodType.angry,
        displayName: "Angry",
        positivityScore: 1,
        description: "Mad, irritated",
        emoji: "😠",
      ),
      const MoodOption(
        moodType: MoodType.defeated,
        displayName: "Defeated",
        positivityScore: 0,
        description: "Hopeless, giving up",
        emoji: "😞",
      ),
      const MoodOption(
        moodType: MoodType.depressed,
        displayName: "Depressed",
        positivityScore: 0,
        description: "Very low, heavy sadness",
        emoji: "😔",
      ),
    ];
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