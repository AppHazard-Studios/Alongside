import 'package:flutter/material.dart';
import 'dart:math';

class ResponsiveUtils {
  // MUCH MORE RESTRICTIVE scaling to prevent layout breaking

  // Extremely conservative text scaling - prevents huge text
  static double scaledFontSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.98,  // Barely scales down
        double maxScale = 1.03,   // MUCH more restricted - was 1.2
        double scaleFactor = 0.1, // REDUCED scaling responsiveness
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Only allow very minimal scaling beyond 1.0
    final effectiveScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    final clampedScale = effectiveScale.clamp(minScale, maxScale);

    return baseSize * clampedScale;
  }

  // Even more conservative spacing scaling
  static double scaledSpacing(
      BuildContext context,
      double baseSpacing, {
        double scaleFactor = 0.05, // MUCH reduced from 0.2
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Calculate very minimal spacing increase
    final spacingMultiplier = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);

    // Very tight clamps to prevent layout breaking
    return baseSpacing * spacingMultiplier.clamp(0.95, 1.05);
  }

  // Very conservative icon scaling
  static double scaledIconSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.98,
        double maxScale = 1.02, // VERY restricted
        double scaleFactor = 0.05, // Much less responsive
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
        double scaleFactor = 0.05, // MUCH more conservative
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    final containerScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);

    // Very tight clamps - containers should barely grow
    return baseSize * containerScale.clamp(0.98, 1.03);
  }

  // More conservative compact layout threshold
  static bool needsCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Trigger compact layout earlier to prevent breaking
    return screenWidth < 350 || textScaleFactor > 1.03; // Reduced from 1.2
  }

  // Conservative padding scaling
  static EdgeInsets scaledPadding(
      BuildContext context,
      EdgeInsets basePadding,
      {double maxScale = 1.05} // Reduced max scale
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
    final buttonScale = 1.0 + ((textScaleFactor - 1.0) * 0.15); // Reduced from 0.25

    // Tighter clamps for buttons
    return baseHeight * buttonScale.clamp(1.0, 1.15); // Reduced from 1.25
  }

  // For form fields - slightly more scaling for accessibility but still restricted
  static double scaledFormHeight(BuildContext context, {double baseHeight = 44}) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.2); // Reduced from 0.3
    return baseHeight * scale.clamp(1.0, 1.03); // Reduced from 1.3
  }

  // For cards - minimal scaling to maintain layout
  static double scaledCardPadding(BuildContext context, double basePadding) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.05); // Reduced from 0.1
    return basePadding * scale.clamp(1.0, 1.03); // Very minimal
  }

  // For profile images and similar elements
  static double scaledProfileSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scale = 1.0 + ((textScaleFactor - 1.0) * 0.1); // Reduced from 0.2
    return baseSize * scale.clamp(1.0, 1.03); // Reduced from 1.2
  }

  // Check if scaling is causing layout issues
  static bool isHighAccessibilityScale(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor > 1.03; // Reduced threshold
  }

  // Get safe scaling factor that won't break layouts
  static double getSafeScaleFactor(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return textScaleFactor.clamp(0.95, 1.03); // Much more restrictive
  }

  // NEW: Get the effective text scale factor with our restrictions applied
  static double getEffectiveTextScale(BuildContext context) {
    final rawScale = MediaQuery.of(context).textScaleFactor;
    // Apply our conservative scaling factor
    return (1.0 + ((rawScale - 1.0) * 0.15)).clamp(0.95, 1.03);
  }
}