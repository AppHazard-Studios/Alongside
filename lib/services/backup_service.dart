// lib/services/backup_service.dart - Fixed with proper file handling
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      // Get lock settings
      final lockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      final lockType = prefs.getString('app_lock_type');
      final lockPin = prefs.getString('app_lock_pin');
      final lockCooldown = prefs.getInt('lock_cooldown_minutes') ?? 5;

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
        },
        'security': {
          'lockEnabled': lockEnabled,
          'lockType': lockType,
          'lockPin': lockPin,
          'lockCooldown': lockCooldown,
        }
      };

      // Convert to JSON with pretty printing
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show security info dialog before export
      if (lockEnabled && context.mounted) {
        final proceed = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text(
              'Security Settings Included',
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
                'This backup includes your lock settings (${lockType == 'biometric' ? 'Biometric' : 'PIN'}). When you import this backup, it will restore your security configuration.',
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
                child: const Text(
                  'Continue',
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

        if (proceed != true) return null;
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
                      'Reading...',
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

        // Get current and backup security settings
        final prefs = await SharedPreferences.getInstance();
        final currentLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
        final currentLockType = prefs.getString('app_lock_type');

        final backupSecurity = backupData['security'] as Map<String, dynamic>?;
        final backupLockEnabled = backupSecurity?['lockEnabled'] ?? false;
        final backupLockType = backupSecurity?['lockType'];

        // Build current status text
        String currentStatus = 'No lock';
        if (currentLockEnabled && currentLockType != null) {
          currentStatus = currentLockType == 'biometric' ? 'Biometric lock' : 'PIN lock';
        }

        // Build backup status text
        String backupStatus = 'No lock';
        if (backupLockEnabled && backupLockType != null) {
          backupStatus = backupLockType == 'biometric' ? 'Biometric lock' : 'PIN lock';
        }

        // Show detailed import confirmation dialog
        if (context.mounted) {
          final importChoice = await showCupertinoDialog<String>(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This will replace all your current data.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: CupertinoColors.label,
                        fontFamily: '.SF Pro Text',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (backupLockEnabled) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.lock_shield,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Security Settings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Current:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                Text(
                                  currentStatus,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.label,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Backup:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                Text(
                                  backupStatus,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.label,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                if (backupLockEnabled)
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context, 'skip_security'),
                    child: const Text(
                      'Import Without Lock',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, 'import_all'),
                  child: Text(
                    backupLockEnabled ? 'Import Everything' : 'Import',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          );

          if (importChoice == null || importChoice == 'cancel') return;

          final includeSecurity = importChoice == 'import_all';

          // Show importing dialog
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

          // Import the data
          final provider = Provider.of<FriendsProvider>(context, listen: false);
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
            await prefs.setInt('messages_sent_count',
                backupData['stats']['messagesSent'] ?? 0);
            await prefs.setInt(
                'calls_made_count', backupData['stats']['callsMade'] ?? 0);
          }

          // Import security settings if user chose to
          if (includeSecurity && backupSecurity != null) {
            await prefs.setBool('app_lock_enabled', backupSecurity['lockEnabled'] ?? false);

            if (backupSecurity['lockType'] != null) {
              await prefs.setString('app_lock_type', backupSecurity['lockType']);
            } else {
              await prefs.remove('app_lock_type');
            }

            if (backupSecurity['lockPin'] != null) {
              await prefs.setString('app_lock_pin', backupSecurity['lockPin']);
            } else {
              await prefs.remove('app_lock_pin');
            }

            if (backupSecurity['lockCooldown'] != null) {
              await prefs.setInt('lock_cooldown_minutes', backupSecurity['lockCooldown']);
            }
          }

          // Force reload the provider
          await provider.reloadFriends();

          // Close importing dialog
          if (context.mounted) {
            Navigator.pop(context);
          }

          // Show success with security info
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
                content: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    includeSecurity && backupLockEnabled
                        ? 'Your data and security settings have been imported successfully!'
                        : includeSecurity
                        ? 'Your data has been imported successfully!'
                        : 'Your data has been imported successfully! Your current lock settings were kept.',
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