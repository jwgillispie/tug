// lib/widgets/home/empty_state.dart
import 'package:flutter/material.dart';
import '../../utils/theme/colors.dart';
import '../../utils/theme/buttons.dart';
import '../../utils/theme/decorations.dart';
import '../../utils/quantum_effects.dart';
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
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isViceMode
                ? [
                    TugColors.viceGreen.withValues(alpha: 0.08),
                    TugColors.viceGreenLight.withValues(alpha: 0.04),
                    TugColors.viceGreenDark.withValues(alpha: 0.12),
                    TugColors.viceGreen.withValues(alpha: 0.06),
                  ]
                : [
                    TugColors.primaryPurple.withValues(alpha: 0.08),
                    TugColors.primaryPurpleLight.withValues(alpha: 0.04),
                    TugColors.primaryPurpleDark.withValues(alpha: 0.12),
                    TugColors.primaryPurple.withValues(alpha: 0.06),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced icon with premium glow effect
            QuantumEffects.floating(
              offset: 12,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.3),
                          TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Main icon container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isViceMode
                            ? [
                                TugColors.viceGreen,
                                TugColors.viceGreenLight,
                                TugColors.viceGreenDark,
                              ]
                            : [
                                TugColors.primaryPurple,
                                TugColors.primaryPurpleLight,
                                TugColors.primaryPurpleDark,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isViceMode ? Icons.psychology_rounded : Icons.auto_awesome_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Enhanced title with gradient text
            QuantumEffects.gradientText(
              isViceMode ? 'no vices defined yet' : 'no values defined yet',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              colors: isViceMode
                  ? [TugColors.viceGreen, TugColors.viceGreenLight, TugColors.viceGreenDark]
                  : [TugColors.primaryPurple, TugColors.primaryPurpleLight, TugColors.primaryPurpleDark],
            ),
            const SizedBox(height: 12),
            
            // Enhanced subtitle
            Text(
              isViceMode 
                  ? 'start tracking behaviors you want to overcome'
                  : 'define what matters most to you and track your progress',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode 
                    ? TugColors.darkTextSecondary 
                    : TugColors.lightTextSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Premium button with gradient
            Container(
              decoration: TugDecorations.premiumButtonDecoration(
                isDark: isDarkMode,
                isViceMode: isViceMode,
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onAddPressed,
                icon: Icon(
                  isViceMode ? Icons.add_circle_outline : Icons.star_border,
                  color: Colors.white,
                ),
                label: Text(
                  isViceMode ? 'add your first vice' : 'add your first value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: TugDecorations.premiumCard(
          isDark: isDarkMode,
          isViceMode: isViceMode,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced loading indicator
            QuantumEffects.holographicShimmer(
              child: CircularProgressIndicator(
                color: isViceMode ? TugColors.viceGreen : TugColors.primaryPurple,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            
            // Enhanced loading text with gradient
            QuantumEffects.gradientText(
              message ?? (isViceMode ? 'loading vices...' : 'loading values...'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              colors: isViceMode
                  ? [TugColors.viceGreen, TugColors.viceGreenLight]
                  : [TugColors.primaryPurple, TugColors.primaryPurpleLight],
            ),
            const SizedBox(height: 8),
            
            Text(
              'preparing your personalized experience',
              style: TextStyle(
                color: isDarkMode 
                    ? TugColors.darkTextSecondary 
                    : TugColors.lightTextSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: TugDecorations.premiumCard(
          isDark: isDarkMode,
          isViceMode: isViceMode,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced error icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    TugColors.error.withValues(alpha: 0.2),
                    TugColors.error.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: TugColors.error.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: TugColors.error,
              ),
            ),
            const SizedBox(height: 24),
            
            // Enhanced error title
            Text(
              isViceMode ? 'error loading vices' : 'error loading values',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode 
                    ? TugColors.darkTextPrimary 
                    : TugColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode 
                    ? TugColors.darkTextSecondary 
                    : TugColors.lightTextSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Premium retry button
            Container(
              decoration: TugDecorations.premiumButtonDecoration(
                isDark: isDarkMode,
                isViceMode: isViceMode,
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                label: const Text(
                  'try again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}