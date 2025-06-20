// lib/screens/message_screen.dart - Fixed with CupertinoSegmentedControl
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';
import '../providers/friends_provider.dart';
import '../utils/colors.dart';

class MessageScreenNew extends StatefulWidget {
  final Friend friend;

  const MessageScreenNew({Key? key, required this.friend}) : super(key: key);

  @override
  State<MessageScreenNew> createState() => _MessageScreenNewState();
}

class _MessageScreenNewState extends State<MessageScreenNew> {
  List<String> _customMessages = [];
  List<String> _favoriteMessages = [];
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Favorites',
    'Check-ins',
    'Support & Struggle',
    'Confession',
    'Celebration',
    'Prayer Requests',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final messages = await provider.storageService.getCustomMessages();

    // Load favorites from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_messages') ?? [];

    setState(() {
      _customMessages = messages;
      _favoriteMessages = favorites;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(String message) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (_favoriteMessages.contains(message)) {
        _favoriteMessages.remove(message);
      } else {
        _favoriteMessages.add(message);
      }
    });

    await prefs.setStringList('favorite_messages', _favoriteMessages);
    _showToast(_favoriteMessages.contains(message) ? 'Added to favorites' : 'Removed from favorites');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Send Message',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
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
      ),
      child: _isLoading
          ? const Center(
        child: CupertinoActivityIndicator(radius: 14),
      )
          : SafeArea(
        child: Column(
          children: [
            // Friend info header
            Container(
              padding: const EdgeInsets.all(16),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  _buildProfileImage(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.friend.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                        if (widget.friend.helpingWith != null && widget.friend.helpingWith!.isNotEmpty)
                          Text(
                            'Alongside: ${widget.friend.helpingWith}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontFamily: '.SF Pro Text',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category segmented control
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: CupertinoColors.systemGrey6,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: CupertinoSegmentedControl<int>(
                  children: {
                    for (int i = 0; i < _categories.length; i++)
                      i: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          _categories[i],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ),
                  },
                  onValueChanged: (value) {
                    setState(() {
                      _selectedCategoryIndex = value;
                    });
                  },
                  groupValue: _selectedCategoryIndex,
                  unselectedColor: CupertinoColors.white,
                  selectedColor: AppColors.primary,
                  borderColor: AppColors.primary,
                  pressedColor: AppColors.primaryLight,
                ),
              ),
            ),

            // Messages content
            Expanded(
              child: _buildCategoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final categorizedMessages = provider.storageService.getCategorizedMessages();

    switch (_selectedCategoryIndex) {
      case 0: // Favorites
        return _buildMessagesList(_favoriteMessages, isSpecial: true);
      case 1: // Check-ins
        return _buildMessagesList(categorizedMessages['Check-ins'] ?? []);
      case 2: // Support & Struggle
        return _buildMessagesList(categorizedMessages['Support & Struggle'] ?? []);
      case 3: // Confession
        return _buildMessagesList(categorizedMessages['Confession'] ?? []);
      case 4: // Celebration
        return _buildMessagesList(categorizedMessages['Celebration'] ?? []);
      case 5: // Prayer Requests
        return _buildMessagesList(categorizedMessages['Prayer Requests'] ?? []);
      case 6: // Custom
        return _buildCustomMessagesList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMessagesList(List<String> messages, {bool isSpecial = false}) {
    if (messages.isEmpty && isSpecial) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.star,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorite messages yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontFamily: '.SF Pro Text',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Press and hold any message to favorite it',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isFavorite = _favoriteMessages.contains(message);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _sendMessage(context, message),
            onLongPress: () => _toggleFavorite(message),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemGrey5,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontFamily: '.SF Pro Text',
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isFavorite)
                    Icon(
                      CupertinoIcons.star_fill,
                      color: AppColors.warning,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.arrow_right_circle,
                    color: AppColors.primary.withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomMessagesList() {
    return Stack(
      children: [
        if (_customMessages.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.bubble_left,
                  size: 48,
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No custom messages yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => _showCustomMessageDialog(context),
                  child: const Text(
                    'Create First Message',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _customMessages.length,
            itemBuilder: (context, index) {
              final message = _customMessages[index];
              final isFavorite = _favoriteMessages.contains(message);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _sendMessage(context, message),
                  onLongPress: () => _showCustomMessageOptions(context, message, index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontFamily: '.SF Pro Text',
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isFavorite)
                          Icon(
                            CupertinoIcons.star_fill,
                            color: AppColors.warning,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.ellipsis,
                          color: AppColors.textSecondary.withOpacity(0.6),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // Floating action button
        Positioned(
          right: 16,
          bottom: 16,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showCustomMessageDialog(context),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppColors.primaryShadow,
              ),
              child: const Icon(
                CupertinoIcons.add,
                size: 24,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 48,
      height: 48,
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
          style: const TextStyle(fontSize: 24),
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

  void _showToast(String message) {
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: CupertinoColors.white,
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
          child: CupertinoTextField(
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
                _loadMessages();
                _showToast('Message saved! ✨');
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
          if (!_favoriteMessages.contains(message))
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _toggleFavorite(message);
              },
              child: const Text(
                'Add to Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            )
          else
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _toggleFavorite(message);
              },
              child: const Text(
                'Remove from Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
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

                setState(() {
                  _customMessages[index] = textController.text;
                });

                final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
                await storageService.saveCustomMessages(_customMessages);

                _showToast('Message updated! ✨');
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

              setState(() {
                _customMessages.removeAt(index);
              });

              final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
              await storageService.saveCustomMessages(_customMessages);

              if (mounted) {
                setState(() {});
              }

              _showToast('Message deleted! 🗑️');
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

  void _sendMessage(BuildContext context, String message) async {
    final phoneNumber = widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
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

      await Future.delayed(const Duration(milliseconds: 300));

      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      // Track the message sent
      final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.incrementMessagesSent();

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
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
}