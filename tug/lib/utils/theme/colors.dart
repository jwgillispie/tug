// Simplified color palette focused on purple, black, white, and gray
import 'package:flutter/material.dart';

class TugColors {
  // Primary Colors - elegant purple palette (for values mode)
  static const primaryPurple = Color(0xFF7C3AED); // main purple
  static const primaryPurpleDark = Color(0xFF5B21B6); // darker purple
  static const primaryPurpleLight = Color(0xFF9F7AEA); // lighter purple

  // Vice Mode Colors - serious red/orange palette
  static const viceRed = Color(0xFFDC2626); // main red for vices
  static const viceRedDark = Color(0xFF991B1B); // darker red
  static const viceRedLight = Color(0xFFEF4444); // lighter red
  static const viceOrange = Color(0xFFEA580C); // warning orange
  static const viceOrangeDark = Color(0xFFC2410C); // darker orange
  static const viceOrangeLight = Color(0xFFF97316); // lighter orange
  
  // Indulgence Colors - calming green palette for acceptance and growth
  static const indulgenceGreen = Color(0xFF059669); // main green for indulgences
  static const indulgenceGreenDark = Color(0xFF047857); // darker green
  static const indulgenceGreenLight = Color(0xFF10B981); // lighter green
  static const indulgenceForest = Color(0xFF064E3B); // deep forest green
  static const indulgenceEmerald = Color(0xFF065F46); // emerald green
  static const indulgenceMint = Color(0xFF6EE7B7); // soft mint green
  
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

  // Vice Mode Dark Theme - more serious/somber
  static const viceModeDarkBackground = Color(0xFF0A0A0A);
  static const viceModeDarkSurface = Color(0xFF1C1C1C);
  static const viceModeDarkSurfaceVariant = Color(0xFF2C1810);
  static const viceModeTextPrimary = Color(0xFFFEF2F2);
  static const viceModeTextSecondary = Color(0xFFA1A1AA);
  static const viceModeBorder = Color(0xFF451A03);

  // Gradient colors
  static const gradientPurpleStart = Color(0xFF7C3AED);
  static const gradientPurpleEnd = Color(0xFF9F7AEA);
  
  // Vice mode gradient colors
  static const gradientViceStart = Color(0xFFDC2626);
  static const gradientViceEnd = Color(0xFFEA580C);
  
  // Indulgence mode gradient colors
  static const gradientIndulgenceStart = Color(0xFF059669);
  static const gradientIndulgenceEnd = Color(0xFF10B981);

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

  // Vice mode specific methods
  
  /// Get vice mode gradient
  static LinearGradient getViceGradient({bool vertical = false, bool reversed = false}) {
    final List<Color> colors = reversed 
        ? [gradientViceEnd, gradientViceStart]
        : [gradientViceStart, gradientViceEnd];
        
    return LinearGradient(
      colors: colors,
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    );
  }

  /// Get indulgence mode gradient
  static LinearGradient getIndulgenceGradient({bool vertical = false, bool reversed = false}) {
    final List<Color> colors = reversed 
        ? [gradientIndulgenceEnd, gradientIndulgenceStart]
        : [gradientIndulgenceStart, gradientIndulgenceEnd];
        
    return LinearGradient(
      colors: colors,
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    );
  }

  /// Get mode-appropriate primary color
  static Color getPrimaryColor(bool isViceMode) {
    return isViceMode ? viceRed : primaryPurple;
  }

  /// Get indulgence-specific primary color
  static Color getIndulgencePrimaryColor() {
    return indulgenceGreen;
  }

  /// Get indulgence-specific secondary color
  static Color getIndulgenceSecondaryColor() {
    return indulgenceGreenLight;
  }

  /// Get mode-appropriate background color
  static Color getBackgroundColor(bool isDark, bool isViceMode) {
    if (isViceMode && isDark) return viceModeDarkBackground;
    if (isDark) return darkBackground;
    return lightBackground;
  }

  /// Get mode-appropriate surface color
  static Color getSurfaceColor(bool isDark, bool isViceMode) {
    if (isViceMode && isDark) return viceModeDarkSurface;
    if (isDark) return darkSurface;
    return lightSurface;
  }

  /// Get mode-appropriate text color
  static Color getTextColor(bool isDark, bool isViceMode, {bool isSecondary = false}) {
    if (isViceMode && isDark) {
      return isSecondary ? viceModeTextSecondary : viceModeTextPrimary;
    }
    if (isDark) {
      return isSecondary ? darkTextSecondary : darkTextPrimary;
    }
    return isSecondary ? lightTextSecondary : lightTextPrimary;
  }

  /// Get streak color based on mode and days
  static Color getStreakColor(bool isViceMode, int days) {
    if (isViceMode) {
      // For vices, longer streaks = better (more days clean)
      if (days >= 30) return Color(0xFF059669); // Green for 30+ days clean
      if (days >= 7) return Color(0xFFD97706); // Orange for 7-29 days
      if (days >= 1) return Color(0xFFEAB308); // Yellow for 1-6 days
      return viceRed; // Red for 0 days (recent indulgence)
    } else {
      // For values, streaks use the standard purple theme
      return primaryPurple;
    }
  }

  /// Get severity color for vices (1-5 scale)
  static Color getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Color(0xFFF59E0B); // Mild - yellow
      case 2:
        return Color(0xFFEA580C); // Moderate - orange
      case 3:
        return Color(0xFFDC2626); // Concerning - red
      case 4:
        return Color(0xFF991B1B); // Severe - dark red
      case 5:
        return Color(0xFF7F1D1D); // Critical - very dark red
      default:
        return Color(0xFF6B7280); // Unknown - gray
    }
  }
}