// lib/services/notification_service.dart - Compatible with flutter_local_notifications ^19.1.0
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NotificationActionCallback = void Function(
    String friendId, String action);

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

  // Initialize notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data FIRST
      tz_data.initializeTimeZones();

      // Set local location to a default timezone
      try {
        tz.setLocalLocation(tz.getLocation('America/New_York'));
      } catch (e) {
        print("Timezone error: $e");
      }

      // Android initialization settings with icon
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      final initialized = await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationAction,
      );

      if (initialized == true) {
        print("✅ Notifications initialized successfully");

        // Create notification channels AFTER initialization
        await _createNotificationChannels();

        // Request permissions
        await _requestNotificationPermission();

        _isInitialized = true;
      } else {
        print("❌ Failed to initialize notifications");
      }
    } catch (e) {
      print("❌ Error initializing notifications: $e");
    }
  }

  // Create notification channels
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
      // Reminder channel - HIGH importance for better delivery
      const reminderChannel = AndroidNotificationChannel(
        'alongside_reminders',
        'Friend Reminders',
        description: 'Notifications for friend check-in reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      await androidPlugin.createNotificationChannel(reminderChannel);

      // Persistent channel - LOW importance
      const persistentChannel = AndroidNotificationChannel(
        'alongside_persistent',
        'Quick Access Notifications',
        description: 'Persistent notifications for quick access to friends',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );
      await androidPlugin.createNotificationChannel(persistentChannel);

      print("✅ Notification channels created successfully");
    } catch (e) {
      print("❌ Error creating notification channels: $e");
    }
  }

  // Request notification permission for Android 13+
  Future<bool> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    // Check Android version first
    final sdkInt = await _getAndroidSdkVersion();
    if (sdkInt < 33) return true; // Android 13 is API level 33

    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      print(
          "Notification permission: ${result.isGranted ? 'Granted' : 'Denied'}");
      return result.isGranted;
    }
    return status.isGranted;
  }

  // Get Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    // For simplicity, assume Android 12+ (API 31+) for schedule exact alarm
    return 31; // You might want to use device_info_plus package for accurate version
  }

  // Handle notification actions
  void _handleNotificationAction(NotificationResponse response) {
    try {
      final String? actionId = response.actionId;
      final String? payload = response.payload;

      if (payload == null || payload.isEmpty) return;

      String friendId = "";
      if (payload.contains(";")) {
        final parts = payload.split(";");
        if (parts.isNotEmpty) friendId = parts[0];
      } else {
        friendId = payload;
      }

      if (friendId.isNotEmpty) {
        // Cancel the notification
        final notificationId = _getNotificationId(friendId);
        flutterLocalNotificationsPlugin.cancel(notificationId);

        // Update last action time
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(
              'last_action_$friendId', DateTime.now().millisecondsSinceEpoch);
        });
      }

      // Trigger callback
      if (actionId != null && actionId.isNotEmpty) {
        _actionCallback?.call(friendId, actionId);
      } else {
        _actionCallback?.call(friendId, "tap");
      }
    } catch (e) {
      print("Error handling notification action: $e");
    }
  }

  // Show persistent notification
  Future<void> showPersistentNotification(Friend friend) async {
    if (!_isInitialized) {
      print("❌ Notifications not initialized");
      return;
    }

    if (!friend.hasPersistentNotification) {
      await removePersistentNotification(friend.id);
      return;
    }

    try {
      final int id = _getNotificationId(friend.id, isPersistent: true);

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alongside_persistent',
        'Quick Access Notifications',
        channelDescription:
            'Persistent notifications for quick access to friends',
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
        'Check in with them, or reach out for support.',
        NotificationDetails(android: androidDetails),
        payload: '${friend.id};${friend.phoneNumber}',
      );

      print("✅ Showed persistent notification for ${friend.name}");
    } catch (e) {
      print("❌ Error showing persistent notification: $e");
    }
  }

  // Remove persistent notification
  Future<void> removePersistentNotification(String friendId) async {
    try {
      await flutterLocalNotificationsPlugin
          .cancel(_getNotificationId(friendId, isPersistent: true));
      print("✅ Removed persistent notification for friend: $friendId");
    } catch (e) {
      print("❌ Error removing persistent notification: $e");
    }
  }

  // Schedule reminder - Fixed without UILocalNotificationDateInterpretation
  Future<void> scheduleReminder(Friend friend) async {
    if (!_isInitialized) {
      print("❌ Notifications not initialized");
      return;
    }

    if (friend.reminderDays <= 0) {
      await cancelReminder(friend.id);
      return;
    }

    try {
      final int id = _getNotificationId(friend.id);
      final prefs = await SharedPreferences.getInstance();

      // Cancel any existing reminder
      await cancelReminder(friend.id);

      // Get last action time or use now
      final lastActionKey = 'last_action_${friend.id}';
      final lastActionTime = prefs.getInt(lastActionKey);
      final DateTime baseTime = lastActionTime != null
          ? DateTime.fromMillisecondsSinceEpoch(lastActionTime)
          : DateTime.now();

      // Parse reminder time
      final parts = friend.reminderTime.split(':');
      final int hour = int.tryParse(parts[0]) ?? 9;
      final int minute = int.tryParse(parts[1]) ?? 0;

      // Calculate next reminder - add days first
      DateTime nextReminder = baseTime.add(Duration(days: friend.reminderDays));

      // Then set the specific time
      nextReminder = DateTime(
        nextReminder.year,
        nextReminder.month,
        nextReminder.day,
        hour,
        minute,
      );

      // Make sure it's in the future
      final now = DateTime.now();
      while (nextReminder.isBefore(now)) {
        nextReminder = nextReminder.add(Duration(days: friend.reminderDays));
      }

      // Store the scheduled time
      await prefs.setInt(
          'next_reminder_${friend.id}', nextReminder.millisecondsSinceEpoch);
      await prefs.setInt(
          'active_reminder_${friend.id}', nextReminder.millisecondsSinceEpoch);

      // Create notification details
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Notifications for friend check-in reminders',
        importance: Importance.high,
        priority: Priority.high,
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

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Convert to TZDateTime
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.from(nextReminder, tz.local);

      // Schedule the notification (without uiLocalNotificationDateInterpretation)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Check in with ${friend.name}',
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
        scheduledDate,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: null,
        payload: '${friend.id};${friend.phoneNumber}',
      );

      print("✅ Scheduled reminder for ${friend.name} at $nextReminder");
    } catch (e) {
      print("❌ Error scheduling reminder: $e");
    }
  }

  // Cancel reminder
  Future<void> cancelReminder(String friendId) async {
    try {
      final int id = _getNotificationId(friendId);
      await flutterLocalNotificationsPlugin.cancel(id);

      // Clean up stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('next_reminder_$friendId');
      await prefs.remove('active_reminder_$friendId');

      print("✅ Cancelled reminder for friend: $friendId");
    } catch (e) {
      print("❌ Error cancelling reminder: $e");
    }
  }

  // Generate unique notification IDs
  int _getNotificationId(String friendId, {bool isPersistent = false}) {
    final baseId = friendId.hashCode.abs() % 100000;
    return isPersistent ? baseId + 200000 : baseId;
  }

  // Test notification - Show immediately
  Future<void> scheduleTestNotification() async {
    if (!_isInitialized) {
      print("❌ Notifications not initialized");
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Test notification',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Show notification immediately for testing
      await flutterLocalNotificationsPlugin.show(
        999999,
        'Test Notification',
        'This is a test notification from Alongside',
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: 'test',
      );

      print("✅ Test notification sent immediately");
    } catch (e) {
      print("❌ Error sending test notification: $e");
    }
  }

  // Get next reminder time for a friend
  Future<DateTime?> getNextReminderTime(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final nextTime = prefs.getInt('next_reminder_$friendId');
    return nextTime != null
        ? DateTime.fromMillisecondsSinceEpoch(nextTime)
        : null;
  }

  // Check if notifications are properly set up
  Future<bool> checkNotificationSetup() async {
    if (!_isInitialized) return false;

    // Check notification permission
    final hasPermission = await Permission.notification.isGranted;
    if (!hasPermission) {
      print("❌ No notification permission");
      return false;
    }

    return true;
  }
}
