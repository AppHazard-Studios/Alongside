// lib/providers/friends_provider.dart - FIXED FOR NEW REMINDER SYSTEM
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
  }

  Future<void> reorderFriends(List<Friend> reorderedFriends) async {
    _friends = reorderedFriends;
    await storageService.saveFriends(_friends);
    notifyListeners();
  }

  Future<void> addFriend(Friend friend) async {
    friends.add(friend);
    notifyListeners();

    await storageService.saveFriends(friends);

    // FIXED: Use the friend's hasReminder property instead of reminderDays
    if (friend.hasReminder) {
      print("📅 Setting up reminders for new friend: ${friend.name}");
      print("   - Uses advanced reminders: ${friend.usesAdvancedReminders}");
      print("   - Reminder days: ${friend.reminderDays}");
      print("   - Reminder data: ${friend.reminderData}");

      // Mark as new friend (no previous interactions)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_action_${friend.id}'); // Ensure clean slate

      final success = await notificationService.scheduleReminder(friend);
      if (success) {
        print("✅ Successfully scheduled reminder for ${friend.name}");
      } else {
        print("❌ Failed to schedule reminder for ${friend.name}");
      }
    } else {
      print("🔕 No reminders set for ${friend.name}");
    }

    // Handle persistent notification
    if (friend.hasPersistentNotification) {
      await notificationService.showPersistentNotification(friend);
    }
  }

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

      // FIXED: Check for reminder changes using hasReminder property
      final reminderChanged = oldFriend.hasReminder != updatedFriend.hasReminder ||
          oldFriend.reminderTime != updatedFriend.reminderTime ||
          oldFriend.reminderData != updatedFriend.reminderData ||
          oldFriend.reminderDays != updatedFriend.reminderDays;

      if (reminderChanged) {
        print("🔄 Reminder settings changed for ${updatedFriend.name}");
        print("   - Old has reminder: ${oldFriend.hasReminder}");
        print("   - New has reminder: ${updatedFriend.hasReminder}");
        print("   - Uses advanced reminders: ${updatedFriend.usesAdvancedReminders}");

        // Always cancel old reminders first
        await notificationService.cancelReminder(updatedFriend.id);

        // Schedule new reminders if enabled
        if (updatedFriend.hasReminder) {
          final success = await notificationService.scheduleReminder(updatedFriend);
          if (success) {
            print("✅ Successfully updated reminder for ${updatedFriend.name}");
          } else {
            print("❌ Failed to update reminder for ${updatedFriend.name}");
          }
        } else {
          print("🔕 Reminders disabled for ${updatedFriend.name}");
        }
      }

      // Handle persistent notification changes
      if (oldFriend.hasPersistentNotification != updatedFriend.hasPersistentNotification) {
        if (updatedFriend.hasPersistentNotification) {
          await notificationService.showPersistentNotification(updatedFriend);
        } else {
          await notificationService.removePersistentNotification(updatedFriend.id);
        }
      }

      notifyListeners();
    }
  }

  Future<void> removeFriend(String id) async {
    _friends.removeWhere((friend) => friend.id == id);
    await storageService.saveFriends(_friends);

    // Cancel all notifications for this friend
    await notificationService.cancelReminder(id);
    await notificationService.removePersistentNotification(id);

    notifyListeners();
  }
}