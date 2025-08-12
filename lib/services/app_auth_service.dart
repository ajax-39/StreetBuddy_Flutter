import 'package:flutter/material.dart';
import 'package:street_buddy/services/biometrics_service.dart';

class AppAuthService {
  static final AppAuthService _instance = AppAuthService._internal();
  factory AppAuthService() => _instance;
  AppAuthService._internal();

  final BiometricsService _biometricsService = BiometricsService();
  bool _isAuthenticated = false;

  // Call this when app starts or resumes from background
  Future<bool> authenticateWithBiometricsIfNeeded(BuildContext? context) async {
    // If already authenticated, no need to check again
    if (_isAuthenticated) return true;

    // Check if biometrics is enabled in user settings
    final isBiometricEnabled =
        await _biometricsService.isBiometricLockEnabled();
    if (!isBiometricEnabled) {
      _isAuthenticated = true;
      return true; // If not enabled, allow access
    }

    // Check if device supports biometrics
    final isAvailable = await _biometricsService.isBiometricsAvailable();
    if (!isAvailable) {
      _isAuthenticated = true;
      return true; // If not available, allow access
    }

    // Authenticate with biometrics
    bool result = await _biometricsService.authenticateWithBiometrics();
    _isAuthenticated = result;

    if (!result && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication failed. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    return result;
  }

  // Call this when app is about to become inactive
  void resetAuthentication() {
    _isAuthenticated = false;
  }
}
