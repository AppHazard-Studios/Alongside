// lib/services/notification_service.dart - Fixed without deprecated parameters
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

  void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  // Initialize notifications
  Future<void> initialize() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationAction,
    );

    // Create channels AFTER initialization
    await _createNotificationChannels();

    // Request permissions
    await _requestNotificationPermission();
  }

  // Create notification channels before anything else
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

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

    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
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
          prefs.setInt('last_action_$friendId', DateTime.now().millisecondsSinceEpoch);
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
    if (!friend.hasPersistentNotification) {
      await removePersistentNotification(friend.id);
      return;
    }

    try {
      final int id = _getNotificationId(friend.id, isPersistent: true);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alongside_persistent',
        'Quick Access Notifications',
        channelDescription: 'Persistent notifications for quick access to friends',
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
    } catch (e) {
      print("Error showing persistent notification: $e");
    }
  }

  // Remove persistent notification
  Future<void> removePersistentNotification(String friendId) async {
    try {
      await flutterLocalNotificationsPlugin
          .cancel(_getNotificationId(friendId, isPersistent: true));
    } catch (e) {
      print("Error removing persistent notification: $e");
    }
  }

  // Schedule reminder - Using timezone properly but with local time
  Future<void> scheduleReminder(Friend friend) async {
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
      await prefs.setInt('next_reminder_${friend.id}', nextReminder.millisecondsSinceEpoch);

      // Create notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

      // Convert to TZDateTime using local timezone
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(nextReminder, tz.local);

      // Schedule using zonedSchedule (without deprecated parameter)
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Check in with ${friend.name}',
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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

      print("✅ Cancelled reminder for friend: $friendId");
    } catch (e) {
      print("Error cancelling reminder: $e");
    }
  }

  // Generate unique notification IDs
  int _getNotificationId(String friendId, {bool isPersistent = false}) {
    final baseId = friendId.hashCode.abs() % 100000;
    return isPersistent ? baseId + 200000 : baseId;
  }

  // Test notification - simplified
  Future<void> scheduleTestNotification() async {
    try {
      final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        channelDescription: 'Test notification',
        importance: Importance.high,
        priority: Priority.high,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        999999,
        'Test Notification',
        'This is a test notification from Alongside',
        testTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'test',
      );

      print("✅ Test notification scheduled for 10 seconds from now");
    } catch (e) {
      print("❌ Error scheduling test notification: $e");
    }
  }

  // Get next reminder time for a friend
  Future<DateTime?> getNextReminderTime(String friendId) async {
    final prefs = await SharedPreferences.getInstance();
    final nextTime = prefs.getInt('next_reminder_$friendId');
    return nextTime != null ? DateTime.fromMillisecondsSinceEpoch(nextTime) : null;
  }
}