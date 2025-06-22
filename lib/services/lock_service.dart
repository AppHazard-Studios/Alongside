import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class LockService {
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _lockPinKey = 'app_lock_pin';
  static const String _lockTypeKey = 'app_lock_type'; // 'biometric' or 'pin'

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
