// lib/models/indulgence_model.dart
import 'package:equatable/equatable.dart';

class IndulgenceModel extends Equatable {
  final String? id;
  final String viceId;
  final String userId;
  final DateTime date;
  final int? duration; // minutes spent, optional
  final String notes;
  final int severityAtTime; // severity level when indulgence occurred
  final List<String> triggers; // what triggered this indulgence
  final int emotionalState; // 1-10 scale before indulgence
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IndulgenceModel({
    this.id,
    required this.viceId,
    required this.userId,
    required this.date,
    this.duration,
    this.notes = '',
    required this.severityAtTime,
    this.triggers = const [],
    this.emotionalState = 5,
    this.createdAt,
    this.updatedAt,
  });

  IndulgenceModel copyWith({
    String? id,
    String? viceId,
    String? userId,
    DateTime? date,
    int? duration,
    String? notes,
    int? severityAtTime,
    List<String>? triggers,
    int? emotionalState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IndulgenceModel(
      id: id ?? this.id,
      viceId: viceId ?? this.viceId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      severityAtTime: severityAtTime ?? this.severityAtTime,
      triggers: triggers ?? this.triggers,
      emotionalState: emotionalState ?? this.emotionalState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vice_id': viceId,
      'user_id': userId,
      'date': date.toIso8601String(),
      'duration': duration,
      'notes': notes,
      'severity_at_time': severityAtTime,
      'triggers': triggers,
      'emotional_state': emotionalState,
    };
  }

  factory IndulgenceModel.fromJson(Map<String, dynamic> json) {
    return IndulgenceModel(
      id: json['id'],
      viceId: json['vice_id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      duration: json['duration'],
      notes: json['notes'] ?? '',
      severityAtTime: json['severity_at_time'],
      triggers: json['triggers'] != null 
          ? List<String>.from(json['triggers']) 
          : const [],
      emotionalState: json['emotional_state'] ?? 5,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Helper methods

  /// Get time of day when indulgence occurred
  String get timeOfDay {
    final hour = date.hour;
    if (hour < 6) return 'Late Night';
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  /// Get emotional state description
  String get emotionalStateDescription {
    if (emotionalState <= 2) return 'Very Low';
    if (emotionalState <= 4) return 'Low';
    if (emotionalState <= 6) return 'Neutral';
    if (emotionalState <= 8) return 'Good';
    return 'Very Good';
  }

  /// Check if this was a high-risk indulgence
  bool get isHighRisk => severityAtTime >= 4 || emotionalState <= 3;

  /// Get formatted duration string
  String get formattedDuration {
    if (duration == null) return 'Not tracked';
    if (duration! < 60) return '${duration}m';
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  List<Object?> get props => [
    id,
    viceId,
    userId,
    date,
    duration,
    notes,
    severityAtTime,
    triggers,
    emotionalState,
    createdAt,
    updatedAt,
  ];
}