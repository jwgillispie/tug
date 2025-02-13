
// lib/utils/theme/theme.dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

class TugTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: TugColors.primaryPurple,
      secondary: TugColors.secondaryTeal,
      surface: TugColors.lightSurface,
      background: TugColors.lightBackground,
      error: TugColors.error,
    ),
    scaffoldBackgroundColor: TugColors.lightBackground,
    textTheme: TextTheme(
      displayLarge: TugTextStyles.displayLarge,
      titleLarge: TugTextStyles.titleLarge,
      titleMedium: TugTextStyles.titleMedium,
      bodyLarge: TugTextStyles.bodyLarge,
      bodyMedium: TugTextStyles.bodyMedium,
      labelLarge: TugTextStyles.button,
    ),
    cardTheme: CardTheme(
      color: TugColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TugColors.lightBackground,
      foregroundColor: TugColors.lightTextPrimary,
      elevation: 0,
      titleTextStyle: TugTextStyles.titleLarge,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TugColors.lightBackground,
      selectedItemColor: TugColors.primaryPurple,
      unselectedItemColor: TugColors.lightTextSecondary,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: TugColors.primaryPurple,
      secondary: TugColors.secondaryTeal,
      surface: TugColors.darkSurface,
      background: TugColors.darkBackground,
      error: TugColors.error,
    ),
    scaffoldBackgroundColor: TugColors.darkBackground,
    textTheme: TextTheme(
      displayLarge: TugTextStyles.displayLarge.copyWith(color: TugColors.darkTextPrimary),
      titleLarge: TugTextStyles.titleLarge.copyWith(color: TugColors.darkTextPrimary),
      titleMedium: TugTextStyles.titleMedium.copyWith(color: TugColors.darkTextPrimary),
      bodyLarge: TugTextStyles.bodyLarge.copyWith(color: TugColors.darkTextPrimary),
      bodyMedium: TugTextStyles.bodyMedium.copyWith(color: TugColors.darkTextPrimary),
      labelLarge: TugTextStyles.button.copyWith(color: TugColors.darkTextPrimary),
    ),
    cardTheme: CardTheme(
      color: TugColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TugColors.darkBackground,
      foregroundColor: TugColors.darkTextPrimary,
      elevation: 0,
      titleTextStyle: TugTextStyles.titleLarge.copyWith(color: TugColors.darkTextPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TugColors.darkBackground,
      selectedItemColor: TugColors.primaryPurple,
      unselectedItemColor: TugColors.darkTextSecondary,
    ),
  );
}