// lib/widgets/friend_card.dart - FIXED reminder display issues
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

  // Load next reminder time - FIXED VERSION
  Future<void> _loadNextReminderTime() async {
    // FIXED: Use hasReminder instead of reminderDays > 0
    if (widget.friend.hasReminder) {
      setState(() {
        _isLoadingReminderTime = true;
      });

      try {
        final notificationService = NotificationService();
        final nextTime = await notificationService.getNextReminderTime(widget.friend.id);

        print('DEBUG: Friend ${widget.friend.name} - Next reminder: $nextTime');

        // If no scheduled time found, try to schedule one
        if (nextTime == null) {
          print('DEBUG: No scheduled reminder found, scheduling one');
          await notificationService.scheduleReminder(widget.friend);
          // Try getting the time again
          final newNextTime = await notificationService.getNextReminderTime(widget.friend.id);
          print('DEBUG: After scheduling - Next reminder: $newNextTime');

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
        print('DEBUG: Error loading reminder time: $e');
        if (mounted) {
          setState(() {
            _nextReminderTime = null;
            _isLoadingReminderTime = false;
          });
        }
      }
    }
  }

  // Helper method to format next reminder text for expanded view
// Helper method to format next reminder text for expanded view
  String _getNextReminderText(DateTime? nextReminder) {
    if (nextReminder == null) return 'No reminder scheduled';

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    // Don't show overdue or negative times
    if (difference.isNegative) {
      return 'Reminder is now';
    } else if (difference.inDays > 1) {
      return 'Next reminder in ${difference.inDays} days';
    } else if (difference.inDays == 1) {
      return 'Next reminder in 1 day';
    } else if (difference.inHours >= 1) {
      return 'Next reminder in ${difference.inHours} hours';
    } else if (difference.inMinutes >= 1) {
      return 'Next reminder in ${difference.inMinutes} minutes';
    } else {
      return 'Reminder is now';
    }
  }
  // Helper method to format concise reminder text for collapsed view badge
// Helper method to format concise reminder text for collapsed view badge
// Helper method to format concise reminder text for collapsed view badge
  String _getCollapsedReminderText(DateTime? nextReminder) {
    if (nextReminder == null) return 'No reminder';

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    // If time has passed, don't show the badge (let it refresh to next occurrence)
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

  // Get badge color based on reminder urgency
// Get badge color based on reminder urgency
// Get badge color based on reminder urgency
  Color _getBadgeColor(DateTime? nextReminder) {
    if (nextReminder == null) return CupertinoColors.systemGrey;

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    // Don't show different colors for passed times, just treat as normal
    if (difference.inDays == 0 && difference.inHours <= 1) {
      return AppColors.warning;
    } else if (difference.inDays <= 1) {
      return AppColors.primary;
    } else {
      return AppColors.primary;
    }
  }

  // Get badge background color based on reminder urgency
// Get badge background color based on reminder urgency
// Get badge background color based on reminder urgency
  Color _getBadgeBackgroundColor(DateTime? nextReminder) {
    if (nextReminder == null) return CupertinoColors.systemGrey6;

    final now = DateTime.now();
    final difference = nextReminder.difference(now);

    // Don't show different colors for passed times, just treat as normal
    if (difference.inDays == 0 && difference.inHours <= 1) {
      return AppColors.warning.withOpacity(0.1);
    } else if (difference.inDays <= 1) {
      return AppColors.primaryLight;
    } else {
      return AppColors.primaryLight;
    }
  }

  @override
  void didUpdateWidget(FriendCardNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
    // FIXED: Check both old and new reminder systems for changes
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
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CupertinoColors.white,
              CupertinoColors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main card content (always visible)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnhancedProfileImage(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Friend name row with enhanced reminder badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.friend.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: '.SF Pro Text',
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.friend.hasReminder && !widget.isExpanded) ...[
                              const SizedBox(width: 12),
                              _buildEnhancedReminderBadge(),
                            ],
                          ],
                        ),

                        // "Alongside them in" info with enhanced design
                        if (widget.friend.helpingWith != null &&
                            widget.friend.helpingWith!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.8),
                                      AppColors.primary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  CupertinoIcons.heart_fill,
                                  color: CupertinoColors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Alongside them: ${widget.friend.helpingWith}",
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 15,
                                    fontFamily: '.SF Pro Text',
                                    height: 1.4,
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
                  const SizedBox(width: 12),
                  // Enhanced chevron with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: widget.isExpanded ? 0.5 : 0.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 3.14,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.chevron_down,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Rest of expandable content...
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

  Widget _buildEnhancedProfileImage() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 68);
    final emojiSize = ResponsiveUtils.scaledIconSize(context, 32, maxScale: 1.3);

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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: widget.friend.isEmoji
              ? CupertinoColors.systemGrey6
              : CupertinoColors.white,
          shape: BoxShape.circle,
        ),
        child: widget.friend.isEmoji
            ? Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(6),
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
      ),
    );
  }

// UPDATED: Enhanced reminder badge with better styling
  Widget _buildEnhancedReminderBadge() {
    if (_isLoadingReminderTime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CupertinoColors.systemGrey6,
              CupertinoColors.systemGrey5,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.bell,
              size: 14,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 14,
              height: 14,
              child: CupertinoActivityIndicator(radius: 7),
            ),
          ],
        ),
      );
    }

    String badgeText;
    Color badgeColor;
    List<Color> gradientColors;

    if (_nextReminderTime != null) {
      final timeText = _getCollapsedReminderText(_nextReminderTime);

      if (timeText.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadNextReminderTime();
        });
        return const SizedBox.shrink();
      }

      badgeText = timeText;
      final baseColor = _getBadgeColor(_nextReminderTime);
      badgeColor = CupertinoColors.white;
      gradientColors = [
        baseColor.withOpacity(0.8),
        baseColor,
      ];
    } else {
      badgeText = widget.friend.reminderDisplayText.replaceAll('Every ', '').replaceAll(' on', '');
      badgeColor = CupertinoColors.white;
      gradientColors = [
        AppColors.primary.withOpacity(0.8),
        AppColors.primary,
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.bell_fill,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        // Enhanced separator
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
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

        // Enhanced info section
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "They're alongside you in" section with enhanced design
              if (widget.friend.theyHelpingWith != null &&
                  widget.friend.theyHelpingWith!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.tertiary.withOpacity(0.8),
                            AppColors.tertiary,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tertiary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.person_2_fill,
                        color: CupertinoColors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Alongside you:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tertiary,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.friend.theyHelpingWith!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.label,
                              fontFamily: '.SF Pro Text',
                              height: 1.4,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Enhanced reminder info
              if (widget.friend.hasReminder) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warning.withOpacity(0.8),
                            AppColors.warning,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.bell_fill,
                        color: CupertinoColors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.friend.reminderDisplayText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.time,
                                size: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTimeString(widget.friend.reminderTime),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel,
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
                                fontSize: 13,
                                color: AppColors.primary,
                                fontFamily: '.SF Pro Text',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),

        // Enhanced action buttons
        _buildEnhancedActionButtons(),
      ],
    );
  }

// NEW: Enhanced action buttons with better styling
  Widget _buildEnhancedActionButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        ResponsiveUtils.scaledSpacing(context, 20),
      ),
      child: Row(
        children: [
          // Enhanced message button
          Expanded(
            child: Container(
              height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => _navigateToMessageScreen(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.bubble_left_fill,
                      color: CupertinoColors.white,
                      size: ResponsiveUtils.scaledIconSize(context, 18),
                    ),
                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                    Text(
                      'Message',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),

          // Enhanced call button
          Expanded(
            child: Container(
              height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CupertinoColors.systemGrey6,
                    CupertinoColors.systemGrey5,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => _callFriend(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.phone_fill,
                      color: AppColors.primary,
                      size: ResponsiveUtils.scaledIconSize(context, 18),
                    ),
                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                    Text(
                      'Call',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),

          // Enhanced edit button
          Container(
            width: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 48),
            height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CupertinoColors.systemGrey6,
                  CupertinoColors.systemGrey5,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              onPressed: () => _navigateToEditScreen(context),
              child: Icon(
                CupertinoIcons.pencil,
                size: ResponsiveUtils.scaledIconSize(context, 20),
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the collapsed reminder badge with dynamic time display
// Build the collapsed reminder badge with dynamic time display
  Widget _buildCollapsedReminderBadge() {
    if (_isLoadingReminderTime) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.bell,
              size: 12,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(width: 4),
            SizedBox(
              width: 12,
              height: 12,
              child: CupertinoActivityIndicator(radius: 6),
            ),
          ],
        ),
      );
    }

    // Show dynamic time if available, otherwise show static interval
    String badgeText;
    Color badgeColor;
    Color backgroundColor;

    if (_nextReminderTime != null) {
      final timeText = _getCollapsedReminderText(_nextReminderTime);

      // If time has passed (empty string), don't show badge and refresh
      if (timeText.isEmpty) {
        // Trigger refresh of reminder time to get next occurrence
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadNextReminderTime();
        });
        return const SizedBox.shrink();
      }

      badgeText = timeText;
      badgeColor = _getBadgeColor(_nextReminderTime);
      backgroundColor = _getBadgeBackgroundColor(_nextReminderTime);
    } else {
      // Fallback to static interval display
      badgeText = widget.friend.reminderDisplayText.replaceAll('Every ', '').replaceAll(' on', '');
      badgeColor = AppColors.primary;
      backgroundColor = AppColors.primaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.bell_fill,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
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

      // Reschedule reminder and refresh display
      final notificationService = NotificationService();
      await notificationService.scheduleReminder(widget.friend);

      // Reload the next reminder time to update the display
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