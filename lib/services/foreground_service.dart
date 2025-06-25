// lib/services/foreground_service.dart - Updated for better reliability
import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'storage_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(AlongsideTaskHandler());
}

class AlongsideTaskHandler extends TaskHandler {
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;
  Timer? _periodicTimer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      print("🚀 Foreground service starting...");
      await _notificationService.initialize();
      _initialized = true;

      // Start periodic timer for more reliable checks
      _periodicTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
        _performNotificationCheck();
      });

      // Initial check
      await _performNotificationCheck();

      print("✅ Foreground service started successfully");
    } catch (e) {
      print("❌ Error starting foreground service: $e");
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool wasRunning) async {
    print("🛑 Foreground service stopping...");
    _periodicTimer?.cancel();
    await FlutterForegroundTask.clearAllData();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    if (_initialized) {
      await _performNotificationCheck();
    }
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Handle any custom events if needed
  }

  void onButtonPressed(String id) {
    print('Foreground service button pressed: $id');
  }

  Future<void> _performNotificationCheck() async {
    try {
      print("🔄 Performing notification check at ${DateTime.now()}");

      // Check for missed reminders
      await _notificationService.checkAndRescheduleAllReminders();

      // Update persistent notifications
      final storageService = StorageService();
      final friends = await storageService.getFriends();

      for (final friend in friends) {
        if (friend.hasPersistentNotification) {
          await _notificationService.showPersistentNotification(friend);
        }

        // Verify reminders are properly scheduled
        if (friend.reminderDays > 0) {
          await _verifyAndFixReminder(friend);
        }
      }

      print("✅ Notification check completed");
    } catch (e, stackTrace) {
      print("❌ Error in notification check: $e");
      print("Stack: $stackTrace");
    }
  }

  Future<void> _verifyAndFixReminder(Friend friend) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nextReminderTime = prefs.getInt('next_reminder_${friend.id}');

      if (nextReminderTime == null) {
        print("⚠️ No reminder scheduled for ${friend.name} - scheduling now");
        await _notificationService.scheduleReminder(friend);
        return;
      }

      final nextReminder = DateTime.fromMillisecondsSinceEpoch(nextReminderTime);
      final now = DateTime.now();

      // Check if reminder is in the past (missed)
      if (now.isAfter(nextReminder)) {
        print("⚠️ Missed reminder for ${friend.name} - rescheduling");

        // Show immediate notification for missed reminder
        await _notificationService.scheduleTestNotification(); // You can create a specific method for this

        // Reschedule for next cycle
        await _notificationService.scheduleReminder(friend);
      } else {
        // Verify it's actually scheduled
        final pending = await _notificationService.getPendingNotifications();
        final id = 1000000 + friend.id.codeUnits.fold(0, (a, b) => ((a << 5) - a) + b) % 900000 + 100000;

        if (!pending.any((n) => n.id == id)) {
          print("⚠️ Reminder for ${friend.name} not in pending list - rescheduling");
          await _notificationService.scheduleReminder(friend);
        }
      }
    } catch (e) {
      print("❌ Error verifying reminder: $e");
    }
  }
}

class ForegroundServiceManager {
  static Future<void> initForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alongside_foreground',
        channelName: 'Alongside Background Service',
        channelDescription: 'Keeps reminders working reliably',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          const Duration(minutes: 30).inMilliseconds,
        ),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> startForegroundService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      print("ℹ️ Foreground service already running");
      return true;
    }

    // Request permission first
    if (!await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    // Request battery optimization exemption
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'Alongside Active',
      notificationText: 'Keeping your reminders on schedule',
      notificationIcon: null,
      notificationButtons: [],
      callback: startCallback,
    );

    print(result == true ? "✅ Foreground service started" : "❌ Failed to start");
    return result == true;
  }

  static Future<bool> stopForegroundService() async {
    final result = await FlutterForegroundTask.stopService();
    return result == true;
  }

  static Future<bool> isServiceRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }

  static Future<void> updateServiceNotification(String text) async {
    await FlutterForegroundTask.updateService(
      notificationText: text,
    );
  }
}