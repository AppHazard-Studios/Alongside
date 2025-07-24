// lib/utils/text_styles.dart - FIXED SIZES WITH STYLE GUIDE
import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Complete Text Style Guide for Alongside App
///
/// USAGE GUIDE:
/// - Navigation Bar Titles: scaledNavTitle
/// - Screen Headers: scaledTitle1 or scaledTitle2
/// - Section Headers: scaledSectionHeader
/// - Card Titles: scaledHeadline
/// - Body Text: scaledBody
/// - Buttons: scaledButton
/// - Form Labels: scaledFormLabel
/// - Captions: scaledCaption
/// - Dialog Titles: scaledDialogTitle
///
/// NEVER use raw TextStyle(fontSize: X) - always use these predefined styles!

class AppTextStyles {
  static const String _fontFamily = '.SF Pro Text';
  static const Color _primaryColor = Color(0xFF007AFF);
  static const Color _textColor = Color(0xFF000000);
  static const Color _secondaryColor = Color(0xFF8E8E93);

  // ============================================
  // BASE STYLES - iOS Human Interface Guidelines
  // ============================================

  // Large Title - 34pt (Splash screens, onboarding)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Title 1 - 28pt (Main screen titles like "Alongside")
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Title 2 - 22pt (Section titles in screens)
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Title 3 - 20pt (Subsection titles, card headers)
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Headline - 17pt semibold (Navigation titles, important labels)
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Body - 17pt regular (Main content text)
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Callout - 16pt (Secondary content, form fields)
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Subhead - 15pt (Smaller labels, descriptions)
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Footnote - 13pt (Timestamps, metadata)
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Caption 1 - 12pt (Small labels)
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // Caption 2 - 11pt (Very small labels)
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

  // App Title (e.g., "Alongside" in header)
  static const TextStyle appTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
    color: _primaryColor,
    height: 1.2,
  );

  // Navigation Bar Title
  static const TextStyle navTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.2,
  );

  // Section Headers (e.g., "SECURITY", "BACKUP")
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
    height: 1.2,
  );

  // Dialog Title
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.3,
  );

  // Form Label
  static const TextStyle formLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    height: 1.3,
  );

  // Form Input
  static const TextStyle formInput = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
    height: 1.4,
  );

  // Placeholder
  static const TextStyle placeholder = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: Color(0xFFBEBEC0),
    height: 1.4,
  );

  // ============================================
  // SCALED METHODS (Now with FIXED sizes)
  // ============================================

  // Core scaling method - now returns FIXED sizes
  static TextStyle scaledTextStyle(BuildContext context, TextStyle baseStyle) {
    // Check for accessibility scaling in debug mode
    if (ResponsiveUtils.hasAccessibilityScaling(context)) {
      ResponsiveUtils.checkAccessibilityScaling(context);
    }

    // Return the base style unchanged - no scaling!
    return baseStyle;
  }

  // ============================================
  // QUICK REFERENCE - Use these in your widgets!
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
  // BACKWARD COMPATIBILITY ALIASES
  // ============================================

  // These are deprecated but kept for compatibility
  // TODO: Replace these throughout the app with proper scaled versions
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

// ============================================
// USAGE EXAMPLES:
// ============================================
//
// ✅ CORRECT:
// Text('Hello', style: AppTextStyles.scaledBody(context))
// Text('Title', style: AppTextStyles.scaledTitle1(context))
// Text('Save', style: AppTextStyles.scaledButton(context))
//
// ❌ WRONG:
// Text('Hello', style: TextStyle(fontSize: 17))
// Text('Title', style: Theme.of(context).textTheme.headline)
// Text('Save', style: AppTextStyles.body) // <- Missing context!