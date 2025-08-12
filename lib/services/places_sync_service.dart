import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/services/settings_service.dart';

/// Service responsible for syncing saved places while respecting user's network preferences
class PlacesSyncService {
  final SettingsService _settingsService;
  final Connectivity _connectivity = Connectivity();
  Timer? _syncTimer;
  bool _isSyncing = false;

  // Singleton pattern
  static PlacesSyncService? _instance;

  PlacesSyncService._({required SettingsService settingsService})
      : _settingsService = settingsService {
    // Initialize sync timer
    _setupSyncTimer();
    // Listen for connectivity changes
    _setupConnectivityListener();
  }

  factory PlacesSyncService({required SettingsService settingsService}) {
    _instance ??= PlacesSyncService._(settingsService: settingsService);
    return _instance!;
  }

  /// Sets up a periodic sync timer
  void _setupSyncTimer() {
    // Cancel any existing timer
    _syncTimer?.cancel();

    // Create a new timer that attempts sync every 15 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      attemptSync();
    });
  }

  /// Sets up a listener for connectivity changes
  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      // When connectivity changes (e.g., switching from mobile to WiFi),
      // try to sync if appropriate
      if (result.contains(ConnectivityResult.wifi)) {
        debugPrint('WiFi connected, checking if sync is needed');
        attemptSync();
      }
    });
  }

  /// Attempts to sync saved places based on current settings and connectivity
  Future<bool> attemptSync() async {
    // Don't attempt another sync if already syncing
    if (_isSyncing) return false;

    try {
      _isSyncing = true;

      // Check if sync is allowed based on user settings
      final canSync = await canSyncBasedOnSettings();

      if (!canSync) {
        debugPrint(
            'Sync blocked by settings: WiFi-only setting is ON and device is not on WiFi');
        return false;
      }

      // Perform the actual sync operation
      await _syncSavedPlaces();

      debugPrint('Places sync completed successfully');
      return true;
    } catch (e) {
      debugPrint('Places sync failed: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Checks if syncing is allowed based on current settings and network state
  Future<bool> canSyncBasedOnSettings() async {
    // If sync is disabled in settings, don't sync
    if (!_settingsService.syncSavedPlaces) {
      return false;
    }

    // If "sync over WiFi only" is enabled, check if we're on WiFi
    if (_settingsService.syncOverWifi) {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi);
    }

    // If "sync over WiFi only" is disabled, sync on any connection
    return true;
  }

  /// Performs the actual sync operation
  Future<void> _syncSavedPlaces() async {
    // In a real implementation, this would:
    // 1. Fetch saved places from local database
    // 2. Upload any new or modified saved places to the backend
    // 3. Download any new saved places from the backend
    // 4. Resolve conflicts if any

    // Simulating sync with a delay
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Syncing saved places...');
    // In real implementation: API calls would go here
  }

  /// Force sync regardless of timer (but still respects connectivity settings)
  Future<bool> forceSyncNow() async {
    return attemptSync();
  }

  /// Disposes resources
  void dispose() {
    _syncTimer?.cancel();
  }
}
