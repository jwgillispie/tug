// Ultra-modern colors with immersive cosmic palette for spectacular visual impact
import 'package:flutter/material.dart';

class TugColors {
  // Primary Colors - vibrant cosmic spectrum
  static const primaryPurple = Color(0xFF9D34FF); // electric vibrant purple
  static const primaryPurpleDark = Color(0xFF7000E0); // deep cosmic purple for contrast
  static const primaryPurpleLight = Color(0xFFBE7DFF); // radiant lavender for highlights

  // Secondary colors - spectral energy palette
  static const secondaryTeal = Color(0xFF00F7FF); // brilliant cyan that pops
  static const secondaryTealDark = Color(0xFF00C2FF); // deep electric blue for depth
  static const tertiaryGold = Color(0xFFFFD000); // brilliant gold with higher saturation

  // Accent Colors - expanded celestial palette
  static const accentBlue = Color(0xFF2D6CFF); // vibrant ultramarine blue
  static const accentPink = Color(0xFFFF2D8E); // electric hot pink for emotion
  static const accentOrange = Color(0xFFFF6B1F); // vivid tangerine orange
  static const accentGreen = Color(0xFF0DFFC2); // energetic aqua green
  static const accentPurple = Color(0xFFE545FF); // brilliant magenta purple

  // Achievement type colors - heightened spectral impact
  static const streakOrange = Color(0xFFFF5F00); // intense fiery orange for streaks
  static const balanceBlue = Color(0xFF0091FF); // dynamic azure blue for balance
  static const frequencyGreen = Color(0xFF00FFB8); // high-energy turquoise for frequency
  static const milestoneRed = Color(0xFFFF2D6C); // vibrant ruby red for milestones
  static const specialPurple = Color(0xFFE545FF); // electric magenta for special achievements

  // Status Colors - highly visible with enhanced accessibility
  static const success = Color(0xFF00E676); // vibrant emerald success green
  static const warning = Color(0xFFFFCC00); // intense amber for warnings
  static const error = Color(0xFFFF2D55); // brilliant crimson for errors
  static const info = Color(0xFF2D95FF); // clear sapphire blue for information

  // Light Theme Neutrals - crystalline with aurora iridescence
  static const lightBackground = Color(0xFFF9FAFF); // pristine ice-white with subtle blue aura
  static const lightSurface = Color(0xFFFFFFFF); // pure absolute white for surfaces
  static const lightSurfaceVariant = Color(0xFFF2F5FF); // delicate blue-tinted white for depth
  static const lightTextPrimary = Color(0xFF14153A); // deep indigo-black for contrast
  static const lightTextSecondary = Color(0xFF4D4DB8); // vibrant cosmic indigo for secondary text
  static const lightBorder = Color(0xFFE0E8FF); // celestial blue-white border

  // Dark Theme Neutrals - deep space with nebula undertones
  static const darkBackground = Color(0xFF070825); // abyssal deep space background
  static const darkSurface = Color(0xFF121336); // rich cosmic indigo surface
  static const darkSurfaceVariant = Color(0xFF1B1F4E); // elevated nebula surface
  static const darkTextPrimary = Color(0xFFFAFCFF); // brilliant starlight white text
  static const darkTextSecondary = Color(0xFFCED3FF); // cosmic blue-white for secondary text
  static const darkBorder = Color(0xFF363D8C); // glowing nebula border

  // Gradient colors for spectacular visual effects
  static const gradientPurpleStart = Color(0xFF7000E0);
  static const gradientPurpleEnd = Color(0xFFBE7DFF);

  static const gradientTealStart = Color(0xFF00C2FF);
  static const gradientTealEnd = Color(0xFF00F7FF);

  static const gradientGoldStart = Color(0xFFFF9D00);
  static const gradientGoldEnd = Color(0xFFFFD000);
  
  // New additional gradients for variety
  static const gradientPinkStart = Color(0xFFFF2D6C);
  static const gradientPinkEnd = Color(0xFFFF90BD);
  
  static const gradientBlueStart = Color(0xFF2D6CFF);
  static const gradientBlueEnd = Color(0xFF90C8FF);

  // Spectacular holographic gradient with enhanced vibrancy
  static final holographicGradient = [
    const Color(0xFF2D95FF), // electric blue
    const Color(0xFF9D34FF), // vibrant purple
    const Color(0xFFE545FF), // brilliant magenta
    const Color(0xFFFF2D8E), // hot pink
  ];

  // Aurora borealis inspired UI gradients
  static final auroraGradient = [
    const Color(0xFF00F7FF), // brilliant cyan
    const Color(0xFF2D6CFF), // deep blue
    const Color(0xFF9D34FF), // vibrant purple
    const Color(0xFFE545FF), // magenta
  ];
  
  // Cosmic nebula inspired gradient
  static final nebulaGradient = [
    const Color(0xFF0DFFC2), // aqua green
    const Color(0xFF00C2FF), // bright blue
    const Color(0xFF9D34FF), // vibrant purple
    const Color(0xFFE545FF), // magenta
  ];

  // Subtle crystalline gradients for cards and surfaces
  static final lightGradient = [
    const Color(0xFFFFFFFF),
    const Color(0xFFF2F5FF),
  ];

  static final darkGradient = [
    const Color(0xFF121336),
    const Color(0xFF070825),
  ];
  
  // Dynamic ambient gradients for backgrounds
  static final lightAmbientGradient = [
    const Color(0xFFFFFFFF),
    const Color(0xFFF2F5FF),
    const Color(0xFFEFEFFF),
    const Color(0xFFE6EBFF),
  ];
  
  static final darkAmbientGradient = [
    const Color(0xFF070825),
    const Color(0xFF0A0D35),
    const Color(0xFF121336),
    const Color(0xFF1B1F4E),
  ];

  // Enhanced depth shadows with atmospheric light diffusion
  static List<BoxShadow> getShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.45)
              : const Color(0xFF7D98FF).withOpacity(0.22),
          offset: const Offset(0, 6),
          blurRadius: 24,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark
              ? primaryPurple.withOpacity(0.08)
              : primaryPurple.withOpacity(0.05),
          offset: const Offset(0, 2),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  // Spectacular neon glow effect with enhanced luminosity
  static List<BoxShadow> getNeonGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withOpacity(0.7 * intensity),
          blurRadius: 10,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: color.withOpacity(0.4 * intensity),
          blurRadius: 32,
          spreadRadius: 2 * intensity,
        ),
      ];
      
  // Ultra glow for special elements with extreme brightness
  static List<BoxShadow> getUltraGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withOpacity(0.8 * intensity),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: color.withOpacity(0.5 * intensity),
          blurRadius: 24,
          spreadRadius: 3 * intensity,
        ),
        BoxShadow(
          color: color.withOpacity(0.3 * intensity),
          blurRadius: 40,
          spreadRadius: 4 * intensity,
        ),
      ];

  // Enhanced glass effect with improved translucency
  static Color glassEffect(bool isDark) => isDark
      ? const Color(0xFF151A44).withOpacity(0.75)
      : Colors.white.withOpacity(0.75);
      
  // Better blur parameters for backdrop filters (use with glassEffect)
  static double glassBlurRadius(bool isDark) => isDark ? 15.0 : 10.0;
      
  // Advanced glass border colors
  static Color glassBorder(bool isDark) => isDark
      ? Colors.white.withOpacity(0.15)
      : Colors.white.withOpacity(0.5);

  // Enhanced shimmer effect colors with better contrast
  static Color shimmerBase(bool isDark) => isDark
      ? const Color(0xFF1B1F4E) // deeper nebula base
      : const Color(0xFFE6EBFF); // crystalline blue base

  static Color shimmerHighlight(bool isDark) => isDark
      ? const Color(0xFF363D8C) // bright cosmic highlight
      : Colors.white; // pure white highlight
  
  // New cosmic particle effects for special UI elements
  static Color cosmicDustColor(bool isDark) => isDark
      ? const Color(0xFFE545FF).withOpacity(0.7) // bright nebula dust
      : const Color(0xFF9D34FF).withOpacity(0.4); // cosmic purple particles
      
  // Additional gradient constructors for common use cases
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
  
  static LinearGradient getSecondaryGradient({bool vertical = false, bool reversed = false}) {
    final List<Color> colors = reversed 
        ? [gradientTealEnd, gradientTealStart]
        : [gradientTealStart, gradientTealEnd];
        
    return LinearGradient(
      colors: colors,
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    );
  }
  
  // Radial gradient for cosmic effects
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
  
  // Sweeping cosmic gradient for circular progress indicators and radial elements
  static SweepGradient getCosmicSweepGradient(List<Color> colors) {
    return SweepGradient(
      colors: colors,
      stops: List.generate(colors.length, (index) => index / (colors.length - 1)),
      startAngle: 0,
      endAngle: 2 * 3.14159,
    );
  }
}