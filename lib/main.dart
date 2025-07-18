// lib/main.dart - FIXED LOCK SCREEN FLOW AND NOTIFICATION ROUTING
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

// FIXED: Global notification handler that respects lock screen flow
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

  // Store the intended action for after lock screen (if needed)
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('pending_notification_action', '$friendId|$action');

  print("💾 Stored pending action: $friendId|$action");

  // Navigate to notification router (which will handle lock screen flow)
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

    // FIXED: Start with proper initial states
    _lockChecked = false;
    _isLocked = false;

    // CRITICAL: Check lock immediately on start
    _checkLockOnStart();
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
        _checkNotificationSchedules();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // FIXED: Immediate lock check on app start
  Future<void> _checkLockOnStart() async {
    try {
      print("🔒 Checking lock on app start...");

      final shouldLock = await _lockService.shouldShowLockScreen();

      if (mounted) {
        setState(() {
          _isLocked = shouldLock;
          _lockChecked = true;
        });

        if (shouldLock) {
          print("🔒 Lock screen required on start");
        } else {
          print("🔓 No lock required on start - initializing app");
          await _lockService.clearBackgroundTime();
          _initializeAppFeatures();
        }
      }
    } catch (e) {
      print("❌ Error checking lock on start: $e");
      if (mounted) {
        setState(() {
          _isLocked = false;
          _lockChecked = true;
        });
        _initializeAppFeatures();
      }
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

  // FIXED: Separate app feature initialization
  Future<void> _initializeAppFeatures() async {
    print("🚀 Initializing app features...");

    try {
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
    } catch (e) {
      print("❌ Error initializing app features: $e");
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
    // FIXED: Show loading only while checking lock status
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

    // FIXED: Show lock screen immediately if locked
    if (_isLocked) {
      return CupertinoApp(
        title: 'Alongside',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.cupertinoTheme,
        home: LockScreen(
          onUnlocked: () async {
            setState(() {
              _isLocked = false;
            });
            await _lockService.clearBackgroundTime();

            // FIXED: Initialize app features only after unlock
            if (!_scheduleCheckTimer!.isActive ?? true) {
              _initializeAppFeatures();
            }
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

// FIXED: Notification router screen with proper lock screen integration
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
    print("🔔 Processing notification in router...");

    try {
      // FIXED: Check if lock screen should be shown first
      final lockService = LockService();
      final shouldShowLock = await lockService.shouldShowLockScreen();

      if (shouldShowLock) {
        print("🔒 Lock required - showing lock screen first");

        if (mounted) {
          // Show lock screen and wait for unlock
          final unlocked = await Navigator.push<bool>(
            context,
            CupertinoPageRoute(
              builder: (context) => LockScreen(
                onUnlocked: () {
                  Navigator.pop(context, true);
                },
              ),
            ),
          );

          if (unlocked != true) {
            // User didn't unlock - go to home
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
            return;
          }

          // Clear background time after successful unlock
          await lockService.clearBackgroundTime();
        }
      }

      // Process the pending notification action
      final prefs = await SharedPreferences.getInstance();
      final pendingAction = prefs.getString('pending_notification_action');

      if (pendingAction != null && mounted) {
        await prefs.remove('pending_notification_action');
        final parts = pendingAction.split('|');

        if (parts.length == 2) {
          final friendId = parts[0];
          final action = parts[1];

          print("🔔 Processing action: $action for friend: $friendId");

          final provider = Provider.of<FriendsProvider>(context, listen: false);
          final friend = provider.getFriendById(friendId);

          if (friend != null) {
            // CRITICAL: Record interaction time using notification service
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
          } else {
            print("❌ Friend not found for ID: $friendId");
          }
        } else {
          print("❌ Invalid pending action format: $pendingAction");
        }
      } else {
        print("🔔 No pending notification action found");
      }

      // Default: go to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }

    } catch (e) {
      print("❌ Error processing notification: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: 16),
            Text(
              'Opening...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }
}