// lib/widgets/common/error_boundary.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/error_service.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final Function(AppError)? onError;
  final bool showErrorDetails;
  final bool allowRetry;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.fallbackWidget,
    this.onError,
    this.showErrorDetails = kDebugMode,
    this.allowRetry = true,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // Listen to error stream
    ErrorService().errorStream.listen((error) {
      if (mounted && error.severity == ErrorSeverity.critical) {
        setState(() {
          _error = error;
          _hasError = true;
        });
        
        widget.onError?.call(error);
      }
    });
  }

  void _retry() {
    setState(() {
      _error = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallbackWidget ?? 
             _buildDefaultErrorWidget(context, _error!);
    }

    // Wrap child in error catching widget
    return ErrorCatchingWidget(
      child: widget.child,
      onError: (error, stackTrace) {
        final appError = AppError.crash(
          message: error.toString(),
          stackTrace: stackTrace,
          context: {'widget': widget.child.runtimeType.toString()},
        );
        
        ErrorService().reportError(appError);
        
        setState(() {
          _error = appError;
          _hasError = true;
        });
        
        widget.onError?.call(appError);
      },
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context, AppError error) {
    final theme = Theme.of(context);
    
    return Material(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.userMessage,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (widget.showErrorDetails) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Error Details:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (error.code != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${error.code}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (widget.allowRetry)
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ErrorCatchingWidget extends StatefulWidget {
  final Widget child;
  final Function(Object, StackTrace?)? onError;

  const ErrorCatchingWidget({
    Key? key,
    required this.child,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorCatchingWidget> createState() => _ErrorCatchingWidgetState();
}

class _ErrorCatchingWidgetState extends State<ErrorCatchingWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _catchErrors();
  }

  void _catchErrors() {
    FlutterError.onError = (FlutterErrorDetails details) {
      widget.onError?.call(details.exception, details.stack);
    };
  }
}

/// Snackbar for showing non-critical errors
class ErrorSnackBar {
  static void show(
    BuildContext context,
    AppError error, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    
    // Remove any existing snackbars
    messenger.clearSnackBars();
    
    Color backgroundColor;
    IconData icon;
    
    switch (error.severity) {
      case ErrorSeverity.low:
        backgroundColor = theme.colorScheme.surfaceVariant;
        icon = Icons.info_outline;
        break;
      case ErrorSeverity.medium:
        backgroundColor = Colors.orange.shade100;
        icon = Icons.warning_outlined;
        break;
      case ErrorSeverity.high:
        backgroundColor = theme.colorScheme.errorContainer;
        icon = Icons.error_outline;
        break;
      case ErrorSeverity.critical:
        backgroundColor = theme.colorScheme.error;
        icon = Icons.dangerous_outlined;
        break;
    }
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: error.severity == ErrorSeverity.critical
                  ? theme.colorScheme.onError
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error.userMessage,
                    style: TextStyle(
                      color: error.severity == ErrorSeverity.critical
                          ? theme.colorScheme.onError
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (kDebugMode && error.code != null)
                    Text(
                      'Code: ${error.code}',
                      style: TextStyle(
                        fontSize: 12,
                        color: error.severity == ErrorSeverity.critical
                            ? theme.colorScheme.onError.withOpacity(0.8)
                            : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Dialog for showing detailed error information
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      icon: Icon(
        _getIconForSeverity(error.severity),
        color: _getColorForSeverity(error.severity, theme),
        size: 32,
      ),
      title: Text(
        _getTitleForSeverity(error.severity),
        style: TextStyle(
          color: _getColorForSeverity(error.severity, theme),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.userMessage),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Debug Information:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type: ${error.type.name}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (error.code != null)
                    Text(
                      'Code: ${error.code}',
                      style: theme.textTheme.bodySmall,
                    ),
                  Text(
                    'Message: ${error.message}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info_outline;
      case ErrorSeverity.medium:
        return Icons.warning_outlined;
      case ErrorSeverity.high:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  Color _getColorForSeverity(ErrorSeverity severity, ThemeData theme) {
    switch (severity) {
      case ErrorSeverity.low:
        return theme.colorScheme.primary;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        return theme.colorScheme.error;
    }
  }

  String _getTitleForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 'Information';
      case ErrorSeverity.medium:
        return 'Warning';
      case ErrorSeverity.high:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }
}