// lib/widgets/friend_card_new.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/friend.dart';
import '../screens/add_friend_screen.dart';
import '../screens/manage_messages_screen.dart';
import '../utils/text_styles.dart';
import '../utils/colors.dart';
import '../widgets/character_components.dart';

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

  // Get background color for card based on friend index (for variety)
  Color _getBackgroundColor() {
    // Create a pattern of different background colors for visual interest
    final colorIndex = widget.index % 4;
    switch (colorIndex) {
      case 0:
        return AppColors.primaryLight;
      case 1:
        return AppColors.secondaryLight;
      case 2:
        return AppColors.tertiaryLight;
      case 3:
        return AppColors.accentLight;
      default:
        return AppColors.cardBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _isPressed ? 0.98 : 1.0),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getBackgroundColor().withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: _getBackgroundColor().withOpacity(0.8),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _toggleExpand();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
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
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.friend.reminderDays > 0)
                                  CharacterComponents.bouncingBadge(
                                    text: '${widget.friend.reminderDays}d',
                                    backgroundColor: AppColors.accent,
                                    textColor: Colors.white,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Alongside them in section
                            if (widget.friend.helpingWith != null &&
                                widget.friend.helpingWith!.isNotEmpty) ...[
                              Text(
                                'Alongside them in:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                widget.friend.helpingWith!,
                                style: AppTextStyles.bodyText.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getBackgroundColor().withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.chevron_down,
                                color: AppColors.textPrimary,
                                size: 16,
                              ),
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
                      // Separator line
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _getBackgroundColor().withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),

                      // "They're alongside you in:" section
                      if (widget.friend.theyHelpingWith != null &&
                          widget.friend.theyHelpingWith!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                          child: CharacterComponents.playfulCard(
                            backgroundColor: _getBackgroundColor().withOpacity(0.2),
                            borderColor: _getBackgroundColor().withOpacity(0.5),
                            borderRadius:
                            12,
                            padding: const EdgeInsets.all(12),
                            showShadow: false,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getBackgroundColor().withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.person_2_fill,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'They\'re alongside you in:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _getBackgroundColor().withOpacity(1.0),
                                        ),
                                      ),
                                      Text(
                                        widget.friend.theyHelpingWith!,
                                        style: AppTextStyles.bodyText.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Reminder section if reminder is set
                      if (widget.friend.reminderDays > 0) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                          child: CharacterComponents.playfulCard(
                            backgroundColor: AppColors.accentLight,
                            borderColor: AppColors.accent.withOpacity(0.5),
                            borderRadius: 12,
                            padding: const EdgeInsets.all(12),
                            showShadow: false,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.bell_fill,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reminder every ${widget.friend.reminderDays} ${widget.friend.reminderDays == 1 ? 'day' : 'days'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      Text(
                                        'Next: 5/14/2025 at 6:32 PM', // This should be dynamic
                                        style: AppTextStyles.bodyText.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Action buttons section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Message button
                            Expanded(
                              child: CharacterComponents.playfulButton(
                                label: 'Message',
                                icon: CupertinoIcons.bubble_left_fill,
                                backgroundColor: AppColors.primary,
                                onPressed: () => _showMessageOptions(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Call button
                            Expanded(
                              child: CharacterComponents.playfulButton(
                                label: 'Call',
                                icon: CupertinoIcons.phone_fill,
                                backgroundColor: Colors.white,
                                textColor: AppColors.primary,
                                borderColor: AppColors.divider,
                                onPressed: () => _callFriend(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Edit button
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.tertiary.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  CupertinoIcons.pencil,
                                  size: 20,
                                  color: AppColors.tertiary,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => AddFriendScreen(friend: widget.friend),
                                    ),
                                  );
                                },
                                padding: EdgeInsets.zero,
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
        ),
      ),
    );
  }

  // Create the profile image with consistent size and playful styling
  Widget _buildProfileImage() {
    // Different background colors based on the friend's index
    final colorIndex = widget.index % AppColors.extendedPalette.length;
    final backgroundColor = AppColors.extendedPalette[colorIndex].withOpacity(0.2);

    return CharacterComponents.floatingElement(
      yOffset: 3,
      period: const Duration(seconds: 3),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.extendedPalette[colorIndex].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.friend.isEmoji
            ? Center(
          child: Text(
            widget.friend.profileImage,
            style: const TextStyle(fontSize: 34),
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

  // Message options popup with colorful, playful messaging
  void _showMessageOptions(BuildContext context) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();
    final allMessages = [...provider.storageService.getDefaultMessages(), ...customMessages];

    // Design the bottom sheet with more character
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle at top with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 10),
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Header with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight,
                    AppColors.secondaryLight,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Message ${widget.friend.name}',
                        style: AppTextStyles.navTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Settings button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        CupertinoIcons.gear,
                        size: 16,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageMessagesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Messages list with staggered animation
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: allMessages.length + 1,
                itemBuilder: (context, index) {
                  // Add staggered animation
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    curve: Curves.easeOutQuint,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: child,
                        ),
                      );
                    },
                    child: index == allMessages.length
                        ? _buildCreateMessageButton(context)
                        : _buildMessageOption(context, allMessages[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create message button with playful style
  Widget _buildCreateMessageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showCustomMessageDialog(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.secondary.withOpacity(0.2),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.add,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Create custom message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Message option with playful style
  Widget _buildMessageOption(BuildContext context, String message, int index) {
    // Get different colors for each message to add visual interest
    final colorIndex = index % AppColors.extendedPalette.length;
    final color = AppColors.extendedPalette[colorIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _sendMessage(context, message);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // Display a custom message dialog with character
  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Create Message',
          style: AppTextStyles.dialogTitle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // Little character or emoji above the input
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '✍️',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              CupertinoTextField(
                controller: textController,
                placeholder: 'Type your message...',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                style: AppTextStyles.inputText,
                placeholderStyle: AppTextStyles.placeholder,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                Navigator.pop(context);
                final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
                await storageService.addCustomMessage(textController.text);
                _showSuccessToast(context, 'Message saved! ✅');
              }
            },
            child: Text(
              'Save',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show a success toast notification with character
  void _showSuccessToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  // Send a message
  void _sendMessage(BuildContext context, String message) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(
              'Error',
              style: AppTextStyles.dialogTitle.copyWith(
                color: AppColors.error,
              ),
            ),
            content: Text(
              'Unable to open messaging app. Please try again later.',
              style: AppTextStyles.dialogContent,
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  // Call a friend
  void _callFriend(BuildContext context) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
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
            title: Text(
              'Error',
              style: AppTextStyles.dialogTitle.copyWith(
                color: AppColors.error,
              ),
            ),
            content: Text(
              'Unable to open phone app. Please try again later.',
              style: AppTextStyles.dialogContent,
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}