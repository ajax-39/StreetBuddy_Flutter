import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/premium_lock_overlay.dart';
import 'package:street_buddy/widgets/smart_image_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlaceCard extends StatelessWidget {
  final PlaceModel place;
  final int index;
  final bool isVIP;
  final int blurAfter;
  final void Function()? onTap;
  final String? heroTag;
  final double borderRadius;
  final double imageHeight;

  const PlaceCard({
    super.key,
    required this.place,
    required this.index,
    required this.isVIP,
    this.blurAfter = 3,
    this.onTap,
    this.heroTag,
    this.borderRadius = 12,
    this.imageHeight = 137,
  });

  @override
  Widget build(BuildContext context) {
    // Original VIP Logic: First 3 places are free, all others are locked for non-VIP users
    final shouldBlur = !isVIP && index >= blurAfter;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: () {
          if (shouldBlur) {
            context.push('/vip');
            return;
          }
          if (onTap != null) {
            onTap!();
          } else {
            context.push('/locations/place', extra: place);
          }
        },
        child: Hero(
          tag: heroTag ?? 'place_${place.id}',
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, AppColors.surfaceBackground],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(borderRadius),
                      ),
                      child: SmartImageWidget.fromPlace(
                        place: place,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                    fontFamily: 'SFUI',
                                    fontWeight: fontmedium,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                if (place.vicinity != null)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          place.vicinity!,
                                          style: TextStyle(
                                            fontFamily: 'SFUI',
                                            fontSize: 12,
                                            fontWeight: fontregular,
                                            color:
                                                Colors.black.withOpacity(0.5),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.solidStar,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      place.rating.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'SFUI',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (shouldBlur) const PremiumLockOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}
