// Enhanced typography styles
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class TugTextStyles {
  // Using a combination of Montserrat and Outfit for a premium feel
  // Montserrat for headings (strong, distinctive)
  // Outfit for body text (clean, modern, highly readable)

  static final _headingStyle = GoogleFonts.montserrat();
  static final _bodyStyle = GoogleFonts.outfit();

  // Display styles - more dramatic and eye-catching
  static final displayLarge = _headingStyle.copyWith(
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w700, // bolder
    letterSpacing: -0.5,
  );

  static final displayMedium = _headingStyle.copyWith(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  // Title styles - sharper and more distinctive
  static final titleLarge = _headingStyle.copyWith(
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  static final titleMedium = _headingStyle.copyWith(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
  );

  static final titleSmall = _headingStyle.copyWith(
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  // Body styles - more readable with better line spacing
  static final bodyLarge = _bodyStyle.copyWith(
    fontSize: 16,
    height: 1.6, // slightly more line height for better readability
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static final bodyMedium = _bodyStyle.copyWith(
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static final bodySmall = _bodyStyle.copyWith(
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  // Caption styles - elegant and refined
  static final caption = _bodyStyle.copyWith(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  // Button text - bold and confident
  static final button = _headingStyle.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600, // bolder for better visibility
    letterSpacing: 0.2, // slightly wider letter spacing for buttons
  );

  // Label text for chips, badges, etc.
  static final label = _bodyStyle.copyWith(
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // Helper function for colored text styles
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // Helper for setting emphasis
  static TextStyle emphasized(TextStyle base) {
    return base.copyWith(fontWeight: FontWeight.w600);
  }

  // Helper for setting de-emphasis
  static TextStyle deEmphasized(TextStyle base, {double opacity = 0.7}) {
    return base.copyWith(
      color: base.color?.withOpacity(opacity),
      fontWeight: FontWeight.w400,
    );
  }
}