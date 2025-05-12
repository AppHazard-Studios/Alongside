// widgets/friend_card.dart
// widgets/friend_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/friend.dart';
import '../screens/add_friend_screen.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
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
    return LongPressDraggable<int>(
      data: widget.index,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              _buildProfileImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.friend.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(AppConstants.primaryTextColorValue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(),
      ),
      onDragStarted: () {
        // Optional: Add haptic feedback
      },
      onDragEnd: (details) {
        // Handle drag end if needed
      },
      onDraggableCanceled: (velocity, offset) {
        // Handle cancellation if needed
      },
      maxSimultaneousDrags: widget.onReorder == null ? 0 : 1, // Only allow dragging when reorder is enabled
      child: DragTarget<int>(
        builder: (context, candidateData, rejectedData) {
          return _buildCardContent();
        },
        onWillAccept: (data) => data != null && data != widget.index,
        onAccept: (data) {
          if (widget.onReorder != null) {
            widget.onReorder!(data, widget.index);
          }
        },
      ),
    );
  }

  Widget _buildCardContent() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: widget.isHighlighted ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.isHighlighted
                ? AppConstants.primaryColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: widget.isHighlighted
            ? Border.all(color: AppConstants.primaryColor.withOpacity(0.3), width: 1.5)
            : Border.all(color: AppConstants.borderColor.withOpacity(0.7), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpand,
            splashColor: AppConstants.primaryColor.withOpacity(0.05),
            highlightColor: AppConstants.primaryColor.withOpacity(0.02),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main card content (always visible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      _buildProfileImage(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.friend.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(AppConstants.primaryTextColorValue),
                                  ),
                                ),
                                // Removed the reminder badge
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (widget.friend.helpingWith != null &&
                                widget.friend.helpingWith!.isNotEmpty) ...[
                              Text(
                                'Alongside them in:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.friend.helpingWith!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(AppConstants.primaryTextColorValue),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: widget.isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppConstants.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expandable details with a seamless transition
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
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          AppConstants.backgroundColor.withOpacity(0.5),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Very subtle separator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppConstants.borderColor.withOpacity(0),
                                  AppConstants.borderColor.withOpacity(0.3),
                                  AppConstants.borderColor.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Additional info sections
                        if (widget.friend.theyHelpingWith != null &&
                            widget.friend.theyHelpingWith!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppConstants.secondaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: AppConstants.secondaryColor,
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
                                          fontWeight: FontWeight.w500,
                                          color: AppConstants.secondaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.friend.theyHelpingWith!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppConstants.primaryTextColor,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (widget.friend.theyHelpingWith != null &&
                            widget.friend.theyHelpingWith!.isNotEmpty)
                          const SizedBox(height: 16),

                        if (widget.friend.reminderDays > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FutureBuilder<String?>(
                              future: _getNextReminderTime(),
                              builder: (context, snapshot) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppConstants.accentColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: AppConstants.accentColor,
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
                                              fontWeight: FontWeight.w500,
                                              color: AppConstants.secondaryTextColor,
                                            ),
                                          ),
                                          if (snapshot.hasData && snapshot.data != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Next: ${snapshot.data}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppConstants.primaryTextColor,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  Icons.message_rounded,
                                  'Message',
                                      () => _showMessageOptions(context),
                                  inverted: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  Icons.phone_rounded,
                                  'Call',
                                      () => _callFriend(context),
                                  inverted: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildEditButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Rest of your methods remain unchanged...
  // Include all your existing methods here
  Widget _buildReminderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active_rounded,
            size: 12,
            color: AppConstants.accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.friend.reminderDays}d',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.friend.isEmoji
            ? widget.isHighlighted
            ? AppConstants.primaryColor.withOpacity(0.08)
            : AppConstants.profileCircleColor
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        image: !widget.friend.isEmoji
            ? DecorationImage(
          image: FileImage(File(widget.friend.profileImage)),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: widget.friend.isEmoji
          ? Center(
        child: Text(
          widget.friend.profileImage,
          style: const TextStyle(fontSize: 30),
        ),
      )
          : null,
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onPressed,
      {bool inverted = false}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inverted ? AppConstants.primaryColor : Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: inverted
              ? Colors.white
              : AppConstants.primaryColor,
          foregroundColor: inverted
              ? AppConstants.primaryColor
              : Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: inverted
                ? BorderSide(color: AppConstants.primaryColor, width: 1.5)
                : BorderSide.none,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
  Widget _buildEditButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.borderColor,
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          Icons.edit_outlined,
          color: AppConstants.primaryColor,
          size: 20,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFriendScreen(friend: widget.friend),
            ),
          );
        },
        splashRadius: 24,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<String?> _getNextReminderTime() async {
    if (widget.friend.reminderDays <= 0) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('next_notification_${widget.friend.id}');
  }

  void _showMessageOptions(BuildContext context) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();

    final allMessages = [...AppConstants.presetMessages, ...customMessages];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Handle at the top
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 0),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.bottomSheetHandleColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header with title and settings icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // Profile icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.message_rounded,
                            color: AppConstants.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Centered title
                        Expanded(
                          child: Text(
                            'Message ${widget.friend.name}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryTextColor,
                            ),
                          ),
                        ),
                        // Settings icon with circle background to match other UI elements
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageMessagesScreen(),
                                ),
                              );
                            },
                            icon: Icon(Icons.settings, color: AppConstants.primaryColor, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Use same gradient divider as in friend cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppConstants.borderColor.withOpacity(0),
                            AppConstants.borderColor.withOpacity(0.3),
                            AppConstants.borderColor.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Message list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: allMessages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == allMessages.length) {
                          // Create custom message option
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: InkWell(
                              onTap: () => _showCustomMessageDialog(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: AppConstants.primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Create custom message',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Regular message option
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppConstants.borderColor, width: 1),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _sendMessage(context, allMessages[index]);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Text(
                                  allMessages[index],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppConstants.primaryTextColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Create Message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: dialogWidth,
            child: TextFormField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppConstants.borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelStyle: TextStyle(
                  fontSize: 15,
                  color: AppConstants.secondaryTextColor,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(
                fontSize: 15,
                color: AppConstants.primaryTextColor,
                height: 1.4,
              ),
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
            ),
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  final storageService = Provider.of<FriendsProvider>(
                    context,
                    listen: false,
                  ).storageService;

                  await storageService.addCustomMessage(textController.text);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Message saved',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, String message) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      bool launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final telUri = Uri.parse('tel:$phoneNumber');
        await launchUrl(
          telUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to open messaging app. Try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
    }
  }

  void _callFriend(BuildContext context) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      bool launched = await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not launch dialer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to open phone app. Try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
    }
  }
}

// Keep the rest of the file unchanged...

// New screen to manage custom messages
class ManageMessagesScreen extends StatefulWidget {
  const ManageMessagesScreen({Key? key}) : super(key: key);

  @override
  State<ManageMessagesScreen> createState() => _ManageMessagesScreenState();
}

class _ManageMessagesScreenState extends State<ManageMessagesScreen> {
  List<String> _customMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final messages = await provider.storageService.getCustomMessages();

    setState(() {
      _customMessages = messages;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Custom Messages',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppConstants.primaryColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : _customMessages.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.message_outlined,
                  size: 48,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No custom messages yet',
                style: TextStyle(
                  color: AppConstants.primaryTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add custom messages when sending texts to friends',
                style: TextStyle(
                  color: AppConstants.secondaryTextColor,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              final dragBorderRadius = BorderRadius.circular(16);

              return Material(
                color: Colors.transparent,
                borderRadius: dragBorderRadius,
                elevation: 0,
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: dragBorderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2 * animation.value),
                            blurRadius: 8 * animation.value,
                            offset: Offset(0, 4 * animation.value),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: child,
                ),
              );
            },
            itemCount: _customMessages.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _customMessages.removeAt(oldIndex);
                _customMessages.insert(newIndex, item);

                // Save the new order
                Provider.of<FriendsProvider>(context, listen: false)
                    .storageService
                    .saveCustomMessages(_customMessages);
              });
            },
            itemBuilder: (context, index) {
              return Card(
                key: ValueKey(_customMessages[index]),
                margin: const EdgeInsets.symmetric(vertical: 5),
                elevation: 0,
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppConstants.borderColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppConstants.deleteColor,
                          size: 22,
                        ),
                        onPressed: () => _confirmDelete(index),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        splashRadius: 24,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _customMessages[index],
                            style: TextStyle(
                              fontSize: 15,
                              color: AppConstants.primaryTextColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_handle,
                            color: AppConstants.secondaryTextColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMessageDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Future<bool> _confirmDelete(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Message',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.primaryTextColor,
            letterSpacing: -0.2,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this custom message?',
          style: TextStyle(
            fontSize: 15,
            color: AppConstants.primaryTextColor,
            height: 1.4,
          ),
        ),
        backgroundColor: AppConstants.dialogBackgroundColor,
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.all(14),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.deleteColor,
              padding: const EdgeInsets.all(14),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );

    if (shouldDelete == true) {
      _deleteMessage(index);
    }

    return shouldDelete ?? false;
  }

  void _deleteMessage(int index) {
    final deletedMessage = _customMessages[index];

    // Remove the message
    setState(() {
      _customMessages.removeAt(index);
    });

    // Remove from storage
    Provider.of<FriendsProvider>(context, listen: false)
        .storageService
        .deleteCustomMessage(deletedMessage);

    // Show snackbar with updated styling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Message deleted',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _customMessages.insert(index, deletedMessage);
              Provider.of<FriendsProvider>(context, listen: false)
                  .storageService
                  .saveCustomMessages(_customMessages);
            });
          },
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showAddMessageDialog() {
    final textController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Add Custom Message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: dialogWidth,
            child: TextFormField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelStyle: TextStyle(
                  fontSize: 15,
                  color: AppConstants.secondaryTextColor,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(
                fontSize: 15,
                color: AppConstants.primaryTextColor,
                height: 1.4,
              ),
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
            ),
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  Navigator.pop(context);

                  // Add the new message
                  setState(() {
                    _customMessages.add(textController.text);
                  });

                  // Save to storage
                  await Provider.of<FriendsProvider>(context, listen: false)
                      .storageService
                      .saveCustomMessages(_customMessages);

                  // Show a brief feedback that message was saved with updated styling
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Message saved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      },
    );
  }
}