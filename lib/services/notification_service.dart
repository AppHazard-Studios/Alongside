// services/notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'package:url_launcher/url_launcher.dart';

// Add these imports for notification permission
import 'package:permission_handler/permission_handler.dart';

// Callback type for handling notification actions
typedef NotificationActionCallback = void Function(String friendId, String action);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Track notification IDs per friend
  final Map<String, int> _friendNotificationIds = {};

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
    // For Android 13+ (API level 33+), request POST_NOTIFICATIONS permission
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

    if (actionId.isEmpty) {
      _actionCallback?.call("", "home");
    } else {
      _actionCallback?.call(friendId, actionId);
    }
  }

  // Create Android notification channels
  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        'alongside_reminders',
        'Friend Reminders',
        description: 'Notifications for friend check-in reminders',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(reminderChannel);

      const AndroidNotificationChannel persistentChannel = AndroidNotificationChannel(
        'alongside_persistent',
        'Quick Access Notifications',
        description: 'Persistent notifications for quick access to friends',
        importance: Importance.high,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(persistentChannel);

      print("Notification channels created successfully");
    } catch (e) {
      print("Error creating notification channels: $e");
    }
  }

  // Show an immediate reminder notification
  Future<void> showReminderNotification(Friend friend) async {
    try {
      final int id = _getNotificationId(friend.id);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alongside_reminders',
        'Friend Reminders',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
        ),
        actions: [
          const AndroidNotificationAction(
            'message',
            'Message',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'call',
            'Call',
            showsUserInterface: true,
          ),
        ],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_notification_${friend.id}',
        DateTime.now().millisecondsSinceEpoch,
      );

      await flutterLocalNotificationsPlugin.show(
        id,
        'Check in with ${friend.name}',
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
        NotificationDetails(android: androidDetails),
        payload: '${friend.id};${friend.phoneNumber}',
      );

      print("Reminder notification shown for ${friend.name}");
    } catch (e) {
      print("Error showing reminder notification: $e");
    }
  }

  // Show a persistent notification - Fixed implementation
  Future<void> showPersistentNotification(Friend friend) async {
    try {
      if (!friend.hasPersistentNotification) {
        await removePersistentNotification(friend.id);
        return;
      }

      final int id = _getNotificationId(friend.id, isPersistent: true);

      // Make sure our notification flags are set properly
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'alongside_persistent',
        'Quick Access Notifications',
        channelDescription: 'Persistent notifications for quick access to friends',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,  // This is crucial for persistent notifications
        autoCancel: false,
        category: AndroidNotificationCategory.service, // Improves persistence
        styleInformation: BigTextStyleInformation(
          'Check in with them, or reach out for support.',
          contentTitle: 'You\'re Alongside, ${friend.name}.',
          summaryText: friend.name,
        ),
        actions: [
          const AndroidNotificationAction(
            'message',
            'Message',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'call',
            'Call',
            showsUserInterface: true,
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

  // The rest of your NotificationService methods remain unchanged...
  // ... (Schedule reminders, remove notifications, etc.)

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

  // Cancel a scheduled reminder
  Future<void> cancelReminder(String friendId) async {
    final int id = _getNotificationId(friendId);
    await flutterLocalNotificationsPlugin.cancel(id);
    _friendNotificationIds.remove(friendId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notification_$friendId');
    await prefs.remove('next_notification_$friendId');
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

  // Schedule a future reminder
  Future<void> scheduleReminder(Friend friend) async {
    if (friend.reminderDays <= 0) {
      await cancelReminder(friend.id);
      return;
    }

    final int id = _getNotificationId(friend.id);
    final prefs = await SharedPreferences.getInstance();
    final String lastKey = 'last_notification_${friend.id}';
    int? lastTime = prefs.getInt(lastKey);

    DateTime baseTime;
    if (lastTime != null) {
      baseTime = DateTime.fromMillisecondsSinceEpoch(lastTime);
    } else {
      baseTime = DateTime.now();
      await prefs.setInt(lastKey, baseTime.millisecondsSinceEpoch);
    }

    final parts = friend.reminderTime.split(':');
    final int hour = int.tryParse(parts[0]) ?? 9;
    final int minute = int.tryParse(parts[1]) ?? 0;

    DateTime next = DateTime(
      baseTime.year,
      baseTime.month,
      baseTime.day + friend.reminderDays,
      hour,
      minute,
    );
    final DateTime now = DateTime.now();
    if (next.isBefore(now)) {
      final int daysPassed = now.difference(baseTime).inDays;
      final int cycles = (daysPassed / friend.reminderDays).ceil();
      next = DateTime(
        baseTime.year,
        baseTime.month,
        baseTime.day + cycles * friend.reminderDays,
        hour,
        minute,
      );
      if (next.isBefore(now)) next = next.add(Duration(days: friend.reminderDays));
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alongside_reminders',
      'Friend Reminders',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
      ),
      actions: [
        const AndroidNotificationAction(
          'message',
          'Message',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'call',
          'Call',
          showsUserInterface: true,
        ),
      ],
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Check in with ${friend.name}',
      'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
      tz.TZDateTime.from(next, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '${friend.id};${friend.phoneNumber}',
    );

    _friendNotificationIds[friend.id] = id;
    final String nextString =
        '${next.month}/${next.day}/${next.year} at ${_formatTimeOfDay(
      TimeOfDay(hour: next.hour, minute: next.minute),
    )}';
    await prefs.setString('next_notification_${friend.id}', nextString);
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
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999999,
      'Test Notification',
      'This is a test notification from Alongside',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'test',
    );
  }
}