// screens/add_friend_screen.dart
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
    // Use Cupertino-style toast or alert instead of Material SnackBar
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
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.friend == null ? 'Add Friend' : 'Edit Friend',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
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
        backgroundColor: CupertinoColors.white,
        border: null,
      ),
      child: SafeArea(
        child: Form(
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
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      onPressed: _showProfileOptions,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.camera, color: AppConstants.primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Change Profile',
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // iOS-style grouped sections
              _buildFormSection(
                children: [
                  _buildIOSTextField(
                    controller: _nameController,
                    label: 'Name',
                    placeholder: 'Enter name',
                    icon: CupertinoIcons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  _buildIOSDivider(),
                  _buildIOSTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    placeholder: 'Enter phone number',
                    icon: CupertinoIcons.phone,
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
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.book,
                        color: AppConstants.primaryColor,
                        size: 22,
                      ),
                      onPressed: _pickContact,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildFormSection(
                children: [
                  _buildIOSTextField(
                    controller: _helpingThemWithController,
                    label: 'What are you alongside them in?',
                    placeholder: 'e.g., "Accountability for exercise"',
                    icon: CupertinoIcons.heart,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  _buildIOSDivider(),
                  _buildIOSTextField(
                    controller: _helpingYouWithController,
                    label: 'What are they alongside you in?',
                    placeholder: 'e.g., "Prayer for family issues"',
                    icon: CupertinoIcons.person_2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notification settings section
              _buildFormSection(
                header: 'NOTIFICATION SETTINGS',
                children: [
                  _buildReminderSelector(),

                  if (_reminderDays > 0) ...[
                    _buildIOSDivider(),
                    _buildTimeSelector(),
                  ],

                  _buildIOSDivider(),
                  _buildToggleRow(
                    icon: CupertinoIcons.rectangle_stack_badge_person_crop,
                    title: 'Show in notification area',
                    subtitle: 'Keep a quick access notification for this friend',
                    value: _hasPersistentNotification,
                    onChanged: (value) {
                      setState(() {
                        _hasPersistentNotification = value;
                      });
                    },
                  ),
                ],
              ),

              // Delete button for edit mode
              if (widget.friend != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    onPressed: _confirmDelete,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.delete,
                          size: 18,
                          color: CupertinoColors.systemRed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remove Friend',
                          style: TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({String? header, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Text(
              header,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(10),
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
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildIOSTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? placeholder,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  placeholderStyle: TextStyle(
                    color: CupertinoColors.systemGrey.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.white,
                    border: Border(), // No border - iOS style
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.black,
                  ),
                  suffix: suffix,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 48),
      height: 0.5,
      color: CupertinoColors.systemGrey4,
    );
  }

  Widget _buildReminderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.bell,
            color: AppConstants.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check-in Reminder',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
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
                          fontSize: 15,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground,
                  border: Border(
                    bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: AppConstants.reminderOptions.indexOf(_reminderDays),
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _reminderDays = AppConstants.reminderOptions[index];
                    });
                  },
                  children: AppConstants.reminderOptions.map((days) {
                    final label = days == 0
                        ? 'No reminder'
                        : days == 1
                        ? 'Every day'
                        : 'Every $days days';
                    return Center(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.clock,
            color: AppConstants.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder Time',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _showIOSTimePicker,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeOfDay(_reminderTime),
                        style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        size: 16,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showIOSTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground,
                  border: Border(
                    bottom: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2023, 1, 1, _reminderTime.hour, _reminderTime.minute,
                  ),
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Profile Picture Options'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showEmojiPicker();
              },
              child: const Text('Choose Emoji'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage();
              },
              child: const Text('Choose from Gallery'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    const emojis = AppConstants.profileEmojis;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Choose an Emoji'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _profileImage = emojis[index];
                    _isEmoji = true;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
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
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text('Cancel'),
          ),
        ],
      ),
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
    // Validate fields
    bool isValid = true;

    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a name');
      isValid = false;
    } else if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a phone number');
      isValid = false;
    } else if (!_phoneController.text.contains(RegExp(r'[0-9]'))) {
      _showErrorSnackBar('Please enter a valid phone number');
      isValid = false;
    }

    if (isValid) {
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

        // Show success alert with iOS style
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('$name Added'),
            content: Text('$name has been added as a friend.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        Provider.of<FriendsProvider>(context, listen: false).updateFriend(friend);

        // Show a toast for iOS (Cupertino doesn't have a built-in toast)
        // Using dialog instead
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Changes Saved'),
            content: Text('Your changes for $name have been saved.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _confirmDelete() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Remove Friend'),
          content: Text(
            'Are you sure you want to remove ${widget.friend?.name} from your Alongside friends?',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Provider.of<FriendsProvider>(
                  context,
                  listen: false,
                ).removeFriend(widget.friend!.id);

                // Show a quick toast for feedback
                showCupertinoDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text('Friend Removed'),
                    content: Text('${widget.friend?.name} has been removed.'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              isDestructiveAction: true,
              child: const Text('Remove'),
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