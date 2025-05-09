// Enhanced decorations.dart with modern UI elements
import 'package:flutter/material.dart';
import 'colors.dart';

class TugDecorations {
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
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0xFF9CADF3).withOpacity(0.08),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
    border: Border.all(
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.03),
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
              TugColors.primaryPurple.withOpacity(0.15),
              TugColors.darkSurface,
            ]
          : [
              TugColors.primaryPurpleLight.withOpacity(0.05),
              Colors.white,
            ],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: TugColors.getShadow(isDark),
    border: Border.all(
      color: isDark
          ? TugColors.primaryPurple.withOpacity(0.2)
          : TugColors.primaryPurple.withOpacity(0.1),
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
        ? color.withOpacity(0.15)
        : color.withOpacity(0.08)),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: (isDark
          ? color.withOpacity(0.3)
          : color.withOpacity(0.2)),
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
            ? TugColors.primaryPurple.withOpacity(0.3)
            : TugColors.primaryPurple.withOpacity(0.2),
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
        ? color.withOpacity(0.1)
        : color.withOpacity(0.07),
    shape: BoxShape.circle,
    border: Border.all(
      color: color.withOpacity(isDark ? 0.3 : 0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.15),
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
        color: color.withOpacity(0.3),
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
        color: TugColors.primaryPurple.withOpacity(0.3),
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
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.03),
      width: 0.5,
    ),
  );
}