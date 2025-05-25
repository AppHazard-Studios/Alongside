// lib/screens/home_screen.dart - Integrated favorites into greeting card, improved typography
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
  String? _expandedFriendId; // No card expanded by default
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
      navigationBar: CupertinoNavigationBar(
        middle: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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

          return _buildFriendsListWithIntegratedGreeting(context, friends);
        },
      ),
    );
  }

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

  Widget _buildFriendsListWithIntegratedGreeting(BuildContext context, List<Friend> friends) {
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

    // Get favorite friends
    final favoriteFriends = friends.where((friend) => friend.isFavorite).toList();

    return Stack(
      children: [
        SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Integrated greeting card with favorites
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.subtleShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting section with improved typography
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
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
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: const TextStyle(
                                      fontSize: 20, // Reduced from 24 for better hierarchy
                                      fontWeight: FontWeight.w700,
                                      color: CupertinoColors.label,
                                      fontFamily: '.SF Pro Text',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Here's who you're walking alongside",
                                    style: const TextStyle(
                                      fontSize: 14, // Reduced from 16 for better hierarchy
                                      color: AppColors.textSecondary,
                                      fontFamily: '.SF Pro Text',
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Favorites section integrated into the card
                        if (friends.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Text(
                                'Favorites',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                              const Spacer(),
                              if (favoriteFriends.length < friends.length)
                                GestureDetector(
                                  onTap: () => _showAddFavoriteDialog(context, friends),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                      fontFamily: '.SF Pro Text',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Favorites display
                          if (favoriteFriends.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.add,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Add friends here for quick access',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontFamily: '.SF Pro Text',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SizedBox(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: favoriteFriends.length,
                                itemBuilder: (context, index) {
                                  final friend = favoriteFriends[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: 16,
                                      left: index == 0 ? 0 : 0,
                                    ),
                                    child: _buildFavoriteStory(friend),
                                  );
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Friends list
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
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onLongPress: () {
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

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),

        // Floating action button
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

  Widget _buildFavoriteStory(Friend friend) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => MessageScreenNew(friend: friend),
          ),
        );
      },
      onLongPress: () {
        _showFavoriteOptions(context, friend);
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
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
                  style: const TextStyle(fontSize: 20),
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
          const SizedBox(height: 6),
          SizedBox(
            width: 60,
            child: Text(
              friend.name,
              style: const TextStyle(
                fontSize: 11,
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

  void _showFavoriteOptions(BuildContext context, Friend friend) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          friend.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => MessageScreenNew(friend: friend),
                ),
              );
            },
            child: const Text(
              'Send Message',
              style: TextStyle(
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/call',
                arguments: {'friend': friend},
              );
            },
            child: const Text(
              'Call',
              style: TextStyle(
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _removeFavorite(context, friend);
            },
            isDestructiveAction: true,
            child: const Text(
              'Remove from Favorites',
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

  void _showAddFavoriteDialog(BuildContext context, List<Friend> allFriends) {
    final nonFavoriteFriends = allFriends.where((friend) => !friend.isFavorite).toList();

    if (nonFavoriteFriends.isEmpty) {
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
              'All your friends are already favorites!',
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
          'Add to Favorites',
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

  void _addFavorite(BuildContext context, Friend friend) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final updatedFriend = friend.copyWith(isFavorite: true);
    provider.updateFriend(updatedFriend);
  }

  void _removeFavorite(BuildContext context, Friend friend) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Remove from Favorites',
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
            'Remove ${friend.name} from favorites?',
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
      // Toggle expansion - allow collapsing by clicking the same card
      _expandedFriendId = _expandedFriendId == friendId ? null : friendId;
    });
  }

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