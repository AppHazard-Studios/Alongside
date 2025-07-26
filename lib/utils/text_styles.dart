// lib/utils/text_styles.dart - CORRECTED TO EXACT iOS FONT SIZES
import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Complete Text Style Guide for Alongside App with iOS-Exact Font Sizes
///
/// All base font sizes now match iOS specifications exactly:
/// Large Title: 34pt, Title 1: 28pt, Title 2: 22pt, Title 3: 20pt
/// Headline: 17pt (semibold), Body: 17pt, Callout: 16pt, Subhead: 15pt
/// Footnote: 13pt, Caption 1: 12pt, Caption 2: 11pt

class AppTextStyles {
  static const String _fontFamily = '.SF Pro Text';
  static const Color _primaryColor = Color(0xFF007AFF);
  static const Color _textColor = Color(0xFF000000);
  static const Color _secondaryColor = Color(0xFF8E8E93);

  // ============================================
  // BASE STYLES - EXACT iOS FONT SIZES
  // ============================================

  // Large Title - 34pt (iOS exact)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Title 1 - 28pt (iOS exact)
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Title 2 - 22pt (iOS exact)
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Title 3 - 20pt (iOS exact)
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Headline - 17pt semibold (iOS exact)
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Body - 17pt (iOS exact, MAIN CONTENT TEXT)
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Callout - 16pt (iOS exact)
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Subhead - 15pt (iOS exact)
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Footnote - 13pt (iOS exact)
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Caption 1 - 12pt (iOS exact)
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // Caption 2 - 11pt (iOS exact)
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // ============================================
  // SPECIFIC USE STYLES
  // ============================================

  // App Title (e.g., "Alongside" in header) - 28pt
  static const TextStyle appTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
    color: _primaryColor,
    height: 1.2,
  );

  // Navigation Bar Title - 20pt
  static const TextStyle navTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Section Headers (e.g., "SECURITY", "BACKUP") - 13pt
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // Button Text - 17pt
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
    height: 1.2,
  );

  // Dialog Title - 17pt
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Form Label - 16pt
  static const TextStyle formLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // Form Input - 17pt
  static const TextStyle formInput = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Placeholder - 17pt
  static const TextStyle placeholder = TextStyle(
    fontSize: 17,
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
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.4,
  );
  static const TextStyle accentText = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _primaryColor,
    height: 1.3,
  );
}