// lib/screens/settings_screen.dart - FIXED FOR COMPLETE CONSISTENCY WITH ADD_FRIEND_SCREEN
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/text_styles.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header matching add_friend_screen pattern exactly
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 12),
                ),
                child: Row(
                  children: [
                    // Title area - takes available space
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title with overflow protection
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Settings',
                                style: AppTextStyles.scaledAppTitle(context),
                                maxLines: 1,
                              ),
                            ),
                          ),

                          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

                          // Settings icon matching add_friend_screen pattern
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
                    ),

                    // Fixed spacing between title and X button
                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 16)),

                    // X button - matching add_friend_screen exactly
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: ResponsiveUtils.scaledContainerSize(context, 32),
                        height: ResponsiveUtils.scaledContainerSize(context, 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
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
                          size: ResponsiveUtils.scaledIconSize(context, 16),
                          color: AppColors.primary,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

                    // Backup section
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
                            padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 12)),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: ResponsiveUtils.scaledIconSize(context, 14),
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                                Text(
                                  'Last backup: $_lastBackupDate',
                                  style: AppTextStyles.scaledSubhead(context).copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

                    // Advanced section
                    _buildSection(
                      title: 'ADVANCED',
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.battery_25,
                          iconColor: AppColors.primary,
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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

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
                        _buildSettingsItem(
                          context,
                          icon: CupertinoIcons.lock,
                          iconColor: AppColors.primary,
                          title: 'Privacy',
                          subtitle: 'All data stays on your device',
                          onTap: () => _showPrivacyInfo(context),
                        ),
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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

                    _buildAppInfoFooter(),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: ResponsiveUtils.scaledSpacing(context, 8),
            bottom: ResponsiveUtils.scaledSpacing(context, 8),
          ),
          child: Text(
            title,
            style: AppTextStyles.scaledSectionHeader(context),
          ),
        ),

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

  Widget _buildAppInfoFooter() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 20)),
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
            width: ResponsiveUtils.scaledContainerSize(context, 50),
            height: ResponsiveUtils.scaledContainerSize(context, 50),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.heart_fill,
              size: ResponsiveUtils.scaledIconSize(context, 25),
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
          Text(
            'Alongside',
            style: AppTextStyles.scaledHeadline(context).copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 3)),
          Text(
            'Version 1.0.0',
            style: AppTextStyles.scaledSubhead(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.15),
      margin: EdgeInsets.zero,
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
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.scaledSpacing(context, 16),
          vertical: ResponsiveUtils.scaledSpacing(context, 6), // 🔧 FIXED: Match add_friend_screen padding
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 🔧 FIXED: Top alignment like add_friend_screen
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.scaledSpacing(context, 2), // 🔧 FIXED: Consistent top padding
              ),
              child: Container(
                width: ResponsiveUtils.scaledContainerSize(context, 32), // 🔧 FIXED: Match add_friend_screen icon size
                height: ResponsiveUtils.scaledContainerSize(context, 32),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: iconColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: ResponsiveUtils.scaledIconSize(context, 16), // 🔧 FIXED: Match add_friend_screen icon size
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.scaledCallout(context).copyWith(
                      color: isDestructive ? AppColors.error : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.scaledSubhead(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveUtils.scaledSpacing(context, 8), // 🔧 FIXED: Center with text content
                ),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.textSecondary,
                  size: ResponsiveUtils.scaledIconSize(context, 14),
                ),
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
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 16),
        vertical: ResponsiveUtils.scaledSpacing(context, 6), // 🔧 FIXED: Match add_friend_screen padding
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 🔧 FIXED: Top alignment like add_friend_screen
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.scaledSpacing(context, 2), // 🔧 FIXED: Consistent top padding
            ),
            child: Container(
              width: ResponsiveUtils.scaledContainerSize(context, 32), // 🔧 FIXED: Match add_friend_screen icon size
              height: ResponsiveUtils.scaledContainerSize(context, 32),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveUtils.scaledIconSize(context, 16), // 🔧 FIXED: Match add_friend_screen icon size
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.scaledCallout(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.scaledSubhead(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.scaledSpacing(context, 8), // 🔧 FIXED: Center switch with text content
            ),
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
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
          title: Text(
            'Disable App Lock',
            style: AppTextStyles.scaledDialogTitle(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Padding(
            padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
            child: Text(
              'Are you sure you want to disable app lock?',
              style: AppTextStyles.scaledCallout(context).copyWith(
                height: 1.4,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.scaledButton(context).copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
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
              child: Text(
                'Disable',
                style: AppTextStyles.scaledButton(context).copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
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
        title: Text(
          'Choose Lock Method',
          style: AppTextStyles.scaledCallout(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary, // 🔧 FIXED: Proper text color
          ),
        ),
        message: Text(
          'Select how you want to secure the app',
          style: AppTextStyles.scaledSubhead(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          if (biometricAvailable)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _setupBiometric();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.lock_shield,
                    color: AppColors.primary,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Text(
                    'Biometric Lock (Face ID / Touch ID)',
                    style: AppTextStyles.scaledCallout(context).copyWith(
                      color: AppColors.textPrimary, // 🔧 FIXED: Proper text color
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.number,
                  color: AppColors.primary,
                  size: ResponsiveUtils.scaledIconSize(context, 18),
                ),
                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                Text(
                  'PIN Lock (4 digits)',
                  style: AppTextStyles.scaledCallout(context).copyWith(
                    color: AppColors.textPrimary, // 🔧 FIXED: Proper text color
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: Text(
            'Cancel',
            style: AppTextStyles.scaledButton(context).copyWith(
              color: AppColors.error, // 🔧 FIXED: Proper cancel button color
              fontWeight: FontWeight.w600,
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
        title: Text(
          'Set 4-Digit PIN',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
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
                style: AppTextStyles.scaledHeadline(context).copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.scaledSpacing(context, 12),
                    horizontal: ResponsiveUtils.scaledSpacing(context, 16)
                ),
                onChanged: (value) {
                  if (value.length == 4) {
                    confirmFocusNode.requestFocus();
                  }
                },
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
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
                style: AppTextStyles.scaledHeadline(context).copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.scaledSpacing(context, 12),
                    horizontal: ResponsiveUtils.scaledSpacing(context, 16)
                ),
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
            child: Text(
              'Cancel',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _processPinSetup(pinController.text, confirmController.text);
              Navigator.pop(context);
            },
            child: Text(
              'Set PIN',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
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
          width: ResponsiveUtils.scaledContainerSize(context, 100),
          height: ResponsiveUtils.scaledContainerSize(context, 100),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CupertinoActivityIndicator(
                color: Colors.white,
                radius: 12,
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
              Text(
                'Setting PIN...',
                style: AppTextStyles.scaledSubhead(context).copyWith(
                  color: Colors.white,
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
          width: ResponsiveUtils.scaledContainerSize(context, 120),
          height: ResponsiveUtils.scaledContainerSize(context, 120),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CupertinoActivityIndicator(
                color: Colors.white,
                radius: 14,
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
              Text(
                'Setting up\nBiometric Lock',
                style: AppTextStyles.scaledSubhead(context).copyWith(
                  color: Colors.white,
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
              title: Text(
                'Biometric Lock Enabled',
                style: AppTextStyles.scaledDialogTitle(context).copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Padding(
                padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
                child: Text(
                  'Biometric authentication has been enabled successfully. Would you like to test it now?',
                  style: AppTextStyles.scaledCallout(context).copyWith(
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Later',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _testBiometricAuthentication();
                  },
                  child: Text(
                    'Test Now',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
            width: ResponsiveUtils.scaledContainerSize(context, 120),
            height: ResponsiveUtils.scaledContainerSize(context, 100),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 12,
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
                Text(
                  'Testing biometric\nauthentication...',
                  style: AppTextStyles.scaledSubhead(context).copyWith(
                    color: Colors.white,
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
              title: Text(
                'Authentication Failed',
                style: AppTextStyles.scaledDialogTitle(context).copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Padding(
                padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
                child: Text(
                  'Biometric authentication failed, but the lock is still enabled. You may need to authenticate using your device passcode when the app locks.',
                  style: AppTextStyles.scaledCallout(context).copyWith(
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Text(
            message,
            style: AppTextStyles.scaledCallout(context).copyWith(
              height: 1.4,
              color: AppColors.textPrimary,
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
              child: Text(
                'Use PIN Instead',
                style: AppTextStyles.scaledButton(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
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
        title: Text(
          'Success',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Text(
            message,
            style: AppTextStyles.scaledCallout(context).copyWith(
              height: 1.4,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
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
        title: Text(
          'Error',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Text(
            message,
            style: AppTextStyles.scaledCallout(context).copyWith(
              height: 1.4,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCooldownPicker() {
    final options = [0, 1, 5, 10, 15, 30, 60];
    int selectedMinutes = _lockCooldownMinutes;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: ResponsiveUtils.scaledContainerSize(context, 280),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              height: ResponsiveUtils.scaledContainerSize(context, 56),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE5E5EA),
                    width: 0.33,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scaledSpacing(context, 16)),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.scaledHeadline(context).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // 🔧 FIXED: Completely removed middle text as requested
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scaledSpacing(context, 16)),
                    child: Text(
                      'Done',
                      style: AppTextStyles.scaledHeadline(context).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
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
                itemExtent: ResponsiveUtils.scaledContainerSize(context, 36),
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
                      // 🔧 FIXED: Use scaled text style instead of raw TextStyle
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
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

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.battery_25,
              color: AppColors.primary,
              size: ResponsiveUtils.scaledIconSize(context, 16), // 🔧 FIXED: Scale with text properly
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
            // 🔧 FIXED: Prevent text overflow with Flexible
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Battery Settings',
                  style: AppTextStyles.scaledDialogTitle(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔧 FIXED: Responsive status indicator with proper centering
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // 🔧 FIXED: Icon and status with proper responsive layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasPermission
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.exclamationmark_triangle_fill,
                          color: AppColors.primary,
                          size: ResponsiveUtils.scaledIconSize(context, 18), // 🔧 FIXED: Scales with text
                        ),
                        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                        // 🔧 FIXED: Prevent "Unrestricted" overflow with Flexible
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hasPermission ? 'Unrestricted' : 'Restricted',
                              style: AppTextStyles.scaledCallout(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),

                    // Simple explanation - also prevent overflow
                    Text(
                      hasPermission
                          ? 'Reminders will work reliably'
                          : 'Reminders may be delayed or missed',
                      style: AppTextStyles.scaledSubhead(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, // 🔧 FIXED: Prevent overflow
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              if (hasPermission) {
                await openAppSettings();
              } else {
                await BatteryOptimizationService.requestBatteryOptimization(context);
              }
            },
            child: Text(
              hasPermission ? 'App Settings' : 'Allow Background',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAppData(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Clear All Data',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Text(
            'This will permanently delete all your friends and custom messages. This action cannot be undone.',
            style: AppTextStyles.scaledCallout(context).copyWith(
              height: 1.4,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(
              'Cancel',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
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
                    width: ResponsiveUtils.scaledContainerSize(context, 100),
                    height: ResponsiveUtils.scaledContainerSize(context, 100),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CupertinoActivityIndicator(
                          color: Colors.white,
                          radius: 12,
                        ),
                        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
                        Text(
                          'Clearing...',
                          style: AppTextStyles.scaledCallout(context).copyWith(
                            color: Colors.white,
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
                    title: Text(
                      'Data Cleared',
                      style: AppTextStyles.scaledDialogTitle(context).copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: Padding(
                      padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
                      child: Text(
                        'All app data has been cleared successfully.',
                        style: AppTextStyles.scaledCallout(context).copyWith(
                          height: 1.4,
                          color: AppColors.textPrimary,
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
                        child: Text(
                          'OK',
                          style: AppTextStyles.scaledButton(context).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            isDestructiveAction: true,
            child: Text(
              'Clear All Data',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
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
        initialChildSize: 0.45, // 🔧 FIXED: Reduced size since we removed a section
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 8)),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                          top: ResponsiveUtils.scaledSpacing(context, 8),
                          bottom: ResponsiveUtils.scaledSpacing(context, 16)
                      ),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scaledSpacing(context, 20)),
                      child: Text(
                        'Troubleshooting Guide',
                        style: AppTextStyles.scaledHeadline(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.scaledSpacing(context, 20),
                      ResponsiveUtils.scaledSpacing(context, 10),
                      ResponsiveUtils.scaledSpacing(context, 20),
                      ResponsiveUtils.scaledSpacing(context, 20)
                  ),
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
                          '4. Restart your device and try again',
                        ],
                      ),
                      _buildTroubleshootingSection(
                        'Can\'t send messages or make calls?',
                        [
                          '1. Check that phone numbers are entered correctly',
                          '2. Ensure you have a default messaging/phone app set',
                          '3. Check app permissions for phone and SMS',
                          '4. Try restarting the messaging app',
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
      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 14)),
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
              style: AppTextStyles.scaledCallout(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
            ...steps
                .map((step) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 5)),
              child: Text(
                step,
                style: AppTextStyles.scaledSubhead(context).copyWith(
                  color: AppColors.textSecondary,
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
            width: screenWidth * 0.95,
            constraints: const BoxConstraints(maxWidth: 380),
            child: CupertinoAlertDialog(
              title: Text(
                'About Alongside',
                style: AppTextStyles.scaledDialogTitle(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Padding(
                padding: EdgeInsets.only(
                    top: ResponsiveUtils.scaledSpacing(context, 16),
                    bottom: ResponsiveUtils.scaledSpacing(context, 6)
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 14)),
                      child: Container(
                        width: ResponsiveUtils.scaledContainerSize(context, 70),
                        height: ResponsiveUtils.scaledContainerSize(context, 70),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Illustrations.friendsIllustration(size: ResponsiveUtils.scaledContainerSize(context, 70)),
                      ),
                    ),
                    Text(
                      'Alongside helps you walk with your friends through the highs and lows of life.',
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 14)),
                    Text(
                      'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 14)),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
            width: screenWidth * 0.98,
            constraints: const BoxConstraints(maxWidth: 380),
            child: CupertinoAlertDialog(
              title: Text(
                'Privacy & Security',
                style: AppTextStyles.scaledDialogTitle(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Padding(
                padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
                child: Text(
                  'Alongside is designed with privacy in mind. All your data is stored locally on your device and never shared with third parties. Your conversations and friend information remain completely private.',
                  style: AppTextStyles.scaledCallout(context).copyWith(
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Got it',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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