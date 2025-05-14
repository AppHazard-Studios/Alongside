// lib/widgets/character_components.dart - No shadows, with patterns
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

/// A collection of custom UI components with personality without shadows
class CharacterComponents {
  // Playful button with pattern background instead of shadow
  static Widget playfulButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double borderRadius = 12,
  }) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown: (_) {
            setState(() => isPressed = true);
          },
          onTapUp: (_) {
            setState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () {
            setState(() => isPressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            height: 50,
            transform: isPressed ? Matrix4.translationValues(0, 1, 0) : Matrix4.identity(),
            decoration: BoxDecoration(
              // Gradient for character
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  bgColor.withBlue((bgColor.blue + 20).clamp(0, 255))
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1.0)
                  : null,
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
                  style: AppTextStyles.button.copyWith(
                    color: txtColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Playful Card with pattern background instead of shadow
  static Widget playfulCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 16,
    Widget? illustration,
  }) {
    final bgColor = backgroundColor ?? AppColors.cardBackground;
    final border = borderColor ?? AppColors.divider;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: onTap != null ? (_) {
            setState(() => isPressed = true);
          } : null,
          onTapUp: onTap != null ? (_) {
            setState(() => isPressed = false);
            onTap();
          } : null,
          onTapCancel: onTap != null ? () {
            setState(() => isPressed = false);
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            padding: padding,
            decoration: BoxDecoration(
              // Subtle gradient for character
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  bgColor.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: border,
                width: 1.0,
              ),
            ),
            transform: isPressed && onTap != null
                ? Matrix4.translationValues(0, 1, 0)
                : Matrix4.identity(),
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
      },
    );
  }

  // Playful Profile Picture with pattern instead of shadow
  static Widget playfulProfilePicture({
    required String imageOrEmoji,
    required bool isEmoji,
    double size = 60,
    Color? backgroundColor,
    VoidCallback? onTap,
    List<BoxShadow>? boxShadow, // Ignored parameter, kept for compatibility
  }) {
    final bgColor = backgroundColor ?? AppColors.primaryLight;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: onTap != null ? (_) {
            setState(() => isPressed = true);
          } : null,
          onTapUp: onTap != null ? (_) {
            setState(() => isPressed = false);
            onTap();
          } : null,
          onTapCancel: onTap != null ? () {
            setState(() => isPressed = false);
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              // Gradient for character
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor.withOpacity(0.9),
                  bgColor.withOpacity(0.6),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: bgColor.withOpacity(0.3),
                  width: 1.5
              ),
            ),
            transform: isPressed ? Matrix4.translationValues(0, 1, 0) : Matrix4.identity(),
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
      },
    );
  }

  // Subtle animation wrapper with refined parameters
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

  // Progress indicator with pattern instead of shadow
  static Widget playfulProgressIndicator({
    required double value,
    Color? backgroundColor,
    Color? progressColor,
    double height = 8,
    bool animated = true,
  }) {
    final bgColor = backgroundColor ?? AppColors.primaryLight;
    final pgColor = progressColor ?? AppColors.primary;

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
                // Gradient for progress indicator
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      pgColor,
                      pgColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Tag/Pill with pattern instead of shadow
  static Widget playfulTag({
    required String label,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
    double fontSize = 14,
  }) {
    final bgColor = backgroundColor ?? AppColors.primaryLight;
    final txtColor = textColor ?? AppColors.primary;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: onTap != null ? (_) {
            setState(() => isPressed = true);
          } : null,
          onTapUp: onTap != null ? (_) {
            setState(() => isPressed = false);
            onTap();
          } : null,
          onTapCancel: onTap != null ? () {
            setState(() => isPressed = false);
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              // Gradient background for character
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor.withOpacity(1.0),
                  bgColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: bgColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            transform: isPressed ? Matrix4.translationValues(0, 1, 0) : Matrix4.identity(),
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Emotionally responsive greeting based on time of day and user name
  static Widget personalizedGreeting({
    required String name,
    TextStyle? style,
  }) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    Color iconBgColor;
    Color iconColor;

    if (hour < 12) {
      greeting = "Good Morning";
      icon = CupertinoIcons.sun_max_fill;
      iconBgColor = AppColors.joyful.withOpacity(0.2);
      iconColor = AppColors.joyful;
    } else if (hour < 17) {
      greeting = "Good Afternoon";
      icon = CupertinoIcons.sun_min_fill;
      iconBgColor = AppColors.accent.withOpacity(0.2);
      iconColor = AppColors.accent;
    } else {
      greeting = "Good Evening";
      icon = CupertinoIcons.moon_stars_fill;
      iconBgColor = AppColors.calm.withOpacity(0.2);
      iconColor = AppColors.calm;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            // Gradient background for icon
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                iconBgColor,
                iconBgColor.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1,
            ),
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
          style: style ?? AppTextStyles.title.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Mood Icons with pattern instead of shadow
  static Widget moodIcon({
    required String mood,
    double size = 40,
  }) {
    IconData icon;
    Color color;

    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
        icon = CupertinoIcons.smiley_fill;
        color = AppColors.joyful;
        break;
      case 'calm':
      case 'relaxed':
        icon = CupertinoIcons.heart_fill;
        color = AppColors.calm;
        break;
      case 'focused':
      case 'productive':
        icon = CupertinoIcons.lightbulb_fill;
        color = AppColors.focused;
        break;
      case 'stressed':
      case 'anxious':
        icon = CupertinoIcons.exclamationmark_circle_fill;
        color = AppColors.stressed;
        break;
      default:
        icon = CupertinoIcons.smiley;
        color = AppColors.secondary;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Gradient background for character
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: size * 0.6,
        ),
      ),
    );
  }

  // Badge with pattern instead of shadow
  static Widget bouncingBadge({
    required String text,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final bgColor = backgroundColor ?? AppColors.secondary;
    final txtColor = textColor ?? Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // Gradient background for character
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgColor,
                  bgColor.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: txtColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}