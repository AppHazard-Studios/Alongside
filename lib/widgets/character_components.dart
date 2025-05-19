// lib/widgets/character_components.dart - Fix profile image and simplify components
import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../utils/colors.dart';

/// A collection of streamlined UI components with iOS design principles
class CharacterComponents {
  // Personalized greeting with fixed text styling
  static Widget personalizedGreeting({
    required String name,
    TextStyle? style,
    bool centered = false,
  }) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    Color iconColor;

    if (hour < 12) {
      greeting = "Good Morning";
      icon = CupertinoIcons.sun_max_fill;
      iconColor = CupertinoColors.systemYellow;
    } else if (hour < 17) {
      greeting = "Good Afternoon";
      icon = CupertinoIcons.sun_min_fill;
      iconColor = CupertinoColors.systemOrange;
    } else {
      greeting = "Good Evening";
      icon = CupertinoIcons.moon_stars_fill;
      iconColor = CupertinoColors.systemIndigo;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$greeting, $name!",
          style: style ?? const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ],
    );

    return centered
        ? Center(child: content)
        : content;
  }

  // Clean iOS-style button
  static Widget playfulButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 12,
  }) {
    final bgColor = backgroundColor ?? CupertinoColors.systemBlue;
    final txtColor = textColor ?? CupertinoColors.white;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: txtColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clean iOS-style card
  static Widget playfulCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 16,
    Widget? illustration,
  }) {
    final bgColor = backgroundColor ?? CupertinoColors.systemBackground;
    final border = borderColor ?? CupertinoColors.systemGrey5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (illustration != null) ...[
              Center(child: illustration),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }

  // Fixed profile picture component with proper background color
  static Widget playfulProfilePicture({
    required String imageOrEmoji,
    required bool isEmoji,
    double size = 60,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    // Default background color that contrasts with both light and dark themes
    final bgColor = backgroundColor ?? (isEmoji
        ? CupertinoColors.systemGrey6  // Light gray background for emoji
        : CupertinoColors.white);      // White background for photos

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
        child: isEmoji
            ? Center(
          child: Text(
            imageOrEmoji,
            style: TextStyle(fontSize: size * 0.5),
          ),
        )
            : ClipOval(
          child: Image.file(
            File(imageOrEmoji),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}