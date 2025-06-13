// services/notification_service.dart - Complete rewrite with better scheduling
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/storage_service.dart';

// Callback type for handling notification actions
typedef NotificationActionCallback = void Function(String friendId, String action);

class NotificationService {
  DateTime? _lastMessageActionTime;
  DateTime? get lastMessageActionTime => _lastMessageActionTime;
  DateTime? _lastPersistentCancelTime;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Track notification IDs per friend
  final Map<String, int> _friendNotificationIds = {};

  // Track last shown times to prevent flooding
  final Map<String, DateTime> _lastNotificationTimes = {};
  static const Duration _notificationCooldown = Duration(minutes: 30);

  // App callback when an action fires
  NotificationActionCallback? _actionCallback;
  void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  // Initialize notifications
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationAction,
    );

    // Request notification permission for Android 13+
    await _requestNotificationPermission();

    await _createNotificationChannel();
  }

  // Request notification permission for Android 13+
  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
  }

  // Handle notification actions
  void _handleNotificationAction(NotificationResponse response) {
    final String actionId = response.actionId ?? "";
    final String payload = response.payload ?? "";

    String friendId = "";
    if (payload.contains(";")) {
      final parts = payload.split(";");
      if (parts.length >= 2) friendId = parts[0];
    } else {
      friendId = payload;
    }

    // Cancel the notification to avoid repeated triggers
    if (friendId.isNotEmpty) {
      _lastPersistentCancelTime = DateTime.now();
      flutterLocalNotificationsPlugin.cancel(_getNotificationId(friendId));

      // Update last action time in preferences
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('last_action_$friendId', DateTime.now().millisecondsSinceEpoch);
      });
    }

    if (actionId.isEmpty) {
      _actionCallback?.call("", "home");
    } else {
      if (actionId == 'message') {
        _lastMessageActionTime = DateTime.now();
      }
      _actionCallback?.call(friendId, actionId);
    }
  }

  // Create Android notification channels with HIGH importance
  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        'alongside_reminders',
        'Friend Reminders',
        description: 'Notifications for friend check-in reminders',
        importance: Importance.high, // HIGH importance for better delivery
        playSound: true,
        enableVibration: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(reminderChannel);

      const AndroidNotificationChannel persistentChannel = AndroidNotificationChannel(
        'alongside_persistent',
        'Quick Access Notifications',
        description: 'Persistent notifications for quick access to friends',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(persistentChannel);

      print("Notification channels created successfully");
    } catch (e) {
      print("Error creating notification channels: $e");
    }
  }

  // Show a persistent notification
  Future<void> showPersistentNotification(Friend friend) async {
    try {
      if (_lastPersistentCancelTime != null &&
          DateTime.now().difference(_lastPersistentCancelTime!).inSeconds < 30) {
        print("⏱  Skipping persistent notification (cooldown)");
        return;
      }

      if (!friend.hasPersistentNotification) {
        await removePersistentNotification(friend.id);
        return;
      }

      final int id = _getNotificationId(friend.id, isPersistent: true);

      // Check if the notification already exists
      final List<ActiveNotification>? activeNotifications =
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();

      if (activeNotifications != null) {
        for (var notification in activeNotifications) {
          if (notification.id == id) {
            print("Persistent notification already exists for ${friend.name}, skipping");
            return;
          }
        }
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alongside_persistent',
        'Quick Access Notifications',
        channelDescription: 'Persistent notifications for quick access to friends',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        category: AndroidNotificationCategory.service,
        playSound: false,
        enableVibration: false,
        enableLights: false,
        styleInformation: BigTextStyleInformation(
          'Check in with them, or reach out for support.',
          contentTitle: 'You\'re Alongside ${friend.name}.',
          summaryText: friend.name,
        ),
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
        'Alongside',
        'Check in with ${friend.name}, or reach out for support.',
        NotificationDetails(android: androidDetails),
        payload: '${friend.id};${friend.phoneNumber}',
      );

      print("Persistent notification shown for ${friend.name}");
    } catch (e) {
      print("Error showing persistent notification: $e");
    }
  }

  // Remove a persistent notification
  Future<void> removePersistentNotification(String friendId) async {
    try {
      await flutterLocalNotificationsPlugin
          .cancel(_getNotificationId(friendId, isPersistent: true));
      print("Persistent notification removed for friend ID: $friendId");
    } catch (e) {
      print("Error removing persistent notification: $e");
    }
  }

  // Schedule a reminder with improved logic
  Future<void> scheduleReminder(Friend friend) async {
    if (friend.reminderDays <= 0) {
      await cancelReminder(friend.id);
      return;
    }

    final int id = _getNotificationId(friend.id);
    final prefs = await SharedPreferences.getInstance();

    // Always cancel any existing reminder first
    await cancelReminder(friend.id);

    // Keys for tracking
    final String lastActionKey = 'last_action_${friend.id}';
    final String nextReminderKey = 'next_reminder_${friend.id}';

    // Get last action time or use current time
    final lastActionTime = prefs.getInt(lastActionKey);
    final DateTime baseTime = lastActionTime != null
        ? DateTime.fromMillisecondsSinceEpoch(lastActionTime)
        : DateTime.now();

    // Parse reminder time
    final parts = friend.reminderTime.split(':');
    final int hour = int.tryParse(parts[0]) ?? 9;
    final int minute = int.tryParse(parts[1]) ?? 0;

    // Calculate next reminder time
    DateTime nextReminder = DateTime(
      baseTime.year,
      baseTime.month,
      baseTime.day,
      hour,
      minute,
    );

    // Add the reminder interval
    nextReminder = nextReminder.add(Duration(days: friend.reminderDays));

    // Ensure it's in the future
    final DateTime now = DateTime.now();
    while (nextReminder.isBefore(now)) {
      nextReminder = nextReminder.add(Duration(days: friend.reminderDays));
    }

    // Create notification details with HIGH priority
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alongside_reminders',
      'Friend Reminders',
      channelDescription: 'Notifications for friend check-in reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
        contentTitle: 'Check in with ${friend.name}',
      ),
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

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Check in with ${friend.name}',
      'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
      tz.TZDateTime.from(nextReminder, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Removed uiLocalNotificationDateInterpretation as per instructions
      payload: '${friend.id};${friend.phoneNumber}',
    );

    _friendNotificationIds[friend.id] = id;

    // Store the next reminder time
    await prefs.setInt(nextReminderKey, nextReminder.millisecondsSinceEpoch);

    print("Scheduled reminder for ${friend.name} at $nextReminder");
  }

  // Cancel a scheduled reminder - Enhanced cleanup
  Future<void> cancelReminder(String friendId) async {
    final int id = _getNotificationId(friendId);
    await flutterLocalNotificationsPlugin.cancel(id);

    final prefs = await SharedPreferences.getInstance();
    // Clean up all related keys
    await prefs.remove('last_notification_$friendId');
    await prefs.remove('next_notification_$friendId');
    await prefs.remove('scheduled_$friendId');
    await prefs.remove('active_reminder_$friendId');
    await prefs.remove('next_reminder_$friendId');

    _friendNotificationIds.remove(friendId);
    _lastNotificationTimes.remove('reminder_$friendId');

    print("Cancelled reminder and cleaned up for friend ID: $friendId");
  }

  // Generate unique IDs
  int _getNotificationId(String friendId, {bool isPersistent = false}) {
    if (isPersistent) return (friendId.hashCode.abs() % 100000) + 200000;
    return _friendNotificationIds[friendId] ?? (friendId.hashCode.abs() % 100000);
  }

  // Format a TimeOfDay into 12h
  String _formatTimeOfDay(TimeOfDay time) {
    final int hour =
    time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final String minuteStr = time.minute.toString().padLeft(2, '0');
    final String period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minuteStr $period';
  }

  // Cancel all notifications (for testing)
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    _friendNotificationIds.clear();
  }

  // Schedule a quick test notification in 10s
  Future<void> scheduleTestNotification() async {
    final tz.TZDateTime when = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alongside_reminders',
      'Friend Reminders',
      channelDescription: 'Notifications for friend check-in reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999999,
      'Test Notification',
      'This is a test notification from Alongside',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Removed uiLocalNotificationDateInterpretation as per instructions
      payload: 'test',
    );

    print("Test notification scheduled for ${when.toLocal()}");
  }
}