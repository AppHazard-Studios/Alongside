// lib/widgets/friend_card.dart - REQUIRED REMINDERS + PERFECT ALIGNMENT
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  bool _isMessagePressed = false;
  bool _isCallPressed = false;
  DateTime? _nextReminderTime;
  bool _isLoadingReminderTime = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
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

  Future<void> _loadNextReminderTime() async {
    // Since reminders are now required, this should always have a value
    setState(() {
      _isLoadingReminderTime = true;
    });

    try {
      final notificationService = NotificationService();
      final nextTime = await notificationService.getNextReminderTime(widget.friend.id);

      if (nextTime == null) {
        await notificationService.scheduleReminder(widget.friend);
        final newNextTime = await notificationService.getNextReminderTime(widget.friend.id);
        if (mounted) {
          setState(() {
            _nextReminderTime = newNextTime;
            _isLoadingReminderTime = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _nextReminderTime = nextTime;
            _isLoadingReminderTime = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nextReminderTime = null;
          _isLoadingReminderTime = false;
        });
      }
    }
  }

  String _getFixedWidthReminderText(DateTime? nextReminder) {
    if (nextReminder == null) return '---'; // Fallback if no reminder somehow

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.isNegative) {
      return 'now'; // 3 characters
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).round().clamp(1, 6);
      return '${months}mo'; // 1mo, 2mo, 3mo, 4mo, 5mo, 6mo
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d'; // 1d, 2d, 3d, ... 29d
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h'; // 1h, 2h, ... 23h
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m'; // 1m, 2m, ... 59m
    } else {
      return 'now'; // 3 characters
    }
  }

  Color _getReminderColor(DateTime? nextReminder) {
    if (nextReminder == null) return AppColors.primary;

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.inDays == 0 && difference.inHours <= 1) {
      return AppColors.warning; // Urgent reminder
    } else {
      return AppColors.primary;
    }
  }

  @override
  void didUpdateWidget(FriendCardNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
    if (widget.friend.reminderTime != oldWidget.friend.reminderTime ||
        widget.friend.reminderData != oldWidget.friend.reminderData) {
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
    HapticFeedback.lightImpact();
  }

  void _showActionMenu() {
    HapticFeedback.mediumImpact();
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final totalFriends = provider.friends.length;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          widget.friend.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToMessageScreen(context);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.bubble_left_fill,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Text(
                  'Send Message',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _callFriend(context);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.phone_fill,
                  color: AppColors.tertiary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Text(
                  'Call',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppColors.tertiary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),

          // Single reorder option (only show if more than 1 friend)
          if (totalFriends > 1)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showReorderMenu();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Reorder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),

          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditScreen(context);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  void _showReorderMenu() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final totalFriends = provider.friends.length;
    final isFirst = widget.index == 0;
    final isLast = widget.index == totalFriends - 1;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Reorder ${widget.friend.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          if (!isFirst)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _moveToTop();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_up_to_line,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Move to Top',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          if (!isFirst)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _moveUp();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_up,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Move Up',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          if (!isLast)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _moveDown();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_down,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Move Down',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          if (!isLast)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _moveToBottom();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_down_to_line,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Move to Bottom',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  void _moveToTop() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final currentFriends = List<Friend>.from(provider.friends);
    final friend = currentFriends.removeAt(widget.index);
    currentFriends.insert(0, friend);
    provider.reorderFriends(currentFriends);
    HapticFeedback.lightImpact();
  }

  void _moveUp() {
    if (widget.index > 0) {
      final provider = Provider.of<FriendsProvider>(context, listen: false);
      final currentFriends = List<Friend>.from(provider.friends);
      final friend = currentFriends.removeAt(widget.index);
      currentFriends.insert(widget.index - 1, friend);
      provider.reorderFriends(currentFriends);
      HapticFeedback.lightImpact();
    }
  }

  void _moveDown() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    if (widget.index < provider.friends.length - 1) {
      final currentFriends = List<Friend>.from(provider.friends);
      final friend = currentFriends.removeAt(widget.index);
      currentFriends.insert(widget.index + 1, friend);
      provider.reorderFriends(currentFriends);
      HapticFeedback.lightImpact();
    }
  }

  void _moveToBottom() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final currentFriends = List<Friend>.from(provider.friends);
    final friend = currentFriends.removeAt(widget.index);
    currentFriends.add(friend);
    provider.reorderFriends(currentFriends);
    HapticFeedback.lightImpact();
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
      onLongPress: _showActionMenu,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        margin: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.scaledSpacing(context, 4),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(widget.isExpanded ? 0.95 : 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(widget.isExpanded ? 0.15 : 0.1),
            width: widget.isExpanded ? 1.5 : 1,
          ),
          boxShadow: widget.isExpanded ? [
            // Subtle extra shadow for expanded cards
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : [
            // Standard subtle shadow for collapsed cards
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main card content with cohesive layout
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 14)),
              child: Row(
                children: [
                  _buildProfileImage(),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),

                  Expanded(
                    child: _buildNameWithReminder(),
                  ),

                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Message button
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isMessagePressed = true),
                        onTapUp: (_) {
                          setState(() => _isMessagePressed = false);
                          HapticFeedback.lightImpact();
                          _navigateToMessageScreen(context);
                        },
                        onTapCancel: () => setState(() => _isMessagePressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: _isMessagePressed
                              ? Matrix4.translationValues(0, 1, 0)
                              : Matrix4.identity(),
                          width: ResponsiveUtils.scaledContainerSize(context, 32),
                          height: ResponsiveUtils.scaledContainerSize(context, 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isMessagePressed ? [
                                AppColors.primary.withOpacity(0.3),
                                AppColors.primary.withOpacity(0.2),
                              ] : [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(_isMessagePressed ? 0.4 : 0.2),
                              width: 1,
                            ),
                            boxShadow: _isMessagePressed ? [] : [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            CupertinoIcons.bubble_left_fill,
                            color: AppColors.primary,
                            size: ResponsiveUtils.scaledIconSize(context, 16),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

                      // Call button
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isCallPressed = true),
                        onTapUp: (_) {
                          setState(() => _isCallPressed = false);
                          HapticFeedback.lightImpact();
                          _callFriend(context);
                        },
                        onTapCancel: () => setState(() => _isCallPressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          transform: _isCallPressed
                              ? Matrix4.translationValues(0, 1, 0)
                              : Matrix4.identity(),
                          width: ResponsiveUtils.scaledContainerSize(context, 32),
                          height: ResponsiveUtils.scaledContainerSize(context, 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isCallPressed ? [
                                AppColors.tertiary.withOpacity(0.3),
                                AppColors.tertiary.withOpacity(0.2),
                              ] : [
                                AppColors.tertiary.withOpacity(0.15),
                                AppColors.tertiary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.tertiary.withOpacity(_isCallPressed ? 0.4 : 0.2),
                              width: 1,
                            ),
                            boxShadow: _isCallPressed ? [] : [
                              BoxShadow(
                                color: AppColors.tertiary.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            CupertinoIcons.phone_fill,
                            color: AppColors.tertiary,
                            size: ResponsiveUtils.scaledIconSize(context, 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expandable content - ONLY relationship context
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
              child: _buildExpandedContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 44);
    final emojiSize = ResponsiveUtils.scaledIconSize(context, 20, maxScale: 1.2);

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: widget.friend.isEmoji
              ? Colors.white.withOpacity(0.9)
              : Colors.white,
          shape: BoxShape.circle,
        ),
        child: widget.friend.isEmoji
            ? Center(
          child: Text(
            widget.friend.profileImage,
            style: TextStyle(fontSize: emojiSize),
          ),
        )
            : ClipOval(
          child: Image.file(
            File(widget.friend.profileImage),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildNameWithReminder() {
    if (_isLoadingReminderTime) {
      return Row(
        children: [
          Expanded(
            child: Text(
              widget.friend.name,
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 20, maxScale: 1.3),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
          SizedBox(
            width: ResponsiveUtils.scaledContainerSize(context, 16),
            height: ResponsiveUtils.scaledContainerSize(context, 16),
            child: const CupertinoActivityIndicator(radius: 8),
          ),
        ],
      );
    }

    final reminderText = _getFixedWidthReminderText(_nextReminderTime);
    final reminderColor = _getReminderColor(_nextReminderTime);

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.friend.name,
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 20, maxScale: 1.3),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

        // Smaller, better positioned reminder indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveUtils.scaledContainerSize(context, 4),
              height: ResponsiveUtils.scaledContainerSize(context, 4),
              decoration: BoxDecoration(
                color: reminderColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
            Text(
              reminderText,
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 13, maxScale: 1.1),
                fontWeight: FontWeight.w600,
                color: reminderColor,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    final hasAlongsideThem = widget.friend.helpingWith != null && widget.friend.helpingWith!.isNotEmpty;
    final hasAlongsideYou = widget.friend.theyHelpingWith != null && widget.friend.theyHelpingWith!.isNotEmpty;

    if (!hasAlongsideThem && !hasAlongsideYou) {
      return const SizedBox.shrink(); // No expanded content if no relationship info
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.primary.withOpacity(0.01),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 0.5,
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.scaledSpacing(context, 20),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.scaledSpacing(context, 16),
              ResponsiveUtils.scaledSpacing(context, 14),
              ResponsiveUtils.scaledSpacing(context, 16),
              ResponsiveUtils.scaledSpacing(context, 16),
            ),
            child: Column(
              children: [
                if (hasAlongsideThem) ...[
                  _buildInfoRow(
                    icon: CupertinoIcons.person_fill,
                    title: "Alongside them",
                    content: widget.friend.helpingWith!,
                    color: AppColors.primary,
                  ),
                  if (hasAlongsideYou) SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
                ],
                if (hasAlongsideYou) ...[
                  _buildInfoRow(
                    icon: CupertinoIcons.person_2_fill,
                    title: "Alongside you",
                    content: widget.friend.theyHelpingWith!,
                    color: AppColors.tertiary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 12),
        vertical: ResponsiveUtils.scaledSpacing(context, 10),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveUtils.scaledContainerSize(context, 24),
            height: ResponsiveUtils.scaledContainerSize(context, 24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color.withOpacity(0.8),
              size: ResponsiveUtils.scaledIconSize(context, 12),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.scaledFontSize(context, 13, maxScale: 1.1),
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.2),
                    color: AppColors.textPrimary.withOpacity(0.8),
                    fontFamily: '.SF Pro Text',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMessageScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => MessageScreenNew(friend: widget.friend),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AddFriendScreen(friend: widget.friend),
      ),
    );
  }

  void _callFriend(BuildContext context) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.incrementCallsMade();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_action_${widget.friend.id}', DateTime.now().millisecondsSinceEpoch);

      final notificationService = NotificationService();
      await notificationService.scheduleReminder(widget.friend);

      _loadNextReminderTime();

    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Unable to open phone app. Please try again later.'),
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
}