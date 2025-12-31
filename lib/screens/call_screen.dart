// lib/screens/call_screen.dart - FIXED WITH SCALED TEXT STYLES

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/friend.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../utils/ui_constants.dart';
import '../utils/colors.dart';
import '../providers/friends_provider.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallScreen extends StatefulWidget {
  final Friend friend;

  const CallScreen({Key? key, required this.friend}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Launch the call immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateCall();
    });
  }

  Future<void> _initiateCall() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final phoneNumber =
      widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final telUri = Uri.parse('tel:$phoneNumber');

      final launched = await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch phone app');
      }

      // Track the call made
      final storageService =
          Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.incrementCallsMade();

      // CRITICAL: Record friend interaction for reminder scheduling
      await _recordCallInteraction();

      // Return to home screen after initiating call
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Unable to launch phone call. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // ADD this new method to the _CallScreenState class
  Future<void> _recordCallInteraction() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if this was opened from a notification
      final pendingAction = prefs.getString('pending_notification_action');
      if (pendingAction == null || !pendingAction.contains(widget.friend.id)) {
        // Manual action - record it
        await prefs.setInt('last_action_${widget.friend.id}', DateTime.now().millisecondsSinceEpoch);

        // Reschedule reminder
        final notificationService = NotificationService();
        await notificationService.scheduleReminder(widget.friend);

        print("📞 Manual call action recorded for ${widget.friend.name}");
      }
    } catch (e) {
      print("❌ Error recording call interaction: $e");
    }
  }

  // ADD this method to both MessageScreen and CallScreen classes

  @override
  Widget build(BuildContext context) {
    // Using Scaffold but with iOS styling
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: Text(
          'Call ${widget.friend.name}',
          style: AppTextStyles.scaledNavTitle(context),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.screenPadding * 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const CupertinoActivityIndicator(radius: 14),
                  const SizedBox(height: 24),
                  Text(
                    'Initiating call to ${widget.friend.name}...',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.scaledBody(context),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ] else if (_hasError) ...[
                  const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    size: 56,
                    color: CupertinoColors.destructiveRed,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.scaledBody(context),
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    onPressed: _initiateCall,
                    child: const Text('Try Again'),
                  ),
                ] else ...[
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.phone_fill,
                      size: 48,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ready to call ${widget.friend.name}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.scaledTitle2(context),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.friend.phoneNumber,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.scaledBody(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CupertinoButton.filled(
                    onPressed: _initiateCall,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.phone_fill, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Call Now',
                          style: AppTextStyles.scaledButton(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}