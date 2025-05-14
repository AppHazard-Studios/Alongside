// lib/screens/home_screen_new.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/friend_card_new.dart';
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: _buildAnimatedLogo(),
        backgroundColor: AppColors.background,
        border: null, // Remove border for modern look
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
              size: 20,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => _showAboutDialog(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.add,
              size: 22,
              color: AppColors.secondary,
            ),
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
                  Text(
                    'Loading your friends...',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 16,
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

          // Auto-expand the first friend card if none is expanded
          if (_expandedFriendId == null && friends.isNotEmpty) {
            _expandedFriendId = friends[0].id;
          }

          return _buildFriendsList(context, friends);
        },
      ),
    );
  }

  // Animated app logo
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Text(
                'Alongside',
                style: AppTextStyles.navTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
              const SizedBox(width: 6),
              // Little bouncing heart icon
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
                        color: AppColors.secondaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.heart_fill,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(BuildContext context, List<Friend> friends) {
    return SafeArea(
      child: Stack(
        children: [
          // Time of day greeting
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 80, // Space for the add button at bottom
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting with animation
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
                  child: CharacterComponents.personalizedGreeting(
                    name: "Friend",
                    style: AppTextStyles.title.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Subheader
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 16),
                          child: Text(
                            "Here's who you're walking alongside",
                            style: AppTextStyles.secondary.copyWith(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Friends list with staggered animation
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      // Staggered animation for each card
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

          // Floating add friend button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: CharacterComponents.playfulButton(
                  label: 'Add Friend',
                  icon: CupertinoIcons.person_add_solid,
                  backgroundColor: AppColors.primary,
                  borderRadius: 20,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: 32, vertical: 16),
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
              child: CharacterComponents.floatingElement(
                yOffset: 8,
                period: const Duration(seconds: 3),
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
            ),
            const SizedBox(height: 32),
            // Title with animated gradient
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuint,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Walk alongside a friend',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // Will be masked by gradient
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Description with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutQuint,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: Text(
                      'Add someone to walk with—through setbacks, growth, and everything in between.',
                      style: AppTextStyles.secondary.copyWith(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Button with animation
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
              child: CharacterComponents.playfulButton(
                label: 'Add Your First Friend',
                icon: CupertinoIcons.person_add_solid,
                backgroundColor: AppColors.primary,
                borderRadius: 20,
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
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'About Alongside',
            style: AppTextStyles.dialogTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Column(
            children: [
              // Little illustration
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CharacterComponents.floatingElement(
                  yOffset: 4,
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
              ),
              Text(
                'Alongside helps you walk with your friends through the highs and lows of life.',
                style: AppTextStyles.dialogContent.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                style: AppTextStyles.dialogContent.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.tertiary.withOpacity(0.5),
                    width: 1.5,
                  ),
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
                        style: AppTextStyles.dialogContent.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textPrimary,
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
            child: Text(
              'Close',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}