// lib/services/crash_reporting_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_service.dart';

class CrashReport {
  final String id;
  final DateTime timestamp;
  final AppError error;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appInfo;
  final List<String> breadcrumbs;
  bool uploaded;

  CrashReport({
    required this.id,
    required this.timestamp,
    required this.error,
    required this.deviceInfo,
    required this.appInfo,
    required this.breadcrumbs,
    this.uploaded = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'error': error.toJson(),
      'deviceInfo': deviceInfo,
      'appInfo': appInfo,
      'breadcrumbs': breadcrumbs,
      'uploaded': uploaded,
    };
  }

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      error: AppError(
        message: json['error']['message'],
        userMessage: json['error']['userMessage'],
        type: ErrorType.values.firstWhere(
          (e) => e.name == json['error']['type'],
          orElse: () => ErrorType.unknown,
        ),
        severity: ErrorSeverity.values.firstWhere(
          (e) => e.name == json['error']['severity'],
          orElse: () => ErrorSeverity.medium,
        ),
        code: json['error']['code'],
        correlationId: json['error']['correlationId'],
        context: json['error']['context'],
      ),
      deviceInfo: json['deviceInfo'],
      appInfo: json['appInfo'],
      breadcrumbs: List<String>.from(json['breadcrumbs']),
      uploaded: json['uploaded'] ?? false,
    );
  }
}

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  final List<String> _breadcrumbs = [];
  final int _maxBreadcrumbs = 50;
  final String _crashReportsKey = 'crash_reports';
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  Map<String, dynamic>? _deviceInfo;
  Map<String, dynamic>? _appInfo;

  /// Initialize the crash reporting service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _collectDeviceInfo();
      await _collectAppInfo();
      
      // Set up error service integration
      ErrorService().addErrorReporter(_handleError);
      
      // Upload any pending crash reports
      unawaited(_uploadPendingReports());
      
      _initialized = true;
      _addBreadcrumb('CrashReportingService initialized');
    } catch (e) {
      developer.log('Failed to initialize CrashReportingService: $e');
    }
  }

  /// Add a breadcrumb for tracking user actions
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().toIso8601String();
    final breadcrumb = '$timestamp: $message';
    
    if (data != null && data.isNotEmpty) {
      final dataString = data.entries
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      _breadcrumbs.add('$breadcrumb [$dataString]');
    } else {
      _breadcrumbs.add(breadcrumb);
    }

    // Keep only the most recent breadcrumbs
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Handle errors from ErrorService
  void _handleError(AppError error) {
    if (!_initialized) return;

    // Only create crash reports for critical errors or crashes
    if (error.severity == ErrorSeverity.critical || error.type == ErrorType.crash) {
      _createCrashReport(error);
    } else {
      // For non-critical errors, just add a breadcrumb
      _addBreadcrumb('Error: ${error.type.name} - ${error.message}');
    }
  }

  /// Create a crash report
  void _createCrashReport(AppError error) {
    try {
      final crashReport = CrashReport(
        id: _generateReportId(),
        timestamp: DateTime.now(),
        error: error,
        deviceInfo: _deviceInfo ?? {},
        appInfo: _appInfo ?? {},
        breadcrumbs: List.from(_breadcrumbs),
      );

      _saveCrashReport(crashReport);
      _addBreadcrumb('Crash report created: ${crashReport.id}');
      
      // Attempt to upload immediately (in background)
      unawaited(_uploadCrashReport(crashReport));
    } catch (e) {
      developer.log('Failed to create crash report: $e');
    }
  }

  /// Save crash report to local storage
  void _saveCrashReport(CrashReport report) {
    try {
      final reports = _getStoredReports();
      reports.add(report);
      
      // Keep only the last 10 reports to avoid excessive storage
      if (reports.length > 10) {
        reports.removeAt(0);
      }
      
      final reportsJson = reports.map((r) => r.toJson()).toList();
      _prefs.setString(_crashReportsKey, jsonEncode(reportsJson));
    } catch (e) {
      developer.log('Failed to save crash report: $e');
    }
  }

  /// Get stored crash reports
  List<CrashReport> _getStoredReports() {
    try {
      final reportsJson = _prefs.getString(_crashReportsKey);
      if (reportsJson == null) return [];
      
      final List<dynamic> reportsList = jsonDecode(reportsJson);
      return reportsList.map((json) => CrashReport.fromJson(json)).toList();
    } catch (e) {
      developer.log('Failed to load crash reports: $e');
      return [];
    }
  }

  /// Upload crash report (mock implementation)
  Future<bool> _uploadCrashReport(CrashReport report) async {
    try {
      if (kDebugMode) {
        developer.log('Would upload crash report: ${report.id}');
        developer.log('Error: ${report.error.message}');
        developer.log('Stack trace: ${report.error.stackTrace}');
        return true;
      }

      // TODO: Implement actual crash reporting service integration
      // This could be Firebase Crashlytics, Sentry, Bugsnag, etc.
      
      // Simulate network call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mark as uploaded
      report.uploaded = true;
      _updateStoredReport(report);
      
      return true;
    } catch (e) {
      developer.log('Failed to upload crash report: $e');
      return false;
    }
  }

  /// Update stored report
  void _updateStoredReport(CrashReport updatedReport) {
    try {
      final reports = _getStoredReports();
      final index = reports.indexWhere((r) => r.id == updatedReport.id);
      
      if (index != -1) {
        reports[index] = updatedReport;
        final reportsJson = reports.map((r) => r.toJson()).toList();
        _prefs.setString(_crashReportsKey, jsonEncode(reportsJson));
      }
    } catch (e) {
      developer.log('Failed to update crash report: $e');
    }
  }

  /// Upload pending crash reports
  Future<void> _uploadPendingReports() async {
    try {
      final reports = _getStoredReports();
      final pendingReports = reports.where((r) => !r.uploaded).toList();
      
      for (final report in pendingReports) {
        await _uploadCrashReport(report);
        // Add small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      developer.log('Failed to upload pending reports: $e');
    }
  }

  /// Collect device information
  Future<void> _collectDeviceInfo() async {
    try {
      // Get basic platform info
      _deviceInfo = {
        'platform': defaultTargetPlatform.name,
        'isPhysicalDevice': !kIsWeb,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Try to get more detailed device info if available
      if (!kIsWeb) {
        try {
          // This would require device_info_plus package
          // For now, just include basic Flutter info
          _deviceInfo!.addAll({
            'flutterVersion': 'Flutter Framework',
            'dartVersion': 'Dart Runtime',
          });
        } catch (e) {
          developer.log('Failed to get detailed device info: $e');
        }
      }
    } catch (e) {
      developer.log('Failed to collect device info: $e');
      _deviceInfo = {'error': 'Failed to collect device info'};
    }
  }

  /// Collect app information
  Future<void> _collectAppInfo() async {
    try {
      _appInfo = {
        'appName': 'Tug App',
        'version': '1.0.0', // This should come from package_info_plus
        'buildMode': kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release'),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      developer.log('Failed to collect app info: $e');
      _appInfo = {'error': 'Failed to collect app info'};
    }
  }

  /// Generate unique report ID
  String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode.abs();
    return 'crash_${timestamp}_$random';
  }

  /// Add breadcrumb (public method)
  void _addBreadcrumb(String message) {
    addBreadcrumb(message);
  }

  /// Get crash report summary for debugging
  Map<String, dynamic> getCrashReportSummary() {
    if (!_initialized) {
      return {'error': 'Service not initialized'};
    }

    final reports = _getStoredReports();
    return {
      'totalReports': reports.length,
      'uploadedReports': reports.where((r) => r.uploaded).length,
      'pendingReports': reports.where((r) => !r.uploaded).length,
      'breadcrumbsCount': _breadcrumbs.length,
      'lastReport': reports.isNotEmpty ? reports.last.timestamp.toIso8601String() : null,
    };
  }

  /// Clear all stored crash reports (for testing/debugging)
  void clearCrashReports() {
    _prefs.remove(_crashReportsKey);
    _breadcrumbs.clear();
  }

  /// Dispose resources
  void dispose() {
    ErrorService().removeErrorReporter(_handleError);
  }
}

/// Extension to avoid unawaited warnings
extension _Unawaited on Future {
  void get unawaited {}
}