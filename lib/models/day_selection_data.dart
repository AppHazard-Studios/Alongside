// lib/models/day_selection_data.dart - NEW FILE
import 'dart:convert';

enum RepeatInterval {
  weekly,
  biweekly,
  monthly,
  custom
}

class DaySelectionData {
  final Set<int> selectedDays; // 1-7 where 1 is Monday, 7 is Sunday
  final RepeatInterval interval;
  final int customIntervalDays; // Only used when interval is custom

  DaySelectionData({
    required this.selectedDays,
    required this.interval,
    this.customIntervalDays = 0,
  });

  // Convert to JSON string for storage
  String toJson() {
    return jsonEncode({
      'selectedDays': selectedDays.toList(),
      'interval': interval.index,
      'customIntervalDays': customIntervalDays,
    });
  }

  // Create from JSON string
  factory DaySelectionData.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return DaySelectionData(
        selectedDays: Set<int>.from(json['selectedDays'] ?? []),
        interval: RepeatInterval.values[json['interval'] ?? 0],
        customIntervalDays: json['customIntervalDays'] ?? 0,
      );
    } catch (e) {
      // Return default if parsing fails
      return DaySelectionData(
        selectedDays: {},
        interval: RepeatInterval.weekly,
      );
    }
  }

  // Helper method to get human-readable description
  String getDescription() {
    if (selectedDays.isEmpty) return 'No days selected';

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDayNames = selectedDays
        .map((day) => dayNames[day - 1])
        .toList()
      ..sort((a, b) => dayNames.indexOf(a).compareTo(dayNames.indexOf(b)));

    String daysText = selectedDayNames.join(', ');

    switch (interval) {
      case RepeatInterval.weekly:
        return 'Every week on $daysText';
      case RepeatInterval.biweekly:
        return 'Every 2 weeks on $daysText';
      case RepeatInterval.monthly:
        return 'Monthly on $daysText';
      case RepeatInterval.custom:
        return 'Every $customIntervalDays days on $daysText';
    }
  }

  // Calculate next reminder date based on selected days and interval
  DateTime? calculateNextReminder(DateTime from, int hour, int minute) {
    if (selectedDays.isEmpty) return null;

    DateTime candidate = DateTime(from.year, from.month, from.day, hour, minute);

    // If the time has already passed today, start from tomorrow
    if (candidate.isBefore(from)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Find the next selected day
    int daysToAdd = 0;
    int currentWeekday = candidate.weekday;
    bool found = false;

    // First, check if we can use a day in the current week
    for (int i = 0; i < 7; i++) {
      int checkDay = ((currentWeekday - 1 + i) % 7) + 1;
      if (selectedDays.contains(checkDay)) {
        daysToAdd = i;
        found = true;
        break;
      }
    }

    if (!found) {
      // Should not happen if selectedDays is not empty
      return null;
    }

    candidate = candidate.add(Duration(days: daysToAdd));

    // Apply interval if we're past the first occurrence
    if (daysToAdd == 0 && candidate.isBefore(from)) {
      // We need to go to the next interval
      switch (interval) {
        case RepeatInterval.weekly:
          candidate = candidate.add(const Duration(days: 7));
          break;
        case RepeatInterval.biweekly:
          candidate = candidate.add(const Duration(days: 14));
          break;
        case RepeatInterval.monthly:
        // Add a month
          candidate = DateTime(
            candidate.month == 12 ? candidate.year + 1 : candidate.year,
            candidate.month == 12 ? 1 : candidate.month + 1,
            candidate.day,
            candidate.hour,
            candidate.minute,
          );
          break;
        case RepeatInterval.custom:
          candidate = candidate.add(Duration(days: customIntervalDays));
          break;
      }
    }

    return candidate;
  }

  DaySelectionData copyWith({
    Set<int>? selectedDays,
    RepeatInterval? interval,
    int? customIntervalDays,
  }) {
    return DaySelectionData(
      selectedDays: selectedDays ?? this.selectedDays,
      interval: interval ?? this.interval,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
    );
  }
}