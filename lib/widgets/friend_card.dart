// lib/widgets/friend_card.dart - UNIFIED GLASSMORPHISM DESIGN
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
    if (widget.friend.hasReminder) {
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
  }

  String _getNextReminderText(DateTime? nextReminder) {
    if (nextReminder == null) return 'No reminder scheduled';

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.isNegative) {
      return 'Reminder is now';
    } else if (difference.inDays > 1) {
      return 'Next reminder in ${difference.inDays} days';
    } else if (difference.inDays == 1) {
      return 'Next reminder tomorrow';
    } else if (difference.inHours >= 1) {
      return 'Next reminder in ${difference.inHours} hours';
    } else if (difference.inMinutes >= 1) {
      return 'Next reminder in ${difference.inMinutes} minutes';
    } else {
      return 'Reminder is now';
    }
  }

  String _getCollapsedReminderText(DateTime? nextReminder) {
    if (nextReminder == null) return '';

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    if (difference.isNegative) {
      return '';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).round();
      return '${months}mo';
    } else if (difference.inDays > 1) {
      return '${difference.inDays}d';
    } else if (difference.inDays == 1) {
      return '1d';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return '';
    }
  }

  Color _getBadgeColor(DateTime? nextReminder) {
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
    if (widget.friend.hasReminder != oldWidget.friend.hasReminder ||
        widget.friend.reminderTime != oldWidget.friend.reminderTime ||
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
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        margin: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.scaledSpacing(context, 4),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main card content
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: widget.friend.isFavorite
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warning.withOpacity(0.05),
                    AppColors.warning.withOpacity(0.02),
                  ],
                )
                    : null,
              ),
              child: Row(
                children: [
                  _buildUnifiedProfileImage(),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and badges row
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  // Favorite star indicator
                                  if (widget.friend.isFavorite) ...[
                                    Container(
                                      width: ResponsiveUtils.scaledContainerSize(context, 20),
                                      height: ResponsiveUtils.scaledContainerSize(context, 20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.warning,
                                            AppColors.warning.withOpacity(0.8),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.warning.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        CupertinoIcons.star_fill,
                                        color: Colors.white,
                                        size: ResponsiveUtils.scaledIconSize(context, 12),
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                                  ],
                                  Expanded(
                                    child: Text(
                                      widget.friend.name,
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.scaledFontSize(context, 18, maxScale: 1.3),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.friend.hasReminder && !widget.isExpanded) ...[
                              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                              _buildUnifiedReminderBadge(),
                            ],
                          ],
                        ),

                        // Subtitle with glass styling
                        if (widget.friend.helpingWith != null &&
                            widget.friend.helpingWith!.isNotEmpty) ...[
                          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.scaledSpacing(context, 10),
                              vertical: ResponsiveUtils.scaledSpacing(context, 6),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: ResponsiveUtils.scaledContainerSize(context, 4),
                                  height: ResponsiveUtils.scaledContainerSize(context, 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                                Expanded(
                                  child: Text(
                                    "Alongside them: ${widget.friend.helpingWith}",
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.2),
                                      color: AppColors.primary,
                                      fontFamily: '.SF Pro Text',
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: widget.isExpanded ? 3 : 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  // Glass chevron
                  Container(
                    width: ResponsiveUtils.scaledContainerSize(context, 32),
                    height: ResponsiveUtils.scaledContainerSize(context, 32),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: AppColors.primary,
                        size: ResponsiveUtils.scaledIconSize(context, 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expandable content with glass styling
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
              child: _buildUnifiedExpandedContent(),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Unified glass profile image
  Widget _buildUnifiedProfileImage() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 50);
    final emojiSize = ResponsiveUtils.scaledIconSize(context, 24, maxScale: 1.2);

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
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
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

  // NEW: Unified glass reminder badge
  Widget _buildUnifiedReminderBadge() {
    if (_isLoadingReminderTime) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.scaledSpacing(context, 10),
          vertical: ResponsiveUtils.scaledSpacing(context, 6),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: SizedBox(
          width: ResponsiveUtils.scaledContainerSize(context, 12),
          height: ResponsiveUtils.scaledContainerSize(context, 12),
          child: const CupertinoActivityIndicator(radius: 6),
        ),
      );
    }

    String badgeText;
    Color badgeColor;

    if (_nextReminderTime != null) {
      final timeText = _getCollapsedReminderText(_nextReminderTime);
      if (timeText.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadNextReminderTime();
        });
        return const SizedBox.shrink();
      }
      badgeText = timeText;
      badgeColor = _getBadgeColor(_nextReminderTime);
    } else {
      badgeText = widget.friend.reminderDisplayText
          .replaceAll('Every ', '')
          .replaceAll(' on', '');
      badgeColor = AppColors.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 10),
        vertical: ResponsiveUtils.scaledSpacing(context, 6),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            badgeColor.withOpacity(0.1),
            badgeColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveUtils.scaledContainerSize(context, 14),
            height: ResponsiveUtils.scaledContainerSize(context, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  badgeColor,
                  badgeColor.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.bell_fill,
              size: ResponsiveUtils.scaledIconSize(context, 8),
              color: Colors.white,
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 12, maxScale: 1.1),
              fontWeight: FontWeight.w600,
              color: badgeColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Unified glass expanded content
  Widget _buildUnifiedExpandedContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.primary.withOpacity(0.02),
          ],
        ),
      ),
      child: Column(
        children: [
          // Glass separator
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.scaledSpacing(context, 16),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
            child: Column(
              children: [
                // Info sections with unified glass styling
                if (widget.friend.theyHelpingWith != null &&
                    widget.friend.theyHelpingWith!.isNotEmpty) ...[
                  _buildUnifiedInfoCard(
                    icon: CupertinoIcons.person_2_fill,
                    title: "Alongside you:",
                    content: widget.friend.theyHelpingWith!,
                    color: AppColors.tertiary,
                  ),
                  SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
                ],

                // Reminder info with unified glass styling
                if (widget.friend.hasReminder) ...[
                  _buildUnifiedInfoCard(
                    icon: CupertinoIcons.bell_fill,
                    title: widget.friend.reminderDisplayText,
                    content: _nextReminderTime != null
                        ? _getNextReminderText(_nextReminderTime)
                        : _formatTimeString(widget.friend.reminderTime),
                    color: AppColors.warning,
                  ),
                  SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
                ],

                // Unified glass action buttons
                _buildUnifiedActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Unified glass info card
  Widget _buildUnifiedInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 14)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveUtils.scaledContainerSize(context, 32),
            height: ResponsiveUtils.scaledContainerSize(context, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: ResponsiveUtils.scaledIconSize(context, 16),
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
                    fontSize: ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.2),
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 4)),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.scaledFontSize(context, 15, maxScale: 1.2),
                    color: AppColors.textPrimary,
                    fontFamily: '.SF Pro Text',
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Unified glass action buttons
  Widget _buildUnifiedActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 46),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _navigateToMessageScreen(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.bubble_left_fill,
                    color: Colors.white,
                    size: ResponsiveUtils.scaledIconSize(context, 16),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
                  Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.scaledFontSize(context, 15, maxScale: 1.2),
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)),
        Expanded(
          child: Container(
            height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 46),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _callFriend(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.phone_fill,
                    color: AppColors.primary,
                    size: ResponsiveUtils.scaledIconSize(context, 16),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
                  Text(
                    'Call',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.scaledFontSize(context, 15, maxScale: 1.2),
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)),
        Container(
          width: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 46),
          height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 46),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
            onPressed: () => _navigateToEditScreen(context),
            child: Icon(
              CupertinoIcons.pencil,
              size: ResponsiveUtils.scaledIconSize(context, 16),
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';

        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;

        return '$hour:$minute $period';
      }
    } catch (e) {
      // In case of parsing error, return original string
    }
    return timeStr;
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
    final phoneNumber =
    widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      final storageService =
          Provider.of<FriendsProvider>(context, listen: false).storageService;
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
}