// lib/widgets/friend_card.dart - Complete updated version with simplified reminders
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/friend.dart';
import '../screens/add_friend_screen.dart';
import '../screens/message_screen.dart';
import '../utils/colors.dart';
import '../providers/friends_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive_utils.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendCardNew extends StatefulWidget {
  final Friend friend;
  final bool isExpanded;
  final Function(String) onExpand;
  final int index;
  final Function(int, int)? onReorder;

  const FriendCardNew({
    Key? key,
    required this.friend,
    this.isExpanded = false,
    required this.onExpand,
    required this.index,
    this.onReorder,
  }) : super(key: key);

  @override
  State<FriendCardNew> createState() => _FriendCardNewState();
}

class _FriendCardNewState extends State<FriendCardNew>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isPressed = false;
  DateTime? _nextReminderTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }

    _loadNextReminderTime();
  }

  // Load next reminder time
  Future<void> _loadNextReminderTime() async {
    if (widget.friend.reminderDays > 0) {
      final notificationService = NotificationService();
      final nextTime = await notificationService.getNextReminderTime(widget.friend.id);
      if (mounted) {
        setState(() {
          _nextReminderTime = nextTime;
        });
      }
    }
  }

  // Helper method to format next reminder text
  String _getNextReminderText(DateTime? nextReminder) {
    if (nextReminder == null) return '';

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.isNegative) {
      return 'Reminder overdue';
    } else if (difference.inDays > 1) {
      return 'Next reminder in ${difference.inDays} days';
    } else if (difference.inDays == 1) {
      return 'Next reminder tomorrow';
    } else if (difference.inHours > 1) {
      return 'Next reminder in ${difference.inHours} hours';
    } else if (difference.inMinutes > 1) {
      return 'Next reminder in ${difference.inMinutes} minutes';
    } else {
      return 'Reminder coming soon';
    }
  }

  @override
  void didUpdateWidget(FriendCardNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
    if (widget.friend.reminderDays != oldWidget.friend.reminderDays ||
        widget.friend.reminderTime != oldWidget.friend.reminderTime) {
      _loadNextReminderTime();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    widget.onExpand(widget.friend.id);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _toggleExpand();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isPressed
            ? Matrix4.translationValues(0, 1, 0)
            : Matrix4.identity(),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main card content (always visible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileImage(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Friend name row with reminder badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.friend.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: '.SF Pro Text',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.friend.reminderDays > 0 &&
                                !widget.isExpanded) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.friend.reminderDays <= 30
                                      ? '${widget.friend.reminderDays}d'
                                      : widget.friend.reminderDays == 60
                                      ? '2mo'
                                      : widget.friend.reminderDays == 90
                                      ? '3mo'
                                      : '6mo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // "Alongside them in" info
                        if (widget.friend.helpingWith != null &&
                            widget.friend.helpingWith!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.heart_fill,
                                  color: AppColors.primary,
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Alongside them: ${widget.friend.helpingWith}",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontFamily: '.SF Pro Text',
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chevron icon that rotates when expanded
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: widget.isExpanded ? 0.5 : 0.0,
                    ),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 3.14,
                        child: const Icon(
                          CupertinoIcons.chevron_down,
                          color: CupertinoColors.systemGrey,
                          size: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Expandable details section
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    heightFactor: _expandAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Separator line
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: CupertinoColors.systemGrey5,
                  ),

                  // Integrated info section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "They're alongside you in" section
                        if (widget.friend.theyHelpingWith != null &&
                            widget.friend.theyHelpingWith!.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.tertiaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.person_2_fill,
                                  color: AppColors.tertiary,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Alongside you:",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.tertiary,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.friend.theyHelpingWith!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: CupertinoColors.label,
                                        fontFamily: '.SF Pro Text',
                                        height: 1.3,
                                      ),
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Reminder info with next reminder time
                        if (widget.friend.reminderDays > 0) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.bell_fill,
                                  color: AppColors.warning,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reminder ${AppConstants.formatReminderOption(widget.friend.reminderDays).toLowerCase()}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.warning,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.time,
                                          size: 12,
                                          color: CupertinoColors.secondaryLabel,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimeString(
                                              widget.friend.reminderTime),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color:
                                            CupertinoColors.secondaryLabel,
                                            fontFamily: '.SF Pro Text',
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_nextReminderTime != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _getNextReminderText(_nextReminderTime),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          fontFamily: '.SF Pro Text',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Action buttons section
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      ResponsiveUtils.scaledSpacing(context, 16),
                    ),
                    child: Row(
                      children: [
                        // Message button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () => _navigateToMessageScreen(context),
                            child: Container(
                              height:
                              ResponsiveUtils.scaledButtonHeight(context),
                              padding: ResponsiveUtils.scaledPadding(
                                context,
                                const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.bubble_left_fill,
                                    color: CupertinoColors.white,
                                    size: ResponsiveUtils.scaledIconSize(
                                        context, 16),
                                  ),
                                  SizedBox(
                                      width: ResponsiveUtils.scaledSpacing(
                                          context, 6)),
                                  Flexible(
                                    child: Text(
                                      'Message',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                        ResponsiveUtils.scaledFontSize(
                                            context, 15,
                                            maxScale: 1.3),
                                        fontFamily: '.SF Pro Text',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: ResponsiveUtils.scaledSpacing(context, 12)),
                        // Call button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () => _callFriend(context),
                            child: Container(
                              height:
                              ResponsiveUtils.scaledButtonHeight(context),
                              padding: ResponsiveUtils.scaledPadding(
                                context,
                                const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.phone_fill,
                                    color: AppColors.primary,
                                    size: ResponsiveUtils.scaledIconSize(
                                        context, 16),
                                  ),
                                  SizedBox(
                                      width: ResponsiveUtils.scaledSpacing(
                                          context, 6)),
                                  Flexible(
                                    child: Text(
                                      'Call',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize:
                                        ResponsiveUtils.scaledFontSize(
                                            context, 15,
                                            maxScale: 1.3),
                                        fontFamily: '.SF Pro Text',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: ResponsiveUtils.scaledSpacing(context, 12)),
                        // Edit button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => _navigateToEditScreen(context),
                          child: SizedBox(
                            width: ResponsiveUtils.scaledButtonHeight(context),
                            height: ResponsiveUtils.scaledButtonHeight(context),
                            child: Icon(
                              CupertinoIcons.pencil,
                              size: ResponsiveUtils.scaledIconSize(context, 18),
                              color: AppColors.primary,
                            ),
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
    );
  }

  // Convert 24h time format to 12h time format
  String _formatTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';

        // Convert to 12-hour format
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;

        return '$hour:$minute $period';
      }
    } catch (e) {
      // In case of parsing error, return original string
    }
    return timeStr;
  }

  // Navigate to MessageScreen
  void _navigateToMessageScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => MessageScreenNew(friend: widget.friend),
      ),
    );
  }

  // Navigate to EditScreen
  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AddFriendScreen(friend: widget.friend),
      ),
    );
  }

  // Call friend
  void _callFriend(BuildContext context) async {
    // Simplified phone number cleaning
    final phoneNumber =
    widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      // Track the call made
      final storageService =
          Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.incrementCallsMade();

      // Record action for reminder rescheduling
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_action_${widget.friend.id}', DateTime.now().millisecondsSinceEpoch);

      // Reschedule reminder
      final notificationService = NotificationService();
      await notificationService.scheduleReminder(widget.friend);

    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text(
              'Unable to open phone app. Please try again later.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Create profile image with consistent background
  Widget _buildProfileImage() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 60);
    final emojiSize =
    ResponsiveUtils.scaledIconSize(context, 30, maxScale: 1.3);

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: widget.friend.isEmoji
            ? CupertinoColors.systemGrey6
            : CupertinoColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      child: widget.friend.isEmoji
          ? Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              widget.friend.profileImage,
              style: TextStyle(fontSize: emojiSize),
            ),
          ),
        ),
      )
          : ClipOval(
        child: Image.file(
          File(widget.friend.profileImage),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}