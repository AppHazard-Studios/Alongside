// lib/utils/text_styles.dart - Revised and standardized

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Consolidated and standardized text styles for the entire app
class AppTextStyles {
  // Base properties
  static const String _fontFamily = '.SF Pro Text';
  static const String _displayFontFamily = '.SF Pro Display';
  static const Color _textColor = Color(0xFF000000);
  static const Color _secondaryTextColor = Color(0xFF8E8E93);
  static const Color _accentColor = Color(0xFF007AFF);

  // NAVIGATION & HEADERS

  // Navigation bar title (17pt, semibold)
  static const navTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: _textColor,
    letterSpacing: -0.41,
    fontFamily: _fontFamily,
  );

  // Page title (22pt, semibold, Display font)
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: _textColor,
    letterSpacing: -0.5,
    fontFamily: _displayFontFamily,
  );

  // Section title (17pt, semibold)
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: _textColor,
    letterSpacing: -0.41,
    fontFamily: _fontFamily,
  );

  // CONTENT TEXT

  // Card title, used in friend cards (17pt, semibold)
  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: _textColor,
    letterSpacing: -0.41,
    fontFamily: _fontFamily,
  );

  // Card content text (17pt, regular)
  static const cardContent = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: _textColor,
    letterSpacing: -0.41,
    fontFamily: _fontFamily,
  );

  // Blue accent label text (15pt, iOS blue)
  static const cardLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _accentColor,
    letterSpacing: -0.24,
    fontFamily: _fontFamily,
  );

  // Secondary gray text (15pt, gray)
  static const cardSecondaryContent = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _secondaryTextColor,
    letterSpacing: -0.24,
    fontFamily: _fontFamily,
  );

  // FORM ELEMENTS

  // Form field label (13pt, medium, gray)
  static const formFieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _secondaryTextColor,
    letterSpacing: -0.08,
    fontFamily: _fontFamily,
    height: 1.2,
  );

  // Form field text (15pt, regular)
  static const formFieldText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _textColor,
    letterSpacing: -0.24,
    fontFamily: _fontFamily,
  );

  // Form field placeholder (15pt, gray)
  static const formFieldHint = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFFC7C7CC),
    letterSpacing: -0.24,
    fontFamily: _fontFamily,
  );

  // Section header caps (13pt, medium, gray)
  static const sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _secondaryTextColor,
    letterSpacing: 0.07,
    fontFamily: _fontFamily,
  );

  // BUTTONS & INTERACTIVE ELEMENTS

  // Button text (17pt, semibold, white)
  static const button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.white,
    letterSpacing: -0.41,
    fontFamily: _fontFamily,
  );

  // Secondary button text (16pt, medium, blue)
  static const secondaryButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: _accentColor,
    letterSpacing: -0.32,
    fontFamily: _fontFamily,
  );

  // DIALOG ELEMENTS

  // Dialog title (17pt, semibold)
  static const dialogTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: _textColor,
    letterSpacing: -0.41,
    fontFamily: _fontFamily,
  );

  // Dialog content (13pt, regular)
  static const dialogContent = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _textColor,
    letterSpacing: -0.08,
    fontFamily: _fontFamily,
    height: 1.38,
  );

  // GENERAL PURPOSE

  // Body text (15pt, regular)
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _textColor,
    letterSpacing: -0.24,
    fontFamily: _fontFamily,
    height: 1.3,
  );

  // Secondary text (15pt, gray)
  static const secondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: _secondaryTextColor,
    letterSpacing: -0.24,
    fontFamily: _fontFamily,
    height: 1.3,
  );

  // Small text/caption (13pt, gray)
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _secondaryTextColor,
    letterSpacing: -0.08,
    fontFamily: _fontFamily,
  );
}