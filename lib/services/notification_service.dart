// lib/services/notification_service.dart - COMPLETE FIXED VERSION
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:workmanager/workmanager.dart';

typedef NotificationActionCallback = void Function(String friendId, String action);

// WorkManager callback - MUST be top-level
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🔄 WorkManager task started: $task");

    if (task == "checkReminders") {
      final service = NotificationService();
      await service.initialize();
      await service.checkAndRescheduleAllReminders();
    }

    return Future.value(true);
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  NotificationActionCallback? _actionCallback;
  bool _isInitialized = false;

  // Use stable IDs to avoid conflicts
  static const int _idOffset = 1000000;
  static const int _persistentOffset = 2000000;

  void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  // Initialize with proper timezone handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("🚀 Starting notification service initialization...");

      // Initialize timezone with proper local detection
      await _initializeTimezone();

      // Android settings with high priority icon
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationResponse,
      );

      if (initialized == true) {
        print("✅ Notification plugin initialized");

        // Create notification channels - CLEANED UP VERSION
        await _createNotificationChannels();

        // Request all permissions
        await _requestAllPermissions();

        // Initialize WorkManager for backup scheduling
        await _initializeWorkManager();

        _isInitialized = true;
        print("✅ Notification service fully initialized");
      }
    } catch (e, stackTrace) {
      print("❌ Error initializing notifications: $e");
      print("Stack trace: $stackTrace");
    }
  }

  // Initialize timezone properly
  Future<void> _initializeTimezone() async {
    try {
      tz_data.initializeTimeZones();

      // Get the device's timezone
      String timeZoneName;
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        print("⚠️ Could not detect timezone, using default");
        timeZoneName = 'America/New_York';
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        print("✅ Timezone set to: $timeZoneName");
      } catch (e) {
        print("⚠️ Failed to set timezone $timeZoneName, using UTC");
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      print("❌ Critical timezone error: $e");
      tz.setLocalLocation(tz.UTC);
    }
  }

  // Initialize WorkManager as backup
  Future<void> _initializeWorkManager() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // Register periodic task to check reminders every 6 hours
      await Workmanager().registerPeriodicTask(
        "checkRemindersTask",
        "checkReminders",
        frequency: const Duration(hours: 6),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
        ),
      );

      print("✅ WorkManager initialized for backup scheduling");
    } catch (e) {
      print("⚠️ WorkManager initialization failed: $e");
    }
  }

  // Create channels with proper configuration - CLEANED UP TO SINGLE CHANNEL
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    try {
      // SINGLE HIGH PRIORITY channel for all reminders
      const reminderChannel = AndroidNotificationChannel(
        'alongside_reminders',
        'Friend Reminders',
        description: 'Reminders to check in with friends',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
        ledColor: Colors.blue,
      );
      await androidPlugin.createNotificationChannel(reminderChannel);

      // Persistent channel remains separate
      const persistentChannel = AndroidNotificationChannel(
        'alongside_persistent',
        'Quick Access',
        description: 'Persistent notifications for quick friend access',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );
      await androidPlugin.createNotificationChannel(persistentChannel);

      print("✅ Notification channels created");
    } catch (e) {
      print("❌ Error creating channels: $e");
    }
  }

  // Request all permissions
  Future<bool> _requestAllPermissions() async {
    try {
      bool allGranted = true;

      // Notification permission (Android 13+)
      if (Platform.isAndroid) {
        if (await Permission.notification.isDenied) {
          final status = await Permission.notification.request();
          allGranted &= status.isGranted;
          print("📱 Notification permission: ${status.name}");
        }

        // Schedule exact alarm (Android 12+)
        if (await Permission.scheduleExactAlarm.isDenied) {
          final status = await Permission.scheduleExactAlarm.request();
          allGranted &= status.isGranted;
          print("⏰ Exact alarm permission: ${status.name}");
        }

        // Ignore battery optimizations
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          final status = await Permission.ignoreBatteryOptimizations.request();
          print("🔋 Battery optimization: ${status.name}");
        }
      }

      return allGranted;
    } catch (e) {
      print("❌ Error requesting permissions: $e");
      return false;
    }
  }

  // Background notification handler
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(NotificationResponse response) {
    // Handle notification in background
    print("🔔 Background notification: ${response.payload}");
  }

  // Handle notification response
  void _handleNotificationResponse(NotificationResponse response) {
    try {
      final String? payload = response.payload;
      final String? actionId = response.actionId;

      print("📲 Notification tapped - Action: $actionId, Payload: $payload");

      if (payload == null || payload.isEmpty) return;

      final parts = payload.split(";");
      if (parts.isEmpty) return;

      final friendId = parts[0];

      if (friendId.isNotEmpty) {
        // Update last action time immediately
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('last_action_$friendId', DateTime.now().millisecondsSinceEpoch);
        });

        // Trigger callback
        _actionCallback?.call(friendId, actionId ?? "tap");
      }
    } catch (e) {
      print("❌ Error handling notification: $e");
    }
  }

  // Schedule reminder with FIXED timing logic
  Future<bool> scheduleReminder(Friend friend) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return false;
    }

    if (friend.reminderDays <= 0) {
      await cancelReminder(friend.id);
      return false;
    }

    try {
      // Generate stable ID
      final id = _getStableNotificationId(friend.id);

      // Cancel existing reminder
      await cancelReminder(friend.id);

      // Calculate next reminder time
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      // Parse time
      final timeParts = friend.reminderTime.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 9;
      final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      DateTime nextReminder;

      // Check if we have reminder data for day-based scheduling
      if (friend.reminderData != null && friend.reminderData!.isNotEmpty) {
        // Day-based scheduling - will be implemented with the new feature
        nextReminder = _calculateNextDayBasedReminder(friend, now, hour, minute);
      } else {
        // Interval-based scheduling
        final lastActionTime = prefs.getInt('last_action_${friend.id}');

        if (lastActionTime == null) {
          // First time - check if we can do it today
          DateTime todayReminder = DateTime(now.year, now.month, now.day, hour, minute);

          if (todayReminder.isAfter(now)) {
            // Can do it today!
            nextReminder = todayReminder;
          } else {
            // Too late today, schedule for tomorrow
            nextReminder = todayReminder.add(const Duration(days: 1));
          }
        } else {
          // Has previous action - calculate from last action
          final baseTime = DateTime.fromMillisecondsSinceEpoch(lastActionTime);
          nextReminder = DateTime(
            baseTime.year,
            baseTime.month,
            baseTime.day,
            hour,
            minute,
          ).add(Duration(days: friend.reminderDays));

          // Ensure it's in the future
          while (nextReminder.isBefore(now)) {
            nextReminder = nextReminder.add(Duration(days: friend.reminderDays));
          }
        }
      }

      // Store times
      await prefs.setInt('next_reminder_${friend.id}', nextReminder.millisecondsSinceEpoch);
      await prefs.setInt('active_reminder_${friend.id}', now.millisecondsSinceEpoch);
      await prefs.setString('friend_name_${friend.id}', friend.name);
      await prefs.setInt('friend_days_${friend.id}', friend.reminderDays);

      print("📅 Scheduling reminder for ${friend.name}:");
      print("   ID: $id");
      print("   Time: $nextReminder");

      // Android notification details - USING SINGLE CHANNEL
      final androidDetails = AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Reminders to check in with friends',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Alongside Reminder',
        styleInformation: BigTextStyleInformation(
          'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since you last checked in. Send a message or give them a call! 💙',
          htmlFormatBigText: false,
          contentTitle: 'Time to check in with ${friend.name}',
          htmlFormatContentTitle: false,
        ),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'message',
            'Message',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'call',
            'Call',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert to TZDateTime
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(nextReminder, tz.local);

      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Time to check in with ${friend.name}',
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: '${friend.id};${friend.phoneNumber}',
      );

      // Verify scheduling
      final pending = await getPendingNotifications();
      final isScheduled = pending.any((n) => n.id == id);

      if (isScheduled) {
        print("✅ Reminder scheduled successfully!");

        // Also set up a backup using WorkManager
        await _scheduleBackupReminder(friend, nextReminder);

        return true;
      } else {
        print("❌ Failed to schedule - not in pending list");
        return false;
      }
    } catch (e, stackTrace) {
      print("❌ Error scheduling reminder: $e");
      print("Stack trace: $stackTrace");
      return false;
    }
  }

  // Helper method for day-based reminders (placeholder for now)
  DateTime _calculateNextDayBasedReminder(Friend friend, DateTime now, int hour, int minute) {
    // This will be implemented when we add the day selection feature
    // For now, fallback to interval-based
    DateTime nextReminder = DateTime(now.year, now.month, now.day, hour, minute);
    if (nextReminder.isBefore(now)) {
      nextReminder = nextReminder.add(const Duration(days: 1));
    }
    return nextReminder;
  }

  // Schedule backup reminder using WorkManager
  Future<void> _scheduleBackupReminder(Friend friend, DateTime scheduledTime) async {
    try {
      final delay = scheduledTime.difference(DateTime.now());
      if (delay.isNegative) return;

      await Workmanager().registerOneOffTask(
        "reminder_${friend.id}",
        "showReminder",
        initialDelay: delay,
        inputData: {
          'friendId': friend.id,
          'friendName': friend.name,
          'reminderDays': friend.reminderDays,
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
      );

      print("✅ Backup reminder scheduled via WorkManager");
    } catch (e) {
      print("⚠️ Could not schedule backup reminder: $e");
    }
  }

  // Generate stable notification ID
  int _getStableNotificationId(String friendId, {bool isPersistent = false}) {
    // Use a more stable ID generation
    int hash = 0;
    for (int i = 0; i < friendId.length; i++) {
      hash = ((hash * 31) + friendId.codeUnitAt(i)) & 0x7FFFFFFF; // Keep positive
    }

    final baseId = (hash % 900000) + 100000; // Range: 100000-999999
    return isPersistent ? baseId + _persistentOffset : baseId + _idOffset;
  }

  // Check and reschedule all reminders
  Future<void> checkAndRescheduleAllReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Get all friend IDs from stored reminders
      final keys = prefs.getKeys();
      final friendIds = <String>{};

      for (final key in keys) {
        if (key.startsWith('next_reminder_')) {
          friendIds.add(key.replaceFirst('next_reminder_', ''));
        }
      }

      print("🔍 Checking ${friendIds.length} friend reminders");

      for (final friendId in friendIds) {
        final nextReminderTime = prefs.getInt('next_reminder_$friendId');
        final friendName = prefs.getString('friend_name_$friendId');
        final reminderDays = prefs.getInt('friend_days_$friendId');

        if (nextReminderTime != null && friendName != null && reminderDays != null) {
          final nextReminder = DateTime.fromMillisecondsSinceEpoch(nextReminderTime);

          // Check if reminder time has passed
          if (now.isAfter(nextReminder)) {
            print("⚠️ Missed reminder for $friendName - showing now");

            // Show immediate notification
            await _showImmediateReminder(friendId, friendName, reminderDays);

            // Clear the scheduled reminder
            await prefs.remove('next_reminder_$friendId');
            await prefs.remove('active_reminder_$friendId');
          }
        }
      }
    } catch (e) {
      print("❌ Error checking reminders: $e");
    }
  }

  // Show immediate reminder for missed notifications
  Future<void> _showImmediateReminder(String friendId, String friendName, int days) async {
    try {
      final id = _getStableNotificationId(friendId) + 50000; // Different ID for immediate

      final androidDetails = AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Reminders to check in with friends',
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'message',
            'Message',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'call',
            'Call',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        'Check in with $friendName',
        'It\'s been $days ${days == 1 ? 'day' : 'days'} since your last check-in',
        NotificationDetails(android: androidDetails),
        payload: '$friendId;',
      );

      print("✅ Immediate reminder shown for $friendName");
    } catch (e) {
      print("❌ Error showing immediate reminder: $e");
    }
  }

  // Show persistent notification
  Future<void> showPersistentNotification(Friend friend) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return;
    }

    if (!friend.hasPersistentNotification) {
      await removePersistentNotification(friend.id);
      return;
    }

    try {
      final id = _getStableNotificationId(friend.id, isPersistent: true);

      final androidDetails = AndroidNotificationDetails(
        'alongside_persistent',
        'Quick Access',
        channelDescription: 'Persistent notifications for quick friend access',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'message',
            'Message',
            showsUserInterface: true,
            cancelNotification: false,
          ),
          const AndroidNotificationAction(
            'call',
            'Call',
            showsUserInterface: true,
            cancelNotification: false,
          ),
        ],
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        'Alongside ${friend.name}',
        'Tap to check in or reach out',
        NotificationDetails(android: androidDetails),
        payload: '${friend.id};${friend.phoneNumber}',
      );

      print("✅ Persistent notification shown for ${friend.name}");
    } catch (e) {
      print("❌ Error showing persistent notification: $e");
    }
  }

  // Cancel reminder
  Future<void> cancelReminder(String friendId) async {
    try {
      final id = _getStableNotificationId(friendId);
      await flutterLocalNotificationsPlugin.cancel(id);

      // Also cancel immediate reminder ID
      await flutterLocalNotificationsPlugin.cancel(id + 50000);

      // Cancel WorkManager backup
      await Workmanager().cancelByUniqueName("reminder_$friendId");

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('next_reminder_$friendId');
      await prefs.remove('active_reminder_$friendId');
      await prefs.remove('friend_name_$friendId');
      await prefs.remove('friend_days_$friendId');

      print("✅ Cancelled all reminders for friend: $friendId");
    } catch (e) {
      print("❌ Error cancelling reminder: $e");
    }
  }

  // Remove persistent notification
  Future<void> removePersistentNotification(String friendId) async {
    try {
      final id = _getStableNotificationId(friendId, isPersistent: true);
      await flutterLocalNotificationsPlugin.cancel(id);
      print("✅ Removed persistent notification for friend: $friendId");
    } catch (e) {
      print("❌ Error removing persistent notification: $e");
    }
  }

  // Get next reminder time
  Future<DateTime?> getNextReminderTime(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final nextTime = prefs.getInt('next_reminder_$friendId');
    return nextTime != null ? DateTime.fromMillisecondsSinceEpoch(nextTime) : null;
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print("❌ Error getting pending notifications: $e");
      return [];
    }
  }

  // Test notification
  Future<void> scheduleTestNotification() async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Test notification',
        importance: Importance.high,
        priority: Priority.high,
      );

      await flutterLocalNotificationsPlugin.show(
        999999,
        'Test Notification',
        'Notifications are working! You\'ll receive reminders on schedule 🎉',
        NotificationDetails(android: androidDetails),
      );

      print("✅ Test notification sent");
    } catch (e) {
      print("❌ Error sending test notification: $e");
    }
  }

  // Debug scheduled notifications
  Future<void> debugScheduledNotifications() async {
    try {
      final pending = await getPendingNotifications();
      final prefs = await SharedPreferences.getInstance();

      print("\n📅 ===== NOTIFICATION DEBUG =====");
      print("Pending notifications: ${pending.length}");

      for (final notification in pending) {
        print("\n📌 Notification ${notification.id}:");
        print("   Title: ${notification.title}");
        print("   Body: ${notification.body}");
        print("   Payload: ${notification.payload}");
      }

      // Also show stored reminder times
      final keys = prefs.getKeys().where((k) => k.startsWith('next_reminder_'));
      print("\n⏰ Stored reminder times:");
      for (final key in keys) {
        final time = prefs.getInt(key);
        if (time != null) {
          final friendId = key.replaceFirst('next_reminder_', '');
          final dateTime = DateTime.fromMillisecondsSinceEpoch(time);
          print("   Friend $friendId: $dateTime");
        }
      }

      print("===== END DEBUG =====\n");
    } catch (e) {
      print("❌ Error debugging notifications: $e");
    }
  }

  // Check notification setup
  Future<bool> checkNotificationSetup() async {
    try {
      bool allGood = _isInitialized;

      if (Platform.isAndroid) {
        final hasNotification = await Permission.notification.isGranted;
        final hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;

        allGood = allGood && hasNotification && hasExactAlarm;
      }

      final pending = await getPendingNotifications();

      return allGood;
    } catch (e) {
      print("❌ Error checking notification setup: $e");
      return false;
    }
  }

  // Force migrate all existing reminders to new system
  Future<void> migrateExistingReminders() async {
    try {
      print("🔄 Starting reminder migration...");

      // Cancel all existing notifications
      await flutterLocalNotificationsPlugin.cancelAll();

      // Clear all WorkManager tasks
      await Workmanager().cancelAll();

      print("✅ Migration complete - reminders will be rescheduled when friends are updated");
    } catch (e) {
      print("❌ Error during migration: $e");
    }
  }
}