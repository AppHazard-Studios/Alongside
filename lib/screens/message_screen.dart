// lib/screens/message_screen.dart - Redesigned with better UX and sharing
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
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

  final PageController _pageController = PageController();
  int _currentPage = 0;

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> _updateFavorites(List<String> newFavorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_messages', newFavorites);
    setState(() {
      _favoriteMessages = newFavorites;
    });
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
            // Friend info header with alongside details
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CupertinoColors.systemGrey5,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Friend basic info
                  Row(
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
                            const SizedBox(height: 4),
                            Text(
                              widget.friend.phoneNumber,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Alongside information
                  if ((widget.friend.helpingWith != null && widget.friend.helpingWith!.isNotEmpty) ||
                      (widget.friend.theyHelpingWith != null && widget.friend.theyHelpingWith!.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 0.5,
                      color: CupertinoColors.systemGrey5,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // What you're alongside them in
                  if (widget.friend.helpingWith != null && widget.friend.helpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.heart_fill,
                            color: AppColors.primary,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alongside them in:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.friend.helpingWith!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.friend.theyHelpingWith != null && widget.friend.theyHelpingWith!.isNotEmpty)
                      const SizedBox(height: 12),
                  ],

                  // What they're alongside you in
                  if (widget.friend.theyHelpingWith != null && widget.friend.theyHelpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_2_fill,
                            color: AppColors.tertiary,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Alongside you in:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tertiary,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.friend.theyHelpingWith!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Help text for interactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to send • Hold for options',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),

            // Category indicator dots
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_categories.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Swipeable message pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  HapticFeedback.lightImpact();
                },
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryPage(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPage(int categoryIndex) {
    final category = _categories[categoryIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Category title
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),

          // Messages content
          Expanded(
            child: _buildCategoryContent(categoryIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(int categoryIndex) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final categorizedMessages = provider.storageService.getCategorizedMessages();

    switch (categoryIndex) {
      case 0: // Favorites
        return _buildFavoritesList();
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

  Widget _buildFavoritesList() {
    if (_favoriteMessages.isEmpty) {
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
            const SizedBox(height: 24),
            CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _showFavoritePicker(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    color: CupertinoColors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add Favorites',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: _favoriteMessages.length,
          itemBuilder: (context, index) {
            final message = _favoriteMessages[index];
            return _buildMessageCard(message, isFavorite: true);
          },
        ),

        // Add more favorites button
        Positioned(
          right: 16,
          bottom: 16,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showFavoritePicker(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppColors.primaryShadow,
              ),
              child: const Icon(
                CupertinoIcons.star_fill,
                size: 24,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList(List<String> messages) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isFavorite = _favoriteMessages.contains(message);
        return _buildMessageCard(message, isFavorite: isFavorite);
      },
    );
  }

  Widget _buildCustomMessagesList() {
    if (_customMessages.isEmpty) {
      return Center(
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
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: _customMessages.length,
          itemBuilder: (context, index) {
            final message = _customMessages[index];
            final isFavorite = _favoriteMessages.contains(message);
            return _buildMessageCard(
              message,
              isFavorite: isFavorite,
              isCustom: true,
              customIndex: index,
            );
          },
        ),

        // Floating action button - only show if there are messages
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

  Widget _buildMessageCard(
      String message, {
        required bool isFavorite,
        bool isCustom = false,
        int? customIndex,
      }) {
    return GestureDetector(
      onTap: () => _sendMessage(context, message),
      onLongPress: () => _showMessageOptions(context, message, isCustom: isCustom, customIndex: customIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            if (isFavorite) ...[
              Icon(
                CupertinoIcons.star_fill,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 12),
            ],
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
            if (isCustom) ...[
              GestureDetector(
                onTap: () => _showCustomMessageOptions(context, message, customIndex!),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    size: 18,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                CupertinoIcons.arrow_right_circle_fill,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, String message, {bool isCustom = false, int? customIndex}) {
    final isFavorite = _favoriteMessages.contains(message);

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
              _sendMessage(context, message);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.bubble_left_fill,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Send via Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _shareMessage(context, message);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.share,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Share to Other Apps',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          if (!isFavorite)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _favoriteMessages.add(message);
                });
                _updateFavorites(_favoriteMessages);
                _showToast('Added to favorites');
              },
              child: const Text(
                'Add to Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          if (isCustom && customIndex != null) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editCustomMessage(context, message, customIndex);
              },
              child: const Text(
                'Edit Message',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
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

  void _showCustomMessageOptions(BuildContext context, String message, int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          if (!_favoriteMessages.contains(message))
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _favoriteMessages.add(message);
                });
                _updateFavorites(_favoriteMessages);
                _showToast('Added to favorites');
              },
              child: const Text(
                'Add to Favorites',
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

  void _showFavoritePicker() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final allMessages = <String>[];
    final categorizedMessages = provider.storageService.getCategorizedMessages();

    // Add all categorized messages
    categorizedMessages.forEach((category, messages) {
      allMessages.addAll(messages);
    });

    // Add custom messages
    allMessages.addAll(_customMessages);

    // Create a copy of current favorites for editing
    final selectedMessages = List<String>.from(_favoriteMessages);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _FavoritePickerModal(
        allMessages: allMessages,
        selectedMessages: selectedMessages,
        onSave: (newFavorites) {
          _updateFavorites(newFavorites);
          _showToast('Favorites updated');
        },
      ),
    );
  }

  void _shareMessage(BuildContext context, String message) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        message,
        subject: 'Message for ${widget.friend.name}',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      _showToast('Unable to share message');
    }
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
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
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

  void _deleteCustomMessage(BuildContext context, String message, int index) async {
    final shouldDelete = await showCupertinoDialog<bool>(
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
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
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

    if (shouldDelete == true) {
      setState(() {
        _customMessages.removeAt(index);
        // Also remove from favorites if it was favorited
        _favoriteMessages.remove(message);
      });

      final storageService = Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.saveCustomMessages(_customMessages);
      await _updateFavorites(_favoriteMessages);

      _showToast('Message deleted');
    }
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

// Favorite picker modal widget
class _FavoritePickerModal extends StatefulWidget {
  final List<String> allMessages;
  final List<String> selectedMessages;
  final Function(List<String>) onSave;

  const _FavoritePickerModal({
    required this.allMessages,
    required this.selectedMessages,
    required this.onSave,
  });

  @override
  State<_FavoritePickerModal> createState() => _FavoritePickerModalState();
}

class _FavoritePickerModalState extends State<_FavoritePickerModal> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedMessages);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                const Text(
                  'Select Favorites',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    widget.onSave(_selected);
                    Navigator.pop(context);
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
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.allMessages.length,
              itemBuilder: (context, index) {
                final message = widget.allMessages[index];
                final isSelected = _selected.contains(message);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(message);
                      } else {
                        _selected.add(message);
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : CupertinoColors.systemGrey5,
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : CupertinoColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : CupertinoColors.systemGrey3,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoColors.white,
                            size: 14,
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontFamily: '.SF Pro Text',
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
        ],
      ),
    );
  }
}