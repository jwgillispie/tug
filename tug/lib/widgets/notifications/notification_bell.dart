// lib/widgets/notifications/notification_bell.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/social_notification_service.dart';
import '../../models/notification_models.dart';
import '../../utils/theme/colors.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../services/app_mode_service.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final SocialNotificationService _notificationService = SocialNotificationService();
  final AppModeService _appModeService = AppModeService();
  NotificationSummary? _notificationSummary;
  AppMode _currentMode = AppMode.valuesMode;
  StreamSubscription<NotificationSummary>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMode();
    _loadNotifications();
    _startListening();
  }

  void _initializeMode() async {
    await _appModeService.initialize();
    if (mounted) {
      setState(() {
        _currentMode = _appModeService.currentMode;
      });
    }
  }

  void _startListening() {
    // Listen to notification stream for real-time updates
    _notificationSubscription = _notificationService.notificationStream.listen((summary) {
      if (mounted) {
        setState(() {
          _notificationSummary = summary;
        });
      }
    });

    // Start polling for updates
    _notificationService.startPolling();
  }

  Future<void> _loadNotifications() async {
    try {
      final summary = await _notificationService.getNotificationSummary();
      if (mounted) {
        setState(() {
          _notificationSummary = summary;
        });
      }
    } catch (e) {
      // Fail silently, will show bell without badge
    }
  }

  void _onNotificationTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = _currentMode == AppMode.vicesMode;
    final unreadCount = _notificationSummary?.unreadCount ?? 0;

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: isViceMode
                ? (isDarkMode ? TugColors.viceGreenLight : TugColors.viceGreen)
                : (isDarkMode ? TugColors.primaryPurpleLight : TugColors.primaryPurple),
          ),
          onPressed: _onNotificationTap,
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkMode ? TugColors.darkBackground : TugColors.lightBackground,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}