// Futuristic colors.dart with modern sci-fi palette
import 'package:flutter/material.dart';

class TugColors {
  // Primary Colors - luxurious neon purple palette
  static const primaryPurple = Color(0xFF8A4FFF); // vibrant violet purple
  static const primaryPurpleDark = Color(0xFF6E3AE0); // deeper rich purple for contrast
  static const primaryPurpleLight = Color(0xFFB285FF); // ethereal lavender for accents

  // Secondary colors - holographic palette
  static const secondaryTeal = Color(0xFF00ECEF); // electric neon blue-teal
  static const secondaryTealDark = Color(0xFF00B3B5); // deeper teal for contrast
  static const tertiaryGold = Color(0xFFFFC837); // energetic golden yellow

  // Accent Colors for variety - expanded cyber palette
  static const accentBlue = Color(0xFF3E7EFF); // electric royal blue
  static const accentPink = Color(0xFFFF3E9A); // neon magenta pink
  static const accentOrange = Color(0xFFFF7A45); // energetic orange
  static const accentGreen = Color(0xFF27F2AA); // cyberpunk mint green
  static const accentPurple = Color(0xFFD860FF); // bright holographic purple

  // Achievement type colors - enhanced for visual impact
  static const streakOrange = Color(0xFFFF7A45); // energetic orange for streaks
  static const balanceBlue = Color(0xFF3E7EFF); // vibrant blue for balance
  static const frequencyGreen = Color(0xFF27F2AA); // fresh mint for frequency
  static const milestoneRed = Color(0xFFFF3E9A); // neon pink for milestones
  static const specialPurple = Color(0xFFD860FF); // bright purple for special achievements

  // Status Colors - futuristic and accessible
  static const success = Color(0xFF27F2AA); // neon success green
  static const warning = Color(0xFFFFBB38); // clear warning amber
  static const error = Color(0xFFFF4A6E); // bright error red
  static const info = Color(0xFF3E7EFF); // informational blue

  // Light Theme Neutrals - clean with subtle iridescence
  static const lightBackground = Color(0xFFF8F9FE); // crisp cool white with slight blue tint
  static const lightSurface = Color(0xFFFEFEFF); // pure white surface
  static const lightSurfaceVariant = Color(0xFFEEF1FF); // subtle purple tint
  static const lightTextPrimary = Color(0xFF191A2E); // near-black with blue undertone
  static const lightTextSecondary = Color(0xFF4E5080); // rich muted purple-gray
  static const lightBorder = Color(0xFFE0E3F5); // subtle lavender border

  // Dark Theme Neutrals - cyberpunk night shades
  static const darkBackground = Color(0xFF0A0B1E); // deep space background
  static const darkSurface = Color(0xFF151629); // rich navy surface
  static const darkSurfaceVariant = Color(0xFF232542); // elevated purple dark surface
  static const darkTextPrimary = Color(0xFFF8F9FF); // crisp white text
  static const darkTextSecondary = Color(0xFFC2C8E8); // soft lavender-gray text
  static const darkBorder = Color(0xFF3A3D60); // subtle indigo border

  // Gradient colors for futuristic effects
  static const gradientPurpleStart = Color(0xFF8224FF);
  static const gradientPurpleEnd = Color(0xFFB285FF);

  static const gradientTealStart = Color(0xFF00B3B5);
  static const gradientTealEnd = Color(0xFF00F5F8);

  static const gradientGoldStart = Color(0xFFE8A617);
  static const gradientGoldEnd = Color(0xFFFFC837);

  // Holographic gradient with vibrant colors
  static final holographicGradient = [
    const Color(0xFF3E7EFF), // blue
    const Color(0xFF8A4FFF), // purple
    const Color(0xFFD860FF), // pink-purple
    const Color(0xFFFF3E9A), // pink
  ];

  // Futuristic UI gradients - for backgrounds and cards
  static final cyberpunkGradient = [
    const Color(0xFF00ECEF), // cyber teal
    const Color(0xFF3E7EFF), // electric blue
    const Color(0xFF8A4FFF), // neon purple
  ];

  // Subtle tech gradients for cards
  static final lightGradient = [
    const Color(0xFFFFFFFF),
    const Color(0xFFF6F7FE),
  ];

  static final darkGradient = [
    const Color(0xFF1E2038),
    const Color(0xFF151629),
  ];

  // Modern card shadows - revised for depth
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

  // Neon glow effect for highlights
  static List<BoxShadow> getNeonGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withOpacity(0.6 * intensity),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withOpacity(0.3 * intensity),
          blurRadius: 24,
          spreadRadius: 2 * intensity,
        ),
      ];

  // Glass effect - for frosted glass components
  static Color glassEffect(bool isDark) => isDark
      ? const Color(0xFF191B31).withOpacity(0.7)
      : Colors.white.withOpacity(0.7);

  // Shimmer effect colors
  static Color shimmerBase(bool isDark) => isDark
      ? const Color(0xFF232537)
      : const Color(0xFFEEF1FF);

  static Color shimmerHighlight(bool isDark) => isDark
      ? const Color(0xFF3A3D60)
      : Colors.white;
}