// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/friend_card.dart';
import '../utils/constants.dart';
import '../utils/text_styles.dart';
import 'add_friend_screen.dart';
import '../models/friend.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _expandedFriendId;

  @override
  Widget build(BuildContext context) {
    // Use Scaffold but with iOS styling
    return Scaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: Text(
          'Alongside',
          style: AppTextStyles.navTitle,
        ),
        centerTitle: true,
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        // Info button on the left with iOS style
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.info,
            color: Color(AppConstants.primaryColorValue),
            size: 22,
          ),
          onPressed: () => _showAboutDialog(context),
          splashRadius: 24,
        ),
        // Add button on the right with iOS style
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.add,
              color: Color(AppConstants.primaryColorValue),
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AddFriendScreen(),
                ),
              );
            },
            splashRadius: 24,
          ),
        ],
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoading) {
            return const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            );
          }

          final friends = friendsProvider.friends;

          if (friends.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subtle animation for icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      curve: Curves.easeInOut,
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.person_2_fill,
                              size: 54,
                              color: Color(AppConstants.primaryColorValue),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Walk alongside a friend',
                      style: AppTextStyles.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add someone to walk with—through setbacks, growth, and everything in between.',
                      style: AppTextStyles.secondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildAddFriendButton(context),
                  ],
                ),
              ),
            );
          }

          // Auto-expand the first friend card if none is expanded
          if (_expandedFriendId == null && friends.isNotEmpty) {
            _expandedFriendId = friends[0].id;
          }

          return _buildFriendsList(context, friends);
        },
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context, List<Friend> friends) {
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 24,
        ),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return FriendCard(
            friend: friends[index],
            index: index,
            isExpanded: friends[index].id == _expandedFriendId,
            onExpand: _handleCardExpanded,
          );
        },
      ),
    );
  }

  // iOS-style button widget
  Widget _buildAddFriendButton(BuildContext context) {
    // CupertinoButton.filled inside a MaterialApp
    return CupertinoButton.filled(
      onPressed: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const AddFriendScreen(),
          ),
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.add, size: 16),
          const SizedBox(width: 8),
          Text(
            'Add Friend',
            style: AppTextStyles.button,
          ),
        ],
      ),
    );
  }

  void _handleCardExpanded(String friendId) {
    setState(() {
      _expandedFriendId = _expandedFriendId == friendId ? null : friendId;
    });
  }

  void _showAboutDialog(BuildContext context) {
    // Calculate a wider width for the dialog content
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth * 0.8; // 80% of screen width

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'About Alongside',
          style: AppTextStyles.dialogTitle,
        ),
        content: SizedBox(
          width: contentWidth, // Set explicit width for content
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Column(
              children: [
                Text(
                  'Alongside helps you walk with your friends through the highs and lows of life.',
                  style: AppTextStyles.dialogContent,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                  style: AppTextStyles.dialogContent,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity, // Full width within container
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.lock,
                        size: 18,
                        color: Color(0xFF007AFF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Everything stays on your device. It\'s private, secure, and fully in your control.',
                          style: AppTextStyles.dialogContent.copyWith(
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.41,
              ),
            ),
          ),
        ],
      ),
    );
  }}