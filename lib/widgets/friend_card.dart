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
          //boxShadow: [
          //  BoxShadow(
          //    color: Colors.black.withOpacity(0.08), // Increased shadow opacity
          //    blurRadius: 6, // Increased blur
          //    offset: const Offset(0, 3), // Slightly larger offset
          //  ),
          //],
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
// Replace the entire _showMessageOptions method with this corrected version:

  void _showMessageOptions(BuildContext context) async {
    final provider = Provider.of<FriendsProvider>(context, listen: false);
    final customMessages = await provider.storageService.getCustomMessages();

    final allMessages = [...AppConstants.presetMessages, ...customMessages];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Use the app's main background color instead of a tinted primary color
      backgroundColor: const Color(AppConstants.backgroundColorValue),
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
                // Handle at the top
                Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 0),
                  width: 100,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppConstants.bottomSheetHandleColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Header with title and manage button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Message ${friend.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppConstants.primaryTextColor,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageMessagesScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings, color: AppConstants.primaryColor, size: 26),
                        label: Text('Manage', style: TextStyle(color: AppConstants.primaryColor, fontSize: 18)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Message list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: allMessages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == allMessages.length) {
                        // Create custom message option
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Card(
                            elevation: 2,
                            color: Colors.white, // Explicit white background
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                            ),
                            child: InkWell(
                              onTap: () => _showCustomMessageDialog(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 24,
                                      color: AppConstants.primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Create custom message',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Regular message option
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Card(
                          elevation: 2,
                          color: Colors.white, // Explicit white background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _sendMessage(context, allMessages[index]);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              child: Text(
                                allMessages[index],
                                style: TextStyle(
                                  fontSize: 18,
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

                const SizedBox(height: 8),
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
            child: TextFormField(
              controller: textController,
              // Use the same style as the AddFriend form fields
              decoration: InputDecoration(
                labelText: 'Type your message...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelStyle: TextStyle(
                  fontSize: 17,
                  color: AppConstants.secondaryTextColor,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(
                fontSize: 17.0,
                color: AppConstants.primaryTextColor,
                height: 1.5,
              ),
              minLines: 2, // Start with 2 lines
              maxLines: 5, // Grow up to 5 lines
              textCapitalization: TextCapitalization.sentences,
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
                  // Save the custom message
                  final storageService = Provider.of<FriendsProvider>(
                    context,
                    listen: false,
                  ).storageService;

                  await storageService.addCustomMessage(textController.text);
                  Navigator.pop(context); // Just close the dialog, don't send message

                  // Show a brief feedback that message was saved with updated styling
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Message saved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  );
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
              child: const Text('Save'), // Changed from "Save & Send" to just "Save"
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
      // For error snackbars, use a warning color to differentiate them
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open messaging app. Try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      // For error snackbars, use a warning color to differentiate them
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open phone app. Try again later.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            size: 26, // Match home screen icons
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
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _customMessages.length,
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
            return Dismissible(
              key: Key('dismissible-${_customMessages[index]}'),
              background: Container(
                color: AppConstants.deleteColor.withOpacity(0.1),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.delete,
                  color: AppConstants.deleteColor,
                  size: 26,
                ),
              ),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _deleteMessage(index);
              },
              confirmDismiss: (direction) {
                return _confirmDelete(index);
              },
              child: Card(
                key: ValueKey(_customMessages[index]), // Required for ReorderableListView
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ListTile(
                    title: Text(
                      _customMessages[index],
                      style: TextStyle(
                        fontSize: 18, // Increased font size
                        color: AppConstants.primaryTextColor,
                        height: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle,
                          color: AppConstants.secondaryTextColor,
                          size: 26), // Increased to match home
                    ),
                  ),
                ),
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

  Future<bool> _confirmDelete(int index) async {
    return await showDialog(
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
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
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
    ) ?? false; // In case the dialog is dismissed
  }

  void _deleteMessage(int index) {
    final deletedMessage = _customMessages[index];

    // Remove the message
    setState(() {
      _customMessages.removeAt(index);
    });

    // Remove from storage
    Provider.of<FriendsProvider>(context, listen: false)
        .storageService
        .deleteCustomMessage(deletedMessage);

    // Show snackbar with updated styling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Message deleted',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white, // White text for better visibility
          onPressed: () {
            setState(() {
              _customMessages.insert(index, deletedMessage);
              Provider.of<FriendsProvider>(context, listen: false)
                  .storageService
                  .saveCustomMessages(_customMessages);
            });
          },
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            child: TextFormField(
              controller: textController,
              // Use the same style as the AddFriend form fields
              decoration: InputDecoration(
                labelText: 'Type your message...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
                labelStyle: TextStyle(
                  fontSize: 17,
                  color: AppConstants.secondaryTextColor,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: TextStyle(
                fontSize: 17.0,
                color: AppConstants.primaryTextColor,
                height: 1.5,
              ),
              minLines: 2, // Start with 2 lines
              maxLines: 5, // Grow up to 5 lines
              textCapitalization: TextCapitalization.sentences,
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

                  // Show a brief feedback that message was saved with updated styling
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Message saved',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppConstants.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  );
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
              child: const Text('Save'), // Changed from "Save & Send" to just "Save"
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        );
      },
    );
  }
}