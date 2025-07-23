// lib/utils/responsive_utils.dart - MUCH MORE RESTRICTIVE VERSION
import 'package:flutter/material.dart';
import 'dart:math';

class ResponsiveUtils {
  // EXTREMELY restrictive text scaling - prevents any significant changes
  static double scaledFontSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.99,  // Barely scales down
        double maxScale = 1.02,  // EXTREMELY restricted - was 1.03
        double scaleFactor = 0.05, // MUCH less responsive - was 0.1
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Debug print to see what's happening
    debugPrint('TextScaleFactor: $textScaleFactor');

    // Cap the textScaleFactor itself to prevent extreme values
    final cappedTextScaleFactor = textScaleFactor.clamp(0.85, 1.3);

    // Only allow very minimal scaling beyond 1.0
    final effectiveScale = 1.0 + ((cappedTextScaleFactor - 1.0) * scaleFactor);
    final clampedScale = effectiveScale.clamp(minScale, maxScale);

    debugPrint('BaseSize: $baseSize, EffectiveScale: $effectiveScale, ClampedScale: $clampedScale, FinalSize: ${baseSize * clampedScale}');

    return baseSize * clampedScale;
  }

  // Even more conservative spacing scaling
  static double scaledSpacing(
      BuildContext context,
      double baseSpacing, {
        double scaleFactor = 0.02, // MUCH reduced from 0.05
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3);

    // Calculate very minimal spacing increase
    final spacingMultiplier = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);

    // Very tight clamps to prevent layout breaking
    return baseSpacing * spacingMultiplier.clamp(0.98, 1.02);
  }

  // Very conservative icon scaling
  static double scaledIconSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.99,
        double maxScale = 1.01, // EXTREMELY restricted
        double scaleFactor = 0.02, // Much less responsive
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3);

    // Icons scale at much slower rate
    final iconScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    final clampedScale = iconScale.clamp(minScale, maxScale);

    return baseSize * clampedScale;
  }

  // Very conservative container scaling
  static double scaledContainerSize(
      BuildContext context,
      double baseSize, {
        double scaleFactor = 0.02, // MUCH more conservative
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3);

    final containerScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);

    // Very tight clamps - containers should barely grow
    return baseSize * containerScale.clamp(0.99, 1.01);
  }

  // More conservative compact layout threshold
  static bool needsCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Trigger compact layout earlier to prevent breaking
    return screenWidth < 350 || textScaleFactor > 1.2;
  }

  // Conservative padding scaling
  static EdgeInsets scaledPadding(
      BuildContext context,
      EdgeInsets basePadding,
      {double maxScale = 1.02} // Reduced max scale
      ) {
    final scale = scaledSpacing(context, 1.0).clamp(1.0, maxScale);

    return EdgeInsets.only(
      left: basePadding.left * scale,
      right: basePadding.right * scale,
      top: basePadding.top * scale,
      bottom: basePadding.bottom * scale,
    );
  }

  // Conservative button height scaling
  static double scaledButtonHeight(BuildContext context,
      {double baseHeight = 44}) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3);

    // Buttons need to grow for accessibility but very conservatively
    final buttonScale = 1.0 + ((textScaleFactor - 1.0) * 0.1); // Reduced from 0.15

    // Tighter clamps for buttons
    return baseHeight * buttonScale.clamp(1.0, 1.1); // Reduced from 1.15
  }

  // For form fields - slightly more scaling for accessibility but still restricted
  static double scaledFormHeight(BuildContext context, {double baseHeight = 44}) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3);
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.15); // Reduced from 0.2
    return baseHeight * scale.clamp(1.0, 1.1); // Reduced from 1.03
  }

  // For cards - minimal scaling to maintain layout
  static double scaledCardPadding(BuildContext context, double basePadding) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3);
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.02); // Reduced from 0.05
    return basePadding * scale.clamp(1.0, 1.01); // Very minimal
  }

  // For profile images and similar elements
  static double scaledProfileSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.85, 1.3);
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.05); // Reduced from 0.1
    return baseSize * scale.clamp(1.0, 1.02); // Reduced from 1.03
  }

  // Check if scaling is causing layout issues
  static bool isHighAccessibilityScale(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor > 1.2; // Reduced threshold
  }

  // Get safe scaling factor that won't break layouts
  static double getSafeScaleFactor(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return textScaleFactor.clamp(0.95, 1.02); // Much more restrictive
  }

  // NEW: Get the effective text scale factor with our restrictions applied
  static double getEffectiveTextScale(BuildContext context) {
    final rawScale = MediaQuery.of(context).textScaleFactor;
    // Apply our conservative scaling factor and cap it
    return (1.0 + ((rawScale.clamp(0.85, 1.3) - 1.0) * 0.05)).clamp(0.99, 1.02);
  }

  // DEBUG: Method to see what's happening with text scaling
  static void debugTextScaling(BuildContext context, String widgetName) {
    final rawScale = MediaQuery.of(context).textScaleFactor;
    final effectiveScale = getEffectiveTextScale(context);
    debugPrint('[$widgetName] Raw TextScaleFactor: $rawScale, Effective: $effectiveScale');
  }
}