import 'package:flutter/material.dart';
import 'dart:math';

class ResponsiveUtils {
  // IMPROVED scaling with better restrictions to prevent app breaking

  // Smart text scaling with MUCH more conservative limits
  static double scaledFontSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.9,  // Slightly increased minimum
        double maxScale = 1.2,  // REDUCED from 1.5 - prevents breaking
        double scaleFactor = 1.0,
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Apply custom scale factor then clamp to conservative limits
    final effectiveScale = textScaleFactor * scaleFactor;
    final clampedScale = effectiveScale.clamp(minScale, maxScale);

    return baseSize * clampedScale;
  }

  // Much more conservative spacing scaling
  static double scaledSpacing(
      BuildContext context,
      double baseSpacing, {
        double scaleFactor = 0.2, // REDUCED from 0.3 - less aggressive
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Calculate proportional spacing increase (much more conservative)
    final spacingMultiplier = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);

    // TIGHTER clamps to prevent layout breaking
    return baseSpacing * spacingMultiplier.clamp(0.9, 1.3);
  }

  // Conservative icon scaling - prevents icons from becoming huge
  static double scaledIconSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.95, // Barely scales down
        double maxScale = 1.15, // MUCH more restricted
        double scaleFactor = 0.3, // Even less responsive
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Icons scale at much slower rate
    final iconScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    final clampedScale = iconScale.clamp(minScale, maxScale);

    return baseSize * clampedScale;
  }

  // Very conservative container scaling
  static double scaledContainerSize(
      BuildContext context,
      double baseSize, {
        double scaleFactor = 0.15, // MUCH more conservative
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    final containerScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);

    // Very tight clamps - containers should barely grow
    return baseSize * containerScale.clamp(0.95, 1.15);
  }

  // More conservative compact layout threshold
  static bool needsCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Trigger compact layout earlier to prevent breaking
    return screenWidth < 350 || textScaleFactor > 1.2; // Reduced from 1.3
  }

  // Conservative padding scaling
  static EdgeInsets scaledPadding(
      BuildContext context,
      EdgeInsets basePadding,
      {double maxScale = 1.2} // Add max scale parameter
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
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Buttons need to grow for accessibility but very conservatively
    final buttonScale = 1.0 + ((textScaleFactor - 1.0) * 0.25); // Reduced from 0.4

    // Tighter clamps for buttons
    return baseHeight * buttonScale.clamp(1.0, 1.25); // Reduced from 1.4
  }

  // NEW: Specific scaling for different UI elements

  // For form fields - need more scaling for accessibility
  static double scaledFormHeight(BuildContext context, {double baseHeight = 44}) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.3);
    return baseHeight * scale.clamp(1.0, 1.3);
  }

  // For cards - minimal scaling to maintain layout
  static double scaledCardPadding(BuildContext context, double basePadding) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.1); // Very minimal
    return basePadding * scale.clamp(1.0, 1.1);
  }

  // For profile images and similar elements
  static double scaledProfileSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.2);
    return baseSize * scale.clamp(1.0, 1.2);
  }

  // Check if scaling is causing layout issues
  static bool isHighAccessibilityScale(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor > 1.3;
  }

  // Get safe scaling factor that won't break layouts
  static double getSafeScaleFactor(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return textScaleFactor.clamp(0.9, 1.2);
  }
}