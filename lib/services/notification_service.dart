// lib/services/notification_service.dart - FIXED: Background rescheduling after notification fires
import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide RepeatInterval;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import '../models/day_selection_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:workmanager/workmanager.dart';

typedef NotificationActionCallback = void Function(String friendId, String action);

// FIXED: WorkManager callback that RESCHEDULES after firing
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("🔔 WorkManager executing: $task");

      if (task == "send_reminder") {
        final friendId = inputData?['friendId'] as String?;
        final friendName = inputData?['friendName'] as String?;
        final reminderText = inputData?['reminderText'] as String? ?? 'Check in reminder';

        if (friendId != null && friendName != null) {
          // Send the notification
          await _sendBackgroundNotification(friendId, friendName, reminderText);

          // CRITICAL FIX: Schedule the NEXT reminder
          await _rescheduleFromBackground(friendId);

          return Future.value(true);
        }
      }
    } catch (e) {
      print("❌ WorkManager error: $e");
    }
    return Future.value(false);
  });
}

Future<void> _sendBackgroundNotification(String friendId, String friendName, String reminderText) async {
  try {
    if (friendId.isEmpty || friendName.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);

    final notificationId = friendName.hashCode.abs() % 999999 + 100000;
    final safeName = friendName.length > 50 ? friendName.substring(0, 50) : friendName;

    await plugin.show(
      notificationId,
      'Time to check in with $safeName',
      reminderText,
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
            AndroidNotificationAction('message', 'Message', showsUserInterface: true, cancelNotification: true),
            AndroidNotificationAction('call', 'Call', showsUserInterface: true, cancelNotification: true),
          ],
        ),
      ),
      payload: '$friendId|reminder',
    );
    print("✅ Notification sent for $safeName");
  } catch (e) {
    print("❌ Send notification error: $e");
  }
}

// CRITICAL: Reschedule next reminder from background
Future<void> _rescheduleFromBackground(String friendId) async {
  try {
    print("🔄 Rescheduling next reminder for $friendId");

    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('friend_config_$friendId');

    if (configJson == null) {
      print("❌ No config found for $friendId");
      return;
    }

    final config = jsonDecode(configJson) as Map<String, dynamic>;
    final friendName = config['name'] as String? ?? 'Friend';
    final reminderTime = config['reminderTime'] as String? ?? '09:00';
    final reminderData = config['reminderData'] as String?;
    final reminderDays = config['reminderDays'] as int? ?? 0;

    // Parse time
    final timeParts = reminderTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    final now = DateTime.now();
    DateTime nextTime;
    String nextReminderText;

    // Calculate next time based on reminder type
    if (reminderData != null && reminderData.isNotEmpty) {
      try {
        final daySelection = DaySelectionData.fromJson(reminderData);
        nextTime = daySelection.calculateNextReminder(now, hour, minute) ??
            DateTime(now.year, now.month, now.day + 7, hour, minute);

        switch (daySelection.interval) {
          case RepeatInterval.weekly:
            nextReminderText = 'Your weekly check-in';
            break;
          case RepeatInterval.biweekly:
            nextReminderText = 'Your bi-weekly check-in';
            break;
          case RepeatInterval.monthly:
            nextReminderText = 'Your monthly check-in';
            break;
          case RepeatInterval.quarterly:
            nextReminderText = 'Your quarterly check-in';
            break;
          case RepeatInterval.semiannually:
            nextReminderText = 'Your semi-annual check-in';
            break;
        }
      } catch (e) {
        nextTime = DateTime(now.year, now.month, now.day + (reminderDays > 0 ? reminderDays : 7), hour, minute);
        nextReminderText = 'Your scheduled check-in';
      }
    } else if (reminderDays > 0) {
      nextTime = DateTime(now.year, now.month, now.day + reminderDays, hour, minute);
      nextReminderText = 'It\'s been $reminderDays ${reminderDays == 1 ? 'day' : 'days'}';
    } else {
      print("❌ No valid reminder config");
      return;
    }

    // Ensure future time
    while (nextTime.isBefore(now.add(const Duration(minutes: 1)))) {
      if (reminderData != null && reminderData.isNotEmpty) {
        try {
          final daySelection = DaySelectionData.fromJson(reminderData);
          nextTime = daySelection.calculateNextReminder(nextTime.add(const Duration(days: 1)), hour, minute) ??
              nextTime.add(const Duration(days: 7));
        } catch (e) {
          nextTime = nextTime.add(Duration(days: reminderDays > 0 ? reminderDays : 7));
        }
      } else {
        nextTime = nextTime.add(Duration(days: reminderDays > 0 ? reminderDays : 7));
      }
    }

    final delay = nextTime.difference(now);
    if (delay.isNegative || delay.inMinutes < 1) {
      print("❌ Invalid delay");
      return;
    }

    // Schedule next
    await Workmanager().registerOneOffTask(
      "reminder_$friendId",
      "send_reminder",
      initialDelay: delay,
      inputData: {
        'friendId': friendId,
        'friendName': friendName,
        'reminderText': nextReminderText,
      },
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    await prefs.setInt('next_reminder_$friendId', nextTime.millisecondsSinceEpoch);
    print("✅ Next reminder scheduled for $friendId at $nextTime");

  } catch (e) {
    print("❌ Reschedule error: $e");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  NotificationActionCallback? _actionCallback;
  bool _isInitialized = false;
  static const int _persistentOffset = 2000000;

  void setActionCallback(NotificationActionCallback callback) {
    _actionCallback = callback;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("\n🚀 INITIALIZING NOTIFICATION SYSTEM");

      tz_data.initializeTimeZones();
      String timeZoneName;
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        timeZoneName = 'UTC';
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("📍 Timezone: $timeZoneName");

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      print("✅ NOTIFICATION SYSTEM READY\n");
    } catch (e) {
      print("❌ INITIALIZATION ERROR: $e");
    }
  }

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

  void _handleNotificationResponse(NotificationResponse response) {
    try {
      print("🔔 FOREGROUND: ${response.payload}, Action: ${response.actionId}");

      if (_actionCallback == null) {
        print("❌ No action callback set");
        return;
      }

      final String? payload = response.payload;
      if (payload == null || payload.isEmpty) {
        print("❌ Invalid payload");
        return;
      }

      final parts = payload.split('|');
      if (parts.isEmpty) return;

      final friendId = parts[0].trim();
      if (friendId.isEmpty) return;

      final String? actionId = response.actionId;
      String finalAction;

      if (actionId == 'call' || actionId == 'message') {
        finalAction = actionId!;
      } else {
        finalAction = 'message';
      }

      print("🔔 Callback: friendId=$friendId, action=$finalAction");
      _actionCallback!(friendId, finalAction);

    } catch (e) {
      print("❌ Handle response error: $e");
    }
  }

  Future<List<Friend>> sortFriendsByReminderProximityOptimized(List<Friend> friends) async {
    if (friends.isEmpty) return friends;

    final friendIds = friends.map((f) => f.id).toList();
    final reminderTimes = await getAllReminderTimes(friendIds);

    List<MapEntry<Friend, DateTime?>> friendsWithTimes = friends
        .map((friend) => MapEntry(friend, reminderTimes[friend.id]))
        .toList();

    friendsWithTimes.sort((a, b) {
      final aHasReminder = a.key.hasReminder;
      final bHasReminder = b.key.hasReminder;

      if (!aHasReminder && !bHasReminder) return 0;
      if (!aHasReminder) return 1;
      if (!bHasReminder) return -1;

      if (a.value == null && b.value == null) return 0;
      if (a.value == null) return 1;
      if (b.value == null) return -1;

      return a.value!.compareTo(b.value!);
    });

    return friendsWithTimes.map((entry) => entry.key).toList();
  }

  Future<bool> scheduleReminder(Friend friend) async {
    if (!_isInitialized) {
      await initialize();
    }

    print("\n🔄 SCHEDULING REMINDER FOR: ${friend.name}");

    try {
      await cancelReminder(friend.id);

      if (!friend.hasReminder) {
        print("❌ No reminders enabled");
        return false;
      }

      // CRITICAL: Store friend config for background rescheduling
      final prefs = await SharedPreferences.getInstance();
      final config = {
        'name': friend.name,
        'reminderTime': friend.reminderTime,
        'reminderData': friend.reminderData,
        'reminderDays': friend.reminderDays,
      };
      await prefs.setString('friend_config_${friend.id}', jsonEncode(config));

      final nextTime = await _calculateNextReminderTime(friend);
      if (nextTime == null) {
        print("❌ Could not calculate next time");
        return false;
      }

      return await _scheduleWithWorkManager(friend, nextTime);

    } catch (e) {
      print("❌ SCHEDULING ERROR: $e");
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

    if (friend.usesAdvancedReminders) {
      try {
        final daySelectionData = DaySelectionData.fromJson(friend.reminderData!);
        final fromTime = lastActionTime != null
            ? DateTime.fromMillisecondsSinceEpoch(lastActionTime)
            : now;

        nextTime = daySelectionData.calculateNextReminder(fromTime, hour, minute) ??
            DateTime(now.year, now.month, now.day + 1, hour, minute);

        print("📅 Next reminder (day selection): $nextTime");
      } catch (e) {
        print("❌ Error parsing day selection: $e");
        return _calculateLegacyReminderTime(friend, now, hour, minute, lastActionTime);
      }
    } else {
      return _calculateLegacyReminderTime(friend, now, hour, minute, lastActionTime);
    }

    while (nextTime.isBefore(now.add(const Duration(minutes: 1)))) {
      if (friend.usesAdvancedReminders) {
        try {
          final daySelectionData = DaySelectionData.fromJson(friend.reminderData!);
          nextTime = daySelectionData.calculateNextReminder(nextTime.add(const Duration(days: 1)), hour, minute) ??
              nextTime.add(const Duration(days: 1));
        } catch (e) {
          nextTime = nextTime.add(Duration(days: friend.reminderDays > 0 ? friend.reminderDays : 7));
        }
      } else {
        nextTime = nextTime.add(Duration(days: friend.reminderDays > 0 ? friend.reminderDays : 7));
      }
    }

    return nextTime;
  }

  Future<DateTime?> _calculateLegacyReminderTime(Friend friend, DateTime now, int hour, int minute, int? lastActionTime) async {
    if (friend.reminderDays <= 0) return null;

    DateTime nextTime;

    if (lastActionTime == null) {
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
        print("❌ Invalid delay");
        return false;
      }

      await Workmanager().cancelByUniqueName("reminder_${friend.id}");

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('next_reminder_${friend.id}', nextTime.millisecondsSinceEpoch);

      print("✅ WorkManager scheduled for ${friend.name}");
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
      print("🗑️ Cancelled: $friendId");
    } catch (e) {
      print("❌ Cancel error: $e");
    }
  }

  Future<void> recordFriendInteraction(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_action_$friendId', DateTime.now().millisecondsSinceEpoch);
      print("📝 Recorded interaction: $friendId");
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

  Future<void> scheduleTestIn30Seconds() async {
    try {
      print("\n🧪 TEST IN 30 SECONDS");
      await Workmanager().cancelByUniqueName("test_30s");
      await Workmanager().registerOneOffTask(
        "test_30s",
        "send_reminder",
        initialDelay: const Duration(seconds: 30),
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
      print("✅ Test scheduled");
    } catch (e) {
      print("❌ Test error: $e");
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
              AndroidNotificationAction('message', 'Message', showsUserInterface: true, cancelNotification: true),
              AndroidNotificationAction('call', 'Call', showsUserInterface: true, cancelNotification: true),
            ],
          ),
        ),
        payload: 'test_immediate|reminder',
      );
      print("📨 Immediate test sent");
    } catch (e) {
      print("❌ Test error: $e");
    }
  }

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
      print("\n📋 PENDING: ${pending.length}");
      for (final n in pending) {
        print("   ID: ${n.id} - ${n.title}");
      }

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('next_reminder_'));

      print("\n📝 SCHEDULED:");
      for (final key in keys) {
        final time = prefs.getInt(key);
        if (time != null) {
          final id = key.replaceFirst('next_reminder_', '');
          final dt = DateTime.fromMillisecondsSinceEpoch(time);
          print("   $id: $dt ${dt.isBefore(now) ? '(OVERDUE)' : ''}");
        }
      }
      print("=" * 50);
    } catch (e) {
      print("❌ Debug error: $e");
    }
  }

  Future<void> checkAndExtendSchedule() async {
    print("🔍 WorkManager handles scheduling");
  }

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
              AndroidNotificationAction('message', 'Message', showsUserInterface: true, cancelNotification: false),
              AndroidNotificationAction('call', 'Call', showsUserInterface: true, cancelNotification: false),
            ],
          ),
        ),
        payload: '${friend.id}|persistent',
      );
      print("📌 Persistent shown: ${friend.name}");
    } catch (e) {
      print("❌ Persistent error: $e");
    }
  }

  Future<void> removePersistentNotification(String friendId) async {
    try {
      final id = _persistentOffset + _getNotificationId(friendId);
      await flutterLocalNotificationsPlugin.cancel(id);
      print("🗑️ Persistent removed: $friendId");
    } catch (e) {
      print("❌ Remove error: $e");
    }
  }
}