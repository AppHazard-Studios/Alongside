// lib/main.dart - Fixed version with proper imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
import 'providers/friends_provider.dart'; // Import FriendsProvider from separate file
import 'utils/constants.dart';
import 'utils/text_styles.dart';
import 'utils/ui_constants.dart';
import 'utils/colors.dart';
import 'theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/foreground_service.dart';
import 'screens/call_screen.dart';
import 'screens/message_screen.dart';
import 'screens/manage_messages_screen.dart';

// Global key for navigation from notification callbacks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Cold-start & background callback: navigate via named route
  notificationService.setActionCallback((friendId, action) {
    // Always return to home first
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    // Then deep-link into /notification with arguments
    Future.delayed(const Duration(milliseconds: 100), () {
      navigatorKey.currentState?.pushNamed(
        '/notification',
        arguments: {'id': friendId, 'action': action},
      );
    });
  });

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

class AlongsideApp extends StatefulWidget {
  const AlongsideApp({Key? key}) : super(key: key);

  @override
  State<AlongsideApp> createState() => _AlongsideAppState();
}

class _AlongsideAppState extends State<AlongsideApp> with WidgetsBindingObserver {
  // Static flag to prevent multiple dialog displays
  bool _skipNextPersistentRepost = false;
  static bool isShowingDialog = false;
  static Map<String, int> processedActions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // After first frame, also register the in-app callback
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
      // keep the foreground service alive
      ForegroundServiceManager.startForegroundService();

      // restore the persistent notification if needed
      Future.delayed(const Duration(milliseconds: 500), () {
        final provider = Provider.of<FriendsProvider>(context, listen: false);
        for (final f in provider.friends) {
          if (f.hasPersistentNotification) {
            provider.notificationService.showPersistentNotification(f);
          }
        }
      });
    }
  }

  Future<void> _initializeApp() async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);

    // In-app callback (when already running)
    provider.notificationService.setActionCallback(_handleNotificationAction);

    await ForegroundServiceManager.initForegroundService();
    Future.delayed(const Duration(seconds: 3), () {
      ForegroundServiceManager.startForegroundService();
    });
  }

  void _handleNotificationAction(String friendId, String action) {
    // Mirror cold-start: navigate via /notification
    if (action == 'message') {
      _skipNextPersistentRepost = true;
    }
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    Future.delayed(const Duration(milliseconds: 100), () {
      navigatorKey.currentState?.pushNamed(
        '/notification',
        arguments: {'id': friendId, 'action': action},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use CupertinoApp instead of MaterialApp for pure iOS feel
    return CupertinoApp(
      title: 'Alongside',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.cupertinoTheme, // Use our custom Cupertino theme
      // Define routes, including the updated notification handler
      routes: {
        '/': (context) => const WithForegroundTask(child: HomeScreenNew()),
        '/notification': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, String>;
          final friendId = args['id']!;
          final action = args['action']!;

          // Create a unique action ID that combines friendId and action
          final actionId = '$friendId-$action';

          // Get current timestamp to track when this action was processed
          final now = DateTime.now().millisecondsSinceEpoch;

          // Check if we've processed this exact action recently (within 5 seconds)
          if (processedActions.containsKey(actionId)) {
            final lastProcessed = processedActions[actionId]!;
            if (now - lastProcessed < 5000) {
              // If same action was processed within last 5 seconds, ignore it
              print('Ignoring duplicate action: $actionId');
              return const HomeScreenNew();
            }
          }

          // Record that we've processed this action
          processedActions[actionId] = now;

          // Cleanup old entries in processedActions map (older than 10 seconds)
          processedActions.removeWhere((key, value) => now - value > 10000);

          final provider = Provider.of<FriendsProvider>(ctx, listen: false);
          final friend = provider.getFriendById(friendId);

          // Ensure we have a valid friend
          if (friend != null) {
            // Immediately cancel all notifications for this friend to prevent duplicates
            provider.notificationService.cancelReminder(friendId);

            // For messages, navigate to the dedicated message screen
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
            // For calls, use the dedicated screen approach
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