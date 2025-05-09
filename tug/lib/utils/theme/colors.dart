// Enhanced colors.dart
import 'package:flutter/material.dart';

class TugColors {
  // Primary Colors - enhanced vibrant palette
  static const primaryPurple = Color(0xFF7B2EE1); // richer purple
  static const primaryPurpleDark = Color(0xFF652CD0); // darker shade for depth
  static const primaryPurpleLight = Color(0xFFA975FF); // lighter shade for accents

  // Secondary colors
  static const secondaryTeal = Color(0xFF0BCBC8); // brighter teal that pops
  static const secondaryTealDark = Color(0xFF06ADAC); // darker teal for depth
  static const tertiaryGold = Color(0xFFE8BE42); // warmer gold tone

  // Accent Colors for variety
  static const accentBlue = Color(0xFF3D7AFF); // vibrant blue
  static const accentPink = Color(0xFFFF5BB0); // soft pink
  static const accentOrange = Color(0xFFFF9052); // warm orange

  // Supporting Colors - refined and clear
  static const success = Color(0xFF26C77E); // brighter, more positive green
  static const warning = Color(0xFFFFC02C); // warmer, more visible yellow
  static const error = Color(0xFFFF4D4F); // more vibrant red

  // Light Theme Neutrals - cleaner, more elegant grays
  static const lightBackground = Color(0xFFF9FAFD); // slightly cooler white
  static const lightSurface = Color(0xFFF2F4F9); // subtle blue-tinted gray
  static const lightSurfaceVariant = Color(0xFFE7ECFF); // subtle purple tint
  static const lightTextPrimary = Color(0xFF1E1E2F); // darker, richer text color
  static const lightTextSecondary = Color(0xFF5D5E78); // more elegant secondary text
  static const lightBorder = Color(0xFFDCE1F0); // subtle blue-tinted border

  // Dark Theme Neutrals - more sophisticated darks
  static const darkBackground = Color(0xFF121320); // deeper blue-black
  static const darkSurface = Color(0xFF1D1E30); // deeper blue-purple tint
  static const darkSurfaceVariant = Color(0xFF262942); // subtle purple dark surface
  static const darkTextPrimary = Color(0xFFF0F2FF); // slightly blue-tinted white
  static const darkTextSecondary = Color(0xFFBBC0D9); // elegant light purple-gray
  static const darkBorder = Color(0xFF32344A); // subtle purple border

  // Gradient colors for effects
  static const gradientStart = Color(0xFF6C38D4);
  static const gradientEnd = Color(0xFF9C64FF);

  // Shades for card gradients
  static final lightGradient = [
    const Color(0xFFFFFFFF),
    const Color(0xFFF6F7FE),
  ];

  static final darkGradient = [
    const Color(0xFF232537),
    const Color(0xFF1B1C2E),
  ];

  // Card shadow
  static List<BoxShadow> getShadow(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withOpacity(0.3)
          : const Color(0xFF9CADF3).withOpacity(0.15),
      offset: const Offset(0, 4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: isDark
          ? primaryPurple.withOpacity(0.03)
          : primaryPurple.withOpacity(0.02),
      offset: const Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];
}
