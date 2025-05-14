// lib/utils/ui_constants.dart - New file for consistent UI styling

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized UI constants to ensure consistency across the entire app
class UIConstants {
  // Standard padding values
  static const double screenEdgePadding = 16.0;
  static const double contentPadding = 16.0;
  static const double itemSpacing = 8.0;
  static const double smallSpacing = 4.0;

  // Border radius values
  static const double cardBorderRadius = 10.0;
  static const double buttonBorderRadius = 10.0;

  // Container styling
  static BoxDecoration standardCardDecoration = BoxDecoration(
    color: CupertinoColors.white,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    border: Border.all(
      color: CupertinoColors.systemGrey5,
      width: 1.0,
    ),
  );

  // Blue accent styling
  static BoxDecoration accentCardDecoration = BoxDecoration(
    color: const Color(0xFF007AFF).withOpacity(0.08),
    borderRadius: BorderRadius.circular(cardBorderRadius),
  );

  // Standard container padding
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    vertical: 14.0,
    horizontal: 16.0,
  );

  // Separator styling
  static const Divider iosSeparator = Divider(
    height: 0.5,
    thickness: 0.5,
    color: CupertinoColors.separator,
  );

  // Icon styling
  static Widget circularSettingsIcon({required VoidCallback onPressed}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          CupertinoIcons.gear,
          color: Color(0xFF007AFF),
          size: 16,
        ),
        padding: EdgeInsets.zero,
        splashRadius: 14,
      ),
    );
  }

  // Standard appbar styling
  static AppBar standardAppBar({
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.black,
          fontFamily: '.SF Pro Text',
          letterSpacing: -0.41,
        ),
      ),
      centerTitle: true,
      backgroundColor: CupertinoColors.systemBackground,
      elevation: 0,
      leading: onBackPressed != null
          ? IconButton(
        icon: const Icon(CupertinoIcons.back),
        onPressed: onBackPressed,
        splashRadius: 24,
      )
          : null,
      actions: actions,
    );
  }

  // Consistent form field styling (no yellow underlines)
  static InputDecoration cleanInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: CupertinoColors.placeholderText,
        fontFamily: '.SF Pro Text',
      ),
      border: InputBorder.none, // Remove all borders including underlines
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Cupertino form field styling (for iOS native feel)
  static Widget buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String placeholder = '',
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF007AFF),
            size: 20,
          ),
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
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                const SizedBox(height: 6),
                CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  placeholderStyle: TextStyle(
                    color: CupertinoColors.systemGrey.withOpacity(0.7),
                    fontSize: 15,
                    fontFamily: '.SF Pro Text',
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.white,
                    border: Border(), // No border - iOS style
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.black,
                    fontFamily: '.SF Pro Text',
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
}