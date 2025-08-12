import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/ad_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class FeedNativeAdWidget extends StatefulWidget {
  final int position;
  final double? cardMargin;
  final bool isTablet;

  const FeedNativeAdWidget({
    super.key,
    required this.position,
    this.cardMargin,
    this.isTablet = false,
  });

  @override
  State<FeedNativeAdWidget> createState() => _FeedNativeAdWidgetState();
}

class _FeedNativeAdWidgetState extends State<FeedNativeAdWidget> {
  @override
  void initState() {
    super.initState();
    // Only load ad if initialization is allowed (after posts are loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adProvider = context.read<AdProvider>();
      if (adProvider.isAdInitializationAllowed) {
        adProvider.loadFeedNativeAd(widget.position);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        // If ads are now allowed but haven't been loaded yet, trigger loading
        if (adProvider.isAdInitializationAllowed &&
            !adProvider.isFeedAdLoaded(widget.position) &&
            !adProvider.isFeedAdLoading(widget.position) &&
            !adProvider.hasFeedAdError(widget.position)) {
          // Use post frame callback to avoid calling during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            adProvider.loadFeedNativeAd(widget.position);
          });
        }

        final isLoaded = adProvider.isFeedAdLoaded(widget.position);
        final isLoading = adProvider.isFeedAdLoading(widget.position);
        final hasError = adProvider.hasFeedAdError(widget.position);
        final nativeAd = adProvider.feedAds[widget.position];

        // If error, failed to load, or ad doesn't exist, don't show anything
        if (hasError || nativeAd == null) {
          return const SizedBox.shrink();
        }

        // If still loading, don't show anything to avoid layout issues
        if (isLoading || !isLoaded) {
          return const SizedBox.shrink();
        }

        // Only show ad if it's successfully loaded and available
        try {
          // Updated container for ad to ensure all assets stay within the view boundary
          return Card(
            margin: EdgeInsets.only(
              top: (widget.cardMargin ?? 8.0),
              bottom: 0,
              left:
                  8.0, // Add horizontal margin to prevent assets from bleeding
              right:
                  8.0, // Add horizontal margin to prevent assets from bleeding
            ),
            elevation: 0,
            color: AppColors.surfaceBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior:
                Clip.antiAlias, // Ensure nothing renders outside the card
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 250,
                maxHeight: 320, // Allow more height to fit all ad components
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical:
                        4.0), // Add padding to keep assets away from the edge
                child: AdWidget(ad: nativeAd),
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error displaying ad at position ${widget.position}: $e');
          return const SizedBox.shrink();
        }
      },
    );
  }

  @override
  void didUpdateWidget(FeedNativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload ad if position changes (for refresh) and ads are allowed
    if (oldWidget.position != widget.position) {
      final adProvider = context.read<AdProvider>();
      if (adProvider.isAdInitializationAllowed) {
        adProvider.loadFeedNativeAd(widget.position);
      }
    }
  }
}
