// utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // Preset messages for check-ins
  static const List<String> presetMessages = [
    // ✅ Check-ins
    "Just checking in. How are you doing today?",
    "Thinking of you today — how's everything going?",

    // 🟡 Struggle
    "Feeling tempted and didn't want to keep it to myself.",
    "Struggling a bit right now. Just wanted to reach out.",

    // 🔴 Confession
    "Hey — I slipped up. Trying to stay honest with you.",
    "Not proud of today. Thanks for walking with me anyway.",
  ];

  // Emoji options for profile pictures
  static const List<String> profileEmojis = [
    "😊", // kind, warm
    "🙂", // steady, approachable
    "😇", // faithful, gentle
    "😎", // confident, relaxed
    "😅", // honest, human
    "😉", // playful, close
    "😐", // lowkey, chill
    "😶", // quiet type, good listener
    "🙏", // spiritual, prayerful
    "✝️", // Jesus-centered
    "❤️", // compassionate, loving
    "🤍", // pure-hearted, gentle
    "🔥", // intense, passionate
    "⚓", // steady, grounded
    "🛡️", // protector type
    "👊", // strong and loyal
    "💪", // determined, resilient
    "🤝", // dependable, mutual support
    "🙌", // encourager, uplifting
    "🕊️", // peaceful, calm presence
  ];

  // Reminder options in days
  static const List<int> reminderOptions = [0, 1, 3, 7, 14, 30];

  // App theme colors
  static const int primaryColorValue = 0xFF3F8CFF; // Vibrant blue
  static const int secondaryColorValue = 0xFF2DCCA7; // Teal accent
  static const int accentColorValue = 0xFFFFAB40; // Warm orange accent
  static const int backgroundColorValue =
  0xFFF8FBFF; // Light blue-tinted background
  static const int cardColorValue = 0xFFFFFFFF; // Pure white cards

  // Text colors
  static const int primaryTextColorValue = 0xFF2A3747; // Dark blue-gray
  static const int secondaryTextColorValue = 0xFF617387; // Medium blue-gray

  // UI Element colors
  static const int profileCircleColorValue =
  0xFFEEF6FF; // Light blue for profile circles
  static const int emojiPickerColorValue =
  0xFFE9F2FF; // Light blue for emoji picker backgrounds
  static const int notificationSettingsColorValue =
  0xFFF4F8FF; // Very light blue for settings
  static const int dialogBackgroundColorValue = 0xFFFFFFFF; // White for dialogs
  static const int bottomSheetHandleColorValue =
  0xFFDDEAFF; // Light blue for handles
  static const int deleteColorValue = 0xFFFF4D6B; // Soft red for delete actions
  static const int borderColorValue = 0xFFE1EBFD; // Light blue borders

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
}