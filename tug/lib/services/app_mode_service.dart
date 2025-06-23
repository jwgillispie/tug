// lib/services/app_mode_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { valuesMode, vicesMode }

class AppModeService {
  static final AppModeService _instance = AppModeService._internal();
  factory AppModeService() => _instance;
  AppModeService._internal();

  static const String _modeKey = 'app_mode';
  
  AppMode _currentMode = AppMode.valuesMode;
  final StreamController<AppMode> _modeController = StreamController<AppMode>.broadcast();

  /// Current app mode
  AppMode get currentMode => _currentMode;

  /// Stream to listen for mode changes
  Stream<AppMode> get modeStream => _modeController.stream;

  /// Check if currently in values mode
  bool get isValuesMode => _currentMode == AppMode.valuesMode;

  /// Check if currently in vices mode
  bool get isVicesMode => _currentMode == AppMode.vicesMode;

  /// Initialize the service and load saved mode preference
  Future<void> initialize() async {
    await _loadSavedMode();
  }

  /// Toggle between values and vices mode
  Future<void> toggleMode() async {
    _currentMode = _currentMode == AppMode.valuesMode ? AppMode.vicesMode : AppMode.valuesMode;
    await _saveMode();
    _modeController.add(_currentMode);
  }

  /// Set specific mode
  Future<void> setMode(AppMode mode) async {
    if (_currentMode != mode) {
      _currentMode = mode;
      await _saveMode();
      _modeController.add(_currentMode);
    }
  }

  /// Switch to values mode
  Future<void> switchToValuesMode() async {
    await setMode(AppMode.valuesMode);
  }

  /// Switch to vices mode
  Future<void> switchToVicesMode() async {
    await setMode(AppMode.vicesMode);
  }

  /// Load saved mode from SharedPreferences
  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_modeKey);
      
      if (savedMode != null) {
        _currentMode = savedMode == 'valuesMode' 
            ? AppMode.valuesMode 
            : AppMode.vicesMode;
      }
      
      // Notify listeners of initial mode
      _modeController.add(_currentMode);
    } catch (e) {
      // If loading fails, default to values mode
      _currentMode = AppMode.valuesMode;
      _modeController.add(_currentMode);
    }
  }

  /// Save current mode to SharedPreferences
  Future<void> _saveMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = _currentMode.toString().split('.').last;
      await prefs.setString(_modeKey, modeString);
    } catch (e) {
      // Handle save error silently
    }
  }

  /// Get mode-specific app title
  String get appTitle {
    switch (_currentMode) {
      case AppMode.valuesMode:
        return 'viceless';
      case AppMode.vicesMode:
        return 'viceless';
    }
  }

  /// Get mode-specific subtitle
  String get modeSubtitle {
    switch (_currentMode) {
      case AppMode.valuesMode:
        return 'track your values';
      case AppMode.vicesMode:
        return 'overcome your vices';
    }
  }

  /// Get mode-specific primary action text
  String get primaryActionText {
    switch (_currentMode) {
      case AppMode.valuesMode:
        return 'log activity';
      case AppMode.vicesMode:
        return 'record indulgence';
    }
  }

  /// Get mode-specific positive action text
  String get positiveActionText {
    switch (_currentMode) {
      case AppMode.valuesMode:
        return 'build streak';
      case AppMode.vicesMode:
        return 'stay clean';
    }
  }

  /// Get mode-specific dashboard greeting
  String get dashboardGreeting {
    final hour = DateTime.now().hour;
    String timeGreeting;
    
    if (hour < 12) {
      timeGreeting = 'good morning';
    } else if (hour < 17) {
      timeGreeting = 'good afternoon';
    } else {
      timeGreeting = 'good evening';
    }

    switch (_currentMode) {
      case AppMode.valuesMode:
        return '$timeGreeting, let\'s align with your values';
      case AppMode.vicesMode:
        return '$timeGreeting, stay strong today';
    }
  }

  /// Get mode-specific empty state message
  String get emptyStateMessage {
    switch (_currentMode) {
      case AppMode.valuesMode:
        return 'add your first value to start tracking';
      case AppMode.vicesMode:
        return 'define a vice to begin your journey';
    }
  }

  /// Get mode-specific streak message
  String getStreakMessage(int days) {
    switch (_currentMode) {
      case AppMode.valuesMode:
        return days == 1 ? '$days day streak' : '$days days streak';
      case AppMode.vicesMode:
        return days == 1 ? '$days day clean' : '$days days clean';
    }
  }

  /// Dispose the service
  void dispose() {
    _modeController.close();
  }
}