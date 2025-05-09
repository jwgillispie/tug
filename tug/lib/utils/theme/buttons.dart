// Enhanced buttons.dart with modern styling
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class TugButtons {
  // Primary Button - fresh design with subtle gradient and shadow
  static ButtonStyle primaryButtonStyle({bool isDark = false}) => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    elevation: 4,
    shadowColor: TugColors.primaryPurple.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ).copyWith(
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.pressed)) {
        return TugColors.primaryPurpleDark;
      }
      return TugColors.primaryPurple;
    }),
    overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
    elevation: MaterialStateProperty.resolveWith<double>((states) {
      if (states.contains(MaterialState.pressed)) {
        return 2;
      }
      return 4;
    }),
  );

  // Secondary Button - refined outline with animated hover effect
  static ButtonStyle secondaryButtonStyle({bool isDark = false}) => OutlinedButton.styleFrom(
    foregroundColor: TugColors.primaryPurple,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    side: const BorderSide(color: TugColors.primaryPurple, width: 1.5),
    backgroundColor: isDark
        ? TugColors.darkSurface.withOpacity(0.7)
        : Colors.white.withOpacity(0.9),
  ).copyWith(
    overlayColor: MaterialStateProperty.all(
        TugColors.primaryPurple.withOpacity(0.05)),
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.hovered)) {
        return TugColors.primaryPurple.withOpacity(0.04);
      }
      if (states.contains(MaterialState.pressed)) {
        return TugColors.primaryPurple.withOpacity(0.08);
      }
      return isDark
          ? TugColors.darkSurface.withOpacity(0.7)
          : Colors.white.withOpacity(0.9);
    }),
  );

  // Tertiary Button - Clean appearance for less important actions
  static ButtonStyle tertiaryButtonStyle({bool isDark = false}) => TextButton.styleFrom(
    foregroundColor: isDark
        ? TugColors.primaryPurpleLight
        : TugColors.primaryPurple,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    backgroundColor: Colors.transparent,
  ).copyWith(
    overlayColor: MaterialStateProperty.all(
        TugColors.primaryPurple.withOpacity(0.05)),
    foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.pressed)) {
        return isDark
            ? TugColors.primaryPurpleLight.withOpacity(0.8)
            : TugColors.primaryPurpleDark;
      }
      return isDark
          ? TugColors.primaryPurpleLight
          : TugColors.primaryPurple;
    }),
  );

  // Icon Button - with background hover effect
  static ButtonStyle iconButtonStyle({bool isDark = false}) => IconButton.styleFrom(
    foregroundColor: isDark
        ? TugColors.darkTextPrimary
        : TugColors.primaryPurple,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.all(12),
    shape: const CircleBorder(),
  ).copyWith(
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.hovered)) {
        return isDark
            ? TugColors.darkSurfaceVariant.withOpacity(0.5)
            : TugColors.lightSurfaceVariant.withOpacity(0.5);
      }
      if (states.contains(MaterialState.pressed)) {
        return isDark
            ? TugColors.darkSurfaceVariant.withOpacity(0.7)
            : TugColors.lightSurfaceVariant.withOpacity(0.7);
      }
      return Colors.transparent;
    }),
  );

  // Disabled Button States
  static ButtonStyle disabledButtonStyle({bool isDark = false}) => ElevatedButton.styleFrom(
    backgroundColor: isDark
        ? TugColors.darkSurfaceVariant.withOpacity(0.5)
        : TugColors.lightSurfaceVariant.withOpacity(0.7),
    foregroundColor: isDark
        ? TugColors.darkTextSecondary.withOpacity(0.5)
        : TugColors.lightTextSecondary.withOpacity(0.5),
    elevation: 0,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Action Button with Icon - combines icon and text
  static ButtonStyle actionButtonStyle({bool isDark = false}) => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: TugColors.secondaryTeal,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    elevation: 3,
    shadowColor: TugColors.secondaryTeal.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ).copyWith(
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.pressed)) {
        return TugColors.secondaryTealDark;
      }
      return TugColors.secondaryTeal;
    }),
  );

  // Small button for compact spaces
  static ButtonStyle smallButtonStyle({bool isDark = false}) => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: TugColors.primaryPurple,
    textStyle: TugTextStyles.button.copyWith(fontSize: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    minimumSize: const Size(60, 32),
    elevation: 2,
    shadowColor: TugColors.primaryPurple.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ).copyWith(
    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.pressed)) {
        return TugColors.primaryPurpleDark;
      }
      return TugColors.primaryPurple;
    }),
  );
}