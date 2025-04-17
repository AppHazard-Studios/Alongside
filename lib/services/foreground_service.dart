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
  // Register the task handler
  FlutterForegroundTask.setTaskHandler(AlongsideTaskHandler());
}

class AlongsideTaskHandler extends TaskHandler {
  Timer? _timer;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _notificationService.initialize();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _checkAndUpdateNotifications();
    });
    await _checkAndUpdateNotifications();
    _initialized = true;
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    if (_initialized) {
      await _checkAndUpdateNotifications();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool wasRunning) async {
    _timer?.cancel();
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_initialized) {
      await _checkAndUpdateNotifications();
    }
  }

  @override
  void onButtonPressed(String id) {
    // Use named parameter `key` here instead of positional
    FlutterForegroundTask.getData<String>(key: id).then((message) {
      print('Button pressed: $id, Message: $message');
    });
  }

  Future<void> _checkAndUpdateNotifications() async {
    try {
      final friends = await _storageService.getFriends();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final friend in friends) {
        if (friend.hasPersistentNotification) {
          await _notificationService.showPersistentNotification(friend);
        }
        if (friend.reminderDays > 0) {
          final lastKey = 'last_notification_${friend.id}';
          final lastTime = prefs.getInt(lastKey);
          final interval = Duration(days: friend.reminderDays).inMilliseconds;

          if (lastTime != null && now - lastTime >= interval) {
            await _notificationService.showReminderNotification(friend);
            await prefs.setInt(lastKey, now);
          } else if (lastTime == null) {
            // Use correct _notificationService instance
            await _notificationService.scheduleReminder(friend);
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
      // Include the required eventAction parameter
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
      // `eventAction` is no longer a parameter here, so it has been removed
    );

    return result == true;
  }

  // Stop the foreground service
  static Future<bool> stopForegroundService() async {
    final result = await FlutterForegroundTask.stopService();
    return result == true;
  }
}
