// lib/utils/colors.dart - Refined version
import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - Refined and iOS-friendly
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

  // REFINED SHADOW SYSTEM
  // These shadow styles provide consistent shadows across the entire app

  // Subtle shadow for cards and containers - iOS style
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // Medium shadow for buttons and interactive elements
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  // Primary color shadow (for branded elements)
  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Secondary color shadow
  static List<BoxShadow> get secondaryShadow => [
    BoxShadow(
      color: secondary.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Accent color shadow
  static List<BoxShadow> get accentShadow => [
    BoxShadow(
      color: accent.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Modal shadow (bottom sheets, dialogs)
  static List<BoxShadow> get modalShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  // iOS standard system colors for consistency
  static const Color iosRed = Color(0xFFFF3B30);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosGray = Color(0xFF8E8E93);
}