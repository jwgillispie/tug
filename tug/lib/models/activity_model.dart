// lib/models/activity_model.dart
import 'package:equatable/equatable.dart';

class ActivityModel extends Equatable {
  final String? id;
  final String name;
  final List<String> valueIds; // Changed from single valueId to list
  final int duration;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;
  final bool isPublic;
  final bool notesPublic;

  const ActivityModel({
    this.id,
    required this.name,
    required this.valueIds,
    required this.duration,
    required this.date,
    this.notes,
    this.createdAt,
    this.isPublic = true, // Default to public for social sharing
    this.notesPublic = false, // Default notes to private for privacy
  });

  ActivityModel copyWith({
    String? id,
    String? name,
    List<String>? valueIds,
    int? duration,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    bool? isPublic,
    bool? notesPublic,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      valueIds: valueIds ?? this.valueIds,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      notesPublic: notesPublic ?? this.notesPublic,
    );
  }

  Map<String, dynamic> toJson() {
    // Send the date as-is to preserve local time context
    // The backend should handle timezone conversion if needed
    return {
      'name': name,
      'value_ids': valueIds,
      'duration': duration,
      'date': date.toIso8601String(), // Send local time to preserve user's intended date
      'notes': notes,
      'is_public': isPublic,
      'notes_public': notesPublic,
    };
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    // Parse dates more intelligently to preserve user's local context
    DateTime parseDate(String dateStr) {
      final parsed = DateTime.parse(dateStr);
      // If the date comes with timezone info, convert to local time
      // If it's UTC, convert to local; otherwise keep as-is
      if (parsed.isUtc) {
        return parsed.toLocal();
      }
      return parsed;
    }
    
    return ActivityModel(
      id: json['id'],
      name: json['name'],
      valueIds: json['value_ids'] != null 
          ? List<String>.from(json['value_ids'])
          : (json['value_id'] != null ? [json['value_id']] : []), // Backward compatibility
      duration: json['duration'],
      date: parseDate(json['date']),
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? parseDate(json['created_at']) 
          : null,
      isPublic: json['is_public'] ?? false, // Default old activities to private for safety
      notesPublic: json['notes_public'] ?? false, // Default notes to private
    );
  }

  // Helper methods for backward compatibility and ease of use
  
  /// Get primary value ID (first in list, for backward compatibility)
  String? get primaryValueId => valueIds.isNotEmpty ? valueIds.first : null;
  
  /// Get secondary value IDs (all except first)
  List<String> get secondaryValueIds => valueIds.length > 1 ? valueIds.skip(1).toList() : [];
  
  /// Check if activity has multiple values
  bool get hasMultipleValues => valueIds.length > 1;

  @override
  List<Object?> get props => [
    id, 
    name, 
    valueIds, 
    duration, 
    date, 
    notes, 
    createdAt,
    isPublic,
    notesPublic,
  ];
}