// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'models/friend.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'screens/add_friend_screen.dart';
// For launching URLs
import 'package:url_launcher/url_launcher.dart';

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

class _AlongsideAppState extends State<AlongsideApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Set up notification action handlers
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    provider.notificationService.setActionCallback(_handleNotificationAction);
  }

  // Handle notification actions
  // For default (persistent notification tap), navigate home.
  // For action buttons, navigate home then perform the action.
  void _handleNotificationAction(String friendId, String action) async {
    if (action == 'home') {
      // Navigate to home screen
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }

    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final friend = provider.getFriendById(friendId);
    if (friend == null) return;

    // Ensure we are at home first.
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);

    if (action == 'message') {
      _showMessageOptionsForFriend(friend);
    } else if (action == 'call') {
      _callFriend(friend);
    } else {
      // Fallback—log unhandled action.
    }
  }

  // Helper method: Show a bottom sheet for message options.
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
                leading: const Icon(Icons.message),
                title: const Text('Send Default Message'),
                onTap: () {
                  Navigator.pop(context);
                  _messageFriend(friend);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Customize Message'),
                onTap: () {
                  Navigator.pop(context);
                  // For simplicity, using default SMS; you could navigate to a full message editor.
                  _messageFriend(friend);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Send an SMS message to the friend.
  void _messageFriend(Friend friend) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri = Uri.parse('sms:$phoneNumber');
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Error handling for messaging
    }
  }

  // Directly call the friend.
  void _callFriend(Friend friend) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Error handling for call
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alongside',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
          elevation: 6,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.primaryTextColorValue),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(AppConstants.primaryTextColorValue),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(AppConstants.primaryTextColorValue),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(AppConstants.primaryColorValue),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(AppConstants.backgroundColorValue),
          foregroundColor: Color(AppConstants.primaryTextColorValue),
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Color(AppConstants.primaryTextColorValue),
          ),
          titleSpacing: 20,
        ),
        cardTheme: CardTheme(
          color: const Color(AppConstants.cardColorValue),
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: const DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          modalElevation: 8,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// Provider for managing friends state
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