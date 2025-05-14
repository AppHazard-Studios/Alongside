// lib/main.dart - Fixed for localization
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
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
    // Use MaterialApp with Cupertino styling for better localization support
    return MaterialApp(
      title: 'Alongside',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Add localization support
      localizationsDelegates: const [
        //GlobalMaterialLocalizations.delegate,
        //GlobalWidgetsLocalizations.delegate,
        //GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
      ],
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

// FriendsProvider class
class FriendsProvider with ChangeNotifier {
  final StorageService storageService;
  final NotificationService notificationService;
  List<Friend> _friends = [];
  bool _isLoading = true;

  FriendsProvider({
    required this.storageService,
    required this.notificationService,
  }) {
    _loadFriends();
  }

  List<Friend> get friends => _friends;
  bool get isLoading => _isLoading;

  Friend? getFriendById(String id) {
    try {
      return _friends.firstWhere((friend) => friend.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadFriends() async {
    _isLoading = true;
    notifyListeners();

    _friends = await storageService.getFriends();

    _isLoading = false;
    notifyListeners();

    // Ensure all notifications are scheduled correctly
    for (final friend in _friends) {
      if (friend.reminderDays > 0) {
        await notificationService.scheduleReminder(friend);
      }
      if (friend.hasPersistentNotification) {
        await notificationService.showPersistentNotification(friend);
      }
    }
  }

  Future<void> reorderFriends(List<Friend> reorderedFriends) async {
    _friends = reorderedFriends;
    await storageService.saveFriends(_friends);
    notifyListeners();
  }

  Future<void> addFriend(Friend friend) async {
    _friends.add(friend);
    await storageService.saveFriends(_friends);

    if (friend.reminderDays > 0) {
      await notificationService.scheduleReminder(friend);
    }
    if (friend.hasPersistentNotification) {
      await notificationService.showPersistentNotification(friend);
    }

    notifyListeners();
  }

  Future<void> updateFriend(Friend updatedFriend) async {
    final index = _friends.indexWhere((f) => f.id == updatedFriend.id);
    if (index != -1) {
      _friends[index] = updatedFriend;
      await storageService.saveFriends(_friends);

      if (updatedFriend.reminderDays > 0) {
        await notificationService.scheduleReminder(updatedFriend);
      } else {
        await notificationService.cancelReminder(updatedFriend.id);
      }

      if (updatedFriend.hasPersistentNotification) {
        await notificationService.showPersistentNotification(updatedFriend);
      } else {
        await notificationService.removePersistentNotification(updatedFriend.id);
      }

      notifyListeners();
    }
  }

  Future<void> removeFriend(String id) async {
    _friends.removeWhere((friend) => friend.id == id);
    await storageService.saveFriends(_friends);

    await notificationService.cancelReminder(id);
    await notificationService.removePersistentNotification(id);

    notifyListeners();
  }
}