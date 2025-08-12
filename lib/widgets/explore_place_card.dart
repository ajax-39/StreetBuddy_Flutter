import 'package:flutter/material.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/smart_image_widget.dart';

Widget explorePlaceCard(PlaceModel place) {
  return SizedBox(
    width: 370, // Keep the card width
    height: 240, // Keep the card height
    child: Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Image section - takes most of the space
          Expanded(
            flex: 3, // 3/5 of the card height for image
            child: SmartImageWidget(
              place: place,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Content section
          Expanded(
            flex: 2, // 2/5 of the card height for content
            child: Padding(
              padding: const EdgeInsets.all(12), // Balanced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Place name
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'SF UI Display',
                      fontSize: 16, // Reduced from 18
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                      height: 1.2,
                    ),
                  ),
                  // Location row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12, // Reduced from 14
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.vicinity ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'SF UI Display',
                            fontSize: 12, // Reduced from 14
                            fontWeight: FontWeight.w400,
                            color: Color(0x80000000),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.star_half_rounded,
                        size: 14, // Reduced from 16
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4), // Reduced spacing
                      Text(
                        place.rating.toString(),
                        style: const TextStyle(
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
