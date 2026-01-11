// lib/services/photo_migration_service.dart
// ONE-TIME MIGRATION - Safe to remove after v2.0 (2025-06)
import 'dart:io';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import '../services/storage_service.dart';

class PhotoMigrationService {
  static const String _migrationKey = 'has_run_photo_migration';

  // Main entry point - checks flag and runs migration if needed
  static Future<void> runPhotoMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRun = prefs.getBool(_migrationKey) ?? false;

      if (hasRun) {
        print('📸 Photo migration already completed, skipping');
        return;
      }

      print('📸 Running one-time photo migration...');
      await _performMigration();

      // Always set flag even if migration had errors
      await prefs.setBool(_migrationKey, true);
      print('✅ Photo migration complete');
    } catch (e) {
      print('❌ Photo migration error: $e');
      // Still set flag to prevent retry loop
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_migrationKey, true);
      } catch (_) {}
    }
  }

  // Perform the actual migration
  static Future<void> _performMigration() async {
    // Request contacts permission
    final hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      print('📸 Contacts permission denied, skipping migration');
      return;
    }

    // Load contacts with photos
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    if (contacts.isEmpty) {
      print('📸 No contacts found, skipping migration');
      return;
    }

    // Load friends
    final storageService = StorageService();
    final friends = await storageService.getFriends();

    if (friends.isEmpty) {
      print('📸 No friends found, skipping migration');
      return;
    }

    // Track updates
    int updatedCount = 0;
    final updatedFriends = <Friend>[];

    // Match and update friends
    for (final friend in friends) {
      // Only update emoji placeholders
      if (!friend.isEmoji) {
        updatedFriends.add(friend);
        continue;
      }

      // Find matching contact
      final matchingContact = _findMatchingContact(friend.name, contacts);
      if (matchingContact == null || matchingContact.photo == null || matchingContact.photo!.isEmpty) {
        updatedFriends.add(friend);
        continue;
      }

      // Save contact photo
      try {
        final photoPath = await _saveContactPhoto(matchingContact.photo!);

        // Update friend with photo
        final updatedFriend = friend.copyWith(
          profileImage: photoPath,
          isEmoji: false,
        );

        updatedFriends.add(updatedFriend);
        updatedCount++;
        print('📸 Updated photo for: ${friend.name}');
      } catch (e) {
        print('❌ Failed to save photo for ${friend.name}: $e');
        updatedFriends.add(friend);
      }
    }

    // Save updated friends if any changes
    if (updatedCount > 0) {
      await storageService.saveFriends(updatedFriends);
      print('✅ Migration updated $updatedCount friend(s)');
    } else {
      print('📸 No friends needed photo updates');
    }
  }

  // Find contact with matching name (case-insensitive, exact match)
  static Contact? _findMatchingContact(String friendName, List<Contact> contacts) {
    final normalizedFriendName = friendName.toLowerCase().trim();

    for (final contact in contacts) {
      final normalizedContactName = contact.displayName.toLowerCase().trim();
      if (normalizedContactName == normalizedFriendName) {
        return contact;
      }
    }

    return null;
  }

  // Save contact photo to app documents directory
  static Future<String> _saveContactPhoto(List<int> photoBytes) async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final String imagePath = '${docDir.path}/contact_migration_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File imageFile = File(imagePath);
    await imageFile.writeAsBytes(photoBytes);
    return imagePath;
  }
}