import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:street_buddy/services/image_url_service.dart';

/// Service that handles background tasks for the application
class BackgroundTaskService {
  static final BackgroundTaskService _instance =
      BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  Timer? _imageValidationTimer;
  final ImageUrlService _imageUrlService = ImageUrlService();

  /// Start background services
  void startBackgroundTasks() {
    // Start periodic image validation every 6 hours
    _startImageValidationTask();
    debugPrint('✅ Background task service started');
  }

  /// Stop all background services
  void stopBackgroundTasks() {
    _imageValidationTimer?.cancel();
    _imageValidationTimer = null;
    debugPrint('🛑 Background task service stopped');
  }

  /// Start periodic image URL validation task
  void _startImageValidationTask() {
    _imageValidationTimer?.cancel();

    // Run every 6 hours (no initial delay)
    _imageValidationTimer = Timer.periodic(const Duration(hours: 6), (timer) {
      debugPrint('🔄 Running scheduled image validation...');
      _imageUrlService.validateAndRefreshExpiredImages();
    });

    debugPrint('⏰ Image validation task scheduled every 6 hours');
  }

  /// Force run image validation immediately
  Future<void> forceImageValidation() async {
    debugPrint('🔄 Force running image validation...');
    await _imageUrlService.validateAndRefreshExpiredImages();
  }

  /// Clear image validation cache
  void clearImageCache() {
    _imageUrlService.clearValidationCache();
    debugPrint('🗑️ Image validation cache cleared');
  }
}
