// Simplified color palette focused on purple, black, white, and gray
import 'package:flutter/material.dart';

class TugColors {
  // Primary Colors - elegant purple palette
  static const primaryPurple = Color(0xFF7C3AED); // main purple
  static const primaryPurpleDark = Color(0xFF5B21B6); // darker purple
  static const primaryPurpleLight = Color(0xFF9F7AEA); // lighter purple
  
  // Additional purple shades for variety
  static const purpleShade50 = Color(0xFFF5F3FF);
  static const purpleShade100 = Color(0xFFEDE9FE);
  static const purpleShade200 = Color(0xFFDDD6FE);
  static const purpleShade300 = Color(0xFFC4B5FD);
  static const purpleShade400 = Color(0xFFA78BFA);
  static const purpleShade500 = Color(0xFF8B5CF6);
  static const purpleShade600 = Color(0xFF7C3AED);
  static const purpleShade700 = Color(0xFF6D28D9);
  static const purpleShade800 = Color(0xFF5B21B6);
  static const purpleShade900 = Color(0xFF4C1D95);

  // Status Colors - simplified
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Light Theme - clean whites and grays
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFAFAFA);
  static const lightSurfaceVariant = Color(0xFFF5F5F5);
  static const lightTextPrimary = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightBorder = Color(0xFFE5E7EB);

  // Dark Theme - sophisticated blacks and grays
  static const darkBackground = Color(0xFF0F0F0F);
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkSurfaceVariant = Color(0xFF2A2A2A);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkBorder = Color(0xFF374151);

  // Gradient colors
  static const gradientPurpleStart = Color(0xFF7C3AED);
  static const gradientPurpleEnd = Color(0xFF9F7AEA);

  // Simple gradient sets
  static final lightGradient = [
    lightSurface,
    lightBackground,
  ];

  static final darkGradient = [
    darkSurface,
    darkBackground,
  ];

  // Subtle shadows
  static List<BoxShadow> getShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  // Simple glow effect
  static List<BoxShadow> getNeonGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withOpacity(0.3 * intensity),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ];

  // Glass effect
  static Color glassEffect(bool isDark) => isDark
      ? darkSurface.withOpacity(0.8)
      : lightSurface.withOpacity(0.8);
      
  static double glassBlurRadius(bool isDark) => 10.0;
      
  static Color glassBorder(bool isDark) => isDark
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.1);

  // Shimmer effect
  static Color shimmerBase(bool isDark) => isDark
      ? darkSurfaceVariant
      : lightSurfaceVariant;

  static Color shimmerHighlight(bool isDark) => isDark
      ? Colors.white.withOpacity(0.1)
      : Colors.white;

  // Gradient constructors
  static LinearGradient getPrimaryGradient({bool vertical = false, bool reversed = false}) {
    final List<Color> colors = reversed 
        ? [gradientPurpleEnd, gradientPurpleStart]
        : [gradientPurpleStart, gradientPurpleEnd];
        
    return LinearGradient(
      colors: colors,
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    );
  }
  
  static RadialGradient getCosmicGlow(Color centerColor, Color outerColor, {double radius = 1.0}) {
    return RadialGradient(
      colors: [
        centerColor,
        Color.lerp(centerColor, outerColor, 0.5) ?? outerColor,
        outerColor,
      ],
      stops: const [0.0, 0.5, 1.0],
      radius: radius,
    );
  }
}