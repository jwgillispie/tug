// lib/models/achievement_model.dart
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';

/// Types of achievements available in the app
enum AchievementType {
  streak,     // Based on consecutive activities
  balance,    // Based on balanced usage across values
  frequency,  // Based on total number of activities
  milestone,  // Based on total time spent
  special,    // Special one-off achievements
}

/// Model representing an achievement in the app
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final Color color;
  final int requiredValue;
  final bool isUnlocked;
  final double progress;
  final DateTime? unlockedAt;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.color,
    required this.requiredValue,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
  });

  /// Create a copy of this achievement with some fields replaced
  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    Color? color,
    int? requiredValue,
    bool? isUnlocked,
    double? progress,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      color: color ?? this.color,
      requiredValue: requiredValue ?? this.requiredValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// Create an achievement from JSON
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      type: AchievementType.values[json['type']],
      color: Color(json['color']),
      requiredValue: json['requiredValue'],
      isUnlocked: json['isUnlocked'] ?? false,
      progress: json['progress'] ?? 0.0,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt']) 
          : null,
    );
  }

  /// Convert achievement to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.index,
      'color': color.value,
      'requiredValue': requiredValue,
      'isUnlocked': isUnlocked,
      'progress': progress,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  /// Get list of predefined achievements
  static List<AchievementModel> getPredefinedAchievements() {
    return [
      // Streak achievements
      AchievementModel(
        id: 'streak_3',
        title: '3-Day Streak',
        description: 'Complete activities for the same value 3 days in a row',
        icon: '🔥',
        type: AchievementType.streak,
        color: TugColors.streakOrange,
        requiredValue: 3,
      ),
      AchievementModel(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Complete activities for the same value 7 days in a row',
        icon: '📅',
        type: AchievementType.streak,
        color: TugColors.streakOrange,
        requiredValue: 7,
      ),
      AchievementModel(
        id: 'streak_14',
        title: 'Fortnight Force',
        description: 'Complete activities for the same value 14 days in a row',
        icon: '🧠',
        type: AchievementType.streak,
        color: TugColors.streakOrange,
        requiredValue: 14,
      ),
      AchievementModel(
        id: 'streak_30',
        title: 'Monthly Master',
        description: 'Complete activities for the same value 30 days in a row',
        icon: '🏆',
        type: AchievementType.streak,
        color: TugColors.streakOrange,
        requiredValue: 30,
      ),
      
      // Balance achievements
      AchievementModel(
        id: 'balance_3',
        title: 'Balanced Beginner',
        description: 'Maintain a balanced distribution across your values for 3 days',
        icon: '⚖️',
        type: AchievementType.balance,
        color: TugColors.balanceBlue,
        requiredValue: 3,
      ),
      AchievementModel(
        id: 'balance_7',
        title: 'Harmony Keeper',
        description: 'Maintain a balanced distribution across your values for 7 days',
        icon: '☯️',
        type: AchievementType.balance,
        color: TugColors.balanceBlue,
        requiredValue: 7,
      ),
      AchievementModel(
        id: 'balance_30',
        title: 'Life Balancer',
        description: 'Maintain a balanced distribution across your values for 30 days',
        icon: '🧘',
        type: AchievementType.balance,
        color: TugColors.balanceBlue,
        requiredValue: 30,
      ),
      
      // Frequency achievements
      AchievementModel(
        id: 'frequency_10',
        title: 'Getting Started',
        description: 'Log 10 activities',
        icon: '🏁',
        type: AchievementType.frequency,
        color: TugColors.frequencyGreen,
        requiredValue: 10,
      ),
      AchievementModel(
        id: 'frequency_50',
        title: 'Regular Tracker',
        description: 'Log 50 activities',
        icon: '📝',
        type: AchievementType.frequency,
        color: TugColors.frequencyGreen,
        requiredValue: 50,
      ),
      AchievementModel(
        id: 'frequency_100',
        title: 'Century Club',
        description: 'Log 100 activities',
        icon: '💯',
        type: AchievementType.frequency,
        color: TugColors.frequencyGreen,
        requiredValue: 100,
      ),
      AchievementModel(
        id: 'frequency_365',
        title: 'Year of Growth',
        description: 'Log 365 activities',
        icon: '📊',
        type: AchievementType.frequency,
        color: TugColors.frequencyGreen,
        requiredValue: 365,
      ),
      
      // Milestone achievements
      AchievementModel(
        id: 'milestone_300',
        title: 'Time Investment',
        description: 'Spend 5 hours on value-aligned activities',
        icon: '⏱️',
        type: AchievementType.milestone,
        color: TugColors.milestoneRed,
        requiredValue: 300, // minutes
      ),
      AchievementModel(
        id: 'milestone_1200',
        title: 'Dedicated Day',
        description: 'Spend 20 hours on value-aligned activities',
        icon: '⌛',
        type: AchievementType.milestone,
        color: TugColors.milestoneRed,
        requiredValue: 1200, // minutes
      ),
      AchievementModel(
        id: 'milestone_3000',
        title: 'Value Maven',
        description: 'Spend 50 hours on value-aligned activities',
        icon: '🕰️',
        type: AchievementType.milestone,
        color: TugColors.milestoneRed,
        requiredValue: 3000, // minutes
      ),
      
      // Special achievements
      AchievementModel(
        id: 'special_balanced_all',
        title: 'Perfect Harmony',
        description: 'Log at least one activity for each of your values',
        icon: '🌈',
        type: AchievementType.special,
        color: TugColors.specialPurple,
        requiredValue: 1,
      ),
      AchievementModel(
        id: 'special_comeback',
        title: 'Comeback Kid',
        description: 'Return to logging activities after a 2-week break',
        icon: '🔄',
        type: AchievementType.special,
        color: TugColors.specialPurple,
        requiredValue: 1,
      ),
    ];
  }
}