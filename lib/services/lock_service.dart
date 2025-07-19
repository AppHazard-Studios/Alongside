// COMPLETE REPLACEMENT for lib/services/lock_service.dart
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class LockService {
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _lockPinKey = 'app_lock_pin';
  static const String _lockTypeKey = 'app_lock_type'; // 'biometric' or 'pin'
  static const String _backgroundTimeKey = 'app_background_time';
  static const String _lockCooldownKey = 'lock_cooldown_minutes';

  // Default cooldown is 5 minutes
  static const int _defaultCooldownMinutes = 5;

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if lock is enabled
  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  // Get lock type
  Future<String?> getLockType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockTypeKey);
  }

  // Get cooldown minutes
  Future<int> getCooldownMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lockCooldownKey) ?? _defaultCooldownMinutes;
  }

  // Set cooldown minutes
  Future<void> setCooldownMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lockCooldownKey, minutes);
  }

  // Record when app goes to background
  Future<void> recordBackgroundTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundTimeKey, DateTime.now().millisecondsSinceEpoch);
    print("🔒 Recorded background time: ${DateTime.now()}");
  }

  // Clear background time (when app is active)
  Future<void> clearBackgroundTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundTimeKey);
    print("🔓 Cleared background time");
  }

  // Check if we should show lock screen based on cooldown
  Future<bool> shouldShowLockScreen() async {
    final isEnabled = await isLockEnabled();
    if (!isEnabled) return false;

    final prefs = await SharedPreferences.getInstance();
    final backgroundTime = prefs.getInt(_backgroundTimeKey);

    if (backgroundTime == null) {
      // No background time recorded, don't lock
      return false;
    }

    final backgroundDateTime = DateTime.fromMillisecondsSinceEpoch(backgroundTime);
    final now = DateTime.now();
    final difference = now.difference(backgroundDateTime);
    final cooldownMinutes = await getCooldownMinutes();

    print("🔒 Background duration: ${difference.inMinutes} minutes");
    print("🔒 Cooldown required: $cooldownMinutes minutes");

    // Only show lock if app was in background for longer than cooldown
    final shouldLock = difference.inMinutes >= cooldownMinutes;

    if (shouldLock) {
      // Clear the background time so we don't lock again until next background
      await clearBackgroundTime();
    }

    return shouldLock;
  }

  // FIXED: Enable biometric lock without immediate authentication test
  Future<BiometricSetupResult> enableBiometricLockWithoutTest() async {
    try {
      // Check if biometric is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return BiometricSetupResult(
          success: false,
          error: 'Biometric authentication is not available on this device',
        );
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return BiometricSetupResult(
          success: false,
          error: 'No biometric data enrolled. Please set up Face ID or Touch ID in device settings',
        );
      }

      // FIXED: Don't authenticate during setup - just enable it
      // Save settings directly without authentication test
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockEnabledKey, true);
      await prefs.setString(_lockTypeKey, 'biometric');

      print("🔐 Biometric lock enabled without authentication test");
      return BiometricSetupResult(success: true);

    } catch (e) {
      print("🔐 Biometric setup error: $e");
      return BiometricSetupResult(
        success: false,
        error: 'Failed to set up biometric lock: ${e.toString()}',
      );
    }
  }

  // Enable biometric lock with proper authentication check (original method)
  Future<BiometricSetupResult> enableBiometricLock() async {
    try {
      // Check if biometric is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return BiometricSetupResult(
          success: false,
          error: 'Biometric authentication is not available on this device',
        );
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return BiometricSetupResult(
          success: false,
          error: 'No biometric data enrolled. Please set up fingerprint or face authentication in device settings',
        );
      }

      // Authenticate to confirm biometric setup
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric lock for Alongside',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false, // Allow fallback to device credential
            sensitiveTransaction: true,
            useErrorDialogs: true,
          ),
        );

        if (!authenticated) {
          return BiometricSetupResult(
            success: false,
            error: 'Authentication failed. Please try again',
          );
        }

        // Save settings only after successful authentication
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_lockEnabledKey, true);
        await prefs.setString(_lockTypeKey, 'biometric');

        return BiometricSetupResult(success: true);
      } on PlatformException catch (e) {
        print("🔐 Biometric setup error: ${e.code} - ${e.message}");
        return BiometricSetupResult(
          success: false,
          error: _getBiometricErrorMessage(e.code),
        );
      }
    } catch (e) {
      print("🔐 Biometric setup error: $e");
      return BiometricSetupResult(
        success: false,
        error: 'Failed to set up biometric lock: ${e.toString()}',
      );
    }
  }

  // Helper to get user-friendly error messages
  String _getBiometricErrorMessage(String code) {
    switch (code) {
      case 'NotAvailable':
        return 'Biometric authentication is not available';
      case 'NotEnrolled':
        return 'No biometric data found. Please enroll fingerprint or face in device settings';
      case 'LockedOut':
        return 'Too many failed attempts. Please try again later';
      case 'PermanentlyLockedOut':
        return 'Biometric authentication is locked. Please use device passcode';
      case 'PasscodeNotSet':
        return 'Device passcode not set. Please set up a passcode first';
      case 'OtherOperatingSystem':
        return 'Biometric authentication is not supported on this OS version';
      default:
        return 'Biometric setup failed. Please try again';
    }
  }

  // UPDATED: Enhanced PIN validation for exactly 4 digits
  Future<bool> enablePinLock(String pin) async {
    // Strict validation: exactly 4 digits
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      print("🔐 Invalid PIN format: must be exactly 4 digits");
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockEnabledKey, true);
      await prefs.setString(_lockTypeKey, 'pin');
      await prefs.setString(_lockPinKey, pin);

      print("🔐 4-digit PIN lock enabled successfully");
      return true;
    } catch (e) {
      print("🔐 Error enabling PIN lock: $e");
      return false;
    }
  }

  // Disable lock
  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.remove(_lockTypeKey);
    await prefs.remove(_lockPinKey);
    await prefs.remove(_backgroundTimeKey);
  }

  // Authenticate with biometric - FIXED for Android
  Future<bool> authenticateBiometric() async {
    try {
      // Check if biometric is available first
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        print("🔐 Biometric not available");
        return false;
      }

      // Check if biometrics are enrolled
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        print("🔐 No biometrics enrolled");
        return false;
      }

      // Authenticate with Android-friendly options
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Alongside',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // CRITICAL: Allow fallback on Android
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      print("🔐 Biometric authentication error: ${e.code} - ${e.message}");

      // Handle specific error codes
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        // These are expected errors, not failures
        return false;
      }

      // For other errors, throw to handle upstream
      rethrow;
    } catch (e) {
      print("🔐 Biometric authentication error: $e");
      return false;
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_lockPinKey);
    return storedPin == pin;
  }

  // Check if biometrics available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (isAvailable && isDeviceSupported) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
}

// Result class for biometric setup
class BiometricSetupResult {
  final bool success;
  final String? error;

  BiometricSetupResult({
    required this.success,
    this.error,
  });
}