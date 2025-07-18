// lib/screens/lock_screen.dart - REDESIGNED PREMIUM iOS STYLE
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/lock_service.dart';
import '../utils/colors.dart';
import '../utils/responsive_utils.dart';
import 'dart:async';
import 'dart:ui';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({
    Key? key,
    required this.onUnlocked,
  }) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final LockService _lockService = LockService();
  final TextEditingController _pinController = TextEditingController();

  String? _lockType;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isAuthenticating = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLock();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _shakeAnimation = Tween(
      begin: 0.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeLock() async {
    final lockType = await _lockService.getLockType();
    setState(() {
      _lockType = lockType;
      _isLoading = false;
    });

    // Auto-trigger biometric if enabled
    if (lockType == 'biometric') {
      Future.delayed(const Duration(milliseconds: 800), () {
        _authenticateBiometric();
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final authenticated = await _lockService.authenticateBiometric();

      if (authenticated && mounted) {
        HapticFeedback.lightImpact();
        await _fadeController.reverse();
        widget.onUnlocked();
      } else {
        setState(() {
          _errorMessage = 'Authentication failed';
        });
        HapticFeedback.heavyImpact();
        _shakeController.forward().then((_) {
          _shakeController.reset();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    final verified = await _lockService.verifyPin(_pinController.text);

    if (verified && mounted) {
      HapticFeedback.lightImpact();
      await _fadeController.reverse();
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN';
        _pinController.clear();
        _isAuthenticating = false;
      });
      HapticFeedback.heavyImpact();
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: SizedBox.expand(
          child: Center(
            child: CupertinoActivityIndicator(
              radius: ResponsiveUtils.scaledIconSize(context, 14),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: SizedBox.expand(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.primaryLight.withOpacity(0.1),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: ResponsiveUtils.scaledPadding(
                    context,
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  ),
                  child: Column(
                    children: [
                      // Top spacer
                      const Spacer(flex: 2),

                      // App branding section
                      _buildAppBranding(),

                      const Spacer(flex: 1),

                      // Authentication section
                      _buildAuthenticationSection(),

                      const Spacer(flex: 2),

                      // Bottom info
                      if (_lockType == 'biometric' && !_isAuthenticating && _errorMessage.isNotEmpty)
                        _buildRetryButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBranding() {
    return Column(
      children: [
        // App icon with subtle animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseAnimation.value * 0.05),
              child: Container(
                width: ResponsiveUtils.scaledContainerSize(context, 100),
                height: ResponsiveUtils.scaledContainerSize(context, 100),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  size: ResponsiveUtils.scaledIconSize(context, 50),
                  color: CupertinoColors.white,
                ),
              ),
            );
          },
        ),

        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

        // App name
        Text(
          'Alongside',
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 28, maxScale: 1.4),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFamily: '.SF Pro Text',
          ),
        ),

        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),

        // Subtitle
        Text(
          _lockType == 'biometric'
              ? 'Secure access with biometrics'
              : 'Enter your PIN to continue',
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
            color: AppColors.textSecondary,
            fontFamily: '.SF Pro Text',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthenticationSection() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            children: [
              if (_lockType == 'biometric')
                _buildBiometricAuth()
              else
                _buildPinAuth(),

              // Error message
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtils.scaledSpacing(context, 20)),
                _buildErrorMessage(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBiometricAuth() {
    return Column(
      children: [
        // Biometric icon with subtle pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: ResponsiveUtils.scaledContainerSize(context, 120),
              height: ResponsiveUtils.scaledContainerSize(context, 120),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3 + _pulseAnimation.value * 0.7),
                  width: 2,
                ),
              ),
              child: Center(
                child: _isAuthenticating
                    ? CupertinoActivityIndicator(
                  radius: ResponsiveUtils.scaledIconSize(context, 20),
                  color: AppColors.primary,
                )
                    : Icon(
                  CupertinoIcons.lock_shield_fill,
                  size: ResponsiveUtils.scaledIconSize(context, 50),
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),

        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

        Text(
          _isAuthenticating
              ? 'Authenticating...'
              : 'Touch sensor or use Face ID',
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 15, maxScale: 1.3),
            color: AppColors.textSecondary,
            fontFamily: '.SF Pro Text',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPinAuth() {
    return Column(
      children: [
        // PIN input with premium styling
        Container(
          width: ResponsiveUtils.scaledContainerSize(context, 240),
          padding: ResponsiveUtils.scaledPadding(
            context,
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _errorMessage.isNotEmpty
                  ? AppColors.error.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CupertinoTextField(
            controller: _pinController,
            placeholder: 'Enter PIN',
            keyboardType: TextInputType.number,
            obscureText: true,
            textAlign: TextAlign.center,
            autofocus: true,
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 20, maxScale: 1.3),
              letterSpacing: 8,
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
              color: AppColors.textPrimary,
            ),
            decoration: null,
            padding: EdgeInsets.zero,
            onSubmitted: (_) => _verifyPin(),
            onChanged: (value) {
              if (_errorMessage.isNotEmpty) {
                setState(() {
                  _errorMessage = '';
                });
              }
            },
            placeholderStyle: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 20, maxScale: 1.3),
              color: AppColors.textSecondary.withOpacity(0.5),
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),

        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 32)),

        // Unlock button
        Container(
          width: ResponsiveUtils.scaledContainerSize(context, 200),
          height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 50),
          child: CupertinoButton(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            onPressed: _isAuthenticating ? null : _verifyPin,
            child: _isAuthenticating
                ? CupertinoActivityIndicator(
              color: CupertinoColors.white,
              radius: ResponsiveUtils.scaledIconSize(context, 12),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.lock_open_fill,
                  size: ResponsiveUtils.scaledIconSize(context, 18),
                  color: CupertinoColors.white,
                ),
                SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                Text(
                  'Unlock',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: ResponsiveUtils.scaledPadding(
        context,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: ResponsiveUtils.scaledIconSize(context, 16),
            color: AppColors.error,
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
          Flexible(
            child: Text(
              _errorMessage,
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.3),
                color: AppColors.error,
                fontFamily: '.SF Pro Text',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return Container(
      width: ResponsiveUtils.scaledContainerSize(context, 200),
      height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 44),
      child: CupertinoButton(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        onPressed: _authenticateBiometric,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.arrow_clockwise,
              size: ResponsiveUtils.scaledIconSize(context, 16),
              color: AppColors.primary,
            ),
            SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
            Text(
              'Try Again',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
                fontWeight: FontWeight.w600,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }
}