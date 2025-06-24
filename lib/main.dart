// lib/main.dart - Fixed with lock cooldown and better notification handling
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
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/foreground_service.dart';
import 'screens/call_screen.dart';
import 'screens/message_screen.dart';
import 'services/battery_optimization_service.dart';

// Global key for navigation from notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications with better error handling
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

// Global notification handler function
void _handleNotificationAction(String friendId, String action) async {
  print("🔔 Notification action received: Friend=$friendId, Action=$action");

  // Wait for navigator to be ready (max 5 seconds)
  int attempts = 0;
  while (navigatorKey.currentState == null && attempts < 50) {
    await Future.delayed(const Duration(milliseconds: 100));
    attempts++;
  }

  if (navigatorKey.currentState == null) {
    print("❌ Navigator not ready after 5 seconds");
    return;
  }

  // Store the action to process
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_notification_action', '$friendId|$action');

  // Navigate to home first
  navigatorKey.currentState!.popUntil((route) => route.isFirst);

  // Then navigate to notification handler
  navigatorKey.currentState!.pushNamed('/notification');
}

class AlongsideApp extends StatefulWidget {
  const AlongsideApp({Key? key}) : super(key: key);

  @override
  State<AlongsideApp> createState() => _AlongsideAppState();
}

class _AlongsideAppState extends State<AlongsideApp>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _lockChecked = false;
  final LockService _lockService = LockService();
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Don't check lock on initial app start
    _lockChecked = true;
    _isLocked = false;

    // Setup foreground service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      // App going to background
        print("📱 App paused - recording background time");
        _lockService.recordBackgroundTime();
        _pausedTime = DateTime.now();
        break;

      case AppLifecycleState.resumed:
      // App coming to foreground
        print("📱 App resumed - checking if lock needed");
        _checkIfShouldLock();

        // Restart foreground service if needed
        ForegroundServiceManager.startForegroundService();
        break;

      case AppLifecycleState.inactive:
      // Transitional state - do nothing
        break;

      case AppLifecycleState.detached:
      // App is being destroyed
        break;

      case AppLifecycleState.hidden:
      // App is hidden (newer Flutter versions)
        break;
    }
  }

  Future<void> _checkIfShouldLock() async {
    // Check if we should show lock based on cooldown
    final shouldLock = await _lockService.shouldShowLockScreen();

    if (shouldLock && mounted) {
      print("🔒 Showing lock screen after cooldown");
      setState(() {
        _isLocked = true;
      });
    } else {
      print("🔓 No lock needed - cooldown not met or lock disabled");
      // Clear any background time if we're not locking
      await _lockService.clearBackgroundTime();
    }
  }

  Future<void> _initializeApp() async {
    print("🚀 Initializing app services...");

    // Initialize and start foreground service
    await ForegroundServiceManager.initForegroundService();

    // Start service after a delay to ensure everything is ready
    Future.delayed(const Duration(seconds: 2), () {
      print("🔄 Starting foreground service...");
      ForegroundServiceManager.startForegroundService();
    });

    // Check battery optimization after a delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        print("🔋 Checking battery optimization...");
        BatteryOptimizationService.requestBatteryOptimization(context);
      }
    });

    // Debug scheduled notifications
    Future.delayed(const Duration(seconds: 3), () async {
      final notificationService = NotificationService();
      await notificationService.debugScheduledNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show lock screen if needed
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
            // Clear background time when unlocked
            _lockService.clearBackgroundTime();
          },
        ),
      );
    }

    // Main app
    return CupertinoApp(
      title: 'Alongside',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cupertinoTheme,
      routes: {
        '/': (context) => const WithForegroundTask(child: HomeScreenNew()),
        '/notification': (context) => const NotificationRouterScreen(),
        '/call': (ctx) {
          final args =
          ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          final friend = args['friend'] as Friend;
          return CallScreen(friend: friend);
        },
      },
    );
  }
}

// Screen to handle notification routing
class NotificationRouterScreen extends StatefulWidget {
  const NotificationRouterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationRouterScreen> createState() =>
      _NotificationRouterScreenState();
}

class _NotificationRouterScreenState extends State<NotificationRouterScreen> {
  @override
  void initState() {
    super.initState();
    _processNotification();
  }

  Future<void> _processNotification() async {
    print("🔔 Processing notification action...");

    final prefs = await SharedPreferences.getInstance();
    final pendingAction = prefs.getString('pending_notification_action');

    if (pendingAction != null) {
      await prefs.remove('pending_notification_action');
      final parts = pendingAction.split('|');

      if (parts.length == 2 && mounted) {
        final friendId = parts[0];
        final action = parts[1];

        print("🔔 Action details: Friend=$friendId, Action=$action");

        final provider = Provider.of<FriendsProvider>(context, listen: false);
        final friend = provider.getFriendById(friendId);

        if (friend != null) {
          // Update last action time
          await prefs.setInt(
              'last_action_$friendId', DateTime.now().millisecondsSinceEpoch);

          if (mounted) {
            if (action == 'message') {
              print("📱 Navigating to message screen");
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (context) => MessageScreenNew(friend: friend),
                ),
              );
              return;
            } else if (action == 'call') {
              print("📞 Navigating to call screen");
              Navigator.pushReplacementNamed(
                context,
                '/call',
                arguments: {'friend': friend},
              );
              return;
            }
          }
        } else {
          print("❌ Friend not found: $friendId");
        }
      }
    }

    // Default: go to home
    if (mounted) {
      print("🏠 Navigating to home screen");
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