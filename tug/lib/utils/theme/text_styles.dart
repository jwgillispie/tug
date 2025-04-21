// Updated text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TugTextStyles {
  // Using Inter for a modern, clean look
  static final _baseTextStyle = GoogleFonts.inter();

  // Display styles - more refined
  static final displayLarge = _baseTextStyle.copyWith(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  // Title styles - sharper
  static final titleLarge = _baseTextStyle.copyWith(
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );

  static final titleMedium = _baseTextStyle.copyWith(
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
  );

  // Body styles - more readable
  static final bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static final bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  // Caption styles - elegant
  static final caption = _baseTextStyle.copyWith(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  // Button text - crisp
  static final button = _baseTextStyle.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
}