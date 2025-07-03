// Enhanced decorations.dart with modern UI elements and premium styling patterns
import 'package:flutter/material.dart';
import 'colors.dart';

class TugDecorations {
  // Premium hero container with enhanced gradients and glow effects
  static BoxDecoration heroContainer({
    bool isDark = false,
    bool isViceMode = false,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isViceMode
          ? [
              TugColors.viceGreen.withValues(alpha: 0.1),
              TugColors.viceGreenLight.withValues(alpha: 0.05),
              TugColors.viceGreenDark.withValues(alpha: 0.15),
            ]
          : [
              TugColors.primaryPurple.withValues(alpha: 0.1),
              TugColors.primaryPurpleLight.withValues(alpha: 0.05),
              TugColors.primaryPurpleDark.withValues(alpha: 0.15),
            ],
    ),
    boxShadow: [
      BoxShadow(
        color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // Enhanced section header with gradient background
  static BoxDecoration sectionHeaderDecoration({
    bool isDark = false,
    bool isViceMode = false,
  }) => BoxDecoration(
    gradient: LinearGradient(
      colors: isViceMode
          ? [TugColors.viceGreen.withValues(alpha: 0.2), TugColors.viceGreenLight.withValues(alpha: 0.1)]
          : [TugColors.primaryPurple.withValues(alpha: 0.2), TugColors.primaryPurpleLight.withValues(alpha: 0.1)],
    ),
    borderRadius: BorderRadius.circular(12),
  );

  // Enhanced icon container decoration
  static BoxDecoration iconContainerDecoration({
    bool isDark = false,
    bool isViceMode = false,
  }) => BoxDecoration(
    gradient: LinearGradient(
      colors: isViceMode
          ? [TugColors.viceGreen.withValues(alpha: 0.15), TugColors.viceGreenLight.withValues(alpha: 0.05)]
          : [TugColors.primaryPurple.withValues(alpha: 0.15), TugColors.primaryPurpleLight.withValues(alpha: 0.05)],
    ),
    borderRadius: BorderRadius.circular(12),
  );

  // Premium button decoration with gradients
  static BoxDecoration premiumButtonDecoration({
    bool isDark = false,
    bool isViceMode = false,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      colors: isViceMode
          ? [TugColors.viceGreen, TugColors.viceGreenDark]
          : [TugColors.primaryPurple, TugColors.primaryPurpleDark],
    ),
    boxShadow: [
      BoxShadow(
        color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Premium card with enhanced styling
  static BoxDecoration premiumCard({
    bool isDark = false,
    bool isViceMode = false,
    bool elevated = true,
  }) => BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        isDark ? TugColors.darkSurface : Colors.white,
        (isDark ? TugColors.darkSurface : Colors.white).withValues(alpha: 0.8),
      ],
    ),
    border: Border.all(
      color: isDark
          ? TugColors.darkSurfaceVariant.withValues(alpha: 0.3)
          : TugColors.lightSurfaceVariant.withValues(alpha: 0.5),
      width: 1,
    ),
    boxShadow: elevated ? [
      BoxShadow(
        color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.1),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ] : [],
  );

  // Enhanced app background with mode-specific gradients
  static BoxDecoration enhancedAppBackground({
    bool isDark = false,
    bool isViceMode = false,
  }) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.02),
      ],
    ),
  );

  // Enhanced avatar decoration with glow effects
  static BoxDecoration enhancedAvatarDecoration({
    bool isDark = false,
    bool isViceMode = false,
  }) => BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: isViceMode
          ? [TugColors.viceGreen, TugColors.viceGreenLight]
          : [TugColors.primaryPurple, TugColors.primaryPurpleLight],
    ),
    boxShadow: [
      BoxShadow(
        color: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.4),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Enhanced badge decoration with gradient and glow
  static BoxDecoration enhancedBadgeDecoration({
    Color color = TugColors.success,
    double radius = 16,
  }) => BoxDecoration(
    gradient: LinearGradient(
      colors: [color, Color.lerp(color, Colors.white, 0.2) ?? color],
    ),
    shape: radius > 0 ? BoxShape.rectangle : BoxShape.circle,
    borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
    border: Border.all(color: Colors.white, width: 1),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.4),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Legacy decorations for backward compatibility
  
  // Premium card with glass effect and subtle border
  static BoxDecoration cardDecoration({bool isDark = false, bool elevated = false}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? TugColors.darkGradient
          : TugColors.lightGradient,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: elevated
        ? TugColors.getShadow(isDark)
        : [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color(0xFF9CADF3).withValues(alpha: 0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
      width: 0.5,
    ),
  );

  // Featured card with highlight for important elements
  static BoxDecoration featuredCardDecoration({bool isDark = false}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              TugColors.primaryPurple.withValues(alpha: 0.15),
              TugColors.darkSurface,
            ]
          : [
              TugColors.primaryPurpleLight.withValues(alpha: 0.05),
              Colors.white,
            ],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: TugColors.getShadow(isDark),
    border: Border.all(
      color: isDark
          ? TugColors.primaryPurple.withValues(alpha: 0.2)
          : TugColors.primaryPurple.withValues(alpha: 0.1),
      width: isDark ? 1 : 0.5,
    ),
  );

  // Container with tint for secondary elements
  static BoxDecoration tintedContainerDecoration({
    bool isDark = false,
    Color color = Colors.transparent,
    double radius = 12,
  }) => BoxDecoration(
    color: (isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.08)),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: (isDark
          ? color.withValues(alpha: 0.3)
          : color.withValues(alpha: 0.2)),
      width: 1,
    ),
  );

  // Beautiful app background with soft gradient
  static BoxDecoration appBackground({bool isDark = false}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              TugColors.darkBackground,
              Color.lerp(TugColors.darkBackground, TugColors.primaryPurple, 0.07) ?? TugColors.darkBackground,
            ]
          : [
              TugColors.lightBackground,
              Color.lerp(TugColors.lightBackground, TugColors.primaryPurple, 0.03) ?? TugColors.lightBackground,
            ],
    ),
  );

  // Fancy section header with indicator line
  static BoxDecoration sectionHeader({bool isDark = false}) => BoxDecoration(
    border: Border(
      bottom: BorderSide(
        color: isDark
            ? TugColors.primaryPurple.withValues(alpha: 0.3)
            : TugColors.primaryPurple.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
  );

  // Circular avatar container with colored border
  static BoxDecoration avatarDecoration({
    bool isDark = false,
    required Color color,
    double size = 40,
  }) => BoxDecoration(
    color: isDark
        ? color.withValues(alpha: 0.1)
        : color.withValues(alpha: 0.07),
    shape: BoxShape.circle,
    border: Border.all(
      color: color.withValues(alpha: isDark ? 0.3 : 0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.15),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Badge decoration for notifications or status indicators
  static BoxDecoration badgeDecoration({
    Color color = Colors.red,
    double radius = 16,
  }) => BoxDecoration(
    color: color,
    shape: radius > 0 ? BoxShape.rectangle : BoxShape.circle,
    borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Floating action button decoration
  static BoxDecoration fabDecoration({bool isDark = false}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        TugColors.primaryPurple,
        TugColors.primaryPurpleLight,
      ],
    ),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: TugColors.primaryPurple.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // Search box decoration
  static BoxDecoration searchBoxDecoration({bool isDark = false}) => BoxDecoration(
    color: isDark
        ? TugColors.darkSurfaceVariant
        : TugColors.lightSurfaceVariant,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      width: 0.5,
    ),
  );
}