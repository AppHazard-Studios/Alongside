// lib/screens/settings_screen.dart - Enhanced settings with all new features
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _lastBackupDate;
  bool _notificationSounds = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBackupDate = prefs.getString('last_backup_date');
      _notificationSounds = prefs.getBool('notification_sounds') ?? true;
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
                      color: isDestructive ? AppColors.error : CupertinoColors.label,
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

  // Settings actions
  void _testNotifications(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.scheduleTestNotification();

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(
            'Test Notification Scheduled',
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
              'You should receive a notification in 10 seconds. If you don\'t, check your notification settings.',
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

  // Replace these two methods in settings_screen.dart

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
    // Reload stats after import
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
                await BatteryOptimizationService.requestBatteryOptimization(context);
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

              // Clear all data
              final provider = Provider.of<FriendsProvider>(context, listen: false);
              final storageService = provider.storageService;

              // Clear friends - this will trigger provider to reload
              await storageService.saveFriends([]);
              await storageService.saveCustomMessages([]);

              // Clear preferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Cancel all notifications
              final notificationService = NotificationService();
              for (final friend in provider.friends) {
                await notificationService.cancelReminder(friend.id);
                await notificationService.removePersistentNotification(friend.id);
              }

              // Force reload the provider
              await provider.reloadFriends();

              // Close loading dialog
              if (mounted) {
                Navigator.pop(context);

                // Show success message
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
                          // Go back to home
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
                        '2. Disable battery optimization for Alongside',
                        '3. Make sure Do Not Disturb is off',
                        '4. Try the test notification feature',
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
          ...steps.map((step) => Padding(
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
          )).toList(),
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