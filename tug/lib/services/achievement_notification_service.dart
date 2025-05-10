// lib/services/achievement_notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tug/models/achievement_model.dart';
import 'package:tug/services/achievement_service.dart';
import 'package:tug/widgets/achievements/achievement_notification.dart';

/// Service to check for and show achievement notifications
class AchievementNotificationService {
  final AchievementService _achievementService;
  
  // Singleton instance
  static final AchievementNotificationService _instance =
      AchievementNotificationService._internal();

  // Factory constructor to return the singleton instance
  factory AchievementNotificationService({
    AchievementService? achievementService,
  }) {
    if (achievementService != null) {
      // We can't modify the final field directly, so we'll have to ignore
      // any passed service in a singleton pattern
      debugPrint('Note: Singleton pattern prevents changing achievement service');
    }
    return _instance;
  }

  // Private constructor
  AchievementNotificationService._internal()
      : _achievementService = AchievementService();
  
  // Current notification being shown
  OverlayEntry? _currentNotification;
  
  // Queue of achievements to show
  final List<AchievementModel> _achievementQueue = [];
  
  // Completer for checking if achievements are shown
  Completer<void>? _checkCompleter;
  
  /// Check for new achievements and show notifications
  Future<void> checkForAchievements(BuildContext context) async {
    // If already checking, return the existing completer
    if (_checkCompleter != null && !_checkCompleter!.isCompleted) {
      return _checkCompleter!.future;
    }
    
    _checkCompleter = Completer<void>();
    
    try {
      // Check for new achievements
      final newAchievements = await _achievementService.checkForNewAchievements();
      
      if (newAchievements.isNotEmpty) {
        debugPrint('New achievements unlocked: ${newAchievements.length}');
        
        // Add to queue
        _achievementQueue.addAll(newAchievements);
        
        // Show notifications if not already showing
        if (_currentNotification == null) {
          _showNextNotification(context);
        }
      }
      
      _checkCompleter?.complete();
    } catch (e) {
      debugPrint('Error checking for achievements: $e');
      _checkCompleter?.completeError(e);
    }
    
    return _checkCompleter!.future;
  }
  
  /// Show the next achievement notification from the queue
  void _showNextNotification(BuildContext context) {
    if (_achievementQueue.isEmpty) {
      return;
    }
    
    // Get the next achievement
    final achievement = _achievementQueue.removeAt(0);
    
    // Create overlay entry for the notification
    final overlay = Overlay.of(context);
    _currentNotification = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: AchievementNotification(
            achievement: achievement,
            onDismiss: () {
              _removeCurrentNotification();
              // Show next notification if any
              if (_achievementQueue.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  _showNextNotification(context);
                });
              }
            },
            onTap: () {
              _removeCurrentNotification();
              // Navigate to achievements screen
              Navigator.of(context).pushNamed('/achievements');
            },
          ),
        ),
      ),
    );
    
    // Insert the overlay entry
    overlay.insert(_currentNotification!);
    
    // Play sound or haptic feedback if needed
    // HapticFeedback.mediumImpact();
  }
  
  /// Remove the current notification
  void _removeCurrentNotification() {
    _currentNotification?.remove();
    _currentNotification = null;
  }
  
  /// Clear all pending notifications
  void clearNotifications() {
    _removeCurrentNotification();
    _achievementQueue.clear();
  }
}