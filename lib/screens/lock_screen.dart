// lib/screens/lock_screen.dart - COMPLETE MODERN iOS REDESIGN
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lock_service.dart';
import '../utils/colors.dart';
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
  bool _hasAttemptedBiometric = false; // ← ADD THIS

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _pinDotController;


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
      _hasAttemptedBiometric = true; // ← MARK THAT WE'VE TRIED
      _errorMessage = '';
    });

    try {
      final authenticated = await _lockService.authenticateBiometric();

      if (authenticated && mounted) {
        HapticFeedback.lightImpact();
        widget.onUnlocked();
      } else {
        _showError('Authentication failed');
        _triggerErrorAnimation();
      }
    } catch (e) {
      _showError('Authentication error');
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

    // Calculate scale factor based on screen size
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    double scaleFactor = 1.07;

    if (screenWidth < 380 || screenHeight < 700) {
      scaleFactor = 0.90;
    }
    if (screenWidth < 350 || screenHeight < 650) {
      scaleFactor = 0.85;
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _buildBackgroundDecoration(),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                _buildAppBranding(scaleFactor),

                const Spacer(flex: 1),

                _buildAuthenticationSection(scaleFactor),

                const Spacer(flex: 2),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16 * scaleFactor),
                    child: _buildErrorMessage(scaleFactor),
                  ),

                if (_lockType == 'biometric' && _hasAttemptedBiometric &&
                    !_isAuthenticating)
                  Padding(
                    padding: EdgeInsets.only(bottom: 20 * scaleFactor),
                    child: _buildBottomActions(scaleFactor),
                  ),
              ],
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


  Widget _buildAppBranding(double scale) {
    return Column(
      children: [
        Container(
          width: 120 * scale,
          height: 120 * scale,
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
            size: 60 * scale,
            color: CupertinoColors.white,
          ),
        ),

        SizedBox(height: 24 * scale),

        Text(
          'Alongside',
          style: TextStyle(
            fontSize: 32 * scale,
            fontWeight: FontWeight.w800,
            color: CupertinoColors.white,
            fontFamily: '.SF Pro Text',
          ),
          textScaler: TextScaler.noScaling,
        ),

        SizedBox(height: 8 * scale),

        Text(
          _lockType == 'biometric'
              ? 'Use biometric authentication to unlock'
              : 'Enter your PIN to unlock',
          style: TextStyle(
            fontSize: 16 * scale,
            color: CupertinoColors.white.withOpacity(0.8),
            fontFamily: '.SF Pro Text',
          ),
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
        ),
      ],
    );
  }

  Widget _buildAuthenticationSection(double scale) {
    if (_lockType == 'biometric') {
      return _buildBiometricAuth(scale);
    } else {
      return _buildPinAuth(scale);
    }
  }

  Widget _buildBiometricAuth(double scale) {
    return Column(
      children: [
        Icon(
          CupertinoIcons.lock_shield_fill,
          size: 60 * scale,
          color: Colors.white.withOpacity(0.9),
        ),

        SizedBox(height: 24 * scale),

        Text(
          _isAuthenticating
              ? 'Authenticating...'
              : 'Authenticate to unlock',
          style: TextStyle(
            fontSize: 16 * scale,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            fontFamily: '.SF Pro Text',
          ),
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
        ),
      ],
    );
  }

  Widget _buildPinAuth(double scale) {
    return Column(
      children: [
        // PIN Display Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _enteredPin.length;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 8 * scale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 60 * scale,
                height: 70 * scale,
                decoration: BoxDecoration(
                  color: _showPinError
                      ? AppColors.error.withOpacity(0.2)
                      : Colors.white.withOpacity(isFilled ? 0.3 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showPinError
                        ? AppColors.error
                        : isFilled
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isFilled
                      ? Container(
                    width: 16 * scale,
                    height: 16 * scale,
                    decoration: BoxDecoration(
                      color: _showPinError ? AppColors.error : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                      : null,
                ),
              ),
            );
          }),
        ),

        SizedBox(height: 40 * scale),

        // Keypad
        Container(
          padding: EdgeInsets.symmetric(horizontal: 32 * scale),
          child: Column(
            children: [
              _buildKeypadRow(['1', '2', '3'], scale),
              SizedBox(height: 16 * scale),
              _buildKeypadRow(['4', '5', '6'], scale),
              SizedBox(height: 16 * scale),
              _buildKeypadRow(['7', '8', '9'], scale),
              SizedBox(height: 16 * scale),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 70 * scale),
                  _buildKeypadButton('0', scale),
                  _buildBackspaceButton(scale),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers
          .map((number) => _buildKeypadButton(number, scale))
          .toList(),
    );
  }

  Widget _buildKeypadButton(String digit, double scale) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isAuthenticating ? null : () => _handlePinInput(digit),
      child: Container(
        width: 70 * scale,
        height: 70 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 28 * scale,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              fontFamily: '.SF Pro Text',
            ),
            textScaler: TextScaler.noScaling,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(double scale) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isAuthenticating ? null : _clearPin,
      child: Container(
        width: 70 * scale,
        height: 70 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.delete_left,
            size: 24 * scale,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32 * scale),
      padding: EdgeInsets.symmetric(
          horizontal: 20 * scale, vertical: 12 * scale),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 16 * scale,
            color: CupertinoColors.white,
          ),
          SizedBox(width: 8 * scale),
          Flexible(
            child: Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14 * scale,
                color: CupertinoColors.white,
                fontFamily: '.SF Pro Text',
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(double scale) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _authenticateBiometric,
      child: Container(
        width: 60 * scale,
        height: 60 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.white.withOpacity(0.15),
          border: Border.all(
            color: CupertinoColors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          CupertinoIcons.arrow_clockwise,
          size: 24 * scale,
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}