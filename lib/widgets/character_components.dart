// lib/widgets/character_components.dart - Complete file with fixes
import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../utils/colors.dart';

/// A collection of custom UI components with iOS 2025 design principles
class CharacterComponents {
  // Personalized greeting with fixed text styling
  static Widget personalizedGreeting({
    required String name,
    TextStyle? style,
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

    return Row(
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

  // Clean iOS-style profile picture
  static Widget playfulProfilePicture({
    required String imageOrEmoji,
    required bool isEmoji,
    double size = 60,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    final bgColor = backgroundColor ?? CupertinoColors.systemGrey6;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEmoji ? bgColor : CupertinoColors.white,
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

  // Subtle animation wrapper
  static Widget floatingElement({
    required Widget child,
    Duration period = const Duration(seconds: 2),
    double yOffset = 4,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1, end: 1),
      duration: period,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * yOffset / 2),
          child: child,
        );
      },
      child: child,
    );
  }

  // Simple iOS-style progress indicator
  static Widget playfulProgressIndicator({
    required double value,
    Color? backgroundColor,
    Color? progressColor,
    double height = 8,
    bool animated = true,
  }) {
    final bgColor = backgroundColor ?? CupertinoColors.systemGrey5;
    final pgColor = progressColor ?? CupertinoColors.systemBlue;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: animated
                    ? const Duration(milliseconds: 500)
                    : Duration.zero,
                curve: Curves.easeInOut,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: pgColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // iOS-style tag/badge
  static Widget playfulTag({
    required String label,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
    double fontSize = 14,
  }) {
    final bgColor = backgroundColor ?? CupertinoColors.systemGrey6;
    final txtColor = textColor ?? CupertinoColors.systemBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: txtColor,
                size: fontSize + 2,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: txtColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // iOS-style bouncingBadge
  static Widget bouncingBadge({
    required String text,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final bgColor = backgroundColor ?? CupertinoColors.systemBlue;
    final txtColor = textColor ?? CupertinoColors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: txtColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: '.SF Pro Text',
        ),
      ),
    );
  }
}