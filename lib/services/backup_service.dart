// lib/services/backup_service.dart - Fixed with proper file handling
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/friend.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../utils/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';

class BackupService {
  static const String _backupVersion = '1.0';

  static Future<String?> exportData(BuildContext context) async {
    try {
      // Show loading dialog
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CupertinoColors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(
                  color: CupertinoColors.white,
                  radius: 14,
                ),
                SizedBox(height: 16),
                Text(
                  'Exporting...',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Get current data
      final storageService = StorageService();
      final notificationService = NotificationService();
      final friends = await storageService.getFriends();
      final customMessages = await storageService.getCustomMessages();
      final prefs = await SharedPreferences.getInstance();

      // Build reminder data
      final reminderData = <String, dynamic>{};
      for (final friend in friends) {
        if (friend.reminderDays > 0) {
          final nextReminderTime =
              await notificationService.getNextReminderTime(friend.id);
          final lastActionTime = prefs.getInt('last_action_${friend.id}');

          reminderData[friend.id] = {
            'nextReminder': nextReminderTime?.toIso8601String(),
            'lastAction': lastActionTime,
          };
        }
      }

      // Create backup data structure
      final backupData = {
        'version': _backupVersion,
        'exportDate': DateTime.now().toIso8601String(),
        'friends': friends.map((f) => f.toJson()).toList(),
        'customMessages': customMessages,
        'reminderData': reminderData,
        'stats': {
          'messagesSent': await storageService.getMessagesSentCount(),
          'callsMade': await storageService.getCallsMadeCount(),
        }
      };

      // Convert to JSON with pretty printing
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // For Android: Show options to save or share
      if (Platform.isAndroid && context.mounted) {
        return await _showAndroidExportOptions(context, jsonString, backupData);
      } else {
        // For iOS: Use share sheet
        return await _shareFile(context, jsonString);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        _showErrorDialog(context, 'Export failed: $e');
      }
      return null;
    }
  }

  // Android-specific export options
  static Future<String?> _showAndroidExportOptions(
    BuildContext context,
    String jsonString,
    Map<String, dynamic> backupData,
  ) async {
    return showCupertinoModalPopup<String?>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Export Backup',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final path = await _saveToDevice(context, jsonString);
              if (path != null && context.mounted) {
                _showExportSuccessDialog(context,
                    savedToDevice: true, path: path);
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.folder,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Save to Device',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _shareFile(context, jsonString);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.share,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  // Save file directly to device storage - FIXED VERSION
  static Future<String?> _saveToDevice(
      BuildContext context, String jsonString) async {
    try {
      // Create a temporary file first
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/alongside_backup_${DateTime.now().millisecondsSinceEpoch}.json');

      // Write as bytes to avoid encoding issues
      await tempFile.writeAsBytes(utf8.encode(jsonString));

      // Let user choose location using the temporary file
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Alongside Backup',
        fileName:
            'alongside_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: await tempFile.readAsBytes(), // Pass bytes directly
      );

      // Clean up temp file
      await tempFile.delete();

      if (outputFile != null) {
        // Update last backup date
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        final dateStr = '${now.month}/${now.day}/${now.year}';
        await prefs.setString('last_backup_date', dateStr);

        return outputFile;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to save file: $e');
      }
    }
    return null;
  }

  // Share file using share sheet
  static Future<String?> _shareFile(
      BuildContext context, String jsonString) async {
    try {
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/alongside_backup_$timestamp.json');
      await tempFile.writeAsString(jsonString);

      // Share the file
      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(tempFile.path, mimeType: 'application/json')],
          text: 'Alongside Backup - ${DateTime.now().toString().split(' ')[0]}',
          subject: 'Alongside App Backup',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );

        // Update last backup date
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        final dateStr = '${now.month}/${now.day}/${now.year}';
        await prefs.setString('last_backup_date', dateStr);

        // Show success dialog
        if (context.mounted) {
          _showExportSuccessDialog(context);
        }

        return tempFile.path;
      }

      return null;
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Share failed: $e');
      }
      return null;
    }
  }

  // Clean up all reminder-related data before import
  static Future<void> _cleanupReminderData() async {
    try {
      // Cancel ALL WorkManager tasks
      await Workmanager().cancelAll();
      print("🗑️ Cancelled all WorkManager tasks");

      // Clear all reminder-related SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys()
          .where((key) =>
      key.startsWith('next_reminder_') ||
          key.startsWith('last_action_'))
          .toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      print("🗑️ Cleared ${keysToRemove.length} reminder keys");
    } catch (e) {
      print("⚠️ Error cleaning up reminder data: $e");
    }
  }

  // Show export success dialog
  static void _showExportSuccessDialog(BuildContext context,
      {bool savedToDevice = false, String? path}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Export Successful',
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text(
                savedToDevice
                    ? 'Your backup has been saved to your device.'
                    : 'Your data has been exported. You can now save it or share it.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: CupertinoColors.label,
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
              if (path != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    path.split('/').last,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Import data - Updated to handle file picker properly
  static Future<void> importData(BuildContext context) async {
    try {
      // Pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Alongside Backup',
      );

      if (result != null && result.files.single.path != null) {
        // Show loading
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                      radius: 14,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Importing...',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Read the file
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

        // Parse the backup data
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        // Close loading
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Validate version
        final version = backupData['version'] as String?;
        if (version != '1.0') {
          throw Exception('Incompatible backup version');
        }

        // Show confirmation dialog
        if (context.mounted) {
          final shouldImport = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text(
                'Import Data',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              content: const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'This will replace all your current friends and messages. Are you sure you want to continue?',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: CupertinoColors.label,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  isDefaultAction: true,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, true),
                  isDestructiveAction: true,
                  child: const Text(
                    'Import',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          );

// Replace the import success section in importData method (around line 360-395)
          if (shouldImport == true && context.mounted) {
            // Show importing dialog
            showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                        radius: 14,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Importing...',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            // CLEANUP OLD DATA FIRST
            await _cleanupReminderData();

            // Import the data
            final provider =
            Provider.of<FriendsProvider>(context, listen: false);
            final storageService = provider.storageService;

            // Import friends
            final friendsList = (backupData['friends'] as List?)
                ?.map((f) => Friend.fromJson(f))
                .toList() ??
                [];
            await storageService.saveFriends(friendsList);

            // Import custom messages
            final customMessages =
                (backupData['customMessages'] as List?)?.cast<String>() ?? [];
            await storageService.saveCustomMessages(customMessages);

            // Import stats if available
            if (backupData['stats'] != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('messages_sent_count',
                  backupData['stats']['messagesSent'] ?? 0);
              await prefs.setInt(
                  'calls_made_count', backupData['stats']['callsMade'] ?? 0);
            }

            // Force reload and reschedule all reminders
            await provider.reloadFriends();

            // Reschedule reminders for all friends
            final notificationService = NotificationService();
            for (final friend in friendsList) {
              if (friend.hasReminder) {
                await notificationService.scheduleReminder(friend);
              }
            }
            print("✅ Rescheduled ${friendsList.where((f) => f.hasReminder).length} reminders");

            // Close importing dialog
            if (context.mounted) {
              Navigator.pop(context);
            }

            // Show success
            if (context.mounted) {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text(
                    'Import Successful',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  content: const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Your data has been imported successfully!',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: CupertinoColors.label,
                        fontFamily: '.SF Pro Text',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      // Close loading if still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        _showErrorDialog(context, 'Import failed: ${e.toString()}');
      }
    }
  }

  // Show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: CupertinoColors.label,
              fontFamily: '.SF Pro Text',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
