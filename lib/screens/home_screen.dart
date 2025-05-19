// lib/screens/home_screen.dart - Message-style greeting
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../widgets/friend_card.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/character_components.dart';
import '../widgets/illustrations.dart';
import 'add_friend_screen.dart';
import '../models/friend.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({Key? key}) : super(key: key);

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> with SingleTickerProviderStateMixin {
  String? _expandedFriendId;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

// Updated CupertinoNavigationBar & Build method to improve visual hierarchy

  @override
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      // Simple navigation bar with compact buttons
      navigationBar: CupertinoNavigationBar(
        middle: null, // We'll put "Alongside" in content
        backgroundColor: AppColors.background,
        border: null,
        // Return to original compact button style
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.info,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => _showAboutDialog(context),
        ),
        trailing: Consumer<FriendsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading || provider.friends.isEmpty) {
              return const SizedBox.shrink();
            }

            return CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.add,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              onPressed: () => _navigateToAddFriend(context),
            );
          },
        ),
      ),
      child: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(
                    radius: 14,
                  ),
                  const SizedBox(height: 16),
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: CupertinoColors.label,
                      fontFamily: '.SF Pro Text',
                    ),
                    child: Text(
                      'Loading your friends...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final friends = friendsProvider.friends;

          if (friends.isEmpty) {
            return _buildEmptyState(context);
          }

          if (_expandedFriendId == null && friends.isNotEmpty) {
            _expandedFriendId = friends[0].id;
          }

          return _buildFriendsList(context, friends);
        },
      ),
    );
  }

  void _navigateToAddFriend(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AddFriendScreen(),
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context, List<Friend> friends) {
    // Get time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    IconData iconData;

    if (hour < 12) {
      greeting = "Good morning";
      iconData = CupertinoIcons.sun_max_fill;
    } else if (hour < 17) {
      greeting = "Good afternoon";
      iconData = CupertinoIcons.sun_min_fill;
    } else {
      greeting = "Good evening";
      iconData = CupertinoIcons.moon_stars_fill;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small "Alongside" branding above greeting (subtle)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Alongside',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.heart_fill,
                      size: 8,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Modern greeting component exactly as in screenshot
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.7),
                          AppColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Greeting text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.label,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                        Text(
                          "Here's who you're walking alongside",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Friends list with staggered animation
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 500 + (index * 100)),
                    curve: Curves.easeOutQuint,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 50),
                          child: child,
                        ),
                      );
                    },
                    child: FriendCardNew(
                      friend: friends[index],
                      index: index,
                      isExpanded: friends[index].id == _expandedFriendId,
                      onExpand: _handleCardExpanded,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated illustration
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Illustrations.friendsIllustration(size: 180),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
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
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: CupertinoColors.label,
                  fontFamily: '.SF Pro Text',
                ),
                child: Text(
                  'Walk alongside a friend',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: CupertinoColors.label,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
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
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontFamily: '.SF Pro Text',
                ),
                child: Text(
                  'Add someone to walk with—through setbacks, growth, and everything in between.',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Single prominent button
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: SizedBox(
                width: 240,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () => _navigateToAddFriend(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_add_solid,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Your First Friend',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardExpanded(String friendId) {
    setState(() {
      _expandedFriendId = _expandedFriendId == friendId ? null : friendId;
    });
  }

// Complete _showAboutDialog method with wider dialog

// Fixed _showAboutDialog method - using showCupertinoDialog instead

  void _showAboutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    showCupertinoDialog(  // Changed from showDialog to showCupertinoDialog
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: screenWidth * 0.92, // Much wider dialog (92% of screen width)
            child: CupertinoAlertDialog(
              title: Text(
                'About Alongside',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              content: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: CupertinoColors.label,
                    fontFamily: '.SF Pro Text',
                  ),
                  child: Column(
                    children: [
                      // Little illustration
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Illustrations.friendsIllustration(size: 80),
                        ),
                      ),
                      Text(
                        'Alongside helps you walk with your friends through the highs and lows of life.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: CupertinoColors.label,
                          fontFamily: '.SF Pro Text',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: CupertinoColors.label,
                          fontFamily: '.SF Pro Text',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: double.infinity,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.lock_fill,
                                size: 16,
                                color: AppColors.tertiary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Everything stays on your device. It\'s private, secure, and fully in your control.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: CupertinoColors.label,
                                  fontFamily: '.SF Pro Text',
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
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}