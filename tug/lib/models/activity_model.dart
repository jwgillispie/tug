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
    // Create a UTC version of the date to ensure consistent timezone handling
    final dateUtc = DateTime.utc(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
    
    return {
      'name': name,
      'value_id': valueId,
      'duration': duration,
      'date': dateUtc.toIso8601String(), // Use UTC ISO format for API compatibility
      'notes': notes,
    };
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    // Parse dates and ensure they're in UTC format
    DateTime parseToUtc(String dateStr) {
      final parsed = DateTime.parse(dateStr);
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      );
    }
    
    return ActivityModel(
      id: json['id'],
      name: json['name'],
      valueId: json['value_id'],
      duration: json['duration'],
      date: parseToUtc(json['date']),
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? parseToUtc(json['created_at']) 
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