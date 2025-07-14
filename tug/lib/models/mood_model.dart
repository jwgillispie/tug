// lib/models/mood_model.dart

/// Enum for mood types
enum MoodType {
  ecstatic,
  joyful,
  confident,
  content,
  focused,
  neutral,
  restless,
  tired,
  frustrated,
  anxious,
  sad,
  overwhelmed,
  angry,
  defeated,
  depressed,
}

/// Extension for MoodType to handle string conversion
extension MoodTypeExtension on MoodType {
  String get value {
    switch (this) {
      case MoodType.ecstatic:
        return 'ecstatic';
      case MoodType.joyful:
        return 'joyful';
      case MoodType.confident:
        return 'confident';
      case MoodType.content:
        return 'content';
      case MoodType.focused:
        return 'focused';
      case MoodType.neutral:
        return 'neutral';
      case MoodType.restless:
        return 'restless';
      case MoodType.tired:
        return 'tired';
      case MoodType.frustrated:
        return 'frustrated';
      case MoodType.anxious:
        return 'anxious';
      case MoodType.sad:
        return 'sad';
      case MoodType.overwhelmed:
        return 'overwhelmed';
      case MoodType.angry:
        return 'angry';
      case MoodType.defeated:
        return 'defeated';
      case MoodType.depressed:
        return 'depressed';
    }
  }

  static MoodType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ecstatic':
        return MoodType.ecstatic;
      case 'joyful':
        return MoodType.joyful;
      case 'confident':
        return MoodType.confident;
      case 'content':
        return MoodType.content;
      case 'focused':
        return MoodType.focused;
      case 'neutral':
        return MoodType.neutral;
      case 'restless':
        return MoodType.restless;
      case 'tired':
        return MoodType.tired;
      case 'frustrated':
        return MoodType.frustrated;
      case 'anxious':
        return MoodType.anxious;
      case 'sad':
        return MoodType.sad;
      case 'overwhelmed':
        return MoodType.overwhelmed;
      case 'angry':
        return MoodType.angry;
      case 'defeated':
        return MoodType.defeated;
      case 'depressed':
        return MoodType.depressed;
      default:
        return MoodType.neutral;
    }
  }
}

/// Mood option model for displaying available moods
class MoodOption {
  final MoodType moodType;
  final String displayName;
  final int positivityScore;
  final String description;
  final String emoji;

  const MoodOption({
    required this.moodType,
    required this.displayName,
    required this.positivityScore,
    required this.description,
    required this.emoji,
  });

  factory MoodOption.fromJson(Map<String, dynamic> json) {
    return MoodOption(
      moodType: MoodTypeExtension.fromString(json['mood_type'] ?? ''),
      displayName: json['display_name'] ?? '',
      positivityScore: json['positivity_score'] ?? 0,
      description: json['description'] ?? '',
      emoji: json['emoji'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood_type': moodType.value,
      'display_name': displayName,
      'positivity_score': positivityScore,
      'description': description,
      'emoji': emoji,
    };
  }
}

/// Mood entry model for recording mood entries
class MoodEntry {
  final String? id;
  final String? userId;
  final MoodType moodType;
  final int positivityScore;
  final String? notes;
  final String? activityId;
  final String? indulgenceId;
  final DateTime recordedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MoodEntry({
    this.id,
    this.userId,
    required this.moodType,
    required this.positivityScore,
    this.notes,
    this.activityId,
    this.indulgenceId,
    required this.recordedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      userId: json['user_id'],
      moodType: MoodTypeExtension.fromString(json['mood_type'] ?? ''),
      positivityScore: json['positivity_score'] ?? 0,
      notes: json['notes'],
      activityId: json['activity_id'],
      indulgenceId: json['indulgence_id'],
      recordedAt: DateTime.parse(json['recorded_at']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mood_type': moodType.value,
      'positivity_score': positivityScore,
      'notes': notes,
      'activity_id': activityId,
      'indulgence_id': indulgenceId,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Mood chart data point for overlaying on activity charts
class MoodDataPoint {
  final DateTime date;
  final double moodScore;
  final MoodType moodType;
  final String? activityName;
  final String? valueName;

  const MoodDataPoint({
    required this.date,
    required this.moodScore,
    required this.moodType,
    this.activityName,
    this.valueName,
  });

  factory MoodDataPoint.fromJson(Map<String, dynamic> json) {
    return MoodDataPoint(
      date: DateTime.parse(json['date']),
      moodScore: (json['mood_score'] ?? 0).toDouble(),
      moodType: MoodTypeExtension.fromString(json['mood_type'] ?? ''),
      activityName: json['activity_name'],
      valueName: json['value_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mood_score': moodScore,
      'mood_type': moodType.value,
      'activity_name': activityName,
      'value_name': valueName,
    };
  }
}

/// Mood chart data response
class MoodChartData {
  final List<MoodDataPoint> moodData;
  final Map<String, dynamic> dateRange;
  final double averageMood;

  const MoodChartData({
    required this.moodData,
    required this.dateRange,
    required this.averageMood,
  });

  factory MoodChartData.fromJson(Map<String, dynamic> json) {
    return MoodChartData(
      moodData: (json['mood_data'] as List<dynamic>?)
          ?.map((item) => MoodDataPoint.fromJson(item))
          .toList() ?? [],
      dateRange: json['date_range'] ?? {},
      averageMood: (json['average_mood'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood_data': moodData.map((item) => item.toJson()).toList(),
      'date_range': dateRange,
      'average_mood': averageMood,
    };
  }
}