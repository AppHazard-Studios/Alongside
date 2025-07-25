// lib/utils/text_styles.dart - SMART RESPONSIVE TEXT STYLES
import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Complete Text Style Guide for Alongside App with Smart Responsive Scaling
///
/// This version allows controlled font scaling that keeps layouts intact

class AppTextStyles {
  static const String _fontFamily = '.SF Pro Text';
  static const Color _primaryColor = Color(0xFF007AFF);
  static const Color _textColor = Color(0xFF000000);
  static const Color _secondaryColor = Color(0xFF8E8E93);

  // ============================================
  // BASE STYLES - LARGER SIZES WITH SMART SCALING
  // ============================================

  // Large Title - 36pt base
  static const TextStyle largeTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Title 1 - 30pt base
  static const TextStyle title1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Title 2 - 24pt base
  static const TextStyle title2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Title 3 - 22pt base
  static const TextStyle title3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Headline - 19pt base
  static const TextStyle headline = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Body - 19pt base (MAIN CONTENT TEXT)
  static const TextStyle body = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Callout - 18pt base
  static const TextStyle callout = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Subhead - 17pt base
  static const TextStyle subhead = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Footnote - 15pt base
  static const TextStyle footnote = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Caption 1 - 14pt base
  static const TextStyle caption1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // Caption 2 - 13pt base
  static const TextStyle caption2 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // ============================================
  // SPECIFIC USE STYLES
  // ============================================

  // App Title (e.g., "Alongside" in header) - 30pt base
  static const TextStyle appTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
    color: _primaryColor,
    height: 1.2,
  );

  // Navigation Bar Title - 22pt base
  static const TextStyle navTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Section Headers (e.g., "SECURITY", "BACKUP") - 15pt base
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // Button Text - 19pt base
  static const TextStyle button = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
    height: 1.2,
  );

  // Dialog Title - 19pt base
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Form Label - 18pt base
  static const TextStyle formLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // Form Input - 19pt base
  static const TextStyle formInput = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Placeholder - 19pt base
  static const TextStyle placeholder = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: Color(0xFFBEBEC0),
    height: 1.4,
  );

  // ============================================
  // SMART SCALING METHODS
  // ============================================

  // Core scaling method - now uses smart responsive scaling
  static TextStyle scaledTextStyle(BuildContext context, TextStyle baseStyle) {
    // Check for accessibility scaling in debug mode
    if (ResponsiveUtils.hasAccessibilityScaling(context)) {
      ResponsiveUtils.checkAccessibilityScaling(context);
    }

    // Apply smart scaling to font size
    final scaledSize = ResponsiveUtils.scaledFontSize(context, baseStyle.fontSize ?? 17);

    return baseStyle.copyWith(fontSize: scaledSize);
  }

  // ============================================
  // SCALED TEXT STYLES - Use these in your widgets!
  // ============================================

  // Titles & Headers
  static TextStyle scaledLargeTitle(BuildContext context) => scaledTextStyle(context, largeTitle);
  static TextStyle scaledTitle1(BuildContext context) => scaledTextStyle(context, title1);
  static TextStyle scaledTitle2(BuildContext context) => scaledTextStyle(context, title2);
  static TextStyle scaledTitle3(BuildContext context) => scaledTextStyle(context, title3);
  static TextStyle scaledAppTitle(BuildContext context) => scaledTextStyle(context, appTitle);
  static TextStyle scaledNavTitle(BuildContext context) => scaledTextStyle(context, navTitle);

  // Content
  static TextStyle scaledHeadline(BuildContext context) => scaledTextStyle(context, headline);
  static TextStyle scaledBody(BuildContext context) => scaledTextStyle(context, body);
  static TextStyle scaledCallout(BuildContext context) => scaledTextStyle(context, callout);
  static TextStyle scaledSubhead(BuildContext context) => scaledTextStyle(context, subhead);

  // Small Text
  static TextStyle scaledFootnote(BuildContext context) => scaledTextStyle(context, footnote);
  static TextStyle scaledCaption(BuildContext context) => scaledTextStyle(context, caption1);
  static TextStyle scaledCaption2(BuildContext context) => scaledTextStyle(context, caption2);

  // Functional
  static TextStyle scaledButton(BuildContext context) => scaledTextStyle(context, button);
  static TextStyle scaledSectionHeader(BuildContext context) => scaledTextStyle(context, sectionHeader);
  static TextStyle scaledDialogTitle(BuildContext context) => scaledTextStyle(context, dialogTitle);
  static TextStyle scaledFormLabel(BuildContext context) => scaledTextStyle(context, formLabel);
  static TextStyle scaledFormInput(BuildContext context) => scaledTextStyle(context, formInput);

  // Aliases for common use cases
  static TextStyle scaledCardTitle(BuildContext context) => scaledHeadline(context);
  static TextStyle scaledScreenHeader(BuildContext context) => scaledTitle2(context);

  // ============================================
  // OVERFLOW-SAFE TEXT HELPERS
  // ============================================

  // Safe text widget that prevents overflow
  static Widget safeText(
      BuildContext context,
      String text, {
        required TextStyle Function(BuildContext) styleBuilder,
        int? maxLines,
        TextOverflow overflow = TextOverflow.ellipsis,
        TextAlign? textAlign,
      }) {
    return ResponsiveUtils.safeText(
      text,
      style: styleBuilder(context),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  // Helper for friend names that might be long
  static Widget safeFriendName(BuildContext context, String name) {
    return safeText(
      context,
      name,
      styleBuilder: scaledHeadline,
      maxLines: 1,
    );
  }

  // Helper for body text that might wrap
  static Widget safeBodyText(BuildContext context, String text, {int? maxLines}) {
    return safeText(
      context,
      text,
      styleBuilder: scaledBody,
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  // ============================================
  // BACKWARD COMPATIBILITY ALIASES
  // ============================================

  static const TextStyle bodyText = body;
  static const TextStyle title = title2;
  static const TextStyle secondaryText = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.4,
  );
  static const TextStyle accentText = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _primaryColor,
    height: 1.3,
  );
}