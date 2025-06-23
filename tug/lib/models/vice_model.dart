// lib/models/vice_model.dart
import 'package:equatable/equatable.dart';

class ViceModel extends Equatable {
  final String? id;
  final String name;
  final int severity; // 1-5 scale instead of importance
  final String description;
  final String color;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int currentStreak; // days without engaging in vice
  final int longestStreak; // longest clean streak
  final DateTime? lastIndulgenceDate;
  final int totalIndulgences; // count of times engaged
  final List<DateTime> indulgenceDates;

  const ViceModel({
    this.id,
    required this.name,
    required this.severity,
    this.description = '',
    required this.color,
    this.active = true,
    this.createdAt,
    this.updatedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastIndulgenceDate,
    this.totalIndulgences = 0,
    this.indulgenceDates = const [],
  });

  ViceModel copyWith({
    String? id,
    String? name,
    int? severity,
    String? description,
    String? color,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastIndulgenceDate,
    int? totalIndulgences,
    List<DateTime>? indulgenceDates,
  }) {
    return ViceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      color: color ?? this.color,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastIndulgenceDate: lastIndulgenceDate ?? this.lastIndulgenceDate,
      totalIndulgences: totalIndulgences ?? this.totalIndulgences,
      indulgenceDates: indulgenceDates ?? this.indulgenceDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity,
      'description': description,
      'color': color,
      'active': active,
    };
  }

  factory ViceModel.fromJson(Map<String, dynamic> json) {
    return ViceModel(
      id: json['id'],
      name: json['name'],
      severity: json['severity'],
      description: json['description'] ?? '',
      color: json['color'],
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastIndulgenceDate: json['last_indulgence_date'] != null
          ? DateTime.parse(json['last_indulgence_date'])
          : null,
      totalIndulgences: json['total_indulgences'] ?? 0,
      indulgenceDates: json['indulgence_dates'] != null
          ? (json['indulgence_dates'] as List).map((date) => DateTime.parse(date)).toList()
          : const [],
    );
  }

  // Helper methods for vice-specific functionality
  
  /// Calculate days since last indulgence
  int get daysSinceLastIndulgence {
    if (lastIndulgenceDate == null) return currentStreak;
    final now = DateTime.now();
    final difference = now.difference(lastIndulgenceDate!);
    return difference.inDays;
  }

  /// Check if currently on a clean streak
  bool get isOnCleanStreak => currentStreak > 0;

  /// Get severity level description
  String get severityDescription {
    switch (severity) {
      case 1:
        return 'Mild';
      case 2:
        return 'Moderate';
      case 3:
        return 'Concerning';
      case 4:
        return 'Severe';
      case 5:
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  /// Get appropriate color based on current streak
  String get streakStatusColor {
    if (currentStreak >= 30) return '#4CAF50'; // Green for 30+ days
    if (currentStreak >= 7) return '#FF9800'; // Orange for 7-29 days
    if (currentStreak >= 1) return '#FFC107'; // Yellow for 1-6 days
    return '#F44336'; // Red for 0 days
  }

  @override
  List<Object?> get props => [
    id, 
    name, 
    severity, 
    description, 
    color, 
    active, 
    createdAt, 
    updatedAt,
    currentStreak,
    longestStreak,
    lastIndulgenceDate,
    totalIndulgences,
    indulgenceDates
  ];
}