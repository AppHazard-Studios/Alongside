// lib/screens/message_screen.dart - Fixed navbar, removed duplicate name, fixed wrapping
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/friend.dart';
import '../providers/friends_provider.dart';
import '../utils/text_styles.dart';
import '../utils/colors.dart';
import '../widgets/character_components.dart';
import '../widgets/illustrations.dart';

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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        // Removed friend name - just "Send Message" to avoid duplication
        middle: const Text(
          'Send Message',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary, // Consistent primary color
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor: AppColors.primaryLight, // Light background with primary color
        border: null,
        // Consistent outline button style (matching home screen)
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              CupertinoIcons.back,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Consistent outline button style for settings
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              CupertinoIcons.ellipsis,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => _showMessageOptions(context),
        ),
      ),
      child: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(
              radius: 14,
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              'Loading messages...',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      )
          : _buildMessageList(),
    );
  }

  Widget _buildMessageList() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final allMessages = [...provider.storageService.getDefaultMessages(), ..._customMessages];

    return SafeArea(
      child: Column(
        children: [
          // Friend profile at top - with proper text wrapping
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align to top for wrapping
              children: [
                // Profile image
                Container(
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
                ),
                const SizedBox(width: 16),
                Expanded( // Critical: This allows text to wrap properly
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.friend.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: '.SF Pro Text',
                        ),
                        maxLines: 2, // Allow name wrapping
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Show what you're alongside them in with proper wrapping
                      if (widget.friend.helpingWith != null && widget.friend.helpingWith!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Alongside them: ${widget.friend.helpingWith}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontFamily: '.SF Pro Text',
                            height: 1.3,
                          ),
                          maxLines: 3, // Allow multiple lines
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Show what they're alongside you in with proper wrapping
                      if (widget.friend.theyHelpingWith != null && widget.friend.theyHelpingWith!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Alongside you: ${widget.friend.theyHelpingWith}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontFamily: '.SF Pro Text',
                            height: 1.3,
                          ),
                          maxLines: 3, // Allow multiple lines
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                  // Clean, simplified message sections
                  _buildCleanMessageSection(
                    title: 'Check-ins',
                    color: AppColors.success,
                    messages: allMessages.where((msg) =>
                    msg.contains('checking in') ||
                        msg.contains('Thinking of you')
                    ).toList(),
                  ),

                  _buildCleanMessageSection(
                    title: 'Support & Struggle',
                    color: AppColors.warning,
                    messages: allMessages.where((msg) =>
                    msg.contains('Feeling tempted') ||
                        msg.contains('Struggling')
                    ).toList(),
                  ),

                  _buildCleanMessageSection(
                    title: 'Confession',
                    color: AppColors.error,
                    messages: allMessages.where((msg) =>
                    msg.contains('slipped up') ||
                        msg.contains('Not proud')
                    ).toList(),
                  ),

                  _buildCleanMessageSection(
                    title: 'Your Custom Messages',
                    color: AppColors.primary,
                    messages: _customMessages,
                    isEmpty: _customMessages.isEmpty,
                    emptyStateMessage: 'No custom messages yet. Create your first one!',
                  ),
                ],
              ),
            ),
          ),

          // Narrower floating button (matching home screen style)
          Positioned(
            right: 20,
            bottom: 20,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showCustomMessageDialog(context),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.primaryShadow,
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  size: 28,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Clean message section without kitschy elements
  Widget _buildCleanMessageSection({
    required String title,
    required Color color,
    required List<String> messages,
    bool isEmpty = false,
    String emptyStateMessage = '',
    bool isCustom = false, // NEW: Flag for custom messages
  }) {
    if (messages.isEmpty && !isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean section title
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),

          // Empty state if needed
          if (isEmpty && messages.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  emptyStateMessage,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 15,
                    fontFamily: '.SF Pro Text',
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Clean message list
          ...messages.asMap().entries.map((entry) {
            final index = entry.key;
            final message = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _sendMessage(context, message),
                onLongPress: isCustom ? () => _showCustomMessageOptions(context, message, index) : null, // NEW: Long press for custom messages
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Small colored indicator
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Message text
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontFamily: '.SF Pro Text',
                            height: 1.4,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Send arrow or options for custom messages
                      if (isCustom) ...[
                        GestureDetector(
                          onTap: () => _showCustomMessageOptions(context, message, index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              CupertinoIcons.ellipsis,
                              color: color.withOpacity(0.6),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        CupertinoIcons.arrow_right_circle,
                        color: color.withOpacity(0.6),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Message section with title and colored accent - DEPRECATED, keeping for reference
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
                      fontFamily: '.SF Pro Text',
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Expanded( // Allow text to wrap
                    child: Text(
                      emptyStateMessage,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontFamily: '.SF Pro Text',
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontFamily: '.SF Pro Text',
                      height: 1.4, // Better line height
                    ),
                    maxLines: 10, // Allow long messages to wrap
                    overflow: TextOverflow.ellipsis,
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
  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Create Message',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
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
              // Text input with proper styling
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
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
                placeholderStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
                minLines: 1,
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
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
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
                _showSuccessToast(context, 'Message saved! ✨');
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show success toast with animation
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.primaryShadow,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Message saved! ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
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
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 14,
                ),
                SizedBox(height: 16),
                Text(
                  'Sending...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
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
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontFamily: '.SF Pro Text',
              ),
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Unable to open messaging app. Please try again later.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  // NEW: Show message options (replaces manage messages screen)
  void _showMessageOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Message Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCustomMessageDialog(context);
            },
            child: const Text(
              'Create Custom Message',
              style: TextStyle(
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          if (_customMessages.isNotEmpty)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showAllCustomMessages(context);
              },
              child: const Text(
                'Manage All Custom Messages',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Show custom message options (edit/delete)
  void _showCustomMessageOptions(BuildContext context, String message, int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          message.length > 50 ? '${message.substring(0, 50)}...' : message,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editCustomMessage(context, message, index);
            },
            child: const Text(
              'Edit Message',
              style: TextStyle(
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomMessage(context, message, index);
            },
            isDestructiveAction: true,
            child: const Text(
              'Delete Message',
              style: TextStyle(
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Edit custom message
  void _editCustomMessage(BuildContext context, String message, int index) {
    final textController = TextEditingController(text: message);

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Edit Message',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Type your message...',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontFamily: '.SF Pro Text',
            ),
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (textController.text.isNotEmpty && textController.text != message) {
                Navigator.pop(context);

                // Update the message
                setState(() {
                  _customMessages[index] = textController.text;
                });

                // Save to storage
                final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
                await storageService.saveCustomMessages(_customMessages);

                _showSuccessToast(context, 'Message updated! ✨');
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Delete custom message
  void _deleteCustomMessage(BuildContext context, String message, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Delete Message',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to delete this custom message?',
            style: TextStyle(
              fontSize: 16,
              height: 1.3,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);

              // Remove the message
              setState(() {
                _customMessages.removeAt(index);
              });

              // Save to storage
              final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
              await storageService.saveCustomMessages(_customMessages);

              // Close any open modals to refresh the view
              Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == null);

              _showSuccessToast(context, 'Message deleted! 🗑️'); // FIXED: Correct message
            },
            isDestructiveAction: true,
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Show all custom messages for bulk management
  void _showAllCustomMessages(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Custom Messages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
            // Messages list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _customMessages.length,
                itemBuilder: (context, index) {
                  final message = _customMessages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: '.SF Pro Text',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 32,
                            onPressed: () => _showCustomMessageOptions(context, message, index),
                            child: const Icon(
                              CupertinoIcons.ellipsis,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                        ],
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
}