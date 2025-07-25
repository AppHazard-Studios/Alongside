// lib/widgets/friend_card.dart - FIXED CONSISTENT TEXT SCALING
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
import '../utils/text_styles.dart'; // FIXED: Ensure text_styles import
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
    if (nextReminder == null) return '---';

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.isNegative) {
      return 'now';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).round().clamp(1, 6);
      return '${months}mo';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Color _getReminderColor(DateTime? nextReminder) {
    if (nextReminder == null) return AppColors.primary;

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.inDays == 0 && difference.inHours <= 1) {
      return AppColors.warning;
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
          // FIXED: Use proper scaled text style instead of raw fontSize
          style: AppTextStyles.scaledCallout(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditScreen(context);
            },
            child: Row(
              children: [
                const SizedBox(
                  width: 60,
                  child: Icon(
                    CupertinoIcons.pencil,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Edit',
                    textAlign: TextAlign.center,
                    // FIXED: Use proper scaled text style
                    style: AppTextStyles.scaledHeadline(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
          if (totalFriends > 1)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showReorderMenu();
              },
              child: Row(
                children: [
                  const SizedBox(
                    width: 60,
                    child: Icon(
                      CupertinoIcons.arrow_up_arrow_down,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Reorder',
                      textAlign: TextAlign.center,
                      // FIXED: Use proper scaled text style
                      style: AppTextStyles.scaledHeadline(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            // FIXED: Use proper scaled text style
            style: AppTextStyles.scaledHeadline(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
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
          // FIXED: Use proper scaled text style
          style: AppTextStyles.scaledCallout(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!isFirst)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _moveToTop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_up_to_line,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Move to Top',
                    // FIXED: Use proper scaled text style
                    style: AppTextStyles.scaledHeadline(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_up,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Move Up',
                    // FIXED: Use proper scaled text style
                    style: AppTextStyles.scaledHeadline(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_down,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Move Down',
                    // FIXED: Use proper scaled text style
                    style: AppTextStyles.scaledHeadline(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_down_to_line,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Move to Bottom',
                    // FIXED: Use proper scaled text style
                    style: AppTextStyles.scaledHeadline(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            // FIXED: Use proper scaled text style
            style: AppTextStyles.scaledHeadline(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
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

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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

  // FRIEND CARD FIXES - Replace these methods in friend_card.dart

  Widget _buildProfileImage() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 44);

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
          child: FittedBox( // 🔧 FIX: Prevents emoji from growing outside circle
            fit: BoxFit.scaleDown,
            child: Text(
              widget.friend.profileImage,
              style: TextStyle(
                fontSize: containerSize * 0.45, // 🔧 FIX: Size relative to container
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
      ),
    );
  }

// REMINDER INDICATOR FIX - Replace _buildNameWithReminder in friend_card.dart

  Widget _buildNameWithReminder() {
    if (_isLoadingReminderTime) {
      return Row(
        children: [
          Expanded( // 🔧 FIX: Use Expanded instead of Flexible for proper spacing
            child: Text(
              widget.friend.name,
              style: AppTextStyles.scaledHeadline(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
        // 🔧 FIX: Give name most of the space but leave room for reminder
        Expanded(
          child: Text(
            widget.friend.name,
            style: AppTextStyles.scaledHeadline(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 🔧 FIX: Fixed spacing
        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

        // 🔧 FIX: Constrained reminder indicator to prevent overflow
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 50, // Fixed max width to prevent overflow
          ),
          child: Row(
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
              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 4)), // 🔧 FIX: Reduced spacing

              // 🔧 FIX: Flexible text that can scale down if needed
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    reminderText,
                    style: AppTextStyles.scaledFootnote(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: reminderColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    final hasAlongsideThem = widget.friend.helpingWith != null && widget.friend.helpingWith!.isNotEmpty;
    final hasAlongsideYou = widget.friend.theyHelpingWith != null && widget.friend.theyHelpingWith!.isNotEmpty;

    if (!hasAlongsideThem && !hasAlongsideYou) {
      return const SizedBox.shrink();
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

          // 🔧 FIX: Remove fixed padding, let content determine height
          Padding(
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

  // ALONGSIDE ICONS FIX - Replace _buildInfoRow in friend_card.dart

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 12),
        vertical: ResponsiveUtils.scaledSpacing(context, 12), // 🔧 FIX: Increased vertical padding
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12), // 🔧 FIX: Slightly bigger radius
        border: Border.all(
          color: color.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔧 FIX: Bigger, properly scaling icon container
          Container(
            width: ResponsiveUtils.scaledContainerSize(context, 32), // 🔧 FIX: Bigger container (was 24)
            height: ResponsiveUtils.scaledContainerSize(context, 32),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), // 🔧 FIX: Slightly more opaque background
              borderRadius: BorderRadius.circular(8), // 🔧 FIX: Bigger border radius
              border: Border.all(
                color: color.withOpacity(0.15), // 🔧 FIX: Subtle border
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              color: color.withOpacity(0.9), // 🔧 FIX: More opaque icon
              size: ResponsiveUtils.scaledIconSize(context, 16), // 🔧 FIX: Bigger icon (was 12)
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.scaledFootnote(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 4)), // 🔧 FIX: Increased spacing

                // 🔧 FIX: Better text handling
                Text(
                  content,
                  style: AppTextStyles.scaledSubhead(context).copyWith(
                    color: AppColors.textPrimary.withOpacity(0.8),
                    height: 1.3,
                  ),
                  // No maxLines restriction - let it flow naturally
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