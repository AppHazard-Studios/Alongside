// lib/screens/home_screen.dart - Fixed scrolling, Material issues, and button consistency
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../widgets/friend_card.dart';
import '../utils/colors.dart';
import '../widgets/illustrations.dart';
import 'add_friend_screen.dart';
import 'settings_screen.dart';
import 'message_screen.dart';
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
      // Fixed navigation bar with proper centering
      navigationBar: CupertinoNavigationBar(
        // Center the text first, then add heart beside it
        middle: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min, // This centers the row content
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Center the "Alongside" text
                  const Text(
                    'Alongside',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary, // Consistent primary color
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Heart icon placed beside the centered text
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
        // Settings button
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
              CupertinoIcons.gear,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          onPressed: () => _navigateToSettings(context),
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
                  Text(
                    'Loading your friends...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontFamily: '.SF Pro Text',
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

          return _buildFriendsListWithCleanUI(context, friends);
        },
      ),
    );
  }

  // Navigate to settings page
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SettingsScreen(),
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

  Widget _buildFriendsListWithCleanUI(BuildContext context, List<Friend> friends) {
    // Get time-based greeting with appropriate colors
    final hour = DateTime.now().hour;
    String greeting;
    IconData iconData;
    Color greetingColor;

    if (hour < 12) {
      greeting = "Good morning";
      iconData = CupertinoIcons.sun_max_fill;
      greetingColor = AppColors.morningColor;
    } else if (hour < 17) {
      greeting = "Good afternoon";
      iconData = CupertinoIcons.sun_min_fill;
      greetingColor = AppColors.afternoonColor;
    } else {
      greeting = "Good evening";
      iconData = CupertinoIcons.moon_stars_fill;
      greetingColor = AppColors.eveningColor;
    }

    // Get favorite friends for the stories section
    final favoriteFriends = friends.where((friend) => friend.isFavorite).toList();

    return Stack(
      children: [
        // The main scrollable content
        SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Increased top padding from navbar
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Greeting card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.subtleShadow,
                    ),
                    child: Row(
                      children: [
                        // Icon with time-appropriate gradient background
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                greetingColor.withOpacity(0.7),
                                greetingColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: greetingColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            iconData,
                            color: CupertinoColors.white,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontFamily: '.SF Pro Text',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Favorites/Stories section
              if (favoriteFriends.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'Quick Access',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: favoriteFriends.length,
                            itemBuilder: (context, index) {
                              final friend = favoriteFriends[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: 16,
                                  left: index == 0 ? 4 : 0,
                                ),
                                child: _buildFavoriteStory(friend),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

              // Friends list - FIXED: Using proper approach with standard widgets
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: friends.asMap().entries.map((entry) {
                      final index = entry.key;
                      final friend = entry.value;

                      return TweenAnimationBuilder<double>(
                        key: ValueKey(friend.id),
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
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onLongPress: () {
                              // Show reorder options
                              _showReorderOptions(context, friend, friends);
                            },
                            child: FriendCardNew(
                              friend: friend,
                              index: index,
                              isExpanded: friend.id == _expandedFriendId,
                              onExpand: _handleCardExpanded,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bottom padding to ensure content doesn't get hidden behind button
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),

        // Clean floating action button (iOS standard)
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
                  boxShadow: AppColors.primaryShadow,
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  size: 28,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build favorite story widget with remove option
  Widget _buildFavoriteStory(Friend friend, {VoidCallback? onRemove}) {
    return GestureDetector(
      onTap: () {
        // Navigate directly to message screen
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => MessageScreenNew(friend: friend),
          ),
        );
      },
      onLongPress: onRemove, // Long press to remove from favorites
      child: Column(
        children: [
          // Profile picture with favorite indicator
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2.5,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: friend.isEmoji
                        ? CupertinoColors.systemGrey6
                        : CupertinoColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: friend.isEmoji
                      ? Center(
                    child: Text(
                      friend.profileImage,
                      style: const TextStyle(fontSize: 24),
                    ),
                  )
                      : ClipOval(
                    child: Image.file(
                      File(friend.profileImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Remove indicator (appears on long press)
              if (onRemove != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CupertinoColors.white,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.minus,
                      color: CupertinoColors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Friend name
          SizedBox(
            width: 70,
            child: Text(
              friend.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Build add favorite button
  Widget _buildAddFavoriteButton(BuildContext context, List<Friend> allFriends) {
    return GestureDetector(
      onTap: () => _showAddFavoriteDialog(context, allFriends),
      child: Column(
        children: [
          // + button circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
                width: 2,
                style: BorderStyle.solid,
              ),
              color: AppColors.primaryLight,
            ),
            child: const Icon(
              CupertinoIcons.add,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          // Label
          const SizedBox(
            width: 70,
            child: Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Show dialog to add friend to favorites
  void _showAddFavoriteDialog(BuildContext context, List<Friend> allFriends) {
    final nonFavoriteFriends = allFriends.where((friend) => !friend.isFavorite).toList();

    if (nonFavoriteFriends.isEmpty) {
      // Show message that all friends are already favorites
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text(
            'All Set!',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'All your friends are already in Quick Access!',
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
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Add to Quick Access',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: nonFavoriteFriends.map((friend) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addFavorite(context, friend);
            },
            child: Row(
              children: [
                // Friend profile picture
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: friend.isEmoji
                        ? CupertinoColors.systemGrey6
                        : CupertinoColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                  child: friend.isEmoji
                      ? Center(
                    child: Text(
                      friend.profileImage,
                      style: const TextStyle(fontSize: 16),
                    ),
                  )
                      : ClipOval(
                    child: Image.file(
                      File(friend.profileImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
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

  // NEW: Add friend to favorites
  void _addFavorite(BuildContext context, Friend friend) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final updatedFriend = friend.copyWith(isFavorite: true);
    provider.updateFriend(updatedFriend);
  }

  // NEW: Remove friend from favorites
  void _removeFavorite(BuildContext context, Friend friend) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Remove from Quick Access',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Remove ${friend.name} from Quick Access?',
            style: const TextStyle(
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
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              final provider = Provider.of<FriendsProvider>(context, listen: false);
              final updatedFriend = friend.copyWith(isFavorite: false);
              provider.updateFriend(updatedFriend);
            },
            child: const Text(
              'Remove',
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

  // Reorder friends functionality
  void _reorderFriends(BuildContext context, int oldIndex, int newIndex, List<Friend> friends) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final reorderedFriends = List<Friend>.from(friends);
    final Friend friend = reorderedFriends.removeAt(oldIndex);
    reorderedFriends.insert(newIndex, friend);

    provider.reorderFriends(reorderedFriends);
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
              child: const Text(
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
              child: const Text(
                'Add someone to walk with—through setbacks, growth, and everything in between.',
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 40),

            // Clean floating style button for consistency
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
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => _navigateToAddFriend(context),
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

  // Show reorder options when long pressing a friend card
  void _showReorderOptions(BuildContext context, Friend friend, List<Friend> friends) {
    final currentIndex = friends.indexOf(friend);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Reorder ${friend.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          if (currentIndex > 0)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _reorderFriends(context, currentIndex, 0, friends);
              },
              child: const Text(
                'Move to Top',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          if (currentIndex > 0)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _reorderFriends(context, currentIndex, currentIndex - 1, friends);
              },
              child: const Text(
                'Move Up',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          if (currentIndex < friends.length - 1)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _reorderFriends(context, currentIndex, currentIndex + 1, friends);
              },
              child: const Text(
                'Move Down',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          if (currentIndex < friends.length - 1)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _reorderFriends(context, currentIndex, friends.length - 1, friends);
              },
              child: const Text(
                'Move to Bottom',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
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
}