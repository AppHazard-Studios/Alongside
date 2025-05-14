// main.dart - Refactored with consistent styling

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'utils/text_styles.dart';
import 'utils/ui_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/foreground_service.dart';
import 'screens/call_screen.dart';
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
  // ignore: unused_field
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

  // Show the message options dialog with variable height messages
  Future<void> _showFullMessageOptionsDialog(BuildContext context, Friend friend) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();
    final allMessages = [...AppConstants.presetMessages, ...customMessages];

    // Get screen width for fixed message width
    final screenWidth = MediaQuery.of(context).size.width;
    // ignore: unused_local_variable
    final messageWidth = screenWidth - 32; // Fixed width for all messages

    // Wrap the showModalBottomSheet in a Completer to make it return a Future
    final completer = Completer<void>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle at the top
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with title and settings icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Empty space for balance (or back button if needed)
                    const SizedBox(width: 28),
                    // Centered title
                    Expanded(
                      child: Center(
                        child: Text(
                          'Message ${friend.name}',
                          style: AppTextStyles.navTitle,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Settings icon in iOS style
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // First close the modal bottom sheet
                        Navigator.pop(context);

                        // Add a slight delay to avoid navigation issues
                        Future.delayed(const Duration(milliseconds: 100), () {
                          // Then navigate to manage messages screen
                          navigatorKey.currentState?.push(
                            MaterialPageRoute(
                              builder: (context) => const ManageMessagesScreen(),
                            ),
                          );
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.gear,
                            color: Color(0xFF007AFF),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // iOS-style separator
              Container(
                height: 0.5,
                color: CupertinoColors.separator,
              ),

              // Message list with fixed width messages
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    itemCount: allMessages.length + 1,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      if (index == allMessages.length) {
                        // Create custom message option with fixed width
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showCustomMessageDialog(context, friend);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        CupertinoIcons.add_circled,
                                        size: 18,
                                        color: Color(0xFF007AFF),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Create custom message',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF007AFF),
                                          fontFamily: '.SF Pro Text',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Regular message option with fixed width
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5E5EA),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _sendMessage(context, friend, allMessages[index]);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Text(
                                  allMessages[index],
                                  style: AppTextStyles.bodyText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).then((_) {
      completer.complete();
    });

    return completer.future;
  }

  void _showCustomMessageDialog(BuildContext context, Friend friend) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Create Message',
          style: AppTextStyles.dialogTitle,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Type your message...',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CupertinoColors.systemGrey4,
                width: 0.5,
              ),
            ),
            style: AppTextStyles.inputText,
            placeholderStyle: AppTextStyles.placeholder,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                final storageService = Provider.of<FriendsProvider>(
                  context,
                  listen: false,
                ).storageService;

                await storageService.addCustomMessage(textController.text);
                Navigator.pop(context);

                UIConstants.showToast(context, 'Message saved');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Error', style: AppTextStyles.dialogTitle),
            content: Text(
              'Unable to open messaging app. Please try again later.',
              style: AppTextStyles.dialogContent,
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We'll use MaterialApp for compatibility but with Cupertino styling
    return MaterialApp(
      title: 'Alongside',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use primary color from our iOS styling
        primaryColor: const Color(AppConstants.primaryColorValue),
        primarySwatch: createMaterialColor(const Color(AppConstants.primaryColorValue)),
        // Platform.iOS ensures we get iOS-style scroll behaviors, etc.
        platform: TargetPlatform.iOS,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        // Disable Material ink splashes to maintain iOS feel
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        // Use System Font (.SF Pro Text) as default for everything
        fontFamily: '.SF Pro Text',
        // Cupertino-like text themes
        textTheme: TextTheme(
          headlineMedium: AppTextStyles.title,
          titleLarge: AppTextStyles.sectionTitle,
          bodyLarge: AppTextStyles.bodyText,
          labelLarge: AppTextStyles.button,
        ),
        // Use lighter app bar styling
        appBarTheme: AppBarTheme(
          backgroundColor: CupertinoColors.systemBackground,
          foregroundColor: CupertinoColors.label,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Color(AppConstants.primaryColorValue),
            size: 22,
          ),
          titleTextStyle: AppTextStyles.navTitle,
          toolbarHeight: 44, // iOS navigation bar height
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

  // Helper function to create MaterialColor from a single color
  MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    final int r = color.red, g = color.green, b = color.blue;

    return MaterialColor(color.value, {
      for (final strength in strengths)
        (strength * 1000).round(): Color.fromRGBO(
          r,
          g,
          b,
          strength,
        ),
      50: Color.fromRGBO(r, g, b, .05),
      100: Color.fromRGBO(r, g, b, .1),
      200: Color.fromRGBO(r, g, b, .2),
      300: Color.fromRGBO(r, g, b, .3),
      400: Color.fromRGBO(r, g, b, .4),
      500: Color.fromRGBO(r, g, b, .5),
      600: Color.fromRGBO(r, g, b, .6),
      700: Color.fromRGBO(r, g, b, .7),
      800: Color.fromRGBO(r, g, b, .8),
      900: Color.fromRGBO(r, g, b, .9),
    });
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