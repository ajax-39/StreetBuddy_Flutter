import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:street_buddy/constants.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    const request = AdRequest(
      nonPersonalizedAds: !AdMobConstants.personalizedAdsEnabled,
    );

    _bannerAd = BannerAd(
      adUnitId: AdMobConstants.getAdUnitId(AdType.banner),
      size: AdSize.banner,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}'); 
          debugPrint('Error code: ${error.code}'); 
          ad.dispose();
          _bannerAd = null;
          Future.delayed(const Duration(minutes: 1), _loadBannerAd);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}