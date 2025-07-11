// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/social_notification_service.dart';
import '../../services/app_mode_service.dart';
import '../../models/notification_models.dart';
import '../../utils/theme/colors.dart';
import '../../utils/quantum_effects.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SocialNotificationService _notificationService = SocialNotificationService();
  final AppModeService _appModeService = AppModeService();
  final ScrollController _scrollController = ScrollController();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMoreNotifications = true;
  AppMode _currentMode = AppMode.valuesMode;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    if (mounted) {
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (refresh) {
        _notifications.clear();
        _hasMoreNotifications = true;
      }
    });

    try {
      final notifications = await _notificationService.getNotifications(
        limit: 20,
        skip: refresh ? 0 : _notifications.length,
      );
      
      setState(() {
        if (refresh) {
          _notifications = notifications;
        } else {
          _notifications.addAll(notifications);
        }
        _hasMoreNotifications = notifications.length == 20;
        _isLoading = false;
      });

      // Mark all as read when user opens notifications
      if (refresh && _notifications.isNotEmpty) {
        final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
        if (unreadNotifications.isNotEmpty) {
          final unreadIds = unreadNotifications.map((n) => n.id).toList();
          _notificationService.markNotificationsAsRead(unreadIds);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (!_hasMoreNotifications || _isLoading) return;
    await _loadNotifications();
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications(refresh: true);
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = NotificationModel(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            type: _notifications[i].type,
            title: _notifications[i].title,
            message: _notifications[i].message,
            relatedId: _notifications[i].relatedId,
            relatedUserId: _notifications[i].relatedUserId,
            isRead: true,
            createdAt: _notifications[i].createdAt,
            updatedAt: _notifications[i].updatedAt,
            relatedUsername: _notifications[i].relatedUsername,
            relatedDisplayName: _notifications[i].relatedDisplayName,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: TugColors.error,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.comment:
        if (notification.relatedId != null) {
          // Navigate to post with comments
          context.go('/social/post/${notification.relatedId}');
        }
        break;
      case NotificationType.friendRequest:
        context.go('/social/friends');
        break;
      case NotificationType.friendAccepted:
        if (notification.relatedUserId != null) {
          context.go('/user/${notification.relatedUserId}');
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;

    return Scaffold(
      backgroundColor: TugColors.getBackgroundColor(isDarkMode, isViceMode),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isViceMode
                  ? (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.viceGreenDark, TugColors.viceGreen]
                      : [TugColors.lightBackground, TugColors.viceGreen.withAlpha(20)])
                  : (isDarkMode 
                      ? [TugColors.darkBackground, TugColors.primaryPurpleDark, TugColors.primaryPurple]
                      : [TugColors.lightBackground, TugColors.primaryPurple.withAlpha(20)]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: QuantumEffects.holographicShimmer(
          child: QuantumEffects.gradientText(
            'notifications',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            colors: isViceMode
                ? (isDarkMode ? [TugColors.viceGreen, TugColors.viceGreenLight, TugColors.viceGreenDark] : [TugColors.viceGreen, TugColors.viceGreenLight])
                : (isDarkMode ? [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark] : [TugColors.primaryPurple, TugColors.primaryPurpleLight]),
          ),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: Icon(
                Icons.done_all,
                color: isViceMode
                    ? (isDarkMode ? TugColors.viceGreenLight : TugColors.viceGreen)
                    : (isDarkMode ? TugColors.primaryPurpleLight : TugColors.primaryPurple),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: TugColors.getPrimaryColor(isViceMode),
        child: _buildNotificationsList(isDarkMode, isViceMode),
      ),
    );
  }

  Widget _buildNotificationsList(bool isDarkMode, bool isViceMode) {
    if (_isLoading && _notifications.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: TugColors.getPrimaryColor(isViceMode),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
            ),
            const SizedBox(height: 16),
            Text(
              'no notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TugColors.getTextColor(isDarkMode, isViceMode),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'when friends interact with your posts or send friend requests, they\'ll appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _notifications.length + (_hasMoreNotifications && _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _notifications.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: TugColors.getPrimaryColor(isViceMode),
              ),
            ),
          );
        }

        final notification = _notifications[index];
        return _buildNotificationItem(notification, isDarkMode, isViceMode);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, bool isDarkMode, bool isViceMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead 
                  ? TugColors.getSurfaceColor(isDarkMode, isViceMode)
                  : TugColors.getSurfaceColor(isDarkMode, isViceMode).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: notification.isRead 
                  ? null 
                  : Border.all(
                      color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.3),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      SocialNotificationService.getNotificationIcon(notification.type),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: TugColors.getTextColor(isDarkMode, isViceMode),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.timeAgoText,
                        style: TextStyle(
                          fontSize: 12,
                          color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: TugColors.getPrimaryColor(isViceMode),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}