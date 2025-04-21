// screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/friend_card.dart';
import '../utils/constants.dart';
import '../models/friend.dart';
import 'add_friend_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Consumer<FriendsProvider>(
          builder: (context, friendsProvider, child) {
            if (friendsProvider.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
              );
            }

            final friends = friendsProvider.friends;

            if (friends.isEmpty) {
              return _buildEmptyState(context);
            }

            // Find upcoming reminders
            final upcomingReminders = friends
                .where((f) => f.reminderDays > 0)
                .toList()
              ..sort((a, b) => a.reminderDays.compareTo(b.reminderDays));

            return CustomScrollView(
              slivers: [
                // Custom app bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: AppConstants.backgroundColor,
                  elevation: 0,
                  title: Row(
                    children: [
                      Text(
                        'Alongside',
                        style: TextStyle(
                          color: AppConstants.primaryTextColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: AppConstants.primaryColor,
                        ),
                        onPressed: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                  expandedHeight: 120,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
                      child: Text(
                        'Your connections',
                        style: TextStyle(
                          color: AppConstants.secondaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Upcoming reminders carousel
                if (upcomingReminders.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timelapse_rounded,
                                size: 20,
                                color: AppConstants.accentColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Upcoming check-ins',
                                style: TextStyle(
                                  color: AppConstants.primaryTextColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                            itemCount: upcomingReminders.length.clamp(0, 5),
                            itemBuilder: (context, index) {
                              return _buildReminderCard(context, upcomingReminders[index]);
                            },
                          ),
                        ),
                        const Divider(height: 32, indent: 16, endIndent: 16),
                      ],
                    ),
                  ),

                // Friend list
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'All connections',
                      style: TextStyle(
                        color: AppConstants.primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return FriendCard(friend: friends[index]);
                    },
                    childCount: friends.length,
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFriendScreen(),
            ),
          );
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, Friend friend) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to friend detail or show quick actions
              _showQuickActionSheet(context, friend);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image with reminder badge
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: friend.isEmoji ? AppConstants.profileCircleColor : null,
                          shape: BoxShape.circle,
                          image: !friend.isEmoji
                              ? DecorationImage(
                            image: FileImage(File(friend.profileImage)),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: friend.isEmoji
                            ? Center(
                          child: Text(
                            friend.profileImage,
                            style: const TextStyle(fontSize: 24),
                          ),
                        )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppConstants.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.cardColor,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${friend.reminderDays}d',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    friend.name,
                    style: TextStyle(
                      color: AppConstants.primaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Supporting text
                  Text(
                    friend.helpingWith != null && friend.helpingWith!.isNotEmpty
                        ? 'Alongside in: ${friend.helpingWith}'
                        : 'Tap to check in',
                    style: TextStyle(
                      color: AppConstants.secondaryTextColor,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickActionSheet(BuildContext context, Friend friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.bottomSheetHandleColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Friend info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: friend.isEmoji ? AppConstants.profileCircleColor : null,
                        shape: BoxShape.circle,
                        image: !friend.isEmoji
                            ? DecorationImage(
                          image: FileImage(File(friend.profileImage)),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: friend.isEmoji
                          ? Center(
                        child: Text(
                          friend.profileImage,
                          style: const TextStyle(fontSize: 30),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: TextStyle(
                              color: AppConstants.primaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (friend.helpingWith != null && friend.helpingWith!.isNotEmpty)
                            Text(
                              'Alongside them in: ${friend.helpingWith}',
                              style: TextStyle(
                                color: AppConstants.secondaryTextColor,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMessageOptions(context, friend);
                        },
                        icon: const Icon(Icons.message_rounded),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _callFriend(context, friend);
                        },
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // View details button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendScreen(friend: friend),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppConstants.primaryColor,
                  ),
                  label: Text(
                    'Edit details',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_alt_rounded,
                size: 64,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Walking Alongside',
              style: TextStyle(
                color: AppConstants.primaryTextColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Add someone to walk with—through setbacks, growth, and everything in between.',
              style: TextStyle(
                color: AppConstants.secondaryTextColor,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFriendScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add First Friend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'About Alongside',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryTextColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alongside helps you walk with your friends through the highs and lows of life.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppConstants.primaryTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppConstants.primaryTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 20,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Everything stays on your device. It\'s private, secure, and fully in your control.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.primaryTextColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Close'),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        );
      },
    );
  }

  void _showMessageOptions(BuildContext context, Friend friend) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();

    final allMessages = [...AppConstants.presetMessages, ...customMessages];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Handle at the top
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 0),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.bottomSheetHandleColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header with title and settings icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        // Profile icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.message_rounded,
                            color: AppConstants.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Centered title
                        Expanded(
                          child: Text(
                            'Message ${friend.name}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  // Message list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: allMessages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == allMessages.length) {
                          // Create custom message option
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: InkWell(
                              onTap: () => _showCustomMessageDialog(context, friend),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: AppConstants.primaryColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Create custom message',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // Regular message option
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: AppConstants.borderColor, width: 1),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _sendMessage(context, friend, allMessages[index]);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Text(
                                  allMessages[index],
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppConstants.primaryTextColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showCustomMessageDialog(BuildContext context, Friend friend) {
    final textController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Create Message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: dialogWidth,
            child: TextFormField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppConstants.borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelStyle: TextStyle(
                  fontSize: 15,
                  color: AppConstants.secondaryTextColor,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(
                fontSize: 15,
                color: AppConstants.primaryTextColor,
                height: 1.4,
              ),
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
            ),
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  final storageService = Provider.of<FriendsProvider>(
                    context,
                    listen: false,
                  ).storageService;

                  await storageService.addCustomMessage(textController.text);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Message saved',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, Friend friend, String message) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      bool launched = await launchUrl(
        smsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final telUri = Uri.parse('tel:$phoneNumber');
        await launchUrl(
          telUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to open messaging app. Try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
    }
  }

  void _callFriend(BuildContext context, Friend friend) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final telUri = Uri.parse('tel:$phoneNumber');
      bool launched = await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Could not launch dialer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Unable to open phone app. Try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
    }
  }
}