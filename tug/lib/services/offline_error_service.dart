// lib/services/offline_error_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_service.dart';

class OfflineAction {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final int maxRetries;

  OfflineAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
    };
  }

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
      maxRetries: json['maxRetries'] ?? 3,
    );
  }

  OfflineAction copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    int? maxRetries,
  }) {
    return OfflineAction(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }
}

class OfflineErrorService {
  static final OfflineErrorService _instance = OfflineErrorService._internal();
  factory OfflineErrorService() => _instance;
  OfflineErrorService._internal();

  final String _offlineActionsKey = 'offline_actions';
  final String _offlineErrorsKey = 'offline_errors';
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _isOnline = true;
  Timer? _syncTimer;
  final Duration _syncInterval = const Duration(minutes: 5);

  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  final StreamController<OfflineAction> _actionController = StreamController<OfflineAction>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<OfflineAction> get actionStream => _actionController.stream;

  bool get isOnline => _isOnline;
  bool get hasOfflineActions => _getOfflineActions().isNotEmpty;
  bool get hasOfflineErrors => _getOfflineErrors().isNotEmpty;

  /// Initialize the offline error service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Check initial connectivity
      await _checkConnectivity();
      
      // Start periodic sync
      _startSyncTimer();
      
      _initialized = true;
      
      if (kDebugMode) {
        print('OfflineErrorService initialized - Online: $_isOnline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize OfflineErrorService: $e');
      }
    }
  }

  /// Update connectivity status
  void updateConnectivity(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(_isOnline);
      
      if (kDebugMode) {
        print('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      }
      
      if (_isOnline) {
        // When back online, try to sync immediately
        _syncOfflineData();
      }
    }
  }

  /// Queue an action for offline execution
  Future<void> queueOfflineAction({
    required String type,
    required Map<String, dynamic> data,
    int maxRetries = 3,
  }) async {
    if (!_initialized) return;

    final action = OfflineAction(
      id: _generateActionId(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
      maxRetries: maxRetries,
    );

    await _saveOfflineAction(action);
    _actionController.add(action);

    if (kDebugMode) {
      print('Queued offline action: ${action.type} (${action.id})');
    }

    // If online, try to execute immediately
    if (_isOnline) {
      _syncOfflineData();
    }
  }

  /// Save an error for offline handling
  Future<void> saveOfflineError(AppError error) async {
    if (!_initialized) return;

    try {
      final errors = _getOfflineErrors();
      errors.add({
        'id': _generateErrorId(),
        'error': error.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only the last 50 errors
      if (errors.length > 50) {
        errors.removeAt(0);
      }

      await _prefs.setString(_offlineErrorsKey, jsonEncode(errors));

      if (kDebugMode) {
        print('Saved offline error: ${error.type.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save offline error: $e');
      }
    }
  }

  /// Get offline actions
  List<OfflineAction> getOfflineActions() {
    return _getOfflineActions();
  }

  /// Get offline errors
  List<Map<String, dynamic>> getOfflineErrors() {
    return _getOfflineErrors();
  }

  /// Manually trigger sync
  Future<void> syncNow() async {
    if (_isOnline) {
      await _syncOfflineData();
    }
  }

  /// Clear all offline data
  Future<void> clearOfflineData() async {
    await _prefs.remove(_offlineActionsKey);
    await _prefs.remove(_offlineErrorsKey);
    
    if (kDebugMode) {
      print('Cleared all offline data');
    }
  }

  /// Get offline data summary
  Map<String, dynamic> getOfflineDataSummary() {
    final actions = _getOfflineActions();
    final errors = _getOfflineErrors();
    
    return {
      'isOnline': _isOnline,
      'actionsCount': actions.length,
      'errorsCount': errors.length,
      'oldestAction': actions.isNotEmpty ? actions.first.timestamp.toIso8601String() : null,
      'newestAction': actions.isNotEmpty ? actions.last.timestamp.toIso8601String() : null,
    };
  }

  List<OfflineAction> _getOfflineActions() {
    try {
      final actionsJson = _prefs.getString(_offlineActionsKey);
      if (actionsJson == null) return [];
      
      final List<dynamic> actionsList = jsonDecode(actionsJson);
      return actionsList.map((json) => OfflineAction.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load offline actions: $e');
      }
      return [];
    }
  }

  List<Map<String, dynamic>> _getOfflineErrors() {
    try {
      final errorsJson = _prefs.getString(_offlineErrorsKey);
      if (errorsJson == null) return [];
      
      return List<Map<String, dynamic>>.from(jsonDecode(errorsJson));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load offline errors: $e');
      }
      return [];
    }
  }

  Future<void> _saveOfflineAction(OfflineAction action) async {
    try {
      final actions = _getOfflineActions();
      actions.add(action);
      
      // Keep only the last 100 actions
      if (actions.length > 100) {
        actions.removeAt(0);
      }
      
      final actionsJson = actions.map((a) => a.toJson()).toList();
      await _prefs.setString(_offlineActionsKey, jsonEncode(actionsJson));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save offline action: $e');
      }
    }
  }

  Future<void> _updateOfflineAction(OfflineAction updatedAction) async {
    try {
      final actions = _getOfflineActions();
      final index = actions.indexWhere((a) => a.id == updatedAction.id);
      
      if (index != -1) {
        actions[index] = updatedAction;
        final actionsJson = actions.map((a) => a.toJson()).toList();
        await _prefs.setString(_offlineActionsKey, jsonEncode(actionsJson));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update offline action: $e');
      }
    }
  }

  Future<void> _removeOfflineAction(String actionId) async {
    try {
      final actions = _getOfflineActions();
      actions.removeWhere((a) => a.id == actionId);
      
      final actionsJson = actions.map((a) => a.toJson()).toList();
      await _prefs.setString(_offlineActionsKey, jsonEncode(actionsJson));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to remove offline action: $e');
      }
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check - in a real app, you might use connectivity_plus
      // For now, assume online unless explicitly told otherwise
      _isOnline = true;
    } catch (e) {
      _isOnline = false;
    }
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnline) {
        _syncOfflineData();
      }
    });
  }

  Future<void> _syncOfflineData() async {
    if (!_isOnline || !_initialized) return;

    final actions = _getOfflineActions();
    if (actions.isEmpty) return;

    if (kDebugMode) {
      print('Syncing ${actions.length} offline actions...');
    }

    final List<OfflineAction> successfulActions = [];
    final List<OfflineAction> failedActions = [];

    for (final action in actions) {
      try {
        final success = await _executeOfflineAction(action);
        
        if (success) {
          successfulActions.add(action);
        } else {
          final updatedAction = action.copyWith(
            retryCount: action.retryCount + 1,
          );
          
          if (updatedAction.retryCount >= updatedAction.maxRetries) {
            // Max retries reached, remove the action
            successfulActions.add(action);
            
            // Save as failed error
            await saveOfflineError(AppError.network(
              message: 'Failed to sync action after ${action.maxRetries} retries',
              userMessage: 'Some changes could not be synced. Please try again.',
              context: {
                'actionType': action.type,
                'actionId': action.id,
                'retryCount': action.retryCount,
              },
            ));
          } else {
            failedActions.add(updatedAction);
          }
        }
      } catch (e) {
        failedActions.add(action.copyWith(
          retryCount: action.retryCount + 1,
        ));
        
        if (kDebugMode) {
          print('Failed to sync action ${action.id}: $e');
        }
      }
    }

    // Remove successful actions
    for (final action in successfulActions) {
      await _removeOfflineAction(action.id);
    }

    // Update failed actions
    for (final action in failedActions) {
      await _updateOfflineAction(action);
    }

    if (kDebugMode) {
      print('Sync completed: ${successfulActions.length} successful, ${failedActions.length} failed');
    }
  }

  Future<bool> _executeOfflineAction(OfflineAction action) async {
    try {
      // Mock implementation - in a real app, this would call actual services
      if (kDebugMode) {
        print('Executing offline action: ${action.type}');
      }
      
      // Simulate network call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock success/failure based on action type
      switch (action.type) {
        case 'create_activity':
        case 'update_activity':
        case 'delete_activity':
        case 'update_user_profile':
          return true; // These usually succeed
        default:
          return DateTime.now().millisecond % 2 == 0; // Random success/failure
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error executing offline action: $e');
      }
      return false;
    }
  }

  String _generateActionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'action_$timestamp';
  }

  String _generateErrorId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'error_$timestamp';
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivityController.close();
    _actionController.close();
  }
}