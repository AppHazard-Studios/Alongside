// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/friend_card.dart';
import '../utils/constants.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // iOS background color
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: const Text(
          'Alongside',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        // Info button on the left with iOS style
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.info,
            color: Color(AppConstants.primaryColorValue),
            size: 24,
          ),
          onPressed: () => _showAboutDialog(context),
        ),
        // Add button on the right with iOS style
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.add,
                color: Color(AppConstants.primaryColorValue),
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const AddFriendScreen(),
                  ),
                );
              },
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoading) {
            return Center(
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
                            child: Icon(
                              CupertinoIcons.person_2_fill,
                              size: 54,
                              color: const Color(AppConstants.primaryColorValue),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Walk alongside a friend',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add someone to walk with—through setbacks, growth, and everything in between.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildIOSButton(
                      context: context,
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const AddFriendScreen(),
                          ),
                        );
                      },
                      text: 'Add Friend',
                      icon: CupertinoIcons.add,
                    ),
                  ],
                ),
              ),
            );
          }

          // Auto-expand the first friend card if none is expanded
          if (_expandedFriendId == null && friends.isNotEmpty) {
            _expandedFriendId = friends[0].id;
          }

          return _buildIOSStyleList(context, friends);
        },
      ),
    );
  }

  Widget _buildIOSStyleList(BuildContext context, List<Friend> friends) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 24,
      ),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        // We're reusing the existing FriendCard widget
        // You would need to update the FriendCard widget separately
        // to have iOS styling
        return FriendCard(
          friend: friends[index],
          index: index,
          isExpanded: friends[index].id == _expandedFriendId,
          onExpand: _handleCardExpanded,
        );
      },
    );
  }

  // iOS-style button widget
  Widget _buildIOSButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    bool isPrimary = true,
  }) {
    final color = isPrimary
        ? const Color(AppConstants.primaryColorValue)
        : Colors.white;
    final textColor = isPrimary
        ? Colors.white
        : const Color(AppConstants.primaryColorValue);
    final borderColor = const Color(AppConstants.primaryColorValue);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color,
        border: !isPrimary ? Border.all(color: borderColor, width: 1.5) : null,
        boxShadow: isPrimary ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleCardExpanded(String friendId) {
    setState(() {
      _expandedFriendId = _expandedFriendId == friendId ? null : friendId;
    });
  }

  void _showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('About Alongside'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            children: [
              Text(
                'Alongside helps you walk with your friends through the highs and lows of life.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.lock,
                      size: 18,
                      color: const Color(AppConstants.primaryColorValue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Everything stays on your device. It\'s private, secure, and fully in your control.',
                        style: TextStyle(
                          fontSize: 13,
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
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}