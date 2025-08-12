
import 'package:flutter/material.dart';
import 'package:street_buddy/widgets/ads/banner_ad_widget.dart';
import 'package:street_buddy/widgets/ads/interstitial_ad_service.dart';
import 'package:street_buddy/widgets/ads/rewaded_ad_service.dart';
import 'package:street_buddy/widgets/ads/rewarded_interstitial_ad_service.dart';


class ExampleAdScreen extends StatefulWidget {
  const ExampleAdScreen({super.key});

  @override
  State<ExampleAdScreen> createState() => _ExampleAdScreenState();
}

class _ExampleAdScreenState extends State<ExampleAdScreen> {
  late final InterstitialAdService _interstitialAdService;
  late final RewardedAdService _rewardedAdService;
  late final RewardedInterstitialAdService _rewardedInterstitialAdService;

  @override
  void initState() {
    super.initState();
    _interstitialAdService = InterstitialAdService()..loadAd();
    _rewardedAdService = RewardedAdService()..loadAd();
    _rewardedInterstitialAdService = RewardedInterstitialAdService()..loadAd();
  }

  @override
  void dispose() {
    _interstitialAdService.dispose();
    _rewardedAdService.dispose();
    _rewardedInterstitialAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AdMob Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const  Card(
              child: Padding(
                padding:  EdgeInsets.all(8.0),
                child: Column(
                  children: [
                     Text('Banner Ad',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                     BannerAdWidget(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _interstitialAdService.showAd(),
              child: const Text('Show Interstitial Ad'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _rewardedAdService.showAd(
                onRewardEarned: (reward) {
                  debugPrint('Reward earned: ${reward.amount}');
                },
              ),
              child: const Text('Show Rewarded Ad'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _rewardedInterstitialAdService.showAd(
                onRewardEarned: (reward) {
                  debugPrint('Reward earned: ${reward.amount}');
                },
              ),
              child: const Text('Show Rewarded Interstitial Ad'),
            ),
          ],
        ),
      ),
    );
  }
}