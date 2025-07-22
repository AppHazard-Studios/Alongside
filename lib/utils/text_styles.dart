// lib/utils/text_styles.dart - iOS STANDARD FONT SIZES WITH BETTER SCALING
import 'package:flutter/material.dart';
import 'responsive_utils.dart';

class AppTextStyles {
  // Base font family
  static const String _fontFamily = '.SF Pro Text';

  // Base colors
  static const Color _primaryColor = Color(0xFF007AFF); // iOS blue
  static const Color _textColor = Color(0xFF000000); // Black
  static const Color _secondaryColor = Color(0xFF8E8E93); // iOS gray

  // iOS STANDARD FONT SIZES - Updated to match iOS exactly

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

  // Headline - 17pt semibold (important labels)
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

  // Body text style (alias for consistency)
  static const TextStyle bodyText = TextStyle(
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

  // SPECIFIC USE CASE STYLES

  // Main title (for screen headers) - Title 2
  static const TextStyle title = title2;

  // Navigation titles - Headline
  static const TextStyle navTitle = headline;

  // Navigation titles secondary
  static const TextStyle navTitle2 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Secondary text for descriptions - Body with secondary color
  static const TextStyle secondary = TextStyle(
    fontSize: 17,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Secondary text style (alias)
  static const TextStyle secondaryText = TextStyle(
    fontSize: 17,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Accent text for highlights - Headline with primary color
  static const TextStyle accentText = TextStyle(
    fontSize: 17,
    fontFamily: _fontFamily,
    color: _primaryColor,
    fontWeight: FontWeight.w600,
  );

  // Button text - Headline
  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
  );

  // Dialog titles - Headline
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Dialog content - Body
  static const TextStyle dialogContent = TextStyle(
    fontSize: 17,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Section titles - Footnote weight, secondary color (iOS section headers)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _secondaryColor,
    letterSpacing: 0.5,
  );

  // Card titles - Headline
  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Card content - Body
  static const TextStyle cardContent = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Card secondary content - Body with secondary color
  static const TextStyle cardSecondaryContent = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Form input text - Body (iOS standard for input fields)
  static const TextStyle inputText = TextStyle(
    fontSize: 17,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Form labels - Callout
  static const TextStyle formLabel = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Form input style (alias)
  static const TextStyle formInput = TextStyle(
    fontSize: 17,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Placeholder text - Body with iOS placeholder color
  static const TextStyle placeholder = TextStyle(
    fontSize: 17,
    fontFamily: _fontFamily,
    color: Color(0xFFBEBEC0), // iOS placeholder color
  );

  // Caption text - Footnote with secondary color
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // RESPONSIVE SCALING WITH RESTRICTIONS

  // Scale text with BETTER restrictions to prevent app breaking
  static TextStyle scaledTextStyle(
      BuildContext context,
      TextStyle baseStyle, {
        double maxScale = 1.2, // REDUCED from 1.5 to prevent breaking
      }) {
    return baseStyle.copyWith(
      fontSize: ResponsiveUtils.scaledFontSize(
        context,
        baseStyle.fontSize ?? 17, // Default to iOS body size
        maxScale: maxScale, // Apply the restricted max scale
      ),
    );
  }

  // Specific scaled styles for common use cases
  static TextStyle scaledBody(BuildContext context) {
    return scaledTextStyle(context, body, maxScale: 1.2);
  }

  static TextStyle scaledHeadline(BuildContext context) {
    return scaledTextStyle(context, headline, maxScale: 1.15); // Even more restricted for titles
  }

  static TextStyle scaledButton(BuildContext context) {
    return scaledTextStyle(context, button, maxScale: 1.1); // Very restricted for buttons
  }

  static TextStyle scaledCaption(BuildContext context) {
    return scaledTextStyle(context, caption, maxScale: 1.3); // Allow more scaling for small text
  }
}