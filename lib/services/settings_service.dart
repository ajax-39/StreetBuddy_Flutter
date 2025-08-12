import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:street_buddy/services/screenshot_protection_service.dart';

class SettingsService with ChangeNotifier {
  // Keys for SharedPreferences
  static const String _dataSaverModeKey = 'data_saver_mode';
  static const String _backgroundDataUsageKey = 'background_data_usage';
  static const String _syncOverWifiKey = 'sync_over_wifi';
  static const String _autoUpdateAppKey = 'auto_update_app';
  static const String _syncSavedPlacesKey = 'sync_saved_places';
  static const String _screenshotProtectionKey = 'screenshot_protection';
  static const String _globalScreenshotProtectionKey =
      'global_screenshot_protection';
  // Default values
  bool _dataSaverMode = false; // Data saver mode disabled by default
  bool _backgroundDataUsage = true;
  bool _syncOverWifi = true;
  bool _autoUpdateApp = true;
  bool _syncSavedPlaces = true;
  bool _screenshotProtection =
      false; // Screenshot protection disabled by default
  bool _globalScreenshotProtection =
      false; // Screen-specific protection is default (more optimized)

  // Singleton instance
  static SettingsService? _instance;

  // Private constructor
  SettingsService._() {
    _loadSettings();
  }

  // Factory constructor to return the singleton instance
  factory SettingsService() {
    _instance ??= SettingsService._();
    return _instance!;
  }

  // Getters
  bool get dataSaverMode => _dataSaverMode;
  bool get backgroundDataUsage => _backgroundDataUsage;
  bool get syncOverWifi => _syncOverWifi;
  bool get autoUpdateApp => _autoUpdateApp;
  bool get syncSavedPlaces => _syncSavedPlaces;
  bool get screenshotProtection => _screenshotProtection;
  bool get globalScreenshotProtection => _globalScreenshotProtection;
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _dataSaverMode = prefs.getBool(_dataSaverModeKey) ??
        false; // Default to false (disabled)
    _backgroundDataUsage = prefs.getBool(_backgroundDataUsageKey) ?? true;
    _syncOverWifi = prefs.getBool(_syncOverWifiKey) ?? true;
    _autoUpdateApp = prefs.getBool(_autoUpdateAppKey) ?? true;
    _syncSavedPlaces = prefs.getBool(_syncSavedPlacesKey) ?? true;
    _screenshotProtection = prefs.getBool(_screenshotProtectionKey) ?? false;
    _globalScreenshotProtection =
        prefs.getBool(_globalScreenshotProtectionKey) ?? false;

    notifyListeners();
  }

  // Set Data Saver Mode
  Future<void> setDataSaverMode(bool value) async {
    if (_dataSaverMode != value) {
      _dataSaverMode = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dataSaverModeKey, value);
      notifyListeners();

      // You can log when this setting changes
      debugPrint('Data Saver Mode changed to: $value');
    }
  }

  // Set Sync Over WiFi setting
  Future<void> setSyncOverWifi(bool value) async {
    if (_syncOverWifi != value) {
      _syncOverWifi = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncOverWifiKey, value);
      notifyListeners();

      // Log when this setting changes
      debugPrint('Sync Over WiFi changed to: $value');
    }
  }

  // Set Sync Saved Places setting
  Future<void> setSyncSavedPlaces(bool value) async {
    if (_syncSavedPlaces != value) {
      _syncSavedPlaces = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncSavedPlacesKey, value);
      notifyListeners();

      // Log when this setting changes
      debugPrint('Sync Saved Places changed to: $value');
    }
  }

  // Set Background Data Usage
  Future<void> setBackgroundDataUsage(bool value) async {
    if (_backgroundDataUsage != value) {
      _backgroundDataUsage = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backgroundDataUsageKey, value);
      notifyListeners();

      // Log when this setting changes
      debugPrint('Background Data Usage changed to: $value');
    }
  }

  // Set Auto Update App
  Future<void> setAutoUpdateApp(bool value) async {
    if (_autoUpdateApp != value) {
      _autoUpdateApp = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoUpdateAppKey, value);
      notifyListeners();

      // Log when this setting changes
      debugPrint('Auto Update App changed to: $value');
    }
  }

  // Set Screenshot Protection
  Future<void> setScreenshotProtection(bool value) async {
    if (_screenshotProtection != value) {
      _screenshotProtection = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_screenshotProtectionKey, value);

      // Apply the protection immediately
      if (value) {
        // Apply based on whether global or screen-specific protection is enabled
        if (_globalScreenshotProtection) {
          await ScreenshotProtectionService.enableProtection();
        } else {
          // Just configure protection to be screen-specific
          await ScreenshotProtectionService.forceDisableProtection();
          // Note: The specific screens will enable protection as needed
        }
      } else {
        await ScreenshotProtectionService.forceDisableProtection();
      }

      notifyListeners();

      // Log when this setting changes
      debugPrint(
          'Screenshot Protection changed to: $value (global: $_globalScreenshotProtection)');
    }
  }

  // Set global screenshot protection mode
  Future<void> setGlobalScreenshotProtection(bool value) async {
    if (_globalScreenshotProtection != value) {
      _globalScreenshotProtection = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_globalScreenshotProtectionKey, value);

      // Apply the change immediately if screenshot protection is enabled
      if (_screenshotProtection) {
        if (value) {
          // Enable app-wide protection
          await ScreenshotProtectionService.enableProtection();
          debugPrint('✅ Switched to global screenshot protection');
        } else {
          // Switch to screen-specific protection
          await ScreenshotProtectionService.forceDisableProtection();
          debugPrint(
              '✅ Switched to screen-specific screenshot protection (optimized)');
          // Note: The specific screens will enable protection as needed
        }
      }

      notifyListeners();
    }
  }

  // Helper method to check if the device is connected to WiFi
  Future<bool> isConnectedToWifi() async {
    // Import connectivity_plus at the top of the file
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.wifi);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  // Helper method to determine image quality based on data saver mode
  int getImageQuality() {
    // If data saver mode is on, return lower quality (0-100)
    return _dataSaverMode ? 60 : 90;
  }

  // Helper method to determine if network operations should be performed
  Future<bool> shouldPerformNetworkOperation() async {
    if (_syncOverWifi) {
      // Check if we're connected to WiFi
      return await isConnectedToWifi();
    }
    return true; // Always allow if sync over WiFi is disabled
  }

  // Helper method to determine if saved places sync should be performed
  Future<bool> shouldSyncSavedPlaces() async {
    if (!_syncSavedPlaces) return false;

    if (_syncOverWifi) {
      return await isConnectedToWifi();
    }

    return true; // Sync allowed if "sync over WiFi" is disabled
  }

  // Reset all settings to defaults
  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataSaverModeKey);
    await prefs.remove(_backgroundDataUsageKey);
    await prefs.remove(_syncOverWifiKey);
    await prefs.remove(_autoUpdateAppKey);
    await prefs.remove(_syncSavedPlacesKey);
    await prefs.remove(_screenshotProtectionKey);

    _dataSaverMode = false; // Reset to disabled by default
    _backgroundDataUsage = true;
    _syncOverWifi = true;
    _autoUpdateApp = true;
    _syncSavedPlaces = true;
    _screenshotProtection = false;

    // Ensure screenshot protection is disabled when settings are reset
    await ScreenshotProtectionService.forceDisableProtection();

    notifyListeners();
  }
}
