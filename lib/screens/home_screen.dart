// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/friend_card.dart';
import '../utils/constants.dart';
import 'add_friend_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Use primaryColor with opacity for background - matching button style in friend_card
        backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
        elevation: 0,
        title: const Text(
          'Alongside',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30, // Larger title font
            color: Color(AppConstants.primaryTextColorValue), // Use primary text color
            letterSpacing: -0.3,
          ),
        ),
        // Info button on the left
        leading: IconButton(
          icon: Icon(
            Icons.info_outline,
            color: AppConstants.primaryColor, // Use primary color
            size: 26, // Larger icon
          ),
          padding: const EdgeInsets.only(left: 16.0),
          onPressed: () => _showAboutDialog(context),
        ),
        // Add button on the right - larger plus icon
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                Icons.add, // Simple plus icon
                color: AppConstants.primaryColor, // Use primary color
                size: 36, // Larger plus icon
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFriendScreen(),
                  ),
                );
              },
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryColor,
                strokeWidth: 3,
              ),
            );
          }

          final friends = friendsProvider.friends;

          if (friends.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Subtle animation for icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      curve: Curves.easeInOut,
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.people_alt_outlined,
                            size: 88,
                            color: AppConstants.secondaryColor.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Walk alongside a friend',
                      style: Theme
                          .of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        color: AppConstants.primaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add someone to walk with—through setbacks, growth, and everything in between.',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                        color: AppConstants.secondaryTextColor,
                        fontSize: 17, // Increased font size
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddFriendScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 24), // Increased icon size
                      label: const Text(
                        'Add Friend',
                        style: TextStyle(
                          fontSize: 17, // Increased font size
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17, // Increased font size
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 30,
            ),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              return FriendCard(friend: friends[index]);
            },
          );
        },
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
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'About Alongside',
                style: TextStyle(
                  fontSize: 22, // Increased font size
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryTextColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alongside helps you walk with your friends through the highs and lows of life.',
                style: TextStyle(
                  fontSize: 17, // Increased font size
                  color: AppConstants.primaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                style: TextStyle(
                  fontSize: 17, // Increased font size
                  color: AppConstants.primaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16), // Increased padding
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 24,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Everything stays on your device. It\'s private, secure, and fully in your control.',
                        style: TextStyle(
                          fontSize: 16, // Increased font size
                          color: AppConstants.primaryTextColor,
                          height: 1.4,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12), // Increased padding
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 17, // Increased font size
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Close'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12), // Increased padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}