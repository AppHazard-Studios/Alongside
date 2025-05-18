// lib/widgets/friend_card.dart - Fixed apostrophe issue
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/friends_provider.dart';
import '../models/friend.dart';
import '../screens/add_friend_screen.dart';
import '../screens/message_screen.dart';
import '../utils/text_styles.dart';
import '../utils/colors.dart';

class FriendCardNew extends StatefulWidget {
  final Friend friend;
  final bool isHighlighted;
  final bool isExpanded;
  final Function(String) onExpand;
  final int index;
  final Function(int, int)? onReorder;

  const FriendCardNew({
    Key? key,
    required this.friend,
    this.isHighlighted = false,
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

    // Initialize animation state based on expanded prop
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FriendCardNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animation when expanded state changes
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          // Clean iOS design
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
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.friend.reminderDays > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.friend.reminderDays}d',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemBlue,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Alongside them in section
                        if (widget.friend.helpingWith != null &&
                            widget.friend.helpingWith!.isNotEmpty) ...[
                          Text(
                            widget.friend.helpingWith!,
                            style: const TextStyle(
                              color: CupertinoColors.secondaryLabel,
                              fontSize: 15,
                              fontFamily: '.SF Pro Text',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        angle: value * 3.14, // Multiply by π for half rotation
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Separator line - Clean iOS style
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: CupertinoColors.systemGrey5,
                  ),

                  // "They're alongside you in:" section (if available)
                  if (widget.friend.theyHelpingWith != null &&
                      widget.friend.theyHelpingWith!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fixed: Using double quotes to avoid apostrophe issues
                          const Text(
                            "They're alongside you in:",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemBlue,
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
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: CupertinoColors.systemGrey5,
                    ),
                  ],

                  // Reminder section if reminder is set
                  if (widget.friend.reminderDays > 0) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder every ${widget.friend.reminderDays} ${widget.friend.reminderDays == 1 ? 'day' : 'days'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemOrange,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Reminders help you stay connected regularly',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: CupertinoColors.systemGrey5,
                    ),
                  ],

                  // Action buttons section - Clean iOS style
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        // Message button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            color: CupertinoColors.systemBlue,
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
                                  color: CupertinoColors.systemBlue,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    color: CupertinoColors.systemBlue,
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
                              color: CupertinoColors.systemBlue,
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
    // Fixed: Simple string cleaning without regex
    final phoneNumber = widget.friend.phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );
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

  // Create profile image - Clean iOS design
  Widget _buildProfileImage() {
    return Container(
      width: 60,
      height: 60,
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