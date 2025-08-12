import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionHandler {
  static final box = Hive.box('prefs');

  static bool isLocationEnabledInPrefs() {
    return box.get('location') ?? true;
  }

  static Future<bool> setLocationPermissionPreference(bool value) async {
    await box.put('location', value);

    if (value) {
      // When enabling location, immediately request the actual permission
      return await requestLocationPermission();
    }

    return true; // When disabling, the operation always succeeds
  }

  static Future<bool> requestLocationPermission() async {
    // Don't request if the preference is turned off
    if (!isLocationEnabledInPrefs()) {
      return false;
    }

    try {
      // First check if location services are enabled on the device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // We could potentially show a dialog asking the user to enable location services
        debugPrint('Location services are disabled');
        return false;
      }

      // Check current location permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // If permission is already granted, return true
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }

      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        // This will show the system permission dialog
        permission = await Geolocator.requestPermission();

        // Return true if permission was granted
        return permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      }

      // If permission is permanently denied, open app settings
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied, opening settings');
        await openAppSettings();
        return false;
      }

      return false; // Should not reach here, but just in case
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  static Future<bool> checkLocationPermission() async {
    if (!isLocationEnabledInPrefs()) {
      return false;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }
}
