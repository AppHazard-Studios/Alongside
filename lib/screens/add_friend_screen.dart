// lib/screens/add_friend_screen.dart - FIXED SCALING, ALIGNMENT & OVERFLOW ISSUES
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
import '../utils/text_styles.dart';
import '../widgets/no_underline_field.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/day_selector_widget.dart';
import '../models/day_selection_data.dart';

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

  String _profileImage = '😊';
  bool _isEmoji = true;
  int _reminderDays = 0;
  bool _hasPersistentNotification = false;
  DaySelectionData? _daySelectionData;

  String _reminderTimeStr = "09:00";

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

      if (widget.friend!.reminderData != null && widget.friend!.reminderData!.isNotEmpty) {
        try {
          _daySelectionData = DaySelectionData.fromJson(widget.friend!.reminderData!);
        } catch (e) {
          print("Error loading day selection data: $e");
          _daySelectionData = null;
        }
      }
    } else {
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
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.primary,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Text(
            'Would you like to select a friend from your contacts?',
            style: AppTextStyles.scaledBody(context),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _pickContact();
            },
            isDefaultAction: true,
            child: Text(
              'Yes',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
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
          style: AppTextStyles.scaledCallout(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: Text(
          'This contact has multiple phone numbers. Which one would you like to use?',
          style: AppTextStyles.scaledCaption(context).copyWith(
            color: AppColors.textSecondary,
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
                  style: AppTextStyles.scaledCallout(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (labelText.isNotEmpty)
                  Text(
                    labelText,
                    style: AppTextStyles.scaledFootnote(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: Text(
            'Cancel',
            style: AppTextStyles.scaledButton(context).copyWith(
              color: AppColors.error,
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
        title: Text(
          'Error',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.error,
          ),
        ),
        content: Text(
          message,
          style: AppTextStyles.scaledBody(context),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
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
          style: AppTextStyles.scaledHeadline(context).copyWith(
            color: AppColors.primary,
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
              style: AppTextStyles.scaledHeadline(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.camera);
            },
            child: Text(
              'Take Photo',
              style: AppTextStyles.scaledCallout(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.gallery);
            },
            child: Text(
              'Choose from Library',
              style: AppTextStyles.scaledCallout(context).copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: Text(
            'Cancel',
            style: AppTextStyles.scaledButton(context).copyWith(
              color: AppColors.error,
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
              title: Text(
                'Camera Permission Required',
                style: AppTextStyles.scaledDialogTitle(context).copyWith(
                  color: AppColors.primary,
                ),
              ),
              content: Padding(
                padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
                child: Text(
                  'Camera access is permanently denied. Please enable it in Settings to take photos.',
                  style: AppTextStyles.scaledBody(context),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text(
                    'Open Settings',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.primary,
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
        padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: ResponsiveUtils.scaledSpacing(context, 16)),
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
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Choose Emoji',
                  style: AppTextStyles.scaledHeadline(context).copyWith(
                    color: AppColors.primary,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Done',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.scaledSpacing(context, 16)),
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
                          // 🔧 FIXED: Proper emoji scaling like home screen
                          style: TextStyle(
                            fontSize: ResponsiveUtils.scaledFontSize(
                              context,
                              28,
                              maxScale: 1.15, // Cap at 32px (28 * 1.15)
                            ),
                          ),
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
        title: Text(
          'Invite Friend',
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.primary,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 16)),
          child: Text(
            'Would you like to invite ${friend.name} to use Alongside with you?',
            style: AppTextStyles.scaledBody(context),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Not Now',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
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
            child: Text(
              'Send Invite',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.primary,
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
          style: AppTextStyles.scaledDialogTitle(context).copyWith(
            color: AppColors.error,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
          child: Text(
            'Are you sure you want to remove ${widget.friend!.name}? This action cannot be undone.',
            style: AppTextStyles.scaledBody(context),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: Text(
              'Cancel',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.secondary,
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
            child: Text(
              'Remove',
              style: AppTextStyles.scaledButton(context).copyWith(
                color: AppColors.error,
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
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        bottom: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 🔧 FIXED: Header like home screen with proper icon
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
                    // Title with icon - like home screen
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title with overflow protection
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.friend == null ? 'Add Friend' : 'Edit Friend',
                                style: AppTextStyles.scaledAppTitle(context),
                                maxLines: 1,
                              ),
                            ),
                          ),

                          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

                          // 🔧 FIXED: Added icon like home screen
                          Container(
                            width: ResponsiveUtils.scaledContainerSize(context, 28),
                            height: ResponsiveUtils.scaledContainerSize(context, 28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.friend == null
                                  ? CupertinoIcons.person_add_solid
                                  : CupertinoIcons.person_crop_circle_badge_checkmark,
                              size: ResponsiveUtils.scaledIconSize(context, 16),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fixed spacing between title and buttons
                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 16)),

                    // Button area - fixed size to prevent overflow
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // X button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Container(
                            width: ResponsiveUtils.scaledContainerSize(context, 32),
                            height: ResponsiveUtils.scaledContainerSize(context, 32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
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
                              CupertinoIcons.xmark,
                              size: ResponsiveUtils.scaledIconSize(context, 16),
                              color: AppColors.primary,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),

                        SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

                        // Save button - responsive width
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _saveFriend,
                          child: Container(
                            height: ResponsiveUtils.scaledContainerSize(context, 32),
                            constraints: BoxConstraints(
                              // 🔧 FIXED: Responsive width limits to prevent overflow
                              minWidth: ResponsiveUtils.scaledContainerSize(context, 60),
                              maxWidth: ResponsiveUtils.scaledContainerSize(context, 80),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.scaledSpacing(context, 12),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Save',
                                  style: AppTextStyles.scaledButton(context).copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                ),
                child: Column(
                  children: [
                    // Profile image section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showProfileOptions,
                            child: Container(
                              width: ResponsiveUtils.scaledContainerSize(context, 80),
                              height: ResponsiveUtils.scaledContainerSize(context, 80),
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
                                  // 🔧 FIXED: Proper emoji scaling like home screen
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.scaledFontSize(
                                      context,
                                      40,
                                      maxScale: 1.15, // Cap at 46px (40 * 1.15)
                                    ),
                                  ),
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
                          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _showProfileOptions,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.scaledSpacing(context, 12),
                                vertical: ResponsiveUtils.scaledSpacing(context, 6),
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
                                    // 🔧 FIXED: Proper icon scaling
                                    size: ResponsiveUtils.scaledIconSize(context, 14),
                                  ),
                                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 6)),
                                  Text(
                                    'Change Profile',
                                    style: AppTextStyles.scaledSubhead(context).copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

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
                          iconColor: AppColors.primary,
                          child: NoUnderlineField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            placeholder: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),

                    // Alongside info section
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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

                    // Day selector
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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

                    // Notification settings section
                    _buildSectionHeader('NOTIFICATION SETTINGS'),

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

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),

                    // Delete button for existing friends
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
                            vertical: ResponsiveUtils.scaledSpacing(context, 12),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => _showDeleteConfirmation(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.delete,
                                color: AppColors.error,
                                size: ResponsiveUtils.scaledIconSize(context, 16),
                              ),
                              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                              Text(
                                'Remove Friend',
                                style: AppTextStyles.scaledCallout(context).copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 🔧 FIXED: Proper bottom spacing to prevent overflow
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
          style: AppTextStyles.scaledSectionHeader(context),
        ),
      ),
    );
  }

  Widget _buildFormRow({
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 16),
        vertical: ResponsiveUtils.scaledSpacing(context, 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.scaledSpacing(context, 2),
            ),
            child: Container(
              width: ResponsiveUtils.scaledContainerSize(context, 32),
              height: ResponsiveUtils.scaledContainerSize(context, 32),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveUtils.scaledIconSize(context, 16),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.15),
      margin: EdgeInsets.zero,
    );
  }

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
          vertical: ResponsiveUtils.scaledSpacing(context, 8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveUtils.scaledContainerSize(context, 32),
              height: ResponsiveUtils.scaledContainerSize(context, 32),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: ResponsiveUtils.scaledIconSize(context, 16),
              ),
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.scaledBody(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.scaledSubhead(context).copyWith(
                      color: AppColors.textSecondary,
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
}

// Contact picker component with consistent scaling
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
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.scaledButton(context).copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Select Contact',
                      style: AppTextStyles.scaledHeadline(context).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.scaledContainerSize(context, 60)),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.scaledSpacing(context, 16)),
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
                  padding: EdgeInsets.only(left: ResponsiveUtils.scaledSpacing(context, 12)),
                  child: Icon(
                    CupertinoIcons.search,
                    color: AppColors.primary,
                    size: ResponsiveUtils.scaledIconSize(context, 16),
                  ),
                ),
                suffix: _searchController.text.isNotEmpty
                    ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => _searchController.clear(),
                  child: Padding(
                    padding: EdgeInsets.only(right: ResponsiveUtils.scaledSpacing(context, 12)),
                    child: Icon(
                      CupertinoIcons.clear_circled,
                      color: AppColors.textSecondary,
                      size: ResponsiveUtils.scaledIconSize(context, 16),
                    ),
                  ),
                )
                    : null,
                style: AppTextStyles.scaledCallout(context).copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: null,
                padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.scaledSpacing(context, 12),
                    horizontal: ResponsiveUtils.scaledSpacing(context, 4)
                ),
                placeholderStyle: AppTextStyles.scaledBody(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),

          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_3,
                    size: ResponsiveUtils.scaledIconSize(context, 40),
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
                  Text(
                    'No contacts found',
                    style: AppTextStyles.scaledCallout(context).copyWith(
                      color: AppColors.textSecondary,
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
                    margin: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                        vertical: ResponsiveUtils.scaledSpacing(context, 2)
                    ),
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
                        style: AppTextStyles.scaledBody(context).copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: contact.phones.isNotEmpty
                          ? Text(
                        contact.phones.length == 1
                            ? '${contact.phones.first.number}${_getPhoneLabel(contact.phones.first).isNotEmpty ? ' (${_getPhoneLabel(contact.phones.first)})' : ''}'
                            : '${contact.phones.length} phone numbers',
                        style: AppTextStyles.scaledCaption(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                          : Text(
                        'No phone number',
                        style: AppTextStyles.scaledCaption(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      leading: Container(
                        width: ResponsiveUtils.scaledContainerSize(context, 36),
                        height: ResponsiveUtils.scaledContainerSize(context, 36),
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
                                size: ResponsiveUtils.scaledIconSize(context, 18),
                              );
                            },
                          ),
                        )
                            : Icon(
                          CupertinoIcons.person,
                          color: AppColors.primary,
                          size: ResponsiveUtils.scaledIconSize(context, 18),
                        ),
                      ),
                      trailing: contact.phones.isNotEmpty
                          ? Icon(
                        CupertinoIcons.chevron_right,
                        color: AppColors.textSecondary,
                        size: ResponsiveUtils.scaledIconSize(context, 14),
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