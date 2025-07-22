// lib/screens/settings_screen.dart - COMPLETE UPDATED FILE WITH ALL DESIGN FIXES
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';
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
      backgroundColor: const Color(0xFFF8FAFC), // Match home screen background
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // FIXED: Integrated header with X button on right, title left-aligned
            SliverToBoxAdapter(
              child: _buildIntegratedHeader(),
            ),

            // Main settings content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                ),
                child: Column(
                  children: [
                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),

                    // Security section
                    _buildSection(
                      title: 'SECURITY',
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
                            iconColor: AppColors.primary,
                            title: 'Change Lock Method',
                            subtitle: 'Switch between PIN and biometrics',
                            onTap: () => _changeLockMethod(),
                          ),
                          _buildDivider(),
                          _buildDivider(),
                          _buildSettingsItem(
                            context,
                            icon: CupertinoIcons.timer,
                            iconColor: AppColors.primary,
                            title: 'Lock Cooldown',
                            subtitle: 'Lock after $_lockCooldownMinutes minutes in background',
                            onTap: () => _showCooldownPicker(),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

                    // Backup & Restore section
                    _buildSection(
                      title: 'BACKUP & RESTORE',
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.arrow_up_circle,
                          iconColor: AppColors.primary,
                          title: 'Export Data',
                          subtitle: 'Save friends and messages to file',
                          onTap: () => _exportData(context),
                        ),
                        _buildDivider(),
                        _buildDivider(),
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.arrow_down_circle,
                          iconColor: AppColors.primary,
                          title: 'Import Data',
                          subtitle: 'Restore from backup file',
                          onTap: () => _importData(context),
                        ),
                        if (_lastBackupDate != null) ...[
                          _buildDivider(),
                          Padding(
                            padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: ResponsiveUtils.scaledIconSize(context, 16),
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                                Text(
                                  'Last backup: $_lastBackupDate',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.scaledFontSize(context, 14),
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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

                    // Advanced section
                    _buildSection(
                      title: 'ADVANCED',
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.battery_25,
                          iconColor: AppColors.primary, // FIXED: Changed from warning to primary
                          title: 'Battery Optimisation',
                          subtitle: 'Ensure notifications work properly',
                          onTap: () => _showBatteryOptimization(context),
                        ),
                        _buildDivider(),
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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

                    // About section
                    _buildSection(
                      title: 'ABOUT',
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
                        _buildDivider(),
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.lock,
                          iconColor: AppColors.primary,
                          title: 'Privacy',
                          subtitle: 'All data stays on your device',
                          onTap: () => _showPrivacyInfo(context),
                        ),
                        _buildDivider(),
                        _buildDivider(),
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.question_circle,
                          iconColor: AppColors.primary,
                          title: 'Troubleshooting',
                          subtitle: 'Help with common issues',
                          onTap: () => _showTroubleshooting(context),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 32)),

                    // App info footer (matches home screen style)
                    _buildAppInfoFooter(),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Header with X button on right, title left-aligned like home screen
// FIXED: Header with primary color settings icon matching home screen style
  Widget _buildIntegratedHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.scaledSpacing(context, 16),
        ResponsiveUtils.scaledSpacing(context, 16),
        ResponsiveUtils.scaledSpacing(context, 16),
        ResponsiveUtils.scaledSpacing(context, 12),
      ),
      child: Column(
        children: [
          // Top row with title left-aligned and X button on right
          Row(
            children: [
              // Title with icon (left-aligned like home screen)
              Row(
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.scaledFontSize(context, 28, maxScale: 1.4),
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Container(
                    width: ResponsiveUtils.scaledContainerSize(context, 28),
                    height: ResponsiveUtils.scaledContainerSize(context, 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.gear_solid,
                      size: ResponsiveUtils.scaledIconSize(context, 16),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // X button on right (matches home screen button style)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  width: ResponsiveUtils.scaledContainerSize(context, 36),
                  height: ResponsiveUtils.scaledContainerSize(context, 36),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10), // Rounded square like home screen
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Section builder matching home screen style
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.only(
            left: ResponsiveUtils.scaledSpacing(context, 8),
            bottom: ResponsiveUtils.scaledSpacing(context, 8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 13),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),

        // Section container (matches home screen card style)
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // NEW: App info footer matching home screen style
  Widget _buildAppInfoFooter() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 24)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: ResponsiveUtils.scaledContainerSize(context, 60),
            height: ResponsiveUtils.scaledContainerSize(context, 60),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.heart_fill,
              size: ResponsiveUtils.scaledIconSize(context, 30),
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
          Text(
            'Alongside',
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 18),
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: '.SF Pro Text',
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 4)),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 14),
              color: AppColors.textSecondary,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

// FIXED: Full-width solid divider like iOS standard
  Widget _buildDivider() {
    return Container(
      height: 0.5,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.1),
      margin: EdgeInsets.zero, // No margin to ensure full width
    );
  }
  // FIXED: Icons now use rounded squares (like home screen) instead of circles
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
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.scaledSpacing(context, 16),
          vertical: ResponsiveUtils.scaledSpacing(context, 16),
        ),
        child: Row(
          children: [
            // FIXED: Changed from circle to rounded square like home screen
            Container(
              width: ResponsiveUtils.scaledContainerSize(context, 38),
              height: ResponsiveUtils.scaledContainerSize(context, 38),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10), // Rounded square instead of circle
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveUtils.scaledIconSize(context, 18),
              ),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? AppColors.error : CupertinoColors.label,
                      fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                      fontWeight: FontWeight.w500,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveUtils.scaledFontSize(context, 14),
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.textSecondary,
                size: ResponsiveUtils.scaledIconSize(context, 16),
              ),
          ],
        ),
      ),
    );
  }

  // FIXED: Icons now use rounded squares (like home screen) instead of circles
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 16),
        vertical: ResponsiveUtils.scaledSpacing(context, 12),
      ),
      child: Row(
        children: [
          // FIXED: Changed from circle to rounded square like home screen
          Container(
            width: ResponsiveUtils.scaledContainerSize(context, 38),
            height: ResponsiveUtils.scaledContainerSize(context, 38),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10), // Rounded square instead of circle
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: ResponsiveUtils.scaledIconSize(context, 18),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: CupertinoColors.label,
                    fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                    fontWeight: FontWeight.w500,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveUtils.scaledFontSize(context, 14),
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
                    CupertinoIcons.lock_shield,
                    color: CupertinoColors.systemBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Biometric Lock (Face ID / Touch ID)',
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
                  'PIN Lock (4 digits)',
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
    final pinFocusNode = FocusNode();
    final confirmFocusNode = FocusNode();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Set 4-Digit PIN',
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
                focusNode: pinFocusNode,
                placeholder: 'Enter 4-digit PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
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
                onChanged: (value) {
                  if (value.length == 4) {
                    confirmFocusNode.requestFocus();
                  }
                },
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: confirmController,
                focusNode: confirmFocusNode,
                placeholder: 'Confirm PIN',
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
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

    Future.delayed(const Duration(milliseconds: 300), () {
      pinFocusNode.requestFocus();
    });
  }

  void _processPinSetup(String pin, String confirmPin) async {
    if (pin.length != 4) {
      _showErrorSnackBar('PIN must be exactly 4 digits');
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _showErrorSnackBar('PIN must contain only numbers');
      return;
    }

    if (pin != confirmPin) {
      _showErrorSnackBar('PINs do not match');
      return;
    }

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
        Navigator.pop(context);

        if (success) {
          await _loadSettings();
          _showSuccessSnackBar('4-digit PIN enabled successfully');
        } else {
          _showErrorSnackBar('Failed to set PIN');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Error setting PIN: ${e.toString()}');
      }
    }
  }

  void _setupBiometric() async {
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
      final isAvailable = await _lockService.isBiometricAvailable();

      if (!isAvailable) {
        if (mounted) {
          Navigator.pop(context);
          _showDetailedErrorDialog(
            'Biometric Not Available',
            'Your device does not support biometric authentication or no biometric data is enrolled. Please set up Face ID or Touch ID in your device settings first.',
          );
        }
        return;
      }

      final result = await _lockService.enableBiometricLockWithoutTest();

      if (mounted) {
        Navigator.pop(context);

        if (result.success) {
          await _loadSettings();

          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text(
                'Biometric Lock Enabled',
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
                  'Biometric authentication has been enabled successfully. Would you like to test it now?',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: CupertinoColors.label,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _testBiometricAuthentication();
                  },
                  child: const Text(
                    'Test Now',
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
        } else {
          _showDetailedErrorDialog(
            'Biometric Setup Failed',
            result.error ?? 'Unknown error occurred while setting up biometric authentication.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showDetailedErrorDialog(
          'Biometric Setup Error',
          'Failed to set up biometric lock: ${e.toString()}',
        );
      }
    }
  }

  void _testBiometricAuthentication() async {
    try {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            width: 140,
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
                  'Testing biometric\nauthentication...',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 14,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      final authenticated = await _lockService.authenticateBiometric();

      if (mounted) {
        Navigator.pop(context);

        if (authenticated) {
          _showSuccessSnackBar('Biometric authentication test successful! ✅');
        } else {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text(
                'Authentication Failed',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              content: const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Biometric authentication failed, but the lock is still enabled. You may need to authenticate using your device passcode when the app locks.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: CupertinoColors.label,
                    fontFamily: '.SF Pro Text',
                  ),
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
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showDetailedErrorDialog(
          'Test Failed',
          'Could not test biometric authentication: ${e.toString()}',
        );
      }
    }
  }

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
                _showPinSetup();
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

  // FIXED: More iOS-native picker with better fonts and styling
// IMPROVED: More precise iOS-native picker styling
// IMPROVED: More precise iOS-native picker styling
  void _showCooldownPicker() {
    final options = [0, 1, 5, 10, 15, 30, 60];
    int selectedMinutes = _lockCooldownMinutes;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300, // Slightly taller for better proportions
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            // iOS-style header - exact iOS dimensions
            Container(
              height: 64, // More standard iOS header height
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.33, // iOS standard separator thickness
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 17, // iOS standard
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Lock Cooldown',
                    style: TextStyle(
                      fontSize: 18, // Slightly larger for better hierarchy
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: CupertinoColors.systemBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
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
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 44, // Exact iOS standard picker item height
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
                      style: const TextStyle(
                        fontSize: 20, // Adjusted to better match your app's sizing
                        fontFamily: '.SF Pro Text',
                        color: CupertinoColors.label,
                        fontWeight: FontWeight.w400, // iOS default weight
                      ),
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
      builder: (context) => DraggableScrollableSheet(
        // CONTENT-AWARE HEIGHT - like real iOS apps
        initialChildSize: hasPermission ? 0.4 : 0.65, // Smaller when unrestricted, larger when restricted
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header with status badge
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Battery Optimisations',
                              style: TextStyle(
                                fontSize: 18,
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
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (hasPermission ? AppColors.success : AppColors.warning).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasPermission ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.exclamationmark_triangle_fill,
                                  color: Colors.white,
                                  size: 14,
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
                  ],
                ),
              ),

              // Content - sizes naturally
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Key: don't take more space than needed
                    children: [
                      // Status container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasPermission
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasPermission
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.warning.withOpacity(0.2),
                            width: 1,
                          ),
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

                      // Only show guide when restricted (saves space when unrestricted)
                      if (!hasPermission) ...[
                        const SizedBox(height: 16),
                        BatteryOptimizationService.buildBatteryOptimizationGuide(context),
                      ],

                      const SizedBox(height: 16),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () async {
                              Navigator.pop(context);
                              if (hasPermission) {
                                openAppSettings();
                              } else {
                                await BatteryOptimizationService.requestBatteryOptimization(context);
                              }
                            },
                            child: Text(
                              hasPermission ? 'View App Settings' : 'Remove Battery Restrictions',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

              await storageService.saveFriends([]);
              await storageService.saveCustomMessages([]);

              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              final notificationService = NotificationService();
              for (final friend in provider.friends) {
                await notificationService.cancelReminder(friend.id);
                await notificationService.removePersistentNotification(friend.id);
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
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple header - let DraggableScrollableSheet handle all drag functionality
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Troubleshooting Guide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection(String title, List<String> steps) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16, // Match your app's sizing
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
            ),
            const SizedBox(height: 12),
            ...steps
                .map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                step,
                style: const TextStyle(
                  fontSize: 14, // Match your app's sizing
                  color: AppColors.textSecondary,
                  fontFamily: '.SF Pro Text',
                  height: 1.4,
                ),
              ),
            ))
                .toList(),
          ],
        ),
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