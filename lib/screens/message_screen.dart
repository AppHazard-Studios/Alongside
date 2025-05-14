// lib/screens/message_screen_new.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/friend.dart';
import '../main.dart';
import '../utils/text_styles.dart';
import '../utils/colors.dart';
import '../widgets/character_components.dart';
import '../widgets/illustrations.dart';
import 'manage_messages_screen.dart';

class MessageScreenNew extends StatefulWidget {
  final Friend friend;

  const MessageScreenNew({Key? key, required this.friend}) : super(key: key);

  @override
  State<MessageScreenNew> createState() => _MessageScreenNewState();
}

class _MessageScreenNewState extends State<MessageScreenNew> {
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
    // Get background color based on friend name (for consistency)
    final nameHash = widget.friend.name.hashCode.abs();
    final colorIndex = nameHash % AppColors.extendedPalette.length;
    final themeColor = AppColors.extendedPalette[colorIndex];
    final lightThemeColor = themeColor.withOpacity(0.15);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Message ${widget.friend.name}',
          style: AppTextStyles.navTitle.copyWith(
            fontWeight: FontWeight.w700,
            color: themeColor,
          ),
        ),
        backgroundColor: lightThemeColor,
        border: null, // Remove border for modern look
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.back,
              color: themeColor,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.gear,
              size: 18,
              color: themeColor,
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ManageMessagesScreen(),
              ),
            );
          },
        ),
      ),
      child: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(
              radius: 14,
              color: themeColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading messages...',
              style: TextStyle(
                color: themeColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : _buildMessageList(themeColor, lightThemeColor),
    );
  }

  Widget _buildMessageList(Color themeColor, Color lightThemeColor) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final allMessages = [...provider.storageService.getDefaultMessages(), ..._customMessages];

    return SafeArea(
      child: Column(
        children: [
          // Friend profile at top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightThemeColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                CharacterComponents.playfulProfilePicture(
                  imageOrEmoji: widget.friend.profileImage,
                  isEmoji: widget.friend.isEmoji,
                  size: 60,
                  backgroundColor: themeColor.withOpacity(0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.friend.name,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: themeColor,
                        ),
                      ),
                      if (widget.friend.helpingWith != null && widget.friend.helpingWith!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Alongside in: ${widget.friend.helpingWith}',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Illustrations.messagingIllustration(size: 60),
              ],
            ),
          ),

          // Message list with categories
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check-in section
                  _buildMessageSection(
                    title: '✅ Check-ins',
                    color: AppColors.focused,
                    messages: allMessages.where((msg) =>
                    msg.contains('checking in') ||
                        msg.contains('Thinking of you')
                    ).toList(),
                  ),

                  // Support section
                  _buildMessageSection(
                    title: '🟡 Support & Struggle',
                    color: AppColors.warning,
                    messages: allMessages.where((msg) =>
                    msg.contains('Feeling tempted') ||
                        msg.contains('Struggling')
                    ).toList(),
                  ),

                  // Confession section
                  _buildMessageSection(
                    title: '🔴 Confession',
                    color: AppColors.secondary,
                    messages: allMessages.where((msg) =>
                    msg.contains('slipped up') ||
                        msg.contains('Not proud')
                    ).toList(),
                  ),

                  // Custom messages section
                  _buildMessageSection(
                    title: '💬 Your Custom Messages',
                    color: themeColor,
                    messages: _customMessages,
                    isEmpty: _customMessages.isEmpty,
                    emptyStateMessage: 'No custom messages yet. Create your first one!',
                  ),
                ],
              ),
            ),
          ),

          // Create custom message button at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: CharacterComponents.playfulButton(
              label: 'Create Custom Message',
              icon: CupertinoIcons.add,
              backgroundColor: themeColor,
              onPressed: () => _showCustomMessageDialog(context, themeColor),
            ),
          ),
        ],
      ),
    );
  }

  // Message section with title and colored accent
  Widget _buildMessageSection({
    required String title,
    required Color color,
    required List<String> messages,
    bool isEmpty = false,
    String emptyStateMessage = '',
  }) {
    if (messages.isEmpty && !isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with animated appearance
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuint,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 10),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Empty state if needed
          if (isEmpty && messages.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.chat_bubble,
                      size: 20,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      emptyStateMessage,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message list with staggered animation
          ...messages.asMap().entries.map((entry) {
            final index = entry.key;
            final message = entry.value;

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
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CharacterComponents.playfulCard(
                  backgroundColor: Colors.white,
                  borderColor: color.withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  borderRadius: 12,
                  onTap: () => _sendMessage(context, message),
                  child: Text(
                    message,
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Show dialog to create a custom message
  void _showCustomMessageDialog(BuildContext context, Color themeColor) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Create Message',
          style: AppTextStyles.dialogTitle.copyWith(
            color: themeColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              // Little message illustration
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 60,
                height: 60,
                child: Illustrations.messagingIllustration(size: 60),
              ),
              CupertinoTextField(
                controller: textController,
                placeholder: 'Type your message...',
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeColor.withOpacity(0.3),
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
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                Navigator.pop(context);
                final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
                await storageService.addCustomMessage(textController.text);
                _loadMessages(); // Reload messages
                _showSuccessToast(context, 'Message saved! ✨', themeColor);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show success toast with animation
  void _showSuccessToast(BuildContext context, String message, Color themeColor) {
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor,
                    themeColor.withBlue((themeColor.blue + 40).clamp(0, 255)),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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

  // Send a message with an animated confirmation
  void _sendMessage(BuildContext context, String message) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      // Show sending animation
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 14,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sending...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Slight delay for UX
      await Future.delayed(const Duration(milliseconds: 300));

      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      // Pop the sending dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Navigate back to home screen
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Pop the sending dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text(
              '❌ Error',
              style: TextStyle(
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w700,
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
}