// Updated buttons.dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class TugButtons {
  // Primary Button - more subtle shadow and rounded corners
  static final primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: TugColors.primaryPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: TugTextStyles.button,
    elevation: 0,
    shadowColor: TugColors.primaryPurple.withOpacity(0.3),
  ).copyWith(
    overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
  );

  // Secondary Button - refined outline
  static final secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: TugColors.primaryPurple,
    side: const BorderSide(color: TugColors.primaryPurple, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    textStyle: TugTextStyles.button,
  ).copyWith(
    overlayColor: MaterialStateProperty.all(TugColors.primaryPurple.withOpacity(0.05)),
  );

  // Text Button - cleaner
  static final textButtonStyle = TextButton.styleFrom(
    foregroundColor: TugColors.primaryPurple,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    textStyle: TugTextStyles.button,
  ).copyWith(
    overlayColor: MaterialStateProperty.all(TugColors.primaryPurple.withOpacity(0.05)),
  );

  // Icon Button - more subtle
  static final iconButtonStyle = IconButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: TugColors.primaryPurple,
    padding: const EdgeInsets.all(8),
  );

  // Disabled Button States
  static ButtonStyle disabledButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: TugColors.lightSurface,
    foregroundColor: TugColors.lightTextSecondary.withOpacity(0.5),
    elevation: 0,
  );
}