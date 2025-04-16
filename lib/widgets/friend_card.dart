// widgets/friend_card.dart
import 'dart:io';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/friend.dart';
import '../screens/add_friend_screen.dart';
import '../utils/constants.dart';

class FriendCard extends StatelessWidget {
  final Friend friend;

  const FriendCard({
    Key? key,
    required this.friend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: AppConstants.primaryTextColor,
      fontSize: 16,
      letterSpacing: 0.2,
    );

    final TextStyle valueStyle = TextStyle(
      color: AppConstants.secondaryTextColor,
      fontSize: 16,
      height: 1.5,
      letterSpacing: 0.1,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile image, name, and edit button consistently at top
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileImage(),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    friend.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24, // Increased to 24
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppConstants.primaryColor, size: 26), // Increased to match home screen
                  tooltip: 'Edit friend details',
                  padding: const EdgeInsets.all(8),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendScreen(friend: friend),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // "Alongside" information section - add icons for visual balance
          if (friend.helpingWith != null && friend.helpingWith!.isNotEmpty ||
              friend.theyHelpingWith != null && friend.theyHelpingWith!.isNotEmpty ||
              friend.reminderDays > 0)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (friend.helpingWith != null && friend.helpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          size: 22, // Slightly increased
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'You\'re alongside them in: ',
                                  style: labelStyle,
                                ),
                                TextSpan(
                                  text: friend.helpingWith,
                                  style: valueStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (friend.theyHelpingWith != null && friend.theyHelpingWith!.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 22, // Slightly increased
                          color: AppConstants.secondaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'They\'re alongside you in: ',
                                  style: labelStyle,
                                ),
                                TextSpan(
                                  text: friend.theyHelpingWith,
                                  style: valueStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (friend.reminderDays > 0) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 22, // Slightly increased
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Reminder: ',
                                  style: labelStyle,
                                ),
                                TextSpan(
                                  text: 'Every ${friend.reminderDays} ${friend.reminderDays == 1 ? 'day' : 'days'}',
                                  style: valueStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Divider to separate content from actions
          Divider(
            height: 1,
            thickness: 1,
            color: AppConstants.borderColor.withOpacity(0.6),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    Icons.message,
                    'Message',
                        () => _showMessageOptions(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildActionButton(
                    context,
                    Icons.phone,
                    'Call',
                        () => _callFriend(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Update the profile image to be slightly larger
  Widget _buildProfileImage() {
    if (friend.isEmoji) {
      return Container(
        width: 65, // Increased from 60
        height: 65, // Increased from 60
        decoration: BoxDecoration(
          color: AppConstants.profileCircleColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // Increased shadow opacity
              blurRadius: 6, // Increased blur
              offset: const Offset(0, 3), // Slightly larger offset
            ),
          ],
        ),
        child: Center(
          child: Text(
            friend.profileImage,
            style: const TextStyle(fontSize: 32), // Increased from 30
          ),
        ),
      );
    } else {
      return Container(
        width: 65, // Increased from 60
        height: 65, // Increased from 60
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(File(friend.profileImage)),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // Increased shadow opacity
              blurRadius: 8, // Increased blur
              offset: const Offset(0, 3), // Slightly larger offset
            ),
          ],
        ),
      );
    }
  }

// Update the action buttons to be more prominent with larger icons
  Widget _buildActionButton(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onPressed) {
    return Material(
      color: AppConstants.primaryColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        splashColor: AppConstants.primaryColor.withOpacity(0.2),
        highlightColor: AppConstants.primaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22, // Increased from 20 to match home screen icons
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showMessageOptions(BuildContext context) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();

    final allMessages = [...AppConstants.presetMessages, ...customMessages];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 0),
                  width: 100,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppConstants.bottomSheetHandleColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Match home screen padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Message ${friend.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const ManageMessagesScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings,
                            color: AppConstants.primaryColor, size: 26), // Increased icon size to match home
                        label: Text('Manage',
                            style: TextStyle(color: AppConstants.primaryColor, fontSize: 18)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: allMessages.length + 1, // +1 for "Custom Message" option
                    itemBuilder: (context, index) {
                      if (index == allMessages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0), // Reduced spacing between items
                          child: ListTile(
                            leading: Icon(Icons.add,
                                color: AppConstants.primaryColor, size: 26), // Increased to match home
                            title: Text(
                              'Create custom message',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.primaryTextColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4), // Reduced vertical padding, match home horizontal
                            onTap: () => _showCustomMessageDialog(context),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0), // Reduced spacing between items
                        child: ListTile(
                          title: Text(
                            allMessages[index],
                            style: TextStyle(
                              fontSize: 17,
                              color: AppConstants.primaryTextColor,
                              height: 1.4,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4), // Reduced vertical padding, match home horizontal
                          onTap: () {
                            Navigator.pop(context);
                            _sendMessage(context, allMessages[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Add bottom padding for safe area
                const SizedBox(height: 8), // Reduced bottom padding
              ],
            );
          },
        );
      },
    );
  }

  void _showCustomMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    // Calculate a fixed width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85; // 85% of screen width

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Create Message',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(28),
          content: Container(
            width: dialogWidth, // Fixed width container
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: AppConstants.secondaryTextColor,
                  fontSize: 17,
                ),
                contentPadding: const EdgeInsets.only(bottom: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: AppConstants.primaryColor
                          .withOpacity(AppConstants.mediumOpacity),
                      width: 1.5),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                  BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
                // No counter text
                counterText: '',
              ),
              style: TextStyle(
                fontSize: 17.0,
                color: AppConstants.primaryTextColor,
                height: 1.5,
              ),
              minLines: 1, // Start with 1 line
              maxLines: 3, // Grow up to 3 lines
              textInputAction: TextInputAction.newline, // Allow new lines
            ),
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(18),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close bottom sheet

                  // Save the custom message
                  final storageService = Provider.of<FriendsProvider>(
                    context,
                    listen: false,
                  ).storageService;

                  await storageService.addCustomMessage(textController.text);

                  // Send the message
                  _sendMessage(context, textController.text);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(18),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Save & Send'),
            ),
          ],
          actionsPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, String message) async {
    final phoneNumber = friend.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final smsUri =
      Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
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
        const SnackBar(
          content: Text('Unable to open messaging app. Try again later.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
  }

  void _callFriend(BuildContext context) async {
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
        const SnackBar(
          content: Text('Unable to open phone app. Try again later.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
    }
  }
}

// New screen to manage custom messages
class ManageMessagesScreen extends StatefulWidget {
  const ManageMessagesScreen({Key? key}) : super(key: key);

  @override
  State<ManageMessagesScreen> createState() => _ManageMessagesScreenState();
}

class _ManageMessagesScreenState extends State<ManageMessagesScreen> {
  List<String> _customMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final messages = await provider.storageService.getCustomMessages();

    setState(() {
      _customMessages = messages;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Custom Messages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppConstants.primaryColor,
            size: 28, // Match home screen icons
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
          child:
          CircularProgressIndicator(color: AppConstants.primaryColor))
          : _customMessages.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.message_outlined,
                size: 80,
                color: AppConstants.secondaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No custom messages yet',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  color: AppConstants.primaryTextColor,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Add custom messages when sending texts to friends',
                style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppConstants.secondaryTextColor,
                  fontSize: 17,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
        ),
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(20), // Match home screen padding
          itemCount: _customMessages.length,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                final double animValue =
                Curves.easeInOut.transform(animation.value);
                final double elevation = lerpDouble(0, 6, animValue)!;

                return Material(
                  elevation: elevation,
                  color: Colors.transparent,
                  shadowColor: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              child: child,
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = _customMessages.removeAt(oldIndex);
              _customMessages.insert(newIndex, item);

              // Save the new order
              Provider.of<FriendsProvider>(context, listen: false)
                  .storageService
                  .saveCustomMessages(_customMessages);
            });
          },
          itemBuilder: (context, index) {
            return Card(
              key: Key(_customMessages[index]),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: IconButton(
                  icon: Icon(Icons.delete,
                      color: AppConstants.deleteColor,
                      size: 26), // Increased to match home
                  onPressed: () => _deleteMessage(index),
                ),
                title: Text(
                  _customMessages[index],
                  style: TextStyle(
                    fontSize: 17,
                    color: AppConstants.primaryTextColor,
                    height: 1.4,
                  ),
                ),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: Icon(Icons.drag_handle,
                      color: AppConstants.secondaryTextColor,
                      size: 26), // Increased to match home
                ),
                contentPadding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMessageDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, size: 30), // Increased size to match home
      ),
    );
  }

  void _deleteMessage(int index) {
    final deletedMessage = _customMessages[index];

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Message',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppConstants.primaryTextColor,
            letterSpacing: -0.2,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this custom message?',
          style: TextStyle(
            fontSize: 17,
            color: AppConstants.primaryTextColor,
            height: 1.5,
          ),
        ),
        backgroundColor: AppConstants.dialogBackgroundColor,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.all(18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove the message
              setState(() {
                _customMessages.removeAt(index);
              });

              // Remove from storage
              Provider.of<FriendsProvider>(context, listen: false)
                  .storageService
                  .deleteCustomMessage(deletedMessage);

              // Close dialog
              Navigator.pop(context);

              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Message deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      setState(() {
                        _customMessages.insert(index, deletedMessage);
                        Provider.of<FriendsProvider>(context, listen: false)
                            .storageService
                            .saveCustomMessages(_customMessages);
                      });
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.deleteColor,
              padding: const EdgeInsets.all(18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showAddMessageDialog() {
    final textController = TextEditingController();

    // Calculate a fixed width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85; // 85% of screen width

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Add Custom Message',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(28),
          content: Container(
            width: dialogWidth, // Fixed width container
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: AppConstants.secondaryTextColor,
                  fontSize: 17,
                ),
                contentPadding: const EdgeInsets.only(bottom: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: AppConstants.primaryColor
                          .withOpacity(AppConstants.mediumOpacity),
                      width: 1.5),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide:
                  BorderSide(color: AppConstants.primaryColor, width: 2),
                ),
                // No counter text
                counterText: '',
              ),
              style: TextStyle(
                fontSize: 17.0,
                color: AppConstants.primaryTextColor,
                height: 1.5,
              ),
              minLines: 1, // Start with 1 line
              maxLines: 3, // Grow up to 3 lines
              textInputAction: TextInputAction.newline, // Allow new lines
            ),
          ),
          backgroundColor: AppConstants.dialogBackgroundColor,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(18),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  Navigator.pop(context);

                  // Add the new message
                  setState(() {
                    _customMessages.add(textController.text);
                  });

                  // Save to storage
                  await Provider.of<FriendsProvider>(context, listen: false)
                      .storageService
                      .saveCustomMessages(_customMessages);
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(18),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Add'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        );
      },
    );
  }
}