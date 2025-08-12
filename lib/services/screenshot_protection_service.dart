import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

/// Enum defining screen types with different security levels
enum ScreenSecurityLevel {
  /// Public screens like home feed, explore, etc.
  public,

  /// Screens with personal info like profile, settings
  personal,

  /// Screens with sensitive data like payments, messages
  sensitive,

  /// Screens with highly confidential data
  confidential
}

class ScreenshotProtectionService {
  static bool _isProtectionEnabled = false;
  static bool _isGloballyEnabled = false;
  static final Map<String, bool> _protectedRoutes = {};

  // Define which security levels should have protection by default
  static final Map<ScreenSecurityLevel, bool> _securityDefaults = {
    ScreenSecurityLevel.public: false,
    ScreenSecurityLevel.personal: false,
    ScreenSecurityLevel.sensitive: true,
    ScreenSecurityLevel.confidential: true,
  };

  /// Enable screenshot protection globally (app-wide)
  static Future<void> enableProtection() async {
    if (_isProtectionEnabled) return;

    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      _isProtectionEnabled = true;
      _isGloballyEnabled = true;
      debugPrint('✅ Screenshot protection enabled globally');
    } catch (e) {
      debugPrint('⚠️ Error enabling screenshot protection: $e');
    }
  }

  /// Disable screenshot protection globally
  static Future<void> disableProtection() async {
    if (!_isProtectionEnabled) return;

    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      _isProtectionEnabled = false;
      _isGloballyEnabled = false;
      debugPrint('✅ Screenshot protection disabled globally');
    } catch (e) {
      debugPrint('⚠️ Error disabling screenshot protection: $e');
    }
  }

  /// Force disable screenshot protection regardless of current state
  static Future<void> forceDisableProtection() async {
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      _isProtectionEnabled = false;
      _isGloballyEnabled = false;
      debugPrint('✅ Screenshot protection force disabled');
    } catch (e) {
      debugPrint('⚠️ Error force disabling screenshot protection: $e');
    }
  }

  /// Enable protection for a specific route/screen
  static Future<void> enableForScreen(String routeName) async {
    _protectedRoutes[routeName] = true;
    debugPrint('✅ Screenshot protection enabled for route: $routeName');

    // If this is the current screen and global protection is not on,
    // enable protection now
    if (!_isGloballyEnabled && !_isProtectionEnabled) {
      try {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        _isProtectionEnabled = true;
        debugPrint('✅ Screenshot protection activated for current screen');
      } catch (e) {
        debugPrint('⚠️ Error enabling screenshot protection for screen: $e');
      }
    }
  }

  /// Disable protection for a specific route/screen
  static Future<void> disableForScreen(String routeName) async {
    _protectedRoutes[routeName] = false;
    debugPrint('✅ Screenshot protection disabled for route: $routeName');
  }

  /// Check if a specific route/screen should have protection
  static bool isScreenProtected(String routeName) {
    return _protectedRoutes[routeName] ?? false;
  }

  /// Enable or disable protection based on current route
  static Future<void> updateProtectionForRoute(String routeName) async {
    if (_isGloballyEnabled) return; // Don't change if globally enabled

    bool shouldProtect = isScreenProtected(routeName);

    if (shouldProtect && !_isProtectionEnabled) {
      try {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        _isProtectionEnabled = true;
        debugPrint('✅ Screenshot protection activated for route: $routeName');
      } catch (e) {
        debugPrint('⚠️ Error enabling protection for route: $e');
      }
    } else if (!shouldProtect && _isProtectionEnabled) {
      try {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        _isProtectionEnabled = false;
        debugPrint('✅ Screenshot protection deactivated for route: $routeName');
      } catch (e) {
        debugPrint('⚠️ Error disabling protection for route: $e');
      }
    }
  }

  /// Configure protection based on screen security level
  static void configureProtectionBySecurityLevel(
      String routeName, ScreenSecurityLevel level) {
    bool shouldProtect = _securityDefaults[level] ?? false;
    _protectedRoutes[routeName] = shouldProtect;
    debugPrint(
        '🔒 Route $routeName configured with security level: $level (protected: $shouldProtect)');
  }

  /// Check if screenshot protection is currently enabled
  static bool get isProtectionEnabled => _isProtectionEnabled;

  /// Check if screenshot protection is globally enabled
  static bool get isGloballyEnabled => _isGloballyEnabled;

  /// Reset state (for testing purposes)
  static void resetState() {
    _isProtectionEnabled = false;
    _isGloballyEnabled = false;
    _protectedRoutes.clear();
  }
}
