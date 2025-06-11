// lib/models/activity_model.dart
import 'package:equatable/equatable.dart';

class ActivityModel extends Equatable {
  final String? id;
  final String name;
  final String valueId;
  final int duration;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;

  const ActivityModel({
    this.id,
    required this.name,
    required this.valueId,
    required this.duration,
    required this.date,
    this.notes,
    this.createdAt,
  });

  ActivityModel copyWith({
    String? id,
    String? name,
    String? valueId,
    int? duration,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      valueId: valueId ?? this.valueId,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    // Send the date as-is to preserve local time context
    // The backend should handle timezone conversion if needed
    return {
      'name': name,
      'value_id': valueId,
      'duration': duration,
      'date': date.toIso8601String(), // Send local time to preserve user's intended date
      'notes': notes,
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
      valueId: json['value_id'],
      duration: json['duration'],
      date: parseDate(json['date']),
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? parseDate(json['created_at']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    name, 
    valueId, 
    duration, 
    date, 
    notes, 
    createdAt
  ];
}