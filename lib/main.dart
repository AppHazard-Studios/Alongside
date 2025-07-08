// lib/main.dart - SIMPLIFIED VERSION WITHOUT FOREGROUND SERVICE
import 'dart:async';
import 'package:alongside/screens/lock_screen.dart';
import 'package:alongside/services/lock_service.dart';
import 'package:alongside/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
import 'providers/friends_provider.dart';
import 'theme/app_theme.dart';
import 'screens/call_screen.dart';
import 'screens/message_screen.dart';
import 'services/battery_optimization_service.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications with hybrid system
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Setup notification callback
  notificationService.setActionCallback(_handleNotificationAction);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FriendsProvider(
            storageService: StorageService(),
            notificationService: notificationService,
          ),
        ),
      ],
      child: const AlongsideApp(),
    ),
  );
}

// Global notification handler
void _handleNotificationAction(String friendId, String action) async {
  print("🔔 Notification action: Friend=$friendId, Action=$action");

  // Wait for navigator
  int attempts = 0;
  while (navigatorKey.currentState == null && attempts < 50) {
    await Future.delayed(const Duration(milliseconds: 100));
    attempts++;
  }

  if (navigatorKey.currentState == null) {
    print("❌ Navigator not ready");
    return;
  }

  // Store action to process
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_notification_action', '$friendId|$action');

  // Navigate
  navigatorKey.currentState!.popUntil((route) => route.isFirst);
  navigatorKey.currentState!.pushNamed('/notification');
}

class AlongsideApp extends StatefulWidget {
  const AlongsideApp({Key? key}) : super(key: key);

  @override
  State<AlongsideApp> createState() => _AlongsideAppState();
}

class _AlongsideAppState extends State<AlongsideApp> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _lockChecked = false;
  final LockService _lockService = LockService();
  DateTime? _pausedTime;
  Timer? _scheduleCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // FIXED: Don't set lock state immediately - check it properly
    _lockChecked = false;  // Start as unchecked
    _isLocked = false;     // Will be set by lock check

    // Initialize app after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduleCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        print("📱 App paused");
        _lockService.recordBackgroundTime();
        _pausedTime = DateTime.now();
        break;

      case AppLifecycleState.resumed:
        print("📱 App resumed");
        _checkIfShouldLock();

        // Check and extend notification schedules when app resumes
        _checkNotificationSchedules();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _checkIfShouldLock() async {
    print("🔒 Checking lock on app resume...");

    final shouldLock = await _lockService.shouldShowLockScreen();

    if (shouldLock && mounted) {
      print("🔒 Lock screen required on resume");
      setState(() {
        _isLocked = true;
      });
    } else {
      print("🔓 No lock required on resume");
      await _lockService.clearBackgroundTime();
    }
  }

  Future<void> _initializeApp() async {
    print("🚀 Initializing app...");

    try {
      // CRITICAL: Check if lock screen should be shown on cold start
      await _checkLockOnColdStart();

      // Only continue with other initialization if not locked
      if (!_isLocked) {
        // Check battery optimization after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            BatteryOptimizationService.requestBatteryOptimization(context);
          }
        });

        // Setup periodic schedule checks (every 6 hours)
        _scheduleCheckTimer = Timer.periodic(
          const Duration(hours: 6),
              (_) => _checkNotificationSchedules(),
        );

        // Initial schedule check
        await _checkNotificationSchedules();

        // Debug notifications
        Future.delayed(const Duration(seconds: 3), () async {
          final notificationService = NotificationService();
          await notificationService.debugScheduledNotifications();
        });
      }
    } catch (e) {
      print("❌ Error initializing app: $e");
    }
  }

  Future<void> _checkLockOnColdStart() async {
    try {
      print("🔒 Checking lock on cold start...");

      final shouldLock = await _lockService.shouldShowLockScreen();

      if (shouldLock && mounted) {
        print("🔒 Lock screen required on cold start");
        setState(() {
          _isLocked = true;
          _lockChecked = true;
        });
      } else {
        print("🔓 No lock required on cold start");
        setState(() {
          _isLocked = false;
          _lockChecked = true;
        });
        // Clear any background time since we're starting fresh
        await _lockService.clearBackgroundTime();
      }
    } catch (e) {
      print("❌ Error checking lock on cold start: $e");
      // If error, default to not locked but mark as checked
      setState(() {
        _isLocked = false;
        _lockChecked = true;
      });
    }
  }

  Future<void> _checkNotificationSchedules() async {
    try {
      print("🔍 Checking notification schedules...");
      final notificationService = NotificationService();
      await notificationService.checkAndExtendSchedule();
    } catch (e) {
      print("❌ Error checking schedules: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking lock status
    if (!_lockChecked) {
      return CupertinoApp(
        title: 'Alongside',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertinoTheme,
        home: CupertinoPageScaffold(
          backgroundColor: AppColors.background,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.heart_fill,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const CupertinoActivityIndicator(radius: 14),
                const SizedBox(height: 16),
                const Text(
                  'Alongside',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show lock screen if locked
    if (_isLocked) {
      return CupertinoApp(
        title: 'Alongside',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertinoTheme,
        home: LockScreen(
          onUnlocked: () {
            setState(() {
              _isLocked = false;
            });
            _lockService.clearBackgroundTime();
          },
        ),
      );
    }

    // Show main app
    return CupertinoApp(
      title: 'Alongside',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cupertinoTheme,
      routes: {
        '/': (context) => const HomeScreenNew(),
        '/notification': (context) => const NotificationRouterScreen(),
        '/call': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          final friend = args['friend'] as Friend;
          return CallScreen(friend: friend);
        },
      },
    );
  }
}

// Notification router screen
class NotificationRouterScreen extends StatefulWidget {
  const NotificationRouterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationRouterScreen> createState() => _NotificationRouterScreenState();
}

class _NotificationRouterScreenState extends State<NotificationRouterScreen> {
  @override
  void initState() {
    super.initState();
    _processNotification();
  }

  Future<void> _processNotification() async {
    print("🔔 Processing notification...");

    final prefs = await SharedPreferences.getInstance();
    final pendingAction = prefs.getString('pending_notification_action');

    if (pendingAction != null) {
      await prefs.remove('pending_notification_action');
      final parts = pendingAction.split('|');

      if (parts.length == 2 && mounted) {
        final friendId = parts[0];
        final action = parts[1];

        final provider = Provider.of<FriendsProvider>(context, listen: false);
        final friend = provider.getFriendById(friendId);

        if (friend != null) {
          // CRITICAL FIX: Record interaction time using notification service
          final notificationService = NotificationService();
          await notificationService.recordFriendInteraction(friendId);

          print("✅ Recorded notification interaction for ${friend.name}");

          if (mounted) {
            if (action == 'message') {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (context) => MessageScreenNew(friend: friend),
                ),
              );
              return;
            } else if (action == 'call') {
              Navigator.pushReplacementNamed(
                context,
                '/call',
                arguments: {'friend': friend},
              );
              return;
            }
          }
        }
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}