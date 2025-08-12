import 'package:flutter/material.dart';
import 'package:street_buddy/services/svg_asset_optimizer.dart';

/// A widget that listens for app lifecycle changes and manages SVG assets accordingly
class SvgMemoryOptimizationObserver extends StatefulWidget {
  final Widget child;

  const SvgMemoryOptimizationObserver({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<SvgMemoryOptimizationObserver> createState() =>
      _SvgMemoryOptimizationObserverState();
}

class _SvgMemoryOptimizationObserverState
    extends State<SvgMemoryOptimizationObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background, clear SVG caches to free up memory
      SvgAssetOptimizer().clearCaches();
      debugPrint('✅ Cleared SVG caches due to app going to background');
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground, reinitialize frequently used SVGs
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await SvgAssetOptimizer().precacheFrequentlyUsedAssets(context);
          debugPrint('✅ Reinitialized SVG caches after app resumed');
        } catch (e) {
          debugPrint('⚠️ Error reinitializing SVG caches: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
