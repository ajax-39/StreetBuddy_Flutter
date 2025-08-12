import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class ChangeLocationScreen extends StatefulWidget {
  const ChangeLocationScreen({super.key});

  @override
  State<ChangeLocationScreen> createState() => _ChangeLocationScreenState();
}

class _ChangeLocationScreenState extends State<ChangeLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentLocation = const LatLng(19.0760, 72.8777); // Default to Mumbai
  LatLng _selectedLocation = const LatLng(19.0760, 72.8777);
  String _selectedLocationName = 'Mumbai';
  String _selectedLocationAddress = 'Maharashtra, India';
  List<String> _recentLocations = ['Delhi', 'Mumbai', 'Hyderabad', 'Bangalore'];
  List<LocationSearchResult> _searchResults = [];
  double _currentZoom = 13.0;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _updateLocationDetails(_selectedLocation);
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Show a message to user that location permission is needed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location permission is required to use this feature'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Show a message about opening settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location permission in settings'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting your location...'),
            duration: Duration(seconds: 1),
          ),
        );

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
          _currentZoom = 15.0; // Zoom in closer when using GPS
        });
        _updateLocationDetails(_currentLocation);
        _mapController.move(_currentLocation, _currentZoom);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location found!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get location. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateLocationDetails(LatLng location) async {
    try {
      // Reverse geocoding using Nominatim (OpenStreetMap)
      final url = 'https://nominatim.openstreetmap.org/reverse?'
          'format=json&lat=${location.latitude}&lon=${location.longitude}';

      final response = await _dio.get(url);
      final data = response.data;

      if (data != null && data['display_name'] != null) {
        final displayName = data['display_name'] as String;
        final addressParts = displayName.split(', ');

        setState(() {
          _selectedLocationName = _extractLocationName(data);
          _selectedLocationAddress = _extractAddress(addressParts);
        });
      }
    } catch (e) {
      debugPrint('Error updating location details: $e');
    }
  }

  String _extractLocationName(Map<String, dynamic> data) {
    // Try to get the city name specifically for consistent city-level updates
    final address = data['address'];
    if (address != null) {
      String? cityName = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'] ??
          address['state_district'];

      if (cityName != null && cityName.isNotEmpty) {
        return cityName;
      }
    }

    // Fallback to display name parsing
    final displayName = data['display_name'] as String?;
    if (displayName != null) {
      final parts = displayName.split(',');
      // Try to find a city-like component
      for (final part in parts.take(3)) {
        // Check first 3 parts
        final trimmed = part.trim();
        if (trimmed.isNotEmpty && !_isStreetOrNumber(trimmed)) {
          return trimmed;
        }
      }
    }

    return 'Selected Location';
  }

  bool _isStreetOrNumber(String text) {
    // Simple check to avoid street numbers or obvious non-city names
    return RegExp(r'^\d+').hasMatch(text) ||
        text.toLowerCase().contains('road') ||
        text.toLowerCase().contains('street') ||
        text.toLowerCase().contains('lane');
  }

  String _extractAddress(List<String> addressParts) {
    // Extract city, state, country
    if (addressParts.length >= 3) {
      return '${addressParts[addressParts.length - 3]}, ${addressParts[addressParts.length - 2]}, ${addressParts.last}';
    }
    return addressParts.join(', ');
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final url = 'https://nominatim.openstreetmap.org/search?'
          'format=json&q=$query&limit=5&countrycodes=in&addressdetails=1';

      final response = await _dio.get(url);
      final List<dynamic> data = response.data;

      setState(() {
        // Create search results with extracted city names for location updates
        _searchResults = data
            .map((item) => LocationSearchResult(
                  name: item['display_name'],
                  lat: double.parse(item['lat']),
                  lon: double.parse(item['lon']),
                  cityName: _extractCityFromSearchResult(
                      item), // Extract city for location updates
                  address: item['address'],
                ))
            .toList();
      });
    } catch (e) {
      debugPrint('Error searching location: $e');
    }
  }

  String _extractCityFromSearchResult(Map<String, dynamic> item) {
    final address = item['address'];
    if (address != null) {
      // Try to get city-level information in order of preference
      String? cityName = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'] ??
          address['state_district'];

      if (cityName != null && cityName.isNotEmpty) {
        return cityName;
      }
    }

    // Fallback: extract from display name
    final displayName = item['display_name'] as String?;
    if (displayName != null) {
      final parts = displayName.split(',');
      if (parts.isNotEmpty) {
        // Return the first part which is usually the most specific location
        return parts.first.trim();
      }
    }

    return 'Unknown City';
  }

  Future<LatLng> _getCityCoordinates(String cityName) async {
    try {
      // First try to search for the city with administrative level
      final cityUrl = 'https://nominatim.openstreetmap.org/search?'
          'format=json&q=$cityName&limit=5&countrycodes=in&addressdetails=1&'
          'extratags=1';

      final response = await _dio.get(cityUrl);
      final List<dynamic> data = response.data;

      if (data.isNotEmpty) {
        // Find the best match - prefer city, town, or administrative areas
        for (final item in data) {
          final address = item['address'];
          if (address != null) {
            final isCity = address['city'] != null ||
                address['town'] != null ||
                address['municipality'] != null ||
                (item['type'] == 'administrative' &&
                    item['class'] == 'boundary');

            if (isCity) {
              return LatLng(
                double.parse(item['lat']),
                double.parse(item['lon']),
              );
            }
          }
        }

        // If no perfect match, use the first result
        final firstResult = data.first;
        return LatLng(
          double.parse(firstResult['lat']),
          double.parse(firstResult['lon']),
        );
      }
    } catch (e) {
      debugPrint('Error getting city coordinates: $e');
    }

    // Fallback to original coordinates if city search fails
    return _selectedLocation;
  }

  void _selectLocation(LatLng location, [String? name]) {
    setState(() {
      _selectedLocation = location;
      if (name != null) {
        _selectedLocationName = name;
      }
    });
    _updateLocationDetails(location);
    _currentZoom = 15.0;
    _mapController.move(location, _currentZoom);
  }

  void _confirmLocation() {
    final exploreProvider =
        Provider.of<ExploreProvider>(context, listen: false);

    // Create a LocationModel from the selected location
    final selectedLocationModel = LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _selectedLocationName,
      nameLowercase: _selectedLocationName.toLowerCase(),
      imageUrls: [],
      description: _selectedLocationAddress,
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
    );

    exploreProvider.setSelectedLocation(selectedLocationModel);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Change Location',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _searchLocation,
                decoration: InputDecoration(
                  hintText: 'Enter your city or location',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  suffixIcon: Icon(
                    Icons.mic,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      _selectLocation(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.streetbuddy.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 40,
                          height: 40,
                          child: Container(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_pin,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Map Controls
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon:
                              Icon(Icons.my_location, color: AppColors.primary),
                          onPressed: _getCurrentLocation,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _currentZoom += 1;
                                _mapController.move(
                                    _selectedLocation, _currentZoom);
                              },
                            ),
                            Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                _currentZoom -= 1;
                                _mapController.move(
                                    _selectedLocation, _currentZoom);
                              },
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

          // Search Results or Location Info
          if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty)
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.grey),
                    title: Text(
                      result.getLocationName(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      result.name,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () async {
                      // Get city coordinates instead of exact location coordinates
                      debugPrint(
                          '🏙️ User selected: ${result.cityName} (extracting city-level coordinates)');
                      final cityCoords =
                          await _getCityCoordinates(result.cityName);
                      _selectLocation(
                        cityCoords,
                        result.cityName,
                      );
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  );
                },
              ),
            )
          else
            // Selected Location Info
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Current Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_pin,
                            color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedLocationName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _selectedLocationAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit, color: Colors.grey[600], size: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent Locations
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Recent Locations', // Updated text
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Adjusting city buttons to ensure they are in a single row
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .start, // Aligning buttons to the start
                        children: _recentLocations.map((city) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                right: 8), // Adding spacing between buttons
                            child: GestureDetector(
                              onTap: () async {
                                // Get city coordinates directly
                                final cityCoords =
                                    await _getCityCoordinates(city);
                                _selectLocation(cityCoords, city);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12, // Keeping smaller padding
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(15),
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Text(
                                    city,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class LocationSearchResult {
  final String name;
  final double lat;
  final double lon;
  final String cityName;
  final Map<String, dynamic>? address;

  LocationSearchResult({
    required this.name,
    required this.lat,
    required this.lon,
    required this.cityName,
    this.address,
  });

  String getLocationName() {
    return cityName;
  }
}
