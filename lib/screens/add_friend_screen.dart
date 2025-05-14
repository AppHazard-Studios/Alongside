// Final Fix to match EXACTLY the screenshots provided

// 1. Fix the Add Friend Screen - Specifically the yellow underlines & exact styling
// lib/screens/add_friend_screen.dart - Critical fixes

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../main.dart';
import '../models/friend.dart';
import '../utils/constants.dart';

class AddFriendScreen extends StatefulWidget {
  final Friend? friend;

  const AddFriendScreen({Key? key, this.friend}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _helpingThemWithController = TextEditingController();
  final _helpingYouWithController = TextEditingController();

  String _profileImage = '😊'; // Default emoji
  bool _isEmoji = true;
  int _reminderDays = 0;
  bool _hasPersistentNotification = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0); // Default to 9:00 AM

  @override
  void initState() {
    super.initState();

    if (widget.friend != null) {
      _nameController.text = widget.friend!.name;
      _phoneController.text = widget.friend!.phoneNumber;
      _profileImage = widget.friend!.profileImage;
      _isEmoji = widget.friend!.isEmoji;
      _reminderDays = widget.friend!.reminderDays;
      _hasPersistentNotification = widget.friend!.hasPersistentNotification;
      _helpingThemWithController.text = widget.friend!.helpingWith ?? '';
      _helpingYouWithController.text = widget.friend!.theyHelpingWith ?? '';

      // Parse the reminder time from string format "HH:MM"
      final timeParts = widget.friend!.reminderTime.split(':');
      if (timeParts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 9,
          minute: int.tryParse(timeParts[1]) ?? 0,
        );
      }
    }
  }

  // Method to pick a contact
  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      try {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        // Show iOS-style contact picker
        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: const Text('Select a Contact'),
            actions: [
              SizedBox(
                height: 300,
                child: CupertinoScrollbar(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      return CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.pop(context, contacts[index]);
                        },
                        child: Text(contacts[index].displayName),
                      );
                    },
                  ),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
          ),
        ).then((contact) {
          if (contact != null && contact.phones.isNotEmpty) {
            setState(() {
              _nameController.text = contact.displayName;
              _phoneController.text = contact.phones.first.number;
            });
          } else if (contact != null) {
            _showErrorSnackBar('Selected contact has no phone number');
          }
        });
      } catch (e) {
        _showErrorSnackBar('Error accessing contacts: $e');
      }
    } else {
      _showErrorSnackBar('Permission to access contacts was denied');
    }
  }

  void _showErrorSnackBar(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.white,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Add Friend',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF007AFF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveFriend,
          child: const Text(
            'Save',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 17,
              color: Color(0xFF007AFF),
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        backgroundColor: Colors.white,
        border: null,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 16),
            children: [
              // Profile image selection - EXACT match to screenshot
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showProfileOptions,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        child: _isEmoji
                            ? Center(
                          child: Text(
                            _profileImage,
                            style: const TextStyle(fontSize: 50),
                          ),
                        )
                            : ClipOval(
                          child: Image.file(
                            File(_profileImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            CupertinoIcons.camera,
                            color: Color(0xFF007AFF),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Change Profile',
                            style: TextStyle(
                              color: Color(0xFF007AFF),
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ],
                      ),
                      onPressed: _showProfileOptions,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form sections - EXACT match to screenshot with proper styling
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Name field - matches screenshot exactly
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.person,
                            color: Color(0xFF007AFF),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Name',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                CupertinoTextField(
                                  controller: _nameController,
                                  placeholder: 'Enter name',
                                  placeholderStyle: const TextStyle(
                                    color: Color(0xFFBEBEC0),
                                    fontSize: 17,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      height: 0.5,
                      color: const Color(0xFFE5E5EA),
                      margin: const EdgeInsets.only(left: 50),
                    ),
                    // Phone Number field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.phone,
                            color: Color(0xFF007AFF),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CupertinoTextField(
                                        controller: _phoneController,
                                        placeholder: 'Enter phone number',
                                        placeholderStyle: const TextStyle(
                                          color: Color(0xFFBEBEC0),
                                          fontSize: 17,
                                          fontFamily: '.SF Pro Text',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontFamily: '.SF Pro Text',
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.transparent,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: _pickContact,
                                      child: const Icon(
                                        CupertinoIcons.book,
                                        color: Color(0xFF007AFF),
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // "Alongside" information section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // What are you alongside them in?
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.heart,
                            color: Color(0xFF007AFF),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'What are you alongside them in?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                CupertinoTextField(
                                  controller: _helpingThemWithController,
                                  placeholder: 'e.g., "Accountability for exercise"',
                                  placeholderStyle: const TextStyle(
                                    color: Color(0xFFBEBEC0),
                                    fontSize: 17,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      height: 0.5,
                      color: const Color(0xFFE5E5EA),
                      margin: const EdgeInsets.only(left: 50),
                    ),
                    // What are they alongside you in?
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.person_2,
                            color: Color(0xFF007AFF),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'What are they alongside you in?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                CupertinoTextField(
                                  controller: _helpingYouWithController,
                                  placeholder: 'e.g., "Prayer for family issues"',
                                  placeholderStyle: const TextStyle(
                                    color: Color(0xFFBEBEC0),
                                    fontSize: 17,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // NOTIFICATION SETTINGS section
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  'NOTIFICATION SETTINGS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E93),
                    letterSpacing: 0.5,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Check-in Reminder
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.bell,
                            color: Color(0xFF007AFF),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Check-in Reminder',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showReminderPicker,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _reminderDays == 0
                                            ? 'No reminder'
                                            : _reminderDays == 1
                                            ? 'Every day'
                                            : 'Every $_reminderDays days',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontFamily: '.SF Pro Text',
                                        ),
                                      ),
                                      const Icon(
                                        CupertinoIcons.chevron_down,
                                        size: 16,
                                        color: Color(0xFFBEBEC0),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      height: 0.5,
                      color: const Color(0xFFE5E5EA),
                      margin: const EdgeInsets.only(left: 50),
                    ),
                    // Show in notification area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.rectangle_stack_badge_person_crop,
                            color: Color(0xFF007AFF),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Show in notification area',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                                const Text(
                                  'Keep a quick access notification for this friend',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: _hasPersistentNotification,
                            onChanged: (value) {
                              setState(() {
                                _hasPersistentNotification = value;
                              });
                            },
                            activeColor: const Color(0xFF007AFF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

// Rest of methods with minimal changes needed
// ...
}