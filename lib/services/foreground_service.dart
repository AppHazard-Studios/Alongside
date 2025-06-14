// lib/services/foreground_service.dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'notification_service.dart';

// The callback function should be a top-level function
@pragma('vm:entry-point')
void startCallback() {
  // Register the task handler
  FlutterForegroundTask.setTaskHandler(AlongsideTaskHandler());
}

class AlongsideTaskHandler extends TaskHandler {
  // REMOVED the duplicate timer - we only use onRepeatEvent
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;
  DateTime? _lastCheckTime;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _notificationService.initialize();
    _initialized = true;
    // Only check once on start, don't start a timer
    await _checkAndUpdateNotifications();
  }

  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Don't check on every event - only on repeat events
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool wasRunning) async {
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_initialized) {
      // Check every 15 minutes minimum (was 5)
      if (_lastCheckTime != null &&
          DateTime.now().difference(_lastCheckTime!).inMinutes < 15) {
        return;
      }
      _lastCheckTime = DateTime.now();

      // Only check during reasonable hours (8 AM - 10 PM)
      final hour = DateTime.now().hour;
      if (hour < 8 || hour > 22) {
        return;
      }

      await _checkAndUpdateNotifications();
    }
  }

  void onButtonPressed(String id) {
    FlutterForegroundTask.getData<String>(key: id).then((message) {
      print('Button pressed: $id, Message: $message');
    });
  }

  Future<void> _checkAndUpdateNotifications() async {
    try {
      final friends = await _storageService.getFriends();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      for (final friend in friends) {
        // Handle persistent notifications
        if (friend.hasPersistentNotification) {
          await _notificationService.showPersistentNotification(friend);
        }

        // Handle scheduled reminders - FIXED LOGIC
        if (friend.reminderDays > 0) {
          final lastActionKey = 'last_action_${friend.id}';
          final nextReminderKey = 'next_reminder_${friend.id}';
          final activeReminderKey = 'active_reminder_${friend.id}';

          // Get the last time user interacted with this friend
          final lastActionTime = prefs.getInt(lastActionKey);
          final nextReminderTime = prefs.getInt(nextReminderKey);
          final activeReminder = prefs.getInt(activeReminderKey);

          // Check if we need to schedule a new reminder
          bool shouldSchedule = false;

          if (activeReminder == null) {
            // No active reminder scheduled
            shouldSchedule = true;
          } else if (nextReminderTime != null) {
            final nextTime = DateTime.fromMillisecondsSinceEpoch(nextReminderTime);
            // If we're past the scheduled time + buffer, schedule next one
            if (now.isAfter(nextTime.add(Duration(hours: 1)))) {
              shouldSchedule = true;
            }
          }

          if (shouldSchedule) {
            // Cancel any existing reminder first
            await _notificationService.cancelReminder(friend.id);

            // Schedule the next reminder
            await _notificationService.scheduleReminder(friend);

            // Calculate next reminder time
            final parts = friend.reminderTime.split(':');
            final hour = int.tryParse(parts[0]) ?? 9;
            final minute = int.tryParse(parts[1]) ?? 0;

            DateTime baseTime = lastActionTime != null
                ? DateTime.fromMillisecondsSinceEpoch(lastActionTime)
                : now;

            DateTime nextTime = DateTime(
                baseTime.year,
                baseTime.month,
                baseTime.day + friend.reminderDays,
                hour,
                minute
            );

            // Make sure it's in the future
            while (nextTime.isBefore(now)) {
              nextTime = nextTime.add(Duration(days: friend.reminderDays));
            }

            await prefs.setInt(nextReminderKey, nextTime.millisecondsSinceEpoch);
          }
        }
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }
}

class ForegroundServiceManager {
  // Initialize the foreground service
  static Future<void> initForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alongside_foreground',
        channelName: 'Alongside Foreground Service',
        channelDescription: 'Keeps alongside friends notifications active',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          Duration(minutes: 15).inMilliseconds,
        ),
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
    );
  }

  // Start the foreground service
  static Future<bool> startForegroundService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) return true;

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Alongside Friends',
      notificationText: 'Running in background to keep your connections active',
      callback: startCallback,
    );

    return result == true;
  }

  // Stop the foreground service
  static Future<bool> stopForegroundService() async {
    final result = await FlutterForegroundTask.stopService();
    return result == true;
  }
}