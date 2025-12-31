// lib/services/toast_service.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  OverlayEntry? _currentOverlayEntry;
  bool _isShowing = false;

  /// Show a toast with the specified message and type
  static void show(
      BuildContext context,
      String message, {
        ToastType type = ToastType.success,
        Duration duration = const Duration(seconds: 2),
        IconData? customIcon,
      }) {
    _instance._showToast(context, message, type, duration, customIcon);
  }

  /// Quick method for success toasts
  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  /// Quick method for error toasts
  static void showError(BuildContext context, String message) {
    show(context, message, type: ToastType.error);
  }

  /// Quick method for warning toasts
  static void showWarning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  /// Quick method for info toasts
  static void showInfo(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }

  /// Hide current toast if showing
  static void hide() {
    _instance._hideCurrentToast();
  }

  void _showToast(
      BuildContext context,
      String message,
      ToastType type,
      Duration duration,
      IconData? customIcon,
      ) async {
    // If already showing a toast, hide it first
    if (_isShowing) {
      await _hideCurrentToast(animated: true);
    }

    final overlay = Overlay.of(context);

    _isShowing = true;

    final toastColors = _getToastColors(type);
    final icon = customIcon ?? _getToastIcon(type);

    _currentOverlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        backgroundColor: toastColors.backgroundColor,
        iconColor: toastColors.iconColor,
        textColor: toastColors.textColor,
        shadows: toastColors.shadows,
      ),
    );

    overlay.insert(_currentOverlayEntry!);

    // Auto-hide after duration
    Future.delayed(duration, () {
      _hideCurrentToast();
    });
  }

  Future<void> _hideCurrentToast({bool animated = false}) async {
    if (_currentOverlayEntry == null || !_isShowing) return;

    if (animated) {
      // Wait a short time for smooth transition
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
    _isShowing = false;
  }

  _ToastColors _getToastColors(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastColors(
          backgroundColor: AppColors.primary,
          iconColor: CupertinoColors.white,
          textColor: CupertinoColors.white,
          shadows: AppColors.primaryShadow,
        );
      case ToastType.error:
        return _ToastColors(
          backgroundColor: AppColors.error,
          iconColor: CupertinoColors.white,
          textColor: CupertinoColors.white,
          shadows: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case ToastType.warning:
        return _ToastColors(
          backgroundColor: AppColors.warning,
          iconColor: CupertinoColors.white,
          textColor: CupertinoColors.white,
          shadows: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case ToastType.info:
        return _ToastColors(
          backgroundColor: AppColors.secondary,
          iconColor: CupertinoColors.white,
          textColor: CupertinoColors.white,
          shadows: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );
    }
  }

  IconData _getToastIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return CupertinoIcons.checkmark_circle_fill;
      case ToastType.error:
        return CupertinoIcons.xmark_circle_fill;
      case ToastType.warning:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case ToastType.info:
        return CupertinoIcons.info_circle_fill;
    }
  }
}

class _ToastColors {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final List<BoxShadow> shadows;

  _ToastColors({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.shadows,
  });
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final List<BoxShadow> shadows;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.shadows,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: ResponsiveUtils.scaledSpacing(context, 100),
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.scaledSpacing(context, 20),
                    vertical: ResponsiveUtils.scaledSpacing(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: widget.shadows,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: ResponsiveUtils.scaledIconSize(context, 20),
                      ),
                      SizedBox(
                        width: ResponsiveUtils.scaledSpacing(context, 8),
                      ),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: ResponsiveUtils.scaledFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                            fontFamily: '.SF Pro Text',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}