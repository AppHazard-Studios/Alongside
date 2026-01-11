// lib/screens/add_friend_screen.dart - FIXED SCALING, ALIGNMENT & OVERFLOW ISSUES
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
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';
import '../utils/text_styles.dart';
import '../widgets/no_underline_field.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/day_selector_widget.dart';
import '../models/day_selection_data.dart';
import 'package:flutter/services.dart';
import '../services/toast_service.dart';

// Contact display item with emoji fallback and progressive photo loading
class _ContactDisplayItem {
  final Contact contact;
  final String assignedEmoji;
  Uint8List? photo;

  _ContactDisplayItem({
    required this.contact,
    required this.assignedEmoji,
    this.photo,
  });
}

class AddFriendScreen extends StatefulWidget {
  final Friend? friend;

  const AddFriendScreen({Key? key, this.friend}) : super(key: key);

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _helpingThemWithController = TextEditingController();
  final _helpingYouWithController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  // NEW: Track if country code warning has been shown in this session
  bool _countryCodeWarningShown = false;

  // ... rest of state variables
  // Comprehensive country codes list - Top 40 countries
  final List<Map<String, String>> _countryCodes = [
    {'name': 'Australia', 'code': '+61'},
    {'name': 'United States', 'code': '+1'},
    {'name': 'United Kingdom', 'code': '+44'},
    {'name': 'Canada', 'code': '+1'},
    {'name': 'New Zealand', 'code': '+64'},
    {'name': 'India', 'code': '+91'},
    {'name': 'Philippines', 'code': '+63'},
    {'name': 'Singapore', 'code': '+65'},
    {'name': 'Malaysia', 'code': '+60'},
    {'name': 'Indonesia', 'code': '+62'},
    {'name': 'Hong Kong', 'code': '+852'},
    {'name': 'China', 'code': '+86'},
    {'name': 'Japan', 'code': '+81'},
    {'name': 'South Korea', 'code': '+82'},
    {'name': 'Vietnam', 'code': '+84'},
    {'name': 'Thailand', 'code': '+66'},
    {'name': 'Germany', 'code': '+49'},
    {'name': 'France', 'code': '+33'},
    {'name': 'Italy', 'code': '+39'},
    {'name': 'Spain', 'code': '+34'},
    {'name': 'Netherlands', 'code': '+31'},
    {'name': 'Belgium', 'code': '+32'},
    {'name': 'Switzerland', 'code': '+41'},
    {'name': 'Sweden', 'code': '+46'},
    {'name': 'Ireland', 'code': '+353'},
    {'name': 'Poland', 'code': '+48'},
    {'name': 'Greece', 'code': '+30'},
    {'name': 'Portugal', 'code': '+351'},
    {'name': 'Brazil', 'code': '+55'},
    {'name': 'Mexico', 'code': '+52'},
    {'name': 'South Africa', 'code': '+27'},
    {'name': 'Kenya', 'code': '+254'},
    {'name': 'Nigeria', 'code': '+234'},
    {'name': 'Egypt', 'code': '+20'},
    {'name': 'UAE', 'code': '+971'},
    {'name': 'Saudi Arabia', 'code': '+966'},
    {'name': 'Israel', 'code': '+972'},
    {'name': 'Turkey', 'code': '+90'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'Bangladesh', 'code': '+880'},
  ];

  // Generate consistent emoji based on contact name hash
  String _getEmojiForContact(String name) {
    if (name.isEmpty) return AppConstants.profileEmojis[0];

    final hash = name.hashCode.abs();
    final index = hash % AppConstants.profileEmojis.length;
    return AppConstants.profileEmojis[index];
  }
  String _profileImage = '😊';
  bool _isEmoji = true;
  int _reminderDays = 0;
  bool _hasPersistentNotification = false;
  DaySelectionData? _daySelectionData;
  String? _selectedCountryCode; // NEW: Store selected country code separately
  String _reminderTimeStr = "09:00";


  @override
  void initState() {
    super.initState();

    if (widget.friend != null) {
      _nameController.text = widget.friend!.name;
      _phoneController.text = widget.friend!.phoneNumber;
      // Remove the + when loading for display
      _countryCodeController.text = widget.friend!.countryCode?.substring(1) ?? '';
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

  // Load contact photos in background and update display items
  Future<void> _loadPhotosInBackground(
      List<_ContactDisplayItem> displayItems,
      ValueNotifier<List<_ContactDisplayItem>> notifier,
      ) async {
    try {
      // Load all contacts again with photos
      final contactsWithPhotos = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true, // Slow but non-blocking
      );

      if (!mounted) return;

      // Create a map for faster lookup
      final photoMap = <String, Uint8List?>{};
      for (final contact in contactsWithPhotos) {
        if (contact.photo != null && contact.photo!.isNotEmpty) {
          photoMap[contact.id] = contact.photo;
        }
      }

      // Update display items with photos
      bool anyUpdates = false;
      for (final displayItem in displayItems) {
        final photo = photoMap[displayItem.contact.id];
        if (photo != null) {
          displayItem.photo = photo;
          anyUpdates = true;
        }
      }

      // Trigger UI update if we got any photos
      if (anyUpdates && mounted) {
        notifier.value = List.from(displayItems); // Create new list to trigger rebuild
      }
    } catch (e) {
      print('Error loading contact photos: $e');
      // Silently fail - emojis will remain
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
    _countryCodeController.dispose(); // NEW
    _helpingThemWithController.dispose();
    _helpingYouWithController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission()) {
      try {
        // Stage 1: Show UI immediately with loading state
        final displayItemsNotifier = ValueNotifier<List<_ContactDisplayItem>>([]);
        final isLoadingNotifier = ValueNotifier<bool>(true);

        if (!mounted) return;

        // Show modal immediately
        showCupertinoModalPopup(
          context: context,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => _ContactPickerWithSearch(
              displayItemsNotifier: displayItemsNotifier,
              isLoadingNotifier: isLoadingNotifier,
              scrollController: scrollController,
              onContactSelected: (displayItem) async {
                // Handle photo if exists
                if (displayItem.photo != null && displayItem.photo!.isNotEmpty) {
                  try {
                    final Directory docDir = await getApplicationDocumentsDirectory();
                    final String imagePath = '${docDir.path}/contact_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final File imageFile = File(imagePath);
                    await imageFile.writeAsBytes(displayItem.photo!);

                    setState(() {
                      _profileImage = imagePath;
                      _isEmoji = false;
                    });
                  } catch (e) {
                    print('Error saving contact photo: $e');
                    // Fall back to emoji on error
                    setState(() {
                      _profileImage = displayItem.assignedEmoji;
                      _isEmoji = true;
                    });
                  }
                } else {
                  // Use the consistent emoji from contact picker
                  setState(() {
                    _profileImage = displayItem.assignedEmoji;
                    _isEmoji = true;
                  });
                }

                // Set contact name
                setState(() {
                  _nameController.text = displayItem.contact.displayName;
                });

                // Handle phone number selection
                if (displayItem.contact.phones.isEmpty) {
                  _showErrorSnackBar('Selected contact has no phone number');
                  return;
                }

                if (displayItem.contact.phones.length == 1) {
                  _processContactNumber(displayItem.contact);
                } else {
                  _showPhoneNumberSelector(displayItem.contact);
                }
              },
            ),
          ),
        );

        // Stage 2: Load contacts WITHOUT photos (fast)
        final contactsWithoutPhotos = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false, // Fast load
        );

        if (!mounted) return;

        // Create display items with emojis
        final displayItems = contactsWithoutPhotos.map((contact) {
          return _ContactDisplayItem(
            contact: contact,
            assignedEmoji: _getEmojiForContact(contact.displayName),
            photo: null,
          );
        }).toList();

        // Update UI with emoji-based list
        displayItemsNotifier.value = displayItems;
        isLoadingNotifier.value = false;

        // Stage 3: Load photos in background (non-blocking)
        _loadPhotosInBackground(displayItems, displayItemsNotifier);

      } catch (e) {
        _showErrorSnackBar('Error accessing contacts: $e');
      }
    } else {
      _showErrorSnackBar('Permission to access contacts was denied');
    }
  }

  void _processContactNumber(Contact contact) async {
    if (contact.phones.isEmpty) return;

    String phoneNumber = contact.phones.first.normalizedNumber.isNotEmpty
        ? contact.phones.first.normalizedNumber
        : contact.phones.first.number;

    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Try to extract country code using our known list
    String? detectedCountryCode;
    if (phoneNumber.startsWith('+')) {
      // Check our 40 known country codes (longest first to avoid partial matches)
      final knownCodes = [
        '+1758', '+1784', '+1869', // 4-digit codes first
        '+353', '+351', '+234', '+254', '+880', '+971', '+966', '+972', // 3-digit codes
        '+61', '+44', '+64', '+27', '+91', '+92', '+63', '+60', '+62', '+66',
        '+84', '+20', '+90', '+1', '+81', '+82', '+86', '+33', '+49', '+39',
        '+34', '+31', '+32', '+41', '+46', '+48', '+30', '+55', '+52', '+852',
      ];

      for (final code in knownCodes) {
        if (phoneNumber.startsWith(code)) {
          detectedCountryCode = code;
          phoneNumber = phoneNumber.substring(code.length);

          // Add leading 0 for countries that need it
          final countriesWithLeadingZero = [
            '+61', '+44', '+64', '+27', '+91', '+92', '+234', '+254', '+63',
            '+60', '+62', '+66', '+84', '+20', '+972', '+90', '+880'
          ];

          if (countriesWithLeadingZero.contains(code) && !phoneNumber.startsWith('0')) {
            phoneNumber = '0$phoneNumber';
          }
          break;
        }
      }

      // If we didn't find a known code, just use the number as-is
      if (detectedCountryCode == null) {
        // Unknown country code - just use the whole thing
        phoneNumber = phoneNumber;
      }
    }

    setState(() {
      _phoneController.text = phoneNumber;
      _countryCodeController.text = detectedCountryCode?.substring(1) ?? ''; // Remove the + for display
    });
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

              // Get the selected phone
              String selectedNumber = phone.normalizedNumber.isNotEmpty
                  ? phone.normalizedNumber
                  : phone.number;

              selectedNumber = selectedNumber.replaceAll(RegExp(r'[^\d+]'), '');

              // Try to detect country code
              String? detectedCountryCode;
              if (selectedNumber.startsWith('+')) {
                final knownCodes = [
                  '+1758', '+1784', '+1869',
                  '+353', '+351', '+234', '+254', '+880', '+971', '+966', '+972',
                  '+61', '+44', '+64', '+27', '+91', '+92', '+63', '+60', '+62', '+66',
                  '+84', '+20', '+90', '+1', '+81', '+82', '+86', '+33', '+49', '+39',
                  '+34', '+31', '+32', '+41', '+46', '+48', '+30', '+55', '+52', '+852',
                ];

                for (final code in knownCodes) {
                  if (selectedNumber.startsWith(code)) {
                    detectedCountryCode = code;
                    selectedNumber = selectedNumber.substring(code.length);

                    final countriesWithLeadingZero = [
                      '+61', '+44', '+64', '+27', '+91', '+92', '+234', '+254', '+63',
                      '+60', '+62', '+66', '+84', '+20', '+972', '+90', '+880'
                    ];

                    if (countriesWithLeadingZero.contains(code) && !selectedNumber.startsWith('0')) {
                      selectedNumber = '0$selectedNumber';
                    }
                    break;
                  }
                }
              }

              setState(() {
                _phoneController.text = selectedNumber;
                _countryCodeController.text = detectedCountryCode?.substring(1) ?? '';
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
              style: AppTextStyles.scaledCallout(context).copyWith( // 🔧 FIXED: Consistent with other options
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

            // 🔧 FIXED: Simplified header - remove "Choose Emoji" text to prevent overflow
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            emoji,
                            // 🔧 FIXED: Proper emoji sizing that stays within container bounds
                            style: TextStyle(
                              fontSize: ResponsiveUtils.scaledContainerSize(context, 40) * 0.6,
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

  Future<String?> _showCountryCodePicker(String currentNumber) async {
    int selectedIndex = 0; // Default to "No Country Code"

    return await showCupertinoModalPopup<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
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

              Container(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 12),
                  ResponsiveUtils.scaledSpacing(context, 16),
                  ResponsiveUtils.scaledSpacing(context, 8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Add Country Code',
                      style: AppTextStyles.scaledHeadline(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 4)),
                    Text(
                      currentNumber,
                      style: AppTextStyles.scaledCallout(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 2)),
                    Text(
                      'Select your country to add the correct code',
                      style: AppTextStyles.scaledCaption(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: CupertinoPicker(
                  itemExtent: ResponsiveUtils.scaledContainerSize(context, 44),
                  scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                  onSelectedItemChanged: (index) {
                    selectedIndex = index;
                    HapticFeedback.selectionClick();
                  },
                  children: [
                    // First option: No Country Code
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                        ),
                        child: Text(
                          'No Country Code',
                          style: AppTextStyles.scaledCallout(context).copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Then all the countries
                    ..._countryCodes.map((country) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.scaledSpacing(context, 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  country['name']!,
                                  style: AppTextStyles.scaledCallout(context).copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                              Text(
                                country['code']!,
                                style: AppTextStyles.scaledCallout(context).copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              Container(
                padding: EdgeInsets.all(ResponsiveUtils.scaledSpacing(context, 16)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context, 'manual'),
                        child: Container(
                          height: ResponsiveUtils.scaledButtonHeight(context),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Type Code in Phone Field',
                              style: AppTextStyles.scaledButton(context).copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: ResponsiveUtils.scaledSpacing(context, 12)),

                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (selectedIndex == 0) {
                            // "No Country Code" selected - return 'none'
                            Navigator.pop(context, 'none');
                          } else {
                            // Country selected - return code
                            final selectedCode = _countryCodes[selectedIndex - 1]['code']!;
                            Navigator.pop(context, selectedCode);
                          }
                        },
                        child: Container(
                          height: ResponsiveUtils.scaledButtonHeight(context),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
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
                              style: AppTextStyles.scaledButton(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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

    // Clean phone number
    String phoneNumber = _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');

    // Get country code (empty if not provided)
    String code = _countryCodeController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    String? countryCode = code.isNotEmpty ? '+$code' : null;

    // NEW: Country code skip flow
    if (countryCode == null || countryCode.isEmpty) {
      // Check if this is an existing friend who already skipped
      bool alreadySkipped = widget.friend?.countryCodeSkipped ?? false;

      if (alreadySkipped) {
        // User already made the choice to skip - don't nag again
        print("✅ Friend already has countryCodeSkipped=true, allowing save");
      } else if (!_countryCodeWarningShown) {
        // First attempt - show warning
        ToastService.showWarning(context, 'Press save again to skip country code');
        setState(() {
          _countryCodeWarningShown = true;
        });
        return; // Block save
      } else {
        // Second attempt - allow save and mark as skipped
        print("✅ User confirmed skip, allowing save without country code");
      }
    }

    // Save
    final provider = Provider.of<FriendsProvider>(context, listen: false);

    if (widget.friend == null) {
      // New friend
      final newFriend = Friend(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        profileImage: _profileImage,
        isEmoji: _isEmoji,
        reminderDays: _reminderDays,
        reminderTime: _reminderTimeStr,
        reminderData: _daySelectionData?.toJson(),
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
        countryCodeSkipped: (countryCode == null || countryCode.isEmpty), // Mark if skipped
      );
      await provider.addFriend(newFriend);

      if (mounted) {
        Navigator.pop(context);
        _showInviteDialog(context, newFriend);
      }
    } else {
      // Existing friend
      final updatedFriend = widget.friend!.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        profileImage: _profileImage,
        isEmoji: _isEmoji,
        reminderDays: _reminderDays,
        reminderTime: _reminderTimeStr,
        reminderData: _daySelectionData?.toJson(),
        hasPersistentNotification: _hasPersistentNotification,
        helpingWith: _helpingThemWithController.text.trim(),
        theyHelpingWith: _helpingYouWithController.text.trim(),
        countryCodeSkipped: (countryCode == null || countryCode.isEmpty), // Update skip status
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
            onPressed: () {
              Navigator.pop(context);

              // Show coming soon message
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text(
                    'Coming Soon!',
                    style: AppTextStyles.scaledDialogTitle(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  content: Padding(
                    padding: EdgeInsets.only(top: ResponsiveUtils.scaledSpacing(context, 8)),
                    child: Text(
                      'The invite feature is currently in development. Stay tuned!',
                      style: AppTextStyles.scaledBody(context),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Got it',
                        style: AppTextStyles.scaledButton(context).copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
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
                    // Title area with icon on left - takes available space
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon first
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

                          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),

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
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _profileImage,
                                    // 🔧 FIXED: Larger minimum size while keeping FittedBox protection
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.scaledContainerSize(context, 100) * 0.55,
                                      height: 1.2, // 🔧 FIXED: Slight line height for better centering
                                    ),
                                    textAlign: TextAlign.center,
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
                              // 🔧 FIXED: Smaller, more compact button
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.scaledSpacing(context, 10), // Reduced from 12
                                vertical: ResponsiveUtils.scaledSpacing(context, 6), // Reduced from 8
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8), // Smaller radius
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
                                    // 🔧 FIXED: Smaller icon size
                                    size: ResponsiveUtils.scaledIconSize(context, 14), // Reduced from 16
                                  ),
                                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 5)), // Reduced from 6
                                  Text(
                                    'Change Profile',
                                    style: AppTextStyles.scaledCaption(context).copyWith( // Smaller text style
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

                    // 🔧 ADDED: Friend Details section header
                    _buildSectionHeader('FRIEND DETAILS'),

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label
                              Text(
                                'Phone Number',
                                style: AppTextStyles.scaledCallout(context).copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),

                              // Input row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Country code section
                                  Text(
                                    '+',
                                    style: AppTextStyles.scaledBody(context).copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 2)),
                                  SizedBox(
                                    width: ResponsiveUtils.scaledContainerSize(context, 32),
                                    child: CupertinoTextField(
                                      controller: _countryCodeController,
                                      placeholder: '61',
                                      keyboardType: TextInputType.number,
                                      maxLength: 4,
                                      style: AppTextStyles.scaledBody(context).copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      placeholderStyle: TextStyle(
                                        fontSize: ResponsiveUtils.scaledFontSize(context, 17),
                                        fontWeight: FontWeight.w400,
                                        fontFamily: '.SF Pro Text',
                                        color: const Color(0xFFBEBEC0),
                                      ),
                                      decoration: null,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),

                                  // Separator
                                  Container(
                                    width: 1,
                                    height: ResponsiveUtils.scaledContainerSize(context, 20),
                                    margin: EdgeInsets.only(
                                      left: ResponsiveUtils.scaledSpacing(context, 4),
                                      right: ResponsiveUtils.scaledSpacing(context, 12),
                                    ),
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),

                                  // Phone number field
                                  Expanded(
                                    child: Focus(
                                      focusNode: _phoneFocusNode,
                                      child: CupertinoTextField(
                                        controller: _phoneController,
                                        placeholder: 'Enter number',
                                        keyboardType: TextInputType.phone,
                                        style: AppTextStyles.scaledBody(context).copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        placeholderStyle: TextStyle(
                                          fontSize: ResponsiveUtils.scaledFontSize(context, 17),
                                          fontWeight: FontWeight.w400,
                                          fontFamily: '.SF Pro Text',
                                          color: const Color(0xFFBEBEC0),
                                        ),
                                        decoration: null,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: ResponsiveUtils.scaledSpacing(context, 12)),

                    // 🔧 ADDED: Support Areas section header
                    _buildSectionHeader('SUPPORT AREAS'),

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

                    // 🔧 ADDED: Reminder Settings section header
                    _buildSectionHeader('REMINDER SETTINGS'),

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

                    // 🔧 REMOVED: Redundant "NOTIFICATION SETTINGS" header - now part of Reminder Settings
                    _buildSection(
                      children: [
                        _buildSwitchRow(
                          icon: CupertinoIcons.rectangle_stack_badge_person_crop,
                          iconColor: AppColors.primary,
                          title: 'Quick Access Notification', // 🔧 IMPROVED: Clearer title
                          subtitle: 'Always-visible notification with call & message buttons', // 🔧 IMPROVED: Clearer description
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
        // 🔧 FIXED: Reduced vertical padding for tighter spacing
        vertical: ResponsiveUtils.scaledSpacing(context, 6), // Reduced from 8
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
          // 🔧 FIXED: Reduced vertical padding for consistency
          vertical: ResponsiveUtils.scaledSpacing(context, 6), // Reduced from 8
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 🔧 FIXED: Align to top like form fields
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.scaledSpacing(context, 2), // Align with text baseline
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.scaledCallout(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500, // 🔧 FIXED: Consistent with other section titles
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
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.scaledSpacing(context, 8), // Center switch with text content
              ),
              child: CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactPickerWithSearch extends StatefulWidget {
  final ValueNotifier<List<_ContactDisplayItem>> displayItemsNotifier;
  final ValueNotifier<bool> isLoadingNotifier;
  final ScrollController scrollController;
  final Function(_ContactDisplayItem) onContactSelected;

  const _ContactPickerWithSearch({
    required this.displayItemsNotifier,
    required this.isLoadingNotifier,
    required this.scrollController,
    required this.onContactSelected,
  });

  @override
  State<_ContactPickerWithSearch> createState() => _ContactPickerWithSearchState();
}

class _ContactPickerWithSearchState extends State<_ContactPickerWithSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<_ContactDisplayItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContacts);

    // Listen to display items changes
    widget.displayItemsNotifier.addListener(_updateFilteredList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.displayItemsNotifier.removeListener(_updateFilteredList);
    super.dispose();
  }

  void _updateFilteredList() {
    _filterContacts();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.displayItemsNotifier.value;
      } else {
        _filteredItems = widget.displayItemsNotifier.value.where((item) {
          return item.contact.displayName.toLowerCase().contains(query);
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
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.isLoadingNotifier,
              builder: (context, isLoading, _) {
                if (isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CupertinoActivityIndicator(radius: 14),
                        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 16)),
                        Text(
                          'Loading contacts...',
                          style: AppTextStyles.scaledCallout(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_filteredItems.isEmpty) {
                  return Center(
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
                  );
                }

                return CupertinoScrollbar(
                  controller: widget.scrollController,
                  child: ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final displayItem = _filteredItems[index];
                      final contact = displayItem.contact;

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
                              color: displayItem.photo != null
                                  ? null
                                  : AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: displayItem.photo != null
                                ? ClipOval(
                              child: Image.memory(
                                displayItem.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to emoji on image error
                                  return Center(
                                    child: Text(
                                      displayItem.assignedEmoji,
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.scaledContainerSize(context, 36) * 0.5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                                : Center(
                              child: Text(
                                displayItem.assignedEmoji,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.scaledContainerSize(context, 36) * 0.5,
                                ),
                              ),
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
                            widget.onContactSelected(displayItem);
                          }
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}