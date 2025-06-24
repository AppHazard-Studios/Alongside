// lib/services/foreground_service.dart - Fixed reminder rescheduling
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
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;
  DateTime? _lastCheckTime;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _notificationService.initialize();
    _initialized = true;
    print("🚀 Foreground service started");
    // Initial check on start
    await _checkAndUpdateNotifications();
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Don't check on every event - only on repeat events
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool wasRunning) async {
    print("🛑 Foreground service stopped");
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_initialized) {
      // Check every 15 minutes minimum
      if (_lastCheckTime != null &&
          DateTime.now().difference(_lastCheckTime!).inMinutes < 15) {
        return;
      }
      _lastCheckTime = DateTime.now();

      // Only check during reasonable hours (7 AM - 11 PM)
      final hour = DateTime.now().hour;
      if (hour < 7 || hour > 23) {
        return;
      }

      print("🔄 Running periodic notification check at ${DateTime.now()}");
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

      print("👥 Checking notifications for ${friends.length} friends");

      for (final friend in friends) {
        // Handle persistent notifications
        if (friend.hasPersistentNotification) {
          await _notificationService.showPersistentNotification(friend);
        }

        // Handle scheduled reminders - IMPROVED LOGIC
        if (friend.reminderDays > 0) {
          final lastActionKey = 'last_action_${friend.id}';
          final nextReminderKey = 'next_reminder_${friend.id}';
          final activeReminderKey = 'active_reminder_${friend.id}';

          // Get stored times
          final lastActionTime = prefs.getInt(lastActionKey);
          final nextReminderTime = prefs.getInt(nextReminderKey);
          final activeReminder = prefs.getInt(activeReminderKey);

          // Debug logging
          print("\n📅 Checking reminder for ${friend.name}:");
          print("   Reminder days: ${friend.reminderDays}");
          print("   Reminder time: ${friend.reminderTime}");
          print("   Last action: ${lastActionTime != null ? DateTime.fromMillisecondsSinceEpoch(lastActionTime) : 'Never'}");
          print("   Next reminder: ${nextReminderTime != null ? DateTime.fromMillisecondsSinceEpoch(nextReminderTime) : 'Not scheduled'}");
          print("   Active reminder: ${activeReminder != null ? DateTime.fromMillisecondsSinceEpoch(activeReminder) : 'None'}");

          bool shouldReschedule = false;
          String reason = "";

          if (activeReminder == null || nextReminderTime == null) {
            // No active reminder scheduled
            shouldReschedule = true;
            reason = "No active reminder found";
          } else {
            final nextTime = DateTime.fromMillisecondsSinceEpoch(nextReminderTime);

            // Check if we've passed the scheduled time by more than an hour
            if (now.isAfter(nextTime.add(const Duration(hours: 1)))) {
              shouldReschedule = true;
              reason = "Past scheduled time";
            }

            // Check if last action was updated after the reminder was scheduled
            if (lastActionTime != null && activeReminder != null &&
                lastActionTime > activeReminder) {
              shouldReschedule = true;
              reason = "User interacted after reminder was scheduled";
            }
          }

          if (shouldReschedule) {
            print("   ⚠️ Rescheduling reminder - Reason: $reason");

            // Cancel any existing reminder first
            await _notificationService.cancelReminder(friend.id);

            // Schedule new reminder
            await _notificationService.scheduleReminder(friend);

            // Get the newly scheduled time for logging
            final newNextTime = await _notificationService.getNextReminderTime(friend.id);
            print("   ✅ New reminder scheduled for: $newNextTime");
          } else {
            print("   ✅ Reminder is properly scheduled");
          }
        }
      }

      print("✅ Notification check completed");
    } catch (e, stackTrace) {
      print('❌ Error checking notifications: $e');
      print('Stack trace: $stackTrace');
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
        showNotification: false, // iOS doesn't need to show this
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          const Duration(minutes: 15).inMilliseconds, // Check every 15 minutes
        ),
        autoRunOnBoot: true,
        allowWifiLock: false, // Don't need WiFi lock
        allowWakeLock: true, // Allow wake lock to ensure timely checks
      ),
    );
  }

  // Start the foreground service
  static Future<bool> startForegroundService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      print("ℹ️ Foreground service already running");
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Alongside Active',
      notificationText: 'Keeping your friend reminders on schedule',
      callback: startCallback,
    );

    print(result == true
        ? "✅ Foreground service started successfully"
        : "❌ Failed to start foreground service");

    return result == true;
  }

  // Stop the foreground service
  static Future<bool> stopForegroundService() async {
    final result = await FlutterForegroundTask.stopService();
    print(result == true
        ? "✅ Foreground service stopped"
        : "❌ Failed to stop foreground service");
    return result == true;
  }

  // Check if service is running
  static Future<bool> isServiceRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}