// Enhanced theme.dart with beautiful Material Design 3 styling
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';
import 'buttons.dart';

class TugTheme {
  // Elegant light theme with enhanced visual hierarchy
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      // Primary colors
      primary: TugColors.primaryPurple,
      onPrimary: Colors.white,
      primaryContainer: TugColors.primaryPurpleLight.withOpacity(0.2),
      onPrimaryContainer: TugColors.primaryPurpleDark,

      // Secondary colors
      secondary: TugColors.secondaryTeal,
      onSecondary: Colors.white,
      secondaryContainer: TugColors.secondaryTeal.withOpacity(0.15),
      onSecondaryContainer: TugColors.secondaryTealDark,

      // Surface colors
      surface: TugColors.lightSurface,
      onSurface: TugColors.lightTextPrimary,
      surfaceContainerHighest: TugColors.lightSurfaceVariant,
      onSurfaceVariant: TugColors.lightTextSecondary,

      // Other colors
      error: TugColors.error,
      outline: TugColors.lightBorder,
      outlineVariant: TugColors.lightBorder.withOpacity(0.5),

      // Add tertiary color
      tertiary: TugColors.tertiaryGold,
      onTertiary: Colors.white,
      tertiaryContainer: TugColors.tertiaryGold.withOpacity(0.15),
      onTertiaryContainer: Color.lerp(TugColors.tertiaryGold, Colors.black, 0.5) ?? Colors.brown,
    ),

    // Set background color
    scaffoldBackgroundColor: TugColors.lightBackground,

    // Typography system
    textTheme: TextTheme(
      displayLarge: TugTextStyles.displayLarge,
      displayMedium: TugTextStyles.displayMedium,
      titleLarge: TugTextStyles.titleLarge,
      titleMedium: TugTextStyles.titleMedium,
      titleSmall: TugTextStyles.titleSmall,
      bodyLarge: TugTextStyles.bodyLarge,
      bodyMedium: TugTextStyles.bodyMedium,
      bodySmall: TugTextStyles.bodySmall,
      labelLarge: TugTextStyles.button,
      labelMedium: TugTextStyles.label,
    ),

    // Enhanced card styling
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: TugColors.primaryPurple.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),

    // Modern app bar
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: TugColors.lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: TugColors.primaryPurple.withOpacity(0.1),
      titleTextStyle: TugTextStyles.titleLarge,
      centerTitle: false,
      toolbarHeight: 64,
      shape: Border(
        bottom: BorderSide(
          color: Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
    ),

    // Distinctive bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: TugColors.primaryPurple,
      unselectedItemColor: TugColors.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: TugTextStyles.label.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TugTextStyles.label,
      selectedIconTheme: const IconThemeData(size: 24),
      unselectedIconTheme: const IconThemeData(size: 22),
    ),

    // Refined input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TugColors.lightSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: TugColors.lightBorder,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: TugColors.primaryPurple,
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TugTextStyles.bodyMedium.copyWith(color: TugColors.lightTextSecondary),
      hintStyle: TugTextStyles.bodyMedium.copyWith(color: TugColors.lightTextSecondary.withOpacity(0.7)),
      prefixIconColor: TugColors.primaryPurple,
      suffixIconColor: TugColors.lightTextSecondary,
      floatingLabelStyle: TugTextStyles.bodyMedium.copyWith(color: TugColors.primaryPurple),
    ),

    // Divider for clear visual separation
    dividerTheme: DividerThemeData(
      color: Colors.grey.withOpacity(0.12),
      thickness: 1,
      space: 32,
      indent: 0,
      endIndent: 0,
    ),

    // Elevated button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: TugButtons.primaryButtonStyle(isDark: false),
    ),

    // Outlined button styling
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: TugButtons.secondaryButtonStyle(isDark: false),
    ),

    // Text button styling
    textButtonTheme: TextButtonThemeData(
      style: TugButtons.tertiaryButtonStyle(isDark: false),
    ),

    // Icon button styling
    iconButtonTheme: IconButtonThemeData(
      style: TugButtons.iconButtonStyle(isDark: false),
    ),

    // Chip theme for tags and filters
    chipTheme: ChipThemeData(
      backgroundColor: TugColors.lightSurfaceVariant,
      selectedColor: TugColors.primaryPurple.withOpacity(0.2),
      disabledColor: Colors.grey.withOpacity(0.1),
      labelStyle: TugTextStyles.bodySmall,
      secondaryLabelStyle: TugTextStyles.bodySmall.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      side: BorderSide(
        width: 1,
        color: Colors.black.withOpacity(0.05),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),

    // Tab bar theme for consistent navigation
    tabBarTheme: TabBarTheme(
      labelColor: TugColors.primaryPurple,
      unselectedLabelColor: TugColors.lightTextSecondary,
      indicatorColor: TugColors.primaryPurple,
      labelStyle: TugTextStyles.button,
      unselectedLabelStyle: TugTextStyles.button.copyWith(fontWeight: FontWeight.normal),
      indicatorSize: TabBarIndicatorSize.label,
    ),

    // Snackbar theme for notifications
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TugColors.darkSurface,
      contentTextStyle: TugTextStyles.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      actionTextColor: TugColors.primaryPurpleLight,
    ),

    // Dialog theme for pop-ups
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: TugTextStyles.titleMedium,
      contentTextStyle: TugTextStyles.bodyMedium,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TugColors.primaryPurple,
      circularTrackColor: Colors.transparent,
      linearTrackColor: Colors.grey,
    ),
  );

  // Sophisticated dark theme with rich color palette
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      // Primary colors
      primary: TugColors.primaryPurple,
      onPrimary: Colors.white,
      primaryContainer: TugColors.primaryPurple.withOpacity(0.2),
      onPrimaryContainer: TugColors.primaryPurpleLight,

      // Secondary colors
      secondary: TugColors.secondaryTeal,
      onSecondary: Colors.white,
      secondaryContainer: TugColors.secondaryTeal.withOpacity(0.15),
      onSecondaryContainer: TugColors.secondaryTeal.withOpacity(0.8),

      // Surface colors
      surface: TugColors.darkSurface,
      onSurface: TugColors.darkTextPrimary,
      surfaceContainerHighest: TugColors.darkSurfaceVariant,
      onSurfaceVariant: TugColors.darkTextSecondary,

      // Other colors
      error: TugColors.error,
      outline: TugColors.darkBorder,
      outlineVariant: TugColors.darkBorder.withOpacity(0.3),

      // Add tertiary color
      tertiary: TugColors.tertiaryGold,
      onTertiary: Colors.black,
      tertiaryContainer: TugColors.tertiaryGold.withOpacity(0.15),
      onTertiaryContainer: TugColors.tertiaryGold,
    ),

    // Set background color
    scaffoldBackgroundColor: TugColors.darkBackground,

    // Typography system
    textTheme: TextTheme(
      displayLarge: TugTextStyles.displayLarge.copyWith(color: TugColors.darkTextPrimary),
      displayMedium: TugTextStyles.displayMedium.copyWith(color: TugColors.darkTextPrimary),
      titleLarge: TugTextStyles.titleLarge.copyWith(color: TugColors.darkTextPrimary),
      titleMedium: TugTextStyles.titleMedium.copyWith(color: TugColors.darkTextPrimary),
      titleSmall: TugTextStyles.titleSmall.copyWith(color: TugColors.darkTextPrimary),
      bodyLarge: TugTextStyles.bodyLarge.copyWith(color: TugColors.darkTextPrimary),
      bodyMedium: TugTextStyles.bodyMedium.copyWith(color: TugColors.darkTextPrimary),
      bodySmall: TugTextStyles.bodySmall.copyWith(color: TugColors.darkTextSecondary),
      labelLarge: TugTextStyles.button.copyWith(color: TugColors.darkTextPrimary),
      labelMedium: TugTextStyles.label.copyWith(color: TugColors.darkTextSecondary),
    ),

    // Enhanced card styling
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.04),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: TugColors.darkSurface,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),

    // Modern app bar
    appBarTheme: AppBarTheme(
      backgroundColor: TugColors.darkSurface,
      foregroundColor: TugColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      titleTextStyle: TugTextStyles.titleLarge.copyWith(color: TugColors.darkTextPrimary),
      centerTitle: false,
      toolbarHeight: 64,
      shape: Border(
        bottom: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
    ),

    // Distinctive bottom navigation
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: TugColors.darkSurface,
      selectedItemColor: TugColors.primaryPurpleLight,
      unselectedItemColor: TugColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: TugTextStyles.label.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TugTextStyles.label,
      selectedIconTheme: const IconThemeData(size: 24),
      unselectedIconTheme: const IconThemeData(size: 22),
    ),

    // Refined input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: TugColors.darkBorder,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: TugColors.primaryPurpleLight,
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TugTextStyles.bodyMedium.copyWith(color: TugColors.darkTextSecondary),
      hintStyle: TugTextStyles.bodyMedium.copyWith(color: TugColors.darkTextSecondary.withOpacity(0.7)),
      prefixIconColor: TugColors.primaryPurpleLight,
      suffixIconColor: TugColors.darkTextSecondary,
      floatingLabelStyle: TugTextStyles.bodyMedium.copyWith(color: TugColors.primaryPurpleLight),
    ),

    // Divider for clear visual separation
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.08),
      thickness: 1,
      space: 32,
      indent: 0,
      endIndent: 0,
    ),

    // Icon theme
    iconTheme: IconThemeData(
      color: TugColors.darkTextPrimary,
      size: 24,
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TugColors.primaryPurpleLight;
        }
        return Colors.grey.shade300;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TugColors.primaryPurple.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.2);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // Elevated button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: TugButtons.primaryButtonStyle(isDark: true),
    ),

    // Outlined button styling
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: TugButtons.secondaryButtonStyle(isDark: true),
    ),

    // Text button styling
    textButtonTheme: TextButtonThemeData(
      style: TugButtons.tertiaryButtonStyle(isDark: true),
    ),

    // Icon button styling
    iconButtonTheme: IconButtonThemeData(
      style: TugButtons.iconButtonStyle(isDark: true),
    ),

    // Chip theme for tags and filters
    chipTheme: ChipThemeData(
      backgroundColor: TugColors.darkSurfaceVariant,
      selectedColor: TugColors.primaryPurple.withOpacity(0.3),
      disabledColor: Colors.grey.shade800.withOpacity(0.2),
      labelStyle: TugTextStyles.bodySmall.copyWith(color: TugColors.darkTextPrimary),
      secondaryLabelStyle: TugTextStyles.bodySmall.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      side: BorderSide(
        width: 1,
        color: Colors.white.withOpacity(0.05),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),

    // Tab bar theme for consistent navigation
    tabBarTheme: TabBarTheme(
      labelColor: TugColors.primaryPurpleLight,
      unselectedLabelColor: TugColors.darkTextSecondary,
      indicatorColor: TugColors.primaryPurpleLight,
      labelStyle: TugTextStyles.button,
      unselectedLabelStyle: TugTextStyles.button.copyWith(fontWeight: FontWeight.normal),
      indicatorSize: TabBarIndicatorSize.label,
    ),

    // Snackbar theme for notifications
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.grey.shade900,
      contentTextStyle: TugTextStyles.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      actionTextColor: TugColors.primaryPurpleLight,
    ),

    // Dialog theme for pop-ups
    dialogTheme: DialogTheme(
      backgroundColor: TugColors.darkSurface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: TugTextStyles.titleMedium.copyWith(color: TugColors.darkTextPrimary),
      contentTextStyle: TugTextStyles.bodyMedium.copyWith(color: TugColors.darkTextPrimary),
    ),

    // Progress indicator theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: TugColors.primaryPurpleLight,
      circularTrackColor: Colors.transparent,
      linearTrackColor: Colors.grey.shade800,
    ),
  );
}