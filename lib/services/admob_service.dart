import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Production Ad IDs
  static const String _androidBannerAdUnitId =
      'ca-app-pub-3084365051755367/4936037379';
  static const String _androidNativeAdUnitId =
      'ca-app-pub-3084365051755367/5011164775';

  // iOS Ad IDs (you can update these when you get iOS ad unit IDs)
  static const String _iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716'; // Test banner ID
  static const String _iosNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511'; // Test native ID

  // Test Ad IDs for development
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('🎯 AdMob SDK initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize AdMob SDK: $e');
    }
  }

  /// Get the appropriate banner ad unit ID based on platform and build mode
  String get bannerAdUnitId {
    if (kDebugMode) {
      return _testBannerAdUnitId;
    }

    if (Platform.isAndroid) {
      return _androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _iosBannerAdUnitId;
    }
    return _testBannerAdUnitId;
  }

  /// Get the appropriate native ad unit ID based on platform and build mode
  String get nativeAdUnitId {
    if (kDebugMode) {
      return _testNativeAdUnitId;
    }

    if (Platform.isAndroid) {
      return _androidNativeAdUnitId;
    } else if (Platform.isIOS) {
      return _iosNativeAdUnitId;
    }
    return _testNativeAdUnitId;
  }

  /// Create and load a banner ad
  BannerAd createBannerAd({
    required AdSize adSize,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
    required void Function(Ad) onAdLoaded,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (Ad ad) => debugPrint('🎯 Banner ad opened'),
        onAdClosed: (Ad ad) => debugPrint('🎯 Banner ad closed'),
      ),
    );
  }

  /// Create and load a native ad
  NativeAd createNativeAd({
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
    required void Function(Ad) onAdLoaded,
    String? factoryId,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      factoryId: factoryId ?? 'listTile', // Default factory ID
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (Ad ad) => debugPrint('🎯 Native ad opened'),
        onAdClosed: (Ad ad) => debugPrint('🎯 Native ad closed'),
        onAdClicked: (Ad ad) => debugPrint('🎯 Native ad clicked'),
      ),
    );
  }

  /// Dispose of an ad
  void disposeAd(Ad? ad) {
    ad?.dispose();
  }
}
