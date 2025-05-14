// lib/screens/add_friend_screen.dart - Complete file
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
import '../widgets/no_underline_field.dart'; // Import our custom field

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

  void _showProfileOptions() {
    // Show options for profile picture selection
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Choose Profile Image'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showEmojiPicker();
            },
            child: const Text('Choose Emoji'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.gallery);
            },
            child: const Text('Choose from Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
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
        // Get documents directory for storing the file
        final Directory docDir = await getApplicationDocumentsDirectory();
        final String imagePath = '${docDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Copy the file to the app's storage
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
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Choose Emoji',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done'),
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
                  return InkWell(
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
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    setState(() {
                      _reminderDays = selectedOption;
                    });
                    Navigator.pop(context);

                    // If they set a reminder, show the time picker
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
                        fontSize: 17,
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
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2023, 1, 1,
                  _reminderTime.hour,
                  _reminderTime.minute,
                ),
                onDateTimeChanged: (dateTime) {
                  setState(() {
                    _reminderTime = TimeOfDay(
                      hour: dateTime.hour,
                      minute: dateTime.minute,
                    );
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
    // Validate form fields
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
        reminderTime: '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
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
        reminderTime: '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
      );
      await provider.updateFriend(updatedFriend);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS background color
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7), // Match background color
        elevation: 0, // No shadow
        title: Text(
          widget.friend == null ? 'Add Friend' : 'Edit Friend',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF007AFF),
          ),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        actions: [
          TextButton(
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
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: 16),
          children: [
            // Profile image selection
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
                  TextButton.icon(
                    onPressed: _showProfileOptions,
                    icon: const Icon(
                      CupertinoIcons.camera,
                      color: Color(0xFF007AFF),
                      size: 20,
                    ),
                    label: const Text(
                      'Change Profile',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        fontFamily: '.SF Pro Text',
                      ),
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
                  // Name field - GUARANTEED NO YELLOW UNDERLINES
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
                          child: NoUnderlineField(
                            controller: _nameController,
                            label: 'Name',
                            placeholder: 'Enter name',
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

                  // Phone Number field - GUARANTEED NO YELLOW UNDERLINES
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
                          child: NoUnderlineField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            placeholder: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                            suffixIcon: IconButton(
                              icon: const Icon(
                                CupertinoIcons.book,
                                color: Color(0xFF007AFF),
                                size: 22,
                              ),
                              onPressed: _pickContact,
                              splashRadius: 20,
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
                        Switch.adaptive(
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
    );
  }
}