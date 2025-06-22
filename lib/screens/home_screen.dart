// lib/screens/home_screen.dart - Enhanced version with search, better visual hierarchy, and animations
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/friend_card.dart';
import '../utils/colors.dart';
import '../widgets/illustrations.dart';
import 'add_friend_screen.dart';
import 'settings_screen.dart';
import 'message_screen.dart';
import '../models/friend.dart';
import 'onboarding_screen.dart';
import '../services/storage_service.dart';
import '../services/battery_optimization_service.dart';

class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({Key? key}) : super(key: key);

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String? _expandedFriendId;
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _animation;
  late Animation<double> _searchAnimation;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  String _searchQuery = '';

  // Track if this is the first launch for onboarding
  bool _shouldShowOnboarding = false;

  // Track stats
  int _messagesSent = 0;
  int _callsMade = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
    _checkFirstLaunch();
    _loadStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _searchAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStats(); // Refresh stats when app resumes
    }
  }

  Future<void> _loadStats() async {
    final storageService = StorageService();
    final messages = await storageService.getMessagesSentCount();
    final calls = await storageService.getCallsMadeCount();
    if (mounted) {
      setState(() {
        _messagesSent = messages;
        _callsMade = calls;
      });
    }
  }

  Future<void> _checkFirstLaunch() async {
    // Check if user has any friends - if not, show onboarding
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    await Future.delayed(
        const Duration(milliseconds: 500)); // Wait for provider to load
    if (provider.friends.isEmpty && mounted) {
      setState(() {
        _shouldShowOnboarding = true;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _searchController.clear();
        _searchQuery = '';
      }
    });

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Set first friend as expanded on first load
    if (_expandedFriendId == null) {
      final provider = Provider.of<FriendsProvider>(context, listen: false);
      if (!provider.isLoading && provider.friends.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _expandedFriendId == null) {
            setState(() {
              _expandedFriendId = provider.friends.first.id;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show onboarding if needed
    if (_shouldShowOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() {
            _shouldShowOnboarding = false;
          });
        },
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: AnimatedBuilder(
          animation: _searchAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Title (fades out when searching)
                IgnorePointer(
                  // Add this to prevent touches on the title
                  child: Opacity(
                    opacity: 1 - _searchAnimation.value,
                    child: AnimatedBuilder(
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
                                semanticsLabel: 'Alongside App',
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
                                        semanticLabel: 'Heart icon',
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
                  ),
                ),

                // Search field (fades in when searching)
                if (_isSearching) // Only show when actively searching
                  Opacity(
                    opacity: _searchAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _searchAnimation.value)),
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width *
                                0.6), // Constrain width
                        child: CupertinoTextField(
                          controller: _searchController,
                          placeholder: 'Search friends...',
                          autofocus: true, // ADD THIS LINE
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              CupertinoIcons.search,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: '.SF Pro Text',
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                  ),
              ],
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
            child: Icon(
              _isSearching ? CupertinoIcons.xmark : CupertinoIcons.search,
              size: 16,
              color: AppColors.primary,
              semanticLabel: _isSearching ? 'Close search' : 'Search friends',
            ),
          ),
          onPressed: _toggleSearch,
        ),
        trailing: CupertinoButton(
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
              semanticLabel: 'Settings',
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
                    semanticsLabel: 'Loading your friends',
                  ),
                ],
              ),
            );
          }

          final allFriends = friendsProvider.friends;

          // Filter friends based on search query
          final friends = _searchQuery.isEmpty
              ? allFriends
              : allFriends.where((friend) {
                  return friend.name.toLowerCase().contains(_searchQuery) ||
                      (friend.helpingWith
                              ?.toLowerCase()
                              .contains(_searchQuery) ??
                          false) ||
                      (friend.theyHelpingWith
                              ?.toLowerCase()
                              .contains(_searchQuery) ??
                          false);
                }).toList();

          if (allFriends.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildFriendsListWithIntegratedGreeting(
              context, friends, allFriends);
        },
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToAddFriend(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const AddFriendScreen(),
      ),
    );
  }

  Widget _buildFriendsListWithIntegratedGreeting(BuildContext context,
      List<Friend> filteredFriends, List<Friend> allFriends) {
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

    final favoriteFriends =
        allFriends.where((friend) => friend.isFavorite).toList();

    // Show message if searching but no results
    if (_searchQuery.isNotEmpty && filteredFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No friends found for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontFamily: '.SF Pro Text',
              ),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Text(
                'Clear search',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(
                  child: SizedBox(height: 12)), // Reduced from 20

              // Only show greeting card when not searching
              if (!_isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.subtleShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting and stats row - with constrained text scaling
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left side - Greeting with better wrapping
                              Expanded(
                                flex: 3,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width:
                                          ResponsiveUtils.scaledContainerSize(
                                              context, 40),
                                      height:
                                          ResponsiveUtils.scaledContainerSize(
                                              context, 40),
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
                                            color:
                                                greetingColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        iconData,
                                        color: CupertinoColors.white,
                                        size: ResponsiveUtils.scaledIconSize(
                                            context, 20),
                                        semanticLabel: greeting,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          MediaQuery(
                                            data:
                                                MediaQuery.of(context).copyWith(
                                              textScaleFactor: ResponsiveUtils
                                                  .scaledFontSize(context, 1.1,
                                                      maxScale: 1),
                                            ),
                                            child: Text(
                                              greeting,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: CupertinoColors.label,
                                                fontFamily: '.SF Pro Text',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          MediaQuery(
                                            data:
                                                MediaQuery.of(context).copyWith(
                                              textScaleFactor: ResponsiveUtils
                                                  .scaledFontSize(context, 1,
                                                      maxScale: 1.3),
                                            ),
                                            child: Text(
                                              allFriends.isEmpty
                                                  ? "Ready to walk alongside"
                                                  : allFriends.length == 1
                                                      ? "Walking alongside 1 friend"
                                                      : "Walking alongside ${allFriends.length} friends",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                                fontFamily: '.SF Pro Text',
                                                height: 1.2,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right side - Compact stats with fixed icon sizes
                              Row(
                                children: [
                                  _buildCompactStat(
                                    icon: CupertinoIcons.person_2_fill,
                                    value: allFriends.length.toString(),
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCompactStat(
                                    icon: CupertinoIcons
                                        .bubble_left_bubble_right_fill,
                                    value: _messagesSent.toString(),
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCompactStat(
                                    icon: CupertinoIcons.phone_fill,
                                    value: _callsMade.toString(),
                                    color: AppColors.tertiary,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Favorites section - more compact
// Replace the favorites section container (around line 300)
// Favorites section with proper card-bounded scrolling
                          if (favoriteFriends.isNotEmpty || true) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Favorites',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  12), // Match card radius
                              child: SizedBox(
                                height: 80,
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: const [
                                        Colors.transparent,
                                        Colors.white,
                                        Colors.white,
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.05, 0.95, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: favoriteFriends.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index < favoriteFriends.length) {
                                        final friend = favoriteFriends[index];
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            right: 8,
                                            left: index == 0 ? 4 : 0,
                                          ),
                                          child: _buildCompactFavoriteStory(
                                              friend),
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              right: 4, left: 0),
                                          child:
                                              _buildCompactAddFavoriteButton(),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Friends list
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Search results header
                      if (_searchQuery.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.search,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${filteredFriends.length} result${filteredFriends.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Friends cards
                      ...filteredFriends.asMap().entries.map((entry) {
                        final index = entry.key;
                        final friend = entry.value;

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(friend.id),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
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
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: GestureDetector(
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                _showFriendActions(context, friend, allFriends);
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
                    ],
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
                  semanticLabel: 'Add new friend',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

// Add these new compact widget methods to home_screen.dart
  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final iconSize = ResponsiveUtils.scaledIconSize(context, 16);
    final fontSize = ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3);
    final padding = ResponsiveUtils.scaledPadding(
      context,
      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: iconSize,
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFavoriteStory(Friend friend) {
    final firstName = friend.name.split(' ').first;
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 56);
    final iconSize = ResponsiveUtils.scaledIconSize(context, 24);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showFavoriteOptions(context, friend);
      },
      child: SizedBox(
        width: containerSize + 8, // Add some buffer
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
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
                child: ClipOval(
                  child: friend.isEmoji
                      ? Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                friend.profileImage,
                                style: TextStyle(fontSize: iconSize),
                                semanticsLabel: 'Profile emoji',
                              ),
                            ),
                          ),
                        )
                      : Image.file(
                          File(friend.profileImage),
                          fit: BoxFit.cover,
                          semanticLabel: 'Profile picture',
                        ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 6)),
            Flexible(
              child: Text(
                firstName,
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 12,
                      maxScale: 1.2),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                semanticsLabel: 'Friend name: ${friend.name}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAddFavoriteButton() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 56);
    final iconSize = ResponsiveUtils.scaledIconSize(context, 24);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final provider = Provider.of<FriendsProvider>(context, listen: false);
        _showAddFavoriteDialog(context, provider.friends);
      },
      child: SizedBox(
        width: containerSize + 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                color: CupertinoColors.systemGrey6,
              ),
              child: Icon(
                CupertinoIcons.add,
                color: AppColors.primary,
                size: iconSize,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 6)),
            Flexible(
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 12,
                      maxScale: 1.2),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteStory(Friend friend) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showFavoriteOptions(
            context, friend); // Changed to show menu instead of direct message
      },
      child: Column(
        children: [
          Container(
            width: 64, // Increased from 50
            height: 64, // Increased from 50
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2.5, // Slightly thicker border
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
                        style:
                            const TextStyle(fontSize: 28), // Increased from 20
                        semanticsLabel: 'Profile emoji',
                      ),
                    )
                  : ClipOval(
                      child: Image.file(
                        File(friend.profileImage),
                        fit: BoxFit.cover,
                        semanticLabel: 'Profile picture',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8), // Increased spacing
          SizedBox(
            width: 72, // Increased width for name
            child: Text(
              friend.name,
              style: const TextStyle(
                fontSize: 13, // Increased from 11
                fontWeight: FontWeight.w600, // Increased font weight
                color: AppColors.textPrimary,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: 'Friend name: ${friend.name}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFavoriteButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final provider = Provider.of<FriendsProvider>(context, listen: false);
        _showAddFavoriteDialog(context, provider.friends);
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2.5,
                style: BorderStyle.solid,
              ),
              color: CupertinoColors.systemGrey6,
            ),
            child: const Icon(
              CupertinoIcons.add,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 72,
            child: Text(
              'Add',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
    final nonFavoriteFriends =
        allFriends.where((friend) => !friend.isFavorite).toList();

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
    HapticFeedback.lightImpact();
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final updatedFriend = friend.copyWith(isFavorite: true);
    provider.updateFriend(updatedFriend);
    _showSuccessToast(context, '${friend.name} added to favorites');
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
              HapticFeedback.lightImpact();
              final provider =
                  Provider.of<FriendsProvider>(context, listen: false);
              final updatedFriend = friend.copyWith(isFavorite: false);
              provider.updateFriend(updatedFriend);
              _showSuccessToast(
                  context, '${friend.name} removed from favorites');
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

  void _showSuccessToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.primaryShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
    HapticFeedback.lightImpact();
  }

  void _showFriendActions(
      BuildContext context, Friend friend, List<Friend> friends) {
    friends.indexOf(friend);

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
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => AddFriendScreen(friend: friend),
                ),
              );
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          if (!friend.isFavorite)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _addFavorite(context, friend);
              },
              child: const Text(
                'Add to Favorites',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          if (friends.length > 1)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showReorderOptions(context, friend, friends);
              },
              child: const Text(
                'Reorder',
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

  void _showReorderOptions(
      BuildContext context, Friend friend, List<Friend> friends) {
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
                _reorderFriends(
                    context, currentIndex, currentIndex - 1, friends);
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
                _reorderFriends(
                    context, currentIndex, currentIndex + 1, friends);
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
                _reorderFriends(
                    context, currentIndex, friends.length - 1, friends);
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

  void _reorderFriends(
      BuildContext context, int oldIndex, int newIndex, List<Friend> friends) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final reorderedFriends = List<Friend>.from(friends);

    // Remove the friend from old position
    final Friend friend = reorderedFriends.removeAt(oldIndex);

    // Insert at new position
    reorderedFriends.insert(newIndex, friend);

    provider.reorderFriends(reorderedFriends);
    HapticFeedback.lightImpact();
  }
}
