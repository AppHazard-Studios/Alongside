// services/notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import '../widgets/friend_card.dart';
import 'package:url_launcher/url_launcher.dart';

// Callback type for handling notification actions
typedef NotificationActionCallback = void Function(String friendId, String action);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Map to track notification IDs for each friend
  final Map<String, int> _friendNotificationIds = {};

  // Callback for handling notification actions
  NotificationActionCallback? _actionCallback;

  // Set the callback function for notification actions
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

    await _createNotificationChannel();
  }

  // Handle notification actions from both default tap and action buttons.
  // Expected persistent payload format: "friendId;friendPhone"
  void _handleNotificationAction(NotificationResponse response) {
    // Get the action ID and payload
    final String actionId = response.actionId ?? "";
    final String payload = response.payload ?? "";

    String friendId = "";
    String friendPhone = "";

    try {
      if (payload.contains(";")) {
        final parts = payload.split(";");
        if (parts.length >= 2) {
          friendId = parts[0];
          friendPhone = parts[1];
        }
      } else {
        friendId = payload;
      }

      // Handle the action by calling the appropriate callback
      if (actionId.isEmpty) {
        // No specific action ID means it was just tapped
        _actionCallback?.call("", "home");
      } else {
        // Call the callback with the action and friend ID
        _actionCallback?.call(friendId, actionId);
      }
    } catch (e) {
      print("Error handling notification action: $e");
      // Default to home if there's an error
      _actionCallback?.call("", "home");
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannel() async {
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

    // Update persistent channel to high importance so actions are supported.
    const AndroidNotificationChannel persistentChannel = AndroidNotificationChannel(
      'alongside_persistent',
      'Quick Access Notifications',
      description: 'Persistent notifications for quick access to friends',
      importance: Importance.high,  // Changed from low to high.
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(persistentChannel);
  }

  // Show a reminder notification immediately
  Future<void> showReminderNotification(Friend friend) async {
    final int notificationId = _getNotificationId(friend.id);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alongside_reminders',
      'Friend Reminders',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
      ),
      actions: [
        const AndroidNotificationAction('message', 'Message'),
        const AndroidNotificationAction('call', 'Call'),
      ],
    );

    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    // Store the current time as the last notification time
    final prefs = await SharedPreferences.getInstance();
    final lastNotificationKey = 'last_notification_${friend.id}';
    await prefs.setInt(lastNotificationKey, DateTime.now().millisecondsSinceEpoch);

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Check in with ${friend.name}',
      'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
      notificationDetails,
      payload: '${friend.id};${friend.phoneNumber}',
    );
  }

  // Schedule reminder for friend check-in
  Future<void> scheduleReminder(Friend friend) async {
    if (friend.reminderDays <= 0) {
      await cancelReminder(friend.id);
      return;
    }

    final int notificationId = _getNotificationId(friend.id);

    // Parse the reminder time
    int hour = 9;
    int minute = 0;
    final List<String> timeParts = friend.reminderTime.split(':');
    if (timeParts.length == 2) {
      hour = int.tryParse(timeParts[0]) ?? 9;
      minute = int.tryParse(timeParts[1]) ?? 0;
    }

    // Get the last notification time or use the current time if it doesn't exist
    final prefs = await SharedPreferences.getInstance();
    final lastNotificationKey = 'last_notification_${friend.id}';
    int? lastNotificationTime = prefs.getInt(lastNotificationKey);

    DateTime baseTime;
    if (lastNotificationTime != null) {
      // Use the last notification time as the base
      baseTime = DateTime.fromMillisecondsSinceEpoch(lastNotificationTime);
    } else {
      // If no previous notification, use the current time and save it
      baseTime = DateTime.now();
      await prefs.setInt(lastNotificationKey, baseTime.millisecondsSinceEpoch);
    }

    // Calculate the next notification time
    final nextNotificationDate = DateTime(
      baseTime.year,
      baseTime.month,
      baseTime.day + friend.reminderDays,
      hour,
      minute,
    );

    // If the calculated time is in the past, adjust to the next valid time
    final now = DateTime.now();
    var scheduledDate = tz.TZDateTime.from(nextNotificationDate, tz.local);
    if (scheduledDate.isBefore(now)) {
      // Calculate how many reminder intervals have passed
      final daysBetween = now.difference(baseTime).inDays;
      final reminderCycles = (daysBetween / friend.reminderDays).ceil();

      // Set the next reminder date based on the original date plus the required cycles
      scheduledDate = tz.TZDateTime(
        tz.local,
        baseTime.year,
        baseTime.month,
        baseTime.day + (reminderCycles * friend.reminderDays),
        hour,
        minute,
      );

      // Ensure it's in the future
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(Duration(days: friend.reminderDays));
      }
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
        const AndroidNotificationAction('message', 'Message'),
        const AndroidNotificationAction('call', 'Call'),
      ],
    );

    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Check in with ${friend.name}',
      'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Removed uiLocalNotificationDateInterpretation
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '${friend.id};${friend.phoneNumber}',
    );

    _friendNotificationIds[friend.id] = notificationId;

    // Update the next notification time text in the database
    final nextNotificationString = '${scheduledDate.month}/${scheduledDate.day}/${scheduledDate.year} at ${_formatTimeOfDay(TimeOfDay(hour: scheduledDate.hour, minute: scheduledDate.minute))}';
    await prefs.setString('next_notification_${friend.id}', nextNotificationString);
  }

  // Helper method to format time in 12-hour format
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    return '$hour:$minute $period';
  }

  // Show persistent notification with actions.
  Future<void> showPersistentNotification(Friend friend) async {
    if (!friend.hasPersistentNotification) {
      await removePersistentNotification(friend.id);
      return;
    }

    final int notificationId = _getNotificationId(friend.id, isPersistent: true);

    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction('message', 'Message'),
      const AndroidNotificationAction('call', 'Call'),
    ];

    final BigTextStyleInformation styleInformation = BigTextStyleInformation(
      'Check in with them, or reach out for support.',
      contentTitle: 'You\'re Alongside, ${friend.name}.',
      summaryText: friend.name,
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alongside_persistent',
      'Quick Access Notifications',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      styleInformation: styleInformation,
      actions: actions,
    );

    final NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    // Set payload to include both friend ID and phone number separated by a semicolon.
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Alongside',
      'Check in with, ${friend.name}, or reach out for support.',
      notificationDetails,
      payload: '${friend.id};${friend.phoneNumber}',
    );
  }

  // Remove persistent notification
  Future<void> removePersistentNotification(String friendId) async {
    final int notificationId = _getNotificationId(friendId, isPersistent: true);
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  // Cancel a scheduled reminder
  Future<void> cancelReminder(String friendId) async {
    final int notificationId = _getNotificationId(friendId);
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    _friendNotificationIds.remove(friendId);

    // Clear the last notification time and next notification text
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notification_$friendId');
    await prefs.remove('next_notification_$friendId');
  }

  // Generate a unique notification ID based on the friend's ID.
  int _getNotificationId(String friendId, {bool isPersistent = false}) {
    if (isPersistent) {
      return (friendId.hashCode.abs() % 100000) + 200000;
    } else if (_friendNotificationIds.containsKey(friendId)) {
      return _friendNotificationIds[friendId]!;
    } else {
      return friendId.hashCode.abs() % 100000;
    }
  }

  // Cancel all notifications (useful for testing or reset)
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    _friendNotificationIds.clear();
  }

  // Schedule a test notification (fires in 10 seconds)
  Future<void> scheduleTestNotification() async {
    final tz.TZDateTime now =
    tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

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
      now,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'test',
    );
  }

  // For the message action, we now simply trigger the callback so that the main app
  // can navigate to the home screen and simulate clicking the message button.
  // (No helper method is called here.)

  // Helper method to launch the phone app for calling.
  Future<void> _callFriend(String phoneNumber) async {
    final String sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final Uri telUri = Uri.parse('tel:$sanitizedPhone');
      await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching phone app: $e');
    }
  }
}