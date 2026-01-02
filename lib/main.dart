// lib/main.dart - FIXED LOCK SCREEN FLOW AND NOTIFICATION ROUTING
import 'dart:async';
import 'package:alongside/screens/lock_screen.dart';
import 'package:alongside/services/lock_service.dart';
import 'package:alongside/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
import 'providers/friends_provider.dart';
import 'theme/app_theme.dart';
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
// FIXED: Global notification handler that respects lock screen flow and defaults to message
// BULLETPROOF: Global notification handler with comprehensive error handling
void _handleNotificationAction(String friendId, String action) async {
  try {
    print("🔔 Notification action: Friend=$friendId, Action=$action");

    // Validate inputs
    if (friendId.isEmpty) {
      print("❌ Empty friendId - cannot process notification");
      return;
    }

    // Sanitize action with whitelist
    String finalAction;
    if (action == 'call' || action == 'message') {
      finalAction = action;
    } else {
      print("🔄 Action '$action' not recognized, defaulting to 'message'");
      finalAction = 'message';
    }

    // Wait for navigator with timeout and retry logic
    int attempts = 0;
    const maxAttempts = 100; // 10 seconds max wait
    const delayMs = 100;

    while (navigatorKey.currentState == null && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: delayMs));
      attempts++;

      if (attempts % 20 == 0) {
        print("⏳ Still waiting for navigator... attempt $attempts");
      }
    }

    if (navigatorKey.currentState == null) {
      print("❌ Navigator not ready after ${maxAttempts * delayMs}ms - aborting notification action");
      return;
    }

    // Store pending action with error handling
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification_action', '$friendId|$finalAction');
      print("💾 Stored pending action: $friendId|$finalAction");
    } catch (e) {
      print("❌ Failed to store pending action: $e");
      // Continue anyway - we'll try to handle without stored action
    }

    // Navigate with error handling
    try {
      final navigator = navigatorKey.currentState!;

      // Safely pop to first route
      try {
        navigator.popUntil((route) => route.isFirst);
      } catch (e) {
        print("⚠️ Error popping routes: $e");
        // Continue to push notification route anyway
      }

      // Push notification route
      await navigator.pushNamed('/notification');
      print("✅ Navigated to notification router");

    } catch (e) {
      print("❌ Navigation failed: $e");

      // Fallback: try to at least get to home screen
      try {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
      } catch (fallbackError) {
        print("❌ Fallback navigation also failed: $fallbackError");
      }
    }

  } catch (e) {
    print("❌ Critical error in notification action handler: $e");
  }
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
        break;

      case AppLifecycleState.resumed:
        print("📱 App resumed");
        _checkIfShouldLock();
        _checkNotificationSchedules();
        _checkPersistentNotifications(); // NEW: Check persistent notifications
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

  Future<void> _checkPersistentNotifications() async {
    try {
      print("🔍 Checking persistent notifications...");
      final notificationService = NotificationService();
      final provider = Provider.of<FriendsProvider>(context, listen: false);

      await notificationService.checkAndRestorePersistentNotifications(provider.friends);
    } catch (e) {
      print("❌ Error checking persistent notifications: $e");
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
            if (!_scheduleCheckTimer!.isActive) {
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
      // Handle lock screen with timeout
      try {
        final lockService = LockService();
        final shouldShowLock = await lockService.shouldShowLockScreen().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print("⚠️ Lock check timeout - assuming no lock needed");
            return false;
          },
        );

        if (shouldShowLock && mounted) {
          print("🔒 Lock required - showing lock screen first");

          try {
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
              print("🔒 User cancelled unlock - going to home");
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
              return;
            }

            // Clear background time after successful unlock
            try {
              await lockService.clearBackgroundTime();
            } catch (e) {
              print("⚠️ Failed to clear background time: $e");
            }
          } catch (e) {
            print("❌ Lock screen error: $e - proceeding without lock");
          }
        }
      } catch (e) {
        print("❌ Lock service error: $e - proceeding without lock check");
      }

      // Process pending action with comprehensive error handling
      String? friendId;
      String? action;

      try {
        final prefs = await SharedPreferences.getInstance();
        final pendingAction = prefs.getString('pending_notification_action');

        if (pendingAction != null && pendingAction.isNotEmpty) {
          // Clean up immediately to prevent reprocessing
          try {
            await prefs.remove('pending_notification_action');
          } catch (e) {
            print("⚠️ Failed to remove pending action: $e");
          }

          final parts = pendingAction.split('|');
          if (parts.length >= 2 && parts[0].isNotEmpty) {
            friendId = parts[0].trim();
            action = parts[1].trim();

            // Validate action
            if (action != 'call' && action != 'message') {
              print("🔄 Invalid action '$action', defaulting to 'message'");
              action = 'message';
            }

            print("🔔 Processing action: $action for friend: $friendId");
          } else {
            print("❌ Invalid pending action format: $pendingAction");
          }
        } else {
          print("🔔 No pending notification action found");
        }
      } catch (e) {
        print("❌ Error reading pending action: $e");
      }

      // Handle the action if we have valid data
      if (friendId != null && action != null && mounted) {
        try {
          final provider = Provider.of<FriendsProvider>(context, listen: false);
          final friend = provider.getFriendById(friendId);

          if (friend != null) {
            // Record interaction with error handling
            try {
              final notificationService = NotificationService();
              await notificationService.recordFriendInteraction(friendId);
              print("✅ Recorded notification interaction for ${friend.name}");
            } catch (e) {
              print("⚠️ Failed to record interaction: $e");
            }

            if (mounted) {
              if (action == 'call') {
                // Handle call action
                try {
                  await _launchPhoneCall(friend);
                  print("📞 Phone call launched for ${friend.name}");
                } catch (e) {
                  print("❌ Failed to launch phone call: $e");
                }

                // Always go to home after call attempt
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
                return;

              } else {
                // Handle message action (default)
                try {
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => MessageScreenNew(friend: friend),
                    ),
                  );
                  return;
                } catch (e) {
                  print("❌ Failed to navigate to message screen: $e");
                }
              }
            }
          } else {
            print("❌ Friend not found for ID: $friendId");
          }
        } catch (e) {
          print("❌ Error processing friend action: $e");
        }
      }

      // Fallback: always try to get to a safe state
      if (mounted) {
        try {
          Navigator.pushReplacementNamed(context, '/');
        } catch (e) {
          print("❌ Final fallback navigation failed: $e");
          // Last resort: pop current route
          try {
            Navigator.of(context).pop();
          } catch (popError) {
            print("❌ Even pop failed: $popError");
          }
        }
      }

    } catch (e) {
      print("❌ Critical error processing notification: $e");

      // Emergency fallback
      if (mounted) {
        try {
          Navigator.pushReplacementNamed(context, '/');
        } catch (emergencyError) {
          print("❌ Emergency navigation failed: $emergencyError");
        }
      }
    }
  }

  // ADDED: Direct phone launch method
  Future<void> _launchPhoneCall(Friend friend) async {
    try {
      // Use ONLY the local phone number - NO country code
      final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final telUri = Uri.parse('tel:$phoneNumber');

      await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.incrementCallsMade();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_action_${friend.id}', DateTime.now().millisecondsSinceEpoch);

      final notificationService = NotificationService();
      await notificationService.scheduleReminder(friend);

      print("📞 Phone call launched for ${friend.name}");

    } catch (e) {
      print("❌ Error launching phone call: $e");
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