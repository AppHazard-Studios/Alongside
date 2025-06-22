// utils/ui_constants.dart - UI standardization

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Standardized UI constants to ensure consistency across the app
class UIConstants {
  // SPACING & PADDING

  // Standard screen edge padding - used consistently in all screens
  static const double screenPadding = 16.0;

  // Content padding within cards and containers
  static const double contentPadding = 16.0;

  // Content item vertical spacing
  static const double itemSpacing = 8.0;

  // Small spacing between related elements
  static const double smallSpacing = 4.0;

  // Standard padding for all cards and containers
  static const EdgeInsets standardPadding = EdgeInsets.all(16.0);

  // Input field padding
  static const EdgeInsets inputPadding =
      EdgeInsets.symmetric(vertical: 12.0, horizontal: 0);

  // List item padding
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0);

  // BORDER RADIUS

  // Used for cards
  static const double cardRadius = 10.0;

  // Used for buttons
  static const double buttonRadius = 8.0;

  // Used for small elements like chips
  static const double smallRadius = 6.0;

  // Used for the bottom sheet handle
  static const double sheetHandleRadius = 2.0;

  // CONTAINER STYLING

  // Standard card decoration without shadow
  static BoxDecoration cardDecoration = BoxDecoration(
    color: CupertinoColors.white,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(
      color: CupertinoColors.systemGrey5,
      width: 0.5,
    ),
  );

  // Card decoration with shadow
  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: CupertinoColors.white,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: [
      BoxShadow(
        color: CupertinoColors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // iOS accent container styling (light blue background)
  static BoxDecoration accentCardDecoration = BoxDecoration(
    color: const Color(0xFF007AFF).withOpacity(0.08),
    borderRadius: BorderRadius.circular(cardRadius),
  );

  // MESSAGE STYLING

  // Method to create message box decoration based on content length
  static BoxDecoration getMessageBoxDecoration(String message) {
    return BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(
        color: CupertinoColors.systemGrey5,
        width: 0.5,
      ),
    );
  }

  // SHADOWS

  // Subtle shadow - for cards
  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: CupertinoColors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // DIVIDERS & SEPARATORS

  // iOS-style separator
  static const Divider iosSeparator = Divider(
    height: 0.5,
    thickness: 0.5,
    color: CupertinoColors.separator,
  );

  // Margin to indent separators (iOS style)
  static const EdgeInsets separatorIndent = EdgeInsets.only(left: 16.0);

  // INPUT FIELD STYLING

  // No yellow underlines with these styles
  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefix: prefix,
      suffix: suffix,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Clean CupertinoTextField style - no yellow underlines
  static BoxDecoration cleanCupertinoInputDecoration = const BoxDecoration(
    color: CupertinoColors.white,
    border: Border(
      bottom: BorderSide(
        width: 0,
        color: Colors.transparent,
      ),
    ),
  );

  // CUSTOM UI COMPONENTS

  // Settings icon in circle background
  static Widget buildSettingsIcon({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            CupertinoIcons.gear,
            size: 16,
            color: Color(0xFF007AFF),
          ),
        ),
      ),
    );
  }

  // Action button with label and icon
  static Widget buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFF007AFF),
    Color textColor = Colors.white,
    Color? borderColor,
  }) {
    return SizedBox(
      height: 44,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(buttonRadius),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toast notification
  static void showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 15,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
