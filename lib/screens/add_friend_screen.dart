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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add Save button to app bar for both add and edit modes
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
              tooltip: 'Save',
              onPressed: _saveFriend,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        icon: Icon(Icons.edit, color: AppConstants.primaryColor, size: 20),
                        label: Text(
                            'Change Profile',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )
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
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person, color: AppConstants.primaryColor, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    labelStyle: TextStyle(
                      fontSize: 15,
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
                    fontSize: 15,
                    color: AppConstants.primaryTextColor,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),

                // Reduce spacing between fields
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone, color: AppConstants.primaryColor, size: 20),
                    hintText: 'Enter phone number to text/call',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    labelStyle: TextStyle(
                      fontSize: 15,
                      color: AppConstants.secondaryTextColor,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
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
                    fontSize: 15,
                    color: AppConstants.primaryTextColor,
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _helpingThemWithController,
                  decoration: InputDecoration(
                    labelText: 'What are you alongside them in?',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.support, color: AppConstants.primaryColor, size: 20),
                    hintText: 'e.g., "Accountability for exercise"',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    labelStyle: TextStyle(
                      fontSize: 15,
                      color: AppConstants.secondaryTextColor,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppConstants.secondaryTextColor.withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppConstants.primaryTextColor,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _helpingYouWithController,
                  decoration: InputDecoration(
                    labelText: 'What are they alongside you in?',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.support_agent, color: AppConstants.primaryColor, size: 20),
                    hintText: 'e.g., "Prayer for family issues"',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    labelStyle: TextStyle(
                      fontSize: 15,
                      color: AppConstants.secondaryTextColor,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppConstants.secondaryTextColor.withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppConstants.primaryTextColor,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),

                // Reduce spacing before notification section
                const SizedBox(height: 24),

                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: AppConstants.notificationSettingsColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppConstants.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Settings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          value: _reminderDays,
                          decoration: InputDecoration(
                            labelText: 'Check-in Reminder',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notifications, color: AppConstants.primaryColor, size: 20),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                            labelStyle: TextStyle(
                              fontSize: 15,
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
                                  fontSize: 15,
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
                            fontSize: 15,
                            color: AppConstants.primaryTextColor,
                          ),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                        ),

                        // Only show time picker if reminders are enabled
                        if (_reminderDays > 0) ...[
                          const SizedBox(height: 14),
                          // Time picker field
                          InkWell(
                            onTap: _showTimePicker,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Reminder Time',
                                prefixIcon: Icon(Icons.access_time, color: AppConstants.primaryColor, size: 20),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                                labelStyle: TextStyle(
                                  fontSize: 15,
                                  color: AppConstants.secondaryTextColor,
                                ),
                              ),
                              child: Text(
                                _formatTimeOfDay(_reminderTime),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppConstants.primaryTextColor,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        SwitchListTile(
                          title: Text(
                            'Show in notification area',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'Keep a quick access notification for this friend',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppConstants.secondaryTextColor,
                              height: 1.3,
                            ),
                          ),
                          value: _hasPersistentNotification,
                          onChanged: (value) {
                            setState(() {
                              _hasPersistentNotification = value;
                            });
                          },
                          activeColor: AppConstants.primaryColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add delete button for edit mode only
                if (widget.friend != null) ...[
                  const SizedBox(height: 28),

                  // Delete button styled similar to Message/Call buttons
                  Material(
                    color: AppConstants.deleteColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _confirmDelete,
                      borderRadius: BorderRadius.circular(8),
                      splashColor: AppConstants.deleteColor.withOpacity(0.2),
                      highlightColor: AppConstants.deleteColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: AppConstants.deleteColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remove Friend',
                              style: TextStyle(
                                color: AppConstants.deleteColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Add bottom padding for when scrolling all the way down
                const SizedBox(height: 20),
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              // Use the Google Clock colors
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppConstants.primaryTextColor,
              surface: Colors.white,
            ),
            // Dialog background
            dialogBackgroundColor: Colors.white,
            // Button styles
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Time picker theme
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodColor: Colors.grey.shade200,
              dayPeriodTextColor: AppConstants.primaryTextColor,
              dayPeriodBorderSide: BorderSide.none,
              hourMinuteColor: MaterialStateColor.resolveWith((states) =>
              states.contains(MaterialState.selected)
                  ? AppConstants.primaryColor
                  : Colors.grey.shade200
              ),
              hourMinuteTextColor: MaterialStateColor.resolveWith((states) =>
              states.contains(MaterialState.selected)
                  ? Colors.white
                  : AppConstants.primaryTextColor
              ),
              dialHandColor: AppConstants.primaryColor,
              dialBackgroundColor: Colors.grey.shade200,
              hourMinuteTextStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              dayPeriodTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              helpTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppConstants.secondaryTextColor,
              ),
              dialTextColor: MaterialStateColor.resolveWith((states) =>
              states.contains(MaterialState.selected)
                  ? Colors.white
                  : AppConstants.primaryTextColor
              ),
              entryModeIconColor: AppConstants.primaryColor,
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
      backgroundColor: const Color(AppConstants.backgroundColorValue),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.bottomSheetHandleColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Reduced vertical spacing between options
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: Icon(Icons.emoji_emotions, color: AppConstants.primaryColor, size: 22),
                    title: Text(
                      'Choose Emoji',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppConstants.primaryTextColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onTap: () {
                      Navigator.pop(context);
                      _showEmojiPicker();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ListTile(
                    leading: Icon(Icons.photo_library, color: AppConstants.primaryColor, size: 22),
                    title: Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppConstants.primaryTextColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
                const SizedBox(height: 12),
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
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.all(20),
          backgroundColor: AppConstants.dialogBackgroundColor,
          content: SizedBox(
            width: double.maxFinite,
            height: 260,
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
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppConstants.emojiPickerColor,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: TextStyle(
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
              style: TextStyle(
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Remove Friend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          backgroundColor: AppConstants.dialogBackgroundColor,
          content: Text(
            'Are you sure you want to remove ${widget.friend?.name} from your Alongside friends?',
            style: TextStyle(
              fontSize: 15,
              color: AppConstants.primaryTextColor,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(14),
                foregroundColor: AppConstants.primaryColor,
                textStyle: const TextStyle(
                  fontSize: 15,
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
                      style: TextStyle(
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
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.deleteColor,
                padding: const EdgeInsets.all(14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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