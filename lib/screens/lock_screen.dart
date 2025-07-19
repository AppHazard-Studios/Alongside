// lib/screens/lock_screen.dart - COMPLETE MODERN iOS REDESIGN
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

  // PIN input tracking
  String _enteredPin = '';
  bool _showPinError = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _pinDotController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _pinDotAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLock();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _pinDotController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _shakeAnimation = Tween(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _pinDotAnimation = CurvedAnimation(
      parent: _pinDotController,
      curve: Curves.elasticOut,
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
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _authenticateBiometric();
        }
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    if (_isAuthenticating || _lockType != 'biometric') return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final authenticated = await _lockService.authenticateBiometric();

      if (authenticated && mounted) {
        HapticFeedback.lightImpact();
        await _successAnimation();
        widget.onUnlocked();
      } else {
        _showError('Authentication failed. Try again or use your device passcode.');
        _triggerErrorAnimation();
      }
    } catch (e) {
      _showError('Authentication error. Please try again.');
      _triggerErrorAnimation();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _handlePinInput(String digit) {
    if (_enteredPin.length >= 4) return;

    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += digit;
      _showPinError = false;
      _errorMessage = '';
    });

    _pinDotController.forward().then((_) {
      _pinDotController.reverse();
    });

    // Auto-verify when 4 digits entered
    if (_enteredPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _verifyPin();
      });
    }
  }

  void _clearPin() {
    if (_enteredPin.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
      _showPinError = false;
      _errorMessage = '';
    });
  }

  Future<void> _verifyPin() async {
    if (_enteredPin.length != 4) {
      _showError('Enter your 4-digit PIN');
      _triggerErrorAnimation();
      return;
    }

    setState(() {
      _isAuthenticating = true;
    });

    final verified = await _lockService.verifyPin(_enteredPin);

    if (verified && mounted) {
      HapticFeedback.lightImpact();
      await _successAnimation();
      widget.onUnlocked();
    } else {
      _showError('Incorrect PIN');
      _triggerErrorAnimation();
      setState(() {
        _enteredPin = '';
        _isAuthenticating = false;
        _showPinError = true;
      });
    }
  }

  Future<void> _successAnimation() async {
    await _fadeController.reverse();
  }

  void _triggerErrorAnimation() {
    HapticFeedback.heavyImpact();
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    // Clear error after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _pinDotController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _buildBackgroundDecoration(),
          child: const Center(
            child: CupertinoActivityIndicator(
              radius: 16,
              color: CupertinoColors.white,
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _buildBackgroundDecoration(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: _buildLockContent(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.8),
          AppColors.primary,
          AppColors.primary.withOpacity(0.9),
        ],
        stops: const [0.0, 0.6, 1.0],
      ),
    );
  }

  Widget _buildLockContent() {
    return Column(
      children: [
        // Top spacer
        const Spacer(flex: 2),

        // App branding section
        _buildAppBranding(),

        const Spacer(flex: 1),

        // Authentication section
        _buildAuthenticationSection(),

        const Spacer(flex: 2),

        // Error message
        if (_errorMessage.isNotEmpty)
          _buildErrorMessage(),

        const Spacer(),

        // Bottom actions
        if (_lockType == 'biometric' && !_isAuthenticating)
          _buildBottomActions(),
      ],
    );
  }

  Widget _buildAppBranding() {
    return Column(
      children: [
        // App icon with animated pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_pulseAnimation.value * 0.05),
              child: Container(
                width: ResponsiveUtils.scaledContainerSize(context, 120),
                height: ResponsiveUtils.scaledContainerSize(context, 120),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  size: ResponsiveUtils.scaledIconSize(context, 60),
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
            fontSize: ResponsiveUtils.scaledFontSize(context, 32, maxScale: 1.4),
            fontWeight: FontWeight.w800,
            color: CupertinoColors.white,
            fontFamily: '.SF Pro Text',
          ),
        ),

        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 8)),

        // Subtitle
        Text(
          _lockType == 'biometric'
              ? 'Use Face ID or Touch ID to unlock'
              : 'Enter your PIN to continue',
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
            color: CupertinoColors.white.withOpacity(0.8),
            fontFamily: '.SF Pro Text',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthenticationSection() {
    if (_lockType == 'biometric') {
      return _buildBiometricAuth();
    } else {
      return _buildPinAuth();
    }
  }

  Widget _buildBiometricAuth() {
    return Column(
      children: [
        // Biometric icon with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: ResponsiveUtils.scaledContainerSize(context, 100),
              height: ResponsiveUtils.scaledContainerSize(context, 100),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.white.withOpacity(0.15),
                border: Border.all(
                  color: CupertinoColors.white.withOpacity(0.3 + (_pulseAnimation.value * 0.3)),
                  width: 2,
                ),
              ),
              child: Center(
                child: _isAuthenticating
                    ? CupertinoActivityIndicator(
                  radius: ResponsiveUtils.scaledIconSize(context, 20),
                  color: CupertinoColors.white,
                )
                    : Icon(
                  CupertinoIcons.lock_shield,
                  size: ResponsiveUtils.scaledIconSize(context, 50),
                  color: CupertinoColors.white,
                ),
              ),
            );
          },
        ),

        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 24)),

        Text(
          _isAuthenticating
              ? 'Authenticating...'
              : 'Touch the sensor or look at your device',
          style: TextStyle(
            fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
            color: CupertinoColors.white.withOpacity(0.9),
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
        // PIN dots display
        _buildPinDots(),

        SizedBox(height: ResponsiveUtils.scaledSpacing(context, 40)),

        // PIN keypad
        _buildPinKeypad(),
      ],
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index < _enteredPin.length;
        final hasError = _showPinError;

        return AnimatedBuilder(
          animation: _pinDotAnimation,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.scaledSpacing(context, 12),
              ),
              child: Transform.scale(
                scale: (isActive && index == _enteredPin.length - 1)
                    ? 1.0 + (_pinDotAnimation.value * 0.3)
                    : 1.0,
                child: Container(
                  width: ResponsiveUtils.scaledContainerSize(context, 20),
                  height: ResponsiveUtils.scaledContainerSize(context, 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? (hasError ? AppColors.error : CupertinoColors.white)
                        : CupertinoColors.white.withOpacity(0.3),
                    border: Border.all(
                      color: hasError
                          ? AppColors.error
                          : CupertinoColors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildPinKeypad() {
    return Container(
      width: ResponsiveUtils.scaledContainerSize(context, 260),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          _buildKeypadRow(['1', '2', '3']),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 20)),

          // Row 2: 4, 5, 6
          _buildKeypadRow(['4', '5', '6']),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 20)),

          // Row 3: 7, 8, 9
          _buildKeypadRow(['7', '8', '9']),
          SizedBox(height: ResponsiveUtils.scaledSpacing(context, 20)),

          // Row 4: empty, 0, backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: ResponsiveUtils.scaledContainerSize(context, 70)),
              _buildKeypadButton('0'),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildKeypadButton(number)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isAuthenticating ? null : () => _handlePinInput(digit),
      child: Container(
        width: ResponsiveUtils.scaledContainerSize(context, 70),
        height: ResponsiveUtils.scaledContainerSize(context, 70),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.white.withOpacity(0.1),
          border: Border.all(
            color: CupertinoColors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: ResponsiveUtils.scaledFontSize(context, 28, maxScale: 1.3),
              fontWeight: FontWeight.w300,
              color: CupertinoColors.white,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isAuthenticating ? null : _clearPin,
      child: Container(
        width: ResponsiveUtils.scaledContainerSize(context, 70),
        height: ResponsiveUtils.scaledContainerSize(context, 70),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.white.withOpacity(0.1),
          border: Border.all(
            color: CupertinoColors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.delete_left,
            size: ResponsiveUtils.scaledIconSize(context, 24),
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 32),
      ),
      padding: ResponsiveUtils.scaledPadding(
        context,
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: ResponsiveUtils.scaledIconSize(context, 16),
            color: CupertinoColors.white,
          ),
          SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
          Flexible(
            child: Text(
              _errorMessage,
              style: TextStyle(
                fontSize: ResponsiveUtils.scaledFontSize(context, 14, maxScale: 1.3),
                color: CupertinoColors.white,
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

  Widget _buildBottomActions() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaledSpacing(context, 32),
      ),
      child: Column(
        children: [
          // Try again button for biometric
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _authenticateBiometric,
            child: Container(
              width: double.infinity,
              height: ResponsiveUtils.scaledButtonHeight(context, baseHeight: 50),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CupertinoColors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: ResponsiveUtils.scaledIconSize(context, 18),
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: ResponsiveUtils.scaledSpacing(context, 8)),
                  Text(
                    'Try Again',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: ResponsiveUtils.scaledFontSize(context, 16, maxScale: 1.3),
                      fontWeight: FontWeight.w600,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}