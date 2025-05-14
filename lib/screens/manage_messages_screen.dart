// Create this file at lib/screens/manage_messages_screen_new.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../widgets/character_components.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Manage Messages',
          style: AppTextStyles.navTitle.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.back,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CupertinoActivityIndicator())
          : _customMessages.isEmpty
          ? _buildEmptyState()
          : _buildMessagesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.bubble_left,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No custom messages yet',
              style: AppTextStyles.title.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add custom messages when sending texts to friends',
              style: AppTextStyles.secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: AppColors.primary,
              child: Text(
                'Create Message',
                style: AppTextStyles.button,
              ),
              onPressed: _showAddMessageDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Column(
      children: [
        // Add button at the top of the list
        Padding(
          padding: const EdgeInsets.all(16),
          child: CharacterComponents.playfulButton(
            label: 'Create Message',
            icon: CupertinoIcons.add,
            backgroundColor: AppColors.primary,
            onPressed: _showAddMessageDialog,
          ),
        ),

        // Message list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            itemCount: _customMessages.length,
            itemBuilder: (context, index) {
              return Dismissible(
                key: ValueKey(_customMessages[index]),
                background: Container(
                  color: AppColors.error.withOpacity(0.2),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: Icon(
                    CupertinoIcons.delete,
                    color: AppColors.error,
                  ),
                ),
                secondaryBackground: Container(
                  color: AppColors.error.withOpacity(0.2),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    CupertinoIcons.delete,
                    color: AppColors.error,
                  ),
                ),
                onDismissed: (direction) => _deleteMessage(index),
                confirmDismiss: (direction) => _confirmDelete(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      _customMessages[index],
                      style: AppTextStyles.bodyText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          CupertinoIcons.line_horizontal_3,
                          color: AppColors.textSecondary,
                          size: 20,
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
  }

  Future<bool> _confirmDelete(int index) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Delete Message',
          style: TextStyle(color: AppColors.error),
        ),
        content: Text(
          'Are you sure you want to delete this custom message?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            isDefaultAction: true,
            child: Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: Text('Delete'),
          ),
        ],
      ),
    );

    return shouldDelete ?? false;
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

    // Show toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message deleted'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showAddMessageDialog() {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Add Custom Message',
          style: TextStyle(color: AppColors.primary),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Type your message...',
            padding: const EdgeInsets.all(12),
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text('Cancel'),
          ),
          CupertinoDialogAction(
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

                // Show toast
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message saved'),
                      duration: Duration(seconds: 2),
                      backgroundColor: AppColors.primary,
                    )
                );
              }
            },
            child: Text(
              'Save',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}