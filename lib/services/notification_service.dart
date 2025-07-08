// lib/services/notification_service.dart - FIXED WORKMANAGER CALLBACK
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:workmanager/workmanager.dart';
import 'storage_service.dart';

typedef NotificationActionCallback = void Function(String friendId, String action);

// REPLACE the entire callbackDispatcher section with this CLEAN version:

// CLEAN WORKMANAGER DISPATCHER - No debug info, clean notifications only
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // NO debug logging that could leak into notifications

    try {
      if (task == "send_reminder") {
        final friendId = inputData?['friendId'] as String?;
        final friendName = inputData?['friendName'] as String?;
        final reminderDays = inputData?['reminderDays'] as int? ?? 1;

        if (friendId != null && friendName != null) {
          // Send ONLY a clean notification, no debug info
          await _sendCleanBackgroundNotification(friendId, friendName, reminderDays);
          return Future.value(true);
        }
      }
    } catch (e) {
      // Silent error handling - don't let errors leak into notifications
    }

    return Future.value(false);
  });
}

// COMPLETELY CLEAN background notification - no WorkManager contamination

// REPLACE the _sendCleanBackgroundNotification function with this CLEAN MESSAGING version:
Future<void> _sendCleanBackgroundNotification(String friendId, String friendName, int reminderDays) async {
  try {
    // Fresh, isolated notification service for background
    final notificationPlugin = FlutterLocalNotificationsPlugin();

    // Minimal initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await notificationPlugin.initialize(initSettings);

    // Simple notification ID
    final notificationId = friendName.hashCode.abs() % 999999 + 100000;

    // CLEAN, USER-FRIENDLY notification with proper language
    await notificationPlugin.show(
      notificationId,
      'Time to check in with $friendName',
      'It\'s been $reminderDays ${reminderDays == 1 ? 'day' : 'days'}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alongside_reminders',
          'Friend Reminders',
          channelDescription: 'Reminders to check in with friends',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          autoCancel: true,
          showWhen: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'message',
              'Message',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'call',
              'Call',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: friendId,
    );

  } catch (e) {
    // Silent - don't let background errors contaminate notifications
  }
}

// Schedule next reminder in background
Future<void> _scheduleNextReminder(String friendId, String friendName, int reminderDays) async {
  try {
    print("🔄 Scheduling next reminder for: $friendName");

    // Calculate next time (simple version for background)
    final nextTime = DateTime.now().add(Duration(days: reminderDays));
    final delay = nextTime.difference(DateTime.now());

    if (delay.isNegative) return;

    // Schedule next WorkManager task
    await Workmanager().registerOneOffTask(
      "reminder_$friendId",
      "send_reminder",
      initialDelay: delay,
      inputData: {
        'friendId': friendId,
        'friendName': friendName,
        'reminderDays': reminderDays,
      },
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    print("✅ Next reminder scheduled for: $nextTime");

  } catch (e) {
    print("❌ Next reminder scheduling error: $e");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  NotificationActionCallback? _actionCallback;
  bool _isInitialized = false;
  static const int _persistentOffset = 2000000;

  void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("\n🚀 INITIALIZING FIXED HYBRID SYSTEM");

      // Initialize timezone
      tz_data.initializeTimeZones();
      String timeZoneName;
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        timeZoneName = 'UTC';
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("📍 Timezone: $timeZoneName");

      // Initialize notifications
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationResponse,
      );

      await _createNotificationChannels();

      // Initialize WorkManager with simplified callback
      if (Platform.isAndroid) {
        await Workmanager().initialize(callbackDispatcher, isInDebugMode: false); // Enable debug for now
        print("🔄 WorkManager initialized with fixed callback");
      }

      await _requestPermissions();

      _isInitialized = true;
      print("✅ FIXED HYBRID SYSTEM READY\n");
    } catch (e) {
      print("❌ INITIALIZATION ERROR: $e");
    }
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // High-priority reminder channel
    const reminderChannel = AndroidNotificationChannel(
      'alongside_reminders',
      'Friend Reminders',
      description: 'Reminders to check in with friends',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidPlugin.createNotificationChannel(reminderChannel);

    const persistentChannel = AndroidNotificationChannel(
      'alongside_persistent',
      'Quick Access',
      description: 'Persistent notifications for quick friend access',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );
    await androidPlugin.createNotificationChannel(persistentChannel);

    print("📱 Notification channels created");
  }

  Future<void> _requestPermissions() async {
    try {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
      await Permission.ignoreBatteryOptimizations.request();
      print("🔐 Permissions requested");
    } catch (e) {
      print("❌ Permission error: $e");
    }
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(NotificationResponse response) {
    print("🔔 BACKGROUND: ${response.payload}");
  }

  void _handleNotificationResponse(NotificationResponse response) {
    print("🔔 FOREGROUND: ${response.payload}, Action: ${response.actionId}");

    final String? payload = response.payload;
    final String? actionId = response.actionId;

    if (payload == null || payload.isEmpty) return;

    final parts = payload.split(";");
    if (parts.isEmpty) return;

    final friendId = parts[0];
    if (friendId.isNotEmpty) {
      _actionCallback?.call(friendId, actionId ?? "tap");
    }
  }

  // SIMPLIFIED WORKMANAGER SCHEDULING
  Future<bool> scheduleReminder(Friend friend) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (friend.reminderDays <= 0) {
      await cancelReminder(friend.id);
      return false;
    }

    print("\n🔄 SIMPLIFIED WORKMANAGER SCHEDULING FOR: ${friend.name}");

    try {
      await cancelReminder(friend.id);

      final nextTime = await _calculateNextReminderTime(friend);
      if (nextTime == null) return false;

      return await _scheduleWithWorkManager(friend, nextTime);

    } catch (e) {
      print("❌ SCHEDULING ERROR: $e");
      return false;
    }
  }

  Future<bool> _scheduleWithWorkManager(Friend friend, DateTime nextTime) async {
    try {
      print("\n🔄 WORKMANAGER SCHEDULING");

      final now = DateTime.now();
      final delay = nextTime.difference(now);

      print("   Friend: ${friend.name}");
      print("   Next time: $nextTime");
      print("   Delay: $delay");

      if (delay.isNegative || delay.inMinutes < 1) {
        print("❌ Invalid delay time");
        return false;
      }

      // Cancel existing
      await Workmanager().cancelByUniqueName("reminder_${friend.id}");

      // Schedule with WorkManager
      await Workmanager().registerOneOffTask(
        "reminder_${friend.id}",
        "send_reminder",
        initialDelay: delay,
        inputData: {
          'friendId': friend.id,
          'friendName': friend.name,
          'reminderDays': friend.reminderDays,
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // Store next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('next_reminder_${friend.id}', nextTime.millisecondsSinceEpoch);

      print("✅ WorkManager task scheduled for ${friend.name}");
      return true;

    } catch (e) {
      print("❌ WorkManager scheduling failed: $e");
      return false;
    }
  }

  Future<DateTime?> _calculateNextReminderTime(Friend friend) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    final timeParts = friend.reminderTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    final lastActionTime = prefs.getInt('last_action_${friend.id}');

    DateTime nextTime;

    if (lastActionTime == null) {
      nextTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (nextTime.isBefore(now.add(Duration(minutes: 2)))) {
        nextTime = nextTime.add(Duration(days: 1));
      }
    } else {
      final lastAction = DateTime.fromMillisecondsSinceEpoch(lastActionTime);
      nextTime = DateTime(
        lastAction.year,
        lastAction.month,
        lastAction.day + friend.reminderDays,
        hour,
        minute,
      );
    }

    while (nextTime.isBefore(now.add(Duration(minutes: 1)))) {
      nextTime = nextTime.add(Duration(days: friend.reminderDays));
    }

    print("📅 Next reminder calculated: $nextTime");
    return nextTime;
  }

  int _getNotificationId(String friendId) {
    int hash = 0;
    for (int i = 0; i < friendId.length; i++) {
      hash = ((hash * 31) + friendId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 100000 + (hash % 900000);
  }

  Future<void> cancelReminder(String friendId) async {
    try {
      await Workmanager().cancelByUniqueName("reminder_$friendId");

      final notificationId = _getNotificationId(friendId);
      await flutterLocalNotificationsPlugin.cancel(notificationId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('next_reminder_$friendId');

      print("🗑️ Cancelled all for: $friendId");
    } catch (e) {
      print("❌ Cancel error: $e");
    }
  }

  Future<void> recordFriendInteraction(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt('last_action_$friendId', now.millisecondsSinceEpoch);
      print("📝 Recorded interaction: $friendId at $now");
    } catch (e) {
      print("❌ Record error: $e");
    }
  }

  Future<DateTime?> getNextReminderTime(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final time = prefs.getInt('next_reminder_$friendId');
      return time != null ? DateTime.fromMillisecondsSinceEpoch(time) : null;
    } catch (e) {
      return null;
    }
  }

  // SIMPLIFIED TEST METHODS
// REPLACE the scheduleTestIn30Seconds method with this CLEAN version:
  Future<void> scheduleTestIn30Seconds() async {
    try {
      print("\n🧪 CLEAN SCHEDULED TEST IN 30 SECONDS");

      await Workmanager().cancelByUniqueName("test_30s");

      await Workmanager().registerOneOffTask(
        "test_30s",
        "send_reminder",
        initialDelay: Duration(seconds: 30),
        inputData: {
          'friendId': 'test_scheduled',
          'friendName': 'Test Friend',
          'reminderDays': 3, // Different from immediate test
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      print("✅ Clean scheduled test planned");

    } catch (e) {
      print("❌ Scheduled test error: $e");
    }
  }

  Future<void> scheduleTestNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        999999,
        'Time to check in with Test Friend',
        'Immediate test - It\'s been 1 day',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alongside_reminders',
            'Friend Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'message',
                'Message',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              AndroidNotificationAction(
                'call',
                'Call',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
        ),
        payload: 'test_immediate',
      );
      print("📨 Clean immediate test sent");
    } catch (e) {
      print("❌ Immediate test error: $e");
    }
  }

  // Simplified utility methods
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }

  Future<void> debugScheduledNotifications() async {
    try {
      print("\n🔄 FIXED HYBRID DEBUG");
      print("=" * 50);

      final now = DateTime.now();
      print("⏰ Current time: $now");

      final pending = await getPendingNotifications();
      print("\n📋 PENDING NOTIFICATIONS: ${pending.length}");
      for (final notification in pending) {
        print("   ID: ${notification.id} - ${notification.title}");
      }

      final prefs = await SharedPreferences.getInstance();
      final reminderKeys = prefs.getKeys().where((k) => k.startsWith('next_reminder_'));

      print("\n📝 WORKMANAGER REMINDERS:");
      for (final key in reminderKeys) {
        final time = prefs.getInt(key);
        if (time != null) {
          final friendId = key.replaceFirst('next_reminder_', '');
          final dateTime = DateTime.fromMillisecondsSinceEpoch(time);
          final isPast = dateTime.isBefore(now);
          print("   $friendId: $dateTime ${isPast ? '(OVERDUE)' : ''}");
        }
      }

      print("=" * 50);

    } catch (e) {
      print("❌ Debug error: $e");
    }
  }

  Future<void> checkAndExtendSchedule() async {
    print("🔍 WorkManager handles scheduling automatically");
  }

  // Persistent notifications (unchanged)
  Future<void> showPersistentNotification(Friend friend) async {
    if (!friend.hasPersistentNotification) return;

    try {
      final id = _persistentOffset + _getNotificationId(friend.id);
      await flutterLocalNotificationsPlugin.show(
        id,
        'Alongside ${friend.name}',
        'Tap to check in',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alongside_persistent',
            'Quick Access',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
          ),
        ),
        payload: '${friend.id};${friend.phoneNumber}',
      );
    } catch (e) {
      print("❌ Persistent error: $e");
    }
  }

  Future<void> removePersistentNotification(String friendId) async {
    try {
      final id = _persistentOffset + _getNotificationId(friendId);
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print("❌ Remove persistent error: $e");
    }
  }
}