// Final check for ManageMessagesScreen.dart - make it match the rest of the app

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../main.dart';

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
        title: const Text(
          'Manage Messages',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMessageDialog,
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(CupertinoIcons.add, size: 24),
      ),
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
            const Text(
              'No custom messages yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Add custom messages when sending texts to friends',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontFamily: '.SF Pro Text',
                        ),
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
    );
  }

  Future<bool> _confirmDelete(int index) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Delete Message',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this custom message?',
          style: TextStyle(
            fontSize: 13,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            isDefaultAction: true,
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text('Delete'),
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
            child: const Text(
              'Message deleted',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: '.SF Pro Text',
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
        title: const Text(
          'Add Custom Message',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
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
            style: const TextStyle(
              fontSize: 17,
              fontFamily: '.SF Pro Text',
            ),
            placeholderStyle: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 17,
              fontFamily: '.SF Pro Text',
            ),
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text('Cancel'),
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
                        child: const Text(
                          'Message saved',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: '.SF Pro Text',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}