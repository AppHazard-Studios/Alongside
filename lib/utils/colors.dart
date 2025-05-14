// lib/utils/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - Vibrant but iOS-friendly
  static const Color primary = Color(0xFF5E6CE7);        // Vibrant blue-purple
  static const Color secondary = Color(0xFFFF7A5C);      // Soft coral
  static const Color tertiary = Color(0xFF8CD9C9);       // Mint green
  static const Color accent = Color(0xFFFFBF65);         // Warm amber

  // Neutrals
  static const Color background = Color(0xFFF8F8FA);     // Soft off-white
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white
  static const Color textPrimary = Color(0xFF222639);    // Dark blue-grey (not pure black)
  static const Color textSecondary = Color(0xFF88889D);  // Muted blue-grey
  static const Color divider = Color(0xFFECECEF);        // Light grey for dividers

  // Semantic colors
  static const Color success = Color(0xFF5CC78C);        // Green
  static const Color warning = Color(0xFFFFBF65);        // Amber
  static const Color error = Color(0xFFFF7575);          // Soft red
  static const Color info = Color(0xFF5EAFFF);           // Sky blue

  // Status/Mood colors
  static const Color joyful = Color(0xFFFFCA62);         // Bright yellow
  static const Color calm = Color(0xFF89D1F5);           // Light blue
  static const Color focused = Color(0xFF8CD9C9);        // Mint green
  static const Color stressed = Color(0xFFE5C0FF);       // Soft purple

  // Button states
  static Color primaryButtonPressed = primary.withOpacity(0.8);
  static Color secondaryButtonPressed = secondary.withOpacity(0.8);

  // Light variants (for backgrounds, etc.)
  static Color primaryLight = primary.withOpacity(0.15);
  static Color secondaryLight = secondary.withOpacity(0.15);
  static Color tertiaryLight = tertiary.withOpacity(0.15);
  static Color accentLight = accent.withOpacity(0.15);

  // Extended palette for illustrations and accents
  static const List<Color> extendedPalette = [
    Color(0xFF5E6CE7),  // Primary blue-purple
    Color(0xFFFF7A5C),  // Coral
    Color(0xFF8CD9C9),  // Mint
    Color(0xFFFFBF65),  // Amber
    Color(0xFFE5C0FF),  // Lavender
    Color(0xFF89D1F5),  // Sky blue
    Color(0xFFFFCA62),  // Yellow
  ];
}