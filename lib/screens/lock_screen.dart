import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/lock_service.dart';
import '../utils/colors.dart';
import '../widgets/illustrations.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({
    Key? key,
    required this.onUnlocked,
  }) : super(key: key);

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LockService _lockService = LockService();
  final TextEditingController _pinController = TextEditingController();

  String? _lockType;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeLock();
  }

  Future<void> _initializeLock() async {
    final lockType = await _lockService.getLockType();
    setState(() {
      _lockType = lockType;
      _isLoading = false;
    });

    // Auto-trigger biometric if enabled
    if (lockType == 'biometric') {
      _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    final authenticated = await _lockService.authenticateBiometric();
    if (authenticated) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'Authentication failed. Try again.';
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    final verified = await _lockService.verifyPin(_pinController.text);
    if (verified) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN';
        _pinController.clear();
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon/illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Illustrations.friendsIllustration(size: 120),
              ),

              const SizedBox(height: 48),

              const Text(
                'Alongside',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: '.SF Pro Text',
                ),
              ),

              const SizedBox(height: 48),

              if (_lockType == 'pin') ...[
                // PIN input
                CupertinoTextField(
                  controller: _pinController,
                  placeholder: 'Enter PIN',
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontFamily: '.SF Pro Text',
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _errorMessage.isNotEmpty
                          ? AppColors.error
                          : CupertinoColors.systemGrey5,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),

                const SizedBox(height: 24),

                CupertinoButton(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _verifyPin,
                  child: const Text(
                    'Unlock',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: '.SF Pro Text',
                    ),
                  ),
                ),
              ] else ...[
                // Biometric button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _authenticateBiometric,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: CupertinoColors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Tap to authenticate',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.error,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}