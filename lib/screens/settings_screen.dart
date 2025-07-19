// lib/screens/settings_screen.dart - COMPLETE ENHANCED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
                        title: 'Battery Optimisation',
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

  // Show scheduled notifications method
  void _showScheduledNotifications(BuildContext context) async {
    final notificationService = NotificationService();
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final friends = provider.friends;

    List<Widget> notificationWidgets = [];

    for (final friend in friends) {
      if (friend.hasReminder) {
        final nextTime = await notificationService.getNextReminderTime(friend.id);
        final now = DateTime.now();

        final isPastDue = nextTime != null && nextTime.isBefore(now);
        final isScheduled = nextTime != null;

        String statusText;
        Color statusColor;
        IconData statusIcon;

        if (!isScheduled) {
          statusText = 'Not scheduled';
          statusColor = AppColors.error;
          statusIcon = CupertinoIcons.exclamationmark_triangle;
        } else if (isPastDue) {
          statusText = 'Overdue';
          statusColor = AppColors.warning;
          statusIcon = CupertinoIcons.clock;
        } else {
          final timeUntil = nextTime.difference(now);
          if (timeUntil.inDays > 0) {
            statusText = 'In ${timeUntil.inDays} day${timeUntil.inDays == 1 ? '' : 's'}';
          } else if (timeUntil.inHours > 0) {
            statusText = 'In ${timeUntil.inHours} hour${timeUntil.inHours == 1 ? '' : 's'}';
          } else {
            statusText = 'In ${timeUntil.inMinutes} minute${timeUntil.inMinutes == 1 ? '' : 's'}';
          }
          statusColor = AppColors.success;
          statusIcon = CupertinoIcons.checkmark_circle_fill;
        }

        notificationWidgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
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
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${friend.reminderDisplayText} at ${friend.reminderTime}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      if (isScheduled && !isPastDue) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Next: ${nextTime.toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
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
                'Scheduled Reminders',
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
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.bell_slash,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No reminders scheduled',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add friends with reminder settings to see them here.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontFamily: '.SF Pro Text',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                ]
                    : notificationWidgets,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CupertinoButton(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check permissions method
  void _checkPermissions(BuildContext context) async {
    final hasNotification = await Permission.notification.isGranted;
    final hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;
    final hasBatteryOptimisation = await Permission.ignoreBatteryOptimizations.isGranted;

    final allPermissionsGood = hasNotification && hasExactAlarm && hasBatteryOptimisation;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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
                'Notification Permissions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildPermissionRow('Notifications', hasNotification),
                    const SizedBox(height: 16),
                    _buildPermissionRow('Exact Alarms', hasExactAlarm),
                    const SizedBox(height: 16),
                    _buildPermissionRow('Battery Optimisations', hasBatteryOptimisation),

                    const Spacer(),

                    if (!allPermissionsGood)
                      CupertinoButton(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          Navigator.pop(context);
                          openAppSettings();
                        },
                        child: const Text(
                          'Open Settings App',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String name, bool granted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: granted ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  granted ? CupertinoIcons.checkmark : CupertinoIcons.xmark,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  granted ? 'Enabled' : 'Disabled',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  // Helper methods
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

  // ENHANCED: App lock toggle
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

  // ENHANCED: Lock method picker with better descriptions
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
        message: const Text(
          'Select how you want to secure the app',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          if (biometricAvailable)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _setupBiometric();
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
                    'Biometric Lock (Fingerprint/Face)',
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
                  'PIN Lock (4-8 digits)',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          if (!biometricAvailable)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showDetailedErrorDialog(
                  'Biometric Not Available',
                  'Your device does not support biometric authentication or no biometric data is enrolled. Please set up fingerprint or face authentication in your device settings first.',
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.lock_shield,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Biometric Lock (Not Available)',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey,
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

  // ENHANCED: PIN setup with proper number input
  void _showPinSetup() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final pinFocusNode = FocusNode();
    final confirmFocusNode = FocusNode();

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
              // PIN input
              CupertinoTextField(
                controller: pinController,
                focusNode: pinFocusNode,
                placeholder: 'Enter PIN (min 4 digits)',
                keyboardType: TextInputType.number, // Force number keyboard
                obscureText: true,
                maxLength: 8,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [
                  // CRITICAL: Only allow digits
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                onSubmitted: (_) {
                  // Move to confirm field
                  confirmFocusNode.requestFocus();
                },
              ),
              const SizedBox(height: 12),
              // Confirm PIN input
              CupertinoTextField(
                controller: confirmController,
                focusNode: confirmFocusNode,
                placeholder: 'Confirm PIN',
                keyboardType: TextInputType.number, // Force number keyboard
                obscureText: true,
                maxLength: 8,
                textAlign: TextAlign.center,
                inputFormatters: [
                  // CRITICAL: Only allow digits
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                onSubmitted: (_) {
                  // Try to set PIN when done
                  _processPinSetup(pinController.text, confirmController.text);
                  Navigator.pop(context);
                },
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
            onPressed: () {
              _processPinSetup(pinController.text, confirmController.text);
              Navigator.pop(context);
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

    // Focus the first field after dialog opens
    Future.delayed(const Duration(milliseconds: 300), () {
      pinFocusNode.requestFocus();
    });
  }

  // ENHANCED: Process PIN setup with enhanced validation
  void _processPinSetup(String pin, String confirmPin) async {
    // Validation
    if (pin.length < 4) {
      _showErrorSnackBar('PIN must be at least 4 digits');
      return;
    }

    if (pin.length > 8) {
      _showErrorSnackBar('PIN cannot be longer than 8 digits');
      return;
    }

    // Ensure PIN contains only digits
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      _showErrorSnackBar('PIN must contain only numbers');
      return;
    }

    if (pin != confirmPin) {
      _showErrorSnackBar('PINs do not match');
      return;
    }

    // Show loading
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
                'Setting PIN...',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await _lockService.enablePinLock(pin);

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (success) {
          await _loadSettings();
          _showSuccessSnackBar('PIN lock enabled successfully');
        } else {
          _showErrorSnackBar('Failed to set PIN');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showErrorSnackBar('Error setting PIN: ${e.toString()}');
      }
    }
  }

  // ENHANCED: Biometric setup with better error handling
  void _setupBiometric() async {
    // Show loading
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: CupertinoColors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(
                color: CupertinoColors.white,
                radius: 16,
              ),
              SizedBox(height: 16),
              Text(
                'Setting up\nBiometric Lock',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  fontFamily: '.SF Pro Text',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _lockService.enableBiometricLock();

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result.success) {
          await _loadSettings();
          _showSuccessSnackBar('Biometric lock enabled successfully');
        } else {
          _showDetailedErrorDialog(
            'Biometric Setup Failed',
            result.error ?? 'Unknown error occurred',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showDetailedErrorDialog(
          'Biometric Setup Error',
          'Failed to set up biometric lock: ${e.toString()}',
        );
      }
    }
  }

  // ENHANCED: Detailed error display with more context
  void _showDetailedErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(
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
          ),
        ),
        actions: [
          if (message.contains('biometric') || message.contains('fingerprint')) ...[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _showPinSetup(); // Offer PIN as alternative
              },
              child: const Text(
                'Use PIN Instead',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Success feedback
  void _showSuccessSnackBar(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Success',
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

  void _showBatteryOptimization(BuildContext context) async {
    final hasPermission = await Permission.ignoreBatteryOptimizations.isGranted;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Battery Optimisations',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasPermission ? AppColors.success : AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasPermission ? CupertinoIcons.checkmark : CupertinoIcons.exclamationmark,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasPermission ? 'Unrestricted' : 'Restricted',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: hasPermission ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasPermission
                                ? 'Alongside runs without battery restrictions'
                                : 'Alongside has battery restrictions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: hasPermission ? AppColors.success : AppColors.warning,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasPermission
                                ? 'Your friend reminders will work reliably, even when the app is closed.'
                                : 'Android may prevent Alongside from sending scheduled reminders to save battery. This can cause notifications to be delayed or missed.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontFamily: '.SF Pro Text',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!hasPermission) ...[
                      const SizedBox(height: 20),
                      BatteryOptimizationService.buildBatteryOptimizationGuide(context),
                    ],

                    const Spacer(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  if (!hasPermission) ...[
                    CupertinoButton(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () async {
                        Navigator.pop(context);
                        await BatteryOptimizationService.requestBatteryOptimization(context);
                      },
                      child: const Text(
                        'Remove Battery Restrictions',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    CupertinoButton(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        Navigator.pop(context);
                        openAppSettings();
                      },
                      child: const Text(
                        'View App Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
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

              final provider = Provider.of<FriendsProvider>(context, listen: false);
              final storageService = provider.storageService;

              // Clear friends and messages
              await storageService.saveFriends([]);
              await storageService.saveCustomMessages([]);

              // Clear all SharedPreferences including stats
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Cancel all notifications
              final notificationService = NotificationService();
              for (final friend in provider.friends) {
                await notificationService.cancelReminder(friend.id);
                await notificationService.removePersistentNotification(friend.id);
              }

              // Reload provider data
              await provider.reloadFriends();

              if (mounted) {
                Navigator.pop(context); // Close loading

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
                          // Pop back to home screen and trigger a reload
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
                        '2. Disable battery optimisation for Alongside',
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

// Enhanced test method for the settings screen
void _testAllNotifications(BuildContext context) async {
  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Container(
        width: 200,
        height: 180,
        decoration: BoxDecoration(
          color: CupertinoColors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(
              color: CupertinoColors.white,
              radius: 16,
            ),
            SizedBox(height: 16),
            Text(
              'TESTING\nNOTIFICATIONS',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontFamily: '.SF Pro Text',
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'All reminder systems',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  final notificationService = NotificationService();
  final provider = Provider.of<FriendsProvider>(context, listen: false);

  bool immediateSuccess = false;
  bool scheduledSuccess = false;
  bool friendReminderSuccess = false;
  int friendsWithReminders = 0;
  int friendsScheduledSuccessfully = 0;

  try {
    // Test 1: Immediate notification
    await notificationService.scheduleTestNotification();
    immediateSuccess = true;
    print("✅ Immediate notification test completed");

    // Small delay between tests
    await Future.delayed(Duration(milliseconds: 500));

    // Test 2: Scheduled notification (30 seconds)
    await notificationService.scheduleTestIn30Seconds();
    scheduledSuccess = true;
    print("✅ Scheduled notification test completed");

    // Test 3: Test friend reminders using hasReminder
    for (final friend in provider.friends) {
      if (friend.hasReminder) {
        friendsWithReminders++;
        print("🔄 Testing reminder for ${friend.name} (${friend.usesAdvancedReminders ? 'Advanced' : 'Legacy'})");

        final success = await notificationService.scheduleReminder(friend);
        if (success) {
          friendsScheduledSuccessfully++;
          print("✅ Successfully scheduled for ${friend.name}");
        } else {
          print("❌ Failed to schedule for ${friend.name}");
        }
      }
    }

    friendReminderSuccess = friendsWithReminders == friendsScheduledSuccessfully;

  } catch (e) {
    print("❌ Error during notification tests: $e");
  }

  if (context.mounted) {
    Navigator.pop(context); // Close loading

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Notification Tests Complete',
          style: TextStyle(
            color: immediateSuccess && scheduledSuccess && friendReminderSuccess
                ? AppColors.success
                : AppColors.warning,
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
              // Immediate test
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: immediateSuccess ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      immediateSuccess ? CupertinoIcons.checkmark_circle : CupertinoIcons.xmark_circle,
                      color: immediateSuccess ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Immediate notification',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scheduled test
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: scheduledSuccess ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      scheduledSuccess ? CupertinoIcons.clock : CupertinoIcons.xmark_circle,
                      color: scheduledSuccess ? AppColors.warning : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Scheduled notification (30s)',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Friend reminders test
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: friendReminderSuccess ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      friendReminderSuccess ? CupertinoIcons.person_alt_circle : CupertinoIcons.exclamationmark_triangle,
                      color: friendReminderSuccess ? AppColors.success : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Friend reminders ($friendsScheduledSuccessfully/$friendsWithReminders)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                immediateSuccess && scheduledSuccess && friendReminderSuccess
                    ? 'All tests passed! You should receive notifications as expected.'
                    : friendsWithReminders == 0
                    ? 'Basic tests passed. Add friends with reminders to test the full system.'
                    : 'Some tests had issues. Check notification permissions and battery optimization settings.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: CupertinoColors.label,
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
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
}