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
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: TugColors.lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      titleTextStyle: TugTextStyles.titleLarge,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: TugColors.primaryPurple,
      unselectedItemColor: TugColors.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TugColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: TugColors.lightBorder,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: TugColors.primaryPurple,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.withOpacity(0.15), 
      thickness: 1,
      space: 32,
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
      onBackground: TugColors.darkTextPrimary,
      onSurface: TugColors.darkTextPrimary,
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
        side: BorderSide(
          color: Colors.white.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TugColors.darkSurface,
      foregroundColor: TugColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      titleTextStyle: TugTextStyles.titleLarge.copyWith(color: TugColors.darkTextPrimary),
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: TugColors.darkSurface,
      selectedItemColor: TugColors.primaryPurple,
      unselectedItemColor: TugColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: TugColors.darkBorder,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: TugColors.primaryPurple,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.1), 
      thickness: 1,
      space: 32,
    ),
    iconTheme: IconThemeData(
      color: TugColors.darkTextPrimary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TugColors.primaryPurple;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TugColors.primaryPurple.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),
  );
}