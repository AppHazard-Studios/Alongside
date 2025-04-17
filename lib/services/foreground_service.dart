// lib/services/foreground_service.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'storage_service.dart';
import 'notification_service.dart';

// The callback function should be a top-level function
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background
  FlutterForegroundTask.setTaskHandler(AlongsideTaskHandler());
}

class AlongsideTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  Timer? _timer;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // Initialize notification service
    await _notificationService.initialize();

    // Start a timer to periodically check and update notifications
    _timer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _checkAndUpdateNotifications();
    });

    // Initial check for notifications
    await _checkAndUpdateNotifications();
    _initialized = true;
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Check notifications when event is triggered
    if (_initialized) {
      await _checkAndUpdateNotifications();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _timer?.cancel();
    await FlutterForegroundTask.clearAllData();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // This is called periodically based on the interval
    if (_initialized) {
      await _checkAndUpdateNotifications();
    }
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button presses
    // Use the _sendPort to communicate with the main isolate if needed
    if (_sendPort != null) {
      _sendPort!.send({'action': id});
    }
  }

  Future<void> _checkAndUpdateNotifications() async {
    try {
      // Load friends
      final friends = await _storageService.getFriends();

      // Recreate persistent notifications
      for (final friend in friends) {
        if (friend.hasPersistentNotification) {
          await _notificationService.showPersistentNotification(friend);
        }

        // Check if a reminder needs to be scheduled
        if (friend.reminderDays > 0) {
          // Get the last notification time
          final prefs = await SharedPreferences.getInstance();
          final lastNotificationKey = 'last_notification_${friend.id}';
          final lastNotificationTime = prefs.getInt(lastNotificationKey);

          final now = DateTime.now().millisecondsSinceEpoch;

          // If we have a last notification time, check if it's time for a new one
          if (lastNotificationTime != null) {
            final elapsed = now - lastNotificationTime;
            final reminderInterval = Duration(days: friend.reminderDays).inMilliseconds;

            if (elapsed >= reminderInterval) {
              await _notificationService.showReminderNotification(friend);
              await prefs.setInt(lastNotificationKey, now);
            }
          } else {
            // If no previous notification, schedule one for the future
            await _notificationService.scheduleReminder(friend);
            // We'll set the last notification time when the notification is actually shown
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
      androidNotificationOptions: const AndroidNotificationOptions(
        channelId: 'alongside_foreground',
        channelName: 'Alongside Foreground Service',
        channelDescription: 'Keeps alongside friends notifications active',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // Removed iconData
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 15 * 60 * 1000, // 15 minutes
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
    );
  }

  // Start the foreground service
  static Future<bool> startForegroundService() async {
    // Check if the service is running
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      return true;
    }

    // Start the service
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Alongside Friends',
      notificationText: 'Running in background to keep your connections active',
      callback: startCallback,
    );

    return result == ServiceResult.success;
  }

  // Stop the foreground service
  static Future<bool> stopForegroundService() async {
    final result = await FlutterForegroundTask.stopService();
    return result == ServiceResult.success;
  }
}