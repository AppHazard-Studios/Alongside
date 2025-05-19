// lib/main.dart - Streamlined version
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
import 'providers/friends_provider.dart';
import 'utils/text_styles.dart';
import 'utils/ui_constants.dart';
import 'utils/colors.dart';
import 'theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/foreground_service.dart';
import 'screens/call_screen.dart';
import 'screens/message_screen.dart';

// Global key for navigation from notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
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
void _handleNotificationAction(String friendId, String action) {
  // Always return to home first to ensure clean navigation
  navigatorKey.currentState?.popUntil((route) => route.isFirst);

  // Then navigate to the appropriate screen
  Future.delayed(const Duration(milliseconds: 100), () {
    navigatorKey.currentState?.pushNamed(
      '/notification',
      arguments: {'id': friendId, 'action': action},
    );
  });
}

class AlongsideApp extends StatefulWidget {
  const AlongsideApp({Key? key}) : super(key: key);

  @override
  State<AlongsideApp> createState() => _AlongsideAppState();
}

class _AlongsideAppState extends State<AlongsideApp> with WidgetsBindingObserver {
  // Tracking for deduplicating actions
  static Map<String, int> processedActions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    if (state == AppLifecycleState.resumed) {
      // Restart the foreground service when app is resumed
      ForegroundServiceManager.startForegroundService();

      // Restore persistent notifications
      Future.delayed(const Duration(milliseconds: 500), () {
        final provider = Provider.of<FriendsProvider>(context, listen: false);
        for (final friend in provider.friends) {
          if (friend.hasPersistentNotification) {
            provider.notificationService.showPersistentNotification(friend);
          }
        }
      });
    }
  }

  Future<void> _initializeApp() async {
    // Initialize and start foreground service
    await ForegroundServiceManager.initForegroundService();
    Future.delayed(const Duration(seconds: 3), () {
      ForegroundServiceManager.startForegroundService();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use CupertinoApp for pure iOS feel
    return CupertinoApp(
      title: 'Alongside',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cupertinoTheme,
      routes: {
        '/': (context) => const WithForegroundTask(child: HomeScreenNew()),
        '/notification': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, String>;
          final friendId = args['id']!;
          final action = args['action']!;

          // Create a unique ID for this action
          final actionId = '$friendId-$action';
          final now = DateTime.now().millisecondsSinceEpoch;

          // Check if we've processed this action recently (dedupe protection)
          if (processedActions.containsKey(actionId)) {
            final lastProcessed = processedActions[actionId]!;
            if (now - lastProcessed < 5000) {
              return const HomeScreenNew(); // Skip if duplicate
            }
          }

          // Record this action as processed
          processedActions[actionId] = now;

          // Clean up old entries (older than 10 seconds)
          processedActions.removeWhere((key, value) => now - value > 10000);

          // Process the action
          final provider = Provider.of<FriendsProvider>(ctx, listen: false);
          final friend = provider.getFriendById(friendId);

          if (friend != null) {
            // Cancel any existing notifications
            provider.notificationService.cancelReminder(friendId);

            // Handle message action
            if (action == 'message') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.push(
                  ctx,
                  CupertinoPageRoute(
                    builder: (context) => MessageScreenNew(friend: friend),
                  ),
                );
              });
            }
            // Handle call action
            else if (action == 'call') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(ctx).pushNamed(
                  '/call',
                  arguments: {'friend': friend},
                );
              });
            }
          }

          return const HomeScreenNew();
        },
        '/call': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          final friend = args['friend'] as Friend;
          return CallScreen(friend: friend);
        },
      },
    );
  }
}