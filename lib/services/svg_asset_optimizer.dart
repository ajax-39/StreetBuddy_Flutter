import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:street_buddy/utils/asset_optimization_util.dart';

/// This class manages SVG asset optimization throughout the application
class SvgAssetOptimizer {
  // Singleton instance
  static final SvgAssetOptimizer _instance = SvgAssetOptimizer._internal();

  factory SvgAssetOptimizer() => _instance;

  SvgAssetOptimizer._internal();

  // The list of SVG assets to pre-optimize
  final List<String> _svgAssetPaths = [];

  // The asset optimization utility
  final AssetOptimizationUtil _assetUtil = AssetOptimizationUtil();

  bool _initialized = false;

  /// Initialize the SVG asset optimizer
  Future<void> initialize() async {
    if (_initialized) return;

    // Find and register all SVG assets
    await _discoverSvgAssets();

    _initialized = true;
    debugPrint(
        '✅ SVG Asset Optimizer initialized with ${_svgAssetPaths.length} assets');
  }

  /// Pre-cache frequently used SVG assets for better performance
  Future<void> precacheFrequentlyUsedAssets(BuildContext context) async {
    if (!_initialized) {
      await initialize();
    }

    // Get the most frequently used SVGs (e.g., UI icons, common elements)
    final frequentAssets = _getFrequentlyUsedAssets();

    // Pre-cache these assets
    await _assetUtil.precacheSvgAssets(context, frequentAssets);
    debugPrint(
        '✅ Pre-cached ${frequentAssets.length} frequently used SVG assets');
  }

  /// Get a list of frequently used SVG assets
  List<String> _getFrequentlyUsedAssets() {
    // Typically these would be icons or elements that appear on multiple screens
    // This is just a subset of all assets
    final frequentAssets = <String>[];

    // Add navigation icons, common UI elements, etc.
    for (final asset in _svgAssetPaths) {
      if (asset.contains('icon') ||
          asset.contains('logo') ||
          asset.contains('nav') ||
          asset.contains('button')) {
        frequentAssets.add(asset);
      }
    }

    // Limit to a reasonable number (too many defeats the purpose of selective pre-caching)
    return frequentAssets.take(15).toList();
  }

  /// Discover all SVG assets in the assets directory
  Future<void> _discoverSvgAssets() async {
    try {
      _svgAssetPaths.clear();

      // Get the asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');

      // Parse the manifest and find SVG files
      final Map<String, dynamic> manifestMap =
          Map.from(json.decode(manifestContent));

      for (final String key in manifestMap.keys) {
        if (key.toLowerCase().endsWith('.svg')) {
          _svgAssetPaths.add(key);
        }
      }

      debugPrint('✅ Found ${_svgAssetPaths.length} SVG assets in the project');
    } catch (e) {
      debugPrint('⚠️ Error discovering SVG assets: $e');

      // If we fail to load from manifest, add some common paths manually
      // This ensures the optimizer still works even if manifest loading fails
      _svgAssetPaths.addAll([
        'assets/icon/logo.svg',
        'assets/icon/nav_home.svg',
        'assets/icon/nav_explore.svg',
        'assets/icon/nav_messages.svg',
        'assets/icon/nav_profile.svg',
      ]);
    }
  }

  /// Get an optimized SVG widget
  Widget getSvg({
    required String assetName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return _assetUtil.optimizedSvg(
      assetName: assetName,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  /// Clear all SVG caches to free up memory
  void clearCaches() {
    _assetUtil.clearCache();
  }
}
