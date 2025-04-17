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
  static const int primaryColorValue = 0xFFAC7858; // Brown primary color
  static const int secondaryColorValue = 0xFFCDAA84; // Lighter brown
  static const int backgroundColorValue = 0xFFFCF5EC; // Light beige background
  static const int cardColorValue = 0xFFFDF8F2; // White-ish card background

  // Text colors
  static const int primaryTextColorValue = 0xFF4F453D; // Dark grey
  static const int secondaryTextColorValue = 0xFF867C74; // Medium grey

  // UI Element colors
  static const int profileCircleColorValue = 0xFFECE4DC; // Light beige for profile circles
  static const int emojiPickerColorValue = 0xFFECE4DC; // For emoji picker backgrounds
  static const int notificationSettingsColorValue = 0xFFFDF8F2; // Light grey for notification settings
  static const int dialogBackgroundColorValue = 0xFFFDF8F2; // Background for dialogs
  static const int bottomSheetHandleColorValue = 0xFFDDDDDD; // Color for bottom sheet drag handle
  static const int deleteColorValue = 0xFFE53935; // Red color for delete actions
  static const int borderColorValue = 0xFFE0D6CF; // Border color for cards & inputs

  // Opacity variants for primary color
  static const double emphasizedOpacity = 1.0;
  static const double mediumOpacity = 0.7;
  static const double lightOpacity = 0.3;

  // Helper method to easily get Color objects
  static Color get primaryColor => const Color(primaryColorValue);
  static Color get secondaryColor => const Color(secondaryColorValue);
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