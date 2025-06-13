// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/friend.dart';
import 'storage_service.dart';
import '../utils/colors.dart';

class BackupService {
  static const String _backupVersion = '1.0';

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ uses different permissions
      if (await Permission.manageExternalStorage.isRestricted) {
        return await Permission.storage.request().isGranted;
      } else {
        return await Permission.manageExternalStorage.request().isGranted;
      }
    }
    return true; // iOS doesn't need explicit permission for app documents
  }

  static Future<String?> exportData(BuildContext context) async {
    try {
      // Get current data
      final storageService = StorageService();
      final friends = await storageService.getFriends();
      final customMessages = await storageService.getCustomMessages();

      // Create backup data structure
      final backupData = {
        'version': _backupVersion,
        'exportDate': DateTime.now().toIso8601String(),
        'friends': friends.map((f) => f.toJson()).toList(),
        'customMessages': customMessages,
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/alongside_backup_$timestamp.json';

      // Write file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Show success dialog with share option
      if (context.mounted) {
        _showExportSuccessDialog(context, filePath);
      }

      return filePath;
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Export failed: $e');
      }
      return null;
    }
  }

  static Future<void> importData(BuildContext context, String filePath) async {
    try {
      // Read file
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Validate version
      final version = backupData['version'] as String?;
      if (version != _backupVersion) {
        throw Exception('Incompatible backup version');
      }

      // Parse data
      final friendsJson = backupData['friends'] as List<dynamic>?;
      final customMessages = (backupData['customMessages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();

      if (friendsJson == null) {
        throw Exception('Invalid backup data');
      }

      // Show confirmation dialog
      if (context.mounted) {
        final shouldImport = await _showImportConfirmationDialog(
          context,
          friendsJson.length,
          customMessages?.length ?? 0,
        );

        if (shouldImport == true) {
          // Import data
          final storageService = StorageService();

          // Import friends
          final friends = friendsJson.map((json) => Friend.fromJson(json)).toList();
          await storageService.saveFriends(friends);

          // Import custom messages
          if (customMessages != null && customMessages.isNotEmpty) {
            await storageService.saveCustomMessages(customMessages);
          }

          if (context.mounted) {
            _showImportSuccessDialog(context, friends.length, customMessages?.length ?? 0);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Import failed: $e');
      }
    }
  }

  // Dialog helpers
  static void _showExportSuccessDialog(BuildContext context, String filePath) {
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
            'Your data has been exported successfully. You can find the backup file in your app documents.',
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

  static Future<bool?> _showImportConfirmationDialog(
      BuildContext context,
      int friendCount,
      int messageCount,
      ) {
    return showCupertinoDialog<bool>(
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
          child: Text(
            'This will replace your current data with:\n'
                '• $friendCount friends\n'
                '• $messageCount custom messages\n\n'
                'This action cannot be undone.',
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
            onPressed: () => Navigator.pop(context, false),
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
  }

  static void _showImportSuccessDialog(BuildContext context, int friendCount, int messageCount) {
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
        content: Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Successfully imported:\n'
                '• $friendCount friends\n'
                '• $messageCount custom messages',
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
            onPressed: () {
              Navigator.pop(context);
              // Pop back to home screen
              Navigator.of(context).popUntil((route) => route.isFirst);
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