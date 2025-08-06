// Enhanced buttons.dart with modern styling and improved interaction states
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class TugButtons {
  // Primary Button - bold design with gradient and elevation effects
  static ButtonStyle primaryButtonStyle({bool isDark = false, bool isViceMode = false}) => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    elevation: 4,
    shadowColor: TugColors.getPrimaryColor(isViceMode).withValues(alpha: 0.4),
    minimumSize: const Size(88, 48), // Ensure touch-friendly size
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkSurfaceVariant.withOpacity(0.6)
            : TugColors.lightSurfaceVariant.withOpacity(0.7);
      }
      final primaryColor = TugColors.getPrimaryColor(isViceMode);
      final primaryDarkColor = isViceMode ? TugColors.viceGreenDark : TugColors.primaryPurpleDark;
      
      if (states.contains(WidgetState.pressed)) {
        return primaryDarkColor;
      }
      if (states.contains(WidgetState.hovered)) {
        return Color.lerp(primaryColor, primaryDarkColor, 0.3) ?? primaryColor;
      }
      return primaryColor;
    }),
    overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
      return Colors.white.withOpacity(0.12);
    }),
    elevation: WidgetStateProperty.resolveWith<double>((states) {
      if (states.contains(WidgetState.disabled)) {
        return 0;
      }
      if (states.contains(WidgetState.pressed)) {
        return 2;
      }
      if (states.contains(WidgetState.hovered)) {
        return 5;
      }
      return 4;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkTextSecondary.withOpacity(0.5)
            : TugColors.lightTextSecondary.withOpacity(0.5);
      }
      return Colors.white;
    }),
    // Add subtle animation to padding when pressed
    padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>((states) {
      if (states.contains(WidgetState.pressed)) {
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(top: 17, bottom: 15);
      }
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }),
  );

  // Secondary Button - refined outline with improved hover and focus states
  static ButtonStyle secondaryButtonStyle({bool isDark = false, bool isViceMode = false}) => OutlinedButton.styleFrom(
    foregroundColor: isDark 
        ? (isViceMode ? TugColors.viceGreen : TugColors.primaryPurpleLight)
        : TugColors.getPrimaryColor(isViceMode),
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    minimumSize: const Size(88, 48), // Ensure touch-friendly size
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    side: BorderSide(
      color: isDark 
          ? (isViceMode ? TugColors.viceGreen : TugColors.primaryPurpleLight)
          : TugColors.getPrimaryColor(isViceMode),
      width: 1.5
    ),
    backgroundColor: Colors.transparent,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
      final baseColor = isDark 
          ? (isViceMode ? TugColors.viceGreen : TugColors.primaryPurpleLight)
          : TugColors.getPrimaryColor(isViceMode);
      if (states.contains(WidgetState.pressed)) {
        return baseColor.withValues(alpha: 0.12);
      }
      return baseColor.withValues(alpha: 0.08);
    }),
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.transparent;
      }
      if (states.contains(WidgetState.hovered)) {
        final baseColor = isDark 
            ? (isViceMode ? TugColors.viceGreen : TugColors.primaryPurpleLight)
            : TugColors.getPrimaryColor(isViceMode);
        return baseColor.withValues(alpha: 0.05);
      }
      if (states.contains(WidgetState.pressed)) {
        final baseColor = isDark 
            ? (isViceMode ? TugColors.viceGreen : TugColors.primaryPurpleLight)
            : TugColors.getPrimaryColor(isViceMode);
        return baseColor.withValues(alpha: 0.1);
      }
      return Colors.transparent;
    }),
    side: WidgetStateProperty.resolveWith<BorderSide>((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(
          color: isDark
              ? TugColors.darkTextSecondary.withOpacity(0.3)
              : TugColors.lightTextSecondary.withOpacity(0.3),
          width: 1.5,
        );
      }
      final baseColor = isDark 
          ? (isViceMode ? TugColors.viceGreen : TugColors.primaryPurpleLight)
          : TugColors.getPrimaryColor(isViceMode);
      if (states.contains(WidgetState.pressed)) {
        return BorderSide(color: baseColor, width: 2.0);
      }
      if (states.contains(WidgetState.hovered)) {
        return BorderSide(color: baseColor, width: 1.75);
      }
      return BorderSide(color: baseColor, width: 1.5);
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkTextSecondary.withOpacity(0.5)
            : TugColors.lightTextSecondary.withOpacity(0.5);
      }
      final baseColor = isDark 
          ? (isViceMode ? TugColors.viceGreen : TugColors.primaryPurpleLight)
          : TugColors.getPrimaryColor(isViceMode);
      if (states.contains(WidgetState.pressed)) {
        return baseColor.withValues(alpha: 0.9);
      }
      return baseColor;
    }),
    // Add subtle animation to padding when pressed
    padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>((states) {
      if (states.contains(WidgetState.pressed)) {
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(top: 17, bottom: 15);
      }
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }),
  );

  // Tertiary Button - Clean appearance with improved touch feedback
  static ButtonStyle tertiaryButtonStyle({bool isDark = false}) => TextButton.styleFrom(
    foregroundColor: isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    minimumSize: const Size(44, 36), // Smaller but still finger-friendly
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    backgroundColor: Colors.transparent,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
      final baseColor = isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple;
      if (states.contains(WidgetState.pressed)) {
        return baseColor.withOpacity(0.12);
      }
      return baseColor.withOpacity(0.06);
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkTextSecondary.withOpacity(0.4)
            : TugColors.lightTextSecondary.withOpacity(0.4);
      }
      final baseColor = isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple;
      if (states.contains(WidgetState.pressed)) {
        return baseColor.withOpacity(0.8);
      }
      if (states.contains(WidgetState.hovered)) {
        Color hoverColor = Color.lerp(baseColor, isDark ? Colors.white : Colors.black, 0.1) ?? baseColor;
        return hoverColor;
      }
      return baseColor;
    }),
    padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>((states) {
      if (states.contains(WidgetState.pressed)) {
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10).copyWith(top: 11, bottom: 9);
      }
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    }),
  );

  // Icon Button - with improved touch response and visual feedback
  static ButtonStyle iconButtonStyle({bool isDark = false}) => IconButton.styleFrom(
    foregroundColor: isDark ? TugColors.darkTextPrimary : TugColors.primaryPurple,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.all(12),
    minimumSize: const Size(44, 44), // Ensure touch-friendly size
    shape: const CircleBorder(),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return Colors.transparent;
      }
      if (states.contains(WidgetState.hovered)) {
        return isDark
            ? TugColors.darkSurfaceVariant.withOpacity(0.6)
            : TugColors.lightSurfaceVariant.withOpacity(0.6);
      }
      if (states.contains(WidgetState.pressed)) {
        return isDark
            ? TugColors.darkSurfaceVariant.withOpacity(0.8)
            : TugColors.lightSurfaceVariant.withOpacity(0.8);
      }
      return Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkTextSecondary.withOpacity(0.4)
            : TugColors.lightTextSecondary.withOpacity(0.4);
      }
      final baseColor = isDark ? TugColors.darkTextPrimary : TugColors.primaryPurple;
      if (states.contains(WidgetState.pressed)) {
        return isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurpleDark;
      }
      return baseColor;
    }),
    overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
      final baseColor = isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple;
      return baseColor.withOpacity(0.05);
    }),
    // Add slight scale effect when pressed
    iconSize: WidgetStateProperty.resolveWith<double?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return 22;
      }
      return 24;
    }),
  );

  // Action Button with Icon - enhanced with better feedback
  static ButtonStyle actionButtonStyle({bool isDark = false}) => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: TugColors.success,
    textStyle: TugTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    elevation: 3,
    shadowColor: TugColors.success.withValues(alpha: 0.4),
    minimumSize: const Size(88, 48), // Ensure touch-friendly size
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkSurfaceVariant.withOpacity(0.6)
            : TugColors.lightSurfaceVariant.withOpacity(0.7);
      }
      if (states.contains(WidgetState.pressed)) {
        return TugColors.primaryPurpleDark;
      }
      if (states.contains(WidgetState.hovered)) {
        return Color.lerp(TugColors.success, TugColors.primaryPurpleDark, 0.3) ?? TugColors.success;
      }
      return TugColors.success;
    }),
    overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
      return Colors.white.withOpacity(0.1);
    }),
    elevation: WidgetStateProperty.resolveWith<double>((states) {
      if (states.contains(WidgetState.disabled)) {
        return 0;
      }
      if (states.contains(WidgetState.pressed)) {
        return 1;
      }
      if (states.contains(WidgetState.hovered)) {
        return 4;
      }
      return 3;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkTextSecondary.withOpacity(0.5)
            : TugColors.lightTextSecondary.withOpacity(0.5);
      }
      return Colors.white;
    }),
    padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>((states) {
      if (states.contains(WidgetState.pressed)) {
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14).copyWith(top: 15, bottom: 13);
      }
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }),
  );

  // Small button for compact spaces - enhanced touch
  static ButtonStyle smallButtonStyle({bool isDark = false}) => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: TugColors.primaryPurple,
    textStyle: TugTextStyles.button.copyWith(fontSize: 13),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    minimumSize: const Size(60, 32),
    elevation: 2,
    shadowColor: TugColors.primaryPurple.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkSurfaceVariant.withOpacity(0.6)
            : TugColors.lightSurfaceVariant.withOpacity(0.7);
      }
      if (states.contains(WidgetState.pressed)) {
        return TugColors.primaryPurpleDark;
      }
      return TugColors.primaryPurple;
    }),
    overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
      return Colors.white.withOpacity(0.12);
    }),
    elevation: WidgetStateProperty.resolveWith<double>((states) {
      if (states.contains(WidgetState.disabled)) {
        return 0;
      }
      if (states.contains(WidgetState.pressed)) {
        return 1;
      }
      return 2;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark
            ? TugColors.darkTextSecondary.withOpacity(0.5)
            : TugColors.lightTextSecondary.withOpacity(0.5);
      }
      return Colors.white;
    }),
  );

  // New: Gradient Button - eye-catching with gradient background
  static ButtonStyle gradientButtonStyle({bool isDark = false}) {
    // Note: The gradient itself will need to be applied via a Container in the button's child
    return ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      textStyle: TugTextStyles.button.copyWith(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      elevation: 4,
      shadowColor: TugColors.primaryPurple.withOpacity(0.5),
      minimumSize: const Size(88, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      backgroundColor: Colors.transparent, // This will be overridden by the gradient
    ).copyWith(
      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.disabled)) {
          return 0;
        }
        if (states.contains(WidgetState.pressed)) {
          return 2;
        }
        if (states.contains(WidgetState.hovered)) {
          return 5;
        }
        return 4;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark
              ? TugColors.darkTextSecondary.withOpacity(0.5)
              : TugColors.lightTextSecondary.withOpacity(0.5);
        }
        return Colors.white;
      }),
      // Add subtle animation to padding when pressed
      padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>((states) {
        if (states.contains(WidgetState.pressed)) {
          return const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(top: 17, bottom: 15);
        }
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      }),
    );
  }

  // New: Chip Button - for tags and filter options
  static ButtonStyle chipButtonStyle({
    bool isDark = false,
    bool isSelected = false,
    Color? color,
  }) {
    final buttonColor = color ?? (isDark ? TugColors.primaryPurpleLight : TugColors.primaryPurple);

    return ElevatedButton.styleFrom(
      foregroundColor: isSelected ? Colors.white : buttonColor,
      backgroundColor: isSelected ? buttonColor : Colors.transparent,
      textStyle: TugTextStyles.label.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      minimumSize: const Size(20, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? buttonColor : buttonColor.withOpacity(0.6),
          width: 1.0,
        ),
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark
              ? TugColors.darkSurfaceVariant.withOpacity(0.3)
              : TugColors.lightSurfaceVariant.withOpacity(0.3);
        }
        if (isSelected) {
          if (states.contains(WidgetState.pressed)) {
            return buttonColor.withOpacity(0.8);
          }
          return buttonColor;
        } else {
          if (states.contains(WidgetState.pressed)) {
            return buttonColor.withOpacity(0.15);
          }
          if (states.contains(WidgetState.hovered)) {
            return buttonColor.withOpacity(0.08);
          }
          return Colors.transparent;
        }
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark
              ? TugColors.darkTextSecondary.withOpacity(0.4)
              : TugColors.lightTextSecondary.withOpacity(0.4);
        }
        if (isSelected) {
          return Colors.white;
        } else {
          if (states.contains(WidgetState.pressed)) {
            return buttonColor.withOpacity(0.9);
          }
          return buttonColor;
        }
      }),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        if (states.contains(WidgetState.disabled)) {
          final disabledColor = isDark
              ? TugColors.darkTextSecondary.withOpacity(0.3)
              : TugColors.lightTextSecondary.withOpacity(0.3);
          return BorderSide(color: disabledColor, width: 1.0);
        }
        if (isSelected) {
          return BorderSide(color: buttonColor, width: 1.0);
        } else {
          if (states.contains(WidgetState.pressed)) {
            return BorderSide(color: buttonColor.withOpacity(0.9), width: 1.5);
          }
          if (states.contains(WidgetState.hovered)) {
            return BorderSide(color: buttonColor.withOpacity(0.8), width: 1.2);
          }
          return BorderSide(color: buttonColor.withOpacity(0.6), width: 1.0);
        }
      }),
    );
  }

  // New: FAB Style - for floating action buttons
  static FloatingActionButtonThemeData fabTheme({bool isDark = false}) => FloatingActionButtonThemeData(
    backgroundColor: TugColors.primaryPurple,
    foregroundColor: Colors.white,
    elevation: 6,
    focusElevation: 8,
    hoverElevation: 8,
    // Removed deprecated splashColor property
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    sizeConstraints: const BoxConstraints.tightFor(
      width: 56.0,
      height: 56.0,
    ),
    smallSizeConstraints: const BoxConstraints.tightFor(
      width: 40.0,
      height: 40.0,
    ),
    extendedSizeConstraints: const BoxConstraints(
      minWidth: 80.0,
      maxWidth: 328.0,
      minHeight: 56.0,
      maxHeight: 56.0,
    ),
    extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    extendedTextStyle: TugTextStyles.button.copyWith(color: Colors.white),
  );
}