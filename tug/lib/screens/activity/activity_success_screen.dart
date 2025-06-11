// lib/screens/activity/activity_success_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tug/models/activity_model.dart';
import 'package:tug/services/achievement_notification_service.dart';
import 'package:tug/utils/theme/colors.dart';

class ActivitySuccessScreen extends StatefulWidget {
  final ActivityModel? activity;

  const ActivitySuccessScreen({
    super.key,
    this.activity,
  });

  @override
  State<ActivitySuccessScreen> createState() => _ActivitySuccessScreenState();
}

class _ActivitySuccessScreenState extends State<ActivitySuccessScreen> {
  final AchievementNotificationService _notificationService = AchievementNotificationService();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Check for achievements after activity is logged
    _checkForAchievements();
  }

  Future<void> _checkForAchievements() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // Wait a brief moment to let the user see the success screen
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Check for new achievements if we have context
      if (mounted) {
        await _notificationService.checkForAchievements(context);
      }
    } catch (e) {
      debugPrint('Error checking for achievements: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    
    return Scaffold(
      backgroundColor: TugColors.primaryPurple.withOpacity(0.1),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success animation (use a simple icon for now)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: TugColors.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: TugColors.success,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Success message
                const Text(
                  'Activity Logged Successfully!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Activity details if available
                if (activity != null) ...[
                  Text(
                    'You spent ${activity.duration} minutes on ${activity.name}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Achievement checking indicator
                if (_isChecking) ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Checking achievements...',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('add another'),
                      onPressed: () {
                        context.go('/activities/new');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TugColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      child: const Text('done'),
                      onPressed: () {
                        context.go('/activities');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}