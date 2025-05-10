// Refined typography system with improved accessibility and visual hierarchy
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class TugTextStyles {
  // Using Inter and Poppins - modern, highly legible typefaces
  // Poppins for headings (geometric, distinctive)
  // Inter for body text (clean, modern, highly readable at all sizes)

  static final _headingStyle = GoogleFonts.poppins();
  static final _bodyStyle = GoogleFonts.inter();

  // Display styles - stronger visual impact with optimized letter spacing
  static final displayLarge = _headingStyle.copyWith(
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static final displayMedium = _headingStyle.copyWith(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static final displaySmall = _headingStyle.copyWith(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  // Title styles - improved weight contrast for better visual hierarchy
  static final titleLarge = _headingStyle.copyWith(
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static final titleMedium = _headingStyle.copyWith(
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static final titleSmall = _headingStyle.copyWith(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
  );

  // Body styles - optimized for better readability on both light and dark modes
  static final bodyLarge = _bodyStyle.copyWith(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
  );

  static final bodyMedium = _bodyStyle.copyWith(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static final bodySmall = _bodyStyle.copyWith(
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  // Caption styles - improved readability for small text
  static final caption = _bodyStyle.copyWith(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  // Button text - optimized for touch targets
  static final button = _headingStyle.copyWith(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // Label text for tags, chips, badges, etc.
  static final label = _bodyStyle.copyWith(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // New: Overline text for section headers
  static final overline = _bodyStyle.copyWith(
    fontSize: 11,
    height: 1.6,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    textBaseline: TextBaseline.alphabetic,
  );

  // Helper function for colored text styles
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // Enhanced text emphasis
  static TextStyle emphasized(TextStyle base) {
    return base.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: base.letterSpacing != null ? base.letterSpacing! - 0.1 : -0.1,
    );
  }

  // Helper for reduced emphasis
  static TextStyle deEmphasized(TextStyle base, {double opacity = 0.7}) {
    return base.copyWith(
      color: base.color?.withOpacity(opacity),
      fontWeight: FontWeight.w400,
    );
  }

  // New: Gradient text style
  static TextStyle gradientText(TextStyle base, {bool isDark = false}) {
    // Will be used with a shader in the widget
    return base.copyWith(
      foreground: Paint()
        ..shader = LinearGradient(
          colors: [
            TugColors.gradientPurpleStart,
            TugColors.gradientPurpleEnd,
          ],
        ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
    );
  }

  // New: Link text style
  static TextStyle link(TextStyle base, {bool isDark = false}) {
    return base.copyWith(
      color: isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple,
      decoration: TextDecoration.underline,
      decorationColor: isDark ? TugColors.primaryPurpleLight.withOpacity(0.5) : TugColors.primaryPurple.withOpacity(0.5),
      decorationThickness: 1.2,
    );
  }

  // New: Success text style
  static TextStyle success(TextStyle base) {
    return base.copyWith(color: TugColors.success);
  }

  // New: Error text style
  static TextStyle error(TextStyle base) {
    return base.copyWith(color: TugColors.error);
  }
}