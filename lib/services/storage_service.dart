// services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import '../utils/constants.dart';

class StorageService {
  static const String _friendsKey = 'friends';
  static const String _messagesKey = 'custom_messages';
  static const String _messageCountKey = 'messages_sent_count';
  static const String _callCountKey = 'calls_made_count';

  // Save friends list
  Future<void> saveFriends(List<Friend> friends) async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson =
    friends.map((friend) => jsonEncode(friend.toJson())).toList();
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

  // Get categorized default messages
  Map<String, List<String>> getCategorizedMessages() {
    return AppConstants.categorizedMessages;
  }

  // Get default messages as flat list (for backward compatibility)
  List<String> getDefaultMessages() {
    return AppConstants.presetMessages;
  }

  // Message count tracking
  Future<int> getMessagesSentCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_messageCountKey) ?? 0;
  }

  Future<void> incrementMessagesSent() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getMessagesSentCount();
    await prefs.setInt(_messageCountKey, current + 1);
  }

  // Call count tracking
  Future<int> getCallsMadeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_callCountKey) ?? 0;
  }

  Future<void> incrementCallsMade() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCallsMadeCount();
    await prefs.setInt(_callCountKey, current + 1);
  }
}