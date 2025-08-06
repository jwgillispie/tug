// lib/screens/debug/error_handling_demo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/error_service.dart';
import '../../services/crash_reporting_service.dart';
import '../../services/offline_error_service.dart';
import '../../widgets/common/error_boundary.dart';

class ErrorHandlingDemoScreen extends StatefulWidget {
  const ErrorHandlingDemoScreen({Key? key}) : super(key: key);

  @override
  State<ErrorHandlingDemoScreen> createState() => _ErrorHandlingDemoScreenState();
}

class _ErrorHandlingDemoScreenState extends State<ErrorHandlingDemoScreen> {
  final ErrorService _errorService = ErrorService();
  final CrashReportingService _crashReportingService = CrashReportingService();
  final OfflineErrorService _offlineErrorService = OfflineErrorService();
  
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _listenToErrors();
  }

  void _listenToErrors() {
    if (_isListening) return;
    
    _errorService.errorStream.listen((error) {
      if (mounted) {
        ErrorSnackBar.show(context, error);
      }
    });
    
    _isListening = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ErrorBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(
                title: 'Error Types Demo',
                children: [
                  _buildErrorButton(
                    'Network Error',
                    () => _simulateNetworkError(),
                    Icons.wifi_off,
                    Colors.orange,
                  ),
                  _buildErrorButton(
                    'Authentication Error',
                    () => _simulateAuthError(),
                    Icons.lock,
                    Colors.red,
                  ),
                  _buildErrorButton(
                    'Validation Error',
                    () => _simulateValidationError(),
                    Icons.error_outline,
                    Colors.yellow[700]!,
                  ),
                  _buildErrorButton(
                    'Critical Error (Crash)',
                    () => _simulateCrashError(),
                    Icons.dangerous,
                    Colors.red[900]!,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSection(
                title: 'Async Error Handling',
                children: [
                  _buildErrorButton(
                    'Async Operation with Error',
                    () => _simulateAsyncError(),
                    Icons.sync_problem,
                    Colors.blue,
                  ),
                  _buildErrorButton(
                    'Safe Async Operation',
                    () => _demonstrateSafeAsync(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildErrorButton(
                    'Async with Retry',
                    () => _demonstrateAsyncRetry(),
                    Icons.refresh,
                    Colors.purple,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSection(
                title: 'Offline Error Handling',
                children: [
                  _buildErrorButton(
                    'Queue Offline Action',
                    () => _demonstrateOfflineAction(),
                    Icons.cloud_off,
                    Colors.indigo,
                  ),
                  _buildErrorButton(
                    'Sync Offline Data',
                    () => _demonstrateOfflineSync(),
                    Icons.cloud_sync,
                    Colors.teal,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSection(
                title: 'Error History & Reporting',
                children: [
                  _buildErrorButton(
                    'Show Error History',
                    () => _showErrorHistory(),
                    Icons.history,
                    Colors.grey[700]!,
                  ),
                  _buildErrorButton(
                    'Show Crash Reports',
                    () => _showCrashReports(),
                    Icons.bug_report,
                    Colors.brown,
                  ),
                  _buildErrorButton(
                    'Clear All Data',
                    () => _clearAllData(),
                    Icons.clear_all,
                    Colors.red[300]!,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildStatusSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildErrorButton(
    String text,
    VoidCallback onPressed,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _getSystemStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text('Error loading status: ${snapshot.error}');
                }
                
                final status = snapshot.data ?? {};
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusItem('Error History', '${status['errorCount'] ?? 0} errors'),
                    _buildStatusItem('Crash Reports', '${status['crashCount'] ?? 0} reports'),
                    _buildStatusItem('Offline Actions', '${status['offlineActions'] ?? 0} queued'),
                    _buildStatusItem('Offline Errors', '${status['offlineErrors'] ?? 0} stored'),
                    _buildStatusItem('Connection Status', _offlineErrorService.isOnline ? 'Online' : 'Offline'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Error simulation methods
  void _simulateNetworkError() {
    _errorService.reportError(
      AppError.network(
        message: 'Failed to connect to server',
        userMessage: 'Please check your internet connection and try again.',
        code: 'NETWORK_001',
        context: {'endpoint': '/api/users', 'method': 'GET'},
      ),
    );
    
    _crashReportingService.addBreadcrumb(
      'Network error simulated',
      data: {'action': 'simulate_network_error'},
    );
  }

  void _simulateAuthError() {
    _errorService.reportError(
      AppError.authentication(
        message: 'Token expired or invalid',
        userMessage: 'Please log in again to continue.',
        code: 'AUTH_001',
        context: {'token_expired': true},
      ),
    );
  }

  void _simulateValidationError() {
    _errorService.reportError(
      AppError.validation(
        message: 'Invalid email format',
        userMessage: 'Please enter a valid email address.',
        code: 'VAL_001',
        context: {'field': 'email', 'value': 'invalid-email'},
      ),
    );
  }

  void _simulateCrashError() {
    _errorService.reportError(
      AppError.crash(
        message: 'Null pointer exception in user profile',
        userMessage: 'Something went wrong. Please restart the app.',
        code: 'CRASH_001',
        stackTrace: StackTrace.current,
        context: {'screen': 'profile', 'action': 'load_data'},
      ),
    );
  }

  Future<void> _simulateAsyncError() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      throw Exception('Simulated async operation failure');
    } catch (error, stackTrace) {
      _errorService.reportError(
        error,
        stackTrace: stackTrace,
        userMessage: 'The operation failed. Please try again.',
        type: ErrorType.api,
      );
    }
  }

  Future<void> _demonstrateSafeAsync() async {
    final result = await _errorService.handleAsync<String>(
      () async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (DateTime.now().millisecond % 2 == 0) {
          throw Exception('Random failure');
        }
        return 'Success!';
      },
      fallback: 'Fallback value',
      userMessage: 'Safe operation completed with fallback if needed.',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Result: $result')),
    );
  }

  Future<void> _demonstrateAsyncRetry() async {
    int attempts = 0;
    
    final result = await _errorService.handleAsync<String>(
      () async {
        attempts++;
        await Future.delayed(const Duration(milliseconds: 200));
        
        if (attempts <= 2) {
          throw Exception('Attempt $attempts failed');
        }
        
        return 'Success on attempt $attempts!';
      },
      fallback: 'Failed after retries',
      retryOnFailure: true,
      maxRetries: 3,
      userMessage: 'Operation with retry logic.',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Result: $result')),
    );
  }

  Future<void> _demonstrateOfflineAction() async {
    await _offlineErrorService.queueOfflineAction(
      type: 'demo_action',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        'user_action': 'button_press',
        'screen': 'error_demo',
      },
      maxRetries: 3,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offline action queued')),
    );
  }

  Future<void> _demonstrateOfflineSync() async {
    await _offlineErrorService.syncNow();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attempted to sync offline data')),
    );
  }

  void _showErrorHistory() {
    final errors = _errorService.errorHistory;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: errors.isEmpty
              ? const Text('No errors recorded')
              : ListView.builder(
                  itemCount: errors.length,
                  itemBuilder: (context, index) {
                    final error = errors[index];
                    return ListTile(
                      leading: Icon(_getErrorIcon(error.type)),
                      title: Text(error.message),
                      subtitle: Text(error.timestamp.toString()),
                      trailing: Chip(
                        label: Text(error.severity.name),
                        backgroundColor: _getSeverityColor(error.severity),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCrashReports() {
    final summary = _crashReportingService.getCrashReportSummary();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crash Report Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Reports: ${summary['totalReports']}'),
            Text('Uploaded Reports: ${summary['uploadedReports']}'),
            Text('Pending Reports: ${summary['pendingReports']}'),
            Text('Breadcrumbs: ${summary['breadcrumbsCount']}'),
            if (summary['lastReport'] != null)
              Text('Last Report: ${summary['lastReport']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    _errorService.clearHistory();
    _crashReportingService.clearCrashReports();
    await _offlineErrorService.clearOfflineData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All error data cleared')),
    );
    
    setState(() {}); // Refresh the status section
  }

  Future<Map<String, dynamic>> _getSystemStatus() async {
    return {
      'errorCount': _errorService.errorHistory.length,
      'crashCount': _crashReportingService.getCrashReportSummary()['totalReports'],
      'offlineActions': _offlineErrorService.getOfflineActions().length,
      'offlineErrors': _offlineErrorService.getOfflineErrors().length,
    };
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.business:
        return Icons.business;
      case ErrorType.unknown:
        return Icons.help_outline;
      case ErrorType.crash:
        return Icons.dangerous;
      case ErrorType.api:
        return Icons.api;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.permission:
        return Icons.security;
    }
  }

  Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.green.shade100;
      case ErrorSeverity.medium:
        return Colors.orange.shade100;
      case ErrorSeverity.high:
        return Colors.red.shade100;
      case ErrorSeverity.critical:
        return Colors.red.shade300;
    }
  }
}