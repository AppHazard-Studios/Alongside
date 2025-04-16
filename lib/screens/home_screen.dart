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
        title: const Text(
          'Alongside',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppConstants.primaryColor),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
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
                      icon: const Icon(Icons.add),
                      label: const Text('Add Friend'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
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

          // Add padding to the bottom of the ListView to prevent FAB from covering items
          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              // Added extra bottom padding to ensure last item is above FAB
              bottom: 100, // Increased from default to accommodate FAB
            ),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              return FriendCard(friend: friends[index]);
            },
          );
        },
      ),
      floatingActionButton: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.friends.isEmpty) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendScreen(),
                ),
              );
            },
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Friend'),
            elevation: 4,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

// Also update the about dialog
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
              const Text('About Alongside'),
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
                  fontSize: 16,
                  color: AppConstants.primaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.primaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 20,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Everything stays on your device. It\'s private, secure, and fully in your control.',
                        style: TextStyle(
                          fontSize: 14,
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
                    horizontal: 16, vertical: 12),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Close'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}