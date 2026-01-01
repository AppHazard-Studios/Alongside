// lib/screens/home_screen.dart - FIXED FOR CORRECT iOS FONT SIZES AND LAYOUT
import 'dart:io';
import 'dart:async';
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
import '../utils/text_styles.dart';
import 'add_friend_screen.dart';
import 'settings_screen.dart';
import 'message_screen.dart';
import '../models/friend.dart';
import 'onboarding_screen.dart';
import '../services/storage_service.dart';

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

  // Foreground timers
  // Precise notification timer
  Timer? _nextNotificationTimer;
  bool _isAppInForeground = true;
  String? _pendingNotificationFriendId; // Track which friend's notification is showing

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

    _animationController.forward();
    _checkFirstLaunch();
    _loadStats();

    // Schedule the first precise notification timer
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scheduleNextNotificationTimer();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _searchAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();

    // Clean up precise timer
    _nextNotificationTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print("📱 App resumed - checking overdue and scheduling");
      _isAppInForeground = true;

      _loadStats();

      // Check for overdue notifications and schedule next timer
      _checkOverdueAndSchedule();

    } else if (state == AppLifecycleState.paused) {
      print("📱 App paused - stopping timers");
      _isAppInForeground = false;

      // Cancel timer when going to background
      _nextNotificationTimer?.cancel();
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

// ============================================================================
  // PRECISE NOTIFICATION TIMER SYSTEM
  // ============================================================================

  Future<void> _scheduleNextNotificationTimer() async {
    _nextNotificationTimer?.cancel();
    _nextNotificationTimer = null;

    try {
      final provider = Provider.of<FriendsProvider>(context, listen: false);
      final notificationService = NotificationService();

      DateTime? earliestTime;
      String? earliestFriendId;

      for (final friend in provider.friends) {
        if (!friend.hasReminder) continue;

        final nextTime = await notificationService.getNextReminderTime(friend.id);
        if (nextTime == null) continue;

        if (earliestTime == null || nextTime.isBefore(earliestTime)) {
          earliestTime = nextTime;
          earliestFriendId = friend.id;
        }
      }

      if (earliestTime == null || earliestFriendId == null) {
        print("⏰ No upcoming notifications to schedule");
        return;
      }

      final now = DateTime.now();
      final delay = earliestTime.difference(now);

      if (delay.isNegative) {
        print("⏰ Notification overdue - showing immediately for $earliestFriendId");
        _handleNotificationDue(earliestFriendId);
      } else {
        print("⏰ Scheduling notification for $earliestFriendId at $earliestTime (in ${delay.inMinutes}m ${delay.inSeconds % 60}s)");

        final friendId = earliestFriendId;
        _nextNotificationTimer = Timer(delay, () {
          if (mounted && _isAppInForeground) {
            _handleNotificationDue(friendId);
          }
        });
      }
    } catch (e) {
      print("❌ Error scheduling notification timer: $e");
    }
  }

  void _handleNotificationDue(String friendId) {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final friend = provider.getFriendById(friendId);

    if (friend == null) {
      print("❌ Friend not found: $friendId");
      _scheduleNextNotificationTimer();
      return;
    }

    print("🔔 Notification due for ${friend.name}");

    // Trigger rebuild to show tick
    setState(() {});

    if (_pendingNotificationFriendId == null) {
      _showNotificationPopup(friend);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scheduleNextNotificationTimer();
      }
    });
  }

  Future<void> _checkOverdueAndSchedule() async {
    try {
      final provider = Provider.of<FriendsProvider>(context, listen: false);
      final notificationService = NotificationService();

      final overdueFriends = await notificationService.checkOverdueNotifications(
        provider.friends,
      );

      if (overdueFriends.isNotEmpty && mounted) {
        setState(() {});

        for (final friend in overdueFriends) {
          await _showNotificationPopupQueued(friend);
        }
      }

      await _scheduleNextNotificationTimer();
    } catch (e) {
      print("❌ Error checking overdue notifications: $e");
    }
  }

  void _showNotificationPopup(Friend friend) {
    if (_pendingNotificationFriendId != null) return;

    _pendingNotificationFriendId = friend.id;

    HapticFeedback.mediumImpact();

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.bell_fill,
              color: AppColors.primary,
              size: ResponsiveUtils.scaledIconSize(context, 20),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
            Text(
              'Check-in Time',
              style: AppTextStyles.scaledHeadline(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveUtils.scaledContainerSize(context, 50),
                height: ResponsiveUtils.scaledContainerSize(context, 50),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: friend.isEmoji
                    ? Center(
                  child: Text(
                    friend.profileImage,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.scaledContainerSize(context, 26),
                    ),
                  ),
                )
                    : ClipOval(
                  child: Image.file(
                    File(friend.profileImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
              Text(
                friend.name,
                style: AppTextStyles.scaledCallout(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              _pendingNotificationFriendId = null;

              final notificationService = NotificationService();
              await notificationService.triggerOverdueNotification(friend);

              // Force multiple rebuilds to ensure FriendCard updates
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) {
                setState(() {});
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) setState(() {});
                });
              }
            },
            child: Text(
              'Already Done',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              _pendingNotificationFriendId = null;

              final notificationService = NotificationService();
              await notificationService.triggerOverdueNotification(friend);

              await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => MessageScreenNew(friend: friend),
                ),
              );

              // Force multiple rebuilds when returning
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) {
                setState(() {});
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) setState(() {});
                });
              }
            },
            isDefaultAction: true,
            child: Text(
              'Message',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      _pendingNotificationFriendId = null;
    });
  }

  Future<void> _showNotificationPopupQueued(Friend friend) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    final completer = Completer<void>();
    _pendingNotificationFriendId = friend.id;

    HapticFeedback.mediumImpact();

    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.bell_fill,
              color: AppColors.primary,
              size: ResponsiveUtils.scaledIconSize(context, 20),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
            Text(
              'Check-in Time',
              style: AppTextStyles.scaledHeadline(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveUtils.scaledContainerSize(context, 50),
                height: ResponsiveUtils.scaledContainerSize(context, 50),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: friend.isEmoji
                    ? Center(
                  child: Text(
                    friend.profileImage,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.scaledContainerSize(context, 26),
                    ),
                  ),
                )
                    : ClipOval(
                  child: Image.file(
                    File(friend.profileImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 10)),
              Text(
                friend.name,
                style: AppTextStyles.scaledCallout(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);

              final notificationService = NotificationService();
              await notificationService.triggerOverdueNotification(friend);

              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) {
                setState(() {});
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) setState(() {});
                });
              }

              completer.complete();
            },
            child: Text(
              'Already Done',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);

              final notificationService = NotificationService();
              await notificationService.triggerOverdueNotification(friend);

              await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => MessageScreenNew(friend: friend),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) {
                setState(() {});
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) setState(() {});
                });
              }

              completer.complete();
            },
            isDefaultAction: true,
            child: Text(
              'Message',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      _pendingNotificationFriendId = null;
    });

    return completer.future;
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      child: SafeArea(
        bottom: true,
        child: Consumer<FriendsProvider>(
          builder: (context, friendsProvider, child) {
            if (friendsProvider.isLoading) {
              return _buildLoadingState();
            }

            final allFriends = friendsProvider.friends;

            if (allFriends.isNotEmpty && _expandedFriendId == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _expandedFriendId = allFriends.first.id;
                  });
                }
              });
            }

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
      ),
    );
  }

  Widget _buildIntegratedLayout(BuildContext context, List<Friend> filteredFriends, List<Friend> allFriends) {
    final favoriteFriends = allFriends.where((friend) => friend.isFavorite).toList();

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _buildIntegratedHeader(allFriends),
            ),

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
                            isSortedByReminders: _isSortedByReminders,
                            onExitSortMode: () {
                              // Restore original custom order before allowing reorder
                              if (_originalFriendsOrder != null) {
                                final provider = Provider.of<FriendsProvider>(context, listen: false);
                                provider.reorderFriends(_originalFriendsOrder!);
                              }

                              setState(() {
                                _isSortedByReminders = false;
                                _originalFriendsOrder = null;
                              });

                              ToastService.showSuccess(context, 'Switched to custom order');
                            },
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

        Positioned(
          right: ResponsiveUtils.scaledSpacing(context, 20),
          bottom: ResponsiveUtils.scaledSpacing(context, 20),
          child: _buildGlassFAB(),
        ),
      ],
    );
  }

  // 🔧 FIXED: Header with greeting text that wraps properly
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
          // Header with consistent title sizing
          Row(
            children: [
              // Title area - takes available space
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Heart icon FIRST
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

                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

                    // Title with overflow protection
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Alongside',
                          style: AppTextStyles.scaledAppTitle(context),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Fixed spacing between title and buttons
              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 16)),

              // Button area - fixed size to prevent overflow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isSearching) ...[
                    _buildHeaderButton(
                      icon: CupertinoIcons.sort_down,
                      onPressed: _isSorting ? null : _toggleSort,
                      isActive: _isSortedByReminders,
                      showSpinner: _isSorting,
                    ),
                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 4)),
                  ],
                  _buildHeaderButton(
                    icon: _isSearching ? CupertinoIcons.xmark : CupertinoIcons.search,
                    onPressed: _toggleSearch,
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 4)),
                  _buildHeaderButton(
                    icon: CupertinoIcons.gear,
                    onPressed: () => _navigateToSettings(context),
                  ),
                ],
              ),
            ],
          ),

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
                style: AppTextStyles.scaledCallout(context),
                decoration: null,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.scaledSpacing(context, 12),
                  horizontal: ResponsiveUtils.scaledSpacing(context, 4),
                ),
                placeholderStyle: AppTextStyles.scaledTextStyle(
                  context,
                  AppTextStyles.placeholder,
                ),
              ),
            ),
          ],

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
                  // 🔧 FIXED: Natural greeting layout - let it flow properly
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: ResponsiveUtils.scaledContainerSize(context, 42),
                        height: ResponsiveUtils.scaledContainerSize(context, 42),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          iconData,
                          color: AppColors.primary,
                          size: ResponsiveUtils.scaledIconSize(context, 22),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),

                      // 🔧 FIXED: Let greeting take available space, naturally wrap when it hits stats
                      Expanded(
                        child: Text(
                          greeting,
                          style: AppTextStyles.scaledTitle3(context).copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2, // Allow wrapping when needed
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),

                      // Stats stay on the same row - they'll naturally push text to wrap
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInlineStatChip(
                            icon: CupertinoIcons.bell_fill,
                            value: friendsWithReminders.toString(),
                            color: AppColors.warning,
                          ),
                          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                          _buildInlineStatChip(
                            icon: CupertinoIcons.bubble_left_bubble_right_fill,
                            value: _messagesSent.toString(),
                            color: AppColors.primary,
                          ),
                          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                          _buildInlineStatChip(
                            icon: CupertinoIcons.phone_fill,
                            value: _callsMade.toString(),
                            color: AppColors.tertiary,
                          ),
                        ],
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

  // Vertical stat chips to prevent wrapping on smaller screens
  Widget _buildInlineStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 10), // Slightly more horizontal padding
        vertical: ResponsiveUtils.scaledSpacing(context, 8), // More vertical padding for balance
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column( // Vertical layout for compact horizontal space
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.scaledIconSize(context, 16), // Slightly bigger icon for vertical layout
          ),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 4)), // Vertical spacing instead of horizontal
          Text(
            value,
            style: AppTextStyles.scaledFootnote(context).copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

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
        width: ResponsiveUtils.scaledContainerSize(context, 32),
        height: ResponsiveUtils.scaledContainerSize(context, 32),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
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
          radius: 6,
          color: isActive ? Colors.white : AppColors.primary,
        )
            : Icon(
          icon,
          size: ResponsiveUtils.scaledIconSize(context, 16),
          color: isActive ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }

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
                style: AppTextStyles.scaledSubhead(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
            style: AppTextStyles.scaledCallout(context).copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
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
              style: AppTextStyles.scaledCallout(context).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
    return Center(
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
                style: AppTextStyles.scaledTitle1(context).copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
              Text(
                'Add someone to walk with—through setbacks, growth, and everything in between.',
                style: AppTextStyles.scaledBody(context).copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
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
                        style: AppTextStyles.scaledButton(context).copyWith(
                          color: Colors.white,
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
      _expandedFriendId = friendId;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _toggleSort() async {
    setState(() => _isSorting = true);

    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final currentFriends = provider.friends;

    if (_isSortedByReminders) {
      // Restore original order
      if (_originalFriendsOrder != null) {
        provider.reorderFriends(_originalFriendsOrder!);
        ToastService.showSuccess(context, 'Sorted by custom order');
      }
      setState(() {
        _isSortedByReminders = false;
        _originalFriendsOrder = null;
      });
    } else {
      // Save current order
      _originalFriendsOrder = List<Friend>.from(currentFriends);

      // Sort by next reminder proximity
      final notificationService = NotificationService();
      final sortedFriends = await notificationService.sortFriendsByReminderProximityOptimized(currentFriends);

      provider.reorderFriends(sortedFriends);
      ToastService.showSuccess(context, 'Sorted by reminders');

      setState(() {
        _isSortedByReminders = true;
      });
    }

    setState(() => _isSorting = false);
  }

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