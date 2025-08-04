// lib/widgets/home/components/home_loading_states.dart
import 'package:flutter/material.dart';
import '../../../utils/quantum_effects.dart';
import '../../../utils/theme/colors.dart';
import '../../../utils/loading_messages.dart';

class HomeLoadingChart extends StatelessWidget {
  final bool isViceMode;
  
  const HomeLoadingChart({
    super.key, 
    required this.isViceMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'Loading chart data, please wait',
      child: Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? TugColors.getSurfaceColor(isDarkMode, isViceMode)
              : TugColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QuantumEffects.cosmicPulse(
                child: CircularProgressIndicator(
                  color: TugColors.getPrimaryColor(isViceMode),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                LoadingMessages.getRandomMessage(),
                style: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeErrorChart extends StatelessWidget {
  final String message;
  final bool isViceMode;
  final VoidCallback? onRetry;
  
  const HomeErrorChart({
    super.key,
    required this.message,
    required this.isViceMode,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'Error loading chart: $message',
      child: Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.withValues(alpha: 0.7),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'unable to load chart',
                style: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  label: 'Retry loading chart',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('try again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TugColors.getPrimaryColor(isViceMode),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HomeEmptyChart extends StatelessWidget {
  final bool isViceMode;
  final VoidCallback? onAddFirst;
  
  const HomeEmptyChart({
    super.key,
    required this.isViceMode,
    this.onAddFirst,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: isViceMode 
          ? 'No vice data available, add your first vice to get started'
          : 'No activity data available, log your first activity to get started',
      child: Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TugColors.getSurfaceColor(isDarkMode, isViceMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QuantumEffects.floating(
                offset: 4,
                child: Icon(
                  isViceMode ? Icons.psychology_outlined : Icons.insights_outlined,
                  color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.5),
                  size: 64,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isViceMode ? 'no vice data yet' : 'no activity data yet',
                style: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isViceMode 
                    ? 'track your first vice to see insights here'
                    : 'log your first activity to see your progress',
                style: TextStyle(
                  color: TugColors.getTextColor(isDarkMode, isViceMode, isSecondary: true),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (onAddFirst != null) ...[
                const SizedBox(height: 20),
                Semantics(
                  label: isViceMode ? 'Add your first vice' : 'Log your first activity',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: onAddFirst,
                    icon: Icon(
                      isViceMode ? Icons.add : Icons.timelapse,
                      size: 16,
                    ),
                    label: Text(isViceMode ? 'add vice' : 'log activity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TugColors.getPrimaryColor(isViceMode),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}