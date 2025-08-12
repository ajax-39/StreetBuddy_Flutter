import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:street_buddy/constants.dart';

class RewardedInterstitialAdService {
  RewardedInterstitialAd? _rewardedInterstitialAd;

  void loadAd() {
    RewardedInterstitialAd.load(
      adUnitId: AdMobConstants.getAdUnitId(AdType.rewardedInterstitial),
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _rewardedInterstitialAd = ad,
        onAdFailedToLoad: (error) => _rewardedInterstitialAd = null,
      ),
    );
  }

  Future<void> showAd({required Function(RewardItem reward) onRewardEarned}) async {
    if (_rewardedInterstitialAd != null) {
      await _rewardedInterstitialAd!.show(onUserEarnedReward: (ad, reward) {
        onRewardEarned(reward);
      });
      loadAd();
    }
  }

  void dispose() {
    _rewardedInterstitialAd?.dispose();
  }
}