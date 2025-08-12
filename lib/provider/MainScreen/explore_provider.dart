import 'package:flutter/material.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';

enum PeopleFilter {
  nearby,
  newest,
  popular,
}

enum FoodFilter {
  nearMe,
  topRated,
  forMe,
}

enum ShopFilter {
  top,
  localMarkets,
  handMe,
  fashion,
}

enum GuideFilter {
  all,
  trending,
  new_,
  popular,
}

class ExploreProvider extends ChangeNotifier {
  PeopleFilter peopleFilter = PeopleFilter.newest;
  FoodFilter foodFilter = FoodFilter.nearMe;
  ShopFilter shopFilter = ShopFilter.top;
  GuideFilter guideFilter = GuideFilter.all;

  LocationModel? location;

  // New properties for city dropdown
  List<LocationModel> _cities = [];
  bool _isLoadingCities = false; 
  LocationModel? _selectedLocation;

  // Getters
  List<LocationModel> get cities {
    final sorted = List<LocationModel>.from(_cities);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  bool get isLoadingCities => _isLoadingCities;
  LocationModel? get selectedLocation => _selectedLocation;

  // Initialize cities and set default location
  Future<void> initializeCities() async {
    if (_cities.isNotEmpty) return; // Already loaded

    _isLoadingCities = true;
    notifyListeners();

    try {
      await _loadCities();
      await _setDefaultLocation();
    } catch (e) {
      debugPrint('Error initializing cities: $e');
    } finally {
      _isLoadingCities = false;
      notifyListeners();
    }
  }

  Future<void> _loadCities() async {
    try {
      final data = await supabase.from('locations').select('*');
      _cities = data.map((e) => LocationModel.fromJson(e)).toList();
      debugPrint('🏙️ Loaded ${_cities.length} cities');
    } catch (e) {
      debugPrint('Error loading cities: $e');
      _cities = [];
    }
  }

  Future<void> _setDefaultLocation() async {
    if (_cities.isEmpty) return;

    // Try to set user's current city first
    if (globalUser?.city != null) {
      try {
        final userCity = _cities.firstWhere(
          (city) => city.nameLowercase == globalUser!.city!.toLowerCase(),
        );
        _selectedLocation = userCity;
        debugPrint('🏙️ Set default location to user city: ${userCity.name}');
      } catch (e) {
        // User's city not found, fallback to first city
        _selectedLocation = _cities.first;
        debugPrint(
            '🏙️ User city not found, set default to: ${_cities.first.name}');
      }
    } else {
      // No user city, fallback to first available city
      _selectedLocation = _cities.first;
      debugPrint(
          '🏙️ Set default location to first city: ${_cities.first.name}');
    }
  }

  void setSelectedLocation(LocationModel location) {
    _selectedLocation = location;
    debugPrint('🏙️ Location changed to: ${location.name}');
    notifyListeners();
  }

  void setLocation(LocationModel location) {
    this.location = location;
    notifyListeners();
  }

  void clearLocation() {
    _selectedLocation = null;
    notifyListeners();
  }

  void setFilter(PeopleFilter filter) {
    peopleFilter = filter;
    notifyListeners();
  }

  void setFoodFilter(FoodFilter filter) {
    foodFilter = filter;
    notifyListeners();
  }

  void setShopFilter(ShopFilter filter) {
    shopFilter = filter;
    notifyListeners();
  }

  void setGuideFilter(GuideFilter filter) {
    guideFilter = filter;
    notifyListeners();
  }

  // Add refresh trigger for guides
  int _guidesRefreshTrigger = 0;
  int get guidesRefreshTrigger => _guidesRefreshTrigger;

  // Method to refresh guides data across the app
  void refreshGuides() {
    _guidesRefreshTrigger++;
    notifyListeners();
    debugPrint('🔄 Guides refresh triggered');
  }
}

Future<List<UserModel>> getPeople(peopleFilter) async {
  try {
    List<Map<String, dynamic>> data;

    if (peopleFilter == PeopleFilter.nearby) {
      data = await supabase
          .from('users')
          .select('*')
          .neq('uid', globalUser?.uid ?? '')
          .eq('city', globalUser?.city ?? '')
          .limit(10);
    } else if (peopleFilter == PeopleFilter.newest) {
      data = await supabase
          .from('users')
          .select('*')
          .neq('uid', globalUser?.uid ?? '')
          .order('created_at', ascending: false)
          .limit(10);
    } else {
      data = await supabase
          .from('users')
          .select('*')
          .neq('uid', globalUser?.uid ?? '')
          .order('total_likes', ascending: false)
          .limit(10);
    }

    return data.map((e) => UserModel.fromMap(e['uid'], e)).toList();
  } catch (e) {
    debugPrint('Error in getting people: $e');
    return [];
  }
}

Future<List<PostModel>> getActivity() async {
  try {
    final data = await supabase
        .from('posts')
        .select('*')
        .order('created_at', ascending: false)
        .limit(10);
    final data2 = await supabase
        .from('guides')
        .select('*')
        .order('created_at', ascending: false)
        .limit(10);
    final list = [
      ...data.map((e) => PostModel.fromMap(e['id'], e)),
      ...data2.map((e) => PostModel.fromMap(e['id'], e))
    ];

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return list;
  } catch (e) {
    debugPrint('Error in getting activity: $e');
    return [];
  }
}

Future<List<PlaceModel>> getTrendingCuisines() async {
  try {
    final response = await supabase.from('explore_places').select('*');
    return response.map((e) => PlaceModel.fromJson(e)).toList();
  } catch (e) {
    debugPrint('Error in getUserSavedGuidesFuture: $e');
    return [];
  }
}
