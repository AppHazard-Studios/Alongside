// lib/screens/add_friend_screen.dart - Complete file with delete friend functionality
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../providers/friends_provider.dart';
import '../models/friend.dart';
import '../utils/constants.dart';
import '../widgets/no_underline_field.dart';

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

  // Using a string for reminder time to avoid Material TimeOfDay dependency
  String _reminderTimeStr = "09:00"; // Default to 9:00 AM

  // Parse time for display in 12-hour format
  String get _formattedReminderTime {
    final parts = _reminderTimeStr.split(':');
    if (parts.length == 2) {
      int hour = int.tryParse(parts[0]) ?? 9;
      int minute = int.tryParse(parts[1]) ?? 0;

      final period = hour < 12 ? 'AM' : 'PM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    }
    return "9:00 AM";
  }

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
      _reminderTimeStr = widget.friend!.reminderTime;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _helpingThemWithController.dispose();
    _helpingYouWithController.dispose();
    super.dispose();
  }

  // Method to pick a contact
  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      try {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: const Text(
              'Select a Contact',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
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
                        child: Text(
                          contacts[index].displayName,
                          style: const TextStyle(
                            color: CupertinoColors.label,
                            fontSize: 16,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontWeight: FontWeight.w600,
                  fontFamily: '.SF Pro Text',
                ),
              ),
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
        title: const Text(
          'Error',
          style: TextStyle(
            color: CupertinoColors.destructiveRed,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: CupertinoColors.label,
            fontSize: 16,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          'Choose Profile Image',
          style: TextStyle(
            color: CupertinoColors.systemBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showEmojiPicker();
            },
            child: const Text(
              'Choose Emoji',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.camera);
            },
            child: const Text(
              'Take Photo',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.gallery);
            },
            child: const Text(
              'Choose from Library',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: CupertinoColors.destructiveRed,
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final Directory docDir = await getApplicationDocumentsDirectory();
        final String imagePath = '${docDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        await File(pickedFile.path).copy(imagePath);

        setState(() {
          _profileImage = imagePath;
          _isEmoji = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  void _showEmojiPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(16),
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Choose Emoji',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: AppConstants.profileEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = AppConstants.profileEmojis[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _profileImage = emoji;
                        _isEmoji = true;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderPicker() {
    const reminderOptions = [0, 1, 3, 7, 14, 30];
    int selectedOption = _reminderDays;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _reminderDays = selectedOption;
                    });
                    Navigator.pop(context);

                    if (selectedOption > 0) {
                      _showTimePicker();
                    }
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                looping: false,
                scrollController: FixedExtentScrollController(
                  initialItem: reminderOptions.indexOf(
                    reminderOptions.contains(_reminderDays) ? _reminderDays : 0,
                  ),
                ),
                onSelectedItemChanged: (index) {
                  selectedOption = reminderOptions[index];
                },
                children: reminderOptions.map((days) {
                  return Center(
                    child: Text(
                      days == 0
                          ? 'No reminder'
                          : days == 1
                          ? 'Every day'
                          : 'Every $days days',
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker() {
    // Extract current hours and minutes from string
    final parts = _reminderTimeStr.split(':');
    int currentHour = int.tryParse(parts[0]) ?? 9;
    int currentMinute = int.tryParse(parts[1]) ?? 0;

    // Create initial DateTime for the picker
    final initialDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      currentHour,
      currentMinute,
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (dateTime) {
                  setState(() {
                    // Update time string in HH:MM format
                    _reminderTimeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                  });
                },
                use24hFormat: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveFriend() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a name');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a phone number');
      return;
    }

    final provider = Provider.of<FriendsProvider>(context, listen: false);

    if (widget.friend == null) {
      // Create a new friend
      final newFriend = Friend(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImage: _profileImage,
        isEmoji: _isEmoji,
        reminderDays: _reminderDays,
        reminderTime: _reminderTimeStr,
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
      );
      await provider.addFriend(newFriend);
    } else {
      // Update existing friend
      final updatedFriend = widget.friend!.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImage: _profileImage,
        isEmoji: _isEmoji,
        reminderDays: _reminderDays,
        reminderTime: _reminderTimeStr,
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
      );
      await provider.updateFriend(updatedFriend);
    }

    if (mounted) Navigator.pop(context);
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Remove Friend',
          style: TextStyle(
            color: CupertinoColors.destructiveRed,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to remove ${widget.friend!.name}? This action cannot be undone.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.3,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final provider = Provider.of<FriendsProvider>(context, listen: false);
              await provider.removeFriend(widget.friend!.id);

              // Navigate back to home screen
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            isDestructiveAction: true,
            child: const Text(
              'Remove',
              style: TextStyle(
                color: CupertinoColors.destructiveRed,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(  // Wrap in Material for localizations
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
        ),
        home: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemGroupedBackground,
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              widget.friend == null ? 'Add Friend' : 'Edit Friend',
              style: const TextStyle(
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                fontFamily: '.SF Pro Text',
              ),
            ),
            backgroundColor: CupertinoColors.systemGroupedBackground,
            leading: CupertinoButton(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  size: 16,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            trailing: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              onPressed: _saveFriend,
            ),
            border: null,
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(top: 16),
                children: [
                  // Profile image selection - with white background for emoji
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showProfileOptions,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: CupertinoColors.white, // White background for all profile images
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.systemGrey5,
                                width: 0.5,
                              ),
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
                          onPressed: _showProfileOptions,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.camera,
                                color: CupertinoColors.systemBlue,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Change Profile',
                                style: TextStyle(
                                  color: CupertinoColors.systemBlue,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: '.SF Pro Text',
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Basic info section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Name field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.person_fill,
                                  color: CupertinoColors.systemBlue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: NoUnderlineField(
                                  controller: _nameController,
                                  label: 'Name',
                                  placeholder: 'Enter name',
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          height: 0.5,
                          color: CupertinoColors.systemGrey5,
                          margin: const EdgeInsets.only(left: 66),
                        ),

                        // Phone Number field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.phone_fill,
                                  color: CupertinoColors.systemGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: NoUnderlineField(
                                  controller: _phoneController,
                                  label: 'Phone Number',
                                  placeholder: 'Enter phone number',
                                  keyboardType: TextInputType.phone,
                                  suffixIcon: GestureDetector(
                                    onTap: _pickContact,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGreen.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.book_fill,
                                        size: 16,
                                        color: CupertinoColors.systemGreen,
                                      ),
                                    ),
                                  ),
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
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // What are you alongside them in?
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.heart_fill,
                                  color: CupertinoColors.systemBlue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: NoUnderlineField(
                                  controller: _helpingThemWithController,
                                  label: 'What are you alongside them in?',
                                  placeholder: 'e.g., "Accountability for exercise"',
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          height: 0.5,
                          color: CupertinoColors.systemGrey5,
                          margin: const EdgeInsets.only(left: 66),
                        ),

                        // What are they alongside you in?
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.person_2_fill,
                                  color: CupertinoColors.systemBlue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: NoUnderlineField(
                                  controller: _helpingYouWithController,
                                  label: 'What are they alongside you in?',
                                  placeholder: 'e.g., "Prayer for family issues"',
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // NOTIFICATION SETTINGS section
                  const Padding(
                    padding: EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'NOTIFICATION SETTINGS',
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Check-in Reminder - Made entire row tappable with GestureDetector
                        GestureDetector(
                          onTap: _showReminderPicker,
                          behavior: HitTestBehavior.opaque, // Important: Makes entire area tappable
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemOrange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.bell_fill,
                                    color: CupertinoColors.systemOrange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Check-in Reminder',
                                        style: TextStyle(
                                          color: CupertinoColors.secondaryLabel,
                                          fontSize: 14,
                                          fontFamily: '.SF Pro Text',
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _reminderDays == 0
                                                ? 'No reminder'
                                                : _reminderDays == 1
                                                ? 'Every day'
                                                : 'Every $_reminderDays days',
                                            style: const TextStyle(
                                              color: CupertinoColors.label,
                                              fontSize: 16,
                                              fontFamily: '.SF Pro Text',
                                            ),
                                          ),
                                          const Icon(
                                            CupertinoIcons.chevron_down,
                                            size: 14,
                                            color: CupertinoColors.secondaryLabel,
                                          ),
                                        ],
                                      ),
                                      if (_reminderDays > 0) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              CupertinoIcons.time,
                                              size: 12,
                                              color: CupertinoColors.secondaryLabel,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'At $_formattedReminderTime',
                                              style: const TextStyle(
                                                color: CupertinoColors.secondaryLabel,
                                                fontSize: 13,
                                                fontFamily: '.SF Pro Text',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Container(
                          height: 0.5,
                          color: CupertinoColors.systemGrey5,
                          margin: const EdgeInsets.only(left: 66),
                        ),

                        // Show in notification area - Made entire row tappable
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _hasPersistentNotification = !_hasPersistentNotification;
                            });
                          },
                          behavior: HitTestBehavior.opaque, // Important: Makes entire area tappable
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.rectangle_stack_badge_person_crop,
                                    color: CupertinoColors.systemBlue,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Show in notification area',
                                        style: TextStyle(
                                          color: CupertinoColors.label,
                                          fontSize: 16,
                                          fontFamily: '.SF Pro Text',
                                        ),
                                      ),
                                      Text(
                                        'Keep a quick access notification for this friend',
                                        style: TextStyle(
                                          color: CupertinoColors.secondaryLabel,
                                          fontSize: 14,
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
                                  activeColor: CupertinoColors.systemBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Delete friend button (only when editing)
                  if (widget.friend != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: CupertinoColors.destructiveRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        onPressed: () => _showDeleteConfirmation(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.delete,
                              color: CupertinoColors.destructiveRed,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Remove Friend',
                              style: TextStyle(
                                color: CupertinoColors.destructiveRed,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}