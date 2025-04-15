// services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';

class StorageService {
  static const String _friendsKey = 'friends';
  static const String _messagesKey = 'custom_messages';

  // Save friends list
  Future<void> saveFriends(List<Friend> friends) async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = friends.map((friend) => jsonEncode(friend.toJson())).toList();
    await prefs.setStringList(_friendsKey, friendsJson);
  }

  // Get friends list
  Future<List<Friend>> getFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = prefs.getStringList(_friendsKey) ?? [];
    return friendsJson
        .map((json) => Friend.fromJson(jsonDecode(json)))
        .toList();
  }

  // Save custom messages
  Future<void> saveCustomMessages(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_messagesKey, messages);
  }

  // Get custom messages
  Future<List<String>> getCustomMessages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_messagesKey) ?? [];
  }

  // Add a custom message
  Future<void> addCustomMessage(String message) async {
    final messages = await getCustomMessages();
    if (!messages.contains(message)) {
      messages.add(message);
      await saveCustomMessages(messages);
    }
  }

  // Delete a custom message
  Future<void> deleteCustomMessage(String message) async {
    final messages = await getCustomMessages();
    messages.remove(message);
    await saveCustomMessages(messages);
  }
}