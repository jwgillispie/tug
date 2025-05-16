// lib/models/ranking_model.dart
import 'package:equatable/equatable.dart';

class UserRankingModel extends Equatable {
  final int? rank;
  final String userId;
  final String displayName;
  final int totalActivities;
  final int totalDuration;
  final int uniqueActivityDays;
  final double avgDurationPerActivity;
  final int streak;
  final String rankingType;
  final bool isCurrentUser;

  const UserRankingModel({
    this.rank,
    required this.userId,
    required this.displayName,
    required this.totalActivities,
    required this.totalDuration,
    required this.uniqueActivityDays,
    required this.avgDurationPerActivity,
    this.streak = 0,
    this.rankingType = 'activities',
    this.isCurrentUser = false,
  });

  UserRankingModel copyWith({
    int? rank,
    String? userId,
    String? displayName,
    int? totalActivities,
    int? totalDuration,
    int? uniqueActivityDays,
    double? avgDurationPerActivity,
    int? streak,
    String? rankingType,
    bool? isCurrentUser,
  }) {
    return UserRankingModel(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      totalActivities: totalActivities ?? this.totalActivities,
      totalDuration: totalDuration ?? this.totalDuration,
      uniqueActivityDays: uniqueActivityDays ?? this.uniqueActivityDays,
      avgDurationPerActivity: avgDurationPerActivity ?? this.avgDurationPerActivity,
      streak: streak ?? this.streak,
      rankingType: rankingType ?? this.rankingType,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  factory UserRankingModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return UserRankingModel(
      rank: json['rank'],
      userId: json['user_id'],
      displayName: json['display_name'] ?? 'Anonymous User',
      totalActivities: json['total_activities'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      uniqueActivityDays: json['unique_activity_days'] ?? 0,
      avgDurationPerActivity: json['avg_duration_per_activity']?.toDouble() ?? 0.0,
      streak: json['streak'] ?? 0,
      rankingType: json['ranking_type'] ?? 'activities',
      isCurrentUser: json['user_id'] == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'display_name': displayName,
      'total_activities': totalActivities,
      'total_duration': totalDuration,
      'unique_activity_days': uniqueActivityDays,
      'avg_duration_per_activity': avgDurationPerActivity,
      'streak': streak,
      'ranking_type': rankingType,
    };
  }

  @override
  List<Object?> get props => [
        rank,
        userId,
        displayName,
        totalActivities,
        totalDuration,
        uniqueActivityDays,
        avgDurationPerActivity,
        streak,
        rankingType,
        isCurrentUser,
      ];
}

class RankingsListModel extends Equatable {
  final List<UserRankingModel> rankings;
  final int? currentUserRank;
  final int periodDays;

  const RankingsListModel({
    required this.rankings,
    this.currentUserRank,
    required this.periodDays,
  });

  factory RankingsListModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return RankingsListModel(
      rankings: (json['rankings'] as List<dynamic>?)
              ?.map((e) => UserRankingModel.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
              .toList() ??
          [],
      currentUserRank: json['current_user_rank'],
      periodDays: json['period_days'] ?? 30,
    );
  }

  @override
  List<Object?> get props => [rankings, currentUserRank, periodDays];
}