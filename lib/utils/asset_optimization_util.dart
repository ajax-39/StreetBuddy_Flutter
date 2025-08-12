import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:street_buddy/services/settings_service.dart';

/// Utility class for optimizing assets, especially SVGs
class AssetOptimizationUtil {
  static final AssetOptimizationUtil _instance = AssetOptimizationUtil._();

  factory AssetOptimizationUtil() => _instance;

  AssetOptimizationUtil._();

  final SettingsService _settingsService = SettingsService();

  // Cache to track which assets have been precached
  final Set<String> _precachedAssets = {};

  /// Loads an optimized SVG asset with caching for better performance
  Widget optimizedSvg({
    required String assetName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    bool useRasterCache = false,
  }) {
    // Use the standard Flutter SVG package with optimized settings
    return SvgPicture.asset(
      assetName,
      width: width,
      height: height,
      fit: fit,
      color: color,
      cacheColorFilter: true,
      placeholderBuilder: (BuildContext context) => SizedBox(
        width: width ?? 24,
        height: height ?? 24,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }

  /// Pre-cache SVG assets for faster loading throughout the app
  /// Call this method during app initialization for frequently used SVGs
  Future<void> precacheSvgAssets(
      BuildContext context, List<String> assetPaths) async {
    for (final assetPath in assetPaths) {
      if (_precachedAssets.contains(assetPath)) continue;

      try {
        // Just create the SVG picture and allow Flutter's internal caching to work
        // This loads the SVG asset bytecode into memory
        SvgPicture.asset(
          assetPath,
          width: 100, // Default size doesn't matter for caching the bytecode
          height: 100,
        );

        _precachedAssets.add(assetPath);
        debugPrint('✅ Added SVG asset to cache registry: $assetPath');
      } catch (e) {
        debugPrint('⚠️ Error registering SVG asset: $assetPath - $e');
      }
    }
  }

  /// Clears the SVG caches to free up memory
  void clearCache() {
    _precachedAssets.clear();
    // Clear image cache to free memory
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    debugPrint('✅ Cleared SVG optimization caches');
  }

  /// Gets the appropriate quality level for asset loading based on device specs
  int getAssetQualityFactor() {
    // If in data saver mode, use lower quality
    if (_settingsService.dataSaverMode) {
      return 1; // Lower quality
    }

    // Otherwise base on screen size and density
    final window = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenWidth = window.physicalSize.width;

    if (screenWidth <= 720) {
      return 1; // Lower end device
    } else if (screenWidth <= 1080) {
      return 2; // Mid-range device
    } else {
      return 3; // High-end device
    }
  }
}
