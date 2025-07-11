// lib/models/notification_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'notification_models.g.dart';

enum NotificationType {
  @JsonValue('comment')
  comment,
  @JsonValue('friend_request')
  friendRequest,
  @JsonValue('friend_accepted')
  friendAccepted,
  @JsonValue('post_mention')
  postMention,
  @JsonValue('achievement')
  achievement,
  @JsonValue('milestone')
  milestone,
}

@JsonSerializable()
class NotificationModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  @JsonKey(name: 'related_id')
  final String? relatedId; // Post ID, comment ID, friend request ID, etc.
  @JsonKey(name: 'related_user_id')
  final String? relatedUserId; // User who triggered the notification
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // User info for display
  @JsonKey(name: 'related_username')
  final String? relatedUsername;
  @JsonKey(name: 'related_display_name')
  final String? relatedDisplayName;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedUserId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.relatedUsername,
    this.relatedDisplayName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  String get timeAgoText {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String get displayName => relatedDisplayName ?? relatedUsername ?? 'Someone';
}

@JsonSerializable()
class NotificationSummary {
  @JsonKey(name: 'unread_count')
  final int unreadCount;
  @JsonKey(name: 'total_count')
  final int totalCount;
  @JsonKey(name: 'latest_notifications')
  final List<NotificationModel> latestNotifications;

  NotificationSummary({
    required this.unreadCount,
    required this.totalCount,
    required this.latestNotifications,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) =>
      _$NotificationSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSummaryToJson(this);
}

@JsonSerializable()
class MarkNotificationReadRequest {
  @JsonKey(name: 'notification_ids')
  final List<String> notificationIds;

  MarkNotificationReadRequest({required this.notificationIds});

  factory MarkNotificationReadRequest.fromJson(Map<String, dynamic> json) =>
      _$MarkNotificationReadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MarkNotificationReadRequestToJson(this);
}