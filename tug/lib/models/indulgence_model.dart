// lib/models/indulgence_model.dart
import 'package:equatable/equatable.dart';

class IndulgenceModel extends Equatable {
  final String? id;
  final List<String> viceIds; // Changed from single viceId to list
  final String userId;
  final DateTime date;
  final int? duration; // minutes spent, optional
  final String notes;
  final int severityAtTime; // severity level when indulgence occurred
  final List<String> triggers; // what triggered this indulgence
  final int emotionalState; // 1-10 scale before indulgence
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isPublic;
  final bool notesPublic;

  const IndulgenceModel({
    this.id,
    required this.viceIds,
    required this.userId,
    required this.date,
    this.duration,
    this.notes = '',
    required this.severityAtTime,
    this.triggers = const [],
    this.emotionalState = 5,
    this.createdAt,
    this.updatedAt,
    this.isPublic = false, // Default indulgences to private for sensitivity
    this.notesPublic = false, // Default notes to private for privacy
  });

  IndulgenceModel copyWith({
    String? id,
    List<String>? viceIds,
    String? userId,
    DateTime? date,
    int? duration,
    String? notes,
    int? severityAtTime,
    List<String>? triggers,
    int? emotionalState,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    bool? notesPublic,
  }) {
    return IndulgenceModel(
      id: id ?? this.id,
      viceIds: viceIds ?? this.viceIds,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      severityAtTime: severityAtTime ?? this.severityAtTime,
      triggers: triggers ?? this.triggers,
      emotionalState: emotionalState ?? this.emotionalState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      notesPublic: notesPublic ?? this.notesPublic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vice_ids': viceIds,
      'user_id': userId,
      'date': date.toIso8601String(),
      'duration': duration,
      'notes': notes,
      'severity_at_time': severityAtTime,
      'triggers': triggers,
      'emotional_state': emotionalState,
      'is_public': isPublic,
      'notes_public': notesPublic,
    };
  }

  factory IndulgenceModel.fromJson(Map<String, dynamic> json) {
    return IndulgenceModel(
      id: json['id'],
      viceIds: json['vice_ids'] != null 
          ? List<String>.from(json['vice_ids'])
          : (json['vice_id'] != null ? [json['vice_id']] : []), // Backward compatibility
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
      isPublic: json['is_public'] ?? false, // Default indulgences to private
      notesPublic: json['notes_public'] ?? false, // Default notes to private
    );
  }

  // Helper methods for backward compatibility and ease of use
  
  /// Get primary vice ID (first in list, for backward compatibility)
  String? get primaryViceId => viceIds.isNotEmpty ? viceIds.first : null;
  
  /// Get secondary vice IDs (all except first)
  List<String> get secondaryViceIds => viceIds.length > 1 ? viceIds.skip(1).toList() : [];
  
  /// Check if indulgence has multiple vices
  bool get hasMultipleVices => viceIds.length > 1;

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
    viceIds,
    userId,
    date,
    duration,
    notes,
    severityAtTime,
    triggers,
    emotionalState,
    createdAt,
    updatedAt,
    isPublic,
    notesPublic,
  ];
}