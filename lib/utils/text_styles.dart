// lib/utils/text_styles.dart - Complete file with ALL required styles
import 'package:flutter/material.dart';
import 'responsive_utils.dart';

class AppTextStyles {
  // Base font family
  static const String _fontFamily = '.SF Pro Text';

  // Base colors
  static const Color _primaryColor = Color(0xFF007AFF); // iOS blue
  static const Color _textColor = Color(0xFF000000); // Black
  static const Color _secondaryColor = Color(0xFF8E8E93); // iOS gray

  // Title style for main headings
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Body text style
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Body text style - this was missing but referenced
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Secondary text style for subtitles and descriptions
  static const TextStyle secondary = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Secondary text style - this was missing but referenced
  static const TextStyle secondaryText = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Accent text style - this was missing but referenced
  static const TextStyle accentText = TextStyle(
    fontSize: 18,
    fontFamily: _fontFamily,
    color: _primaryColor,
    fontWeight: FontWeight.w500,
  );

  // Button text style
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: Colors.white,
  );

  // Dialog title style
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Dialog content style
  static const TextStyle dialogContent = TextStyle(
    fontSize: 13,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Nav bar title style
  static const TextStyle navTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  static const TextStyle navTitle2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Section title style
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Card title style
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Card content style
  static const TextStyle cardContent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Card secondary text
  static const TextStyle cardSecondaryContent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Form input text style - this was missing but referenced
  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Form label style
  static const TextStyle formLabel = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  // Form input style
  static const TextStyle formInput = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: _textColor,
  );

  // Form placeholder style - this was missing but referenced
  static const TextStyle placeholder = TextStyle(
    fontSize: 16,
    fontFamily: _fontFamily,
    color: Color(0xFFBEBEC0), // iOS placeholder color
  );

  // Small caption text
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontFamily: _fontFamily,
    color: _secondaryColor,
  );

  static TextStyle scaledTextStyle(
    BuildContext context,
    TextStyle baseStyle,
  ) {
    return baseStyle.copyWith(
      fontSize: ResponsiveUtils.scaledFontSize(
        context,
        baseStyle.fontSize ?? 16,
      ),
    );
  }
}
