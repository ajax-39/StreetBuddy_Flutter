# SVG Asset Optimization Guide

This guide explains how the SVG asset optimization system works in the Street Buddy app and how to use it effectively.

## Purpose

The SVG asset optimization system is designed to improve performance when using SVG assets in the app by:

1. Optimizing SVG loading and rendering
2. Pre-caching frequently used SVGs for faster access
3. Managing memory efficiently
4. Providing consistent SVG rendering across the app

## Usage

### Basic Usage

Instead of using Flutter's built-in SVG loading or other methods, always use the `OptimizedSvgAsset` widget:

```dart
OptimizedSvgAsset(
  assetName: 'assets/icons/my_icon.svg',
  width: 24,
  height: 24,
  color: Colors.blue,
)
```

### Precaching SVGs

For SVG assets that are used frequently throughout the app, they are automatically precached at startup. The system automatically detects which SVGs should be precached based on their filename patterns (icons, logos, nav elements, etc).

If you need to precache additional assets in a specific part of the app:

```dart
// In a widget's initState or didChangeDependencies:
await SvgAssetOptimizer().precacheFrequentlyUsedAssets(context);
```

### Performance Benefits

1. **Reduced Memory Usage**: SVGs are cached efficiently and only loaded once
2. **Faster Rendering**: Pre-parsed SVGs render faster than loading from scratch
3. **Less Jank**: By preloading common SVGs, the UI is smoother when scrolling
4. **Lower CPU Usage**: Optimized SVG rendering reduces CPU load

## Best Practices

1. **SVG File Optimization**:
   - Use a tool like SVGO to optimize SVGs before adding them to the project
   - Remove unnecessary metadata, comments, and empty groups
   - Simplify paths where possible
   - Avoid using filters or complex gradients

2. **Naming Conventions**:
   - Name navigation icons with `nav_` prefix
   - Name UI icons with `icon_` prefix
   - Name logos with `logo_` prefix
   - These naming patterns help the optimizer identify frequently used assets

3. **Asset Size**:
   - Keep SVG file size under 10KB when possible
   - For larger illustrations, consider using PNG/WebP instead

4. **Color Management**:
   - Remove hardcoded colors from SVGs if you want to tint them in the app
   - Use the `color` parameter to tint SVGs dynamically

5. **Memory Management**:
   - Call `SvgAssetOptimizer().clearCaches()` when your app goes to background to free memory

## Adding New SVG Assets

1. Create or optimize your SVG using a tool like SVGO
2. Place the SVG in the appropriate assets directory
3. Update the pubspec.yaml file to include the asset
4. Use the `OptimizedSvgAsset` widget to display it

## Technical Details

The optimization system works in several layers:

1. **Discovery**: At app startup, all SVG assets are discovered
2. **Analysis**: Frequently used SVGs are identified
3. **Precaching**: Common SVGs are parsed and cached in memory
4. **Rendering**: When displayed, SVGs are rendered with optimized settings

This system provides significant performance improvements, especially on lower-end devices.
