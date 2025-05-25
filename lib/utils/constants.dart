// utils/constants.dart - Restructured with categorized messages

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppConstants {
  // Categorized preset messages for better organization
  static const Map<String, List<String>> categorizedMessages = {
    'Check-ins': [
      "How’s today going?",
      "Hey, just checking in.",
      "You doing okay this week?",
      "Got a second to catch up?",
      "Still on track with your stuff?",
    ],
    'Support & Struggle': [
      "Bit of a rough one today.",
      "Having a hard time staying focused.",
      "Could use some support today.",
      "Today’s been harder than usual.",
      "Not at my best right now.",
    ],
    'Confession': [
      "Messed up today.",
      "Wasn’t a great day for me.",
      "Didn’t stay on track.",
      "Not where I wanted to be today.",
      "Slipped. Can you check in later?",
    ],
  };

  // Get all preset messages as a flat list (for backward compatibility)
  static List<String> get presetMessages {
    return categorizedMessages.values.expand((messages) => messages).toList();
  }

  // Emoji options for profile pictures (unchanged)
  static const List<String> profileEmojis = [
    "😊", "🙂", "😇", "😎", "😅", "😉", "😐", "😶", "🙏", "✝️",
    "❤️", "🤍", "🔥", "⚓", "🛡️", "👊", "💪", "🤝", "🙌", "🕊️",
  ];

  // Reminder options in days (unchanged)
  static const List<int> reminderOptions = [0, 1, 3, 7, 14, 30];

  // App theme colors - modernized for iOS feel
  static const int primaryColorValue = 0xFF007AFF; // iOS blue
  static const int secondaryColorValue = 0xFF5AC8FA; // iOS light blue
  static const int accentColorValue = 0xFFFF9500; // iOS orange
  static const int backgroundColorValue = 0xFFF2F2F7; // iOS light background
  static const int cardColorValue = 0xFFFFFFFF; // Pure white cards

  // Text colors - iOS standard
  static const int primaryTextColorValue = 0xFF000000; // Pure black
  static const int secondaryTextColorValue = 0xFF8E8E93; // iOS gray

  // UI Element colors - iOS style
  static const int profileCircleColorValue = 0xFFE1E6EB; // Light gray for profile circles
  static const int emojiPickerColorValue = 0xFFF2F2F7; // Light background for emoji picker
  static const int notificationSettingsColorValue = 0xFFF9F9FB; // Very light for settings
  static const int dialogBackgroundColorValue = 0xFFFFFFFF; // White for dialogs
  static const int bottomSheetHandleColorValue = 0xFFDCDCDD; // iOS-style handle
  static const int deleteColorValue = 0xFFFF3B30; // iOS red
  static const int borderColorValue = 0xFFDCDCDC; // iOS light border

  // Additional iOS-style colors
  static const int iosSuccessGreen = 0xFF34C759; // iOS green
  static const int iosSeparatorColor = 0xFFC6C6C8; // iOS separator color
  static const int iosGroupedBackground = 0xFFF2F2F7; // iOS grouped background

  // Card shape and elevation
  static const double cardBorderRadius = 14.0;
  static const double cardElevation = 0.5;

  // Helper method to easily get Color objects
  static Color get primaryColor => const Color(primaryColorValue);
  static Color get secondaryColor => const Color(secondaryColorValue);
  static Color get accentColor => const Color(accentColorValue);
  static Color get backgroundColor => const Color(backgroundColorValue);
  static Color get cardColor => const Color(cardColorValue);
  static Color get primaryTextColor => const Color(primaryTextColorValue);
  static Color get secondaryTextColor => const Color(secondaryTextColorValue);
  static Color get profileCircleColor => const Color(profileCircleColorValue);
  static Color get emojiPickerColor => const Color(emojiPickerColorValue);
  static Color get notificationSettingsColor => const Color(notificationSettingsColorValue);
  static Color get dialogBackgroundColor => const Color(dialogBackgroundColorValue);
  static Color get bottomSheetHandleColor => const Color(bottomSheetHandleColorValue);
  static Color get deleteColor => const Color(deleteColorValue);
  static Color get borderColor => const Color(borderColorValue);

  // Helper methods for iOS-specific colors
  static Color get successGreen => const Color(iosSuccessGreen);
  static Color get separatorColor => const Color(iosSeparatorColor);
  static Color get groupedBackground => const Color(iosGroupedBackground);

  // Common text styles
  static TextStyle get title1 => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.35,
    color: Color(primaryTextColorValue),
  );

  static TextStyle get title2 => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.35,
    color: Color(primaryTextColorValue),
  );

  static TextStyle get title3 => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
    color: Color(primaryTextColorValue),
  );

  static TextStyle get headline => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: Color(primaryTextColorValue),
  );

  static TextStyle get body => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.41,
    color: Color(primaryTextColorValue),
  );

  static TextStyle get callout => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.32,
    color: Color(primaryTextColorValue),
  );

  static TextStyle get subhead => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.24,
    color: Color(primaryTextColorValue),
  );

  static TextStyle get footnote => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    letterSpacing: -0.08,
    color: Color(secondaryTextColorValue),
  );

  static TextStyle get caption => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0,
    color: Color(secondaryTextColorValue),
  );
}