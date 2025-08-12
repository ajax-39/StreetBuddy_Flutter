import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/ad_provider.dart';

class ExploreNativeAdWidget extends StatefulWidget {
  const ExploreNativeAdWidget({super.key});

  @override
  State<ExploreNativeAdWidget> createState() => _ExploreNativeAdWidgetState();
}

class _ExploreNativeAdWidgetState extends State<ExploreNativeAdWidget> {
  @override
  void initState() {
    super.initState();
    // Load the ad only if initialization is allowed (after posts are loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adProvider = context.read<AdProvider>();
      if (adProvider.isAdInitializationAllowed) {
        adProvider.loadExploreNativeAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        // If ads are now allowed but haven't been loaded yet, trigger loading
        if (adProvider.isAdInitializationAllowed &&
            !adProvider.isAdLoaded &&
            !adProvider.isAdLoading &&
            !adProvider.hasAdError) {
          // Use post frame callback to avoid calling during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            adProvider.loadExploreNativeAd();
          });
        }

        // Don't show anything if ad is loading or has error
        if (adProvider.isAdLoading ||
            adProvider.hasAdError ||
            !adProvider.isAdLoaded) {
          return const SizedBox.shrink();
        }

        // Show the native ad
        if (adProvider.exploreNativeAd != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160, // Updated height for consistency with search bar
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AdWidget(ad: adProvider.exploreNativeAd!),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    // The AdProvider will handle disposing the ad
    super.dispose();
  }
}
