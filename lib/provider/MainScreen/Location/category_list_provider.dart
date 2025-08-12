import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/services/location_services.dart';
import 'package:street_buddy/services/voice_search_service.dart';

/// Filtering options for place listings
// enum PlaceFilter { relevance, streetBuddyRating, distance, rating, reviews }
enum PlaceFilter { all, trending, newest, popular }

/// Provider for managing and filtering place listings by category
class CategoryListProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  final LocationModel location;
  final String category;
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  CategoryListProvider({
    required this.location,
    required this.category,
  }) {
    scrollController.addListener(_scrollListener);
    loadInitialPlaces();
  }

  List<PlaceModel> _allPlaces = [];
  List<PlaceModel> _filteredPlaces = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _nextPageToken;
  String? _error;
  Position? _userLocation;
  int? _lastOffset;
  final Set<String> _loadedPlaceIds = {};
  PlaceFilter _currentFilter = PlaceFilter.all;

  // Voice search properties
  bool _isVoiceSearching = false;
  bool _isListening = false;
  String _voiceSearchText = '';

  // Voice search getters
  bool get isVoiceSearching => _isVoiceSearching;
  bool get isListening => _isListening;
  String get voiceSearchText => _voiceSearchText;

  // Getters
  List<PlaceModel> get filteredPlaces => _filteredPlaces;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  PlaceFilter get currentFilter => _currentFilter;

  /// Category-specific keyword mappings for refined search results
  final Map<String, String> _categoryKeywords = {
    'restaurant': '13000,13002,13035,13038,13065,13068,13282,13283,13299,13305',
    'tourist_attraction': '16000,16001,16002,16009,16015,16016,16017,16021',
    'lodging': '19000,19001,19002,19003,19004,19005',
    'shopping_mall': '17000,17001,17002,17006,17010,17011,17012',
  };

  /// Handles pagination when user scrolls to bottom
  void _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      _loadMorePlaces();
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    _voiceSearchService.dispose();
    super.dispose();
  }

  /// Adds places to the list ensuring no duplicates
  void _addUniquePlaces(List<PlaceModel> newPlaces) {
    final uniquePlaces = newPlaces.where((place) {
      if (_loadedPlaceIds.contains(place.id)) {
        return false;
      }
      _loadedPlaceIds.add(place.id);
      return true;
    }).toList();

    _allPlaces.addAll(uniquePlaces);
  }

  /// Gets user's current location or falls back to selected location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _userLocation = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
      _userLocation = Position(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  /// Initial loading of places when screen is first opened
  Future<void> loadInitialPlaces() async {
    final stopwatch = Stopwatch()..start();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _getCurrentLocation();
      // Use new custom places flow by default
      await _loadCustomPlacesForCity();
      // Old logic commented out:
      // await _loadPlaces(initial: true);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    } finally {
      stopwatch.stop();
      debugPrint(
          '⏱ Initial places load took: {stopwatch.elapsed.inMilliseconds}ms');
    }
  }

  /// Loads custom places with id prefix 'pcustom_' for the current city
  Future<void> _loadCustomPlacesForCity() async {
    _loadedPlaceIds.clear();
    _allPlaces = [];
    _filteredPlaces = [];
    _error = null;
    notifyListeners();
    try {
      final cityName = location.name;
      final customPlaces =
          await _locationService.fetchCustomPlacesForCity(cityName);
      if (customPlaces.isEmpty) {
        _error = 'No places found, explore other cities like this.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      for (var place in customPlaces) {
        if (_userLocation != null) {
          place.distanceFromUser = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            place.latitude,
            place.longitude,
          );
        }
        _loadedPlaceIds.add(place.id);
        _allPlaces.add(place);
      }
      _filteredPlaces = List.from(_allPlaces);
      _sortPlaces();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'No places found, explore other cities like this.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads places with cache-first approach followed by API requests
  Future<void> loadPlaces() async {
    final stopwatch = Stopwatch()..start();
    try {
      _isLoading = true;
      notifyListeners();

      if (_userLocation == null) {
        await _getCurrentLocation();
      }

      _loadedPlaceIds.clear();
      _allPlaces = [];
      _filteredPlaces = [];

      // First try cache
      final placeStream = await _locationService.searchPlacesFromCache(
        location.latitude,
        location.longitude,
        category,
        radiusInKm: 150,
      );

      bool hasReceivedPlaces = false;

      // Process places as they come from stream
      await for (final place in placeStream) {
        if (!_loadedPlaceIds.contains(place.id)) {
          if (_userLocation != null) {
            place.distanceFromUser = Geolocator.distanceBetween(
              _userLocation!.latitude,
              _userLocation!.longitude,
              place.latitude,
              place.longitude,
            );
          }

          _loadedPlaceIds.add(place.id);
          _allPlaces.add(place);
          _filteredPlaces = _allPlaces;
          hasReceivedPlaces = true;
          _sortPlaces();
          notifyListeners();
        }
      }

      // If no places from cache, use API
      if (!hasReceivedPlaces) {
        final result = await _locationService.searchPlacesForCategory(
          location.latitude,
          location.longitude,
          category,
          keywords: _categoryKeywords[category.toLowerCase()],
        );

        for (var place in result.places) {
          if (!_loadedPlaceIds.contains(place.id)) {
            if (_userLocation != null) {
              place.distanceFromUser = Geolocator.distanceBetween(
                _userLocation!.latitude,
                _userLocation!.longitude,
                place.latitude,
                place.longitude,
              );
            }

            _loadedPlaceIds.add(place.id);
            _allPlaces.add(place);
            _filteredPlaces = _allPlaces;
            _sortPlaces();
            notifyListeners();
          }
        }
      }

      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    } finally {
      stopwatch.stop();
      debugPrint('⏱ Places load took: ${stopwatch.elapsed.inMilliseconds}ms');
      notifyListeners();
    }
  }

  /// Core place loading logic with performance tracking
  Future<void> _loadPlaces({bool initial = false}) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (_userLocation == null) {
        await _getCurrentLocation();
      }

      if (initial) {
        _loadedPlaceIds.clear();
        _lastOffset = 0;
        _allPlaces = [];
        _filteredPlaces = [];
      }

      debugPrint('🔍 Loading places for category: $category');
      debugPrint('📍 Location: ${location.name}');

      // Get both cached and API data through searchPlacesForCategory
      final result = await _locationService.searchPlacesForCategory(
        location.latitude,
        location.longitude,
        category,
        pageToken: initial ? null : _nextPageToken,
      );

      // Process the merged results
      if (result.places.isNotEmpty) {
        for (var place in result.places) {
          if (!_loadedPlaceIds.contains(place.id)) {
            // Update distance from user if needed
            if (_userLocation != null) {
              place.distanceFromUser = Geolocator.distanceBetween(
                _userLocation!.latitude,
                _userLocation!.longitude,
                place.latitude,
                place.longitude,
              );
            }

            _loadedPlaceIds.add(place.id);
            _allPlaces.add(place);
          }
        }

        _filteredPlaces = List.from(_allPlaces);
        _nextPageToken = result.nextPageToken;
        _sortPlaces();

        debugPrint('✅ Loaded ${result.places.length} places');
        debugPrint('📊 Total places: ${_allPlaces.length}');
        if (_nextPageToken != null) {
          debugPrint('📎 Next page token available');
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading places: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    } finally {
      stopwatch.stop();
      debugPrint('⏱ Load places took: ${stopwatch.elapsed.inMilliseconds}ms');
    }
  }

  /// Loads additional places when user scrolls to end of list
  Future<void> _loadMorePlaces() async {
    if (_isLoadingMore || _nextPageToken == null) return;

    final stopwatch = Stopwatch()..start();
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _locationService.searchPlacesForCategory(
        location.latitude,
        location.longitude,
        category,
        pageToken: _nextPageToken,
      );

      if (result.places.isNotEmpty) {
        for (var place in result.places) {
          if (!_loadedPlaceIds.contains(place.id)) {
            if (_userLocation != null) {
              place.distanceFromUser = Geolocator.distanceBetween(
                _userLocation!.latitude,
                _userLocation!.longitude,
                place.latitude,
                place.longitude,
              );
            }

            _loadedPlaceIds.add(place.id);
            _allPlaces.add(place);
          }
        }

        _filteredPlaces = List.from(_allPlaces);
        _nextPageToken = result.nextPageToken;
        _sortPlaces();

        debugPrint('✅ Loaded ${result.places.length} more places');
        debugPrint('📊 Total places: ${_allPlaces.length}');
      }
    } catch (e) {
      debugPrint('❌ Error loading more places: $e');
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
      stopwatch.stop();
      debugPrint(
          '⏱ Load more places took: ${stopwatch.elapsed.inMilliseconds}ms');
    }
  }

  /// Processes search results and updates place listings
  void _processPlacesResult(PlaceSearchResult result, bool initial) {
    for (var place in result.places) {
      if (_userLocation != null) {
        double distanceInMeters = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          place.latitude,
          place.longitude,
        );
        place.distanceFromUser = distanceInMeters;
      }
    }

    if (initial) {
      _allPlaces = [];
      _addUniquePlaces(result.places);
    } else {
      _addUniquePlaces(result.places);
    }

    _nextPageToken = result.nextPageToken;
    _lastOffset = result.lastOffset;
    _filteredPlaces = List.from(_allPlaces);
    _sortPlaces();
    _isLoading = false;
    notifyListeners();

    if (_nextPageToken != null || _lastOffset != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadMorePlaces();
      });
    }
  }

  /// Changes the current filter and re-sorts places
  void setFilter(PlaceFilter filter) {
    _currentFilter = filter;
    _sortPlaces();
    notifyListeners();
  }

  /// Sorts places according to the selected filter
  void _sortPlaces() {
    // Always sort by highest rating first, with image priority and distance as secondary criteria
    _filteredPlaces.sort((a, b) {
      // Primary sort: Rating (highest first)
      int ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      // Secondary sort: Image priority (places with images first)
      bool aHasImage = a.photoUrl != null &&
          a.photoUrl!.isNotEmpty &&
          !a.photoUrl!.contains('default') &&
          !a.photoUrl!.contains('placeholder');
      bool bHasImage = b.photoUrl != null &&
          b.photoUrl!.isNotEmpty &&
          !b.photoUrl!.contains('default') &&
          !b.photoUrl!.contains('placeholder');

      if (aHasImage && !bHasImage) return -1;
      if (!aHasImage && bHasImage) return 1;

      // Tertiary sort: Distance (closest first)
      return (a.distanceFromUser ?? double.infinity)
          .compareTo(b.distanceFromUser ?? double.infinity);
    });
    notifyListeners();
  }

  /// Filters places based on search query
  void filterPlaces(String query) {
    if (query.isEmpty) {
      _filteredPlaces = _allPlaces;
    } else {
      _filteredPlaces = _allPlaces
          .where((place) =>
              place.name.toLowerCase().contains(query.toLowerCase()) ||
              (place.vicinity?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
    }
    _sortPlaces();
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

          // Update search field and filter places
          if (result.isNotEmpty) {
            searchController.text = result;
            filterPlaces(result);
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

  List<PlaceModel> _topRatedOtherCities = [];
  List<PlaceModel> get topRatedOtherCities => _topRatedOtherCities;

  /// Loads top rated custom places from other cities (id prefix pcustom_, city != current city)
  Future<void> loadTopRatedCustomPlacesFromOtherCities() async {
    final cityName = location.name;
    _topRatedOtherCities = await _locationService
        .fetchTopRatedCustomPlacesFromOtherCities(cityName, limit: 20);
    notifyListeners();
  }
}
