import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:street_buddy/services/settings_service.dart';

/// Location usage context to determine optimal polling frequency
enum LocationUsageContext {
  activeNavigation, // User is actively navigating
  mapViewing, // User is viewing the map
  backgroundTracking, // App is in background but tracking location
  dataSaverMode, // User has data saver enabled
}

/// Optimized location service that adapts polling frequency based on usage patterns
class OptimizedLocationService {
  static final OptimizedLocationService _instance =
      OptimizedLocationService._();

  factory OptimizedLocationService() => _instance;

  OptimizedLocationService._();

  final SettingsService _settingsService = SettingsService();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastKnownPosition;
  DateTime? _lastLocationUpdate;

  // Location accuracy levels
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;

  // Polling intervals in milliseconds
  static const int _highFrequencyInterval =
      1000; // 1 second - for active navigation
  static const int _mediumFrequencyInterval =
      5000; // 5 seconds - for map viewing
  static const int _lowFrequencyInterval = 30000; // 30 seconds - for background
  static const int _batteryOptimizedInterval =
      60000; // 1 minute - for data saver mode

  int _currentInterval = _mediumFrequencyInterval;

  LocationUsageContext _currentContext = LocationUsageContext.mapViewing;

  /// Start optimized location tracking based on context
  Stream<Position> startLocationTracking({
    required LocationUsageContext context,
    Function(Position)? onLocationUpdate,
  }) {
    _currentContext = context;
    _updateLocationSettings();

    debugPrint(
        '🗺️ Starting optimized location tracking for context: $context');
    debugPrint('   - Accuracy: $_currentAccuracy');
    debugPrint('   - Interval: ${_currentInterval}ms');

    // Create optimized location settings
    final locationSettings = _getOptimizedLocationSettings();

    // Start position stream
    final positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );

    _positionStreamSubscription = positionStream.listen(
      (Position position) {
        _lastKnownPosition = position;
        _lastLocationUpdate = DateTime.now();

        if (onLocationUpdate != null) {
          onLocationUpdate(position);
        }
      },
      onError: (error) {
        debugPrint('⚠️ Location error: $error');
      },
    );

    return positionStream;
  }

  /// Update location settings based on current context and device state
  void _updateLocationSettings() {
    // Adjust based on data saver mode
    if (_settingsService.dataSaverMode) {
      _currentContext = LocationUsageContext.dataSaverMode;
    }

    // Set interval based on context
    switch (_currentContext) {
      case LocationUsageContext.activeNavigation:
        _currentInterval = _highFrequencyInterval;
        _currentAccuracy = LocationAccuracy.best;
        break;
      case LocationUsageContext.mapViewing:
        _currentInterval = _mediumFrequencyInterval;
        _currentAccuracy = LocationAccuracy.high;
        break;
      case LocationUsageContext.backgroundTracking:
        _currentInterval = _lowFrequencyInterval;
        _currentAccuracy = LocationAccuracy.medium;
        break;
      case LocationUsageContext.dataSaverMode:
        _currentInterval = _batteryOptimizedInterval;
        _currentAccuracy = LocationAccuracy.low;
        break;
    }
  }

  /// Get optimized location settings for current context
  LocationSettings _getOptimizedLocationSettings() {
    return LocationSettings(
      accuracy: _currentAccuracy,
      distanceFilter: _getDistanceFilter(),
      timeLimit: Duration(
          milliseconds: _currentInterval * 2), // Timeout after 2x interval
    );
  }

  /// Get distance filter based on current context
  int _getDistanceFilter() {
    switch (_currentContext) {
      case LocationUsageContext.activeNavigation:
        return 1; // Update every 1 meter during navigation
      case LocationUsageContext.mapViewing:
        return 5; // Update every 5 meters when viewing map
      case LocationUsageContext.backgroundTracking:
        return 25; // Update every 25 meters in background
      case LocationUsageContext.dataSaverMode:
        return 50; // Update every 50 meters in data saver mode
    }
  }

  /// Change location tracking context dynamically
  void updateLocationContext(LocationUsageContext newContext) {
    if (_currentContext != newContext) {
      debugPrint(
          '🗺️ Updating location context from $_currentContext to $newContext');
      _currentContext = newContext;
      _updateLocationSettings();

      // Restart tracking with new settings if currently active
      if (_positionStreamSubscription != null) {
        stopLocationTracking();
        startLocationTracking(context: newContext);
      }
    }
  }

  /// Get the last known position without requesting a new one
  Position? getLastKnownPosition() {
    return _lastKnownPosition;
  }

  /// Get a one-time position with optimal accuracy for the current context
  Future<Position> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _getOptimizedLocationSettings(),
      );

      _lastKnownPosition = position;
      _lastLocationUpdate = DateTime.now();

      return position;
    } catch (e) {
      debugPrint('⚠️ Error getting current position: $e');

      // Fallback to last known position if available
      if (_lastKnownPosition != null) {
        return _lastKnownPosition!;
      }

      rethrow;
    }
  }

  /// Stop location tracking to save battery
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    debugPrint('🗺️ Stopped location tracking');
  }

  /// Check if location tracking is currently active
  bool get isTrackingLocation => _positionStreamSubscription != null;

  /// Get current tracking statistics
  Map<String, dynamic> getTrackingStats() {
    return {
      'isTracking': isTrackingLocation,
      'context': _currentContext.toString(),
      'accuracy': _currentAccuracy.toString(),
      'interval': _currentInterval,
      'lastUpdate': _lastLocationUpdate?.toIso8601String(),
      'lastPosition': _lastKnownPosition != null
          ? {
              'latitude': _lastKnownPosition!.latitude,
              'longitude': _lastKnownPosition!.longitude,
              'accuracy': _lastKnownPosition!.accuracy,
            }
          : null,
    };
  }

  /// Dispose of resources
  void dispose() {
    stopLocationTracking();
  }
}
