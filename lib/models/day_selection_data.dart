// lib/models/day_selection_data.dart - UPDATED FILE
import 'dart:convert';

enum RepeatInterval {
  weekly,
  biweekly,
  monthly,
  quarterly,    // Every 3 months
  semiannually, // Every 6 months
}

class DaySelectionData {
  final Set<int> selectedDays; // 1-7 where 1 is Monday, 7 is Sunday
  final RepeatInterval interval;

  DaySelectionData({
    required this.selectedDays,
    required this.interval,
  });

  // Convert to JSON string for storage
  String toJson() {
    return jsonEncode({
      'selectedDays': selectedDays.toList(),
      'interval': interval.index,
    });
  }

  // Create from JSON string
  factory DaySelectionData.fromJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return DaySelectionData(
        selectedDays: Set<int>.from(json['selectedDays'] ?? []),
        interval: RepeatInterval.values[json['interval'] ?? 0],
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
      case RepeatInterval.quarterly:
        return 'Every 3 months on $daysText';
      case RepeatInterval.semiannually:
        return 'Every 6 months on $daysText';
    }
  }

  // Calculate next reminder date based on selected days and interval
// Calculate next reminder date based on selected days and interval
  DateTime? calculateNextReminder(DateTime from, int hour, int minute) {
    if (selectedDays.isEmpty) return null;

    // STEP 1: Apply the interval to get the target date range
    DateTime targetDate = _applyIntervalFromDate(from);

    // STEP 2: Find the next selected day at or after the target date
    DateTime candidate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    // If the calculated time has already passed, start from tomorrow
    if (candidate.isBefore(DateTime.now())) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // STEP 3: Find the next occurrence of a selected day
    int daysToAdd = 0;
    int currentWeekday = candidate.weekday;
    bool found = false;

    // Check the next 7 days to find a selected day
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

    return candidate;
  }

// Helper method to apply the interval to a date
  DateTime _applyIntervalFromDate(DateTime from) {
    switch (interval) {
      case RepeatInterval.weekly:
        return from.add(const Duration(days: 7));

      case RepeatInterval.biweekly:
        return from.add(const Duration(days: 14));

      case RepeatInterval.monthly:
        return DateTime(
          from.month == 12 ? from.year + 1 : from.year,
          from.month == 12 ? 1 : from.month + 1,
          from.day,
          from.hour,
          from.minute,
        );

      case RepeatInterval.quarterly:
        int newMonth = from.month + 3;
        int newYear = from.year;
        if (newMonth > 12) {
          newMonth -= 12;
          newYear += 1;
        }
        return DateTime(
          newYear,
          newMonth,
          from.day,
          from.hour,
          from.minute,
        );

      case RepeatInterval.semiannually:
        int newMonth = from.month + 6;
        int newYear = from.year;
        if (newMonth > 12) {
          newMonth -= 12;
          newYear += 1;
        }
        return DateTime(
          newYear,
          newMonth,
          from.day,
          from.hour,
          from.minute,
        );
    }
  }

  DaySelectionData copyWith({
    Set<int>? selectedDays,
    RepeatInterval? interval,
  }) {
    return DaySelectionData(
      selectedDays: selectedDays ?? this.selectedDays,
      interval: interval ?? this.interval,
    );
  }
}