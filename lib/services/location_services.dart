import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final dio = Dio();
  final supabase = Supabase.instance.client;

  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      // Only check Supabase cache, don't fall back to API
      final cachedResults = await searchLocationFromCache(query);
      debugPrint(
          'Returning ${cachedResults.length} locations from cache for query: $query');
      return cachedResults;

      // Removing API fallback code
    } catch (e) {
      debugPrint('Error searching locations: $e');
      throw Exception('Failed to search locations: $e');
    }
  }

  Future<List<LocationModel>> searchLocationFromCache(String query) async {
    try {
      final queryLower = query.toLowerCase().trim();
      debugPrint('Searching for: $queryLower');

      final response = await supabase
          .from('locations')
          .select()
          .ilike('name_lowercase', '%$queryLower%')
          .order('name_lowercase');

      if (response.isEmpty) {
        debugPrint('No results found in locations table for: $queryLower');
        return [];
      }

      debugPrint('Found ${response.length} results for: $queryLower');

      return (response as List).map((data) {
        final List<String> imageUrls =
            List<String>.from(data['image_urls'] ?? []);

        // Handle potential type mismatches with explicit conversion
        final dynamic rawRating = data['rating'];
        double rating;
        if (rawRating == null) {
          rating = 0.0;
        } else if (rawRating is int) {
          rating = rawRating.toDouble();
        } else {
          rating = (rawRating as num).toDouble();
        }

        return LocationModel(
          id: data['id'],
          name: data['name'],
          nameLowercase: data['name_lowercase'],
          imageUrls: imageUrls,
          description: data['description'] ?? '',
          latitude: data['latitude'] is int
              ? (data['latitude'] as int).toDouble()
              : data['latitude'],
          longitude: data['longitude'] is int
              ? (data['longitude'] as int).toDouble()
              : data['longitude'],
          rating: rating,
          cachedAt: data['cached_at'] != null
              ? DateTime.parse(data['cached_at'])
              : null,
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'])
              : null,
          updatedAt: data['updated_at'] != null
              ? DateTime.parse(data['updated_at'])
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Cache search error: $e');
      // Log more details about the error
      debugPrint('Error details: ${e.toString()}');
      if (e is PostgrestException) {
        debugPrint('Supabase error code: ${e.code}');
        debugPrint('Supabase error message: ${e.message}');
      }
      return [];
    }
  }

  Future<void> cacheLocations(List<LocationModel> locations) async {
    for (var location in locations) {
      try {
        // Check if document exists
        final existing =
            await supabase.from('locations').select().eq('id', location.id);

        // Check if location already exists using length instead of single()
        if (existing.isNotEmpty) {
          debugPrint('Location already exists: ${location.name}');
          continue;
        }

        final List<String> transformedUrls = location.imageUrls.toList();

        final staticData = {
          'id': location.id,
          'name': location.name,
          'image_urls': transformedUrls,
          'description': location.description,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'name_lowercase': location.name.toLowerCase(),
          'cached_at': DateTime.now().toIso8601String(),
        };

        // Insert new location
        await supabase.from('locations').insert(staticData);
        debugPrint('Successfully cached location: ${location.name}');
      } catch (e) {
        debugPrint('Error caching location ${location.id}: $e');
      }
    }
  }

  Future<PlaceModel?> getDynamicPlaceData(String placeId) async {
    try {
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'fields':
              'place_id,name,rating,user_ratings_total,opening_hours,geometry,types,photos',
          'key': Constant.GOOGLE_API,
        },
      );

      if (response.statusCode == 200) {
        final result = response.data['result'];
        if (result == null) return null;

        return PlaceModel(
          id: result['place_id'] ?? placeId,
          name: result['name'] ?? '',
          rating: (result['rating'] ?? 0.0).toDouble(),
          userRatingsTotal: result['user_ratings_total'] ?? 0,
          openNow: result['opening_hours']?['open_now'] ?? false,
          latitude: result['geometry']?['location']?['lat'] ?? 0.0,
          longitude: result['geometry']?['location']?['lng'] ?? 0.0,
          types:
              (result['types'] as List?)?.map((t) => t.toString()).toList() ??
                  [],
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting dynamic place data: $e');
      return null;
    }
  }

  Future<List<PlaceModel>> getNearbyPlaces(
    double lat,
    double lng,
    String type,
  ) async {
    try {
      // Check cache first
      final cachedPlacesStream = await searchPlacesFromCache(lat, lng, type);
      final cachedPlaces = await cachedPlacesStream.toList();
      if (cachedPlaces.isNotEmpty) {
        return cachedPlaces;
      }

      // If no cache, call Google Places API
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        queryParameters: {
          'location': '$lat,$lng',
          'radius': '5000',
          'type': type,
          'key': Constant.GOOGLE_API,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Google Places API Error: ${response.statusCode}');
      }

      final places = _parsePlacesFromGoogleResponse(response.data, lat, lng);

      // Cache places
      await cachePlaces(places);

      return places;
    } catch (e) {
      debugPrint('Error getting nearby places: $e');
      throw Exception('Failed to get nearby places: $e');
    }
  }

  Future<void> cachePlaces(List<PlaceModel> places,
      {String? currentCategory}) async {
    debugPrint('📝 Starting to cache ${places.length} places...');
    int cached = 0;
    int skipped = 0;
    int errors = 0;

    for (var place in places) {
      try {
        // Check if place exists in either 'places' or 'explore_places' table
        final existingInPlaces =
            await supabase.from('places').select('id').eq('id', place.id);

        final existingInExplorePlaces = await supabase
            .from('explore_places')
            .select('id')
            .eq('id', place.id);

        if (existingInPlaces.isNotEmpty || existingInExplorePlaces.isNotEmpty) {
          skipped++;
          continue;
        }

        // Only cache essential static data with media URLs
        final staticData = {
          'id': place.id,
          'name': place.name,
          'name_lowercase': place.name.toLowerCase(),
          'vicinity': place.vicinity,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'city': place.city,
          'state': place.state,
          'cached_at': DateTime.now().toIso8601String(),
          'types': currentCategory != null ? [currentCategory] : [],
          'media_urls': place.mediaUrls,
          'media_cached_at': place.mediaCachedAt?.toIso8601String(),
          'media_expires_at': place.mediaExpiresAt?.toIso8601String(),
        };

        await supabase.from('places').insert(staticData);
        cached++;
        debugPrint(
            '✅ Cached place: ${place.name} with ${place.mediaUrls.length} media URLs');
      } catch (e) {
        debugPrint('❌ Error caching place ${place.id}: $e');
        errors++;
      }
    }

    debugPrint('📊 Caching Summary:');
    debugPrint('✅ Successfully cached: $cached');
    debugPrint('⏭️ Skipped (already exists): $skipped');
    debugPrint('❌ Errors: $errors');
    debugPrint('📝 Total processed: ${places.length}');
  }

  Future<Stream<PlaceModel>> searchPlacesFromCache(
    double lat,
    double lng,
    String? type, {
    String? searchQuery,
    double radiusInKm = 150,
  }) async {
    final controller = StreamController<PlaceModel>();

    Future(() async {
      try {
        var query = supabase.from('places').select();

        if (type != null) {
          query = query.contains('types', [type]);
        }

        if (searchQuery != null) {
          query =
              query.ilike('name_lowercase', '%${searchQuery.toLowerCase()}%');
        }

        // Add retry logic for network issues
        int retryCount = 0;
        List<dynamic>? response;

        while (retryCount < 3 && response == null) {
          try {
            response = await query;
            // Debug print the response with emoji
            debugPrint('📦 Supabase places query response: $response');
            break;
          } catch (e) {
            retryCount++;
            if (retryCount < 3) {
              await Future.delayed(Duration(seconds: retryCount * 2));
            }
          }
        }

        if (response == null || response.isEmpty) {
          await controller.close();
          return;
        }

        int errorCount = 0;
        int customPlaceCount = 0;

        // Store custom place info for later reporting
        Map<String, double> customPlaceDistances = {};

        for (var data in response) {
          try {
            final placeId = data['id'] ?? 'unknown_id';

            // Only print debug information for custom places
            if (placeId.startsWith('pcustom_')) {
              customPlaceCount++;
              print(
                  'Processing custom place ID: $placeId, Name: ${data['name']}');
            }

            // Check for type issues before they occur
            if (data['latitude'] is int) {
              data['latitude'] = (data['latitude'] as int).toDouble();
              if (placeId.startsWith('pcustom_')) {
                print(
                    'Converting int latitude to double for custom place: $placeId');
              }
            }

            if (data['longitude'] is int) {
              data['longitude'] = (data['longitude'] as int).toDouble();
              if (placeId.startsWith('pcustom_')) {
                print(
                    'Converting int longitude to double for custom place: $placeId');
              }
            }

            if (data['rating'] is int) {
              data['rating'] = (data['rating'] as int).toDouble();
              if (placeId.startsWith('pcustom_')) {
                print(
                    'Converting int rating to double for custom place: $placeId');
              }
            }

            if (data['custom_rating'] is int) {
              data['custom_rating'] = (data['custom_rating'] as int).toDouble();
              if (placeId.startsWith('pcustom_')) {
                print(
                    'Converting int custom_rating to double for custom place: $placeId');
              }
            }

            final distance = Geolocator.distanceBetween(
              lat,
              lng,
              data['latitude'],
              data['longitude'],
            );

            // Store distance for custom places
            if (placeId.startsWith('pcustom_')) {
              customPlaceDistances[placeId] = distance;
              print(
                  'Custom place $placeId (${data['name']}): distance = ${(distance / 1000).toStringAsFixed(2)} km');
            }

            if (distance <= (radiusInKm * 1000)) {
              // Debug print for places within the radius

              final place = PlaceModel(
                id: placeId,
                name: data['name'],
                vicinity: data['vicinity'] ?? '',
                latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
                longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
                photoUrl: data['photo_url'] ?? Constant.DEFAULT_PLACE_IMAGE,
                mediaUrls: data['media_urls'] != null
                    ? List<String>.from(data['media_urls'])
                    : [],
                types: List<String>.from(data['types'] ?? []),
                rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
                userRatingsTotal: data['user_ratings_total'] ?? 0,
                openNow:
                    false, // Foursquare doesn't provide real-time open status
                description: data['description'],
                distanceFromUser: distance,
                customRating:
                    (data['custom_rating'] as num?)?.toDouble() ?? 0.0,
                phoneNumber: data['phone_number'],
                openingHours:
                    Map<String, String>.from(data['opening_hours'] ?? {}),
                priceRange: data['price_range'] != null
                    ? PriceRange.fromMap(
                        Map<String, dynamic>.from(data['price_range']))
                    : null,
                city: data['city'],
                state: data['state'],
                isHiddenGem: data['is_hidden_gem'] ?? false,
                tips: data['tips'],
                extras: data['extras'],
                mediaCachedAt: data['media_cached_at'] != null
                    ? DateTime.parse(data['media_cached_at'])
                    : null,
                mediaExpiresAt: data['media_expires_at'] != null
                    ? DateTime.parse(data['media_expires_at'])
                    : null,
                mediaLastValidatedAt: data['media_last_validated_at'] != null
                    ? DateTime.parse(data['media_last_validated_at'])
                    : null,
                mediaRefreshNeeded: data['media_refresh_needed'] ?? false,
              );

              controller.add(place);

              if (placeId.startsWith('pcustom_')) {
                print(
                    'Successfully processed custom place: $placeId (matched within ${radiusInKm}km radius)');
              }
            } else if (placeId.startsWith('pcustom_')) {
              print(
                  'Custom place $placeId is outside the ${radiusInKm}km radius (distance: ${(distance / 1000).toStringAsFixed(2)} km)');
            }
          } catch (e, stackTrace) {
            errorCount++;
            final placeId = data['id'] ?? 'unknown_id';

            if (placeId.startsWith('pcustom_')) {
              print('ERROR processing custom place ID: $placeId');
              print('Error details: $e');
              print('Data that caused error:');
              data.forEach((key, value) {
                print('  $key: $value (${value?.runtimeType})');
              });
              print('Stack trace: $stackTrace');
            }
          }
        }

        if (customPlaceCount > 0) {
          print('Custom places summary:');
          print('Total custom places found: $customPlaceCount');
          print('Successfully processed: ${customPlaceCount - errorCount}');
          print('Errors: $errorCount');

          // Print distance summary for all custom places
          print('Distance summary for custom places:');
          customPlaceDistances.forEach((placeId, distance) {
            final isWithinRadius = distance <= (radiusInKm * 1000);
            print(
                '  $placeId: ${(distance / 1000).toStringAsFixed(2)} km ${isWithinRadius ? "(within radius)" : "(outside radius)"}');
          });

          // Check if any custom places are outside radius
          final outsideRadius = customPlaceDistances.entries
              .where((entry) => entry.value > (radiusInKm * 1000))
              .length;

          if (outsideRadius > 0) {
            print(
                'WARNING: $outsideRadius custom places are outside the ${radiusInKm}km radius');
          }
        }
      } catch (e) {
        print('Cache search error: $e');
      } finally {
        await controller.close();
      }
    });

    return controller.stream;
  }

  Future<List<LocationModel>> searchLocationsFromAPI(String query) async {
    try {
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/textsearch/json',
        queryParameters: {
          'query': query,
          'type': 'locality',
          'key': Constant.GOOGLE_API,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Google Places API Error: ${response.statusCode}');
      }

      final results = response.data['results'] as List;
      List<LocationModel> locations = [];
      Set<String> addedCities = {}; // To prevent duplicate cities

      for (var result in results) {
        final cityName = result['name'];
        final formattedAddress = result['formatted_address'];

        // Skip if already added
        if (cityName == null || addedCities.contains(cityName.toLowerCase())) {
          continue;
        }

        List<String> imageUrls = [];
        if (result['photos'] != null && (result['photos'] as List).isNotEmpty) {
          for (var photo in (result['photos'] as List).take(3)) {
            final photoReference = photo['photo_reference'];
            final imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';
            imageUrls.add(imageUrl);
            debugPrint('Added image URL for $cityName: $imageUrl');
          }
        }

        // Add default image if no photos found
        if (imageUrls.isEmpty) {
          imageUrls.add(Constant.DEFAULT_PLACE_IMAGE);
          debugPrint(
              'Using default image for $cityName: ${Constant.DEFAULT_PLACE_IMAGE}');
        }

        final locationModel = LocationModel(
          id: result['place_id'],
          name: cityName,
          nameLowercase: cityName.toLowerCase(),
          imageUrls: imageUrls,
          description: formattedAddress ?? '',
          latitude: result['geometry']['location']['lat'],
          longitude: result['geometry']['location']['lng'],
          rating: (result['rating'] ?? 0.0).toDouble(),
        );

        locations.add(locationModel);
        addedCities.add(cityName.toLowerCase());
      }

      // Debug print all locations and their images
      for (var location in locations) {
        debugPrint('Location: ${location.name}');
        debugPrint('Images: ${location.imageUrls}');
      }

      return locations;
    } catch (e) {
      debugPrint('Error searching locations: $e');
      throw Exception('Failed to search locations: $e');
    }
  }

  Future<List<PlaceModel>> getNearbyPlacesFromAPI(
    double lat,
    double lng,
    String type,
  ) async {
    try {
      List<PlaceModel> places = [];
      String? nextPageToken;
      int maxPages = 3; // Limit number of pages to fetch

      do {
        final queryParams = {
          'location': '$lat,$lng',
          'radius': '5000',
          'type': type,
          'key': Constant.GOOGLE_API,
        };

        if (nextPageToken != null) {
          queryParams['pagetoken'] = nextPageToken;
          // Add a delay before making the next request as required by Google Places API
          await Future.delayed(const Duration(seconds: 2));
        }

        final response = await dio.get(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
          queryParameters: queryParams,
        );

        if (response.statusCode != 200) {
          throw Exception('Google Places API Error: ${response.statusCode}');
        }

        nextPageToken = response.data['next_page_token'];
        maxPages--;

        final fetchedPlaces =
            _parsePlacesFromGoogleResponse(response.data, lat, lng);
        places.addAll(fetchedPlaces);
      } while (nextPageToken != null && maxPages > 0);

      return places;
    } catch (e) {
      debugPrint('Error getting nearby places: $e');
      throw Exception('Failed to get nearby places: $e');
    }
  }

  Future<List<PlaceModel>> searchPlacesForSearchScreen(
    String query,
    double userLat,
    double userLng, {
    int radius = 50000 *
        100, // Just to return places if they exist in DB irrespective of their distance from user
    int maxResults = 5,
  }) async {
    try {
      // Only check cache, don't fall back to API
      final cachedPlaces = await searchPlacesFromCacheForSearch(
        query,
        userLat,
        userLng,
        radius: radius,
        maxResults: maxResults,
      );

      debugPrint(
          'Returning ${cachedPlaces.length} places from cache for search query: $query');
      return cachedPlaces;
    } catch (e) {
      debugPrint('Error searching places: $e');
      throw Exception('Failed to search places: $e');
    }
  }

  Future<PlaceSearchResult> searchPlacesForCategory(
    double lat,
    double lng,
    String type, {
    int radius = 50000,
    String? keywords,
    String? pageToken,
  }) async {
    try {
      debugPrint('🔍 Searching places for category: $type');
      debugPrint('📍Current lat: $lat, lng: $lng'); // <-- Added debug print
      List<PlaceModel> places = [];
      Map<String, PlaceModel> cachedPlacesMap = {};

      // Step 1: Get cached places - Make sure this always runs, even with a pageToken
      final cachedPlacesStream = await searchPlacesFromCache(lat, lng, type,
          radiusInKm: radius / 1000);
      final cachedPlaces = await cachedPlacesStream.toList();

      // Debug print custom places
      final customPlaces =
          cachedPlaces.where((p) => p.id.startsWith('pcustom_')).toList();
      if (customPlaces.isNotEmpty) {
        print('Found ${customPlaces.length} custom places for category $type:');
        for (var place in customPlaces) {
          print(
              'Custom place in results: ${place.id} (${place.name}) - distance: ${(place.distanceFromUser! / 1000).toStringAsFixed(2)} km');
        }
      }

      cachedPlacesMap = {for (var place in cachedPlaces) place.id: place};
      debugPrint('📦 Found ${cachedPlaces.length} places in cache');

      if (pageToken == null) {
        // Step 2: Get API data using Google Places API
        try {
          final queryParams = {
            'location': '$lat,$lng',
            'radius': radius.toString(),
            'type': type,
            'key': Constant.GOOGLE_API,
          };

          if (pageToken != null) {
            queryParams['pagetoken'] = pageToken;
            // Add a delay before making the next request as required by Google Places API
            await Future.delayed(const Duration(seconds: 2));
          }

          final response = await dio.get(
            'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
            queryParameters: queryParams,
          );

          if (response.statusCode == 200) {
            final results = response.data['results'] as List;

            print(
                '📊Google Places API results: ${results.length} places found');
            final nextPageToken = response.data['next_page_token'];
            List<PlaceModel> newPlaces = [];

            // Step 3: Process and merge API places
            for (var apiPlace in results) {
              try {
                final String placeId = apiPlace['place_id'];
                final geometry = apiPlace['geometry'];
                final location = geometry['location'];
                final placeLat = location['lat'] as double;
                final placeLng = location['lng'] as double;
                final cachedPlace = cachedPlacesMap[placeId];

                // Extract media URLs from photos (up to 4)
                List<String> mediaUrls = [];
                String photoUrl = Constant.DEFAULT_PLACE_IMAGE;
                if (apiPlace['photos'] != null &&
                    (apiPlace['photos'] as List).isNotEmpty) {
                  final photos = apiPlace['photos'] as List;
                  for (var photo in photos.take(4)) {
                    final photoReference = photo['photo_reference'];
                    final imageUrl =
                        'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';
                    mediaUrls.add(imageUrl);
                  }
                  photoUrl = mediaUrls.isNotEmpty
                      ? mediaUrls.first
                      : Constant.DEFAULT_PLACE_IMAGE;
                }

                final placeModel = PlaceModel(
                  id: cachedPlace?.id ?? placeId,
                  name: cachedPlace?.name ?? apiPlace['name'],
                  vicinity:
                      cachedPlace?.vicinity ?? (apiPlace['vicinity'] ?? ''),
                  latitude: cachedPlace?.latitude ?? placeLat,
                  longitude: cachedPlace?.longitude ?? placeLng,

                  // Only use API data if cache data is null
                  rating: cachedPlace?.rating ??
                      (apiPlace['rating'] ?? 0.0).toDouble(),
                  userRatingsTotal: cachedPlace?.userRatingsTotal ??
                      (apiPlace['user_ratings_total'] ?? 0),
                  openNow: apiPlace['opening_hours']?['open_now'] ??
                      false, // Always use API for real-time status
                  photoUrl: (cachedPlace?.photoUrl == null ||
                          cachedPlace?.photoUrl == '' ||
                          cachedPlace?.photoUrl == Constant.DEFAULT_PLACE_IMAGE)
                      ? photoUrl
                      : cachedPlace!.photoUrl,
                  mediaUrls: cachedPlace?.mediaUrls.isNotEmpty == true
                      ? cachedPlace!.mediaUrls
                      : mediaUrls,
                  priceRange: cachedPlace?.priceRange ??
                      (apiPlace['price_level'] != null
                          ? PriceRange.fromPriceLevel(
                              apiPlace['price_level'], apiPlace['price_level'])
                          : null),
                  types: cachedPlace?.types.isNotEmpty == true
                      ? cachedPlace!.types
                      : List<String>.from(apiPlace['types'] ?? []),

                  // Calculate distance using most accurate coordinates
                  distanceFromUser: Geolocator.distanceBetween(
                    lat,
                    lng,
                    cachedPlace?.latitude ?? placeLat,
                    cachedPlace?.longitude ?? placeLng,
                  ),

                  // Additional fields - use cached values if available
                  description: cachedPlace?.description ??
                      List<String>.from(apiPlace['types'] ?? []).join(', '),
                  isHiddenGem: cachedPlace?.isHiddenGem ?? false,
                  customRating: cachedPlace?.customRating ?? 0,
                  tips: cachedPlace?.tips,
                  extras: cachedPlace?.extras,
                  phoneNumber: cachedPlace?.phoneNumber,
                  openingHours: cachedPlace?.openingHours ?? {},
                  city: cachedPlace?.city,
                  state: cachedPlace?.state,
                );

                places.add(placeModel);

                // Remove from cached map to prevent duplicates
                cachedPlacesMap.remove(placeId);

                // Only add to newPlaces if not already cached
                if (cachedPlace == null) {
                  newPlaces.add(placeModel);
                }
              } catch (e) {
                debugPrint('❌ Error processing API place: $e');
              }
            }

            // Cache new places in background
            if (newPlaces.isNotEmpty) {
              debugPrint('📦 Caching ${newPlaces.length} new places...');
              cachePlaces(newPlaces, currentCategory: type.toLowerCase())
                  .catchError((e) => debugPrint('❌ Error caching places: $e'));
            }

            // Add remaining custom places that weren't matched with API data
            // This is the key fix - make sure ALL custom places get included
            for (var entry in cachedPlacesMap.entries) {
              if (entry.key.startsWith('pcustom_')) {
                print(
                    'Adding remaining custom place: ${entry.key} (${entry.value.name})');
                places.add(entry.value);
              }
            }

            // Sort places by rating and distance
            places.sort((a, b) {
              // Put custom places with high ratings at the top
              if (a.id.startsWith('pcustom_') && !b.id.startsWith('pcustom_')) {
                return -1; // Custom places first
              } else if (!a.id.startsWith('pcustom_') &&
                  b.id.startsWith('pcustom_')) {
                return 1; // Custom places first
              }

              // Then sort by rating
              if ((a.rating - b.rating).abs() > 0.1) {
                return b.rating.compareTo(a.rating);
              }

              // For similar ratings, sort by distance
              return (a.distanceFromUser ?? double.infinity)
                  .compareTo(b.distanceFromUser ?? double.infinity);
            });

            return PlaceSearchResult(
              places: places,
              nextPageToken: nextPageToken,
            );
          }
        } catch (e) {
          debugPrint('❌ Error fetching from API: $e');
          // Continue with just the cached places if API fails
        }
      }

      // If we get here, either API call failed or we just want cached results
      // Sort cached places and return them
      cachedPlaces.sort((a, b) {
        if (a.id.startsWith('pcustom_') && !b.id.startsWith('pcustom_')) {
          return -1; // Custom places first
        } else if (!a.id.startsWith('pcustom_') &&
            b.id.startsWith('pcustom_')) {
          return 1; // Custom places first
        }

        if ((a.rating - b.rating).abs() > 0.1) {
          return b.rating.compareTo(a.rating);
        }

        return (a.distanceFromUser ?? double.infinity)
            .compareTo(b.distanceFromUser ?? double.infinity);
      });

      return PlaceSearchResult(
        places: cachedPlaces,
        nextPageToken: null, // No next page when using only cache
      );
    } catch (e) {
      debugPrint('❌ Error in searchPlacesForCategory: $e');
      throw Exception('Failed to search places for category: $e');
    }
  }

  Future<List<PlaceModel>> searchHiddenGemsFromCache(double lat, double lng,
      {double radiusInKm = 200}) async {
    try {
      debugPrint('🔍 Searching for hidden gems in cache...');
      List<PlaceModel> hiddenGems = [];
      Map<String, PlaceModel> cachedPlacesMap = {};

      // Step 1: Get cached places from Supabase
      final response =
          await supabase.from('places').select().eq('is_hidden_gem', true);

      // Create a map of cached places for quick lookup
      for (var data in response) {
        try {
          final distance = Geolocator.distanceBetween(
            lat,
            lng,
            data['latitude'],
            data['longitude'],
          );

          // Only include places within radius
          if (distance <= (radiusInKm * 1000)) {
            final place = PlaceModel(
              id: data['id'],
              name: data['name'],
              vicinity: data['vicinity'] ?? '',
              latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
              photoUrl: data['photo_url'] ?? Constant.DEFAULT_PLACE_IMAGE,
              mediaUrls: data['media_urls'] != null
                  ? List<String>.from(data['media_urls'])
                  : [],
              types: List<String>.from(data['types'] ?? []),
              rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
              userRatingsTotal: data['user_ratings_total'] ?? 0,
              openNow: false,
              distanceFromUser: distance,
              description: data['description'],
              customRating: (data['custom_rating'] as num?)?.toDouble() ?? 0.0,
              phoneNumber: data['phone_number'],
              openingHours:
                  Map<String, String>.from(data['opening_hours'] ?? {}),
              priceRange: data['price_range'] != null
                  ? PriceRange.fromMap(
                      Map<String, dynamic>.from(data['price_range']))
                  : null,
              city: data['city'],
              state: data['state'],
              isHiddenGem: true,
              tips: data['tips'],
              extras: data['extras'],
              mediaCachedAt: data['media_cached_at'] != null
                  ? DateTime.parse(data['media_cached_at'])
                  : null,
              mediaExpiresAt: data['media_expires_at'] != null
                  ? DateTime.parse(data['media_expires_at'])
                  : null,
              mediaLastValidatedAt: data['media_last_validated_at'] != null
                  ? DateTime.parse(data['media_last_validated_at'])
                  : null,
              mediaRefreshNeeded: data['media_refresh_needed'] ?? false,
            );
            cachedPlacesMap[data['id']] = place;
          }
        } catch (e) {
          debugPrint('❌ Error processing cached hidden gem: $e');
        }
      }

      debugPrint('📦 Found ${cachedPlacesMap.length} hidden gems in cache');

      // Step 2: Get fresh data from API for each place
      for (var entry in cachedPlacesMap.entries) {
        final place = entry.value;

        // Only get fresh data for Google Places (not custom places)
        if (!place.id.startsWith('pcustom_')) {
          try {
            final response = await dio.get(
              'https://maps.googleapis.com/maps/api/place/details/json',
              queryParameters: {
                'place_id': place.id,
                'fields':
                    'place_id,name,rating,user_ratings_total,opening_hours,geometry,types,photos',
                'key': Constant.GOOGLE_API,
              },
            );

            if (response.statusCode == 200) {
              final apiPlace = response.data['result'];

              // Debug log API data
              debugPrint('\n🔍 Processing hidden gem: ${place.name}');
              debugPrint('📍 API Data keys: ${apiPlace?.keys.toList()}');
              debugPrint('ID: ${place.id}');

              String photoUrl = Constant.DEFAULT_PLACE_IMAGE;
              if (apiPlace?['photos'] != null &&
                  (apiPlace!['photos'] as List).isNotEmpty) {
                final photo = apiPlace['photos'][0];
                final photoReference = photo['photo_reference'];
                photoUrl =
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';
                debugPrint('📸 Found photo from API: $photoUrl');
              }

              // Debug log cached data
              debugPrint('\n💾 Cached Data:');
              debugPrint('ID: ${place.id}');
              debugPrint('Name: ${place.name}');
              debugPrint('Rating: ${place.rating}');
              debugPrint('Hidden Gem: ${place.isHiddenGem}');

              // Create place model with merged data
              final placeModel = PlaceModel(
                id: place.id,
                name: place.name,
                vicinity: place.vicinity,
                latitude: place.latitude,
                longitude: place.longitude,
                city: place.city,
                state: place.state,

                // Always use API data for dynamic fields
                rating: (apiPlace?['rating'] ?? 0.0).toDouble(),
                userRatingsTotal: apiPlace?['user_ratings_total'] ?? 0,
                openNow: apiPlace?['opening_hours']?['open_now'] ?? false,
                photoUrl: photoUrl,
                types: List<String>.from(apiPlace?['types'] ?? place.types),

                distanceFromUser: place.distanceFromUser,
                description: place.description ??
                    List<String>.from(apiPlace?['types'] ?? []).join(', '),
                isHiddenGem: true,
                customRating: place.customRating,
                tips: place.tips,
                extras: place.extras,
                phoneNumber: place.phoneNumber,
                openingHours: place.openingHours,
                priceRange: place.priceRange,
              );

              // Debug log final merged data
              debugPrint('\n🔄 Merged Data:');
              debugPrint('Final Name: ${placeModel.name}');
              debugPrint('Final Rating: ${placeModel.rating}');
              debugPrint('Final Photo URL: ${placeModel.photoUrl}');
              debugPrint('Hidden Gem Status: ${placeModel.isHiddenGem}');
              debugPrint(
                  'Distance: ${placeModel.distanceFromUser?.toStringAsFixed(2)}m');
              debugPrint('----------------------------------------');

              hiddenGems.add(placeModel);
            } else {
              // If API call fails, use cached data
              hiddenGems.add(place);
              debugPrint(
                  '❌ API call failed for ${place.name}, using cached data');
            }
          } catch (e) {
            // If error occurs, use cached data
            hiddenGems.add(place);
            debugPrint('❌ Error getting API data for ${place.name}: $e');
          }
        } else {
          // For custom places, just use cached data
          hiddenGems.add(place);
        }
      }

      // Sort by distance
      hiddenGems.sort((a, b) => (a.distanceFromUser ?? double.infinity)
          .compareTo(b.distanceFromUser ?? double.infinity));

      debugPrint(
          'Returning ${hiddenGems.length} hidden gems within ${radiusInKm}km');
      return hiddenGems;
    } catch (e) {
      debugPrint('❌ Error searching hidden gems: $e');
      return [];
    }
  }

  // Helper method to parse places from Google Places API response
  List<PlaceModel> _parsePlacesFromGoogleResponse(
    Map<String, dynamic> data,
    double lat,
    double lng,
  ) {
    final results = data['results'] as List;
    return results
        .map((place) {
          try {
            final geometry = place['geometry'];
            final location = geometry['location'];
            final placeLat = location['lat'] as double;
            final placeLng = location['lng'] as double;

            final distance = Geolocator.distanceBetween(
              lat,
              lng,
              placeLat,
              placeLng,
            );
 
            // Extract media URLs from photos (up to 4)
            List<String> mediaUrls = [];
            if (place['photos'] != null &&
                (place['photos'] as List).isNotEmpty) {
              final photos = place['photos'] as List;
              for (var photo in photos.take(4)) {
                final photoReference = photo['photo_reference'];
                final imageUrl =
                    'https://maps.googleapis.com/maps/api/place/photo?maxwidth=1000&photoreference=$photoReference&key=${Constant.GOOGLE_API}';
                mediaUrls.add(imageUrl);
              }
            }

            return PlaceModel(
              id: place['place_id'],
              name: place['name'],
              vicinity: place['vicinity'] ?? '',
              rating: (place['rating'] ?? 0.0).toDouble(),
              userRatingsTotal: place['user_ratings_total'] ?? 0,
              latitude: placeLat,
              longitude: placeLng,
              photoUrl: mediaUrls.isNotEmpty
                  ? mediaUrls.first
                  : null, // Keep for backward compatibility
              mediaUrls: mediaUrls,
              openNow: place['opening_hours']?['open_now'] ?? false,
              types: List<String>.from(place['types'] ?? []),
              distanceFromUser: distance,
              priceRange: place['price_level'] != null
                  ? PriceRange.fromPriceLevel(
                      place['price_level'], place['price_level'])
                  : null,
              isHiddenGem: false,
              description: List<String>.from(place['types'] ?? []).join(', '),
              mediaCachedAt: DateTime.now(), // Set current time for new places
              mediaExpiresAt:
                  DateTime.now().add(Duration(days: 25)), // Expires in 25 days
            );
          } catch (e) {
            debugPrint('Error parsing place: $e');
            return null;
          }
        })
        .whereType<PlaceModel>()
        .toList();
  }

  Future<List<PlaceModel>> searchPlacesFromCacheForSearch(
    String query,
    double userLat,
    double userLng, {
    int radius = 50000,
    int maxResults = 5,
  }) async {
    try {
      debugPrint('📦 Searching Supabase cache for: $query');
      final response = await supabase
          .from('places')
          .select()
          .ilike('name_lowercase', '%${query.toLowerCase()}%')
          .limit(maxResults);

      final List<PlaceModel> places = [];

      for (var data in response) {
        final String placeId = data['id'];

        final distance = Geolocator.distanceBetween(
          userLat,
          userLng,
          data['latitude'],
          data['longitude'],
        );

        // Only include places within radius
        if (distance <= radius) {
          double rating = 0.0;
          int userRatingsTotal = 0;
          bool openNow = false;

          // Only call Places API if not a custom place
          if (!placeId.startsWith('pcustom_')) {
            final dynamicData = await getDynamicPlaceData(placeId);
            if (dynamicData != null) {
              rating = dynamicData.rating;
              userRatingsTotal = dynamicData.userRatingsTotal;
              openNow = dynamicData.openNow;
            }
          }

          final customRating = data['custom_rating']?.toDouble() ?? 0.0;

          final place = PlaceModel(
            id: placeId,
            name: data['name'],
            vicinity: data['vicinity'] ?? '',
            latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
            photoUrl: data['photo_url'] ?? Constant.DEFAULT_PLACE_IMAGE,
            mediaUrls: data['media_urls'] != null
                ? List<String>.from(data['media_urls'])
                : [],
            types: List<String>.from(data['types'] ?? []),
            rating: placeId.startsWith('pcustom_') ? customRating : rating,
            userRatingsTotal: userRatingsTotal,
            openNow: openNow,
            distanceFromUser: distance,
            customRating: customRating,
            phoneNumber: data['phone_number'],
            openingHours: Map<String, String>.from(data['opening_hours'] ?? {}),
            priceRange: data['price_range'] != null
                ? PriceRange.fromMap(
                    Map<String, dynamic>.from(data['price_range']))
                : null,
            city: data['city'],
            state: data['state'],
            isHiddenGem: data['is_hidden_gem'] ?? false,
            tips: data['tips'],
            extras: data['extras'],
            mediaCachedAt: data['media_cached_at'] != null
                ? DateTime.parse(data['media_cached_at'])
                : null,
            mediaExpiresAt: data['media_expires_at'] != null
                ? DateTime.parse(data['media_expires_at'])
                : null,
            mediaLastValidatedAt: data['media_last_validated_at'] != null
                ? DateTime.parse(data['media_last_validated_at'])
                : null,
            mediaRefreshNeeded: data['media_refresh_needed'] ?? false,
          );
          places.add(place);
        }
      }

      // Sort by distance
      places.sort((a, b) => (a.distanceFromUser ?? double.infinity)
          .compareTo(b.distanceFromUser ?? double.infinity));

      if (places.isNotEmpty) {
        debugPrint(
            '✅ Found ${places.length} places in cache for search: $query');
      }

      return places;
    } catch (e) {
      debugPrint('❌ Cache search error: $e');
      return [];
    }
  }

  /// Fetch places with id prefix 'pcustom_' for a given city
  Future<List<PlaceModel>> fetchCustomPlacesForCity(String cityName) async {
    try {
      final response = await supabase
          .from('places')
          .select()
          .ilike('id', 'pcustom_%')
          .eq('city', cityName);

      if (response.isEmpty) {
        debugPrint('No custom places found for city: $cityName');
        return [];
      }

      return (response as List).map((data) {
        return PlaceModel(
          id: data['id'],
          name: data['name'],
          vicinity: data['vicinity'] ?? '',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          photoUrl: data['photo_url'] ?? Constant.DEFAULT_PLACE_IMAGE,
          mediaUrls: data['media_urls'] != null
              ? List<String>.from(data['media_urls'])
              : [],
          types: List<String>.from(data['types'] ?? []),
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          userRatingsTotal: data['user_ratings_total'] ?? 0,
          openNow: false,
          description: data['description'],
          distanceFromUser: null,
          customRating: (data['custom_rating'] as num?)?.toDouble() ?? 0.0,
          phoneNumber: data['phone_number'],
          openingHours: Map<String, String>.from(data['opening_hours'] ?? {}),
          priceRange: data['price_range'] != null
              ? PriceRange.fromMap(
                  Map<String, dynamic>.from(data['price_range']))
              : null,
          city: data['city'],
          state: data['state'],
          isHiddenGem: data['is_hidden_gem'] ?? false,
          tips: data['tips'],
          extras: data['extras'],
          mediaCachedAt: data['media_cached_at'] != null
              ? DateTime.parse(data['media_cached_at'])
              : null,
          mediaExpiresAt: data['media_expires_at'] != null
              ? DateTime.parse(data['media_expires_at'])
              : null,
          mediaLastValidatedAt: data['media_last_validated_at'] != null
              ? DateTime.parse(data['media_last_validated_at'])
              : null,
          mediaRefreshNeeded: data['media_refresh_needed'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching custom places for city: $e');
      return [];
    }
  }

  /// Fetch top rated custom places from other cities (id prefix pcustom_, city != current city)
  Future<List<PlaceModel>> fetchTopRatedCustomPlacesFromOtherCities(
      String currentCity,
      {int limit = 20}) async {
    try {
      final response = await supabase
          .from('places')
          .select()
          .ilike('id', 'pcustom_%')
          .neq('city', currentCity);
      if (response.isEmpty) return [];
      final places = (response as List).map((data) {
        return PlaceModel(
          id: data['id'],
          name: data['name'],
          vicinity: data['vicinity'] ?? '',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          photoUrl: data['photo_url'] ?? Constant.DEFAULT_PLACE_IMAGE,
          types: List<String>.from(data['types'] ?? []),
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          userRatingsTotal: data['user_ratings_total'] ?? 0,
          openNow: false,
          description: data['description'],
          distanceFromUser: null,
          customRating: (data['custom_rating'] as num?)?.toDouble() ?? 0.0,
          phoneNumber: data['phone_number'],
          openingHours: Map<String, String>.from(data['opening_hours'] ?? {}),
          priceRange: data['price_range'] != null
              ? PriceRange.fromMap(
                  Map<String, dynamic>.from(data['price_range']))
              : null,
          city: data['city'],
          state: data['state'],
          isHiddenGem: data['is_hidden_gem'] ?? false,
          tips: data['tips'],
          extras: data['extras'],
        );
      }).toList();
      places.sort((a, b) => b.rating.compareTo(a.rating));
      return places.take(limit).toList();
    } catch (e) {
      debugPrint(
          'Error fetching top rated custom places from other cities: $e');
      return [];
    }
  }
}

class PlaceSearchResult {
  final List<PlaceModel> places;
  final String? nextPageToken;
  final int? lastOffset;

  PlaceSearchResult({
    required this.places,
    this.nextPageToken,
    this.lastOffset,
  });
}
