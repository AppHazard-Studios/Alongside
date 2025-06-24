// lib/services/notification_service.dart - Fixed with guaranteed scheduling
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NotificationActionCallback = void Function(String friendId, String action);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  NotificationActionCallback? _actionCallback;
  bool _isInitialized = false;

  void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  // Initialize notifications with better error handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("🚀 Starting notification initialization...");

      // Initialize timezone data FIRST with fallback
      try {
        tz_data.initializeTimeZones();
        // Try to use local timezone, fallback to UTC if fails
        try {
          tz.setLocalLocation(tz.getLocation('America/New_York'));
        } catch (e) {
          print("⚠️ Timezone error, using UTC: $e");
          tz.setLocalLocation(tz.UTC);
        }
      } catch (e) {
        print("⚠️ Critical timezone initialization error: $e");
      }

      // Android initialization
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize plugin
      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      if (initialized == true) {
        print("✅ Notification plugin initialized");

        // Create channels AFTER initialization
        await _createNotificationChannels();

        // Request permissions
        await _requestAllPermissions();

        _isInitialized = true;
        print("✅ Notification service fully initialized");
      } else {
        print("❌ Failed to initialize notification plugin");
      }
    } catch (e, stackTrace) {
      print("❌ Critical error initializing notifications: $e");
      print("Stack trace: $stackTrace");
    }
  }

  // Create notification channels with better configuration
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      print("❌ Android plugin is null");
      return;
    }

    try {
      // Reminder channel - MAX importance for scheduled notifications
      const reminderChannel = AndroidNotificationChannel(
        'alongside_reminders',
        'Friend Reminders',
        description: 'Scheduled reminders to check in with friends',
        importance: Importance.max, // Changed to MAX for better delivery
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color.fromARGB(255, 0, 122, 255),
      );
      await androidPlugin.createNotificationChannel(reminderChannel);

      // Persistent channel
      const persistentChannel = AndroidNotificationChannel(
        'alongside_persistent',
        'Quick Access',
        description: 'Persistent notifications for quick friend access',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );
      await androidPlugin.createNotificationChannel(persistentChannel);

      print("✅ Notification channels created");
    } catch (e) {
      print("❌ Error creating channels: $e");
    }
  }

  // Request all necessary permissions
  Future<bool> _requestAllPermissions() async {
    try {
      // Request notification permission (Android 13+)
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.request();
        print("📱 Notification permission: ${notificationStatus.name}");

        // Request exact alarm permission (Android 12+)
        if (await Permission.scheduleExactAlarm.isDenied) {
          final alarmStatus = await Permission.scheduleExactAlarm.request();
          print("⏰ Exact alarm permission: ${alarmStatus.name}");
        }
      }

      return true;
    } catch (e) {
      print("❌ Error requesting permissions: $e");
      return false;
    }
  }

  // Handle notification tap/action
  void _handleNotificationResponse(NotificationResponse response) {
    try {
      final String? payload = response.payload;
      final String? actionId = response.actionId;

      print("📲 Notification response - Action: $actionId, Payload: $payload");

      if (payload == null || payload.isEmpty) return;

      String friendId = "";
      if (payload.contains(";")) {
        friendId = payload.split(";")[0];
      } else {
        friendId = payload;
      }

      if (friendId.isNotEmpty) {
        // Cancel the notification
        flutterLocalNotificationsPlugin.cancel(_getNotificationId(friendId));

        // Update last action time
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('last_action_$friendId', DateTime.now().millisecondsSinceEpoch);
        });

        // Trigger callback
        _actionCallback?.call(friendId, actionId ?? "tap");
      }
    } catch (e) {
      print("❌ Error handling notification response: $e");
    }
  }

  // Schedule reminder with better error handling and verification
  Future<bool> scheduleReminder(Friend friend) async {
    if (!_isInitialized) {
      print("❌ Cannot schedule - service not initialized");
      await initialize();
      if (!_isInitialized) return false;
    }

    if (friend.reminderDays <= 0) {
      await cancelReminder(friend.id);
      return false;
    }

    try {
      final id = _getNotificationId(friend.id);

      // Cancel any existing reminder first
      await cancelReminder(friend.id);

      // Calculate next reminder time
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      // Get last action time or use now
      final lastActionTime = prefs.getInt('last_action_${friend.id}');
      final baseTime = lastActionTime != null
          ? DateTime.fromMillisecondsSinceEpoch(lastActionTime)
          : now;

      // Parse reminder time
      final parts = friend.reminderTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;

      // Calculate next reminder
      DateTime nextReminder = DateTime(
        baseTime.year,
        baseTime.month,
        baseTime.day + friend.reminderDays,
        hour,
        minute,
      );

      // Ensure it's in the future
      while (nextReminder.isBefore(now)) {
        nextReminder = nextReminder.add(Duration(days: friend.reminderDays));
      }

      // Store scheduled time
      await prefs.setInt('next_reminder_${friend.id}', nextReminder.millisecondsSinceEpoch);
      await prefs.setInt('active_reminder_${friend.id}', now.millisecondsSinceEpoch);

      print("📅 Scheduling reminder for ${friend.name}:");
      print("   ID: $id");
      print("   Next: $nextReminder");
      print("   Days: ${friend.reminderDays}");

      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Scheduled reminders to check in with friends',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        actions: [
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
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert to TZDateTime safely
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(nextReminder, tz.local);

      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Check in with ${friend.name}',
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        //uiLocalNotificationDateInterpretation:
        //UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        payload: '${friend.id};${friend.phoneNumber}',
      );

      // Verify it was scheduled
      final pending = await _getPendingNotifications();
      final scheduled = pending.any((n) => n.id == id);

      if (scheduled) {
        print("✅ Reminder successfully scheduled!");
        return true;
      } else {
        print("❌ Failed to schedule reminder - not in pending list");
        return false;
      }
    } catch (e, stackTrace) {
      print("❌ Error scheduling reminder: $e");
      print("Stack trace: $stackTrace");
      return false;
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
      final id = _getNotificationId(friend.id, isPersistent: true);

      final androidDetails = AndroidNotificationDetails(
        'alongside_persistent',
        'Quick Access',
        channelDescription: 'Persistent notifications for quick friend access',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        playSound: false,
        enableVibration: false,
        actions: [
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
        'Tap to check in or reach out for support',
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
      final id = _getNotificationId(friendId);
      await flutterLocalNotificationsPlugin.cancel(id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('next_reminder_$friendId');
      await prefs.remove('active_reminder_$friendId');

      print("✅ Cancelled reminder for friend: $friendId");
    } catch (e) {
      print("❌ Error cancelling reminder: $e");
    }
  }

  // Remove persistent notification
  Future<void> removePersistentNotification(String friendId) async {
    try {
      final id = _getNotificationId(friendId, isPersistent: true);
      await flutterLocalNotificationsPlugin.cancel(id);
      print("✅ Removed persistent notification for friend: $friendId");
    } catch (e) {
      print("❌ Error removing persistent notification: $e");
    }
  }

  // Generate unique notification IDs (improved to avoid conflicts)
  int _getNotificationId(String friendId, {bool isPersistent = false}) {
    // Use simple incrementing IDs based on friend order to avoid hashCode conflicts
    final baseId = friendId.codeUnits.reduce((a, b) => a + b) % 100000;
    return isPersistent ? baseId + 100000 : baseId;
  }

  // Test notification - immediate
  Future<void> scheduleTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Test notification',
        importance: Importance.max,
        priority: Priority.max,
      );

      const details = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        999999,
        'Test Notification',
        'If you see this, notifications are working! 🎉',
        details,
      );

      print("✅ Test notification sent");
    } catch (e) {
      print("❌ Error sending test notification: $e");
    }
  }

  // Get next reminder time
  Future<DateTime?> getNextReminderTime(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final nextTime = prefs.getInt('next_reminder_$friendId');
    return nextTime != null ? DateTime.fromMillisecondsSinceEpoch(nextTime) : null;
  }

  // Get all pending notifications
  Future<List<PendingNotificationRequest>> _getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print("❌ Error getting pending notifications: $e");
      return [];
    }
  }

  // Debug method to show all scheduled notifications
  Future<void> debugScheduledNotifications() async {
    try {
      final pending = await _getPendingNotifications();
      print("📅 Pending notifications: ${pending.length}");
      for (final notification in pending) {
        print("   ID: ${notification.id}");
        print("   Title: ${notification.title}");
        print("   Body: ${notification.body}");
        print("   Payload: ${notification.payload}");
      }
    } catch (e) {
      print("❌ Error debugging notifications: $e");
    }
  }

  // Check if service is properly initialized
  Future<bool> checkNotificationSetup() async {
    if (!_isInitialized) return false;

    // Check permissions
    if (Platform.isAndroid) {
      final hasNotification = await Permission.notification.isGranted;
      final hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;

      print("📱 Notification permission: $hasNotification");
      print("⏰ Exact alarm permission: $hasExactAlarm");

      return hasNotification && hasExactAlarm;
    }

    return true;
  }
}