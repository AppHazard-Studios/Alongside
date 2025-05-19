// lib/screens/home_screen.dart - Updated with floating action button and card-styled greeting
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../widgets/friend_card.dart';
import '../utils/colors.dart';
// ignore: unused_import
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
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      // Simple navigation bar with compact buttons
      navigationBar: CupertinoNavigationBar(
        middle: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Alongside',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(width: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.heart_fill,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: AppColors.background,
        border: null,
        // Keep only the info button in navbar
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.info,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => _showAboutDialog(context),
        ),
      ),
      child: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(
                    radius: 14,
                  ),
                  SizedBox(height: 16),
                  DefaultTextStyle(
                    style: TextStyle(
                      color: CupertinoColors.label,
                      fontFamily: '.SF Pro Text',
                    ),
                    child: Text(
                      'Loading your friends...',
                      style: const TextStyle(
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

          return _buildFriendsListWithFAB(context, friends);
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

  Widget _buildFriendsListWithFAB(BuildContext context, List<Friend> friends) {
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

    return Stack(
      children: [
        // The scrollable content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Small "Alongside" branding above greeting (subtle),

                // New card-style greeting component
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
                              const Text(
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
                ),

                // Friends list with staggered animation
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                    childCount: friends.length,
                  ),
                ),

                // Add bottom padding to ensure the FAB doesn't overlap with content
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ),

        // Floating Action Button
        Positioned(
          right: 20,
          bottom: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _navigateToAddFriend(context),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
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
              child: const DefaultTextStyle(
                style: TextStyle(
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
              child: const DefaultTextStyle(
                style: TextStyle(
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_add_solid,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
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

  void _showAboutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: screenWidth * 0.92, // Much wider dialog (92% of screen width)
            child: CupertinoAlertDialog(
              title: const Text(
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
                      const Text(
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
                      const Text(
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
                              child: const Icon(
                                CupertinoIcons.lock_fill,
                                size: 16,
                                color: AppColors.tertiary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
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
                  child: const Text(
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