// lib/services/notification_service.dart - SIMPLIFIED VERSION
import 'dart:io';
import 'package:flutter/material.dart';
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

// WorkManager callback - MUST be top-level
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "rescheduleNotification") {
      final friendId = inputData?['friendId'] as String?;
      if (friendId != null) {
        final service = NotificationService();
        await service.initialize();

        // Get friend data and reschedule
        final storageService = StorageService();
        final friends = await storageService.getFriends();
        final friend = friends.firstWhere(
              (f) => f.id == friendId,
          orElse: () => throw Exception('Friend not found'),
        );

        if (friend.reminderDays > 0) {
          await service._scheduleNotificationsForFriend(friend);
        }
      }
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

  // Constants
  static const int _persistentOffset = 2000000;
  static const int _notificationsToSchedule = 3; // Schedule 3 in advance

  void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      String timeZoneName;
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        timeZoneName = 'America/New_York';
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Android settings
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

      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationResponse,
      );

      // Create notification channels
      await _createNotificationChannels();

      // Request permissions
      await _requestPermissions();

      // Initialize WorkManager for Android only
      if (Platform.isAndroid) {
        await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      }

      _isInitialized = true;
    } catch (e) {
      print("❌ Error initializing notifications: $e");
    }
  }


  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Reminder channel
    const reminderChannel = AndroidNotificationChannel(
      'alongside_reminders',
      'Friend Reminders',
      description: 'Reminders to check in with friends',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
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
  }

  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final notification = await Permission.notification.request();
        final exactAlarm = await Permission.scheduleExactAlarm.request();
        return notification.isGranted && exactAlarm.isGranted;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(NotificationResponse response) {
    // Handle notification in background
  }

  void _handleNotificationResponse(NotificationResponse response) {
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

  // Main method to schedule reminders for a friend
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
      // Cancel existing notifications for this friend
      await cancelReminder(friend.id);

      // Schedule the next N notifications
      await _scheduleNotificationsForFriend(friend);

      return true;
    } catch (e) {
      print("❌ Error scheduling reminder: $e");
      return false;
    }
  }

  // Schedule multiple notifications in advance
  Future<void> _scheduleNotificationsForFriend(Friend friend) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Parse reminder time
    final timeParts = friend.reminderTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    // Check if friend was just created
    final justCreated = prefs.getBool('just_created_${friend.id}') ?? false;
    if (justCreated) {
      await prefs.remove('just_created_${friend.id}');
    }

// Get last action time
    final lastActionTime = prefs.getInt('last_action_${friend.id}');

// Schedule the next N occurrences
    final List<DateTime> scheduleTimes = [];
    DateTime nextTime;

    if (justCreated || lastActionTime == null) {
      // New friend - try to schedule today if time hasn't passed
      nextTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Add 1 minute buffer to allow for processing time
      final nowWithBuffer = now.add(Duration(minutes: 1));

      // If time has passed today, schedule for tomorrow
      if (nextTime.isBefore(nowWithBuffer)) {
        nextTime = nextTime.add(Duration(days: 1));
      }
    } else {
      // Existing friend - calculate from last action
      final baseTime = DateTime.fromMillisecondsSinceEpoch(lastActionTime);
      nextTime = DateTime(
        baseTime.year,
        baseTime.month,
        baseTime.day + friend.reminderDays,
        hour,
        minute,
      );
    }

    // Make sure first notification is in the future
    while (nextTime.isBefore(now)) {
      nextTime = nextTime.add(Duration(days: friend.reminderDays));
    }

    // Calculate next N notification times
    for (int i = 0; i < _notificationsToSchedule; i++) {
      scheduleTimes.add(nextTime);
      nextTime = nextTime.add(Duration(days: friend.reminderDays));
    }

    // Schedule each notification
    for (int i = 0; i < scheduleTimes.length; i++) {
      final scheduleTime = scheduleTimes[i];
      final notificationId = _getNotificationId(friend.id, i);

      await _scheduleIndividualNotification(
        notificationId,
        friend,
        scheduleTime,
      );

      // For Android, schedule WorkManager to reschedule when this fires
      if (Platform.isAndroid && i == 0) {
        final delay = scheduleTime.difference(now);
        await Workmanager().registerOneOffTask(
          "reschedule_${friend.id}_$i",
          "rescheduleNotification",
          initialDelay: delay,
          inputData: {'friendId': friend.id},
          constraints: Constraints(
            networkType: NetworkType.not_required,
          ),
        );
      }
    }

    // Store the next reminder time for display purposes
    if (scheduleTimes.isNotEmpty) {
      await prefs.setInt(
        'next_reminder_${friend.id}',
        scheduleTimes.first.millisecondsSinceEpoch,
      );
    }
  }

  // Schedule individual notification
  Future<void> _scheduleIndividualNotification(
      int id,
      Friend friend,
      DateTime scheduleTime,
      ) async {
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

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime tzScheduleTime = tz.TZDateTime.from(scheduleTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Check in with ${friend.name}',
      'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'} since your last check-in',
      tzScheduleTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: '${friend.id};${friend.phoneNumber}',
    );
    print("✅ Scheduled notification for ${friend.name}");
    print("   Scheduled time: $tzScheduleTime");
    print("   That's in: ${tzScheduleTime.difference(tz.TZDateTime.now(tz.local))}");
  }

  // Generate notification ID
  int _getNotificationId(String friendId, int index) {
    int hash = 0;
    for (int i = 0; i < friendId.length; i++) {
      hash = ((hash * 31) + friendId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 100000 + (hash % 900000) + (index * 1000);
  }

  // Cancel all reminders for a friend
  Future<void> cancelReminder(String friendId) async {
    try {
      // Cancel all scheduled notifications for this friend
      for (int i = 0; i < _notificationsToSchedule; i++) {
        final id = _getNotificationId(friendId, i);
        await flutterLocalNotificationsPlugin.cancel(id);
      }

      // Cancel WorkManager tasks
      if (Platform.isAndroid) {
        for (int i = 0; i < _notificationsToSchedule; i++) {
          await Workmanager().cancelByUniqueName("reschedule_${friendId}_$i");
        }
      }

      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('next_reminder_$friendId');
    } catch (e) {
      print("❌ Error cancelling reminder: $e");
    }
  }

  // Persistent notifications (unchanged)
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
      final id = _persistentOffset + _getNotificationId(friend.id, 0);

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
    } catch (e) {
      print("❌ Error showing persistent notification: $e");
    }
  }

  Future<void> removePersistentNotification(String friendId) async {
    try {
      final id = _persistentOffset + _getNotificationId(friendId, 0);
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      print("❌ Error removing persistent notification: $e");
    }
  }

  // Check and extend notification schedule
  Future<void> checkAndExtendSchedule() async {
    try {
      final storageService = StorageService();
      final friends = await storageService.getFriends();

      for (final friend in friends) {
        if (friend.reminderDays > 0) {
          // Check how many notifications are still pending
          final pending = await getPendingNotifications();
          int pendingCount = 0;

          for (int i = 0; i < _notificationsToSchedule; i++) {
            final id = _getNotificationId(friend.id, i);
            if (pending.any((n) => n.id == id)) {
              pendingCount++;
            }
          }

          // If less than 2 notifications remain, schedule more
          if (pendingCount < 2) {
            await scheduleReminder(friend);
          }
        }
      }
    } catch (e) {
      print("❌ Error checking schedule: $e");
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
        'Notifications are working! 🎉',
        NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      print("❌ Error sending test notification: $e");
    }
  }

  // This method is now unused but kept for compatibility
  Future<void> checkAndRescheduleAllReminders() async {
    // Now handled by checkAndExtendSchedule
    await checkAndExtendSchedule();
  }

  // Debug info
  Future<void> debugScheduledNotifications() async {
    try {
      final pending = await getPendingNotifications();

      print("\n📅 ===== SCHEDULED NOTIFICATIONS =====");
      print("Current time: ${DateTime.now()}");
      print("Total pending: ${pending.length}");

      for (final notification in pending) {
        print("\nID: ${notification.id} - ${notification.title}");
        // Don't try to match with stored times - just show what's scheduled
      }
      print("=====================================\n");
    } catch (e) {
      print("❌ Error debugging notifications: $e");
    }
  }

  Future<void> scheduleTestIn30Seconds() async {
    final now = DateTime.now();
    final testTime = now.add(Duration(seconds: 30));

    final androidDetails = AndroidNotificationDetails(
      'alongside_reminders',
      'Friend Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final tzTime = tz.TZDateTime.from(testTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      888888,
      'Test in 30 seconds',
      'If you see this, scheduling works!',
      tzTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print("⏰ Test notification scheduled for: $testTime (in 30 seconds)");
  }
}
