// lib/screens/message_screen.dart - FIXED FOR CONSISTENT SCALING WITH HOME SCREEN
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
    'Custom',
    'Check-ins',
    'Support & Struggle',
    'Confession',
    'Celebration',
    'Prayer Requests',
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
      backgroundColor: const Color(0xFFF8FAFC),
      child: _isLoading
          ? const Center(
        child: CupertinoActivityIndicator(radius: 14),
      )
          : SafeArea(
        child: Column(
          children: [
            // Header matching home screen pattern
            Container(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.scaledSpacing(context, 16),
                ResponsiveUtils.scaledSpacing(context, 16),
                ResponsiveUtils.scaledSpacing(context, 16),
                ResponsiveUtils.scaledSpacing(context, 12),
              ),
              child: Row(
                children: [
                  // Title area with icon on left - takes available space
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon first
                        Container(
                          width: ResponsiveUtils.scaledContainerSize(context, 28),
                          height: ResponsiveUtils.scaledContainerSize(context, 28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            CupertinoIcons.chat_bubble_fill,
                            size: ResponsiveUtils.scaledIconSize(context, 16),
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

                        // Title with overflow protection
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Send Message',
                              style: AppTextStyles.scaledAppTitle(context),
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fixed spacing between title and close button
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 16)),

                  // Close button on right
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: ResponsiveUtils.scaledContainerSize(context, 32),
                      height: ResponsiveUtils.scaledContainerSize(context, 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: AppColors.primary,
                        size: ResponsiveUtils.scaledIconSize(context, 16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Friend info card
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.scaledSpacing(context, 16),
              ),
              padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 14)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildProfileImage(),
                      SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.friend.name,
                              style: AppTextStyles.scaledHeadline(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
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
                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
                    Container(
                      height: 0.5,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
                  ],

                  if (widget.friend.helpingWith != null &&
                      widget.friend.helpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: ResponsiveUtils.scaledContainerSize(context, 24),
                          height: ResponsiveUtils.scaledContainerSize(context, 24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.heart_fill,
                            color: AppColors.primary,
                            size: ResponsiveUtils.scaledIconSize(context, 12),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
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
                              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
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
                      SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
                  ],

                  if (widget.friend.theyHelpingWith != null &&
                      widget.friend.theyHelpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: ResponsiveUtils.scaledContainerSize(context, 24),
                          height: ResponsiveUtils.scaledContainerSize(context, 24),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.person_2_fill,
                            color: AppColors.tertiary,
                            size: ResponsiveUtils.scaledIconSize(context, 12),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
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
                              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
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

            // Instructions
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                vertical: ResponsiveUtils.scaledSpacing(context, 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: ResponsiveUtils.scaledIconSize(context, 12),
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 4)),
                  Text(
                    'Tap to send • Hold for options',
                    style: AppTextStyles.scaledCaption(context).copyWith(
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Page indicators
            Container(
              height: ResponsiveUtils.scaledContainerSize(context, 32),
              padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.scaledSpacing(context, 10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_categories.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.scaledSpacing(context, 3)),
                    height: ResponsiveUtils.scaledContainerSize(context, 6),
                    width: _currentPage == index
                        ? ResponsiveUtils.scaledContainerSize(context, 20)
                        : ResponsiveUtils.scaledContainerSize(context, 6),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
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

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Column(
            children: [
              // Compact header - box only around text
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 12)),
                  padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.scaledSpacing(context, 12),
                      vertical: ResponsiveUtils.scaledSpacing(context, 6)
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category,
                    style: AppTextStyles.scaledCallout(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _buildCategoryContent(categoryIndex),
              ),
            ],
          ),
        ),

        // FLOATING BUTTON for Favorites and Custom only
        if (category == 'Favorites' || category == 'Custom')
          Positioned(
            right: ResponsiveUtils.scaledSpacing(context, 20),
            bottom: ResponsiveUtils.scaledSpacing(context, 20),
            child: GestureDetector(
              onTap: () {
                if (category == 'Favorites') {
                  _showFavoritePicker();
                } else if (category == 'Custom') {
                  _showCustomMessageDialog(context);
                }
              },
              child: Container(
                width: ResponsiveUtils.scaledContainerSize(context, 56),
                height: ResponsiveUtils.scaledContainerSize(context, 56),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  category == 'Favorites' ? CupertinoIcons.pencil : CupertinoIcons.add,
                  size: ResponsiveUtils.scaledIconSize(context, 24),
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
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
        return _buildCustomMessagesList();
      case 2:
        return _buildMessagesList(categorizedMessages['Check-ins'] ?? []);
      case 3:
        return _buildMessagesList(
            categorizedMessages['Support & Struggle'] ?? []);
      case 4:
        return _buildMessagesList(categorizedMessages['Confession'] ?? []);
      case 5:
        return _buildMessagesList(categorizedMessages['Celebration'] ?? []);
      case 6:
        return _buildMessagesList(categorizedMessages['Prayer Requests'] ?? []);
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
              size: ResponsiveUtils.scaledIconSize(context, 40),
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
            Text(
              'No favorite messages yet',
              style: AppTextStyles.scaledCallout(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),
            Text(
              'Tap the + button above to add favorites',
              style: AppTextStyles.scaledCaption(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 12)),
      itemCount: _favoriteMessages.length,
      itemBuilder: (context, index) {
        final message = _favoriteMessages[index];
        return _buildMessageCard(message, isFavorite: true);
      },
    );
  }

  Widget _buildMessagesList(List<String> messages) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 12)), // Reduced from 16
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
              size: ResponsiveUtils.scaledIconSize(context, 40),
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
            Text(
              'No custom messages yet',
              style: AppTextStyles.scaledCallout(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),
            Text(
              'Tap the + button above to create one',
              style: AppTextStyles.scaledCaption(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 12)),
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
        margin: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 6)), // Reduced from 8
        padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 12)), // Reduced from 16
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14), // Reduced from 16
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isFavorite) ...[
              Icon(
                CupertinoIcons.star_fill,
                color: AppColors.warning,
                size: ResponsiveUtils.scaledIconSize(context, 16), // Reduced from 18
              ),
              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)), // Reduced from 12
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
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)), // Reduced from 12
            if (isCustom) ...[
              GestureDetector(
                onTap: () =>
                    _showCustomMessageOptions(context, message, customIndex!),
                child: Container(
                  padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 6)), // Reduced from 8
                  child: Icon(
                    CupertinoIcons.ellipsis_vertical,
                    color: AppColors.textSecondary.withOpacity(0.6),
                    size: ResponsiveUtils.scaledIconSize(context, 16), // Reduced from 18
                  ),
                ),
              ),
            ] else ...[
              Icon(
                CupertinoIcons.arrow_right_circle_fill,
                color: AppColors.primary,
                size: ResponsiveUtils.scaledIconSize(context, 20), // Reduced from 22
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 40); // Reduced from 48

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: widget.friend.isEmoji
            ? AppColors.primary.withOpacity(0.1)
            : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: widget.friend.isEmoji
          ? Center(
        child: Text(
          widget.friend.profileImage,
          style: TextStyle(fontSize: ResponsiveUtils.scaledFontSize(context, 20)), // Reduced from 24
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

  // Continue with existing methods but update any dialog text styles...
  void _showMessageOptions(BuildContext context, String message,
      {bool isCustom = false, int? customIndex}) {
    final isFavorite = _favoriteMessages.contains(message);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Container(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.scaledSpacing(context, 8),
          ),
          child: Text(
            message,
            style: AppTextStyles.scaledCallout(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.scaledFontSize(context, 16),
            ),
            textAlign: TextAlign.center,
          ),
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
                  color: AppColors.primary,
                  size: ResponsiveUtils.scaledIconSize(context, 18),
                ),
                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
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
                  color: AppColors.primary,
                  size: ResponsiveUtils.scaledIconSize(context, 18),
                ),
                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.star,
                    color: AppColors.tertiary,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Text(
                    'Add to Favorites',
                    style: AppTextStyles.scaledCallout(context),
                  ),
                ],
              ),
            ),
          if (isFavorite)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _favoriteMessages.remove(message);
                });
                _updateFavorites(_favoriteMessages);
                ToastService.showSuccess(context, 'Removed from favorites');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.star_slash,
                    color: AppColors.secondary,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Text(
                    'Remove from Favorites',
                    style: AppTextStyles.scaledCallout(context),
                  ),
                ],
              ),
            ),
          if (isCustom && customIndex != null) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _editCustomMessage(context, message, customIndex);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.pencil,
                    color: AppColors.primary,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Text(
                    'Edit Message',
                    style: AppTextStyles.scaledCallout(context),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _deleteCustomMessage(context, message, customIndex);
              },
              isDestructiveAction: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.trash,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Text(
                    'Delete Message',
                    style: AppTextStyles.scaledCallout(context),
                  ),
                ],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.star,
                    color: AppColors.tertiary,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Text(
                    'Add to Favorites',
                    style: AppTextStyles.scaledCallout(context),
                  ),
                ],
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editCustomMessage(context, message, index);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  color: AppColors.primary,
                  size: ResponsiveUtils.scaledIconSize(context, 18),
                ),
                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                Text(
                  'Edit Message',
                  style: AppTextStyles.scaledCallout(context),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomMessage(context, message, index);
            },
            isDestructiveAction: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.trash,
                  size: ResponsiveUtils.scaledIconSize(context, 18),
                ),
                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                Text(
                  'Delete Message',
                  style: AppTextStyles.scaledCallout(context),
                ),
              ],
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
          'New Message',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoTextField(
                controller: textController,
                placeholder: 'Type your message...',
                padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 12)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                style: AppTextStyles.scaledCallout(context),
                placeholderStyle: AppTextStyles.scaledCallout(context).copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),
              Text(
                'This will be saved to your custom messages',
                style: AppTextStyles.scaledCaption(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
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

                // Save to custom messages
                final storageService =
                    Provider.of<FriendsProvider>(context, listen: false)
                        .storageService;
                await storageService.addCustomMessage(textController.text);
                _loadMessages();

                // Send the message
                _sendMessage(context, textController.text);
              }
            },
            isDefaultAction: true,
            child: Text(
              'Send',
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
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Type your message...',
            padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white,
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
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
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

  void _sendMessage(BuildContext context, String message) async {
    final phoneNumber =
    widget.friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            width: ResponsiveUtils.scaledContainerSize(context, 100), // Reduced from 120
            height: ResponsiveUtils.scaledContainerSize(context, 100),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 12, // Reduced from 14
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)), // Reduced from 16
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
              padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
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
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
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
              padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scaledSpacing(context, 16)),
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
                    margin: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 6)), // Reduced from 8
                    padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 12)), // Reduced from 16
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        width: isSelected ? 2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ResponsiveUtils.scaledContainerSize(context, 20), // Reduced from 24
                          height: ResponsiveUtils.scaledContainerSize(context, 20),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: ResponsiveUtils.scaledIconSize(context, 12), // Reduced from 14
                          )
                              : null,
                        ),
                        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 10)), // Reduced from 12
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