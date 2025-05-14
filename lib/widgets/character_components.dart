// lib/widgets/character_components.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';

/// A collection of custom UI components with more personality
class CharacterComponents {
  // Playful button with slight bounce animation
  static Widget playfulButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double borderRadius = 12,
    bool showShadow = true,
  }) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 150),
      builder: (context, scale, child) {
        return GestureDetector(
          onTapDown: (_) => {}, // This will be handled by the StatefulWrapper
          onTapUp: (_) => {},
          onTap: onPressed,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isPressed = false;
          return GestureDetector(
            onTapDown: (_) {
              setState(() => isPressed = true);
            },
            onTapUp: (_) {
              setState(() => isPressed = false);
              Future.delayed(const Duration(milliseconds: 50), () {
                if (onPressed != null) {
                  onPressed();
                }
              });
            },
            onTapCancel: () {
              setState(() => isPressed = false);
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: borderColor != null
                    ? Border.all(color: borderColor, width: 1.5)
                    : null,
                boxShadow: showShadow
                    ? [
                  BoxShadow(
                    color: bgColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: txtColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: txtColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Playful Card with subtle hover effect and optional illustration
  static Widget playfulCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 16,
    Widget? illustration,
    bool showShadow = true,
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
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: border,
                width: 1.5,
              ),
              boxShadow: showShadow
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.05 : 0.1),
                  blurRadius: isPressed ? 4 : 8,
                  offset: isPressed
                      ? const Offset(0, 2)
                      : const Offset(0, 4),
                ),
              ]
                  : null,
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
      },
    );
  }

  // Playful Profile Picture with an animated pulse on tap
  static Widget playfulProfilePicture({
    required String imageOrEmoji,
    required bool isEmoji,
    double size = 60,
    Color? backgroundColor,
    VoidCallback? onTap,
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
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: isPressed ? 0.95 : 1.0),
            duration: const Duration(milliseconds: 150),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
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
          ),
        );
      },
    );
  }

  // Subtle animation wrapper that adds a gentle floating effect
  static Widget floatingElement({
    required Widget child,
    Duration period = const Duration(seconds: 2),
    double yOffset = 4,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
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
      },
    );
  }

  // Progress indicator with character (curved ends, animated)
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

  // Tag/Pill with playful bounce on tap
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

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 150),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: StatefulBuilder(
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
                duration: const Duration(milliseconds: 100),
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
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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

    if (hour < 12) {
      greeting = "Good Morning";
      icon = CupertinoIcons.sun_max_fill;
    } else if (hour < 17) {
      greeting = "Good Afternoon";
      icon = CupertinoIcons.sun_min_fill;
    } else {
      greeting = "Good Evening";
      icon = CupertinoIcons.moon_stars_fill;
    }

    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.accent,
          size: 24,
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

  // Mood Icons with personality
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
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
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

  // Badge with bounce animation
  static Widget bouncingBadge({
    required String text,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final bgColor = backgroundColor ?? AppColors.secondary;
    final txtColor = textColor ?? Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
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
              ),
            ),
          ),
        );
      },
    );
  }
}