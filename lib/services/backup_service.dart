// lib/services/backup_service.dart - Complete file with share functionality
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import '../utils/colors.dart';

class BackupService {
  static const String _backupVersion = '1.0';

  static Future<String?> exportData(BuildContext context) async {
    try {
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
          final nextReminderTime = await notificationService.getNextReminderTime(friend.id);
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

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/alongside_backup_$timestamp.json');
      await tempFile.writeAsString(jsonString);

      // Share the file
      if (context.mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: 'Alongside Backup - ${DateTime.now().toString().split(' ')[0]}',
          subject: 'Alongside App Backup',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        );

        // Update last backup date
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
        _showErrorDialog(context, 'Export failed: $e');
      }
      return null;
    }
  }



  // Show export success dialog
  static void _showExportSuccessDialog(BuildContext context) {
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
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Your data has been exported. You can now save it to your device or share it.',
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

void _importData(BuildContext context) {
  final TextEditingController jsonController = TextEditingController();

  showCupertinoDialog(
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
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            const Text(
              'Paste your backup JSON data below:',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.label,
                fontFamily: '.SF Pro Text',
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: jsonController,
              placeholder: 'Paste JSON here...',
              maxLines: 5,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: '.SF Pro Text',
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
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
          onPressed: () async {
            Navigator.pop(context);
            await _processImportedJson(context, jsonController.text);
          },
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
}

// Add this helper method
Future<void> _processImportedJson(BuildContext context, String jsonString) async {
  if (jsonString.trim().isEmpty) {
    _showErrorDialog(context, 'Please paste valid JSON data');
    return;
  }

  try {
    final Map<String, dynamic> backupData = jsonDecode(jsonString);

    // Rest of the import logic from the original method...
    final version = backupData['version'] as String?;
    if (version != '1.0') {
      throw Exception('Incompatible backup version');
    }

    // Continue with the import process...
    // (Copy the rest of the import logic from the original _importData method)

  } catch (e) {
    _showErrorDialog(context, 'Invalid backup data: ${e.toString()}');
  }
}

// Add error dialog helper
void _showErrorDialog(BuildContext context, String message) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text(
        'Import Error',
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