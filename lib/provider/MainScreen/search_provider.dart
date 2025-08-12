import 'package:flutter/material.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/services/location_services.dart';
import 'package:street_buddy/services/voice_search_service.dart';
import 'package:street_buddy/services/search_service.dart';
import 'package:geolocator/geolocator.dart';

enum SearchType { users, locations, places }

class SearchProvider extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  List<UserModel> userResults = [];
  List<LocationModel> locationResults = [];
  List<PlaceModel> placeResults = [];
  SearchType activeSearchType = SearchType.locations;
  final LocationService _locationService = LocationService();
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  Position? _userPosition;
  Position? get userPosition => _userPosition;

  // Custom query tile state
  bool isCustomQueryLoading = false;
  bool showNoResultFound = false;

  // Voice search properties
  bool _isVoiceSearching = false;
  bool _isListening = false;
  String _voiceSearchText = '';

  List<LocationModel> featuredCities = [];

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Voice search getters
  bool get isVoiceSearching => _isVoiceSearching;
  bool get isListening => _isListening;
  String get voiceSearchText => _voiceSearchText;

  // Initialize user location
  Future<void> initializeLocation() async {
    if (_isInitialized) return;

    try {
      initializeFeaturedCitiesSync();
      _userPosition = await Geolocator.getCurrentPosition();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Handle errors appropriately
      _isInitialized = false;
      notifyListeners();
    }
  }

  // Search cities from loaded cities in ExploreProvider
  List<LocationModel> searchCitiesFromLoaded(
      String query, List<LocationModel> loadedCities) {
    if (query.isEmpty || loadedCities.isEmpty) return [];

    final queryLower = query.toLowerCase();
    return loadedCities.where((city) {
      return city.name.toLowerCase().contains(queryLower) ||
          city.nameLowercase.contains(queryLower);
    }).toList();
  }

  void setCityInSearchBar(String city) {
    searchController.text = city;
    notifyListeners();
  }

  // Add new method to handle location permission and fetching
  Future<Position?> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      debugPrint(
          '📍 Got user position: ${position.latitude},${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return null;
    }
  }

  // Calculate distance between two points
  Future<void> performSearch(String query, BuildContext context,
      {List<LocationModel>? loadedCities}) async {
    debugPrint('🔍 Starting search for query: "$query"');
    debugPrint(
        '📍 User position: ${_userPosition?.latitude},${_userPosition?.longitude}');

    if (query.isEmpty) {
      debugPrint('❌ Empty query - clearing search');
      clearSearch();
      return;
    }

    showNoResultFound = false;
    isCustomQueryLoading = false;
    final stopwatch = Stopwatch()..start();
    isSearching = true;
    notifyListeners();
    try {
      // // Search users
      // final users = await context.read<ProfileProvider>().searchUsers(query);
      // userResults = users;
      // debugPrint('👥 Found ${users.length} user results');

      try {
        // Search locations (cities) from loaded cities only
        if (loadedCities != null) {
          locationResults = searchCitiesFromLoaded(query, loadedCities);
        } else {
          locationResults = await _locationService.searchLocations(query);
        }
        debugPrint('🌆 Found ${locationResults.length} location results');
      } catch (e) {
        debugPrint('❌ Location search error: $e');
        locationResults = [];
      }

      try {
        // Search places with user's location
        if (_userPosition != null) {
          placeResults = await _locationService.searchPlacesForSearchScreen(
            query,
            _userPosition!.latitude,
            _userPosition!.longitude,
          );
          debugPrint('📍 Found ${placeResults.length} place results');
        } else {
          debugPrint('⚠️ No user position - requesting permission');
          final position = await _getUserLocation();
          if (position != null) {
            _userPosition = position;
            placeResults = await _locationService.searchPlacesForSearchScreen(
              query,
              position.latitude,
              position.longitude,
            );
            debugPrint(
                '📍 Found ${placeResults.length} place results with new position');
          } else {
            debugPrint('⚠️ Could not get user position');
          }
        }
      } catch (e) {
        debugPrint('❌ Places search error: $e');
        placeResults = [];
      }

      debugPrint('✅ Search completed in ${stopwatch.elapsedMilliseconds}ms');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Global search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing search: ${e.toString()}')),
      );
      clearSearch();
      isCustomQueryLoading = false;
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  /// Called when user taps the custom query tile
  Future<void> handleCustomQueryTap(BuildContext context, String query,
      {String resultType = 'custom'}) async {
    if (query.isEmpty) return;
    isCustomQueryLoading = true;
    showNoResultFound = false;
    notifyListeners();
    try {
      await logSearchQuery(
        queryText: query,
        resultType: resultType,
        resultName: query,
        historyEnabled: true,
      );
      // After storing, show no result found
      showNoResultFound = true;
    } catch (e) {
      debugPrint('❌ Error logging custom query: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving search: ${e.toString()}')),
      );
    } finally {
      isCustomQueryLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    searchController.clear();
    userResults = [];
    locationResults = [];
    placeResults = [];
    isSearching = false;
    isCustomQueryLoading = false;
    showNoResultFound = false;
    _stopVoiceSearch(); // Stop any ongoing voice search
    notifyListeners();
  }

  // New method to only clear the search bar text without clearing the city selection
  void clearSearchBarOnly() {
    searchController.clear();
    userResults = [];
    locationResults = [];
    placeResults = [];
    isSearching = false;
    isCustomQueryLoading = false;
    showNoResultFound = false;
    _stopVoiceSearch(); // Stop any ongoing voice search
    notifyListeners();
  }

  /// Start voice search
  Future<void> startVoiceSearch(BuildContext context) async {
    debugPrint('🎤 Starting voice search...');

    try {
      _isVoiceSearching = true;
      _voiceSearchText = '';
      notifyListeners();

      // Initialize voice search service
      final initialized = await _voiceSearchService.initialize();
      if (!initialized) {
        _showVoiceSearchError(
            context, 'Voice search not available on this device');
        return;
      }

      _isListening = true;
      notifyListeners();

      await _voiceSearchService.startListening(
        onResult: (String result) async {
          debugPrint('🎤 Voice search result: $result');
          _voiceSearchText = result;
          _isListening = false;
          notifyListeners();

          // Perform search with voice result
          if (result.isNotEmpty) {
            searchController.text = result;
            await performSearch(result.toLowerCase(), context);
          }

          _stopVoiceSearch();
        },
        onError: (String error) {
          debugPrint('🎤 Voice search error: $error');
          _showVoiceSearchError(context, 'Voice search failed: $error');
          _stopVoiceSearch();
        },
      );
    } catch (e) {
      debugPrint('❌ Error starting voice search: $e');
      _showVoiceSearchError(context, 'Failed to start voice search');
      _stopVoiceSearch();
    }
  }

  /// Stop voice search
  Future<void> stopVoiceSearch() async {
    debugPrint('🎤 Stopping voice search...');
    await _voiceSearchService.stopListening();
    _stopVoiceSearch();
  }

  /// Cancel voice search
  Future<void> cancelVoiceSearch() async {
    debugPrint('🎤 Cancelling voice search...');
    await _voiceSearchService.cancelListening();
    _stopVoiceSearch();
  }

  /// Internal method to reset voice search state
  void _stopVoiceSearch() {
    _isVoiceSearching = false;
    _isListening = false;
    _voiceSearchText = '';
    notifyListeners();
  }

  /// Show voice search error to user
  void _showVoiceSearchError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _voiceSearchService.dispose();
    super.dispose();
  }

  List<String> getLocalCityImages(String cityId) {
    return [
      'assets/city_images/$cityId/${cityId}_1.jpg',
      'assets/city_images/$cityId/${cityId}_2.jpg',
      'assets/city_images/$cityId/${cityId}_3.jpg',
      'assets/city_images/$cityId/${cityId}_4.jpg',
    ];
  }

  Future<void> initializeFeaturedCities() async {
    featuredCities.clear();

    final cities = [
      {
        'name': 'Mumbai',
        'id': 'mumbai',
        'desc': 'The financial capital of India',
        'lat': 19.0760,
        'lng': 72.8777,
        'rating': 4.5
      },
      {
        'name': 'Delhi',
        'id': 'delhi',
        'desc': 'The capital of India',
        'lat': 28.6139,
        'lng': 77.2090,
        'rating': 4.3
      },
      {
        'name': 'Jabalpur',
        'id': 'jabalpur',
        'desc': 'Cultural capital of Madhya Pradesh',
        'lat': 23.1815,
        'lng': 79.9864,
        'rating': 4.0
      },
      {
        'name': 'Pune',
        'id': 'pune',
        'desc': 'Oxford of the East',
        'lat': 18.5204,
        'lng': 73.8567,
        'rating': 4.2
      },
      {
        'name': 'Bangalore',
        'id': 'bangalore',
        'desc': 'The Silicon Valley of India',
        'lat': 12.9716,
        'lng': 77.5946,
        'rating': 4.4
      },
      {
        'name': 'Kolkata',
        'id': 'kolkata',
        'desc': 'The cultural capital of India',
        'lat': 22.5726,
        'lng': 88.3639,
        'rating': 4.2
      },
      {
        'name': 'Chennai',
        'id': 'chennai',
        'desc': 'The Detroit of India',
        'lat': 13.0827,
        'lng': 80.2707,
        'rating': 4.3
      },
      {
        'name': 'Hyderabad',
        'id': 'hyderabad',
        'desc': 'The City of Pearls',
        'lat': 17.3850,
        'lng': 78.4867,
        'rating': 4.4
      }
    ];

    for (var city in cities) {
      List<String> images = getLocalCityImages(city['id'].toString());

      featuredCities.add(LocationModel(
        id: city['id'] as String,
        name: city['name'] as String,
        nameLowercase: (city['name'] as String).toLowerCase(), // Add this line
        imageUrls: images,
        description: city['desc'] as String,
        latitude: city['lat'] as double,
        longitude: city['lng'] as double,
        rating: city['rating'] as double,
        cachedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    notifyListeners();
  }

  void initializeFeaturedCitiesSync() {
    if (_isInitialized) return;

    featuredCities.clear();
    final cities = [
      {
        'name': 'Mumbai',
        'id': 'mumbai',
        'desc': 'The financial capital of India',
        'lat': 19.0760,
        'lng': 72.8777,
        'rating': 4.5
      },
      {
        'name': 'Delhi',
        'id': 'delhi',
        'desc': 'The capital of India',
        'lat': 28.6139,
        'lng': 77.2090,
        'rating': 4.3
      },
      {
        'name': 'Jabalpur',
        'id': 'jabalpur',
        'desc': 'Cultural capital of Madhya Pradesh',
        'lat': 23.1815,
        'lng': 79.9864,
        'rating': 4.0
      },
      {
        'name': 'Pune',
        'id': 'pune',
        'desc': 'Oxford of the East',
        'lat': 18.5204,
        'lng': 73.8567,
        'rating': 4.2
      },
      {
        'name': 'Bangalore',
        'id': 'bangalore',
        'desc': 'The Silicon Valley of India',
        'lat': 12.9716,
        'lng': 77.5946,
        'rating': 4.4
      },
      {
        'name': 'Kolkata',
        'id': 'kolkata',
        'desc': 'The cultural capital of India',
        'lat': 22.5726,
        'lng': 88.3639,
        'rating': 4.2
      },
      {
        'name': 'Chennai',
        'id': 'chennai',
        'desc': 'The Detroit of India',
        'lat': 13.0827,
        'lng': 80.2707,
        'rating': 4.3
      },
      {
        'name': 'Hyderabad',
        'id': 'hyderabad',
        'desc': 'The City of Pearls',
        'lat': 17.3850,
        'lng': 78.4867,
        'rating': 4.4
      }
    ];

    for (var city in cities) {
      List<String> images = getLocalCityImages(city['id'].toString());
      featuredCities.add(LocationModel(
        id: city['id'] as String,
        name: city['name'] as String,
        nameLowercase: (city['name'] as String).toLowerCase(), // Add this line
        imageUrls: images,
        description: city['desc'] as String,
        latitude: city['lat'] as double,
        longitude: city['lng'] as double,
        rating: city['rating'] as double,
        cachedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    _isInitialized = true;
    // notifyListeners();
  }

  /// Log search query when user clicks on a result
  Future<void> logSearchQuery({
    required String queryText,
    required String resultType,
    required String resultName,
    required bool historyEnabled,
  }) async {
    await SearchService.logSearchQueryWithPrivacyCheck(
      queryText: queryText,
      resultType: resultType,
      resultName: resultName,
      historyEnabled: historyEnabled,
    );
  }
}
