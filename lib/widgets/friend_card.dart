// lib/widgets/friend_card_new.dart - No shadow version with color patterns
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
    final cardBgColor = _getBackgroundColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: _isPressed
          ? Matrix4.translationValues(0, 1, 0)
          : Matrix4.identity(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // Gradient background instead of shadow for character
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardBgColor.withOpacity(0.8),
            Colors.white,
          ],
          stops: const [0.0, 0.4],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBgColor.withOpacity(0.6),
          width: 1.5,
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
          borderRadius: BorderRadius.circular(16),
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
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              widget.friend.helpingWith!,
                              style: AppTextStyles.bodyText.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
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
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cardBgColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.chevron_down,
                              color: AppColors.textPrimary,
                              size: 14,
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
                            cardBgColor.withOpacity(0.5),
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
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // Use the same color for both alongside sections
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.person_2_fill,
                                  size: 16,
                                  color: AppColors.primary,
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      widget.friend.theyHelpingWith!,
                                      style: AppTextStyles.bodyText.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
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
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                              width: 1,
                            ),
                            // Subtle dotted pattern for visual interest without shadows
                            backgroundBlendMode: BlendMode.overlay,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.bell_fill,
                                  size: 16,
                                  color: AppColors.accent,
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    Text(
                                      'Next: 5/14/2025 at 6:32 PM', // This should be dynamic
                                      style: AppTextStyles.bodyText.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
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

                    // Action buttons section with improved styling
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Message button - CupertinoButton for better iOS feeling
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () => _showMessageOptions(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    CupertinoIcons.bubble_left_fill,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Message',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
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
                              onPressed: () => _callFriend(context),
                              child: Container(
                                height: 48, // Match primary button height
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.divider,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.phone_fill,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Call',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Edit button with consistent styling
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => AddFriendScreen(friend: widget.friend),
                                ),
                              );
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.tertiary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.pencil,
                                size: 18,
                                color: AppColors.tertiary,
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
      ),
    );
  }

  // Create the profile image with consistent size and patterns instead of shadows
  Widget _buildProfileImage() {
    // Different background colors based on the friend's index
    final colorIndex = widget.index % AppColors.extendedPalette.length;
    final backgroundColor = AppColors.extendedPalette[colorIndex].withOpacity(0.15);
    final patternColor = AppColors.extendedPalette[colorIndex].withOpacity(0.1);

    return CharacterComponents.floatingElement(
      yOffset: 2, // Subtle movement
      period: const Duration(seconds: 3),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          // Gradient background instead of shadow
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor.withOpacity(0.8),
              backgroundColor.withOpacity(0.3),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.extendedPalette[colorIndex].withOpacity(0.3),
            width: 1.5,
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
      ),
    );
  }

  // Message options popup with patterns instead of shadows
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle at top with animation
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Header with gradient background for character
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
                  const SizedBox(width: 32),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Message ${widget.friend.name}',
                        style: AppTextStyles.navTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  // Settings button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.gear,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const ManageMessagesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Messages list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: allMessages.length + 1,
                itemBuilder: (context, index) {
                  if (index == allMessages.length) {
                    return _buildCreateMessageButton(context);
                  }

                  final message = allMessages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                        _sendMessage(context, message);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          // Use pattern instead of shadow
                          color: index % 2 == 0
                              ? Colors.white
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          message,
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create message button with patterns instead of shadows
  Widget _buildCreateMessageButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.pop(context);
          _showCustomMessageDialog(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            // Gradient for character
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.add,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Create custom message',
                style: TextStyle(
                  fontSize: 15,
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

  // Display a custom message dialog with patterns instead of shadows
  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Create Message',
          style: AppTextStyles.dialogTitle.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // Little emoji above the input
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: const Text(
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
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
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
                _showSuccessToast(context, 'Message saved');
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

  // Show a success toast notification with patterns instead of shadows
  void _showSuccessToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
      // Show a loading indicator
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 12,
                ),
                SizedBox(height: 16),
                Text(
                  'Sending...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      // Dismiss the loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading indicator

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text(
              'Error',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Unable to open messaging app. Please try again later.',
                style: AppTextStyles.dialogContent.copyWith(
                  height: 1.3,
                ),
              ),
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