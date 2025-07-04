// lib/providers/friends_provider.dart
import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // REMOVED: The automatic notification scheduling on load
    // This was causing duplicate notifications every time the provider loaded
    // Notifications should only be scheduled when:
    // 1. A friend is first added
    // 2. A friend's reminder settings are updated
    // 3. The foreground service checks and reschedules as needed
  }

  Future<void> reorderFriends(List<Friend> reorderedFriends) async {
    _friends = reorderedFriends;
    await storageService.saveFriends(_friends);
    notifyListeners();
  }

// In friends_provider.dart - Update the addFriend method
  Future<void> addFriend(Friend friend) async {
    friends.add(friend);
    notifyListeners();

    await storageService.saveFriends(friends);

    // PHASE 2 ADDITION: Mark friend as just created for immediate reminders
    if (friend.reminderDays > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('just_created_${friend.id}', true);
    }

    // Schedule notification if needed
    if (friend.reminderDays > 0) {
      await notificationService.scheduleReminder(friend);
    }

    // Handle persistent notification
    if (friend.hasPersistentNotification) {
      await notificationService.showPersistentNotification(friend);
    }
  }

  // Add this method to FriendsProvider class
  Future<void> reloadFriends() async {
    _friends = [];
    notifyListeners();
    await _loadFriends();
  }

  Future<void> updateFriend(Friend updatedFriend) async {
    final index = _friends.indexWhere((f) => f.id == updatedFriend.id);
    if (index != -1) {
      final oldFriend = _friends[index];
      _friends[index] = updatedFriend;
      await storageService.saveFriends(_friends);

      // Only handle notification changes if settings actually changed

      // Handle reminder changes
      if (oldFriend.reminderDays != updatedFriend.reminderDays ||
          oldFriend.reminderTime != updatedFriend.reminderTime) {
        // Cancel old reminder first
        await notificationService.cancelReminder(updatedFriend.id);

        // Schedule new reminder if enabled
        if (updatedFriend.reminderDays > 0) {
          await notificationService.scheduleReminder(updatedFriend);
        }
      }

      // Handle persistent notification changes
      if (oldFriend.hasPersistentNotification !=
          updatedFriend.hasPersistentNotification) {
        if (updatedFriend.hasPersistentNotification) {
          await notificationService.showPersistentNotification(updatedFriend);
        } else {
          await notificationService
              .removePersistentNotification(updatedFriend.id);
        }
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
