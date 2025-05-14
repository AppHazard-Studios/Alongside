import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../utils/text_styles.dart';

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
      backgroundColor: const Color(0xFFF2F2F7), // iOS grouped background
      appBar: AppBar(
        title: Text(
          'Manage Messages',
          style: AppTextStyles.navTitle,
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F2F7), // Match background
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF007AFF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _customMessages.isEmpty
          ? _buildEmptyState()
          : _buildMessagesList(),
      // Removed floating action button
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
                color: const Color(0xFF007AFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.bubble_left,
                size: 48,
                color: Color(0xFF007AFF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No custom messages yet',
              style: AppTextStyles.title,
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
              color: const Color(0xFF007AFF), // Match iOS style
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
    return Container(
      color: const Color(0xFFF2F2F7),
      child: Column(
        children: [
          // Add button at the top of the list
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF007AFF),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Create Message',
                    style: AppTextStyles.button,
                  ),
                ],
              ),
              onPressed: _showAddMessageDialog,
            ),
          ),

          // Message list
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              buildDefaultDragHandles: false,
              itemCount: _customMessages.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _customMessages.removeAt(oldIndex);
                  _customMessages.insert(newIndex, item);

                  Provider.of<FriendsProvider>(context, listen: false)
                      .storageService
                      .saveCustomMessages(_customMessages);
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey(_customMessages[index]),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _confirmDelete(index),
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: Color(0xFFFF3B30),
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _customMessages[index],
                              style: AppTextStyles.bodyText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              CupertinoIcons.line_horizontal_3,
                              color: Color(0xFF8E8E93),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(int index) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Delete Message',
          style: AppTextStyles.dialogTitle,
        ),
        content: Text(
          'Are you sure you want to delete this custom message?',
          style: AppTextStyles.dialogContent,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            isDefaultAction: true,
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: Text(
              'Delete',
              style: AppTextStyles.button.copyWith(
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deleteMessage(index);
    }

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

    // Show iOS-style toast
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Message deleted',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showAddMessageDialog() {
    final textController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Add Custom Message',
          style: AppTextStyles.dialogTitle,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: textController,
            placeholder: 'Type your message...',
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            style: AppTextStyles.inputText,
            placeholderStyle: AppTextStyles.placeholder,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: CupertinoColors.activeBlue,
              ),
            ),
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

                // Show iOS-style toast
                final overlay = Overlay.of(context);
                final overlayEntry = OverlayEntry(
                  builder: (context) => Positioned(
                    bottom: 100,
                    width: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Message saved',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                overlay.insert(overlayEntry);
                Future.delayed(const Duration(seconds: 2), () {
                  overlayEntry.remove();
                });
              }
            },
            child: Text(
              'Save',
              style: AppTextStyles.button.copyWith(
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
