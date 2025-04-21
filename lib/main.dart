// main.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'screens/add_friend_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/foreground_service.dart';
import 'widgets/friend_card.dart';
import 'screens/call_screen.dart';

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

  // Updated to return a Future
  Future<void> _showFullMessageOptionsDialog(BuildContext context, Friend friend) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();
    final allMessages = [...AppConstants.presetMessages, ...customMessages];

    // Wrap the showModalBottomSheet in a Completer to make it return a Future
    final completer = Completer<void>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(AppConstants.backgroundColorValue),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle at the top
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 0),
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.bottomSheetHandleColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Header with title and settings icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Empty spacer to balance the title
                      const SizedBox(width: 48),
                      // Centered title
                      Text(
                        'Message ${friend.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppConstants.primaryTextColor,
                        ),
                      ),
                      // Settings icon
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageMessagesScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings, color: AppConstants.primaryColor, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),

                // Message list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    itemCount: allMessages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == allMessages.length) {
                        // Create custom message option
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () => _showCustomMessageDialog(context, friend),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: AppConstants.primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Create custom message',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Regular message option
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Card(
                          elevation: 1,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _sendMessage(context, friend, allMessages[index]);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              child: Text(
                                allMessages[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppConstants.primaryTextColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
              ],
            );
          },
        );
      },
    ).then((_) {
      completer.complete();
    });

    return completer.future;
  }

  void _showCustomMessageDialog(BuildContext context, Friend friend) {
    final textController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Create Message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: dialogWidth,
            child: TextFormField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Type your message...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelStyle: TextStyle(
                  fontSize: 15,
                  color: AppConstants.secondaryTextColor,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(
                fontSize: 15,
                color: AppConstants.primaryTextColor,
                height: 1.4,
              ),
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
            ),
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  final storageService = Provider.of<FriendsProvider>(
                    context,
                    listen: false,
                  ).storageService;

                  await storageService.addCustomMessage(textController.text);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Message saved',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, Friend friend, String message) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      bool launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final telUri = Uri.parse('tel:$phoneNumber');
        await launchUrl(
          telUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to open messaging app. Try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alongside',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(AppConstants.primaryColorValue),
        scaffoldBackgroundColor: const Color(AppConstants.backgroundColorValue),
        cardColor: const Color(AppConstants.cardColorValue),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColorValue),
          primary: const Color(AppConstants.primaryColorValue),
          secondary: const Color(AppConstants.secondaryColorValue),
          tertiary: const Color(AppConstants.accentColorValue),
          background: const Color(AppConstants.backgroundColorValue),
          surface: const Color(AppConstants.cardColorValue),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: const Color(AppConstants.primaryTextColorValue),
          onSurface: const Color(AppConstants.primaryTextColorValue),
          brightness: Brightness.light,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.primaryTextColorValue),
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(AppConstants.primaryTextColorValue),
            letterSpacing: -0.25,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            color: Color(AppConstants.primaryTextColorValue),
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(AppConstants.primaryColorValue),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(AppConstants.primaryTextColorValue),
          centerTitle: false,
          elevation: 0,
          iconTheme: IconThemeData(
              color: Color(AppConstants.primaryColorValue),
              size: 24
          ),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.primaryTextColorValue),
            letterSpacing: -0.25,
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(AppConstants.cardColorValue),
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.05),
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(AppConstants.borderColorValue),
              width: 1,
            ),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(AppConstants.cardColorValue),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.15),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(AppConstants.primaryTextColorValue),
            letterSpacing: -0.2,
          ),
          contentTextStyle: const TextStyle(
            fontSize: 15,
            color: Color(AppConstants.primaryTextColorValue),
            height: 1.5,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          modalBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          minLeadingWidth: 20,
          minVerticalPadding: 6,
          iconColor: Color(AppConstants.primaryColorValue),
          titleTextStyle: TextStyle(
            fontSize: 15,
            color: Color(AppConstants.primaryTextColorValue),
          ),
          subtitleTextStyle: TextStyle(
            fontSize: 13,
            color: Color(AppConstants.secondaryTextColorValue),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(AppConstants.borderColorValue),
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(AppConstants.borderColorValue),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(AppConstants.primaryColorValue),
              width: 1.5,
            ),
          ),
          labelStyle: TextStyle(
              fontSize: 15,
              color: const Color(AppConstants.secondaryTextColorValue)),
          hintStyle: TextStyle(
              fontSize: 14,
              color: const Color(AppConstants.secondaryTextColorValue)
                  .withOpacity(0.7)),
        ),
      ),
      // Define routes, including the updated notification handler
      routes: {
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
              return const HomeScreen();
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

            // For messages, use the original slide-up UI
            if (action == 'message') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!isShowingDialog) {
                  isShowingDialog = true;
                  _showFullMessageOptionsDialog(ctx, friend).then((_) {
                    isShowingDialog = false;
                    Navigator.of(ctx).pop();
                  });
                }
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

          return const HomeScreen();
        },
        '/call': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          final friend = args['friend'] as Friend;
          return CallScreen(friend: friend);
        },
      },
      home: WithForegroundTask(
        child: const HomeScreen(),
      ),
    );
  }
}

// Your existing FriendsProvider class (unchanged)
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