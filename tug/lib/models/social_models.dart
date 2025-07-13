// lib/models/social_models.dart
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_models.g.dart';

// Friendship Models
enum FriendshipStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('blocked')
  blocked,
}

@JsonSerializable()
class FriendshipModel {
  final String id;
  @JsonKey(name: 'requester_id')
  final String requesterId;
  @JsonKey(name: 'addressee_id')
  final String addresseeId;
  final FriendshipStatus status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'friend_username')
  final String? friendUsername;
  @JsonKey(name: 'friend_display_name')
  final String? friendDisplayName;

  FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.friendUsername,
    this.friendDisplayName,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) =>
      _$FriendshipModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendshipModelToJson(this);
}

@JsonSerializable()
class UserSearchResult {
  final String id;
  final String username;
  @JsonKey(name: 'display_name')
  final String? displayName;
  @JsonKey(name: 'friendship_status')
  final String? friendshipStatus;

  UserSearchResult({
    required this.id,
    required this.username,
    this.displayName,
    this.friendshipStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) =>
      _$UserSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$UserSearchResultToJson(this);
}

// Social Post Models
enum PostType {
  @JsonValue('activity_update')
  activityUpdate,
  @JsonValue('vice_progress')
  viceProgress,
  @JsonValue('vice_indulgence')
  viceIndulgence,
  @JsonValue('achievement')
  achievement,
  @JsonValue('general')
  general,
}

@JsonSerializable()
class SocialPostModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String content;
  @JsonKey(name: 'post_type')
  final PostType postType;
  @JsonKey(name: 'activity_id')
  final String? activityId;
  @JsonKey(name: 'vice_id')
  final String? viceId;
  @JsonKey(name: 'achievement_id')
  final String? achievementId;
  @JsonKey(name: 'comments_count')
  final int commentsCount;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // User info for display
  final String? username;
  @JsonKey(name: 'user_display_name')
  final String? userDisplayName;
  
  // Value info for activity posts
  @JsonKey(name: 'value_name')
  final String? valueName;
  @JsonKey(name: 'value_color')
  final String? valueColor;
  @JsonKey(name: 'activity_name')
  final String? activityName;
  @JsonKey(name: 'activity_duration')
  final int? activityDuration;
  @JsonKey(name: 'activity_notes')
  final String? activityNotes;

  SocialPostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.postType,
    this.activityId,
    this.viceId,
    this.achievementId,
    required this.commentsCount,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.userDisplayName,
    this.valueName,
    this.valueColor,
    this.activityName,
    this.activityDuration,
    this.activityNotes,
  });

  factory SocialPostModel.fromJson(Map<String, dynamic> json) =>
      _$SocialPostModelFromJson(json);

  Map<String, dynamic> toJson() => _$SocialPostModelToJson(this);

  // Helper methods
  String get displayName => userDisplayName ?? username ?? 'Unknown User';
  
  String get formattedDuration {
    if (activityDuration == null || activityDuration == 0) return '';
    final hours = activityDuration! ~/ 60;
    final minutes = activityDuration! % 60;
    if (hours > 0) {
      return minutes > 0 ? '+${hours}h ${minutes}m' : '+${hours}h';
    } else {
      return '+${minutes}m';
    }
  }
  
  bool get hasValueInfo => valueName != null && valueColor != null;
  
  Color? get valueColorObject {
    if (valueColor == null) return null;
    try {
      return Color(int.parse(valueColor!.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return null;
    }
  }
  
  String get timeAgoText {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }
}

@JsonSerializable()
class CommentModel {
  final String id;
  @JsonKey(name: 'post_id')
  final String postId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // User info for display
  final String? username;
  @JsonKey(name: 'user_display_name')
  final String? userDisplayName;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.username,
    this.userDisplayName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);

  String get displayName => userDisplayName ?? username ?? 'Unknown User';
  
  String get timeAgoText {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Request/Response DTOs
@JsonSerializable()
class CreatePostRequest {
  final String content;
  @JsonKey(name: 'post_type')
  final PostType postType;
  @JsonKey(name: 'activity_id')
  final String? activityId;
  @JsonKey(name: 'vice_id')
  final String? viceId;
  @JsonKey(name: 'achievement_id')
  final String? achievementId;
  @JsonKey(name: 'is_public')
  final bool isPublic;

  CreatePostRequest({
    required this.content,
    this.postType = PostType.general,
    this.activityId,
    this.viceId,
    this.achievementId,
    this.isPublic = true,
  });

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}

@JsonSerializable()
class CreateCommentRequest {
  final String content;

  CreateCommentRequest({required this.content});

  factory CreateCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCommentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCommentRequestToJson(this);
}

@JsonSerializable()
class FriendRequestCreate {
  @JsonKey(name: 'addressee_id')
  final String addresseeId;

  FriendRequestCreate({required this.addresseeId});

  factory FriendRequestCreate.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestCreateFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRequestCreateToJson(this);
}