// lib/utils/text_styles.dart - FIXED with CONSISTENT EXTREMELY RESTRICTIVE SCALING
import 'package:flutter/material.dart';
import 'responsive_utils.dart';

class AppTextStyles {
  // Base font family
  static const String _fontFamily = '.SF Pro Text';

  // Base colors
  static const Color _primaryColor = Color(0xFF007AFF); // iOS blue
  static const Color _textColor = Color(0xFF000000); // Black
  static const Color _secondaryColor = Color(0xFF8E8E93); // iOS gray

  // iOS STANDARD FONT SIZES - These are the exact iOS system sizes

  // Large Title - 34pt (used sparingly, like main app titles)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Title 1 - 28pt (main screen titles)
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Title 2 - 22pt (section titles)
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Title 3 - 20pt (subsection titles)
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Headline - 17pt semibold (important labels, navigation titles)
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Body - 17pt regular (MAIN CONTENT TEXT - iOS standard)
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Callout - 16pt (form labels, secondary content)
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Subhead - 15pt (smaller labels)
  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Footnote - 13pt (section headers, disclaimers)
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Caption 1 - 12pt (small labels)
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Caption 2 - 11pt (very small labels)
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // SPECIFIC USE CASE STYLES WITH PROPER iOS SIZING

  // Navigation titles - Should be Title 3 for prominence
  static const TextStyle navTitle = TextStyle(
    fontSize: 20, // Title 3 size for nav titles
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Main app titles (like "Alongside") - Title 1
  static const TextStyle appTitle = TextStyle(
    fontSize: 28, // Title 1 size
    fontWeight: FontWeight.w800,
    fontFamily: _fontFamily,
    color: _primaryColor,
  );

  // Screen headers - Title 2
  static const TextStyle screenHeader = TextStyle(
    fontSize: 22, // Title 2 size
    fontWeight: FontWeight.w700,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Card titles - Headline
  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Form labels - Callout
  static const TextStyle formLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Form input text - Body
  static const TextStyle formInput = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Button text - Headline
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
  );

  // Section headers (like "SECURITY") - Footnote with bold
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    letterSpacing: 0.5,
  );

  // Secondary text - Body with secondary color
  static const TextStyle secondaryText = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Placeholder text - Body with iOS placeholder color
  static const TextStyle placeholder = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: Color(0xFFBEBEC0), // iOS placeholder color
  );

  // Caption text - Footnote with secondary color
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Dialog titles - Headline
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // RESPONSIVE SCALING WITH EXTREMELY RESTRICTIVE VALUES

  // Scale text with EXTREMELY restricted scaling to prevent any noticeable changes
  static TextStyle scaledTextStyle(
      BuildContext context,
      TextStyle baseStyle) {
    // Use ResponsiveUtils directly - no more maxScale overrides!
    return baseStyle.copyWith(
      fontSize: ResponsiveUtils.scaledFontSize(
        context,
        baseStyle.fontSize ?? 17, // Default to iOS body size
        // Using default values from ResponsiveUtils (maxScale: 1.02)
      ),
    );
  }

  // All scaled styles now use consistent extremely restrictive scaling
  static TextStyle scaledBody(BuildContext context) {
    return scaledTextStyle(context, body);
  }

  static TextStyle scaledHeadline(BuildContext context) {
    return scaledTextStyle(context, headline);
  }

  static TextStyle scaledNavTitle(BuildContext context) {
    return scaledTextStyle(context, navTitle);
  }

  static TextStyle scaledAppTitle(BuildContext context) {
    return scaledTextStyle(context, appTitle);
  }

  static TextStyle scaledFormLabel(BuildContext context) {
    return scaledTextStyle(context, formLabel);
  }

  static TextStyle scaledFormInput(BuildContext context) {
    return scaledTextStyle(context, formInput);
  }

  static TextStyle scaledButton(BuildContext context) {
    return scaledTextStyle(context, button);
  }

  static TextStyle scaledCaption(BuildContext context) {
    return scaledTextStyle(context, caption);
  }

  static TextStyle scaledSectionHeader(BuildContext context) {
    return scaledTextStyle(context, sectionHeader);
  }

  static TextStyle scaledCardTitle(BuildContext context) {
    return scaledTextStyle(context, cardTitle);
  }

  static TextStyle scaledDialogTitle(BuildContext context) {
    return scaledTextStyle(context, dialogTitle);
  }

  static TextStyle scaledSubhead(BuildContext context) {
    return scaledTextStyle(context, subhead);
  }

  static TextStyle scaledCallout(BuildContext context) {
    return scaledTextStyle(context, callout);
  }

  static TextStyle scaledFootnote(BuildContext context) {
    return scaledTextStyle(context, footnote);
  }

  static TextStyle scaledScreenHeader(BuildContext context) {
    return scaledTextStyle(context, title3); // Use Title 3 for screen headers
  }

  static TextStyle scaledCaption2(BuildContext context) {
    return scaledTextStyle(context, caption2);
  }

  static TextStyle scaledTitle1(BuildContext context) {
    return scaledTextStyle(context, title1);
  }

  static TextStyle scaledTitle3(BuildContext context) {
    return scaledTextStyle(context, title3);
  }

  // BACKWARD COMPATIBILITY ALIASES
  static const TextStyle title = title2; // For existing code
  static const TextStyle bodyText = body; // For existing code
  static const TextStyle accentText = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _primaryColor,
  );

  // NEW: Debug method to track text scaling
  static void debugTextStyle(BuildContext context, String styleName, TextStyle style) {
    ResponsiveUtils.debugTextScaling(context, styleName);
    debugPrint('[$styleName] Base fontSize: ${style.fontSize}');
  }
}