import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:street_buddy/services/settings_service.dart';

/// Helper class for loading images with data saver optimizations
class OptimizedImageLoader {
  // Singleton instance
  static final OptimizedImageLoader _instance = OptimizedImageLoader._();

  // Factory constructor
  factory OptimizedImageLoader() => _instance;

  // Private constructor
  OptimizedImageLoader._();

  // Get the settings service
  final SettingsService _settingsService = SettingsService();

  /// Loads a network image with optimizations based on data saver mode
  Widget loadNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Get image quality based on data saver mode
    final imageQuality = _settingsService.getImageQuality();

    // If data saver mode is active, we might append a quality parameter to the URL
    // This is just an example - actual implementation depends on your image CDN
    String optimizedUrl = imageUrl;
    if (_settingsService.dataSaverMode) {
      // This is an example - modify according to your image service
      if (imageUrl.contains('?')) {
        optimizedUrl = '$imageUrl&quality=$imageQuality';
      } else {
        optimizedUrl = '$imageUrl?quality=$imageQuality';
      }
    }

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: _settingsService.dataSaverMode
          ? 400
          : null, // Lower resolution in memory
      memCacheHeight: _settingsService.dataSaverMode ? 400 : null,
      placeholder: (context, url) =>
          placeholder ??
          const Center(
            child: CircularProgressIndicator(),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          const Icon(
            Icons.error_outline,
            color: Colors.grey,
          ),
    );
  }

  /// Helper method to determine if we should preload images
  bool shouldPreloadImages() {
    return !_settingsService.dataSaverMode;
  }
}
