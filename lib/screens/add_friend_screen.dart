// screens/add_friend_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // Updated import
import '../main.dart';
import '../models/friend.dart';
import '../utils/constants.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_contacts/contact.dart';

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

  // New method to pick a contact
  Future<void> _pickContact() async {
    // Request contacts permission
    if (await FlutterContacts.requestPermission()) {
      try {
        // Get all contacts (without thumbnails)
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        // Show contact selection dialog
        final contact = await showDialog<Contact>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select a contact'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(contacts[index].displayName),
                    onTap: () => Navigator.pop(context, contacts[index]),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        );

        if (contact != null && contact.phones.isNotEmpty) {
          setState(() {
            _nameController.text = contact.displayName;
            _phoneController.text = contact.phones.first.number;
          });
        } else if (contact != null) {
          _showErrorSnackBar('Selected contact has no phone number');
        }
      } catch (e) {
        _showErrorSnackBar('Error accessing contacts: $e');
      }
    } else {
      _showErrorSnackBar('Permission to access contacts was denied');
    }
  }
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.friend == null ? 'Add Friend' : 'Edit Friend',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add Save button to app bar for both add and edit modes
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _saveFriend,
              child: Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add top padding for breathing room
                const SizedBox(height: 16),

                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showProfileOptions,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _isEmoji ? AppConstants.profileCircleColor : null,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                            image: !_isEmoji
                                ? DecorationImage(
                              image: FileImage(File(_profileImage)),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: _isEmoji
                              ? Center(
                            child: Text(
                              _profileImage,
                              style: const TextStyle(fontSize: 50),
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _showProfileOptions,
                        icon: Icon(CupertinoIcons.camera, color: AppConstants.primaryColor, size: 18),
                        label: Text(
                          'Change Profile',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacing
                const SizedBox(height: 24),

                // Form fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field with modern iOS-style
                      _buildIOSStyleTextField(
                        controller: _nameController,
                        label: 'Name',
                        icon: CupertinoIcons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      // Phone field with contact picker
                      _buildIOSStyleTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: CupertinoIcons.phone,
                        hintText: 'Enter phone number to text/call',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a phone number';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: const Icon(CupertinoIcons.book, size: 22),
                          onPressed: _pickContact,
                          color: AppConstants.primaryColor,
                        ),
                      ),

                      _buildIOSStyleTextField(
                        controller: _helpingThemWithController,
                        label: 'What are you alongside them in?',
                        icon: CupertinoIcons.heart,
                        hintText: 'e.g., "Accountability for exercise"',
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      _buildIOSStyleTextField(
                        controller: _helpingYouWithController,
                        label: 'What are they alongside you in?',
                        icon: CupertinoIcons.person_2,
                        hintText: 'e.g., "Prayer for family issues"',
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      // Reduce spacing before notification section
                      const SizedBox(height: 24),

                      // iOS-style card for notification settings
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Notification Settings',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            // Reminder dropdown with iOS-style
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-in Reminder',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownButtonFormField<int>(
                                      value: _reminderDays,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                            CupertinoIcons.bell,
                                            color: AppConstants.primaryColor,
                                            size: 20
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 14
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: AppConstants.primaryColor,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      items: AppConstants.reminderOptions.map((days) {
                                        final label = days == 0
                                            ? 'No reminder'
                                            : days == 1
                                            ? 'Every day'
                                            : 'Every $days days';

                                        return DropdownMenuItem(
                                          value: days,
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _reminderDays = value ?? 0;
                                        });
                                      },
                                      icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                                      dropdownColor: Colors.white,
                                      isExpanded: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Only show time picker if reminders are enabled
                            if (_reminderDays > 0) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reminder Time',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: _showIOSTimePicker,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                          child: Row(
                                            children: [
                                              Icon(CupertinoIcons.clock, color: AppConstants.primaryColor, size: 20),
                                              const SizedBox(width: 12),
                                              Text(
                                                _formatTimeOfDay(_reminderTime),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const Spacer(),
                                              const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.black45),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Show in notification toggle with modern iOS switch style
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.rectangle_stack_badge_person_crop,
                                    size: 20,
                                    color: AppConstants.primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Show in notification area',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Keep a quick access notification for this friend',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            height: 1.3,
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
                                    activeColor: AppConstants.primaryColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      // Add delete button for edit mode only
                      if (widget.friend != null) ...[
                        const SizedBox(height: 24),

                        // Delete button styled like iOS
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _confirmDelete,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remove Friend',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Add bottom padding for when scrolling all the way down
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // iOS-style text field builder
  Widget _buildIOSStyleTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon, color: AppConstants.primaryColor, size: 20),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppConstants.primaryColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.black38,
              ),
            ),
            validator: validator,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // iOS-style time picker
  void _showIOSTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(color: AppConstants.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                      2023, 1, 1, _reminderTime.hour, _reminderTime.minute),
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      _reminderTime = TimeOfDay(
                        hour: newDateTime.hour,
                        minute: newDateTime.minute,
                      );
                    });
                  },
                  use24hFormat: false,
                  minuteInterval: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Format TimeOfDay to display in a readable format with iOS style
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;
    final period = time.hour < 12 ? 'AM' : 'PM';
    final minute = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    return '$hour:$minute $period';
  }

  // Convert TimeOfDay to string format for storage (24-hour format)
  String _timeOfDayToString(TimeOfDay time) {
    final hour = time.hour < 10 ? '0${time.hour}' : '${time.hour}';
    final minute = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    return '$hour:$minute';
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // iOS-style option list
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.pop(context);
                    _showEmojiPicker();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.smiley,
                          color: AppConstants.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Choose Emoji',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 60),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.photo,
                          color: AppConstants.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Choose from Gallery',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    const emojis = AppConstants.profileEmojis;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose an Emoji',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const Divider(height: 1),
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _profileImage = emojis[index];
                          _isEmoji = true;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 1),
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppConstants.primaryColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Save the image to the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy(
        '${directory.path}/$fileName',
      );

      setState(() {
        _profileImage = savedImage.path;
        _isEmoji = false;
      });
    }
  }

  void _saveFriend() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final phoneNumber = _phoneController.text.trim();

      final friend = Friend(
        id: widget.friend?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phoneNumber: phoneNumber,
        profileImage: _profileImage,
        isEmoji: _isEmoji,
        reminderDays: _reminderDays,
        reminderTime: _timeOfDayToString(_reminderTime),
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
      );

      if (widget.friend == null) {
        Provider.of<FriendsProvider>(context, listen: false).addFriend(friend);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name added as a friend',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppConstants.primaryColor,
            behavior: SnackBarBehavior.floating,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      } else {
        Provider.of<FriendsProvider>(context, listen: false).updateFriend(friend);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Changes saved for $name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: AppConstants.primaryColor,
            behavior: SnackBarBehavior.floating,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Remove Friend'),
          content: Text(
            'Are you sure you want to remove ${widget.friend?.name} from your Alongside friends?',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Provider.of<FriendsProvider>(
                  context,
                  listen: false,
                ).removeFriend(widget.friend!.id);
                Navigator.pop(context); // Return to home screen

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${widget.friend?.name} removed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppConstants.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                );
              },
              isDestructiveAction: true,
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _helpingThemWithController.dispose();
    _helpingYouWithController.dispose();
    super.dispose();
  }
}