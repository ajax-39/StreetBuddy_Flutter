import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:street_buddy/constants.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: AdMobConstants.getAdUnitId(AdType.interstitial),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  Future<void> showAd() async {
    debugPrint  ('showAd');
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      loadAd();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
