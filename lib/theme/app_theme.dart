// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

class AppTheme {
  // Create the Material color swatch from our primary color
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    final int r = color.red, g = color.green, b = color.blue;

    return MaterialColor(color.value, {
      for (final strength in strengths)
        (strength * 1000).round(): Color.fromRGBO(
          r,
          g,
          b,
          strength,
        ),
      50: Color.fromRGBO(r, g, b, .05),
      100: Color.fromRGBO(r, g, b, .1),
      200: Color.fromRGBO(r, g, b, .2),
      300: Color.fromRGBO(r, g, b, .3),
      400: Color.fromRGBO(r, g, b, .4),
      500: Color.fromRGBO(r, g, b, .5),
      600: Color.fromRGBO(r, g, b, .6),
      700: Color.fromRGBO(r, g, b, .7),
      800: Color.fromRGBO(r, g, b, .8),
      900: Color.fromRGBO(r, g, b, .9),
    });
  }

  // Light theme (default)
  static ThemeData lightTheme = ThemeData(
    // Colors
    primaryColor: AppColors.primary,
    primarySwatch: createMaterialColor(AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.cardBackground,
    dividerColor: AppColors.divider,

    // Platform
    platform: TargetPlatform.iOS,

    // Turn off Material splash effects to maintain iOS feel
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,

    // Use System Font as default
    fontFamily: '.SF Pro Text',

    // Text themes with our custom styles
    textTheme: TextTheme(
      headlineMedium: AppTextStyles.title,
      titleLarge: AppTextStyles.sectionTitle,
      bodyLarge: AppTextStyles.bodyText,
      labelLarge: AppTextStyles.button,
    ),

    // AppBar styling (iOS-like)
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(
        color: AppColors.primary,
        size: 22,
      ),
      titleTextStyle: AppTextStyles.navTitle,
      toolbarHeight: 44, // iOS navigation bar height
    ),

    // Button styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),

    // Text button styling
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),

    // Icon theme
    iconTheme: IconThemeData(
      color: AppColors.primary,
      size: 24,
    ),

    // Card theme - rounded corners
    cardTheme: CardTheme(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),

    // Dialog theme - rounded corners
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // Color scheme
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      background: AppColors.background,
      surface: AppColors.cardBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    ),
  );

  // Get the appropriate CupertinoThemeData from our Material theme
  static CupertinoThemeData get cupertinoTheme {
    return CupertinoThemeData(
      primaryColor: AppColors.primary,
      brightness: Brightness.light,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.primary,
        textStyle: AppTextStyles.bodyText,
        navTitleTextStyle: AppTextStyles.navTitle,
        navActionTextStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        navLargeTitleTextStyle: AppTextStyles.navTitle,
        actionTextStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
      ),
      barBackgroundColor: AppColors.background,
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}