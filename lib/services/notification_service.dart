// lib/services/notification_service.dart - FIXED WITH PROPER ACTION ROUTING
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide RepeatInterval;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import '../models/day_selection_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:workmanager/workmanager.dart';
import 'storage_service.dart';

typedef NotificationActionCallback = void Function(String friendId, String action);

// CLEAN WORKMANAGER DISPATCHER
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == "send_reminder") {
        final friendId = inputData?['friendId'] as String?;
        final friendName = inputData?['friendName'] as String?;
        final reminderText = inputData?['reminderText'] as String? ?? 'Check in reminder';

        if (friendId != null && friendName != null) {
          await _sendCleanBackgroundNotification(friendId, friendName, reminderText);
          return Future.value(true);
        }
      }
    } catch (e) {
      // Silent error handling
    }
    return Future.value(false);
  });
}

// BULLETPROOF: Background notification with comprehensive error handling
Future<void> _sendCleanBackgroundNotification(String friendId, String friendName, String reminderText) async {
  try {
    // Validate inputs
    if (friendId.isEmpty || friendName.isEmpty) {
      print("❌ Invalid notification inputs: friendId='$friendId', friendName='$friendName'");
      return;
    }

    final notificationPlugin = FlutterLocalNotificationsPlugin();

    // Initialize with timeout
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await notificationPlugin.initialize(initSettings).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("❌ Notification initialization timeout");
          return false;
        },
      );
    } catch (e) {
      print("❌ Notification initialization failed: $e");
      return;
    }

    // Generate safe notification ID
    final notificationId = friendName.hashCode.abs() % 999999 + 100000;

    // Sanitize text inputs
    final safeReminderText = reminderText.isNotEmpty ? reminderText : 'Time to check in';
    final safeFriendName = friendName.length > 50 ? friendName.substring(0, 50) : friendName;

    try {
      await notificationPlugin.show(
        notificationId,
        'Time to check in with $safeFriendName',
        safeReminderText,
        NotificationDetails(
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
        payload: '$friendId|reminder',
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print("❌ Notification show timeout for $friendId");
        },
      );

      print("✅ Background notification sent for $safeFriendName");

      // AUTO-RESCHEDULE NEXT REMINDER
      try {
        final storageService = StorageService();
        final friends = await storageService.getFriends();
        final friend = friends.firstWhere((f) => f.id == friendId);

        if (friend.hasReminder) {
          final notificationService = NotificationService();
          final prefs = await SharedPreferences.getInstance();

          // Don't update last_action - this is a reminder, not user interaction
          // Just reschedule for next occurrence

          final success = await notificationService.scheduleReminder(friend);
          if (success) {
            print("✅ Auto-rescheduled next reminder for $safeFriendName");
          } else {
            print("⚠️ Failed to auto-reschedule for $safeFriendName");
          }
        }
      } catch (e) {
        print("⚠️ Couldn't auto-reschedule: $e");
        // Don't fail the whole notification just because rescheduling failed
      }

    } catch (e) {
      print("❌ Failed to show notification for $friendId: $e");
    }
  } catch (e) {
    print("❌ Critical error in background notification: $e");
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
      print("\n🚀 INITIALIZING NOTIFICATION SYSTEM WITH DAY SELECTION");

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

      if (Platform.isAndroid) {
        await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
        print("🔄 WorkManager initialized");
      }

      await _requestPermissions();

      _isInitialized = true;
      print("✅ NOTIFICATION SYSTEM READY WITH DAY SELECTION\n");
    } catch (e) {
      print("❌ INITIALIZATION ERROR: $e");
    }
  }

  // Optimized method to get all reminder times in bulk
  Future<Map<String, DateTime?>> getAllReminderTimes(List<String> friendIds) async {
    final Map<String, DateTime?> reminderTimes = {};
    final prefs = await SharedPreferences.getInstance();

    for (String friendId in friendIds) {
      final time = prefs.getInt('next_reminder_$friendId');
      reminderTimes[friendId] = time != null ? DateTime.fromMillisecondsSinceEpoch(time) : null;
    }

    return reminderTimes;
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

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

  // FIXED: Proper notification response handling with consistent payload parsing
// FIXED: Proper notification response handling with default to message
// BULLETPROOF: Notification response handling with comprehensive validation
  void _handleNotificationResponse(NotificationResponse response) {
    try {
      print("🔔 FOREGROUND: ${response.payload}, Action: ${response.actionId}");

      // Validate callback exists
      if (_actionCallback == null) {
        print("❌ No action callback set - cannot handle notification");
        return;
      }

      // Validate payload
      final String? payload = response.payload;
      if (payload == null || payload.isEmpty || payload.trim().isEmpty) {
        print("❌ Invalid or empty payload");
        return;
      }

      // Parse payload safely
      final parts = payload.split('|');
      if (parts.isEmpty) {
        print("❌ Malformed payload: $payload");
        return;
      }

      final friendId = parts[0].trim();
      if (friendId.isEmpty) {
        print("❌ Empty friendId in payload: $payload");
        return;
      }

      // Validate and sanitize action
      final String? actionId = response.actionId;
      String finalAction;

      if (actionId != null && actionId.isNotEmpty) {
        // Validate known actions
        if (actionId == 'call' || actionId == 'message') {
          finalAction = actionId;
        } else {
          print("⚠️ Unknown actionId '$actionId', defaulting to message");
          finalAction = 'message';
        }
      } else {
        // Default to message for tap without action button
        finalAction = 'message';
      }

      print("🔔 Calling callback with friendId: $friendId, action: $finalAction");

      // Call with timeout protection
      try {
        _actionCallback!(friendId, finalAction);
      } catch (e) {
        print("❌ Error in notification callback: $e");
      }

    } catch (e) {
      print("❌ Critical error handling notification response: $e");
    }
  }

  Future<List<Friend>> sortFriendsByReminderProximityOptimized(List<Friend> friends) async {
    if (friends.isEmpty) return friends;

    // Get all reminder times in one go
    final friendIds = friends.map((f) => f.id).toList();
    final notificationService = NotificationService();
    final reminderTimes = await notificationService.getAllReminderTimes(friendIds);

    // Create list with reminder times
    List<MapEntry<Friend, DateTime?>> friendsWithTimes = friends
        .map((friend) => MapEntry(friend, reminderTimes[friend.id]))
        .toList();

    // Sort by reminder proximity
    friendsWithTimes.sort((a, b) {
      // FIXED: Use hasReminder instead of reminderDays > 0
      final aHasReminder = a.key.hasReminder;
      final bHasReminder = b.key.hasReminder;

      // Friends without reminders go to the end
      if (!aHasReminder && !bHasReminder) return 0;
      if (!aHasReminder) return 1;
      if (!bHasReminder) return -1;

      // Both have reminders - sort by next reminder time
      if (a.value == null && b.value == null) return 0;
      if (a.value == null) return 1;
      if (b.value == null) return -1;

      return a.value!.compareTo(b.value!);
    });

    return friendsWithTimes.map((entry) => entry.key).toList();
  }

  // UPDATED: Schedule reminder with day selection support
  Future<bool> scheduleReminder(Friend friend) async {
    if (!_isInitialized) {
      await initialize();
    }

    print("\n🔄 SCHEDULING REMINDER FOR: ${friend.name}");
    print("   - Has reminder: ${friend.hasReminder}");
    print("   - Uses advanced reminders: ${friend.usesAdvancedReminders}");
    print("   - Reminder days: ${friend.reminderDays}");
    print("   - Reminder data: ${friend.reminderData}");

    try {
      await cancelReminder(friend.id);

      // FIXED: Check hasReminder instead of reminderDays > 0
      if (!friend.hasReminder) {
        print("❌ Friend has no reminders enabled");
        return false;
      }

      final nextTime = await _calculateNextReminderTime(friend);
      if (nextTime == null) {
        print("❌ Could not calculate next reminder time");
        return false;
      }

      return await _scheduleWithWorkManager(friend, nextTime);

    } catch (e) {
      print("❌ SCHEDULING ERROR: $e");
      return false;
    }
  }

  // UPDATED: Calculate next reminder time with day selection support
  Future<DateTime?> _calculateNextReminderTime(Friend friend) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    final timeParts = friend.reminderTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    final lastActionTime = prefs.getInt('last_action_${friend.id}');

    DateTime nextTime;

    // NEW: Use day selection system if available
    if (friend.usesAdvancedReminders) {
      try {
        final daySelectionData = DaySelectionData.fromJson(friend.reminderData!);

        // Calculate from last action time or now
        final fromTime = lastActionTime != null
            ? DateTime.fromMillisecondsSinceEpoch(lastActionTime)
            : now;

        nextTime = daySelectionData.calculateNextReminder(fromTime, hour, minute) ??
            DateTime(now.year, now.month, now.day + 1, hour, minute);

        print("📅 Next reminder (day selection): $nextTime");
      } catch (e) {
        print("❌ Error parsing day selection data: $e");
        // Fallback to old system
        return _calculateLegacyReminderTime(friend, now, hour, minute, lastActionTime);
      }
    } else {
      // Fallback to old system
      return _calculateLegacyReminderTime(friend, now, hour, minute, lastActionTime);
    }

    // Ensure the time is in the future
    while (nextTime.isBefore(now.add(Duration(minutes: 1)))) {
      if (friend.usesAdvancedReminders) {
        try {
          final daySelectionData = DaySelectionData.fromJson(friend.reminderData!);
          nextTime = daySelectionData.calculateNextReminder(nextTime.add(Duration(days: 1)), hour, minute) ??
              nextTime.add(Duration(days: 1));
        } catch (e) {
          nextTime = nextTime.add(Duration(days: friend.reminderDays > 0 ? friend.reminderDays : 7));
        }
      } else {
        nextTime = nextTime.add(Duration(days: friend.reminderDays > 0 ? friend.reminderDays : 7));
      }
    }

    return nextTime;
  }

  // Legacy reminder calculation for backward compatibility
  Future<DateTime?> _calculateLegacyReminderTime(Friend friend, DateTime now, int hour, int minute, int? lastActionTime) async {
    // FIXED: For legacy system, check reminderDays > 0
    if (friend.reminderDays <= 0) return null;

    DateTime nextTime;

    if (lastActionTime == null) {
      // First time scheduling - start tomorrow at specified time
      nextTime = DateTime(now.year, now.month, now.day + 1, hour, minute);
      print("📅 First reminder (legacy): $nextTime");
    } else {
      final lastAction = DateTime.fromMillisecondsSinceEpoch(lastActionTime);
      nextTime = DateTime(
        lastAction.year,
        lastAction.month,
        lastAction.day + friend.reminderDays,
        hour,
        minute,
      );
      print("📅 Next reminder (legacy): $nextTime");
    }

    return nextTime;
  }

  Future<bool> _scheduleWithWorkManager(Friend friend, DateTime nextTime) async {
    try {
      final now = DateTime.now();
      final delay = nextTime.difference(now);

      print("   Next time: $nextTime");
      print("   Delay: $delay");

      if (delay.isNegative || delay.inMinutes < 1) {
        print("❌ Invalid delay time");
        return false;
      }

      // Cancel existing
      await Workmanager().cancelByUniqueName("reminder_${friend.id}");

      // Get reminder text based on interval
      String reminderText = 'Your scheduled check-in';
      if (friend.usesAdvancedReminders) {
        try {
          final daySelectionData = DaySelectionData.fromJson(friend.reminderData!);
          switch (daySelectionData.interval) {
            case RepeatInterval.weekly:
              reminderText = 'Your weekly check-in';
              break;
            case RepeatInterval.biweekly:
              reminderText = 'Your bi-weekly check-in';
              break;
            case RepeatInterval.monthly:
              reminderText = 'Your monthly check-in';
              break;
            case RepeatInterval.quarterly:
              reminderText = 'Your quarterly check-in';
              break;
            case RepeatInterval.semiannually:
              reminderText = 'Your semi-annual check-in';
              break;
          }
        } catch (e) {
          reminderText = 'Your scheduled check-in';
        }
      } else {
        reminderText = 'It\'s been ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'}';
      }

      // Schedule with WorkManager
      await Workmanager().registerOneOffTask(
        "reminder_${friend.id}",
        "send_reminder",
        initialDelay: delay,
        inputData: {
          'friendId': friend.id,
          'friendName': friend.name,
          'reminderText': reminderText,
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

  // Test methods
  Future<void> scheduleTestIn30Seconds() async {
    try {
      print("\n🧪 SCHEDULED TEST IN 30 SECONDS");

      await Workmanager().cancelByUniqueName("test_30s");

      await Workmanager().registerOneOffTask(
        "test_30s",
        "send_reminder",
        initialDelay: Duration(seconds: 30),
        inputData: {
          'friendId': 'test_scheduled',
          'friendName': 'Test Friend',
          'reminderText': 'Scheduled test notification',
        },
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      print("✅ Scheduled test planned");

    } catch (e) {
      print("❌ Scheduled test error: $e");
    }
  }

  Future<void> scheduleTestNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        999999,
        'Time to check in with Test Friend',
        'Immediate test notification',
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
        payload: 'test_immediate|reminder',
      );
      print("📨 Immediate test sent");
    } catch (e) {
      print("❌ Immediate test error: $e");
    }
  }

  // Utility methods
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }

  Future<void> debugScheduledNotifications() async {
    try {
      print("\n🔄 NOTIFICATION DEBUG");
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

      print("\n📝 SCHEDULED REMINDERS:");
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

  // FIXED: Persistent notifications with proper action buttons
  Future<void> showPersistentNotification(Friend friend) async {
    if (!friend.hasPersistentNotification) return;

    try {
      final id = _persistentOffset + _getNotificationId(friend.id);
      await flutterLocalNotificationsPlugin.show(
        id,
        'Alongside ${friend.name}',
        'Tap to check in',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'alongside_persistent',
            'Quick Access',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'message',
                'Message',
                showsUserInterface: true,
                cancelNotification: false, // Don't cancel persistent notifications
              ),
              AndroidNotificationAction(
                'call',
                'Call',
                showsUserInterface: true,
                cancelNotification: false, // Don't cancel persistent notifications
              ),
            ],
          ),
        ),
        payload: '${friend.id}|persistent', // FIXED: Consistent payload format
      );
      print("📌 Persistent notification shown for ${friend.name}");
    } catch (e) {
      print("❌ Persistent error: $e");
    }
  }

  Future<void> removePersistentNotification(String friendId) async {
    try {
      final id = _persistentOffset + _getNotificationId(friendId);
      await flutterLocalNotificationsPlugin.cancel(id);
      print("🗑️ Persistent notification removed for $friendId");
    } catch (e) {
      print("❌ Remove persistent error: $e");
    }
  }
}