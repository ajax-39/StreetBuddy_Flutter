import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/models/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUrlService {
  final dio = Dio();
  final supabase = Supabase.instance.client;

  // Cache for recently validated URLs to avoid repeated validation
  final Map<String, DateTime> _validationCache = {};

  // Queue for background refresh operations
  final Set<String> _refreshQueue = {};

  static const int _expirationDays =
      25; // Refresh 5 days before 30-day expiration
  static const int _validationCacheMinutes =
      10080; // Cache validation results for 24 hours

  /// Check if an image URL needs refresh based on expiration date
  bool needsImageRefresh(DateTime? cachedAt, DateTime? expiresAt) {
    if (cachedAt == null) return true;

    final now = DateTime.now();

    // If we have an explicit expiration date, use it with some buffer
    if (expiresAt != null) {
      // Only refresh if actually expired (not just close to expiration)
      return now.isAfter(expiresAt);
    }

    // Otherwise, calculate based on cached date (only refresh after 25 days)
    final daysSinceCache = now.difference(cachedAt).inDays;
    return daysSinceCache >= _expirationDays;
  }

  /// Validate an image URL by checking its HTTP status
  Future<bool> validateImageUrl(String url) async {
    try {
      // Check validation cache first
      final lastValidation = _validationCache[url];
      if (lastValidation != null) {
        final minutesSinceValidation =
            DateTime.now().difference(lastValidation).inMinutes;
        if (minutesSinceValidation < _validationCacheMinutes) {
          return true; // Assume valid if recently validated
        }
      }

      // Perform HEAD request to check URL status
      final response = await dio.head(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final isValid = response.statusCode == 200;

      if (isValid) {
        _validationCache[url] = DateTime.now();
      } else {
        _validationCache.remove(url);
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Error validating image URL: $e');
      _validationCache.remove(url);
      return false;
    }
  }

  /// Get the correct Google Places ID for API calls
  /// For custom IDs (pcustom_), get the stored google_places_id from database
  /// For regular IDs, use the ID directly
  Future<String?> _getGooglePlacesId(String placeId) async {
    try {
      // If it's not a custom ID, use it directly as Google Places ID
      if (!placeId.startsWith('pcustom_')) {
        return placeId;
      }

      // For custom IDs, get the google_places_id from database
      debugPrint('📍 Getting Google Places ID for custom place: $placeId');

      // First try places table
      var response = await supabase
          .from('places')
          .select('google_places_id')
          .eq('id', placeId)
          .maybeSingle();

      if (response != null && response['google_places_id'] != null) {
        debugPrint(
            '✅ Found Google Places ID in places table: ${response['google_places_id']}');
        return response['google_places_id'];
      }

      // If not found in places, try explore_places table
      response = await supabase
          .from('explore_places')
          .select('google_places_id')
          .eq('id', placeId)
          .maybeSingle();

      if (response != null && response['google_places_id'] != null) {
        debugPrint(
            '✅ Found Google Places ID in explore_places table: ${response['google_places_id']}');
        return response['google_places_id'];
      }

      debugPrint('⚠️ No Google Places ID found for custom place: $placeId');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting Google Places ID for $placeId: $e');
      return null;
    }
  }

  /// Store the discovered Google Places ID for a custom place
  Future<void> _storeGooglePlacesId(
      String customPlaceId, String googlePlacesId) async {
    try {
      debugPrint(
          '💾 Storing Google Places ID $googlePlacesId for custom place $customPlaceId');

      // First try to update in places table
      final placesResponse = await supabase
          .from('places')
          .update({'google_places_id': googlePlacesId}).eq('id', customPlaceId);

      // If no rows affected in places table, try explore_places table
      if (placesResponse == null || (placesResponse as List).isEmpty) {
        await supabase.from('explore_places').update(
            {'google_places_id': googlePlacesId}).eq('id', customPlaceId);
        debugPrint(
            '✅ Stored Google Places ID for explore place: $customPlaceId');
      } else {
        debugPrint('✅ Stored Google Places ID for place: $customPlaceId');
      }
    } catch (e) {
      debugPrint('❌ Error storing Google Places ID: $e');
    }
  }

  /// Refresh image URL for a place from Google Places API
  Future<String?> refreshPlaceImageUrl(String placeId) async {
    try {
      debugPrint('🔄 Refreshing image URL for place: $placeId');

      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'photos',
          'key': Constant.GOOGLE_API,
        },
      );

      if (response.statusCode == 200) {
        final result = response.data['result'];
        if (result?['photos'] != null &&
            (result!['photos'] as List).isNotEmpty) {
          final photo = result['photos'][0];
          final photoReference = photo['photo_reference'];
          final newUrl =
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';

          debugPrint('✅ New image URL generated for $placeId');
          return newUrl;
        }
      }

      debugPrint('⚠️ No photos found for place: $placeId');
      return null;
    } catch (e) {
      debugPrint('❌ Error refreshing image URL for $placeId: $e');
      return null;
    }
  }

  /// Refresh media URLs for a place from Google Places API (up to 4 images)
  Future<List<String>?> refreshPlaceMediaUrls(String placeId) async {
    try {
      debugPrint('🔄 Refreshing media URLs for place: $placeId');

      // Get the correct Google Places ID for API calls
      final googlePlacesId = await _getGooglePlacesId(placeId);
      if (googlePlacesId == null) {
        debugPrint('⚠️ No Google Places ID available for place: $placeId');
        return null;
      }

      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': googlePlacesId,
          'fields': 'photos',
          'key': Constant.GOOGLE_API,
        },
      );

      if (response.statusCode == 200) {
        final result = response.data['result'];
        if (result?['photos'] != null &&
            (result!['photos'] as List).isNotEmpty) {
          final photos = result['photos'] as List;
          final mediaUrls = <String>[];

          // Get up to 4 photos
          for (var photo in photos.take(4)) {
            final photoReference = photo['photo_reference'];
            final imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';
            mediaUrls.add(imageUrl);
          }

          debugPrint(
              '✅ ${mediaUrls.length} new media URLs generated for $googlePlacesId');
          return mediaUrls;
        }
      }

      debugPrint('⚠️ No photos found for place: $googlePlacesId');
      return null;
    } catch (e) {
      debugPrint('❌ Error refreshing media URLs for $placeId: $e');
      return null;
    }
  }

  /// Search for a place and get media URLs if no photos exist
  Future<List<String>?> searchAndGetPlaceMediaUrls(
      String placeName, double lat, double lng,
      {String? customPlaceId}) async {
    try {
      debugPrint('🔍 Searching for place: $placeName at ($lat, $lng)');

      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': '500',
          'name': placeName,
          'key': Constant.GOOGLE_API,
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        if (results.isNotEmpty) {
          final place = results[0];
          final googlePlacesId = place['place_id'];

          debugPrint('🎯 Found place ID: $googlePlacesId');

          // If this is for a custom place, store the Google Places ID
          if (customPlaceId != null && customPlaceId.startsWith('pcustom_')) {
            await _storeGooglePlacesId(customPlaceId, googlePlacesId);
          }

          // Get photos for this place using the discovered Google Places ID
          final response = await dio.get(
            'https://maps.googleapis.com/maps/api/place/details/json',
            queryParameters: {
              'place_id': googlePlacesId,
              'fields': 'photos',
              'key': Constant.GOOGLE_API,
            },
          );

          if (response.statusCode == 200) {
            final result = response.data['result'];
            if (result?['photos'] != null &&
                (result!['photos'] as List).isNotEmpty) {
              final photos = result['photos'] as List;
              final mediaUrls = <String>[];

              // Get up to 4 photos
              for (var photo in photos.take(4)) {
                final photoReference = photo['photo_reference'];
                final imageUrl =
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';
                mediaUrls.add(imageUrl);
              }

              debugPrint(
                  '✅ ${mediaUrls.length} new media URLs generated for $googlePlacesId');
              return mediaUrls;
            }
          }
        }
      }

      debugPrint('⚠️ No places found for search: $placeName');
      return null;
    } catch (e) {
      debugPrint('❌ Error searching for place $placeName: $e');
      return null;
    }
  }

  /// Refresh image URL for a location from Google Places API
  Future<List<String>?> refreshLocationImageUrls(String placeId) async {
    try {
      debugPrint('🔄 Refreshing image URLs for location: $placeId');

      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields': 'photos',
          'key': Constant.GOOGLE_API,
        },
      );

      if (response.statusCode == 200) {
        final result = response.data['result'];
        if (result?['photos'] != null &&
            (result!['photos'] as List).isNotEmpty) {
          final photos = result['photos'] as List;
          final imageUrls = <String>[];

          // Get up to 3 photos
          for (var photo in photos.take(3)) {
            final photoReference = photo['photo_reference'];
            final imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';
            imageUrls.add(imageUrl);
          }

          debugPrint(
              '✅ ${imageUrls.length} new image URLs generated for $placeId');
          return imageUrls;
        }
      }

      debugPrint('⚠️ No photos found for location: $placeId');
      return null;
    } catch (e) {
      debugPrint('❌ Error refreshing image URLs for $placeId: $e');
      return null;
    }
  }

  /// Get valid media URLs for a place, refreshing if necessary
  Future<List<String>> getValidPlaceMediaUrls(PlaceModel place) async {
    // Check if media URLs need refresh
    if (!needsImageRefresh(place.mediaCachedAt, place.mediaExpiresAt) &&
        place.mediaUrls.isNotEmpty) {
      return place.mediaUrls;
    }

    // If no media URLs exist, try to search and get them
    if (place.mediaUrls.isEmpty) {
      debugPrint('📷 No media URLs found for place: ${place.name}');

      // Try to search for the place and get media URLs
      final searchedUrls = await searchAndGetPlaceMediaUrls(
          place.name, place.latitude, place.longitude,
          customPlaceId: place.id);
      if (searchedUrls != null && searchedUrls.isNotEmpty) {
        await _updatePlaceMediaUrls(place.id, searchedUrls);
        return searchedUrls;
      }

      // If search fails, try using the place ID directly
      final directUrls = await refreshPlaceMediaUrls(place.id);
      if (directUrls != null && directUrls.isNotEmpty) {
        await _updatePlaceMediaUrls(place.id, directUrls);
        return directUrls;
      }

      debugPrint('⚠️ No media URLs found for place: ${place.name}');
      return [Constant.DEFAULT_PLACE_IMAGE];
    }

    // If media URLs are expired or invalid, try to refresh in background
    if (!_refreshQueue.contains(place.id)) {
      _refreshPlaceMediaInBackground(place);
    }

    // Return cached URLs immediately (for better UX)
    return place.mediaUrls.isNotEmpty
        ? place.mediaUrls
        : [Constant.DEFAULT_PLACE_IMAGE];
  }

  /// Get a valid image URL for a place, refreshing if necessary
  Future<String> getValidPlaceImageUrl(PlaceModel place) async {
    final mediaUrls = await getValidPlaceMediaUrls(place);
    return mediaUrls.isNotEmpty
        ? mediaUrls.first
        : Constant.DEFAULT_PLACE_IMAGE;
  }

  /// Get valid image URLs for a location, refreshing if necessary
  Future<List<String>> getValidLocationImageUrls(LocationModel location) async {
    // If URLs don't need refresh, return cached URLs
    if (!needsImageRefresh(location.imageCachedAt, location.imageExpiresAt)) {
      return location.imageUrls.isNotEmpty
          ? location.imageUrls
          : [Constant.DEFAULT_PLACE_IMAGE];
    }

    // If URLs are expired, try to refresh in background
    if (location.imageUrls.isNotEmpty && !_refreshQueue.contains(location.id)) {
      _refreshLocationImagesInBackground(location);
    }

    // Return cached URLs immediately (for better UX)
    return location.imageUrls.isNotEmpty
        ? location.imageUrls
        : [Constant.DEFAULT_PLACE_IMAGE];
  }

  /// Refresh place media URLs in background without blocking UI
  void _refreshPlaceMediaInBackground(PlaceModel place) {
    _refreshQueue.add(place.id);

    Timer(const Duration(milliseconds: 100), () async {
      try {
        final newUrls = await refreshPlaceMediaUrls(place.id);
        if (newUrls != null && newUrls.isNotEmpty) {
          await _updatePlaceMediaUrls(place.id, newUrls);
        } else {
          // Try searching if direct method fails
          final searchedUrls = await searchAndGetPlaceMediaUrls(
              place.name, place.latitude, place.longitude,
              customPlaceId: place.id);
          if (searchedUrls != null && searchedUrls.isNotEmpty) {
            await _updatePlaceMediaUrls(place.id, searchedUrls);
          } else {
            // Mark as needing refresh but keep existing URLs
            await _markPlaceMediaForRefresh(place.id);
          }
        }
      } catch (e) {
        debugPrint(
            '❌ Background media refresh failed for place ${place.id}: $e');
      } finally {
        _refreshQueue.remove(place.id);
      }
    });
  }

  /// Refresh location image URLs in background without blocking UI
  void _refreshLocationImagesInBackground(LocationModel location) {
    _refreshQueue.add(location.id);

    Timer(const Duration(milliseconds: 100), () async {
      try {
        final newUrls = await refreshLocationImageUrls(location.id);
        if (newUrls != null && newUrls.isNotEmpty) {
          await _updateLocationImageUrls(location.id, newUrls);
        } else {
          // Mark as needing refresh but keep existing URLs
          await _markLocationImagesForRefresh(location.id);
        }
      } catch (e) {
        debugPrint(
            '❌ Background refresh failed for location ${location.id}: $e');
      } finally {
        _refreshQueue.remove(location.id);
      }
    });
  }

  /// Update place media URLs in database (handles both places and explore_places tables)
  Future<void> _updatePlaceMediaUrls(
      String placeId, List<String> newUrls) async {
    try {
      final now = DateTime.now();
      final updateData = {
        'media_urls': newUrls,
        'media_cached_at': now.toIso8601String(),
        'media_expires_at': now
            .add(Duration(days: 30))
            .toIso8601String(), // Google URLs expire after 30 days
        'media_last_validated_at': now.toIso8601String(),
        'media_refresh_needed': false,
      };

      // First try to update in places table
      final placesResponse =
          await supabase.from('places').update(updateData).eq('id', placeId);

      // If no rows affected in places table, try explore_places table
      if (placesResponse == null || (placesResponse as List).isEmpty) {
        await supabase
            .from('explore_places')
            .update(updateData)
            .eq('id', placeId);
        debugPrint('✅ Updated media URLs for explore place: $placeId');
      } else {
        debugPrint('✅ Updated media URLs for place: $placeId');
      }
    } catch (e) {
      debugPrint('❌ Error updating place media URLs: $e');
    }
  }

  /// Update location image URLs in database
  Future<void> _updateLocationImageUrls(
      String locationId, List<String> newUrls) async {
    try {
      final now = DateTime.now();
      await supabase.from('locations').update({
        'image_urls': newUrls,
        'image_cached_at': now.toIso8601String(),
        'image_expires_at': now
            .add(Duration(days: 30))
            .toIso8601String(), // Google URLs expire after 30 days
        'image_last_validated_at': now.toIso8601String(),
        'image_refresh_needed': false,
      }).eq('id', locationId);

      debugPrint('✅ Updated image URLs for location: $locationId');
    } catch (e) {
      debugPrint('❌ Error updating location image URLs: $e');
    }
  }

  /// Mark place media as needing refresh (handles both places and explore_places tables)
  Future<void> _markPlaceMediaForRefresh(String placeId) async {
    try {
      final updateData = {
        'media_refresh_needed': true,
        'media_last_validated_at': DateTime.now().toIso8601String(),
      };

      // First try to update in places table
      final placesResponse =
          await supabase.from('places').update(updateData).eq('id', placeId);

      // If no rows affected in places table, try explore_places table
      if (placesResponse == null || (placesResponse as List).isEmpty) {
        await supabase
            .from('explore_places')
            .update(updateData)
            .eq('id', placeId);
        debugPrint('⚠️ Marked explore place media for refresh: $placeId');
      } else {
        debugPrint('⚠️ Marked place media for refresh: $placeId');
      }
    } catch (e) {
      debugPrint('❌ Error marking place media for refresh: $e');
    }
  }

  /// Mark location images as needing refresh
  Future<void> _markLocationImagesForRefresh(String locationId) async {
    try {
      await supabase.from('locations').update({
        'image_refresh_needed': true,
        'image_last_validated_at': DateTime.now().toIso8601String(),
      }).eq('id', locationId);

      debugPrint('⚠️ Marked location images for refresh: $locationId');
    } catch (e) {
      debugPrint('❌ Error marking location images for refresh: $e');
    }
  }

  /// Batch validate and refresh expired images
  Future<void> validateAndRefreshExpiredImages() async {
    try {
      debugPrint('🔍 Starting batch validation of expired images...');

      final now = DateTime.now();

      // Find places with expired or soon-to-expire media URLs from places table
      final expiredPlaces = await supabase
          .from('places')
          .select('id, name, latitude, longitude, media_urls, media_expires_at')
          .or('media_expires_at.lt.${now.toIso8601String()},media_refresh_needed.eq.true')
          .limit(25); // Process in smaller batches to accommodate both tables

      // Find places with expired or soon-to-expire media URLs from explore_places table
      final expiredExplorePlaces = await supabase
          .from('explore_places')
          .select('id, name, latitude, longitude, media_urls, media_expires_at')
          .or('media_expires_at.lt.${now.toIso8601String()},media_refresh_needed.eq.true')
          .limit(25); // Process in smaller batches to accommodate both tables

      final allExpiredPlaces = [...expiredPlaces, ...expiredExplorePlaces];

      debugPrint(
          'Found ${allExpiredPlaces.length} places with expired media URLs (${expiredPlaces.length} from places, ${expiredExplorePlaces.length} from explore_places)');

      for (var place in allExpiredPlaces) {
        if (!_refreshQueue.contains(place['id'])) {
          List<String>? newUrls;

          // Try to get media URLs using place ID
          newUrls = await refreshPlaceMediaUrls(place['id']);

          // If no URLs found, try searching
          if (newUrls == null || newUrls.isEmpty) {
            newUrls = await searchAndGetPlaceMediaUrls(
                place['name'], place['latitude'], place['longitude'],
                customPlaceId: place['id']);
          }

          if (newUrls != null && newUrls.isNotEmpty) {
            await _updatePlaceMediaUrls(place['id'], newUrls);
          } else {
            await _markPlaceMediaForRefresh(place['id']);
          }

          // Add small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      // Find locations with expired images
      final expiredLocations = await supabase
          .from('locations')
          .select('id, image_urls, image_expires_at')
          .or('image_expires_at.lt.${now.toIso8601String()},image_refresh_needed.eq.true')
          .limit(20); // Smaller batch for locations

      debugPrint(
          'Found ${expiredLocations.length} locations with expired images');

      for (var location in expiredLocations) {
        if (!_refreshQueue.contains(location['id'])) {
          final newUrls = await refreshLocationImageUrls(location['id']);
          if (newUrls != null && newUrls.isNotEmpty) {
            await _updateLocationImageUrls(location['id'], newUrls);
          }

          // Add delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      debugPrint('✅ Batch validation completed');
    } catch (e) {
      debugPrint('❌ Error during batch validation: $e');
    }
  }

  /// Clear validation cache (call periodically to prevent memory leaks)
  void clearValidationCache() {
    _validationCache.clear();
    debugPrint('🧹 Validation cache cleared');
  }
}
