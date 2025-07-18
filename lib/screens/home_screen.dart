// lib/screens/home_screen.dart - Updated with ToastService
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../services/notification_service.dart';
import '../services/toast_service.dart'; // ADD THIS IMPORT
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
  bool _isSortedByReminders = false;
  bool _isSorting = false;
  List<Friend>? _originalFriendsOrder;

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
                              Text(
                                'Alongside',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.scaledFontSize(
                                      context, 22,
                                      maxScale: 1.3),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: '.SF Pro Text',
                                ),
                                semanticsLabel: 'Alongside App',
                              ),
                              SizedBox(
                                  width:
                                  ResponsiveUtils.scaledSpacing(context, 6)),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.8, end: 1.0),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      width: ResponsiveUtils.scaledContainerSize(
                                          context, 24),
                                      height:
                                      ResponsiveUtils.scaledContainerSize(
                                          context, 24),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.heart_fill,
                                        size: ResponsiveUtils.scaledIconSize(
                                            context, 14),
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
                if (_isSearching)
                  Opacity(
                    opacity: _searchAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _searchAnimation.value)),
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6),
                        child: CupertinoTextField(
                          controller: _searchController,
                          placeholder: 'Search friends...',
                          autofocus: true,
                          prefix: Padding(
                            padding: EdgeInsets.only(
                                left: ResponsiveUtils.scaledSpacing(context, 8)),
                            child: Icon(
                              CupertinoIcons.search,
                              color: AppColors.textSecondary,
                              size:
                              ResponsiveUtils.scaledIconSize(context, 18),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          style: TextStyle(
                            fontSize:
                            ResponsiveUtils.scaledFontSize(context, 16),
                            fontFamily: '.SF Pro Text',
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.scaledSpacing(context, 8),
                            horizontal:
                            ResponsiveUtils.scaledSpacing(context, 8),
                          ),
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
            width: ResponsiveUtils.scaledContainerSize(context, 32),
            height: ResponsiveUtils.scaledContainerSize(context, 32),
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
              size: ResponsiveUtils.scaledIconSize(context, 16),
              color: AppColors.primary,
              semanticLabel: _isSearching ? 'Close search' : 'Search friends',
            ),
          ),
          onPressed: _toggleSearch,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sort toggle button
            if (!_isSearching) ...[
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  width: ResponsiveUtils.scaledContainerSize(context, 32),
                  height: ResponsiveUtils.scaledContainerSize(context, 32),
                  decoration: BoxDecoration(
                    color: _isSortedByReminders
                        ? AppColors.primary
                        : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: _isSorting
                      ? CupertinoActivityIndicator(
                    radius: 8,
                    color: _isSortedByReminders
                        ? CupertinoColors.white
                        : AppColors.primary,
                  )
                      : Icon(
                    CupertinoIcons.sort_down,
                    size: ResponsiveUtils.scaledIconSize(context, 16),
                    color: _isSortedByReminders
                        ? CupertinoColors.white
                        : AppColors.primary,
                    semanticLabel: _isSortedByReminders
                        ? 'Sorted by next reminder - tap for custom order'
                        : 'Custom order - tap to sort by next reminder',
                  ),
                ),
                onPressed: _isSorting ? null : _toggleSort,
              ),
              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
            ],
            // Settings button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                width: ResponsiveUtils.scaledContainerSize(context, 32),
                height: ResponsiveUtils.scaledContainerSize(context, 32),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.gear,
                  size: ResponsiveUtils.scaledIconSize(context, 16),
                  color: AppColors.primary,
                  semanticLabel: 'Settings',
                ),
              ),
              onPressed: () => _navigateToSettings(context),
            ),
          ],
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
                  SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
                  Text(
                    'Loading your friends...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              size: ResponsiveUtils.scaledIconSize(context, 48),
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
            Text(
              'No friends found for "$_searchQuery"',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 18),
                color: AppColors.textSecondary,
                fontFamily: '.SF Pro Text',
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),
            CupertinoButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: Text(
                'Clear search',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: ResponsiveUtils.scaledSpacing(context, 12))),

              // Only show greeting card when not searching
              if (!_isSearching) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.scaledSpacing(context, 16)),
                    child: Container(
                      margin: EdgeInsets.only(
                          bottom: ResponsiveUtils.scaledSpacing(context, 16)),
                      padding: ResponsiveUtils.scaledPadding(
                          context, const EdgeInsets.all(16)),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.subtleShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting and stats row - with better responsive layout
                          ResponsiveUtils.needsCompactLayout(context)
                              ? Column(
                            children: [
                              _buildGreetingSection(
                                  greeting, iconData, greetingColor,
                                  allFriends: allFriends),
                              SizedBox(
                                  height: ResponsiveUtils.scaledSpacing(
                                      context, 16)),
                              _buildStatsRow(allFriends),
                            ],
                          )
                              : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildGreetingSection(
                                    greeting, iconData, greetingColor,
                                    allFriends: allFriends),
                              ),
                              _buildStatsRow(allFriends),
                            ],
                          ),

                          // Favorites section
                          if (favoriteFriends.isNotEmpty || true) ...[
                            SizedBox(
                                height:
                                ResponsiveUtils.scaledSpacing(context, 16)),
                            Text(
                              'Favorites',
                              style: TextStyle(
                                fontSize:
                                ResponsiveUtils.scaledFontSize(context, 16),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                            SizedBox(
                                height:
                                ResponsiveUtils.scaledSpacing(context, 10)),
                            SizedBox(
                              height: ResponsiveUtils.scaledContainerSize(context, 80),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.scaledSpacing(context, 8)),
                                physics: const BouncingScrollPhysics(),
                                itemCount: favoriteFriends.length + 1,
                                itemBuilder: (context, index) {
                                  if (index < favoriteFriends.length) {
                                    final friend = favoriteFriends[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: ResponsiveUtils.scaledSpacing(context, 8),
                                        left: index == 0
                                            ? ResponsiveUtils.scaledSpacing(context, 4)
                                            : 0,
                                      ),
                                      child: _buildCompactFavoriteStory(friend),
                                    );
                                  } else {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          right: ResponsiveUtils.scaledSpacing(context, 4),
                                          left: 0),
                                      child: _buildCompactAddFavoriteButton(),
                                    );
                                  }
                                },
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
                  padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.scaledSpacing(context, 16)),
                  child: Column(
                    children: [
                      // Search results header
                      if (_searchQuery.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: ResponsiveUtils.scaledSpacing(context, 16)),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.search,
                                size: ResponsiveUtils.scaledIconSize(context, 16),
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(
                                  width:
                                  ResponsiveUtils.scaledSpacing(context, 8)),
                              Text(
                                '${filteredFriends.length} result${filteredFriends.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.scaledFontSize(
                                      context, 14),
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
                            padding: EdgeInsets.only(
                                bottom:
                                ResponsiveUtils.scaledSpacing(context, 4)),
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

              SliverToBoxAdapter(
                  child: SizedBox(
                      height: ResponsiveUtils.scaledSpacing(context, 100))),
            ],
          ),
        ),

        // Floating action button
        Positioned(
          right: ResponsiveUtils.scaledSpacing(context, 20),
          bottom: ResponsiveUtils.scaledSpacing(context, 20),
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
                width: ResponsiveUtils.scaledContainerSize(context, 60),
                height: ResponsiveUtils.scaledContainerSize(context, 60),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.primaryShadow,
                ),
                child: Icon(
                  CupertinoIcons.add,
                  size: ResponsiveUtils.scaledIconSize(context, 28),
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

  Widget _buildGreetingSection(
      String greeting, IconData iconData, Color greetingColor,
      {required List<Friend> allFriends}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ResponsiveUtils.scaledContainerSize(context, 40),
          height: ResponsiveUtils.scaledContainerSize(context, 40),
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
            size: ResponsiveUtils.scaledIconSize(context, 20),
            semanticLabel: greeting,
          ),
        ),
        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 20,
                      maxScale: 1.4),
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
              Text(
                allFriends.isEmpty
                    ? "Ready to walk alongside"
                    : allFriends.length == 1
                    ? "Walking alongside 1 friend"
                    : "Walking alongside ${allFriends.length} friends",
                style: TextStyle(
                  fontSize:
                  ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.3),
                  color: AppColors.textSecondary,
                  fontFamily: '.SF Pro Text',
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(List<Friend> allFriends) {
    return Row(
      children: [
        _buildCompactStat(
          icon: CupertinoIcons.person_2_fill,
          value: allFriends.length.toString(),
          color: AppColors.primary,
        ),
        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
        _buildCompactStat(
          icon: CupertinoIcons.bubble_left_bubble_right_fill,
          value: _messagesSent.toString(),
          color: AppColors.secondary,
        ),
        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
        _buildCompactStat(
          icon: CupertinoIcons.phone_fill,
          value: _callsMade.toString(),
          color: AppColors.tertiary,
        ),
      ],
    );
  }

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

  void _showFavoriteOptions(BuildContext context, Friend friend) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          friend.name,
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
            child: Text(
              'Send Message',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
            child: Text(
              'Call',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
            child: Text(
              'Remove from Favorites',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
          title: Text(
            'All Set!',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveUtils.scaledFontSize(context, 18),
              fontFamily: '.SF Pro Text',
            ),
          ),
          content: Padding(
            padding: EdgeInsets.only(
                top: ResponsiveUtils.scaledSpacing(context, 8)),
            child: Text(
              'All your friends are already favorites!',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                height: 1.3,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
        title: Text(
          'Add to Favorites',
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
                  width: ResponsiveUtils.scaledContainerSize(context, 32),
                  height: ResponsiveUtils.scaledContainerSize(context, 32),
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
                      style: TextStyle(
                          fontSize:
                          ResponsiveUtils.scaledIconSize(context, 16)),
                    ),
                  )
                      : ClipOval(
                    child: Image.file(
                      File(friend.profileImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
                Text(
                  friend.name,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
    // REPLACE: _showSuccessToast with ToastService.showSuccess
    ToastService.showSuccess(context, '${friend.name} added to favorites');
  }

  void _removeFavorite(BuildContext context, Friend friend) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Remove from Favorites',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.scaledFontSize(context, 18),
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Padding(
          padding:
          EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
          child: Text(
            'Remove ${friend.name} from favorites?',
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 16),
              height: 1.3,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              // REPLACE: _showSuccessToast with ToastService.showSuccess
              ToastService.showSuccess(context, '${friend.name} removed from favorites');
            },
            child: Text(
              'Remove',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.scaledSpacing(context, 32),
          vertical: ResponsiveUtils.scaledSpacing(context, 16),
        ),
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
                width: ResponsiveUtils.scaledContainerSize(context, 180),
                height: ResponsiveUtils.scaledContainerSize(context, 180),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Illustrations.friendsIllustration(
                    size: ResponsiveUtils.scaledContainerSize(context, 180)),
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 32)),
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
              child: Text(
                'Walk alongside a friend',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 28,
                      maxScale: 1.5),
                  fontWeight: FontWeight.w800,
                  color: CupertinoColors.label,
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
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
              child: Text(
                'Add someone to walk with—through setbacks, growth, and everything in between.',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 17,
                      maxScale: 1.4),
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontFamily: '.SF Pro Text',
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.visible,
              ),
            ),
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 40)),
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
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.scaledSpacing(context, 32),
                  vertical: ResponsiveUtils.scaledSpacing(context, 16),
                ),
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => _navigateToAddFriend(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.person_add_solid,
                      color: CupertinoColors.white,
                      size: ResponsiveUtils.scaledIconSize(context, 18),
                    ),
                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                    Text(
                      'Add Your First Friend',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
            child: Text(
              'Send Message',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
            child: Text(
              'Call',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
            child: Text(
              'Edit',
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              child: Text(
                'Add to Favorites',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              child: Text(
                'Reorder',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.scaledFontSize(context, 16),
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get next reminder time for sorting
  Future<DateTime?> _getNextReminderTimeForFriend(Friend friend) async {
    if (friend.reminderDays <= 0) return null;

    final notificationService = NotificationService();
    return await notificationService.getNextReminderTime(friend.id);
  }

  Future<List<Friend>> _sortFriendsByReminderProximity(List<Friend> friends) async {
    if (friends.isEmpty) return friends;

    print('\n🔄 Sorting ${friends.length} friends by next reminder');

    final notificationService = NotificationService();
    List<MapEntry<Friend, DateTime?>> friendsWithTimes = [];

    // Get reminder times for each friend and ensure they're scheduled
    for (Friend friend in friends) {
      DateTime? nextTime;

      if (friend.reminderDays > 0) {
        // Try to get existing reminder time
        nextTime = await notificationService.getNextReminderTime(friend.id);

        // If no reminder scheduled, schedule one
        if (nextTime == null) {
          await notificationService.scheduleReminder(friend);
          nextTime = await notificationService.getNextReminderTime(friend.id);
        }
      }

      friendsWithTimes.add(MapEntry(friend, nextTime));
    }

    // Sort by reminder proximity
    friendsWithTimes.sort((a, b) {
      // FIXED: Use hasReminder instead of reminderDays > 0
      final aHasReminder = a.key.hasReminder;
      final bHasReminder = b.key.hasReminder;

      // Friends without reminders go to the end
      if (!aHasReminder && !bHasReminder) {
        return a.key.name.compareTo(b.key.name);
      }
      if (!aHasReminder) return 1;
      if (!bHasReminder) return -1;

      // Both have reminders - sort by next reminder time
      if (a.value == null && b.value == null) {
        return a.key.name.compareTo(b.key.name);
      }
      if (a.value == null) return 1;
      if (b.value == null) return -1;

      return a.value!.compareTo(b.value!);
    });

    final sortedFriends = friendsWithTimes.map((entry) => entry.key).toList();
    final friendsWithReminders = sortedFriends.where((f) => f.reminderDays > 0).length;

    print('✅ Sorted complete - $friendsWithReminders friends have reminders');

    return sortedFriends;
  }

  Future<void> _toggleSort() async {
    setState(() => _isSorting = true);

    final provider = Provider.of<FriendsProvider>(context, listen: false);

    if (_isSortedByReminders) {
      print('🔄 RESETTING TO CUSTOM ORDER');
      // Reset to original order
      if (_originalFriendsOrder != null) {
        provider.reorderFriends(_originalFriendsOrder!);
        // REPLACE: _showSuccessToast with ToastService.showSuccess
        ToastService.showSuccess(context, 'Custom order');
      }
      setState(() {
        _isSortedByReminders = false;
        _originalFriendsOrder = null;
      });
    } else {
      print('🔄 SORTING BY NEXT REMINDER');
      // Store original order before sorting
      _originalFriendsOrder = List<Friend>.from(provider.friends);

      // Sort by reminders
      final sortedFriends = await _sortFriendsByReminderProximity(provider.friends);
      provider.reorderFriends(sortedFriends);

      // REPLACE: _showSuccessToast with ToastService.showSuccess
      ToastService.showSuccess(context, 'Sorted by next reminder');

      setState(() {
        _isSortedByReminders = true;
      });
    }

    setState(() => _isSorting = false);
  }

  void _showReorderOptions(
      BuildContext context, Friend friend, List<Friend> friends) {
    final currentIndex = friends.indexOf(friend);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Reorder ${friend.name}',
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              child: Text(
                'Move to Top',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              child: Text(
                'Move Up',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              child: Text(
                'Move Down',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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
              child: Text(
                'Move to Bottom',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.scaledFontSize(context, 16),
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

    // If we're in sorted mode, exit it since user manually reordered
    if (_isSortedByReminders) {
      setState(() {
        _isSortedByReminders = false;
        _originalFriendsOrder = null;
      });
      // REPLACE: _showSuccessToast with ToastService.showSuccess
      ToastService.showSuccess(context, 'Switched to custom order');
    }
  }
}