import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:street_buddy/constants.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;

  void loadAd() {
    RewardedAd.load(
      adUnitId: AdMobConstants.getAdUnitId(AdType.rewarded),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  Future<void> showAd({required Function(RewardItem reward) onRewardEarned}) async {
    if (_rewardedAd != null) {
      await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onRewardEarned(reward);
      });
      loadAd();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
