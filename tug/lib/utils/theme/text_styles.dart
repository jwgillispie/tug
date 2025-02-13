
// lib/utils/theme/text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TugTextStyles {
  static final _baseTextStyle = GoogleFonts.inter();

  // Display styles
  static final displayLarge = _baseTextStyle.copyWith(
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  // Title styles
  static final titleLarge = _baseTextStyle.copyWith(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static final titleMedium = _baseTextStyle.copyWith(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );

  // Body styles
  static final bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static final bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  // Caption styles
  static final caption = _baseTextStyle.copyWith(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  // Button text
  static final button = _baseTextStyle.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
}
