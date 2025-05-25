// models/friend.dart - Added favorite field
class Friend {
  final String id;
  final String name;
  final String phoneNumber;
  final String profileImage; // Path to image or emoji string
  final bool isEmoji;
  final int reminderDays; // Reminder frequency in days (0 = no reminder)
  final String reminderTime; // Format: "HH:MM" (24-hour)
  final bool hasPersistentNotification;
  final bool isFavorite; // NEW: For favorites/stories section
  final String? helpingWith; // What you're helping them with
  final String? theyHelpingWith; // What they're helping you with

  Friend({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.profileImage,
    required this.isEmoji,
    this.reminderDays = 0,
    this.reminderTime = "09:00", // Default to 9:00 AM
    this.hasPersistentNotification = false,
    this.isFavorite = false, // NEW: Default to false
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
      'hasPersistentNotification': hasPersistentNotification,
      'isFavorite': isFavorite, // NEW: Include in JSON
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
      hasPersistentNotification: json['hasPersistentNotification'] ?? false,
      isFavorite: json['isFavorite'] ?? false, // NEW: Handle existing data
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
    bool? hasPersistentNotification,
    bool? isFavorite, // NEW: Include in copyWith
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
      hasPersistentNotification: hasPersistentNotification ?? this.hasPersistentNotification,
      isFavorite: isFavorite ?? this.isFavorite, // NEW: Include in copyWith
      helpingWith: helpingWith ?? this.helpingWith,
      theyHelpingWith: theyHelpingWith ?? this.theyHelpingWith,
    );
  }
}