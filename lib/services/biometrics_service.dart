import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

class BiometricsService {
  static final BiometricsService _instance = BiometricsService._internal();
  factory BiometricsService() => _instance;
  BiometricsService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_lock_enabled';

  Future<bool> isBiometricsAvailable() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      // Check if biometrics is enabled in settings
      if (!await isBiometricLockEnabled()) {
        return true; // If not enabled, return true to allow access
      }

      // Check if device supports biometrics
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) {
        return true; // If not available, bypass biometrics
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      if (e.toString().contains(auth_error.notAvailable)) {
        debugPrint('Biometrics not available on this device');
        return true; // Allow access if biometrics not available
      }
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  // Save biometric preference
  Future<void> setBiometricLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, value);
  }

  // Get biometric preference
  Future<bool> isBiometricLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
}
