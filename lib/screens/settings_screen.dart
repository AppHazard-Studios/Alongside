// lib/screens/settings_screen.dart - Enhanced with debug features
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../widgets/illustrations.dart';
import '../services/battery_optimization_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../providers/friends_provider.dart';
import '../models/friend.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/lock_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _lastBackupDate;
  bool _notificationSounds = true;
  bool _lockEnabled = false;
  String? _lockType;
  int _lockCooldownMinutes = 5;
  final LockService _lockService = LockService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lockEnabled = await _lockService.isLockEnabled();
    final lockType = await _lockService.getLockType();
    final cooldownMinutes = await _lockService.getCooldownMinutes();

    setState(() {
      _lastBackupDate = prefs.getString('last_backup_date');
      _notificationSounds = prefs.getBool('notification_sounds') ?? true;
      _lockEnabled = lockEnabled;
      _lockType = lockType;
      _lockCooldownMinutes = cooldownMinutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              CupertinoIcons.back,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // NOTIFICATION DEBUG SECTION - NEW
                _buildSectionTitle('NOTIFICATION DEBUG'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.bell_fill,
                        iconColor: AppColors.primary,
                        title: 'View Scheduled Notifications',
                        subtitle: 'See all pending reminders',
                        onTap: () => _showScheduledNotifications(context),
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.checkmark_shield,
                        iconColor: AppColors.success,
                        title: 'Check Permissions',
                        subtitle: 'Verify notification permissions',
                        onTap: () => _checkPermissions(context),
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.arrow_clockwise,
                        iconColor: AppColors.warning,
                        title: 'Reschedule All Reminders',
                        subtitle: 'Force reschedule all friend reminders',
                        onTap: () => _rescheduleAllReminders(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Security section
                _buildSectionTitle('SECURITY'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildToggleItem(
                        context,
                        icon: CupertinoIcons.lock_shield_fill,
                        iconColor: AppColors.primary,
                        title: 'App Lock',
                        subtitle: _lockEnabled
                            ? 'Protected with ${_lockType == 'biometric' ? 'biometrics' : 'PIN'}'
                            : 'Secure app with lock screen',
                        value: _lockEnabled,
                        onChanged: (value) => _toggleAppLock(value),
                      ),
                      if (_lockEnabled) ...[
                        _buildDivider(),
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.lock_rotation,
                          iconColor: AppColors.secondary,
                          title: 'Change Lock Method',
                          subtitle: 'Switch between PIN and biometrics',
                          onTap: () => _changeLockMethod(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.timer,
                          iconColor: AppColors.accent,
                          title: 'Lock Cooldown',
                          subtitle: 'Lock after $_lockCooldownMinutes minutes in background',
                          onTap: () => _showCooldownPicker(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Notifications section
                _buildSectionTitle('NOTIFICATIONS'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.bell,
                        iconColor: AppColors.accent,
                        title: 'Test Notifications',
                        subtitle: 'Send a test notification',
                        onTap: () => _testNotifications(context),
                        showChevron: false,
                      ),
                      _buildDivider(),
                      _buildToggleItem(
                        context,
                        icon: CupertinoIcons.speaker_2,
                        iconColor: AppColors.primary,
                        title: 'Notification Sounds',
                        subtitle: 'Play sound for reminders',
                        value: _notificationSounds,
                        onChanged: (value) => _updateNotificationSound(value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Backup & Restore section
                _buildSectionTitle('BACKUP & RESTORE'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.arrow_up_circle,
                        iconColor: AppColors.success,
                        title: 'Export Data',
                        subtitle: 'Save friends and messages to file',
                        onTap: () => _exportData(context),
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.arrow_down_circle,
                        iconColor: AppColors.tertiary,
                        title: 'Import Data',
                        subtitle: 'Restore from backup file',
                        onTap: () => _importData(context),
                      ),
                      if (_lastBackupDate != null) ...[
                        _buildDivider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.clock,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Last backup: $_lastBackupDate',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Advanced section
                _buildSectionTitle('ADVANCED'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.battery_25,
                        iconColor: AppColors.warning,
                        title: 'Battery Optimization',
                        subtitle: 'Ensure notifications work properly',
                        onTap: () => _showBatteryOptimization(context),
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.trash,
                        iconColor: AppColors.error,
                        title: 'Clear App Data',
                        subtitle: 'Remove all friends and messages',
                        onTap: () => _clearAppData(context),
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // About section
                _buildSectionTitle('ABOUT'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.info_circle,
                        iconColor: AppColors.primary,
                        title: 'About Alongside',
                        subtitle: 'Learn more about the app',
                        onTap: () => _showAboutDialog(context),
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.lock,
                        iconColor: AppColors.secondary,
                        title: 'Privacy',
                        subtitle: 'All data stays on your device',
                        onTap: () => _showPrivacyInfo(context),
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        context,
                        icon: CupertinoIcons.question_circle,
                        iconColor: AppColors.accent,
                        title: 'Troubleshooting',
                        subtitle: 'Help with common issues',
                        onTap: () => _showTroubleshooting(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // App version info at bottom
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Illustrations.friendsIllustration(size: 60),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Alongside',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Show scheduled notifications
  void _showScheduledNotifications(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.debugScheduledNotifications();

    // Also show in UI
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final friends = provider.friends;

    List<Widget> notificationWidgets = [];

    for (final friend in friends) {
      if (friend.reminderDays > 0) {
        final nextTime = await notificationService.getNextReminderTime(friend.id);
        notificationWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        nextTime != null
                            ? 'Next: ${nextTime.toString().split('.')[0]}'
                            : 'Not scheduled',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  nextTime != null
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  color: nextTime != null ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
        );
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Scheduled Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: notificationWidgets.isEmpty
                    ? [
                  const Center(
                    child: Text(
                      'No notifications scheduled',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                ]
                    : notificationWidgets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Check permissions
  void _checkPermissions(BuildContext context) async {
    final notificationService = NotificationService();
    final setupStatus = await notificationService.checkNotificationSetup();

    // Convert the bool result to what we need
    final hasSetup = setupStatus;

    // Check individual permissions
    final hasNotification = await Permission.notification.isGranted;
    final hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;
    final hasBatteryOptimization = await Permission.ignoreBatteryOptimizations.isGranted;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Permission Status',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPermissionRow('Notifications', hasNotification),
              const SizedBox(height: 8),
              _buildPermissionRow('Exact Alarms', hasExactAlarm),
              const SizedBox(height: 8),
              _buildPermissionRow('Battery Optimization', hasBatteryOptimization),
              const SizedBox(height: 16),
              Text(
                hasSetup ? '✅ Ready for notifications' : '❌ Setup incomplete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: hasSetup ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!hasSetup)
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
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

  Widget _buildPermissionRow(String name, bool granted) {
    return Row(
      children: [
        Icon(
          granted ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
          color: granted ? AppColors.success : AppColors.error,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // NEW: Reschedule all reminders
  void _rescheduleAllReminders(BuildContext context) async {
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
                'Rescheduling...',
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

    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final notificationService = NotificationService();
    int count = 0;

    for (final friend in provider.friends) {
      if (friend.reminderDays > 0) {
        await notificationService.scheduleReminder(friend);
        count++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context); // Close loading

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(
            'Reminders Rescheduled',
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
              'Successfully rescheduled $count reminder${count == 1 ? '' : 's'}',
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

  // Show cooldown picker
  void _showCooldownPicker() {
    final options = [0, 1, 5, 10, 15, 30, 60];
    int selectedMinutes = _lockCooldownMinutes;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () async {
                    await _lockService.setCooldownMinutes(selectedMinutes);
                    setState(() {
                      _lockCooldownMinutes = selectedMinutes;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: options.indexOf(_lockCooldownMinutes),
                ),
                onSelectedItemChanged: (index) {
                  selectedMinutes = options[index];
                },
                children: options.map((minutes) {
                  return Center(
                    child: Text(
                      minutes == 0
                          ? 'Immediately'
                          : '$minutes minute${minutes == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // All the existing helper methods remain the same...
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
          fontFamily: '.SF Pro Text',
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: CupertinoColors.systemGrey5,
      margin: const EdgeInsets.only(left: 66),
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        bool showChevron = true,
        bool isDestructive = false,
      }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? AppColors.error
                          : CupertinoColors.label,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.textSecondary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required bool value,
        required Function(bool) onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CupertinoColors.label,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // All existing action methods remain the same...
  void _toggleAppLock(bool enable) async {
    if (enable) {
      _showLockMethodPicker();
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(
            'Disable App Lock',
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
              'Are you sure you want to disable app lock?',
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
                await _lockService.disableLock();
                await _loadSettings();
              },
              isDestructiveAction: true,
              child: const Text(
                'Disable',
                style: TextStyle(
                  color: AppColors.error,
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

  void _showLockMethodPicker() async {
    final biometricAvailable = await _lockService.isBiometricAvailable();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Choose Lock Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          if (biometricAvailable)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                final Object? result = await _lockService.enableBiometricLock();
                final bool success = result is bool ? result : false;
                if (success) {
                  await _loadSettings();
                } else {
                  _showErrorSnackBar('Failed to enable biometric lock');
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.lock_shield_fill,
                    color: CupertinoColors.systemBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Biometric Lock',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showPinSetup();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.number,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'PIN Lock',
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

  void _showPinSetup() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Set PIN',
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
              CupertinoTextField(
                controller: pinController,
                placeholder: 'Enter PIN (min 4 digits)',
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: confirmController,
                placeholder: 'Confirm PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 8,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
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
              if (pinController.text.length < 4) {
                _showErrorSnackBar('PIN must be at least 4 digits');
                return;
              }
              if (pinController.text != confirmController.text) {
                _showErrorSnackBar('PINs do not match');
                return;
              }

              Navigator.pop(context);
              final success =
              await _lockService.enablePinLock(pinController.text);
              if (success) {
                await _loadSettings();
              } else {
                _showErrorSnackBar('Failed to set PIN');
              }
            },
            child: const Text(
              'Set PIN',
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

  void _changeLockMethod() {
    _showLockMethodPicker();
  }

  void _showErrorSnackBar(String message) {
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

  void _testNotifications(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.scheduleTestNotification();

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(
            'Test Notification Sent',
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
              'You should see a notification immediately. If you don\'t, check your notification settings.',
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
  }

  void _updateNotificationSound(bool value) async {
    setState(() {
      _notificationSounds = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_sounds', value);
  }

  void _exportData(BuildContext context) async {
    final filePath = await BackupService.exportData(context);
    if (filePath != null) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateStr = '${now.month}/${now.day}/${now.year}';
      await prefs.setString('last_backup_date', dateStr);
      setState(() {
        _lastBackupDate = dateStr;
      });
    }
  }

  void _importData(BuildContext context) async {
    await BackupService.importData(context);
    _loadSettings();
  }

  void _showBatteryOptimization(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            BatteryOptimizationService.buildBatteryOptimizationGuide(context),
            const SizedBox(height: 20),
            CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              onPressed: () async {
                Navigator.pop(context);
                await BatteryOptimizationService.requestBatteryOptimization(
                    context);
              },
              child: const Text(
                'Enable Battery Optimization Exemption',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _clearAppData(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Clear All Data',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'This will permanently delete all your friends and custom messages. This action cannot be undone.',
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
            isDefaultAction: true,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);

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
                          'Clearing...',
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

              final provider =
              Provider.of<FriendsProvider>(context, listen: false);
              final storageService = provider.storageService;

              await storageService.saveFriends([]);
              await storageService.saveCustomMessages([]);

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              final notificationService = NotificationService();
              for (final friend in provider.friends) {
                await notificationService.cancelReminder(friend.id);
                await notificationService
                    .removePersistentNotification(friend.id);
              }

              await provider.reloadFriends();

              if (mounted) {
                Navigator.pop(context);

                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text(
                      'Data Cleared',
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
                        'All app data has been cleared successfully.',
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
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
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
            },
            isDestructiveAction: true,
            child: const Text(
              'Clear All Data',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTroubleshooting(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Troubleshooting Guide',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTroubleshootingSection(
                      'Not receiving notifications?',
                      [
                        '1. Check that notifications are enabled in your device settings',
                        '2. Disable battery optimization for Alongside',
                        '3. Make sure Do Not Disturb is off',
                        '4. Try the test notification feature',
                        '5. Check permissions in Notification Debug section',
                        '6. Try "Reschedule All Reminders" option',
                      ],
                    ),
                    _buildTroubleshootingSection(
                      'App crashes or freezes?',
                      [
                        '1. Force close the app and restart',
                        '2. Check for app updates',
                        '3. Restart your device',
                        '4. Export your data and reinstall if needed',
                      ],
                    ),
                    _buildTroubleshootingSection(
                      'Can\'t send messages or make calls?',
                      [
                        '1. Check that phone numbers are entered correctly',
                        '2. Ensure you have a default messaging/phone app set',
                        '3. Check app permissions for phone and SMS',
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection(String title, List<String> steps) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
              fontFamily: '.SF Pro Text',
            ),
          ),
          const SizedBox(height: 8),
          ...steps
              .map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: '.SF Pro Text',
                height: 1.4,
              ),
            ),
          ))
              .toList(),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: screenWidth * 0.98,
            constraints: const BoxConstraints(maxWidth: 400),
            child: CupertinoAlertDialog(
              title: const Text(
                'About Alongside',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Illustrations.friendsIllustration(size: 80),
                      ),
                    ),
                    const Text(
                      'Alongside helps you walk with your friends through the highs and lows of life.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: CupertinoColors.label,
                        fontFamily: '.SF Pro Text',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: CupertinoColors.label,
                        fontFamily: '.SF Pro Text',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: screenWidth * 1.1,
            child: CupertinoAlertDialog(
              title: const Text(
                'Privacy & Security',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              content: const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Text(
                  'Alongside is designed with privacy in mind. All your data is stored locally on your device and never shared with third parties. Your conversations and friend information remain completely private.',
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
                    'Got it',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}