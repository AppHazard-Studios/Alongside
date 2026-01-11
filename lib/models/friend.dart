import 'day_selection_data.dart';

class Friend {
  final String id;
  final String name;
  final String phoneNumber;
  final String? countryCode; // NEW: Separate country code storage
  final String profileImage; // Path to image or emoji string
  final bool isEmoji;
  final int reminderDays; // DEPRECATED: Keep for backward compatibility
  final String reminderTime; // Format: "HH:MM" (24-hour)
  final String? reminderData; // NEW: Stores the DaySelectionData as string
  final bool hasPersistentNotification;
  final bool isFavorite;
  final String? helpingWith; // What you're helping them with
  final String? theyHelpingWith; // What they're helping you with
  final bool countryCodeSkipped; // NEW: Track if user intentionally skipped country code

  Friend({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.countryCode,
    required this.profileImage,
    required this.isEmoji,
    this.reminderDays = 0,
    this.reminderTime = "09:00",
    this.reminderData,
    this.hasPersistentNotification = false,
    this.isFavorite = false,
    this.helpingWith = '',
    this.theyHelpingWith = '',
    this.countryCodeSkipped = false,
  });

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'profileImage': profileImage,
      'isEmoji': isEmoji,
      'reminderDays': reminderDays,
      'reminderTime': reminderTime,
      'reminderData': reminderData,
      'hasPersistentNotification': hasPersistentNotification,
      'isFavorite': isFavorite,
      'helpingWith': helpingWith,
      'theyHelpingWith': theyHelpingWith,
      'countryCodeSkipped': countryCodeSkipped,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    String phoneNumber = json['phoneNumber'];
    String? countryCode = json['countryCode'];

    // Migration: extract country code but keep local format
    if (countryCode == null && phoneNumber.startsWith('+')) {
      final match = RegExp(r'^\+(\d{1,4})').firstMatch(phoneNumber);
      if (match != null) {
        countryCode = '+${match.group(1)}';
        phoneNumber = phoneNumber.substring(countryCode.length).trim();

        // Add leading 0 back for local format (countries that need it)
        final countriesWithLeadingZero = [
          '+61', '+44', '+64', '+27', '+91', '+92', '+234', '+254', '+63',
          '+60', '+62', '+66', '+84', '+20', '+972', '+90', '+880'
        ];

        if (countriesWithLeadingZero.contains(countryCode) && !phoneNumber.startsWith('0')) {
          phoneNumber = '0$phoneNumber';
        }
      }
    }

    return Friend(
      id: json['id'],
      name: json['name'],
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      profileImage: json['profileImage'],
      isEmoji: json['isEmoji'],
      reminderDays: json['reminderDays'] ?? 0,
      reminderTime: json['reminderTime'] ?? "09:00",
      reminderData: json['reminderData'],
      hasPersistentNotification: json['hasPersistentNotification'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      helpingWith: json['helpingWith'] ?? '',
      theyHelpingWith: json['theyHelpingWith'] ?? '',
      countryCodeSkipped: json['countryCodeSkipped'] ?? false,
    );
  }

  Friend copyWith({
    String? name,
    String? phoneNumber,
    String? countryCode,
    String? profileImage,
    bool? isEmoji,
    int? reminderDays,
    String? reminderTime,
    String? reminderData,
    bool? hasPersistentNotification,
    bool? isFavorite,
    String? helpingWith,
    String? theyHelpingWith,
    bool? countryCodeSkipped,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
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
      countryCodeSkipped: countryCodeSkipped ?? this.countryCodeSkipped,
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

  // NEW: Get full phone number with country code for display
  String get fullPhoneNumber {
    if (countryCode != null && countryCode!.isNotEmpty) {
      return '$countryCode $phoneNumber';
    }
    return phoneNumber;
  }
}