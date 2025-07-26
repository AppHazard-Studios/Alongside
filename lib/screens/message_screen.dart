// lib/screens/message_screen.dart - FIXED FOR iOS-CORRECT SIZING AND LAYOUT
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
import '../utils/responsive_utils.dart';
import '../utils/text_styles.dart';
import '../services/notification_service.dart';
import '../services/toast_service.dart';

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
    _recordMessageAction();
    _loadMessages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _recordMessageAction() async {
    final prefs = await SharedPreferences.getInstance();

    final pendingAction = prefs.getString('pending_notification_action');
    if (pendingAction == null || !pendingAction.contains(widget.friend.id)) {
      await prefs.setInt('last_action_${widget.friend.id}', DateTime.now().millisecondsSinceEpoch);

      final notificationService = NotificationService();
      await notificationService.scheduleReminder(widget.friend);

      print("📱 Manual message action recorded for ${widget.friend.name}");
    }
  }

  Future<void> _loadMessages() async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final messages = await provider.storageService.getCustomMessages();

    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_messages') ?? [];

    setState(() {
      _customMessages = messages;
      _favoriteMessages = favorites;
      _isLoading = false;
    });
  }

  Future<void> _recordFriendInteraction() async {
    try {
      final notificationService = NotificationService();
      await notificationService.recordFriendInteraction(widget.friend.id);
      print("📝 Recorded manual interaction with ${widget.friend.name}");
    } catch (e) {
      print("❌ Error recording interaction: $e");
    }
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
        middle: Text(
          'Send Message',
          style: AppTextStyles.scaledNavTitle(context).copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: ResponsiveUtils.scaledContainerSize(context, 32),
            height: ResponsiveUtils.scaledContainerSize(context, 32),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              CupertinoIcons.back,
              color: AppColors.primary,
              size: ResponsiveUtils.scaledIconSize(context, 16),
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
                              style: AppTextStyles.scaledHeadline(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.friend.phoneNumber,
                              style: AppTextStyles.scaledSubhead(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if ((widget.friend.helpingWith != null &&
                      widget.friend.helpingWith!.isNotEmpty) ||
                      (widget.friend.theyHelpingWith != null &&
                          widget.friend.theyHelpingWith!.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 0.5,
                      color: CupertinoColors.systemGrey5,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.friend.helpingWith != null &&
                      widget.friend.helpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.heart_fill,
                            color: AppColors.primary,
                            size: ResponsiveUtils.scaledIconSize(context, 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alongside them in:',
                                style: AppTextStyles.scaledCaption(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.friend.helpingWith!,
                                style: AppTextStyles.scaledSubhead(context).copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.friend.theyHelpingWith != null &&
                        widget.friend.theyHelpingWith!.isNotEmpty)
                      const SizedBox(height: 12),
                  ],

                  if (widget.friend.theyHelpingWith != null &&
                      widget.friend.theyHelpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.person_2_fill,
                            color: AppColors.tertiary,
                            size: ResponsiveUtils.scaledIconSize(context, 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alongside you in:',
                                style: AppTextStyles.scaledCaption(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.friend.theyHelpingWith!,
                                style: AppTextStyles.scaledSubhead(context).copyWith(
                                  color: AppColors.textPrimary,
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: ResponsiveUtils.scaledIconSize(context, 14),
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to send • Hold for options',
                    style: AppTextStyles.scaledCaption(context).copyWith(
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: ResponsiveUtils.scaledContainerSize(context, 40),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_categories.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: ResponsiveUtils.scaledContainerSize(context, 8),
                    width: _currentPage == index
                        ? ResponsiveUtils.scaledContainerSize(context, 24)
                        : ResponsiveUtils.scaledContainerSize(context, 8),
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
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                vertical: ResponsiveUtils.scaledSpacing(context, 8)
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category,
              style: AppTextStyles.scaledCallout(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),

          Expanded(
            child: _buildCategoryContent(categoryIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(int categoryIndex) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final categorizedMessages =
    provider.storageService.getCategorizedMessages();

    switch (categoryIndex) {
      case 0:
        return _buildFavoritesList();
      case 1:
        return _buildMessagesList(categorizedMessages['Check-ins'] ?? []);
      case 2:
        return _buildMessagesList(
            categorizedMessages['Support & Struggle'] ?? []);
      case 3:
        return _buildMessagesList(categorizedMessages['Confession'] ?? []);
      case 4:
        return _buildMessagesList(categorizedMessages['Celebration'] ?? []);
      case 5:
        return _buildMessagesList(categorizedMessages['Prayer Requests'] ?? []);
      case 6:
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
              size: ResponsiveUtils.scaledIconSize(context, 48),
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite messages yet',
              style: AppTextStyles.scaledCallout(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _showFavoritePicker(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.star_fill,
                    color: CupertinoColors.white,
                    size: ResponsiveUtils.scaledIconSize(context, 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Favorites',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _favoriteMessages.length,
            itemBuilder: (context, index) {
              final message = _favoriteMessages[index];
              return _buildMessageCard(message, isFavorite: true);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            border: Border(
              top: BorderSide(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
            ),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.scaledSpacing(context, 14)
            ),
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            onPressed: () => _showFavoritePicker(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  color: CupertinoColors.white,
                  size: ResponsiveUtils.scaledIconSize(context, 18),
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Favorites',
                  style: AppTextStyles.scaledButton(context).copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
              size: ResponsiveUtils.scaledIconSize(context, 48),
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No custom messages yet',
              style: AppTextStyles.scaledCallout(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _showCustomMessageDialog(context),
              child: Text(
                'Add your first message',
                style: AppTextStyles.scaledButton(context).copyWith(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
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
        ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            border: Border(
              top: BorderSide(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.scaledSpacing(context, 14)
                ),
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _showCustomMessageDialog(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.white,
                      size: ResponsiveUtils.scaledIconSize(context, 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Custom Message',
                      style: AppTextStyles.scaledButton(context).copyWith(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
      onLongPress: () => _showMessageOptions(context, message,
          isCustom: isCustom, customIndex: customIndex),
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
                size: ResponsiveUtils.scaledIconSize(context, 18),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.scaledCallout(context).copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isCustom) ...[
              GestureDetector(
                onTap: () =>
                    _showCustomMessageOptions(context, message, customIndex!),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                ),
              ),
            ] else ...[
              Icon(
                CupertinoIcons.arrow_right_circle_fill,
                color: AppColors.primary,
                size: ResponsiveUtils.scaledIconSize(context, 22),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, String message,
      {bool isCustom = false, int? customIndex}) {
    final isFavorite = _favoriteMessages.contains(message);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          message.length > 50 ? '${message.substring(0, 50)}...' : message,
          style: AppTextStyles.scaledSubhead(context),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendMessage(context, message);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.bubble_left_fill,
                  color: CupertinoColors.systemBlue,
                  size: ResponsiveUtils.scaledIconSize(context, 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Send via Messages',
                  style: AppTextStyles.scaledCallout(context),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _shareMessage(context, message);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.share,
                  color: CupertinoColors.systemBlue,
                  size: ResponsiveUtils.scaledIconSize(context, 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Share to Other Apps',
                  style: AppTextStyles.scaledCallout(context),
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
                ToastService.showSuccess(context, 'Added to favorites');
              },
              child: Text(
                'Add to Favorites',
                style: AppTextStyles.scaledCallout(context),
              ),
            ),
          if (isCustom && customIndex != null) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editCustomMessage(context, message, customIndex);
              },
              child: Text(
                'Edit Message',
                style: AppTextStyles.scaledCallout(context),
              ),
            ),
          ],
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.scaledButton(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomMessageOptions(
      BuildContext context, String message, int index) {
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
                ToastService.showSuccess(context, 'Added to favorites');
              },
              child: Text(
                'Add to Favorites',
                style: AppTextStyles.scaledCallout(context),
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editCustomMessage(context, message, index);
            },
            child: Text(
              'Edit Message',
              style: AppTextStyles.scaledCallout(context),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomMessage(context, message, index);
            },
            isDestructiveAction: true,
            child: Text(
              'Delete Message',
              style: AppTextStyles.scaledCallout(context),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.scaledButton(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoritePicker() {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final allMessages = <String>[];
    final categorizedMessages =
    provider.storageService.getCategorizedMessages();

    categorizedMessages.forEach((category, messages) {
      allMessages.addAll(messages);
    });

    allMessages.addAll(_customMessages);

    final selectedMessages = List<String>.from(_favoriteMessages);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _FavoritePickerModal(
        allMessages: allMessages,
        selectedMessages: selectedMessages,
        onSave: (newFavorites) {
          _updateFavorites(newFavorites);
          ToastService.showSuccess(context, 'Favorites updated');
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
        sharePositionOrigin:
        box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      ToastService.showError(context, 'Unable to share message');
    }
  }

  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Create Message',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
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
            style: AppTextStyles.scaledCallout(context),
            placeholderStyle: AppTextStyles.scaledTextStyle(
              context,
              AppTextStyles.placeholder.copyWith(
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
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
            child: Text(
              'Cancel',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                Navigator.pop(context);
                final storageService =
                    Provider.of<FriendsProvider>(context, listen: false)
                        .storageService;
                await storageService.addCustomMessage(textController.text);
                _loadMessages();
                ToastService.showSuccess(context, 'Message saved! ✨');
              }
            },
            child: Text(
              'Save',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
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
        title: Text(
          'Edit Message',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
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
            style: AppTextStyles.scaledCallout(context),
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(
              'Cancel',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              if (textController.text.isNotEmpty &&
                  textController.text != message) {
                Navigator.pop(context);

                setState(() {
                  _customMessages[index] = textController.text;
                });

                final storageService =
                    Provider.of<FriendsProvider>(context, listen: false)
                        .storageService;
                await storageService.saveCustomMessages(_customMessages);

                ToastService.showSuccess(context, 'Message updated! ✨');
              }
            },
            child: Text(
              'Save',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteCustomMessage(
      BuildContext context, String message, int index) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Delete Message',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to delete this custom message?',
            style: AppTextStyles.scaledCallout(context).copyWith(
              height: 1.3,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: Text(
              'Delete',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _customMessages.removeAt(index);
        _favoriteMessages.remove(message);
      });

      final storageService =
          Provider.of<FriendsProvider>(context, listen: false).storageService;
      await storageService.saveCustomMessages(_customMessages);
      await _updateFavorites(_favoriteMessages);

      ToastService.showSuccess(context, 'Message deleted');
    }
  }

  Widget _buildProfileImage() {
    return Container(
      width: ResponsiveUtils.scaledContainerSize(context, 48),
      height: ResponsiveUtils.scaledContainerSize(context, 48),
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
          style: TextStyle(fontSize: ResponsiveUtils.scaledFontSize(context, 24)),
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
    final phoneNumber =
    widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            width: ResponsiveUtils.scaledContainerSize(context, 120),
            height: ResponsiveUtils.scaledContainerSize(context, 120),
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
                Text(
                  'Sending...',
                  style: AppTextStyles.scaledCallout(context).copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      await _recordFriendInteraction();
      final smsUri =
      Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      final storageService =
          Provider.of<FriendsProvider>(context, listen: false).storageService;
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
            title: Text(
              '❌ Error',
              style: AppTextStyles.scaledDialogTitle(context).copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Unable to open messaging app. Please try again later.',
                style: AppTextStyles.scaledCallout(context).copyWith(
                  height: 1.3,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: AppTextStyles.scaledButton(context).copyWith(
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
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Select Favorites',
                  style: AppTextStyles.scaledHeadline(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    widget.onSave(_selected);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                          width: ResponsiveUtils.scaledContainerSize(context, 24),
                          height: ResponsiveUtils.scaledContainerSize(context, 24),
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
                              ? Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoColors.white,
                            size: ResponsiveUtils.scaledIconSize(context, 14),
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: AppTextStyles.scaledSubhead(context).copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
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