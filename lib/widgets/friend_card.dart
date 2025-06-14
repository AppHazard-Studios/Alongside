// lib/widgets/friend_card.dart - Fixed text wrapping and consistent colors
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

class _FriendCardNewState extends State<FriendCardNew> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isPressed = false;

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
  }

  @override
  void didUpdateWidget(FriendCardNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
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
        transform: _isPressed ? Matrix4.translationValues(0, 1, 0) : Matrix4.identity(),
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
                crossAxisAlignment: CrossAxisAlignment.start, // Align to top for proper wrapping
                children: [
                  _buildProfileImage(),
                  const SizedBox(width: 16),
                  Expanded( // Important: This allows text to wrap properly
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Friend name row with reminder badge (only when collapsed)
// Friend name row with reminder badge (only when collapsed)
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
                  if (widget.friend.reminderDays > 0 && !widget.isExpanded) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                        // "Alongside them in" info - Always visible with proper wrapping
                        if (widget.friend.helpingWith != null &&
                            widget.friend.helpingWith!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight, // Use consistent primary color
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.heart_fill,
                                  color: AppColors.primary, // Use consistent primary color
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded( // Critical: This allows text to wrap properly
                                child: Text(
                                  "Alongside them: ${widget.friend.helpingWith}",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontFamily: '.SF Pro Text',
                                    height: 1.3, // Better line height for readability
                                  ),
                                  maxLines: 3, // Allow multiple lines
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
                        // "They're alongside you in" section with proper wrapping
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
                              Expanded( // Critical: This allows text to wrap properly
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
                                        height: 1.3, // Better line height
                                      ),
                                      maxLines: 5, // Allow multiple lines
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Reminder info with icon
// Reminder info with icon
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
                            _formatTimeString(widget.friend.reminderTime),
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
                      ],
                    ),
                  ),

                  // Action buttons section with consistent primary color
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        // Message button with consistent primary color
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: AppColors.primary, // Consistent primary color for all friends
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () => _navigateToMessageScreen(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.bubble_left_fill,
                                  color: CupertinoColors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Call button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () => _callFriend(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.phone_fill,
                                  color: AppColors.primary, // Consistent primary color
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    color: AppColors.primary, // Consistent primary color
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Edit button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => _navigateToEditScreen(context),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              CupertinoIcons.pencil,
                              size: 18,
                              color: AppColors.primary, // Consistent primary color
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
// Call friend
  void _callFriend(BuildContext context) async {
    // Simplified phone number cleaning
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      // Track the call made
      final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.incrementCallsMade();
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
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.friend.isEmoji
            ? CupertinoColors.systemGrey6  // Consistent emoji background
            : CupertinoColors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      child: widget.friend.isEmoji
          ? Center(
        child: Text(
          widget.friend.profileImage,
          style: const TextStyle(fontSize: 30),
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