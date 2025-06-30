// lib/screens/lock_screen.dart - REPLACE ENTIRE FILE
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/lock_service.dart';
import '../utils/colors.dart';
import '../widgets/illustrations.dart';
import 'dart:async';

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
  late AnimationController _iconAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _iconAnimation;

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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _shakeAnimation = Tween(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _iconAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.easeInOutBack,
    );

    _fadeController.forward();
    _iconAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeLock() async {
    final lockType = await _lockService.getLockType();
    setState(() {
      _lockType = lockType;
      _isLoading = false;
    });

    // Auto-trigger biometric if enabled
    if (lockType == 'biometric') {
      // Small delay for smooth UI
      Future.delayed(const Duration(milliseconds: 500), () {
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
          _errorMessage = 'Authentication failed. Try again.';
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
    _iconAnimationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: Center(
          child: CupertinoActivityIndicator(radius: 14),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  AppColors.primaryLight.withOpacity(0.3),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // App icon/illustration with animation
                    AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.9 + (_iconAnimation.value * 0.1),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Illustrations.friendsIllustration(size: 120),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _lockType == 'biometric'
                          ? 'Authenticate to continue'
                          : 'Enter your PIN to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Authentication area with shake animation
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: _buildAuthenticationArea(),
                    ),

                    // Error message
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                            fontFamily: '.SF Pro Text',
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Bottom action
                    if (_lockType == 'biometric' && !_isAuthenticating)
                      CupertinoButton(
                        onPressed: _authenticateBiometric,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.lock_shield_fill,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Try Again',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: '.SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthenticationArea() {
    if (_lockType == 'biometric') {
      return _buildBiometricAuth();
    } else {
      return _buildPinAuth();
    }
  }

  Widget _buildBiometricAuth() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: _isAuthenticating
                      ? CupertinoActivityIndicator(
                    radius: 20,
                    color: AppColors.primary,
                  )
                      : Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          _isAuthenticating ? 'Authenticating...' : 'Touch the sensor or use Face ID',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ],
    );
  }

  Widget _buildPinAuth() {
    return Column(
      children: [
        // PIN input field with beautiful styling
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorMessage.isNotEmpty
                  ? AppColors.error
                  : AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
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
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
            ),
            decoration: null,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            onSubmitted: (_) => _verifyPin(),
            onChanged: (value) {
              if (_errorMessage.isNotEmpty) {
                setState(() {
                  _errorMessage = '';
                });
              }
            },
          ),
        ),

        const SizedBox(height: 24),

        CupertinoButton(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          onPressed: _isAuthenticating ? null : _verifyPin,
          child: Container(
            width: 140,
            height: 44,
            child: Center(
              child: _isAuthenticating
                  ? const CupertinoActivityIndicator(
                color: CupertinoColors.white,
              )
                  : const Text(
                'Unlock',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}