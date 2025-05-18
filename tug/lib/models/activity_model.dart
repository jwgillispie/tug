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
  final String? importSource; // Source of imported activity (e.g., "strava")

  const ActivityModel({
    this.id,
    required this.name,
    required this.valueId,
    required this.duration,
    required this.date,
    this.notes,
    this.createdAt,
    this.importSource,
  });

  ActivityModel copyWith({
    String? id,
    String? name,
    String? valueId,
    int? duration,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    String? importSource,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      valueId: valueId ?? this.valueId,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      importSource: importSource ?? this.importSource,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value_id': valueId,
      'duration': duration,
      'date': date.toIso8601String(),
      'notes': notes,
      'import_source': importSource,
    };
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      name: json['name'],
      valueId: json['value_id'],
      duration: json['duration'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      importSource: json['import_source'],
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
    createdAt,
    importSource
  ];
}