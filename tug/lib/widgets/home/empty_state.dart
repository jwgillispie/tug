// lib/widgets/home/empty_state.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../services/app_mode_service.dart';

class EmptyState extends StatelessWidget {
  final AppMode appMode;
  final VoidCallback onAddPressed;

  const EmptyState({
    super.key,
    required this.appMode,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = appMode == AppMode.vicesMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isViceMode ? Icons.psychology_outlined : Icons.star_border_rounded,
            size: 64,
            color: (isViceMode ? TugColors.viceGreen : TugColors.primaryPurple)
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isViceMode ? 'no vices defined yet' : 'no values defined yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isViceMode 
                ? 'need to add some vices to track'
                : 'need to add some values',
            style: TextStyle(
              color: isDarkMode 
                  ? TugColors.darkTextSecondary 
                  : TugColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: TugButtons.primaryButtonStyle(isDark: isDarkMode),
            onPressed: onAddPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(isViceMode ? 'add vices' : 'add values'),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  final AppMode appMode;
  final String? message;

  const LoadingState({
    super.key,
    required this.appMode,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = appMode == AppMode.vicesMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isViceMode ? TugColors.viceGreen : TugColors.primaryPurple,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? (isViceMode ? 'loading vices...' : 'loading values...'),
            style: TextStyle(
              color: isDarkMode 
                  ? TugColors.darkTextSecondary 
                  : TugColors.lightTextSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final AppMode appMode;
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.appMode,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isViceMode = appMode == AppMode.vicesMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isViceMode ? TugColors.viceGreen : TugColors.primaryPurple,
          ),
          const SizedBox(height: 16),
          Text(
            isViceMode ? 'error loading vices' : 'error loading values',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode 
                  ? TugColors.darkTextPrimary 
                  : TugColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: isDarkMode 
                  ? TugColors.darkTextSecondary 
                  : TugColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: TugButtons.primaryButtonStyle(isDark: isDarkMode),
            onPressed: onRetry,
            child: const Text('retry'),
          ),
        ],
      ),
    );
  }
}