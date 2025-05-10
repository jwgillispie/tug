// Enhanced colors.dart with modern palette
import 'package:flutter/material.dart';

class TugColors {
  // Primary Colors - luxurious purple palette
  static const primaryPurple = Color(0xFF8A4FFF); // vibrant violet purple
  static const primaryPurpleDark = Color(0xFF6B38E5); // deeper purple for contrast
  static const primaryPurpleLight = Color(0xFFB285FF); // soft lavender for accents

  // Secondary colors - refreshed palette
  static const secondaryTeal = Color(0xFF0DE0DD); // bright electric teal
  static const secondaryTealDark = Color(0xFF00B3B0); // deeper teal for contrast
  static const tertiaryGold = Color(0xFFFFC737); // vivid golden yellow

  // Accent Colors for variety - expanded palette
  static const accentBlue = Color(0xFF4285FF); // vibrant royal blue
  static const accentPink = Color(0xFFFF469C); // bold magenta pink
  static const accentOrange = Color(0xFFFF7A45); // energetic orange
  static const accentGreen = Color(0xFF3FDD91); // fresh mint green
  static const accentPurple = Color(0xFFD860FF); // bright orchid purple

  // Achievement type colors - enhanced for clarity
  static const streakOrange = Color(0xFFFF7A45); // energetic orange for streaks
  static const balanceBlue = Color(0xFF4285FF); // vibrant blue for balance
  static const frequencyGreen = Color(0xFF3FDD91); // fresh mint for frequency
  static const milestoneRed = Color(0xFFFF469C); // bold pink for milestones
  static const specialPurple = Color(0xFFD860FF); // bright purple for special achievements

  // Status Colors - clear and accessible
  static const success = Color(0xFF3FDD91); // fresh success green
  static const warning = Color(0xFFFFBB38); // clear warning amber
  static const error = Color(0xFFFF5252); // bright error red
  static const info = Color(0xFF4285FF); // informational blue

  // Light Theme Neutrals - refined for better contrast
  static const lightBackground = Color(0xFFF8F9FE); // crisp cool white
  static const lightSurface = Color(0xFFFEFEFF); // pure white surface
  static const lightSurfaceVariant = Color(0xFFEEF1FF); // subtle purple tint
  static const lightTextPrimary = Color(0xFF191A2E); // near-black with blue undertone
  static const lightTextSecondary = Color(0xFF4E5080); // rich muted purple-gray
  static const lightBorder = Color(0xFFE0E3F5); // subtle lavender border

  // Dark Theme Neutrals - rich and comfortable darks
  static const darkBackground = Color(0xFF0F1021); // deep space background
  static const darkSurface = Color(0xFF1A1B31); // rich navy surface
  static const darkSurfaceVariant = Color(0xFF282A4A); // elevated purple dark surface
  static const darkTextPrimary = Color(0xFFF8F9FF); // crisp white text
  static const darkTextSecondary = Color(0xFFC2C8E8); // soft lavender-gray text
  static const darkBorder = Color(0xFF3A3D60); // subtle indigo border

  // Gradient colors for effects - enhanced for visual impact
  static const gradientPurpleStart = Color(0xFF7F42E2);
  static const gradientPurpleEnd = Color(0xFFB285FF);

  static const gradientTealStart = Color(0xFF00B3B0);
  static const gradientTealEnd = Color(0xFF0DE0DD);

  static const gradientGoldStart = Color(0xFFE8A617);
  static const gradientGoldEnd = Color(0xFFFFC737);

  // Card gradients - subtle depth
  static final lightGradient = [
    const Color(0xFFFFFFFF),
    const Color(0xFFF6F7FE),
  ];

  static final darkGradient = [
    const Color(0xFF232537),
    const Color(0xFF1A1B31),
  ];

  // Card shadows - revised for clarity
  static List<BoxShadow> getShadow(bool isDark) => [
    BoxShadow(
      color: isDark
          ? Colors.black.withOpacity(0.35)
          : const Color(0xFF9CADF3).withOpacity(0.18),
      offset: const Offset(0, 4),
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: isDark
          ? primaryPurple.withOpacity(0.05)
          : primaryPurple.withOpacity(0.03),
      offset: const Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  // Glass effect - for frosted glass components
  static Color glassEffect(bool isDark) => isDark
      ? const Color(0xFF1A1B31).withOpacity(0.7)
      : Colors.white.withOpacity(0.7);

  // Shimmer effect colors
  static Color shimmerBase(bool isDark) => isDark
      ? const Color(0xFF232537)
      : const Color(0xFFEEF1FF);

  static Color shimmerHighlight(bool isDark) => isDark
      ? const Color(0xFF3A3D60)
      : Colors.white;
}
