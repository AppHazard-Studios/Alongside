// lib/theme/app_theme.dart - Refined version
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
    textTheme: const TextTheme(
      headlineMedium: AppTextStyles.title,
      titleLarge: AppTextStyles.sectionTitle,
      bodyLarge: AppTextStyles.bodyText,
      labelLarge: AppTextStyles.button,
    ),

    // AppBar styling (iOS-like)
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(
        color: AppColors.primary,
        size: 20, // Slightly smaller for iOS feel
      ),
      titleTextStyle: AppTextStyles.navTitle,
      toolbarHeight: 44, // iOS navigation bar height
      centerTitle: true, // iOS standard
    ),

    // Button styling - Cupertino-like
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0, // Flat iOS style
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // Minimum size for better touch targets
        minimumSize: const Size(44, 44),
      ),
    ),

    // Text button styling
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: AppColors.primary,
      size: 22, // Slightly smaller for iOS
    ),

    // Card theme - rounded corners
    cardTheme: CardTheme(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      // Subtle shadow
      shadowColor: Colors.black.withOpacity(0.04),
    ),

    // Dialog theme - rounded corners
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.cardBackground,
      elevation: 0, // No elevation - will use shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Larger modal radius for iOS feel
      modalBackgroundColor: AppColors.cardBackground,
      modalElevation: 0, // No elevation - will use shadow in implementation
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      // Make labels a bit smaller and lighter - iOS style
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.7),
        fontSize: 14,
      ),
      // Add more padding
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.grey.withOpacity(0.3);
      }),
    ),

    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.cardBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
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
        navTitleTextStyle: AppTextStyles.navTitle.copyWith(
          fontSize: 17, // iOS standard
          fontWeight: FontWeight.w600,
        ),
        navActionTextStyle: AppTextStyles.button.copyWith(
          color: AppColors.primary,
          fontSize: 16,
        ),
        navLargeTitleTextStyle: AppTextStyles.title.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        actionTextStyle: AppTextStyles.button.copyWith(
          color: AppColors.primary,
          fontSize: 16,
        ),
        tabLabelTextStyle: AppTextStyles.caption.copyWith(
          fontSize: 10,
        ),
        // Adding more iOS-specific styles
        pickerTextStyle: AppTextStyles.bodyText.copyWith(
          fontSize: 16,
        ),
      ),
      barBackgroundColor: AppColors.background,
      scaffoldBackgroundColor: AppColors.background,
    );
  }

  // Consistent text field styling for the entire app
  static BoxDecoration get textFieldDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: AppColors.divider,
        width: 1,
      ),
    );
  }

  // Consistent button styling
  static BoxDecoration get buttonDecoration {
    return BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      boxShadow: AppColors.subtleShadow,
    );
  }

  // Cupertino button styling
  static ButtonStyle get cupertinoButtonStyle {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.primaryButtonPressed;
        }
        return AppColors.primary;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // No elevation for iOS feel
      elevation: WidgetStateProperty.all(0),
      // Minimum size
      minimumSize: WidgetStateProperty.all(const Size(44, 44)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}