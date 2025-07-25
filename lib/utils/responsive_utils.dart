// lib/utils/responsive_utils.dart - SMART PROPORTIONAL SCALING
import 'package:flutter/material.dart';
import 'dart:math';

class ResponsiveUtils {
  // Smart text scaling - allows limited scaling but keeps it reasonable
  static double scaledFontSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.9,      // Minimal shrinking
        double maxScale = 1.15,     // Conservative growth (15% max)
        double scaleFactor = 0.5,   // Moderate scaling intensity
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Apply scaling factor to reduce the intensity
    final adjustedScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);

    // Clamp to reasonable bounds
    final cappedScale = adjustedScale.clamp(minScale, maxScale);

    return baseSize * cappedScale;
  }

  // Smart spacing that scales with text but conservatively
  static double scaledSpacing(
      BuildContext context,
      double baseSpacing, {
        double scaleFactor = 0.2, // Very conservative for spacing
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final adjustedScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    final cappedScale = adjustedScale.clamp(0.95, 1.1);

    return baseSpacing * cappedScale;
  }

  // Smart icon sizes that scale with text
  static double scaledIconSize(
      BuildContext context,
      double baseSize, {
        double minScale = 0.95,
        double maxScale = 1.1,
        double scaleFactor = 0.3,
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final adjustedScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    final cappedScale = adjustedScale.clamp(minScale, maxScale);

    return baseSize * cappedScale;
  }

  // Smart container sizes that scale proportionally
  static double scaledContainerSize(
      BuildContext context,
      double baseSize, {
        double scaleFactor = 0.4, // Conservative scaling for containers
      }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final adjustedScale = 1.0 + ((textScaleFactor - 1.0) * scaleFactor);
    final cappedScale = adjustedScale.clamp(0.95, 1.15);

    return baseSize * cappedScale;
  }

  // Check if we need compact layout (for extreme text scaling)
  static bool needsCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Use compact layout for extreme scaling or small screens
    return screenWidth < 350 || textScaleFactor > 1.2; // More conservative threshold
  }

  // Smart padding that scales reasonably
  static EdgeInsets scaledPadding(
      BuildContext context,
      EdgeInsets basePadding,
      {double maxScale = 1.2}
      ) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final adjustedScale = 1.0 + ((textScaleFactor - 1.0) * 0.3);
    final scale = adjustedScale.clamp(0.9, maxScale);

    return EdgeInsets.fromLTRB(
      basePadding.left * scale,
      basePadding.top * scale,
      basePadding.right * scale,
      basePadding.bottom * scale,
    );
  }

  // Smart button height
  static double scaledButtonHeight(BuildContext context,
      {double baseHeight = 44}) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final adjustedScale = 1.0 + ((textScaleFactor - 1.0) * 0.3);
    final scale = adjustedScale.clamp(0.98, 1.15);

    return baseHeight * scale;
  }

  // Smart form field height
  static double scaledFormHeight(BuildContext context, {double baseHeight = 44}) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final adjustedScale = 1.0 + ((textScaleFactor - 1.0) * 0.3);
    final scale = adjustedScale.clamp(0.98, 1.15);

    return baseHeight * scale;
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
      debugPrint('📱 Accessibility scaling detected: ${(scale * 100).toStringAsFixed(0)}%');
      debugPrint('📱 Using smart responsive scaling (limited to 125%)');
    }
  }

  // Helper for overflow protection
  static Widget protectFromOverflow({
    required Widget child,
    String? debugName,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OverflowBox(
          maxWidth: constraints.maxWidth,
          child: child,
        );
      },
    );
  }

  // Helper for text that might overflow
  static Widget safeText(
      String text, {
        required TextStyle style,
        int? maxLines,
        TextOverflow overflow = TextOverflow.ellipsis,
        TextAlign? textAlign,
      }) {
    return Flexible(
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}