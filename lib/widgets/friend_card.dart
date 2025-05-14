// lib/widgets/friend_card.dart - Updated to match Add Friend styling
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

class FriendCard extends StatefulWidget {
  final Friend friend;
  final bool isHighlighted;
  final bool isExpanded;
  final Function(String) onExpand;
  final int index;
  final Function(int, int)? onReorder;

  const FriendCard({
    Key? key,
    required this.friend,
    this.isHighlighted = false,
    this.isExpanded = false,
    required this.onExpand,
    required this.index,
    this.onReorder,
  }) : super(key: key);

  @override
  State<FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

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
  void didUpdateWidget(FriendCard oldWidget) {
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
    // Use same horizontal margin as Add Friend screen
    //const double horizontalMargin = 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpand,
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
                                  style: AppTextStyles.cardTitle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.friend.reminderDays > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.bell_fill,
                                        size: 12,
                                        color: Color(0xFFFF9500),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.friend.reminderDays}d',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFFF9500),
                                          fontFamily: '.SF Pro Text',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          // Alongside them in section
                          if (widget.friend.helpingWith != null &&
                              widget.friend.helpingWith!.isNotEmpty) ...[
                            Text(
                              'Alongside them in:',
                              style: AppTextStyles.accentText.copyWith(
                                fontSize: 15,
                                color: const Color(0xFF007AFF),
                              ),
                            ),
                            Text(
                              widget.friend.helpingWith!,
                              style: AppTextStyles.bodyText,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Chevron icon that rotates when expanded
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        CupertinoIcons.chevron_down,
                        color: Color(0xFFCCCCCC),
                        size: 20,
                      ),
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
                      height: 0.5,
                      color: const Color(0xFFE5E5EA),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),

                    // "They're alongside you in:" section
                    if (widget.friend.theyHelpingWith != null &&
                        widget.friend.theyHelpingWith!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              CupertinoIcons.person_2,
                              size: 20,
                              color: Color(0xFF007AFF),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'They\'re alongside you in:',
                                    style: AppTextStyles.accentText.copyWith(
                                      fontSize: 15,
                                      color: const Color(0xFF007AFF),
                                    ),
                                  ),
                                  Text(
                                    widget.friend.theyHelpingWith!,
                                    style: AppTextStyles.bodyText,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Reminder section if reminder is set
                    if (widget.friend.reminderDays > 0) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              CupertinoIcons.calendar,
                              size: 20,
                              color: Color(0xFFFF9500),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reminder every ${widget.friend.reminderDays} ${widget.friend.reminderDays == 1 ? 'day' : 'days'}',
                                    style: AppTextStyles.secondaryText,
                                  ),
                                  Text(
                                    'Next: 5/14/2025 at 6:32 PM', // This should be dynamic
                                    style: AppTextStyles.bodyText,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                            child: _buildActionButton(
                              label: 'Message',
                              icon: CupertinoIcons.bubble_left_fill,
                              backgroundColor: const Color(0xFF007AFF),
                              onPressed: () => _showMessageOptions(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Call button
                          Expanded(
                            child: _buildActionButton(
                              label: 'Call',
                              icon: CupertinoIcons.phone_fill,
                              backgroundColor: Colors.white,
                              textColor: const Color(0xFF007AFF),
                              borderColor: const Color(0xFFE5E5EA),
                              onPressed: () => _callFriend(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Edit button
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE5E5EA),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                CupertinoIcons.pencil,
                                size: 20,
                                color: Color(0xFF007AFF),
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
    );
  }

  // Create the profile image with consistent size
  Widget _buildProfileImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFEEEEEE),
        shape: BoxShape.circle,
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

  // Action button styling
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null
                ? BorderSide(color: borderColor, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: textColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: textColor,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Message options popup with fixed width messages
  void _showMessageOptions(BuildContext context) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();
    final allMessages = [...provider.storageService.getDefaultMessages(), ...customMessages];

    final screenWidth = MediaQuery.of(context).size.width;
    // Fixed width for all messages
    final messageWidth = screenWidth * 0.85;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle at top
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Message ${widget.friend.name}',
                        style: AppTextStyles.navTitle,
                      ),
                    ),
                  ),
                  // Settings button
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        CupertinoIcons.gear,
                        size: 14,
                        color: Color(0xFF007AFF),
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

            // Divider
            Container(
              height: 0.5,
              color: const Color(0xFFE5E5EA),
            ),

            // List of messages with fixed width
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
                    // Create custom message button
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: messageWidth,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _showCustomMessageDialog(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                CupertinoIcons.add_circled,
                                size: 18,
                                color: Color(0xFF007AFF),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Create custom message',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF007AFF),
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Regular message option with fixed width
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: messageWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _sendMessage(context, allMessages[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Text(
                            allMessages[index],
                            style: AppTextStyles.bodyText,
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

  // Display a custom message dialog
  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Create Message',
          style: AppTextStyles.dialogTitle,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Type your message...',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            style: AppTextStyles.inputText,
            placeholderStyle: AppTextStyles.placeholder,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text('Cancel'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show a success toast notification
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
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: '.SF Pro Text',
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
            title: const Text('Error'),
            content: const Text('Unable to open messaging app. Please try again later.'),
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