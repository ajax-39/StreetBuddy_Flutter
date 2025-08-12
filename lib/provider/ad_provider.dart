import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:street_buddy/services/admob_service.dart';

class AdProvider extends ChangeNotifier {
  final AdMobService _adMobService = AdMobService();

  NativeAd? _exploreNativeAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  bool _hasAdError = false;
  bool _adInitializationAllowed = false; // New flag to control ad loading

  // Feed ads management
  final Map<int, NativeAd> _feedAds = {};
  final Map<int, bool> _feedAdLoaded = {};
  final Map<int, bool> _feedAdLoading = {};
  final Map<int, bool> _feedAdError = {};

  // Getters
  NativeAd? get exploreNativeAd => _exploreNativeAd;
  bool get isAdLoaded => _isAdLoaded;
  bool get isAdLoading => _isAdLoading;
  bool get hasAdError => _hasAdError;
  bool get isAdInitializationAllowed => _adInitializationAllowed;

  // Feed ad getters
  Map<int, NativeAd> get feedAds => _feedAds;
  bool isFeedAdLoaded(int position) => _feedAdLoaded[position] ?? false;
  bool isFeedAdLoading(int position) => _feedAdLoading[position] ?? false;
  bool hasFeedAdError(int position) => _feedAdError[position] ?? false;

  /// Allow ad initialization (called after posts are loaded)
  void allowAdInitialization() {
    if (_adInitializationAllowed) {
      debugPrint('🎯 Ad initialization already allowed');
      return;
    }
    _adInitializationAllowed = true;
    debugPrint('🎯 Ad initialization is now allowed');
    notifyListeners(); // Notify widgets that ads can now be loaded
  }

  /// Force enable ads (for debugging/testing)
  void forceEnableAds() {
    debugPrint('🔧 Force enabling ads for testing');
    allowAdInitialization();
  }

  /// Initialize the AdMob service only if allowed
  Future<void> initializeAds() async {
    if (!_adInitializationAllowed) {
      debugPrint('🚫 Ad initialization blocked - posts loading has priority');
      return;
    }

    if (!_adMobService.isInitialized) {
      await _adMobService.initialize();
    }
  }

  /// Load native ad for explore screen
  Future<void> loadExploreNativeAd() async {
    if (!_adInitializationAllowed) {
      debugPrint('🚫 Explore ad loading blocked - posts loading has priority');
      return;
    }

    if (_isAdLoading || _isAdLoaded) return;

    _isAdLoading = true;
    _hasAdError = false;
    notifyListeners();

    try {
      await initializeAds();

      _exploreNativeAd = _adMobService.createNativeAd(
        onAdLoaded: (Ad ad) {
          debugPrint('🎯 Explore native ad loaded successfully');
          _isAdLoaded = true;
          _isAdLoading = false;
          _hasAdError = false;
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('❌ Explore native ad failed to load: $error');
          _isAdLoaded = false;
          _isAdLoading = false;
          _hasAdError = true;
          _exploreNativeAd?.dispose();
          _exploreNativeAd = null;
          notifyListeners();
        },
        factoryId: 'exploreNativeAd', // Custom factory ID for explore screen
      );

      _exploreNativeAd?.load();
    } catch (e) {
      debugPrint('❌ Error loading explore native ad: $e');
      _isAdLoading = false;
      _hasAdError = true;
      notifyListeners();
    }
  }

  /// Dispose of the explore native ad
  void disposeExploreNativeAd() {
    if (_exploreNativeAd != null) {
      _adMobService.disposeAd(_exploreNativeAd);
      _exploreNativeAd = null;
      _isAdLoaded = false;
      _isAdLoading = false;
      _hasAdError = false;
      notifyListeners();
    }
  }

  /// Reload the explore native ad
  Future<void> reloadExploreNativeAd() async {
    disposeExploreNativeAd();
    await loadExploreNativeAd();
  }

  /// Load native ad for feed at specific position
  Future<void> loadFeedNativeAd(int position) async {
    if (!_adInitializationAllowed) {
      debugPrint('🚫 Feed ad loading blocked - posts loading has priority');
      return;
    }

    // Prevent multiple concurrent loads for the same position
    if (_feedAdLoading[position] == true) return;

    // Always dispose existing ad for this position first
    if (_feedAds.containsKey(position)) {
      try {
        _feedAds[position]?.dispose();
      } catch (e) {
        debugPrint('Error disposing existing ad at position $position: $e');
      }
      _feedAds.remove(position);
      _feedAdLoaded.remove(position);
      _feedAdLoading.remove(position);
      _feedAdError.remove(position);
    }

    _feedAdLoading[position] = true;
    _feedAdError[position] = false;
    notifyListeners();

    try {
      await initializeAds();

      final nativeAd = _adMobService.createNativeAd(
        onAdLoaded: (Ad ad) {
          debugPrint(
              '🎯 Feed native ad loaded successfully at position $position');
          _feedAdLoaded[position] = true;
          _feedAdLoading[position] = false;
          _feedAdError[position] = false;
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint(
              '❌ Feed native ad failed to load at position $position: $error');
          _feedAdLoaded[position] = false;
          _feedAdLoading[position] = false;
          _feedAdError[position] = true;
          try {
            ad.dispose();
          } catch (e) {
            debugPrint('Error disposing failed ad: $e');
          }
          _feedAds.remove(position);
          notifyListeners();
        },
        factoryId: 'feedNativeAd', // Custom factory ID for feed
      );

      _feedAds[position] = nativeAd;
      nativeAd.load();
    } catch (e) {
      debugPrint('❌ Error loading feed native ad at position $position: $e');
      _feedAdLoading[position] = false;
      _feedAdError[position] = true;
      _feedAds.remove(position);
      notifyListeners();
    }
  }

  /// Dispose of a specific feed native ad
  void disposeFeedNativeAd(int position) {
    final ad = _feedAds[position];
    if (ad != null) {
      try {
        _adMobService.disposeAd(ad);
      } catch (e) {
        debugPrint('Error disposing ad at position $position: $e');
      }
      _feedAds.remove(position);
      _feedAdLoaded.remove(position);
      _feedAdLoading.remove(position);
      _feedAdError.remove(position);
      notifyListeners();
    }
  }

  /// Dispose all feed native ads
  void disposeAllFeedNativeAds() {
    for (final position in _feedAds.keys.toList()) {
      disposeFeedNativeAd(position);
    }
  }

  /// Check if position should show an ad (every 5 posts)
  bool shouldShowAdAtPosition(int index) {
    return (index + 1) % 6 ==
        0; // Show ad after every 5 posts (positions 5, 11, 17, etc.)
  }

  /// Get the ad position key for a given index
  int getAdPositionKey(int index) {
    return ((index + 1) ~/ 6); // Generate unique keys for ad positions
  }

  @override
  void dispose() {
    disposeExploreNativeAd();
    disposeAllFeedNativeAds();
    super.dispose();
  }
}
