// lib/utils/colors.dart - Simplified with single primary accent color
import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY ACCENT COLOR - The main blue used throughout the app
  static const Color primary = Color(0xFF007AFF);        // iOS system blue - our main accent

  // Supporting colors - more muted to let primary shine
  static const Color secondary = Color(0xFF8E8E93);      // iOS system gray
  static const Color tertiary = Color(0xFF34C759);       // iOS system green (for success only)
  static const Color accent = Color(0xFFFF9500);         // iOS system orange (for warnings only)

  // Neutrals
  static const Color background = Color(0xFFF2F2F7);     // iOS grouped background
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white
  static const Color textPrimary = Color(0xFF000000);    // Pure black
  static const Color textSecondary = Color(0xFF8E8E93);  // iOS system gray
  static const Color divider = Color(0xFFDCDCDC);        // iOS separator

  // Semantic colors
  static const Color success = Color(0xFF34C759);        // iOS green
  static const Color warning = Color(0xFFFF9500);        // iOS orange
  static const Color error = Color(0xFFFF3B30);          // iOS red
  static const Color info = primary;                     // Use primary for info

  // Time-based greeting colors
  static const Color morningColor = Color(0xFFFF9500);   // Orange for morning
  static const Color afternoonColor = Color(0xFFFFBF65); // Warm amber for afternoon
  static const Color eveningColor = Color(0xFF5E6CE7);   // Purple-blue for evening

  // Button states
  static Color primaryButtonPressed = primary.withOpacity(0.8);
  static Color secondaryButtonPressed = secondary.withOpacity(0.8);

  // Light variants (for backgrounds)
  static Color primaryLight = primary.withOpacity(0.1);
  static Color secondaryLight = secondary.withOpacity(0.1);
  static Color tertiaryLight = tertiary.withOpacity(0.1);
  static Color accentLight = accent.withOpacity(0.1);

  // CONSISTENT SHADOW SYSTEM
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get primaryShadow => [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
}