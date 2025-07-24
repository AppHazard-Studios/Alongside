// lib/utils/responsive_utils.dart - ULTRA RESTRICTIVE VERSION
import 'package:flutter/material.dart';
import 'dart:math';

class ResponsiveUtils {
  // ULTRA restrictive text scaling - practically disables accessibility scaling
  static double scaledFontSize(
      BuildContext context,
      double baseSize, {
        double minScale = 1.0,      // Never shrink
        double maxScale = 1.0,      // NEVER GROW - completely fixed
        double scaleFactor = 0.0,   // NO scaling at all
      }) {
    // For debugging - uncomment to see what's happening
    // final rawTextScale = MediaQuery.of(context).textScaleFactor;
    // debugPrint('Raw TextScaleFactor: $rawTextScale, BaseSize: $baseSize, Result: $baseSize');

    // OPTION 1: Completely ignore accessibility scaling
    return baseSize;

    // OPTION 2: Allow MINIMAL scaling (uncomment if you want some accessibility)
    // final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // final cappedScale = textScaleFactor.clamp(0.85, 1.15);
    // final tinyScale = 1.0 + ((cappedScale - 1.0) * 0.1); // Only 10% of the scaling
    // return baseSize * tinyScale.clamp(minScale, maxScale);
  }

  // Fixed spacing - no scaling
  static double scaledSpacing(
      BuildContext context,
      double baseSpacing, {
        double scaleFactor = 0.0,
      }) {
    return baseSpacing; // Completely fixed
  }

  // Fixed icon sizes
  static double scaledIconSize(
      BuildContext context,
      double baseSize, {
        double minScale = 1.0,
        double maxScale = 1.0,
        double scaleFactor = 0.0,
      }) {
    return baseSize; // Completely fixed
  }

  // Fixed container sizes
  static double scaledContainerSize(
      BuildContext context,
      double baseSize, {
        double scaleFactor = 0.0,
      }) {
    return baseSize; // Completely fixed
  }

  // Check if we need compact layout (for extreme text scaling)
  static bool needsCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Use compact layout for extreme scaling
    return screenWidth < 350 || textScaleFactor > 1.5;
  }

  // Fixed padding
  static EdgeInsets scaledPadding(
      BuildContext context,
      EdgeInsets basePadding,
      {double maxScale = 1.0}
      ) {
    return basePadding; // Completely fixed
  }

  // Fixed button height
  static double scaledButtonHeight(BuildContext context,
      {double baseHeight = 44}) {
    return baseHeight; // Completely fixed
  }

  // Fixed form field height
  static double scaledFormHeight(BuildContext context, {double baseHeight = 44}) {
    return baseHeight; // Completely fixed
  }

  // Get raw text scale factor for debugging
  static double getRawTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  // Check if user has accessibility scaling enabled
  static bool hasAccessibilityScaling(BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    return scale < 0.95 || scale > 1.05;
  }

  // Show accessibility warning if needed
  static void checkAccessibilityScaling(BuildContext context) {
    if (hasAccessibilityScaling(context)) {
      final scale = getRawTextScaleFactor(context);
      debugPrint('⚠️ Accessibility scaling detected: ${(scale * 100).toStringAsFixed(0)}%');
      debugPrint('⚠️ This app uses fixed text sizes for consistent layouts.');
    }
  }
}