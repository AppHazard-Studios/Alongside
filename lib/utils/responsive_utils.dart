import 'package:flutter/material.dart';
import 'dart:math';

class ResponsiveUtils {
  // Intelligent text scaling that respects accessibility
  static double scaledFontSize(
    BuildContext context,
    double baseSize, {
    double minScale = 0.85,
    double maxScale = 1.5,
    double scaleFactor = 1.0,
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // Apply custom scale factor then clamp
    final effectiveScale = textScaleFactor * scaleFactor;
    final clampedScale = effectiveScale.clamp(minScale, maxScale);
    return baseSize * clampedScale;
  }

  // Intelligent spacing that scales proportionally
  static double scaledSpacing(
    BuildContext context,
    double baseSpacing, {
    double scaleFactor = 0.3, // How much spacing responds to text scale
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // Calculate proportional spacing increase
    final spacingMultiplier = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    return baseSpacing * spacingMultiplier.clamp(0.8, 1.5);
  }

  // Smart icon scaling - scales but within reason
  static double scaledIconSize(
    BuildContext context,
    double baseSize, {
    double minScale = 0.9,
    double maxScale = 1.3,
    double scaleFactor = 0.5, // Icons scale less than text
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // Icons scale at half the rate of text
    final iconScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    final clampedScale = iconScale.clamp(minScale, maxScale);
    return baseSize * clampedScale;
  }

  // Container scaling for things like profile circles
  static double scaledContainerSize(
    BuildContext context,
    double baseSize, {
    double scaleFactor = 0.3, // Containers scale conservatively
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final containerScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    return baseSize * containerScale.clamp(0.9, 1.2);
  }

  // Check if we need compact layout
  static bool needsCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return screenWidth < 350 || textScaleFactor > 1.3;
  }

  // Get padding that scales intelligently
  static EdgeInsets scaledPadding(
      BuildContext context, EdgeInsets basePadding) {
    final scale = scaledSpacing(context, 1.0);
    return EdgeInsets.only(
      left: basePadding.left * scale,
      right: basePadding.right * scale,
      top: basePadding.top * scale,
      bottom: basePadding.bottom * scale,
    );
  }

  // Button height that scales appropriately
  static double scaledButtonHeight(BuildContext context,
      {double baseHeight = 44}) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // Buttons need to grow for accessibility but not too much
    final buttonScale = 1.0 + ((textScaleFactor - 1.0) * 0.4);
    return baseHeight * buttonScale.clamp(1.0, 1.4);
  }
}
