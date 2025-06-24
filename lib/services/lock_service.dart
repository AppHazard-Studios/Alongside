// lib/services/lock_service.dart - With 5-minute cooldown
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

  // Enable biometric lock
  Future<bool> enableBiometricLock() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockEnabledKey, true);
      await prefs.setString(_lockTypeKey, 'biometric');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Enable PIN lock
  Future<bool> enablePinLock(String pin) async {
    if (pin.length < 4) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, true);
    await prefs.setString(_lockTypeKey, 'pin');
    await prefs.setString(_lockPinKey, pin);
    return true;
  }

  // Disable lock
  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.remove(_lockTypeKey);
    await prefs.remove(_lockPinKey);
    await prefs.remove(_backgroundTimeKey);
  }

  // Authenticate with biometric
  Future<bool> authenticateBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Alongside',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return authenticated;
    } catch (e) {
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
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }
}