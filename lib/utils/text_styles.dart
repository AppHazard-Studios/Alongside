// utils/text_styles.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Precisely matched iOS typography system for consistent styling
class AppTextStyles {
  // Form field label style - exact match to "Name", "Phone Number" etc. in Add Friend screen
  static const formFieldLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF8E8E93), // iOS secondary label gray
    letterSpacing: -0.24,
    fontFamily: '.SF Pro Text',
    height: 1.2,
  );

  // Form field hint text style - exact match to "Enter name", "Enter phone number" in Add Friend
  static const formFieldHint = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: Color(0xFFC7C7CC), // iOS placeholder color
    letterSpacing: -0.41,
    fontFamily: '.SF Pro Text',
  );

  // Friend card label text - blue text like "Alongside them in:"
  static const cardLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF007AFF), // iOS blue
    letterSpacing: -0.24,
    fontFamily: '.SF Pro Text',
  );

  // Friend card content text - black text like "Living more like Jesus"
  static const cardContent = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: Color(0xFF000000), // Pure black
    letterSpacing: -0.41,
    fontFamily: '.SF Pro Text',
  );

  // Secondary content on friend card - gray text like "Reminder every 1 day"
  static const cardSecondaryContent = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF8E8E93), // iOS secondary label
    letterSpacing: -0.24,
    fontFamily: '.SF Pro Text',
  );

  // Section header - "NOTIFICATION SETTINGS" in Add Friend page
  static const sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF8E8E93), // iOS secondary label
    letterSpacing: 0.07,
    fontFamily: '.SF Pro Text',
  );

  // Navigation bar title
  static const navTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    letterSpacing: -0.41,
    fontFamily: '.SF Pro Text',
  );

  // Page title
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    letterSpacing: -0.5,
    fontFamily: '.SF Pro Display',
  );

  // Button text
  static const button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.white,
    letterSpacing: -0.41,
    fontFamily: '.SF Pro Text',
  );

  // Alert dialog title
  static const dialogTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    letterSpacing: -0.41,
    fontFamily: '.SF Pro Text',
  );

  // Alert dialog content
  static const dialogContent = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFF000000),
    letterSpacing: -0.08,
    fontFamily: '.SF Pro Text',
    height: 1.38,
  );

  // === ADDITIONAL STYLES REFERENCED IN CODE ===

  // Body text style - general purpose body text
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF000000),
    letterSpacing: -0.24,
    fontFamily: '.SF Pro Text',
    height: 1.3,
  );

  // Secondary text style - general purpose secondary text
  static const secondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF8E8E93), // iOS secondary gray
    letterSpacing: -0.24,
    fontFamily: '.SF Pro Text',
    height: 1.3,
  );

  // Section title (used in various screens)
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    letterSpacing: -0.41,
    fontFamily: '.SF Pro Text',
  );

  // Card title - used in friend cards
  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    letterSpacing: -0.41,
    fontFamily: '.SF Pro Text',
  );
}