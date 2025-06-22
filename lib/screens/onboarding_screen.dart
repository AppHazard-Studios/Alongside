// lib/screens/onboarding_screen.dart - Simple onboarding for new users
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../widgets/illustrations.dart';
import 'add_friend_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _skipOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.mediumImpact();
    widget.onComplete();
  }

  void _addFirstFriend() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AddFriendScreen(),
      ),
    ).then((_) {
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _skipOnboarding,
                    child: Text(
                      _currentPage == 2 ? 'Done' : 'Skip',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    illustration: Illustrations.friendsIllustration(size: 200),
                    title: 'Welcome to Alongside',
                    description:
                        'A simple way to walk alongside your friends through life\'s ups and downs.',
                    color: AppColors.primary,
                  ),
                  _buildPage(
                    illustration:
                        Illustrations.messagingIllustration(size: 200),
                    title: 'Stay Connected',
                    description:
                        'Send thoughtful messages and check in with reminders that help you be present when it matters most.',
                    color: AppColors.secondary,
                  ),
                  _buildPage(
                    illustration: Illustrations.reminderIllustration(size: 200),
                    title: 'Never Forget',
                    description:
                        'Set gentle reminders to reach out, because the best friendships are built one conversation at a time.',
                    color: AppColors.accent,
                    showAddFriendButton: true,
                  ),
                ],
              ),
            ),

            // Page indicators and next button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
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

                  const SizedBox(height: 32),

                  // Next/Get Started button
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          onPressed: _nextPage,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == 2 ? 'Get Started' : 'Next',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                CupertinoIcons.arrow_right,
                                color: CupertinoColors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required Widget illustration,
    required String title,
    required String description,
    required Color color,
    bool showAddFriendButton = false,
  }) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: illustration,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: CupertinoColors.label,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),

                if (showAddFriendButton) ...[
                  const SizedBox(height: 32),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _addFirstFriend,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
