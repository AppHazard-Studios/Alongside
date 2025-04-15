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
            return Center(child: CircularProgressIndicator(color: AppConstants.primaryColor));
          }

          final friends = friendsProvider.friends;

          if (friends.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 80,
                      color: AppConstants.secondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Walk alongside a friend',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppConstants.primaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add someone to walk with—through setbacks, growth, and everything in between.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppConstants.secondaryTextColor,
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
                      icon: const Icon(Icons.add),
                      label: const Text('Add Friend'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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

          return FloatingActionButton(
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
            child: const Icon(Icons.add),
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
          title: const Text('About Alongside'),
          backgroundColor: AppConstants.dialogBackgroundColor,
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
            'Alongside helps you walk with your friends through the highs and lows of life.',
            style: TextStyle(fontSize: 16, color: AppConstants.primaryTextColor),
          ),
          const SizedBox(height: 16),
          Text(
              'As Christians, we\'re called to carry one another\'s burdens—and this app helps you do that with just a few taps.',
          style: TextStyle(fontSize: 16, color: AppConstants.primaryTextColor),
        ),
        const SizedBox(height: 16),
        Text(
        'Everything stays on your device. It\'s private, secure, and fully in your control.',
        style: TextStyle(fontSize: 14, color: AppConstants.secondaryTextColor),
        ),
        ],
        ),
        actions: [
        TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
        padding: const EdgeInsets.all(16),
        foregroundColor: AppConstants.primaryColor,
        ),
        child: const Text('Close'),
        ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        ),
        );
      },
    );
  }
}