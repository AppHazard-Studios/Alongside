// screens/message_screen.dart - Updated to match the popup style exactly

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/friend.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import '../main.dart';
import '../widgets/friend_card.dart';

class MessageScreen extends StatefulWidget {
  final Friend friend;

  const MessageScreen({Key? key, required this.friend}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
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
    final allMessages = [...AppConstants.presetMessages, ..._customMessages];

    // Match exact padding from popup dialog
    final horizontalPadding = 16.0;

    return Scaffold(
      backgroundColor: CupertinoColors.systemBackground, // Match popup background
      appBar: AppBar(
        title: Text(
          'Message ${widget.friend.name}',
          style: AppTextStyles.navTitle,
          textAlign: TextAlign.center, // Center text like in popup
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true, // Center title
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
        actions: [
          // Settings icon in iOS style - match the popup styling exactly
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const ManageMessagesScreen(),
                  ),
                );
              },
              icon: const Icon(
                CupertinoIcons.gear,
                color: Color(0xFF007AFF),
                size: 16,
              ),
              padding: EdgeInsets.zero,
              splashRadius: 14,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
        children: [
          // iOS-style separator - exactly like in popup
          Container(
            height: 0.5,
            color: CupertinoColors.separator,
          ),

          // Message list - match popup styling exactly
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: horizontalPadding,
              ),
              itemCount: allMessages.length + 1,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                if (index == allMessages.length) {
                  // Create custom message option - match popup styling exactly
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () => _showCustomMessageDialog(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.add_circled,
                              size: 18,
                              color: Color(0xFF007AFF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Create custom message',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF007AFF),
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Regular message option - match popup styling exactly
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () => _sendMessage(context, allMessages[index]),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CupertinoColors.systemGrey5,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        allMessages[index],
                        style: AppTextStyles.cardContent,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
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
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.systemGrey4,
                  width: 0.5,
                ),
              ),
              style: AppTextStyles.cardContent,
              placeholderStyle: TextStyle(
                fontSize: 15,
                color: CupertinoColors.placeholderText,
                fontFamily: '.SF Pro Text',
                letterSpacing: -0.24,
              ),
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.41,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  final storageService = Provider.of<FriendsProvider>(
                    context,
                    listen: false,
                  ).storageService;

                  await storageService.addCustomMessage(textController.text);
                  Navigator.pop(context);
                  _loadMessages(); // Reload the messages list

                  _showSuccessToast(context, 'Message saved');
                }
              },
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.41,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessToast(BuildContext context, String message) {
    // iOS doesn't have built-in toasts, but we can simulate with an overlay
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 15,
                fontFamily: '.SF Pro Text',
                letterSpacing: -0.24,
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

  void _sendMessage(BuildContext context, String message) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');

      final launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch SMS app');
      }

      // Return to home screen after launching SMS
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
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
}