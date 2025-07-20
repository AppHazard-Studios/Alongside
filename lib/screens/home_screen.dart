// lib/screens/home_screen.dart - INTEGRATED FLOWING DESIGN
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../services/notification_service.dart';
import '../services/toast_service.dart';
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

  bool _shouldShowOnboarding = false;
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
      _loadStats();
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
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    await Future.delayed(const Duration(milliseconds: 500));
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
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFF8FAFC),
      child: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoading) {
            return _buildLoadingState();
          }

          final allFriends = friendsProvider.friends;
          final friends = _searchQuery.isEmpty
              ? allFriends
              : allFriends.where((friend) {
            return friend.name.toLowerCase().contains(_searchQuery) ||
                (friend.helpingWith?.toLowerCase().contains(_searchQuery) ?? false) ||
                (friend.theyHelpingWith?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();

          if (allFriends.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildIntegratedLayout(context, friends, allFriends);
        },
      ),
    );
  }

  // NEW: Integrated layout without separate nav bar
  Widget _buildIntegratedLayout(BuildContext context, List<Friend> filteredFriends, List<Friend> allFriends) {
    final favoriteFriends = allFriends.where((friend) => friend.isFavorite).toList();

    return Stack(
      children: [
        // Main content with integrated header
        SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Integrated header that flows with content
              SliverToBoxAdapter(
                child: _buildIntegratedHeader(allFriends),
              ),

              // Subtle favorites if any exist
              if (favoriteFriends.isNotEmpty && !_isSearching)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.scaledSpacing(context, 16),
                      ResponsiveUtils.scaledSpacing(context, 8),
                      ResponsiveUtils.scaledSpacing(context, 16),
                      ResponsiveUtils.scaledSpacing(context, 12),
                    ),
                    child: _buildSubtleFavorites(favoriteFriends),
                  ),
                ),

              // Clean friends list
              if (_searchQuery.isNotEmpty && filteredFriends.isEmpty)
                SliverToBoxAdapter(
                  child: _buildSearchEmpty(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      if (index >= filteredFriends.length) return null;

                      final friend = filteredFriends[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(friend.id),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 200 + (index * 50)),
                        curve: Curves.easeOutQuart,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                            vertical: ResponsiveUtils.scaledSpacing(context, 4),
                          ),
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
                    },
                    childCount: filteredFriends.length,
                  ),
                ),

              SliverToBoxAdapter(
                child: SizedBox(height: ResponsiveUtils.scaledSpacing(context, 100)),
              ),
            ],
          ),
        ),

        // Floating action button
        Positioned(
          right: ResponsiveUtils.scaledSpacing(context, 20),
          bottom: ResponsiveUtils.scaledSpacing(context, 20),
          child: _buildGlassFAB(),
        ),
      ],
    );
  }

  // NEW: Much more subtle integrated header
  Widget _buildIntegratedHeader(List<Friend> allFriends) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening");
    IconData iconData = hour < 12 ? CupertinoIcons.sun_max_fill : (hour < 17 ? CupertinoIcons.sun_min_fill : CupertinoIcons.moon_stars_fill);

    final friendsWithReminders = allFriends.where((f) => f.hasReminder).length;

    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.scaledSpacing(context, 16),
        ResponsiveUtils.scaledSpacing(context, 16),
        ResponsiveUtils.scaledSpacing(context, 16),
        ResponsiveUtils.scaledSpacing(context, 12),
      ),
      child: Column(
        children: [
          // Top row with title and controls
          Row(
            children: [
              // App title with heart
              Row(
                children: [
                  Text(
                    'Alongside',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.scaledFontSize(context, 28, maxScale: 1.4),
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Container(
                    width: ResponsiveUtils.scaledContainerSize(context, 28),
                    height: ResponsiveUtils.scaledContainerSize(context, 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.heart_fill,
                      size: ResponsiveUtils.scaledIconSize(context, 16),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Control buttons
              Row(
                children: [
                  if (!_isSearching) ...[
                    _buildHeaderButton(
                      icon: CupertinoIcons.sort_down,
                      onPressed: _isSorting ? null : _toggleSort,
                      isActive: _isSortedByReminders,
                      showSpinner: _isSorting,
                    ),
                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  ],
                  _buildHeaderButton(
                    icon: _isSearching ? CupertinoIcons.xmark : CupertinoIcons.search,
                    onPressed: _toggleSearch,
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  _buildHeaderButton(
                    icon: CupertinoIcons.gear,
                    onPressed: () => _navigateToSettings(context),
                  ),
                ],
              ),
            ],
          ),

          // Search field if searching
          if (_isSearching) ...[
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search friends...',
                autofocus: true,
                prefix: Padding(
                  padding: EdgeInsets.only(left: ResponsiveUtils.scaledSpacing(context, 12)),
                  child: Icon(
                    CupertinoIcons.search,
                    color: AppColors.primary,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                  fontFamily: '.SF Pro Text',
                  color: AppColors.textPrimary,
                ),
                decoration: null,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.scaledSpacing(context, 12),
                  horizontal: ResponsiveUtils.scaledSpacing(context, 4),
                ),
                placeholderStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                ),
              ),
            ),
          ],

          // Subtle greeting and stats if not searching
          if (!_isSearching) ...[
            SizedBox(height: ResponsiveUtils.scaledSpacing(context, 20)),
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Greeting row
                  Row(
                    children: [
                      Container(
                        width: ResponsiveUtils.scaledContainerSize(context, 36),
                        height: ResponsiveUtils.scaledContainerSize(context, 36),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          iconData,
                          color: AppColors.primary,
                          size: ResponsiveUtils.scaledIconSize(context, 20),
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
                                fontSize: ResponsiveUtils.scaledFontSize(context, 20, maxScale: 1.3),
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                            Text(
                              "Ready to connect?",
                              style: TextStyle(
                                fontSize: ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.2),
                                color: AppColors.textSecondary,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),

                  // Compact stats row
                  Row(
                    children: [
                      _buildCompactStat(
                        icon: CupertinoIcons.bell_fill,
                        value: friendsWithReminders.toString(),
                        label: friendsWithReminders == 1 ? 'Reminder' : 'Reminders',
                      ),
                      SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
                      _buildCompactStat(
                        icon: CupertinoIcons.bubble_left_bubble_right_fill,
                        value: _messagesSent.toString(),
                        label: 'Messages',
                      ),
                      SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
                      _buildCompactStat(
                        icon: CupertinoIcons.phone_fill,
                        value: _callsMade.toString(),
                        label: 'Calls',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Header button
  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isActive = false,
    bool showSpinner = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: ResponsiveUtils.scaledContainerSize(context, 36),
        height: ResponsiveUtils.scaledContainerSize(context, 36),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withOpacity(isActive ? 0.8 : 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isActive ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: showSpinner
            ? CupertinoActivityIndicator(
          radius: 8,
          color: isActive ? Colors.white : AppColors.primary,
        )
            : Icon(
          icon,
          size: ResponsiveUtils.scaledIconSize(context, 18),
          color: isActive ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }

  // NEW: Compact stat widget
  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.scaledSpacing(context, 8),
          horizontal: ResponsiveUtils.scaledSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: ResponsiveUtils.scaledIconSize(context, 14),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.2),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.scaledFontSize(context, 11, maxScale: 1.1),
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
    );
  }

  // NEW: Much more subtle favorites
  Widget _buildSubtleFavorites(List<Friend> favoriteFriends) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                size: ResponsiveUtils.scaledIconSize(context, 14),
                color: AppColors.warning,
              ),
              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
              Text(
                'Favorites',
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.2),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),
          SizedBox(
            height: ResponsiveUtils.scaledContainerSize(context, 44),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: favoriteFriends.length + 1,
              itemBuilder: (context, index) {
                if (index < favoriteFriends.length) {
                  final friend = favoriteFriends[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: ResponsiveUtils.scaledSpacing(context, 10),
                    ),
                    child: _buildSubtleFavoriteItem(friend),
                  );
                } else {
                  return _buildSubtleAddFavorite();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleFavoriteItem(Friend friend) {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 40);
    final iconSize = ResponsiveUtils.scaledIconSize(context, 20);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showFavoriteOptions(context, friend);
      },
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: friend.isEmoji ? Colors.white.withOpacity(0.9) : Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: friend.isEmoji
                ? Center(
              child: Text(
                friend.profileImage,
                style: TextStyle(fontSize: iconSize),
              ),
            )
                : Image.file(
              File(friend.profileImage),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtleAddFavorite() {
    final containerSize = ResponsiveUtils.scaledContainerSize(context, 40);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final provider = Provider.of<FriendsProvider>(context, listen: false);
        _showAddFavoriteDialog(context, provider.friends);
      },
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          CupertinoIcons.add,
          color: AppColors.warning,
          size: ResponsiveUtils.scaledIconSize(context, 18),
        ),
      ),
    );
  }

  Widget _buildSearchEmpty() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 32),
        vertical: ResponsiveUtils.scaledSpacing(context, 40),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 24)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.search,
            size: ResponsiveUtils.scaledIconSize(context, 32),
            color: AppColors.textSecondary,
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
          Text(
            'No friends found for "$_searchQuery"',
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 16),
              color: AppColors.textSecondary,
              fontFamily: '.SF Pro Text',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SafeArea(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 16),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
              Text(
                'Loading your friends...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                  fontFamily: '.SF Pro Text',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassFAB() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: ResponsiveUtils.scaledContainerSize(context, 56),
        height: ResponsiveUtils.scaledContainerSize(context, 56),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _navigateToAddFriend(context),
          child: Icon(
            CupertinoIcons.add,
            size: ResponsiveUtils.scaledIconSize(context, 24),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 32)),
          child: Container(
            padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 32)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: ResponsiveUtils.scaledContainerSize(context, 120),
                  height: ResponsiveUtils.scaledContainerSize(context, 120),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.heart_fill,
                    size: ResponsiveUtils.scaledIconSize(context, 60),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),
                Text(
                  'Walk alongside a friend',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.scaledFontSize(context, 28, maxScale: 1.5),
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
                Text(
                  'Add someone to walk with—through setbacks, growth, and everything in between.',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.scaledFontSize(context, 17, maxScale: 1.4),
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 32)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.scaledSpacing(context, 32),
                      vertical: ResponsiveUtils.scaledSpacing(context, 16),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () => _navigateToAddFriend(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.person_add_solid,
                          color: Colors.white,
                          size: ResponsiveUtils.scaledIconSize(context, 18),
                        ),
                        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                        Text(
                          'Add Your First Friend',
                          style: TextStyle(
                            color: Colors.white,
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
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _navigateToAddFriend(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(context, CupertinoPageRoute(builder: (context) => const AddFriendScreen()));
  }

  void _handleCardExpanded(String friendId) {
    setState(() {
      _expandedFriendId = friendId; // Always keep one expanded
    });
    HapticFeedback.lightImpact();
  }

  // FIXED: Proper sorting implementation
  Future<void> _toggleSort() async {
    setState(() => _isSorting = true);

    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final currentFriends = provider.friends;

    if (_isSortedByReminders) {
      // Reset to custom order
      if (_originalFriendsOrder != null) {
        provider.reorderFriends(_originalFriendsOrder!);
        ToastService.showSuccess(context, 'Sorted by custom order');
      }
      setState(() {
        _isSortedByReminders = false;
        _originalFriendsOrder = null;
      });
    } else {
      // Sort by reminders
      _originalFriendsOrder = List<Friend>.from(currentFriends);

      final sortedFriends = List<Friend>.from(currentFriends);
      sortedFriends.sort((a, b) {
        if (a.hasReminder && !b.hasReminder) return -1;
        if (!a.hasReminder && b.hasReminder) return 1;
        return a.name.compareTo(b.name);
      });

      provider.reorderFriends(sortedFriends);
      ToastService.showSuccess(context, 'Sorted by reminders');

      setState(() {
        _isSortedByReminders = true;
      });
    }

    setState(() => _isSorting = false);
  }

  // Simplified helper methods
  void _showFriendActions(BuildContext context, Friend friend, List<Friend> friends) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(friend.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, CupertinoPageRoute(
                  builder: (context) => MessageScreenNew(friend: friend)));
            },
            child: const Text('Send Message'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, CupertinoPageRoute(
                  builder: (context) => AddFriendScreen(friend: friend)));
            },
            child: const Text('Edit'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showFavoriteOptions(BuildContext context, Friend friend) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(friend.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, CupertinoPageRoute(
                  builder: (context) => MessageScreenNew(friend: friend)));
            },
            child: const Text('Send Message'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _removeFavorite(context, friend);
            },
            isDestructiveAction: true,
            child: const Text('Remove from Favorites'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
          title: const Text('All Set!'),
          content: const Text('All your friends are already favorites!'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add to Favorites'),
        actions: nonFavoriteFriends.map((friend) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addFavorite(context, friend);
            },
            child: Text(friend.name),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _addFavorite(BuildContext context, Friend friend) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final updatedFriend = friend.copyWith(isFavorite: true);
    provider.updateFriend(updatedFriend);
    ToastService.showSuccess(context, '${friend.name} added to favorites');
  }

  void _removeFavorite(BuildContext context, Friend friend) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final updatedFriend = friend.copyWith(isFavorite: false);
    provider.updateFriend(updatedFriend);
    ToastService.showSuccess(context, '${friend.name} removed from favorites');
  }
}