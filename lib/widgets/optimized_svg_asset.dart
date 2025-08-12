import 'package:flutter/material.dart';
import 'package:street_buddy/services/svg_asset_optimizer.dart';

/// A widget that efficiently renders SVG assets with optimizations
class OptimizedSvgAsset extends StatelessWidget {
  /// The asset path to the SVG file
  final String assetName;

  /// Width of the rendered SVG
  final double? width;

  /// Height of the rendered SVG
  final double? height;

  /// How to inscribe the SVG into the space allocated
  final BoxFit fit;

  /// Color to apply to the SVG (if supported by the SVG)
  final Color? color;

  /// Create an optimized SVG asset widget
  const OptimizedSvgAsset({
    Key? key,
    required this.assetName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgAssetOptimizer().getSvg(
      assetName: assetName,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  /// Initialize and precache commonly used SVG assets for better performance
  static Future<void> precacheCommonAssets(BuildContext context) async {
    await SvgAssetOptimizer().precacheFrequentlyUsedAssets(context);
  }
}
