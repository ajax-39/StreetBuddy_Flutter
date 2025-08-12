import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/services/database_helper.dart';
import 'package:street_buddy/utils/connectivity_util.dart';
import 'package:street_buddy/utils/url_util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/**
 * BookmarkProvider
 *
 * Manages bookmark operations for places in the StreetBuddy application.
 *
 * Core Responsibilities:
 * - Add/remove bookmarks with [toggleBookmark]
 * - Check if a place is bookmarked using [isBookmarked]
 * - Retrieve all bookmarked places with [getBookmarkedPlaces]
 * - Organize places by location and category with [getBookmarkedPlacesHierarchy]
 * - Ensure offline availability through local caching
 *
 * Key Features:
 * - Seamless integration with Supabase for remote storage
 * - Local caching of place data and images for offline access
 * - Place data enrichment via Foursquare API
 * - Organization of places into location/category hierarchy
 * - Graceful fallback to cached data when offline
 *
 * API Usage:
 * - One API call per bookmarked place for data enrichment
 * - API calls occur during [getBookmarkedPlaces] and [getBookmarkedPlacesHierarchy]
 *
 * Place Categories:
 * - Attractions (tourist_attraction)
 * - Hotels (lodging)
 * - Restaurants (restaurant)
 * - Shopping (shopping_mall)
 * - Other (default)
 */

class BookmarkProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  final _supabase = Supabase.instance.client;

  static const validCategories = {
    'tourist_attraction': 'Attractions',
    'lodging': 'Hotels',
    'restaurant': 'Restaurants',
    'shopping_mall': 'Shopping'
  };

  Future<void> cacheBookmarkedPlace(PlaceModel place) async {
    try {
      await _db.insertPlace(place);

      if (place.photoUrl != null &&
          place.photoUrl != Constant.DEFAULT_PLACE_IMAGE) {
        await _cacheImage(place);
      }
    } catch (e) {
      // Error handling for caching failure
    }
  }

  Future<void> _cacheImage(PlaceModel place) async {
    try {
      final imageUrl = UrlUtils.addApiKeyToPhotoUrl(
        place.photoUrl!,
        Constant.GOOGLE_API,
      );

      final response = await Dio().get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        await _db.cacheImage(place.photoUrl!, response.data!);
      }
    } catch (e) {
      // Error handling for image caching failure
    }
  }

  Future<void> toggleBookmark(PlaceModel place) async {
    final user = globalUser;
    if (user == null) return;

    try {
      // Get current user data from Supabase
      final userResponse = await _supabase
          .from('users')
          .select('bookmarked_places')
          .eq('uid', user.uid)
          .single();

      List<String> bookmarks =
          List<String>.from(userResponse['bookmarked_places'] ?? []);

      if (bookmarks.contains(place.id)) {
        // Remove bookmark
        bookmarks.remove(place.id);
        await _db.removePlace(place.id);
      } else {
        // Add bookmark
        bookmarks.add(place.id);
        await cacheBookmarkedPlace(place);
        await _ensurePlaceInSupabase(place);
      }

      // Update user's bookmarked places in Supabase
      await _supabase
          .from('users')
          .update({'bookmarked_places': bookmarks}).eq('uid', user.uid);

      notifyListeners();
    } catch (e) {
      // Error handling for bookmark toggle failure
    }
  }

  Future<void> _ensurePlaceInSupabase(PlaceModel place) async {
    try {
      // First check if the place already exists in either table
      final existingPlace = await _supabase
          .from('places')
          .select('id, cached_at')
          .eq('id', place.id)
          .maybeSingle();

      // If place already exists in places table, don't update it
      if (existingPlace != null) {
        return;
      }

      // Also check if it exists in explore_places table
      final existingExplorePlace = await _supabase
          .from('explore_places')
          .select('id')
          .eq('id', place.id)
          .maybeSingle();

      // If place already exists in explore_places table, don't insert it in places table
      if (existingExplorePlace != null) {
        return;
      }

      // Only insert new places with minimal necessary data if not found in either table
      final placeData = {
        'id': place.id,
        'name': place.name,
        'name_lowercase': place.name.toLowerCase(),
        'vicinity': place.vicinity,
        'latitude': place.latitude,
        'longitude': place.longitude,
        'media_urls': place.mediaUrls,
        'types': place.types,
        'city': place.city,
        'state': place.state,
        'cached_at': DateTime.now().toIso8601String(),

        // Only include these if available but they're not essential
        'phone_number': place.phoneNumber,
        'opening_hours': place.openingHours,
        'rating': place.rating,
      };

      await _supabase.from('places').insert([placeData]);
    } catch (e) {
      // Error handling for Supabase storage failure
    }
  }

  Future<bool> isBookmarked(String placeId) async {
    try {
      final user = globalUser;
      if (user == null) return false;

      final response = await _supabase
          .from('users')
          .select('bookmarked_places')
          .eq('uid', user.uid)
          .single();

      final bookmarks = List<String>.from(response['bookmarked_places'] ?? []);
      return bookmarks.contains(placeId);
    } catch (e) {
      return false;
    }
  }

  Map<String, Map<String, List<PlaceModel>>> _organizePlacesHierarchy(
      List<PlaceModel> places) {
    final hierarchy = <String, Map<String, List<PlaceModel>>>{};

    for (final place in places) {
      final location = '${place.city ?? ''}, ${place.state ?? 'Unknown'}';

      String? category;
      for (final type in place.types) {
        if (validCategories.containsKey(type)) {
          category = validCategories[type];
          break;
        }
      }

      // If no valid category found, use "Other"
      category ??= 'Other';

      hierarchy.putIfAbsent(location, () => {});
      hierarchy[location]!.putIfAbsent(category, () => []);
      hierarchy[location]![category]!.add(place);
    }

    return hierarchy;
  }

  Future<List<PlaceModel>> getBookmarkedPlaces() async {
    try {
      final connectivityStatus =
          await ConnectivityUtils.getCurrentConnectivity();
      final hasInternet = !connectivityStatus.contains('No Internet');

      if (hasInternet) {
        // Get bookmarks from Supabase and cache them
        final user = globalUser;
        if (user == null) return [];

        final userResponse = await _supabase
            .from('users')
            .select('bookmarked_places')
            .eq('uid', user.uid)
            .single();

        final bookmarkIds =
            List<String>.from(userResponse['bookmarked_places'] ?? []);

        if (bookmarkIds.isEmpty) {
          return [];
        }

        // First try to get places from the main 'places' table
        final placesResponse =
            await _supabase.from('places').select().inFilter('id', bookmarkIds);

        // Get places from 'explore_places' table for any IDs not found in 'places'
        final foundPlaceIds =
            (placesResponse as List).map((p) => p['id']).toSet();
        final missingIds =
            bookmarkIds.where((id) => !foundPlaceIds.contains(id)).toList();

        List<dynamic> explorePlacesResponse = [];
        if (missingIds.isNotEmpty) {
          explorePlacesResponse = await _supabase
              .from('explore_places')
              .select()
              .inFilter('id', missingIds);
        }

        // Initialize base place models from both sources
        final places = <PlaceModel>[];

        // Add places from 'places' table
        places.addAll((placesResponse as List)
            .map((data) => PlaceModel.fromSupabase(data))
            .toList());
        // Add places from 'explore_places' table
        places.addAll(explorePlacesResponse
            .map((data) => PlaceModel.fromSupabase(data))
            .toList());

        // Enrich with Foursquare API data when online
        final enrichedPlaces = await _enrichPlacesWithApiData(places);

        // Cache all places locally
        for (final place in enrichedPlaces) {
          await cacheBookmarkedPlace(place);
        }

        return enrichedPlaces;
      } else {
        return await _db.getAllPlaces();
      }
    } catch (e) {
      return await _db.getAllPlaces();
    }
  }

  Future<List<PlaceModel>> _enrichPlacesWithApiData(
      List<PlaceModel> places) async {
    final dio = Dio();
    final enrichedPlaces = <PlaceModel>[];
    for (final place in places) {
      try {
        if (!place.id.startsWith('fsq_')) {
          enrichedPlaces.add(place);
          continue;
        }

        final fsqId = place.id.substring(4);

        final response = await dio.get(
          'https://api.foursquare.com/v3/places/$fsqId',
          options: Options(
            headers: {
              'Authorization': Constant.FOURSQUARE_API_KEY,
              'accept': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          final apiPlace = response.data;

          // Get photo URL
          String photoUrl = place.photoUrl ?? Constant.DEFAULT_PLACE_IMAGE;

          // Try to get photo from API response
          if (apiPlace['photos'] != null &&
              (apiPlace['photos'] as List).isNotEmpty) {
            final photo = apiPlace['photos'][0];
            photoUrl = '${photo['prefix']}original${photo['suffix']}';
          }
          // If not in main response, try separate photos endpoint
          else {
            try {
              final photosResponse = await dio.get(
                'https://api.foursquare.com/v3/places/$fsqId/photos',
                options: Options(
                  headers: {
                    'Authorization': Constant.FOURSQUARE_API_KEY,
                    'accept': 'application/json',
                  },
                ),
              );

              if (photosResponse.statusCode == 200 &&
                  photosResponse.data is List &&
                  (photosResponse.data as List).isNotEmpty) {
                final photo = photosResponse.data[0];
                photoUrl = '${photo['prefix']}original${photo['suffix']}';
              }
            } catch (e) {
              // Photo fetch error handling
            }
          } // Parse opening hours
          Map<String, String> openingHours = place.openingHours;
          if (apiPlace['hours'] != null &&
              apiPlace['hours']['regular'] != null) {
            openingHours = _parseHours(apiPlace['hours']['regular']);
          }

          // Parse price range
          PriceRange? priceRange = place.priceRange;
          if (apiPlace['price'] != null) {
            priceRange =
                PriceRange.fromPriceLevel(apiPlace['price'], apiPlace['price']);
          }

          // Create enriched place model
          final enrichedPlace = PlaceModel(
            id: place.id,
            name: place.name,
            vicinity: place.vicinity ?? _formatAddress(apiPlace['location']),
            latitude: place.latitude,
            longitude: place.longitude,
            city: place.city ?? apiPlace['location']?['locality'],
            state: place.state ?? apiPlace['location']?['region'],

            // Use API data for dynamic fields
            rating: (apiPlace['rating'] ?? 0.0) / 2,
            userRatingsTotal: apiPlace['stats']?['total_ratings'] ?? 0,
            openNow: apiPlace['hours']?['open_now'] ?? false,
            photoUrl: photoUrl,
            phoneNumber: apiPlace['tel'] ?? place.phoneNumber,
            openingHours: openingHours,
            priceRange: priceRange,
            types: place.types.isNotEmpty
                ? place.types
                : (apiPlace['categories'] as List?)
                        ?.map((c) => c['name'].toString())
                        .toList() ??
                    [],

            description: place.description ??
                (apiPlace['categories'] as List?)
                    ?.map((c) => c['name'])
                    .join(', '),
            isHiddenGem: place.isHiddenGem,
            customRating: place.customRating,
            tips: place.tips,
            extras: place.extras,
          );

          enrichedPlaces.add(enrichedPlace);
        } else {
          // If API call fails, use original place data
          enrichedPlaces.add(place);
        }
      } catch (e) {
        // If error occurs, use original place data
        enrichedPlaces.add(place);
      }
    }

    return enrichedPlaces;
  }

  String _formatAddress(Map<String, dynamic>? location) {
    if (location == null) return '';

    return [
      location['address'],
      location['cross_street'],
      location['locality'],
      location['region'],
      location['postcode']
    ].where((e) => e != null).join(', ');
  }

  Map<String, String> _parseHours(List<dynamic> hours) {
    Map<String, String> formattedHours = {};
    for (var hour in hours) {
      final day = _getDayString(hour['day']);
      final open = _formatTime(hour['open']);
      final close = _formatTime(hour['close']);
      formattedHours[day] = '$open-$close';
    }
    return formattedHours;
  }

  String _getDayString(int day) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[day % days.length];
  }

  String _formatTime(String time) {
    // Convert "0900" to "09:00"
    return '${time.substring(0, 2)}:${time.substring(2)}';
  }

  Future<Map<String, Map<String, List<PlaceModel>>>>
      getBookmarkedPlacesHierarchy() async {
    try {
      final connectivityStatus =
          await ConnectivityUtils.getCurrentConnectivity();
      final hasInternet = !connectivityStatus.contains('No Internet');

      List<PlaceModel> places = [];
      Set<String> currentBookmarkIds = {};

      if (hasInternet) {
        final user = globalUser;

        if (user != null) {
          // Get bookmarked IDs from Supabase
          final userResponse = await _supabase
              .from('users')
              .select('bookmarked_places')
              .eq('uid', user.uid)
              .single();

          currentBookmarkIds =
              Set<String>.from(userResponse['bookmarked_places'] ?? []);

          if (currentBookmarkIds.isNotEmpty) {
            // Fetch places from Supabase
            final response = await _supabase
                .from('places')
                .select()
                .inFilter('id', currentBookmarkIds.toList());

            places = (response as List)
                .map((data) => PlaceModel.fromSupabase(data))
                .toList();

            // Enrich with Foursquare API data when online
            places = await _enrichPlacesWithApiData(places);

            // Cache the places locally
            for (var place in places) {
              await cacheBookmarkedPlace(place);
            }
          }
        }
      } else {
        places = await _db.getAllPlaces();
      }

      return _organizePlacesHierarchy(places);
    } catch (e) {
      final places = await _db.getAllPlaces();
      return _organizePlacesHierarchy(places);
    }
  }
}
