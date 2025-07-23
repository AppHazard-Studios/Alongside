// lib/screens/add_friend_screen.dart - UPDATED TO MATCH HOME/SETTINGS DESIGN
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/friends_provider.dart';
import '../models/friend.dart';
import '../utils/constants.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';
import '../widgets/no_underline_field.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/day_selector_widget.dart';
import '../models/day_selection_data.dart';
import '../utils/text_styles.dart';

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
  DaySelectionData? _daySelectionData;

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

      // Load day selection data
      if (widget.friend!.reminderData != null && widget.friend!.reminderData!.isNotEmpty) {
        try {
          _daySelectionData = DaySelectionData.fromJson(widget.friend!.reminderData!);
        } catch (e) {
          print("Error loading day selection data: $e");
          _daySelectionData = null;
        }
      }
    } else {
      // Show contact picker prompt for new friends
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showContactPickerPrompt();
      });
    }
  }

  void _showContactPickerPrompt() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Add from Contacts?',
          style: AppTextStyles.dialogTitle.copyWith(
            color: AppColors.primary,
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Would you like to select a friend from your contacts?',
            style: TextStyle(
              fontSize: 17, // iOS body size
              height: 1.4,
              color: AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _pickContact();
            },
            isDefaultAction: true,
            child: const Text(
              'Yes',
              style: TextStyle(
                color: AppColors.primary,
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _helpingThemWithController.dispose();
    _helpingYouWithController.dispose();
    super.dispose();
  }

  // Enhanced method to pick a contact with search and multiple number handling
  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      try {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
        );

        if (!mounted) return;

        showCupertinoModalPopup(
          context: context,
          builder: (context) => _ContactPickerWithSearch(
            contacts: contacts,
            onContactSelected: (contact) async {
              if (contact.phones.isEmpty) {
                _showErrorSnackBar('Selected contact has no phone number');
                return;
              }

              setState(() {
                _nameController.text = contact.displayName;
              });

              if (contact.photo != null && contact.photo!.isNotEmpty) {
                try {
                  final Directory docDir = await getApplicationDocumentsDirectory();
                  final String imagePath = '${docDir.path}/contact_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  final File imageFile = File(imagePath);
                  await imageFile.writeAsBytes(contact.photo!);

                  setState(() {
                    _profileImage = imagePath;
                    _isEmoji = false;
                  });
                } catch (e) {
                  print('Error saving contact photo: $e');
                }
              }

              if (contact.phones.length == 1) {
                setState(() {
                  _phoneController.text = contact.phones.first.number;
                });
              } else {
                _showPhoneNumberSelector(contact);
              }
            },
          ),
        );
      } catch (e) {
        _showErrorSnackBar('Error accessing contacts: $e');
      }
    } else {
      _showErrorSnackBar('Permission to access contacts was denied');
    }
  }

  void _showPhoneNumberSelector(Contact contact) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Choose Phone Number for ${contact.displayName}',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        message: const Text(
          'This contact has multiple phone numbers. Which one would you like to use?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: contact.phones.map((phone) {
          String labelText = '';

          switch (phone.label) {
            case PhoneLabel.mobile:
              labelText = 'Mobile';
              break;
            case PhoneLabel.home:
              labelText = 'Home';
              break;
            case PhoneLabel.work:
              labelText = 'Work';
              break;
            case PhoneLabel.main:
              labelText = 'Main';
              break;
            case PhoneLabel.faxWork:
              labelText = 'Work Fax';
              break;
            case PhoneLabel.faxHome:
              labelText = 'Home Fax';
              break;
            case PhoneLabel.pager:
              labelText = 'Pager';
              break;
            case PhoneLabel.other:
              labelText = 'Other';
              break;
            case PhoneLabel.custom:
              labelText = phone.customLabel.isNotEmpty ? phone.customLabel : 'Custom';
              break;
            default:
              labelText = '';
              break;
          }

          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _phoneController.text = phone.number;
              });
            },
            child: Column(
              children: [
                Text(
                  phone.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                if (labelText.isNotEmpty)
                  Text(
                    labelText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textPrimary,
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
                color: AppColors.primary,
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
        title: Text(
          'Choose Profile Image',
          style: TextStyle(
            color: AppColors.primary,
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
            child: Text(
              'Choose Emoji',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
                color: AppColors.primary,
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
                color: AppColors.primary,
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
              color: AppColors.error,
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
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.status;

        if (cameraStatus.isDenied) {
          final result = await Permission.camera.request();
          if (result.isDenied) {
            _showErrorSnackBar('Camera permission is required to take photos');
            return;
          }
        }

        if (cameraStatus.isPermanentlyDenied) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text(
                'Camera Permission Required',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  fontFamily: '.SF Pro Text',
                ),
              ),
              content: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Camera access is permanently denied. Please enable it in Settings to take photos.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ],
            ),
          );
          return;
        }
      }

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
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC), // Match home screen background
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.secondary,
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
                    color: AppColors.primary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primary,
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
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
    final isNewFriend = widget.friend == null;

    if (isNewFriend) {
      final newFriend = Friend(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImage: _profileImage,
        isEmoji: _isEmoji,
        reminderDays: _reminderDays,
        reminderTime: _reminderTimeStr,
        reminderData: _daySelectionData?.toJson(),
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
      );
      await provider.addFriend(newFriend);

      if (mounted) {
        Navigator.pop(context);
        _showInviteDialog(context, newFriend);
      }
    } else {
      final updatedFriend = widget.friend!.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImage: _profileImage,
        isEmoji: _isEmoji,
        reminderDays: _reminderDays,
        reminderTime: _reminderTimeStr,
        reminderData: _daySelectionData?.toJson(),
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
      );
      await provider.updateFriend(updatedFriend);

      if (mounted) Navigator.pop(context);
    }
  }

  void _showInviteDialog(BuildContext context, Friend friend) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Invite Friend',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Would you like to invite ${friend.name} to use Alongside with you?',
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AppColors.textPrimary,
              fontFamily: '.SF Pro Text',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Not Now',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);

              final message = 'Hey ${friend.name.split(' ')[0]}! I just added you to Alongside - '
                  'an app that helps us stay connected. '
                  'It reminds me to check in with you and makes it easy to send quick messages. '
                  'Would love if you joined too! Download at: alongside.app';

              final smsUri = Uri.parse('sms:${friend.phoneNumber}?body=${Uri.encodeComponent(message)}');

              try {
                await launchUrl(smsUri, mode: LaunchMode.externalApplication);
              } catch (e) {
                // Handle error silently
              }
            },
            child: const Text(
              'Send Invite',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Remove Friend',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.scaledFontSize(context, 17, maxScale: 1.1),
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
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);

              final provider = Provider.of<FriendsProvider>(context, listen: false);
              await provider.removeFriend(widget.friend!.id);

              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            isDestructiveAction: true,
            child: const Text(
              'Remove',
              style: TextStyle(
                color: AppColors.error,
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
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Match home screen background
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // INTEGRATED HEADER matching home/settings design
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 12),
                ),
                child: Row(
                  children: [
                    // Back button (rounded square like settings X button)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: ResponsiveUtils.scaledContainerSize(context, 36),
                        height: ResponsiveUtils.scaledContainerSize(context, 36),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.chevron_left,
                          size: ResponsiveUtils.scaledIconSize(context, 18),
                          color: AppColors.primary,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    const Spacer(),

                    // Title
                    Text(
                      widget.friend == null ? 'Add Friend' : 'Edit Friend',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.scaledFontSize(context, 17, maxScale: 1.15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),


                    const Spacer(),

                    // Save button (rounded square matching back button)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _saveFriend,
                      child: Container(
                        width: ResponsiveUtils.scaledContainerSize(context, 60),
                        height: ResponsiveUtils.scaledContainerSize(context, 36),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.scaledFontSize(context, 17, maxScale: 1.1),
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                ),
                child: Column(
                  children: [
                    // Profile image selection
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showProfileOptions,
                            child: Container(
                              width: ResponsiveUtils.scaledContainerSize(context, 100),
                              height: ResponsiveUtils.scaledContainerSize(context, 100),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isEmoji
                                  ? Center(
                                child: Text(
                                  _profileImage,
                                  style: TextStyle(fontSize: ResponsiveUtils.scaledFontSize(context, 50)),
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
                          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _showProfileOptions,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.scaledSpacing(context, 12),
                                vertical: ResponsiveUtils.scaledSpacing(context, 8),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.camera,
                                    color: AppColors.primary,
                                    size: ResponsiveUtils.scaledIconSize(context, 16),
                                  ),
                                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
                                  Text(
                                    'Change Profile',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: '.SF Pro Text',
                                      fontSize: ResponsiveUtils.scaledFontSize(context, 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

                    // Basic info section
                    _buildSection(
                      children: [
                        _buildFormRow(
                          icon: CupertinoIcons.person_fill,
                          iconColor: AppColors.primary,
                          child: NoUnderlineField(
                            controller: _nameController,
                            label: 'Name',
                            placeholder: 'Enter name',
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        _buildDivider(),
                        _buildFormRow(
                          icon: CupertinoIcons.phone_fill,
                          iconColor: AppColors.success,
                          child: NoUnderlineField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            placeholder: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

                    // "Alongside" information section
                    _buildSection(
                      children: [
                        _buildFormRow(
                          icon: CupertinoIcons.heart_fill,
                          iconColor: AppColors.primary,
                          child: NoUnderlineField(
                            controller: _helpingThemWithController,
                            label: 'What are you alongside them in?',
                            placeholder: 'e.g., "Accountability for exercise"',
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        _buildDivider(),
                        _buildFormRow(
                          icon: CupertinoIcons.person_2_fill,
                          iconColor: AppColors.primary,
                          child: NoUnderlineField(
                            controller: _helpingYouWithController,
                            label: 'What are they alongside you in?',
                            placeholder: 'e.g., "Prayer for family issues"',
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

                    // Day selector widget with integrated time picker
                    DaySelectorWidget(
                      initialData: _daySelectionData,
                      reminderTime: _reminderTimeStr,
                      onTimeChanged: (newTime) {
                        setState(() {
                          _reminderTimeStr = newTime;
                        });
                        print("🕐 Time updated to: $newTime");
                      },
                      onChanged: (daySelectionData) {
                        setState(() {
                          _daySelectionData = daySelectionData;
                          _reminderDays = 0;
                        });
                        print("📅 Day selection updated: ${daySelectionData?.getDescription()}");
                      },
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

                    // NOTIFICATION SETTINGS section header
                    _buildSectionHeader('NOTIFICATION SETTINGS'),

                    // Persistent notification setting
                    _buildSection(
                      children: [
                        _buildSwitchRow(
                          icon: CupertinoIcons.rectangle_stack_badge_person_crop,
                          iconColor: AppColors.primary,
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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

                    // Delete friend button (only when editing)
                    if (widget.friend != null)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveUtils.scaledSpacing(context, 16),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => _showDeleteConfirmation(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.delete,
                                color: AppColors.error,
                                size: ResponsiveUtils.scaledIconSize(context, 18),
                              ),
                              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                              Text(
                                'Remove Friend',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                                  fontFamily: '.SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build sections matching home/settings style
  Widget _buildSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Helper method for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveUtils.scaledSpacing(context, 8),
        bottom: ResponsiveUtils.scaledSpacing(context, 8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 13, maxScale: 1.2),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
    );
  }

  // Helper method for form rows with rounded square icons
  // FIXED: Helper method for form rows with proper iOS text alignment
  // FIXED: Proper iOS-style form row alignment
  Widget _buildFormRow({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 16),
        vertical: ResponsiveUtils.scaledSpacing(context, 12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top of content
        children: [
          // Icon container positioned to align with label text
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.scaledSpacing(context, 2), // Slight offset to align with label baseline
            ),
            child: Container(
              width: ResponsiveUtils.scaledContainerSize(context, 38),
              height: ResponsiveUtils.scaledContainerSize(context, 38),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10), // Rounded square like settings
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveUtils.scaledIconSize(context, 18),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
          // Field takes remaining space and handles its own internal layout
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  // FIXED: Consistent divider with proper opacity for visibility
  // FIXED: Consistent divider with proper opacity (matches add friend screen)
  Widget _buildDivider() {
    return Container(
      height: 0.5,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.15), // INCREASED opacity for better visibility
      margin: EdgeInsets.zero,
    );
  }

  // Helper method for switch rows
  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.scaledSpacing(context, 16),
          vertical: ResponsiveUtils.scaledSpacing(context, 12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveUtils.scaledContainerSize(context, 38),
              height: ResponsiveUtils.scaledContainerSize(context, 38),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10), // Rounded square like settings
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveUtils.scaledIconSize(context, 18),
              ),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: ResponsiveUtils.scaledFontSize(context, 17, maxScale: 1.2),
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15, // iOS subhead size
                      color: AppColors.textSecondary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for dividers matching settings style

}

// Contact picker widget with search functionality - Updated with new styling
class _ContactPickerWithSearch extends StatefulWidget {
  final List<Contact> contacts;
  final Function(Contact) onContactSelected;

  const _ContactPickerWithSearch({
    required this.contacts,
    required this.onContactSelected,
  });

  @override
  State<_ContactPickerWithSearch> createState() => _ContactPickerWithSearchState();
}

class _ContactPickerWithSearchState extends State<_ContactPickerWithSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts.where((contact) {
          return contact.displayName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String _getPhoneLabel(Phone phone) {
    switch (phone.label) {
      case PhoneLabel.mobile:
        return 'Mobile';
      case PhoneLabel.home:
        return 'Home';
      case PhoneLabel.work:
        return 'Work';
      case PhoneLabel.main:
        return 'Main';
      case PhoneLabel.faxWork:
        return 'Work Fax';
      case PhoneLabel.faxHome:
        return 'Home Fax';
      case PhoneLabel.pager:
        return 'Pager';
      case PhoneLabel.other:
        return 'Other';
      case PhoneLabel.custom:
        return phone.customLabel.isNotEmpty ? phone.customLabel : 'Custom';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Match home screen background
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Select Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search contacts...',
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    CupertinoIcons.search,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                suffix: _searchController.text.isNotEmpty
                    ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => _searchController.clear(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      CupertinoIcons.clear_circled,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                )
                    : null,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                  color: AppColors.textPrimary,
                ),
                decoration: null,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                placeholderStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 17, // iOS body size
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact list
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_3,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No contacts found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            )
                : CupertinoScrollbar(
              child: ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                    child: CupertinoListTile(
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontSize: 17, // iOS body size
                          fontFamily: '.SF Pro Text',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: contact.phones.isNotEmpty
                          ? Text(
                        contact.phones.length == 1
                            ? '${contact.phones.first.number}${_getPhoneLabel(contact.phones.first).isNotEmpty ? ' (${_getPhoneLabel(contact.phones.first)})' : ''}'
                            : '${contact.phones.length} phone numbers',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: '.SF Pro Text',
                        ),
                      )
                          : const Text(
                        'No phone number',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: contact.photo != null && contact.photo!.isNotEmpty
                              ? null
                              : AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: contact.photo != null && contact.photo!.isNotEmpty
                            ? ClipOval(
                          child: Image.memory(
                            contact.photo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                CupertinoIcons.person,
                                color: AppColors.primary,
                                size: 20,
                              );
                            },
                          ),
                        )
                            : Icon(
                          CupertinoIcons.person,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      trailing: contact.phones.isNotEmpty
                          ? Icon(
                        CupertinoIcons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 16,
                      )
                          : null,
                      onTap: contact.phones.isNotEmpty
                          ? () {
                        Navigator.pop(context);
                        widget.onContactSelected(contact);
                      }
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}