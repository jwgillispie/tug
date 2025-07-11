// lib/services/social_notification_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/notification_models.dart';
import '../config/env_confg.dart';

class SocialNotificationService {
  final Dio _dio;
  final Logger _logger = Logger();
  
  // Stream controller for real-time notification updates
  final StreamController<NotificationSummary> _notificationController = 
      StreamController<NotificationSummary>.broadcast();
  
  Stream<NotificationSummary> get notificationStream => _notificationController.stream;
  
  // Cache for notification summary
  NotificationSummary? _cachedSummary;
  Timer? _pollTimer;
  
  SocialNotificationService() : _dio = Dio() {
    _dio.options.baseUrl = EnvConfig.apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 3;
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = firebase_auth.FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken(true);
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            _logger.w('SocialNotificationService: No Firebase user found');
          }
        } catch (e) {
          _logger.e('SocialNotificationService: Error getting Firebase auth token: $e');
        }
        handler.next(options);
      },
    ));
  }

  void startPolling({Duration interval = const Duration(minutes: 1)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => getNotificationSummary());
  }

  void stopPolling() {
    _pollTimer?.cancel();
  }

  void dispose() {
    _pollTimer?.cancel();
    _notificationController.close();
  }

  Future<NotificationSummary> getNotificationSummary({bool forceRefresh = false}) async {
    try {
      _logger.i('SocialNotificationService: Getting notification summary');
      
      final response = await _dio.get(
        '/api/v1/notifications/summary',
        queryParameters: forceRefresh ? {'timestamp': DateTime.now().millisecondsSinceEpoch} : null,
      );
      
      if (response.statusCode == 200) {
        final summary = NotificationSummary.fromJson(response.data);
        _cachedSummary = summary;
        
        // Emit to stream for real-time updates
        _notificationController.add(summary);
        
        return summary;
      } else {
        throw Exception('Failed to get notification summary: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialNotificationService: DioException getting notification summary: ${e.message}');
      
      // Return cached summary if available
      if (_cachedSummary != null) {
        return _cachedSummary!;
      }
      
      // Return empty summary as fallback
      final emptySummary = NotificationSummary(
        unreadCount: 0,
        totalCount: 0,
        latestNotifications: [],
      );
      _notificationController.add(emptySummary);
      return emptySummary;
    } catch (e) {
      _logger.e('SocialNotificationService: Error getting notification summary: $e');
      
      // Return cached summary if available
      if (_cachedSummary != null) {
        return _cachedSummary!;
      }
      
      // Return empty summary as fallback
      final emptySummary = NotificationSummary(
        unreadCount: 0,
        totalCount: 0,
        latestNotifications: [],
      );
      _notificationController.add(emptySummary);
      return emptySummary;
    }
  }

  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    int skip = 0,
    bool unreadOnly = false,
  }) async {
    try {
      _logger.i('SocialNotificationService: Getting notifications (limit: $limit, skip: $skip, unreadOnly: $unreadOnly)');
      
      final response = await _dio.get(
        '/api/v1/notifications',
        queryParameters: {
          'limit': limit,
          'skip': skip,
          'unread_only': unreadOnly,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['notifications'] ?? [];
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialNotificationService: DioException getting notifications: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialNotificationService: Error getting notifications: $e');
      throw Exception('Failed to get notifications: $e');
    }
  }

  Future<void> markNotificationsAsRead(List<String> notificationIds) async {
    try {
      _logger.i('SocialNotificationService: Marking ${notificationIds.length} notifications as read');
      
      final request = MarkNotificationReadRequest(notificationIds: notificationIds);
      final response = await _dio.post(
        '/api/v1/notifications/mark-read',
        data: request.toJson(),
      );
      
      if (response.statusCode == 200) {
        _logger.i('SocialNotificationService: Notifications marked as read successfully');
        
        // Refresh summary after marking as read
        await getNotificationSummary(forceRefresh: true);
      } else {
        throw Exception('Failed to mark notifications as read: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialNotificationService: DioException marking notifications as read: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialNotificationService: Error marking notifications as read: $e');
      throw Exception('Failed to mark notifications as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _logger.i('SocialNotificationService: Marking all notifications as read');
      
      final response = await _dio.post('/api/v1/notifications/mark-all-read');
      
      if (response.statusCode == 200) {
        _logger.i('SocialNotificationService: All notifications marked as read successfully');
        
        // Refresh summary after marking all as read
        await getNotificationSummary(forceRefresh: true);
      } else {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.e('SocialNotificationService: DioException marking all notifications as read: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      _logger.e('SocialNotificationService: Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Helper method to get notification icon based on type
  static String getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return '💬';
      case NotificationType.friendRequest:
        return '👥';
      case NotificationType.friendAccepted:
        return '🤝';
      case NotificationType.postMention:
        return '📢';
      case NotificationType.achievement:
        return '🏆';
      case NotificationType.milestone:
        return '🎯';
    }
  }
}