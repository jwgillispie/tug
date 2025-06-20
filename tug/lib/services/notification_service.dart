// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'activity_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  late ActivityService _activityService;
  bool _initialized = false;

  // Notification IDs
  static const int _dailyReminderId = 0;
  static const int _testNotificationId = 1000;

  // SharedPreferences keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';

  // Notification response callback
  static void _onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    debugPrint('Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap here if needed
    // For basic implementation, we just log it
  }

  Future<void> initialize() async {
    if (_initialized) return;

    _activityService = ActivityService();
    
    // Initialize timezone data
    tz.initializeTimeZones();

    // Initialize the plugin
    const androidSettings = AndroidInitializationSettings('@drawable/app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
    _initialized = true;

    // Request permissions on first launch if notifications are enabled by default
    if (await getNotificationsEnabled()) {
      await requestPermissions();
      await scheduleDailyReminder();
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    final result = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return result ?? true;
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default to enabled
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (enabled) {
      await requestPermissions();
      await scheduleDailyReminder();
    } else {
      await cancelAllNotifications();
    }
  }

  Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_notificationHourKey) ?? 20; // Default to 8 PM
    final minute = prefs.getInt(_notificationMinuteKey) ?? 0; // Default to :00
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    debugPrint('Setting notification time - hour: ${time.hour}, minute: ${time.minute}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationHourKey, time.hour);
    await prefs.setInt(_notificationMinuteKey, time.minute);

    // Reschedule notification with new time if notifications are enabled
    if (await getNotificationsEnabled()) {
      await scheduleDailyReminder();
    }
  }

  Future<void> scheduleDailyReminder() async {
    if (!_initialized || kIsWeb) return;

    // Cancel existing notification first
    await _notifications.cancel(_dailyReminderId);

    // Check if notifications are enabled
    if (!(await getNotificationsEnabled())) return;

    // Schedule new notification for daily reminder
    await _notifications.zonedSchedule(
      _dailyReminderId,
      'Don\'t forget to log your activities!',
      'Take a moment to reflect on your day and log your activities',
      await _nextInstanceOfNotificationTime(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily reminders to log your activities',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<tz.TZDateTime> _nextInstanceOfNotificationTime() async {
    final notificationTime = await getNotificationTime();
    debugPrint('Retrieved notification time - hour: ${notificationTime.hour}, minute: ${notificationTime.minute}');
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, 
      now.year, 
      now.month, 
      now.day, 
      notificationTime.hour, 
      notificationTime.minute,
    );
    
    debugPrint('Scheduled date created: $scheduledDate (current time: $now)');
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('Date was in past, rescheduled for tomorrow: $scheduledDate');
    }
    
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized || kIsWeb) return;
    await _notifications.cancelAll();
  }

  Future<bool> shouldShowNotification() async {
    try {
      // Check if user has logged any activities today
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final activities = await _activityService.getActivities(
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Don't show notification if user has already logged activities today
      return activities.isEmpty;
    } catch (e) {
      debugPrint('Error checking activities for notification: $e');
      // Show notification by default if we can't check
      return true;
    }
  }

  Future<void> checkAndShowReminderIfNeeded() async {
    if (!_initialized || kIsWeb) return;
    
    // Check if notifications are enabled
    if (!(await getNotificationsEnabled())) return;

    // Check if we should show the notification
    if (await shouldShowNotification()) {
      await _showImmediateNotification();
    }
  }

  Future<void> _showImmediateNotification() async {
    await _notifications.show(
      _dailyReminderId + 1, // Use different ID for immediate notifications
      'Don\'t forget to log your activities!',
      'Take a moment to reflect on your day and log your activities',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily reminders to log your activities',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> scheduleOneTimeNotification(Duration delay) async {
    if (!_initialized || kIsWeb) return;

    // Cancel any existing test notification
    await _notifications.cancel(_testNotificationId);

    // Check if notifications are enabled
    if (!(await getNotificationsEnabled())) return;

    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);
    
    debugPrint('Scheduling one-time notification for: $scheduledTime (in ${delay.inMinutes} minutes)');

    await _notifications.zonedSchedule(
      _testNotificationId,
      'Test Notification',
      'This is your scheduled notification reminder!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily reminders to log your activities',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleNotificationForTime(TimeOfDay time) async {
    if (!_initialized || kIsWeb) return;

    // Cancel any existing test notification
    await _notifications.cancel(_testNotificationId);

    // Check if notifications are enabled
    if (!(await getNotificationsEnabled())) return;

    debugPrint('Input TimeOfDay - hour: ${time.hour}, minute: ${time.minute}');
    final now = tz.TZDateTime.now(tz.local);
    debugPrint('Current time: $now');
    
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    debugPrint('Created scheduled time: $scheduledTime');

    // If the time is in the past, schedule for today if less than 24 hours ago, otherwise tomorrow
    if (scheduledTime.isBefore(now)) {
      // If it's just a few minutes ago, schedule for right now + 1 minute to test
      final diffInMinutes = now.difference(scheduledTime).inMinutes;
      if (diffInMinutes < 60) {
        scheduledTime = now.add(const Duration(minutes: 1));
        debugPrint('Time was in the past by $diffInMinutes minutes, scheduling for 1 minute from now');
      } else {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        debugPrint('Time was more than 1 hour ago, scheduling for tomorrow');
      }
    }

    debugPrint('Final scheduled time: $scheduledTime');

    await _notifications.zonedSchedule(
      _testNotificationId,
      'Scheduled Notification',
      'This is your notification for ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily reminders to log your activities',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Debug method to test time conversion
  Future<void> debugTimeConversion(TimeOfDay time) async {
    debugPrint('=== DEBUG TIME CONVERSION ===');
    debugPrint('Input TimeOfDay: ${time.hour}:${time.minute}');
    debugPrint('TimeOfDay.hour (24-hour format): ${time.hour}');
    
    final now = tz.TZDateTime.now(tz.local);
    debugPrint('Current timezone: ${now.timeZoneName}');
    debugPrint('Current time: $now');
    
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    debugPrint('Scheduled time created: $scheduledTime');
    debugPrint('Scheduled hour: ${scheduledTime.hour}');
    debugPrint('Scheduled minute: ${scheduledTime.minute}');
    debugPrint('===============================');
  }

}