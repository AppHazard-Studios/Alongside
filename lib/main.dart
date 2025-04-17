// main.dart
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize after render to avoid startup crashes
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
      // Ensure the service is running when the app comes to the foreground
      ForegroundServiceManager.startForegroundService();

      // Refresh notifications
      final provider = Provider.of<FriendsProvider>(context, listen: false);
      if (provider.friends.isNotEmpty) {
        for (final friend in provider.friends) {
          if (friend.hasPersistentNotification) {
            provider.notificationService.showPersistentNotification(friend);
          }
        }
      }
    }
  }

  Future<void> _initializeApp() async {
    // Set up notification action handlers
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    provider.notificationService.setActionCallback(_handleNotificationAction);

    // Initialize and start foreground service
    await ForegroundServiceManager.initForegroundService();

    // Start service with a slight delay to ensure the app is fully loaded
    Future.delayed(const Duration(seconds: 3), () async {
      await ForegroundServiceManager.startForegroundService();
    });
  }

  // Handle notification actions
  void _handleNotificationAction(String friendId, String action) async {
    if (action == 'home') {
      // Navigate to home screen
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }

    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final friend = provider.getFriendById(friendId);
    if (friend == null) return;

    // Ensure we are at home first
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);

    if (action == 'message') {
      _showMessageOptionsForFriend(friend);
    } else if (action == 'call') {
      _callFriend(friend);
    }
  }

  // Helper method: Show a bottom sheet for message options
  void _showMessageOptionsForFriend(Friend friend) {
    showModalBottomSheet(
      context: _navigatorKey.currentContext!,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.message, size: 22, color: AppConstants.primaryColor),
                title: Text(
                  'Send Default Message',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppConstants.primaryTextColor,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  Navigator.pop(context);
                  _messageFriend(friend);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, size: 22, color: AppConstants.primaryColor),
                title: Text(
                  'Customize Message',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppConstants.primaryTextColor,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  Navigator.pop(context);
                  _messageFriend(friend);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Send an SMS message to the friend
  void _messageFriend(Friend friend) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri = Uri.parse('sms:$phoneNumber');
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Error handling for messaging
      ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(
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

  // Directly call the friend
  void _callFriend(Friend friend) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Error handling for call
      ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open phone app. Try again later.',
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
    return WithForegroundTask(
      child: MaterialApp(
        title: 'Alongside',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Your existing theme configuration...
          primaryColor: const Color(AppConstants.primaryColorValue),
          scaffoldBackgroundColor: const Color(AppConstants.backgroundColorValue),
          cardColor: const Color(AppConstants.cardColorValue),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(AppConstants.primaryColorValue),
            primary: const Color(AppConstants.primaryColorValue),
            secondary: const Color(AppConstants.secondaryColorValue),
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
            extendedPadding: EdgeInsets.all(16),
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
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(AppConstants.primaryColorValue),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            iconTheme: IconThemeData(
              color: Colors.white,
              size: 22,
            ),
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.25,
            ),
            titleSpacing: 16,
          ),
          cardTheme: CardTheme(
            color: const Color(AppConstants.cardColorValue),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dialogTheme: DialogTheme(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            backgroundColor: const Color(AppConstants.cardColorValue),
            elevation: 24,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            backgroundColor: Color(AppConstants.cardColorValue),
            modalElevation: 10,
            clipBehavior: Clip.antiAlias,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: const Color(AppConstants.borderColorValue),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: const Color(AppConstants.borderColorValue),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: const Color(AppConstants.primaryColorValue),
                width: 1.5,
              ),
            ),
            labelStyle: TextStyle(
                fontSize: 15,
                color: const Color(AppConstants.secondaryTextColorValue)
            ),
            hintStyle: TextStyle(
                fontSize: 14,
                color: const Color(AppConstants.secondaryTextColorValue).withOpacity(0.7)
            ),
          ),
        ),
        home: const HomeScreen(),
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