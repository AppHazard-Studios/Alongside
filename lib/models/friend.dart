// lib/models/friend.dart - UPDATED FILE
import '../models/day_selection_data.dart';

class Friend {
  final String id;
  final String name;
  final String phoneNumber;
  final String profileImage; // Path to image or emoji string
  final bool isEmoji;
  final int reminderDays; // DEPRECATED: Keep for backward compatibility
  final String reminderTime; // Format: "HH:MM" (24-hour)
  final String? reminderData; // NEW: Stores the DaySelectionData as string
  final bool hasPersistentNotification;
  final bool isFavorite;
  final String? helpingWith; // What you're helping them with
  final String? theyHelpingWith; // What they're helping you with

  Friend({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profileImage,
    required this.isEmoji,
    this.reminderDays = 0,
    this.reminderTime = "09:00",
    this.reminderData,
    this.hasPersistentNotification = false,
    this.isFavorite = false,
    this.helpingWith = '',
    this.theyHelpingWith = '',
  });

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'isEmoji': isEmoji,
      'reminderDays': reminderDays,
      'reminderTime': reminderTime,
      'reminderData': reminderData,
      'hasPersistentNotification': hasPersistentNotification,
      'isFavorite': isFavorite,
      'helpingWith': helpingWith,
      'theyHelpingWith': theyHelpingWith,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      isEmoji: json['isEmoji'],
      reminderDays: json['reminderDays'] ?? 0,
      reminderTime: json['reminderTime'] ?? "09:00",
      reminderData: json['reminderData'],
      hasPersistentNotification: json['hasPersistentNotification'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      helpingWith: json['helpingWith'] ?? '',
      theyHelpingWith: json['theyHelpingWith'] ?? '',
    );
  }

  Friend copyWith({
    String? name,
    String? phoneNumber,
    String? profileImage,
    bool? isEmoji,
    int? reminderDays,
    String? reminderTime,
    String? reminderData,
    bool? hasPersistentNotification,
    bool? isFavorite,
    String? helpingWith,
    String? theyHelpingWith,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      isEmoji: isEmoji ?? this.isEmoji,
      reminderDays: reminderDays ?? this.reminderDays,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderData: reminderData ?? this.reminderData,
      hasPersistentNotification:
      hasPersistentNotification ?? this.hasPersistentNotification,
      isFavorite: isFavorite ?? this.isFavorite,
      helpingWith: helpingWith ?? this.helpingWith,
      theyHelpingWith: theyHelpingWith ?? this.theyHelpingWith,
    );
  }

  // Helper method to check if friend has any reminders
  bool get hasReminder {
    return reminderData != null || reminderDays > 0;
  }

  // NEW: Check if friend uses new day selection system
  bool get usesAdvancedReminders {
    return reminderData != null && reminderData!.isNotEmpty;
  }

  // NEW: Get display text for reminder frequency
  String get reminderDisplayText {
    if (usesAdvancedReminders) {
      try {
        final data = DaySelectionData.fromJson(reminderData!);
        return data.getDescription();
      } catch (e) {
        return 'Custom reminder';
      }
    } else if (reminderDays > 0) {
      // Fallback to old system
      if (reminderDays == 1) return 'Daily';
      if (reminderDays == 7) return 'Weekly';
      return 'Every $reminderDays days';
    } else {
      return 'No reminder';
    }
  }
}