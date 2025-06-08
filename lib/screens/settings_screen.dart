// lib/screens/settings_screen.dart - New dedicated settings page
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/colors.dart';
import '../widgets/illustrations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
        // Consistent outline button style
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Settings sections
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
                    // About section
                    _buildSettingsItem(
                      context,
                      icon: CupertinoIcons.info_circle,
                      title: 'About Alongside',
                      subtitle: 'Learn more about the app',
                      onTap: () => _showAboutDialog(context),
                    ),

                    // Divider
                    Container(
                      height: 0.5,
                      color: CupertinoColors.systemGrey5,
                      margin: const EdgeInsets.only(left: 66),
                    ),

                    // Privacy section (placeholder for future)
                    _buildSettingsItem(
                      context,
                      icon: CupertinoIcons.lock,
                      title: 'Privacy',
                      subtitle: 'All data stays on your device',
                      onTap: () => _showPrivacyInfo(context),
                    ),
                  ],
                ),
              ),

              const Spacer(),

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
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
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
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
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

  void _showAboutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: screenWidth * 0.95, // Increased from 0.92 to make it much wider
            constraints: const BoxConstraints(maxWidth: 400), // Added max width constraint
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
                    // Little illustration
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      width: double.infinity,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.lock_fill,
                              size: 16,
                              color: AppColors.tertiary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Everything stays on your device. It\'s private, secure, and fully in your control.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: CupertinoColors.label,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
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
            width: screenWidth * 0.95, // Made consistent with about dialog
            constraints: const BoxConstraints(maxWidth: 400), // Added max width constraint
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