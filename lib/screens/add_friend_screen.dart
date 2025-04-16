// screens/add_friend_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.friend == null ? 'Add Friend' : 'Edit Friend',
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
            size: 28, // Matching home screen icon size
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add Save button to app bar for both add and edit modes
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                Icons.check,
                color: AppConstants.primaryColor,
                size: 30, // Matching home screen plus icon size
              ),
              tooltip: 'Save',
              onPressed: _saveFriend,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20), // Consistent with home screen
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
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color: _isEmoji ? AppConstants.profileCircleColor : null,
                            shape: BoxShape.circle,
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
                              style: const TextStyle(fontSize: 64),
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _showProfileOptions,
                        icon: Icon(Icons.edit, color: AppConstants.primaryColor, size: 24),
                        label: Text(
                            'Change Profile',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            )
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Increase spacing here
                const SizedBox(height: 32),

                // Form fields
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: AppConstants.primaryColor, size: 24),
                    // Add more padding inside the text field
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    labelStyle: TextStyle(
                      fontSize: 17,
                      color: AppConstants.secondaryTextColor,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                  style: TextStyle(
                    fontSize: 17,
                    color: AppConstants.primaryTextColor,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),

                // Increase spacing between fields
                const SizedBox(height: 20),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone, color: AppConstants.primaryColor, size: 24),
                    hintText: 'Enter phone number to text/call',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    labelStyle: TextStyle(
                      fontSize: 17,
                      color: AppConstants.secondaryTextColor,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppConstants.secondaryTextColor.withOpacity(0.7),
                    ),
                  ),
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
                  style: TextStyle(
                    fontSize: 17,
                    color: AppConstants.primaryTextColor,
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _helpingThemWithController,
                  decoration: InputDecoration(
                    labelText: 'What are you alongside them in?',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.support, color: AppConstants.primaryColor, size: 24),
                    hintText: 'e.g., "Accountability for exercise"',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    labelStyle: TextStyle(
                      fontSize: 17,
                      color: AppConstants.secondaryTextColor,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppConstants.secondaryTextColor.withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    color: AppConstants.primaryTextColor,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _helpingYouWithController,
                  decoration: InputDecoration(
                    labelText: 'What are they alongside you in?',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.support_agent, color: AppConstants.primaryColor, size: 24),
                    hintText: 'e.g., "Prayer for family issues"',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    labelStyle: TextStyle(
                      fontSize: 17,
                      color: AppConstants.secondaryTextColor,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppConstants.secondaryTextColor.withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    color: AppConstants.primaryTextColor,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),

                // Increase spacing before notification section
                const SizedBox(height: 32),

                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: AppConstants.notificationSettingsColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppConstants.borderColor),
                  ),
                  child: Padding(
                    // Add more padding inside the card
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Settings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          value: _reminderDays,
                          decoration: InputDecoration(
                            labelText: 'Check-in Reminder',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notifications, color: AppConstants.primaryColor, size: 24),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            labelStyle: TextStyle(
                              fontSize: 17,
                              color: AppConstants.secondaryTextColor,
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
                                style: TextStyle(
                                  fontSize: 17,
                                  color: AppConstants.primaryTextColor,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _reminderDays = value ?? 0;
                            });
                          },
                          style: TextStyle(
                            fontSize: 17,
                            color: AppConstants.primaryTextColor,
                          ),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                        ),

                        // Only show time picker if reminders are enabled
                        if (_reminderDays > 0) ...[
                          const SizedBox(height: 20),
                          // Time picker field
                          InkWell(
                            onTap: _showTimePicker,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Reminder Time',
                                prefixIcon: Icon(Icons.access_time, color: AppConstants.primaryColor, size: 24),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                labelStyle: TextStyle(
                                  fontSize: 17,
                                  color: AppConstants.secondaryTextColor,
                                ),
                              ),
                              child: Text(
                                _formatTimeOfDay(_reminderTime),
                                style: TextStyle(
                                  fontSize: 17,
                                  color: AppConstants.primaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: Text(
                            'Show in notification area',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'Keep a quick access notification for this friend',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppConstants.secondaryTextColor,
                              height: 1.4,
                            ),
                          ),
                          value: _hasPersistentNotification,
                          onChanged: (value) {
                            setState(() {
                              _hasPersistentNotification = value;
                            });
                          },
                          activeColor: AppConstants.primaryColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add delete button for edit mode only
                if (widget.friend != null) ...[
                  const SizedBox(height: 40),

                  // Delete button styled similar to Message/Call buttons
                  Material(
                    color: AppConstants.deleteColor.withOpacity(0.12), // Use delete color with opacity
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _confirmDelete,
                      borderRadius: BorderRadius.circular(8),
                      splashColor: AppConstants.deleteColor.withOpacity(0.2),
                      highlightColor: AppConstants.deleteColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete,
                              size: 22, // Slightly larger to match home screen
                              color: AppConstants.deleteColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remove Friend',
                              style: TextStyle(
                                color: AppConstants.deleteColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Add bottom padding for when scrolling all the way down
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format TimeOfDay to display in a readable format
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

  void _showTimePicker() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppConstants.primaryTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _reminderTime) {
      setState(() {
        _reminderTime = pickedTime;
      });
    }
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 16),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppConstants.bottomSheetHandleColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.emoji_emotions, color: AppConstants.primaryColor, size: 24),
                    title: Text(
                      'Choose Emoji',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppConstants.primaryTextColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () {
                      Navigator.pop(context);
                      _showEmojiPicker();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.photo_library, color: AppConstants.primaryColor, size: 24),
                    title: Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppConstants.primaryTextColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
                const SizedBox(height: 16),
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
        return AlertDialog(
          title: Text(
            'Choose an Emoji',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(24),
          backgroundColor: AppConstants.dialogBackgroundColor,
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
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
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.emojiPickerColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        reminderTime: _timeOfDayToString(_reminderTime),  // Convert TimeOfDay to string format
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
              style: TextStyle(fontSize: 16),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      } else {
        Provider.of<FriendsProvider>(context, listen: false).updateFriend(friend);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Changes saved for $name',
              style: TextStyle(fontSize: 16),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Remove Friend',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          backgroundColor: AppConstants.dialogBackgroundColor,
          content: Text(
            'Are you sure you want to remove ${widget.friend?.name} from your Alongside friends?',
            style: TextStyle(
              fontSize: 17,
              color: AppConstants.primaryTextColor,
              height: 1.5,
            ),
          ),
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
                      style: TextStyle(fontSize: 16),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              child: const Text('Remove'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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