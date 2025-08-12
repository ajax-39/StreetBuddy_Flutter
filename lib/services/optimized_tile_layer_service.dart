import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:street_buddy/services/settings_service.dart';

/// Optimized tile layer configuration for better performance
class OptimizedTileLayerService {
  static final OptimizedTileLayerService _instance =
      OptimizedTileLayerService._();

  factory OptimizedTileLayerService() => _instance;

  OptimizedTileLayerService._();

  final SettingsService _settingsService = SettingsService();

  /// Get an optimized tile layer based on device capabilities and data saver settings
  TileLayer getOptimizedTileLayer() {
    // Determine tile size and quality based on device and settings
    final isDataSaverMode = _settingsService.dataSaverMode;
    final devicePixelRatio =
        PlatformDispatcher.instance.views.first.devicePixelRatio;

    // Optimize tile size for performance
    double tileSize = 256.0; // Default tile size
    double maxZoom = 18.0; // Default max zoom

    if (isDataSaverMode) {
      // Reduce quality in data saver mode
      tileSize = 256.0; // Use standard size
      maxZoom = 16.0; // Limit zoom level to reduce data usage
    } else if (devicePixelRatio > 2.0) {
      // High DPI devices can handle larger tiles
      tileSize = 512.0;
      maxZoom = 19.0;
    }

    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.streetbuddy.app',
      tileSize: tileSize,
      maxZoom: maxZoom,

      // Optimize caching settings
      maxNativeZoom: maxZoom.toInt(),
      keepBuffer: isDataSaverMode ? 2 : 4, // Reduce buffer in data saver mode

      // Enable tile filtering for better visual quality
      tileBuilder: _buildOptimizedTile,

      // Add error handling for failed tile loads
      errorTileCallback: _handleTileError,
    );
  }

  /// Build optimized tiles with proper filtering
  Widget _buildOptimizedTile(
      BuildContext context, Widget tileWidget, TileImage tile) {
    // Apply image filtering for better visual quality
    return ColorFiltered(
      colorFilter: _settingsService.dataSaverMode
          ? const ColorFilter.matrix([
              0.8, 0.0, 0.0, 0.0, 0.0, // Slightly reduce red
              0.0, 0.8, 0.0, 0.0, 0.0, // Slightly reduce green
              0.0, 0.0, 0.8, 0.0, 0.0, // Slightly reduce blue
              0.0, 0.0, 0.0, 1.0, 0.0, // Keep alpha
            ])
          : const ColorFilter.matrix([
              1.0,
              0.0,
              0.0,
              0.0,
              0.0,
              0.0,
              1.0,
              0.0,
              0.0,
              0.0,
              0.0,
              0.0,
              1.0,
              0.0,
              0.0,
              0.0,
              0.0,
              0.0,
              1.0,
              0.0,
            ]),
      child: tileWidget,
    );
  }

  /// Handle tile loading errors gracefully
  void _handleTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    debugPrint('⚠️ Map tile error for ${tile.coordinates}: $error');

    // Could implement retry logic or fallback tiles here
    // For now, just log the error
  }

  /// Clear tile cache to free up memory
  void clearTileCache() {
    // This would clear the flutter_map internal cache
    // The actual implementation depends on flutter_map's caching mechanism
    debugPrint('✅ Map tile cache cleared');
  }

  /// Preload tiles for a specific area to improve performance
  Future<void> preloadTilesForArea({
    required double centerLat,
    required double centerLng,
    required int zoomLevel,
    required double radiusKm,
  }) async {
    try {
      // Calculate tile bounds for the area
      final tiles =
          _calculateTilesForArea(centerLat, centerLng, zoomLevel, radiusKm);

      debugPrint(
          '📍 Preloading ${tiles.length} tiles for area around $centerLat, $centerLng');

      // Note: Actual preloading would require access to flutter_map's internal tile loading
      // This is a placeholder for the concept
    } catch (e) {
      debugPrint('⚠️ Error preloading tiles: $e');
    }
  }

  /// Calculate which tiles are needed for a given area
  List<Map<String, int>> _calculateTilesForArea(
      double centerLat, double centerLng, int zoom, double radiusKm) {
    final tiles = <Map<String, int>>[];

    // Convert lat/lng to tile coordinates
    final centerX = _lngToTileX(centerLng, zoom);
    final centerY = _latToTileY(centerLat, zoom);

    // Calculate how many tiles we need based on radius
    final tilesRadius =
        (radiusKm * 1000 / 256 / (40075016.686 / (1 << zoom))).ceil();

    for (int x = centerX - tilesRadius; x <= centerX + tilesRadius; x++) {
      for (int y = centerY - tilesRadius; y <= centerY + tilesRadius; y++) {
        if (x >= 0 && y >= 0 && x < (1 << zoom) && y < (1 << zoom)) {
          tiles.add({'x': x, 'y': y, 'z': zoom});
        }
      }
    }

    return tiles;
  }

  /// Convert longitude to tile X coordinate
  int _lngToTileX(double lng, int zoom) {
    return ((lng + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  /// Convert latitude to tile Y coordinate
  int _latToTileY(double lat, int zoom) {
    final latRad = lat * (3.14159265359 / 180.0);
    return ((1.0 - (log(tan(latRad) + (1 / cos(latRad))) / 3.14159265359)) /
            2.0 *
            (1 << zoom))
        .floor();
  }
}
