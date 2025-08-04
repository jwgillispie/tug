// lib/services/balance_insights_service.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../models/indulgence_model.dart';
import '../models/value_model.dart';
import '../models/vice_model.dart';
import '../models/mood_model.dart';

class BalanceInsightsService {
  /// Generate AI-powered insights about user's vice/value balance patterns
  static List<BalanceInsight> generateInsights({
    required List<ActivityModel> activities,
    required List<IndulgenceModel> indulgences,
    required List<ValueModel> values,
    required List<ViceModel> vices,
    required List<MoodEntry> moodEntries,
    int daysToAnalyze = 30,
  }) {
    final insights = <BalanceInsight>[];
    
    // Analyze activity patterns
    insights.addAll(_analyzeMoodCorrelations(activities, indulgences, moodEntries));
    insights.addAll(_analyzeTimePatterns(activities, indulgences));
    insights.addAll(_analyzeStreakPatterns(activities, indulgences));
    insights.addAll(_analyzeBalanceEfficiency(activities, indulgences, values, vices));
    insights.addAll(_generatePredictiveInsights(activities, indulgences));
    insights.addAll(_analyzeWeeklyPatterns(activities, indulgences));
    
    // Sort by priority and impact
    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    
    return insights.take(5).toList(); // Return top 5 insights
  }

  static List<BalanceInsight> _analyzeMoodCorrelations(
    List<ActivityModel> activities,
    List<IndulgenceModel> indulgences,
    List<MoodEntry> moodEntries,
  ) {
    final insights = <BalanceInsight>[];
    
    if (moodEntries.isEmpty) return insights;
    
    // Calculate average mood on activity days vs indulgence days
    final activityDays = activities.map((a) => a.date.day).toSet();
    final indulgenceDays = indulgences.map((i) => i.date.day).toSet();
    
    final moodOnActivityDays = moodEntries
        .where((m) => activityDays.contains(m.recordedAt.day))
        .map((m) => m.positivityScore)
        .toList();
    
    final moodOnIndulgenceDays = moodEntries
        .where((m) => indulgenceDays.contains(m.recordedAt.day))
        .map((m) => m.positivityScore)
        .toList();
    
    if (moodOnActivityDays.isNotEmpty && moodOnIndulgenceDays.isNotEmpty) {
      final avgActivityMood = moodOnActivityDays.reduce((a, b) => a + b) / moodOnActivityDays.length;
      final avgIndulgenceMood = moodOnIndulgenceDays.reduce((a, b) => a + b) / moodOnIndulgenceDays.length;
      
      final moodDifference = avgActivityMood - avgIndulgenceMood;
      
      if (moodDifference > 1.0) {
        insights.add(BalanceInsight(
          title: "values boost your mood",
          description: "your mood improves by ${(moodDifference * 20).toInt()}% on days when you complete activities vs days with indulgences.",
          type: BalanceInsightType.moodCorrelation,
          priority: BalanceInsightPriority.high,
          icon: "😊",
          actionSuggestion: "try doing a quick value activity when you feel down to naturally boost your mood.",
        ));
      }
    }
    
    return insights;
  }

  static List<BalanceInsight> _analyzeTimePatterns(
    List<ActivityModel> activities,
    List<IndulgenceModel> indulgences,
  ) {
    final insights = <BalanceInsight>[];
    
    // Analyze best time of day for activities
    final morningActivities = activities.where((a) => a.date.hour < 12).length;
    final afternoonActivities = activities.where((a) => a.date.hour >= 12 && a.date.hour < 18).length;
    final eveningActivities = activities.where((a) => a.date.hour >= 18).length;
    
    final morningIndulgences = indulgences.where((i) => i.date.hour < 12).length;
    final eveningIndulgences = indulgences.where((i) => i.date.hour >= 18).length;
    
    if (morningActivities > afternoonActivities && morningActivities > eveningActivities) {
      insights.add(BalanceInsight(
        title: "you're a morning champion",
        description: "${(morningActivities / activities.length * 100).toInt()}% of your activities happen in the morning. Your values side is strongest early in the day.",
        type: BalanceInsightType.timePattern,
        priority: BalanceInsightPriority.medium,
        icon: "🌅",
        actionSuggestion: "schedule your most important value activities for morning when your willpower is highest.",
      ));
    }
    
    if (eveningIndulgences > morningIndulgences && indulgences.isNotEmpty) {
      insights.add(BalanceInsight(
        title: "evening vice vulnerability",
        description: "${(eveningIndulgences / indulgences.length * 100).toInt()}% of indulgences happen in the evening. Plan evening value activities to stay balanced.",
        type: BalanceInsightType.timePattern,
        priority: BalanceInsightPriority.high,
        icon: "🌙",
        actionSuggestion: "create an evening routine with value activities to prevent indulgences.",
      ));
    }
    
    return insights;
  }

  static List<BalanceInsight> _analyzeStreakPatterns(
    List<ActivityModel> activities,
    List<IndulgenceModel> indulgences,
  ) {
    final insights = <BalanceInsight>[];
    
    // Calculate current streaks
    final sortedActivities = activities..sort((a, b) => b.date.compareTo(a.date));
    final sortedIndulgences = indulgences..sort((a, b) => b.date.compareTo(a.date));
    
    int valueStreak = 0;
    final now = DateTime.now();
    
    // Calculate value streak
    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final hasActivityOnDay = sortedActivities.any((a) => 
          a.date.year == checkDate.year &&
          a.date.month == checkDate.month &&
          a.date.day == checkDate.day);
      
      if (hasActivityOnDay) {
        valueStreak++;
      } else {
        break;
      }
    }
    
    if (valueStreak >= 7) {
      insights.add(BalanceInsight(
        title: "epic value streak! 🔥",
        description: "you're on a $valueStreak-day value streak! this is your best streak in the last 30 days.",
        type: BalanceInsightType.streak,
        priority: BalanceInsightPriority.high,
        icon: "🔥",
        actionSuggestion: "keep the momentum going! even a small activity today will extend your streak.",
      ));
    }
    
    return insights;
  }

  static List<BalanceInsight> _analyzeBalanceEfficiency(
    List<ActivityModel> activities,
    List<IndulgenceModel> indulgences,
    List<ValueModel> values,
    List<ViceModel> vices,
  ) {
    final insights = <BalanceInsight>[];
    
    if (activities.isEmpty && indulgences.isEmpty) return insights;
    
    // Calculate balance ratio
    final totalActivities = activities.length;
    final totalIndulgences = indulgences.length;
    final balanceRatio = totalActivities / math.max(1, totalIndulgences);
    
    if (balanceRatio >= 3.0) {
      insights.add(BalanceInsight(
        title: "balance master 🏆",
        description: "your value activities outnumber indulgences 3:1! you're winning the tug of war convincingly.",
        type: BalanceInsightType.balance,
        priority: BalanceInsightPriority.high,
        icon: "🏆",
        actionSuggestion: "you're in the optimal zone. consider helping others achieve this balance!",
      ));
    } else if (balanceRatio < 0.5) {
      insights.add(BalanceInsight(
        title: "rebalance opportunity",
        description: "your indulgences are outpacing value activities 2:1. time to tip the scales!",
        type: BalanceInsightType.balance,
        priority: BalanceInsightPriority.high,
        icon: "⚖️",
        actionSuggestion: "focus on 2-3 quick value activities today to start rebalancing the tug of war.",
      ));
    }
    
    return insights;
  }

  static List<BalanceInsight> _generatePredictiveInsights(
    List<ActivityModel> activities,
    List<IndulgenceModel> indulgences,
  ) {
    final insights = <BalanceInsight>[];
    
    // Analyze patterns for predictions
    final now = DateTime.now();
    final lastWeekActivities = activities.where((a) => 
        now.difference(a.date).inDays <= 7).length;
    final previousWeekActivities = activities.where((a) => 
        now.difference(a.date).inDays > 7 && now.difference(a.date).inDays <= 14).length;
    
    if (lastWeekActivities > previousWeekActivities * 1.5) {
      insights.add(BalanceInsight(
        title: "momentum building 📈",
        description: "your activity rate increased by ${((lastWeekActivities / math.max(1, previousWeekActivities) - 1) * 100).toInt()}% this week! you're gaining momentum.",
        type: BalanceInsightType.prediction,
        priority: BalanceInsightPriority.medium,
        icon: "📈",
        actionSuggestion: "ride this wave! set a slightly higher goal this week to keep the momentum going.",
      ));
    }
    
    return insights;
  }

  static List<BalanceInsight> _analyzeWeeklyPatterns(
    List<ActivityModel> activities,
    List<IndulgenceModel> indulgences,
  ) {
    final insights = <BalanceInsight>[];
    
    // Analyze day of week patterns
    final weekdayActivities = activities.where((a) => a.date.weekday <= 5).length;
    final weekendActivities = activities.where((a) => a.date.weekday > 5).length;
    
    final weekdayIndulgences = indulgences.where((i) => i.date.weekday <= 5).length;
    final weekendIndulgences = indulgences.where((i) => i.date.weekday > 5).length;
    
    if (weekendIndulgences > weekdayIndulgences && indulgences.isNotEmpty) {
      insights.add(BalanceInsight(
        title: "weekend vice pattern",
        description: "${(weekendIndulgences / indulgences.length * 100).toInt()}% of your indulgences happen on weekends. Plan weekend value activities!",
        type: BalanceInsightType.weeklyPattern,
        priority: BalanceInsightPriority.medium,
        icon: "🏖️",
        actionSuggestion: "create a weekend routine with planned value activities to maintain balance.",
      ));
    }
    
    if (weekdayActivities > weekendActivities && activities.isNotEmpty) {
      insights.add(BalanceInsight(
        title: "weekday warrior 💼",
        description: "you complete ${(weekdayActivities / activities.length * 100).toInt()}% of activities on weekdays. great work-life integration!",
        type: BalanceInsightType.weeklyPattern,
        priority: BalanceInsightPriority.low,
        icon: "💼",
        actionSuggestion: "try adding one weekend value activity to maintain momentum through the week.",
      ));
    }
    
    return insights;
  }
}

class BalanceInsight {
  final String title;
  final String description;
  final BalanceInsightType type;
  final BalanceInsightPriority priority;
  final String icon;
  final String actionSuggestion;
  
  const BalanceInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.icon,
    required this.actionSuggestion,
  });
}

enum BalanceInsightType {
  moodCorrelation,
  timePattern,
  streak,
  balance,
  prediction,
  weeklyPattern,
}

enum BalanceInsightPriority {
  low,
  medium,
  high,
}

extension BalanceInsightPriorityExtension on BalanceInsightPriority {
  String get displayName {
    switch (this) {
      case BalanceInsightPriority.low:
        return 'nice to know';
      case BalanceInsightPriority.medium:
        return 'worth noting';
      case BalanceInsightPriority.high:
        return 'key insight';
    }
  }
  
  Color get color {
    switch (this) {
      case BalanceInsightPriority.low:
        return Colors.blue;
      case BalanceInsightPriority.medium:
        return Colors.orange;
      case BalanceInsightPriority.high:
        return Colors.red;
    }
  }
}