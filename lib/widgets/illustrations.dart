// lib/widgets/illustrations.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Custom illustrations that add personality to the app
class Illustrations {
  // Simple friends illustration
  static Widget friendsIllustration({double size = 120}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FriendsIllustrationPainter(),
    );
  }

  // Simple messaging illustration
  static Widget messagingIllustration({double size = 120}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MessagingIllustrationPainter(),
    );
  }

  // Simple call illustration
  static Widget callIllustration({double size = 120}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CallIllustrationPainter(),
    );
  }

  // Simple reminder illustration
  static Widget reminderIllustration({double size = 120}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ReminderIllustrationPainter(),
    );
  }

  // Simple empty state illustration
  static Widget emptyStateIllustration({double size = 180}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EmptyStateIllustrationPainter(),
    );
  }
}

// Friends illustration painter
class _FriendsIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    final bgPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2.2,
      bgPaint,
    );

    // First person (left)
    final person1Paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.4),
      size.width * 0.12,
      person1Paint,
    );

    // Body
    final person1Path = Path()
      ..moveTo(size.width * 0.25, size.height * 0.55)
      ..lineTo(size.width * 0.45, size.height * 0.55)
      ..lineTo(size.width * 0.4, size.height * 0.85)
      ..lineTo(size.width * 0.3, size.height * 0.85)
      ..close();
    canvas.drawPath(person1Path, person1Paint);

    // Second person (right)
    final person2Paint = Paint()
      ..color = AppColors.tertiary
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.4),
      size.width * 0.12,
      person2Paint,
    );

    // Body
    final person2Path = Path()
      ..moveTo(size.width * 0.55, size.height * 0.55)
      ..lineTo(size.width * 0.75, size.height * 0.55)
      ..lineTo(size.width * 0.7, size.height * 0.85)
      ..lineTo(size.width * 0.6, size.height * 0.85)
      ..close();
    canvas.drawPath(person2Path, person2Paint);

    // Connection heart between people
    final heartPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final heartPath = Path();
    final heartSize = size.width * 0.12;
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.5;

    heartPath.moveTo(centerX, centerY + heartSize * 0.3);

    // Left curve
    heartPath.cubicTo(
      centerX - heartSize * 0.9, centerY - heartSize * 0.2,
      centerX - heartSize * 0.6, centerY - heartSize * 0.8,
      centerX, centerY - heartSize * 0.2,
    );

    // Right curve
    heartPath.cubicTo(
      centerX + heartSize * 0.6, centerY - heartSize * 0.8,
      centerX + heartSize * 0.9, centerY - heartSize * 0.2,
      centerX, centerY + heartSize * 0.3,
    );

    canvas.drawPath(heartPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Messaging illustration painter
class _MessagingIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.secondaryLight
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2.2,
      bgPaint,
    );

    // Left message bubble
    final leftBubblePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final leftBubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.3,
        size.width * 0.45,
        size.height * 0.2,
      ),
      Radius.circular(size.width * 0.05),
    );
    canvas.drawRRect(leftBubbleRect, leftBubblePaint);

    // Left bubble tail
    final leftTailPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.45)
      ..lineTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..close();
    canvas.drawPath(leftTailPath, leftBubblePaint);

    // Right message bubble
    final rightBubblePaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final rightBubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.45,
        size.height * 0.2,
      ),
      Radius.circular(size.width * 0.05),
    );
    canvas.drawRRect(rightBubbleRect, rightBubblePaint);

    // Right bubble tail
    final rightTailPath = Path()
      ..moveTo(size.width * 0.8, size.height * 0.7)
      ..lineTo(size.width * 0.85, size.height * 0.75)
      ..lineTo(size.width * 0.8, size.height * 0.75)
      ..close();
    canvas.drawPath(rightTailPath, rightBubblePaint);

    // Lines in left bubble (text)
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.35,
          size.width * 0.35,
          size.height * 0.02,
        ),
        Radius.circular(size.width * 0.01),
      ),
      linePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.4,
          size.width * 0.25,
          size.height * 0.02,
        ),
        Radius.circular(size.width * 0.01),
      ),
      linePaint,
    );

    // Lines in right bubble (text)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.4,
          size.height * 0.6,
          size.width * 0.35,
          size.height * 0.02,
        ),
        Radius.circular(size.width * 0.01),
      ),
      linePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.4,
          size.height * 0.65,
          size.width * 0.3,
          size.height * 0.02,
        ),
        Radius.circular(size.width * 0.01),
      ),
      linePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.4,
          size.height * 0.7,
          size.width * 0.2,
          size.height * 0.02,
        ),
        Radius.circular(size.width * 0.01),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Call illustration painter
class _CallIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.tertiaryLight
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2.2,
      bgPaint,
    );

    // Phone shape
    final phonePaint = Paint()
      ..color = AppColors.tertiary
      ..style = PaintingStyle.fill;

    final phoneBodyPath = Path();
    phoneBodyPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.3,
          size.height * 0.3,
          size.width * 0.4,
          size.height * 0.4,
        ),
        Radius.circular(size.width * 0.1),
      ),
    );
    canvas.drawPath(phoneBodyPath, phonePaint);

    // Call button
    final buttonPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.12,
      buttonPaint,
    );

    // Phone icon
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;

    // Draw phone handle
    final phonePath = Path();
    phonePath.moveTo(size.width * 0.44, size.height * 0.47);
    phonePath.lineTo(size.width * 0.48, size.height * 0.45);
    phonePath.lineTo(size.width * 0.52, size.height * 0.49);
    phonePath.lineTo(size.width * 0.56, size.height * 0.47);
    canvas.drawPath(phonePath, iconPaint);

    // Sound waves
    final wavePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.008
      ..strokeCap = StrokeCap.round;

    // Small wave
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.35,
        size.width * 0.3,
        size.height * 0.3,
      ),
      -0.9,
      1.8,
      false,
      wavePaint,
    );

    // Medium wave
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.5,
        size.height * 0.5,
      ),
      -0.9,
      1.8,
      false,
      wavePaint,
    );

    // Large wave
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.15,
        size.width * 0.7,
        size.height * 0.7,
      ),
      -0.9,
      1.8,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Reminder illustration painter
class _ReminderIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.accentLight
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2.2,
      bgPaint,
    );

    // Bell shape
    final bellPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    // Bell body
    final bellPath = Path();
    bellPath.moveTo(size.width * 0.5, size.height * 0.3);
    bellPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.5,
    );
    bellPath.lineTo(size.width * 0.7, size.height * 0.65);
    bellPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.7,
      size.width * 0.65,
      size.height * 0.7,
    );
    bellPath.lineTo(size.width * 0.35, size.height * 0.7);
    bellPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.7,
      size.width * 0.3,
      size.height * 0.65,
    );
    bellPath.lineTo(size.width * 0.3, size.height * 0.5);
    bellPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.3,
    );
    canvas.drawPath(bellPath, bellPaint);

    // Bell handle
    final handlePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.4,
        size.height * 0.25,
        size.width * 0.2,
        size.height * 0.1,
      ),
      -3.14,
      -3.14,
      false,
      handlePaint,
    );

    // Bell bottom
    final bottomPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.75),
      size.width * 0.04,
      bottomPaint,
    );

    // Bell sound waves
    final wavePaint = Paint()
      ..color = AppColors.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.5,
        size.height * 0.5,
      ),
      -0.8,
      1.6,
      false,
      wavePaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.15,
        size.width * 0.7,
        size.height * 0.7,
      ),
      -0.8,
      1.6,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Empty state illustration painter
class _EmptyStateIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.fill;

    // Background circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2.2,
      bgPaint,
    );

    // Character face - circle
    final facePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.45),
      size.width * 0.25,
      facePaint,
    );

    // Eyes
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Left eye
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.4),
      size.width * 0.06,
      eyePaint,
    );

    // Right eye
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.4),
      size.width * 0.06,
      eyePaint,
    );

    // Eye pupils
    final pupilPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    // Left pupil
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.4),
      size.width * 0.03,
      pupilPaint,
    );

    // Right pupil
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.4),
      size.width * 0.03,
      pupilPaint,
    );

    // Smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.4,
        size.width * 0.3,
        size.height * 0.15,
      ),
      0.2,
      2.7,
      false,
      smilePaint,
    );

    // Character body
    final bodyPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.4, size.height * 0.7);
    bodyPath.lineTo(size.width * 0.6, size.height * 0.7);
    bodyPath.lineTo(size.width * 0.55, size.height * 0.85);
    bodyPath.lineTo(size.width * 0.45, size.height * 0.85);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Character arms
    final armPaint = Paint()
      ..color = AppColors.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    // Left arm
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.72),
      Offset(size.width * 0.25, size.height * 0.65),
      armPaint,
    );

    // Right arm
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.72),
      Offset(size.width * 0.75, size.height * 0.65),
      armPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}