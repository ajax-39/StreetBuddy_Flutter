import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:street_buddy/services/optimized_location_service.dart';
import 'package:street_buddy/services/optimized_tile_layer_service.dart';

/// Navigation instruction model containing information about the next maneuver
class NavigationInstruction {
  /// Textual description of the navigation instruction (e.g., "Turn right")
  final String instruction;

  /// Distance to the next maneuver point in meters
  final double distanceInMeters;

  /// Turn angle in degrees (-180 to 180) with negative being left turns and positive being right turns
  final double angle;

  NavigationInstruction({
    required this.instruction,
    required this.distanceInMeters,
    required this.angle,
  });
}

/// Core provider for map functionality, handling navigation, routing, and location tracking
class MapProvider extends ChangeNotifier {
  Timer? _locationTimer;

  /// Current position of the user
  Position? userPosition;

  /// Selected transportation mode: 'car', 'bike', or 'foot'
  String selectedRoute = 'car';

  /// List of route points defining the current path
  List<LatLng> routePoints = [];

  final Dio _dio = Dio();
  StreamSubscription<Position>? _positionStreamSubscription;

  /// User's compass heading in degrees (0-360)
  double userBearing = 0.0;

  // Optimized services
  final OptimizedLocationService _locationService = OptimizedLocationService();
  final OptimizedTileLayerService _tileService = OptimizedTileLayerService();

  /// User's heading in degrees (0-360), used for map rotation
  double bearing = 0.0;

  /// List of alternative routes available for the destination
  List<List<LatLng>> alternativeRoutes = [];

  /// Distances for each alternative route in kilometers
  List<double> alternativeDistances = [];

  /// Formatted durations for each alternative route (e.g., "15 mins" or "1 h 25 mins")
  List<String> alternativeDurations = [];

  /// Index of the currently selected route from alternatives
  int selectedRouteIndex = 0;

  /// Whether to display alternative routes on the map
  bool showRoutes = false;

  /// Controller for manipulating the map view
  final mapController = MapController();
  Position? _lastRouteUpdate;

  // Legacy location settings - now handled by OptimizedLocationService
  // final LocationSettings _locationSettings = const LocationSettings(
  //   accuracy: LocationAccuracy.bestForNavigation,
  //   distanceFilter: 0,
  //   timeLimit: null,
  // );

  double _lastHeading = 0.0;

  /// Points remaining on the current route
  List<LatLng> remainingRoutePoints = [];

  Timer? _headingSmootherTimer;
  bool _isInitialized = false;

  /// Minimum bearing change in degrees to trigger a heading update
  static const double _minimumBearingChange = 0.5;

  /// Queue for smoothing heading updates
  final Queue<double> _bearingQueue = Queue<double>();

  /// Maximum size of bearing queue for smoothing algorithm
  static const int _maxQueueSize = 3;

  StreamSubscription<CompassEvent>? _compassSubscription;

  /// Factor for exponential smoothing of heading updates (0-1)
  static const double _smoothingFactor = 0.15;

  /// Current route being followed
  List<LatLng> currentRoute = [];

  Timer? _locationUpdateTimer;

  /// Threshold in meters to determine if user has deviated from route
  double deviationThreshold = 50.0;

  /// Whether turn-by-turn navigation is active
  bool isNavigationMode = false;

  /// Current speed in km/h
  double currentSpeed = 0.0;

  Timer? _speedUpdateTimer;

  /// Average speed for smoother speed calculations
  double _averageSpeed = 0.0;

  /// Queue for speed averaging
  final Queue<double> _speedQueue = Queue<double>();

  /// Maximum size of speed queue for averaging
  static const int _maxSpeedQueueSize = 5;

  DateTime? _lastLocationUpdate;

  /// Whether a new route is currently being calculated
  bool isGeneratingNewRoute = false;

  /// Previous route points stored for restoration if route calculation fails
  List<LatLng> previousRoutePoints = [];

  /// Current navigation instruction for turn-by-turn guidance
  NavigationInstruction? currentInstruction;

  /// Points for multiple destination routes
  List<LatLng> multiDestinationPoints = [];

  /// Current destination index when navigating through multiple points
  int currentDestinationIndex = 0;

  /// Total number of destinations in the multi-destination route
  int totalDestinations = 0;

  bool _disposed = false;

  /// Whether this provider has been disposed
  bool get disposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// Creates a new map provider and initializes location services
  MapProvider() {
    initializeLocation();
  }

  /// Initializes location services and compass heading with optimizations
  Future<void> initializeLocation() async {
    if (_disposed) return;

    // Start with map viewing context for initial location
    await _startOptimizedLocationTracking(LocationUsageContext.mapViewing);

    if (_disposed) return;

    if (FlutterCompass.events != null) {
      _compassSubscription = FlutterCompass.events!
          .where((event) => event.heading != null)
          .listen((CompassEvent event) {
        if (!_disposed) {
          updateHeading(event.heading!);
        }
      });
    }
  }

  /// Start optimized location tracking based on usage context
  Future<void> _startOptimizedLocationTracking(
      LocationUsageContext context) async {
    if (_disposed) return;

    // Stop existing tracking
    _locationService.stopLocationTracking();

    // Start optimized tracking
    _locationService.startLocationTracking(
      context: context,
      onLocationUpdate: (Position position) {
        if (!_disposed) {
          _updateUserPosition(position);
        }
      },
    );

    debugPrint('🗺️ Started optimized location tracking for context: $context');
  }

  /// Update location context based on current usage
  void updateLocationContext(LocationUsageContext context) {
    _locationService.updateLocationContext(context);
  }

  /// Get optimized tile layer for the map
  TileLayer getOptimizedTileLayer() {
    return _tileService.getOptimizedTileLayer();
  }

  /// Update user position with optimizations
  void _updateUserPosition(Position position) {
    userPosition = position;

    if (position.heading >= 0) {
      updateHeading(position.heading);
    }

    updateRouteProgress(position);

    if (isNavigationMode) {
      updateMapForNavigation();
    }

    notifyListeners();
  }

  /// Start navigation mode with high-frequency location tracking
  void startNavigationMode() {
    isNavigationMode = true;
    updateLocationContext(LocationUsageContext.activeNavigation);
    debugPrint(
        '🧭 Started navigation mode with high-frequency location tracking');
  }

  /// Stop navigation mode and return to normal location tracking
  void stopNavigationMode() {
    isNavigationMode = false;
    updateLocationContext(LocationUsageContext.mapViewing);
    debugPrint(
        '🧭 Stopped navigation mode, returned to normal location tracking');
  }

  // Legacy position tracking - now handled by OptimizedLocationService
  // Position? _previousPosition;

  /// Legacy location tracking method - now handled by OptimizedLocationService
  /*
  void _startLocationTracking() {
    _positionStreamSubscription?.cancel();

    // Configure location settings with high accuracy for navigation
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: const Duration(milliseconds: 20),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _previousPosition = position;

        userPosition = position;
        if (position.heading >= 0) {
          updateHeading(position.heading);
        }
        updateRouteProgress(position);

        if (isNavigationMode) {
          updateMapForNavigation();
        }

        notifyListeners();
      },
      onError: (error) {
        print('Position stream error: $error');
        Future.delayed(const Duration(seconds: 1), _startLocationTracking);
      },
    );
  }
  */

  /// Gets the current location and requests permission if needed
  Future<void> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestResult = await Geolocator.requestPermission();
        if (requestResult == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      userPosition = position;

      if (!_isInitialized) {
        _isInitialized = true;
        await getRoute(
          destinationLat: position.latitude,
          destinationLng: position.longitude,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      rethrow;
    }
  }

  /// Determines if route should be updated based on user movement
  /// Returns true if user has moved more than 10 meters since last update
  bool shouldUpdateRoute(Position newPosition) {
    if (_lastRouteUpdate == null) {
      _lastRouteUpdate = newPosition;
      return true;
    }

    final distance = Geolocator.distanceBetween(
      _lastRouteUpdate!.latitude,
      _lastRouteUpdate!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    if (distance > 10) {
      _lastRouteUpdate = newPosition;
      return true;
    }
    return false;
  }

  /// Fetches a route from current location to specified destination
  /// Gets up to 3 alternative routes using OSRM routing API
  Future<void> getRoute({
    required double destinationLat,
    required double destinationLng,
  }) async {
    if (_disposed || userPosition == null) return;
    void clearRouteData() {
      alternativeRoutes.clear();
      alternativeDistances.clear();
      alternativeDurations.clear();
      remainingRoutePoints.clear();
      print("Routes cleared");
    }

    if (!isGeneratingNewRoute) {
      previousRoutePoints = List.from(remainingRoutePoints);
      clearRouteData();
    }

    try {
      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/$selectedRoute/'
        '${userPosition!.longitude},${userPosition!.latitude};'
        '$destinationLng,$destinationLat'
        '?overview=full&geometries=geojson&alternatives=true',
      );

      if (response.data['code'] == 'Ok') {
        final routes = response.data['routes'] as List;
        final numberOfRoutes = min<int>(routes.length, 3);

        for (var i = 0; i < numberOfRoutes; i++) {
          final route = routes[i];
          final geometry = route['geometry']['coordinates'] as List;
          final distance = (route['distance'] as num).toDouble();
          double duration = (route['duration'] as num).toDouble();

          // Adjust duration based on transportation mode
          switch (selectedRoute) {
            case 'foot':
              duration *= 16;
              break;
            case 'bike':
              duration *= 2.5;
              break;
            case 'car':
              duration *= 1.5;
              break;
          }

          try {
            final List<LatLng> routeCoordinates = geometry.map<LatLng>((coord) {
              final double lng = (coord[0] is int)
                  ? (coord[0] as int).toDouble()
                  : coord[0] as double;
              final double lat = (coord[1] is int)
                  ? (coord[1] as int).toDouble()
                  : coord[1] as double;
              return LatLng(lat, lng);
            }).toList();
            if (distance != 0) {
              alternativeRoutes.insert(0, routeCoordinates);
              alternativeDistances.insert(0, distance / 1000);
              alternativeDurations.insert(0, formatDuration(duration));
            }
          } catch (e) {
            continue;
          }
        }

        selectedRouteIndex = 0;
        notifyListeners();

        if (alternativeRoutes.isNotEmpty) {
          remainingRoutePoints =
              List.from(alternativeRoutes[selectedRouteIndex]);
        }
      }
    } catch (e) {
      // Restore previous route on error
      if (isGeneratingNewRoute) {
        remainingRoutePoints = previousRoutePoints;
      }
      rethrow;
    }

    notifyListeners();
  }

  /// Formats duration in seconds to a human-readable string (e.g., "15 mins" or "2 h 30 mins")
  String formatDuration(double seconds) {
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours h $remainingMinutes mins';
  }

  /// Toggles visibility of alternative routes on the map
  void toggleRoutes() {
    showRoutes = !showRoutes;
    notifyListeners();
  }

  /// Sets the transportation mode ('car', 'bike', or 'foot')
  void setSelectedRoute(String mode) {
    selectedRoute = mode;
    notifyListeners();
  }

  /// Selects an alternative route by index
  void setSelectedRouteIndex(int index) {
    if (index < alternativeRoutes.length) {
      selectedRouteIndex = index;
      // Update the remaining route points with the newly selected route
      remainingRoutePoints = List.from(alternativeRoutes[selectedRouteIndex]);
      // Update the map bounds to show the new route
      if (userPosition != null) {
        final lastPoint = remainingRoutePoints.last;
        fitBoundsToMarkers(lastPoint.latitude, lastPoint.longitude);
      }
      notifyListeners();
    }
  }

  /// Updates user heading with smoothing to prevent jerky rotations
  void updateHeading(double newHeading) {
    // Normalize bearing to 0-360 range
    newHeading = (newHeading + 360) % 360;

    // Add to queue and maintain size
    _bearingQueue.addLast(newHeading);
    if (_bearingQueue.length > _maxQueueSize) {
      _bearingQueue.removeFirst();
    }

    // Calculate moving average
    double avgHeading =
        _bearingQueue.reduce((a, b) => a + b) / _bearingQueue.length;

    // Update with less restrictive conditions
    if (_bearingQueue.length >= 2 &&
        ((_lastHeading - avgHeading).abs() > _minimumBearingChange)) {
      _lastHeading =
          _lastHeading + _smoothingFactor * (avgHeading - _lastHeading);
      userBearing = _lastHeading * (pi / 180);
      bearing = _lastHeading;
      notifyListeners();
    }
  }

  /// Updates the user's progress along the current route
  /// Handles route deviation and updates remaining distance/ETA
  void updateRouteProgress(Position currentPosition) {
    if (alternativeRoutes.isEmpty ||
        selectedRouteIndex >= alternativeRoutes.length ||
        isGeneratingNewRoute) {
      return;
    }

    final currentRoute = alternativeRoutes[selectedRouteIndex];
    if (currentRoute.isEmpty) return;

    var minDistance = double.infinity;
    var minIndex = 0;

    // Find closest point on route
    for (var i = 0; i < currentRoute.length; i++) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        currentRoute[i].latitude,
        currentRoute[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        minIndex = i;
      }
    }

    // Check for route deviation
    if (minDistance > deviationThreshold) {
      _handleRouteDeviation(currentPosition, currentRoute.last);
      return;
    }

    if (minIndex < currentRoute.length) {
      remainingRoutePoints = currentRoute.sublist(minIndex);

      // Update distance and ETA
      if (minIndex > 0) {
        double newDistance = 0;
        for (int i = minIndex; i < currentRoute.length - 1; i++) {
          newDistance += Geolocator.distanceBetween(
            currentRoute[i].latitude,
            currentRoute[i].longitude,
            currentRoute[i + 1].latitude,
            currentRoute[i + 1].longitude,
          );
        }
        alternativeDistances[selectedRouteIndex] = newDistance / 1000;
        updateETA();
      }
      notifyListeners();
    }

    if (isNavigationMode) {
      _updateNavigationInstructions();
    }
  }

  /// Generates turn instruction text based on angle
  String _getTurnInstruction(double angle) {
    if (angle > -30 && angle < 30) return "Continue straight";
    if (angle >= 30 && angle < 60) return "Turn slight right";
    if (angle >= 60 && angle < 120) return "Turn right";
    if (angle >= 120 && angle <= 180) return "Make a U-turn";
    if (angle <= -30 && angle > -60) return "Turn slight left";
    if (angle <= -60 && angle > -120) return "Turn left";
    if (angle <= -120 && angle >= -180) return "Make a U-turn";
    return "Continue straight";
  }

  /// Updates navigation instructions for turn-by-turn guidance
  void _updateNavigationInstructions() {
    if (!isNavigationMode ||
        remainingRoutePoints.isEmpty ||
        userPosition == null) {
      currentInstruction = null;
      return;
    }

    // Find next significant turn
    LatLng currentPos = LatLng(userPosition!.latitude, userPosition!.longitude);
    LatLng? nextTurn;
    double? turnAngle;

    for (int i = 0; i < remainingRoutePoints.length - 1; i++) {
      LatLng point1 = remainingRoutePoints[i];
      LatLng point2 = remainingRoutePoints[i + 1];

      double angle = _calculateBearingChange(point1, point2);
      if (angle.abs() > 30) {
        // Threshold for significant turn
        nextTurn = point1;
        turnAngle = angle;

        break;
      }
    }

    if (nextTurn != null) {
      double distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        nextTurn.latitude,
        nextTurn.longitude,
      );

      currentInstruction = NavigationInstruction(
        instruction: _getTurnInstruction(turnAngle!),
        distanceInMeters: distance,
        angle: turnAngle,
      );
    } else {
      debugPrint('No turns found in remaining route');
    }

    notifyListeners();
  }

  /// Calculates the bearing change between user's current heading and direction to next point
  double _calculateBearingChange(LatLng point1, LatLng point2) {
    double bearing1 = bearing;
    double bearing2 = Geolocator.bearingBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );

    double angle = bearing2 - bearing1;
    if (angle > 180) angle -= 360;

    if (angle < -180) angle += 360;
    return angle;
  }

  /// Handles recalculation of route when user deviates too far from path
  Future<void> _handleRouteDeviation(
      Position currentPosition, LatLng destination) async {
    if (isGeneratingNewRoute) {
      return;
    }

    isGeneratingNewRoute = true;
    previousRoutePoints = List.from(remainingRoutePoints);
    try {
      await getRoute(
        destinationLat: destination.latitude,
        destinationLng: destination.longitude,
      );
    } catch (e) {
      // Restore previous route if new route generation fails
      remainingRoutePoints = previousRoutePoints;
    } finally {
      isGeneratingNewRoute = false;
      notifyListeners();
    }
  }

  /// Starts periodic tracking of user's position along route
  void startRouteTracking(Position initialPosition) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      updateRouteBasedOnLocation();
    });
  }

  /// Updates route based on current location
  Future<void> updateRouteBasedOnLocation() async {
    try {
      final Position currentPosition = await Geolocator.getCurrentPosition();
      final LatLng currentLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      // Check if user deviated from route
      if (_hasDeviatedFromRoute(currentLatLng)) {
        await recalculateRoute(currentLatLng);
      } else {
        _removeTraversedSegments(currentLatLng);
      }

      notifyListeners();
    } catch (e) {
      print('Error updating route: $e');
    }
  }

  /// Checks if user has deviated from the planned route
  bool _hasDeviatedFromRoute(LatLng currentPosition) {
    if (currentRoute.isEmpty) return false;

    // Find closest point on route
    double minDistance = double.infinity;
    for (LatLng routePoint in currentRoute) {
      double distance = Geolocator.distanceBetween(currentPosition.latitude,
          currentPosition.longitude, routePoint.latitude, routePoint.longitude);
      minDistance = min(minDistance, distance);
    }

    return minDistance > deviationThreshold;
  }

  /// Removes segments of the route that have already been traversed
  void _removeTraversedSegments(LatLng currentPosition) {
    if (currentRoute.isEmpty) return;

    int removeUntilIndex = 0;
    double minDistance = double.infinity;

    // Find the closest point on route
    for (int i = 0; i < currentRoute.length; i++) {
      double distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          currentRoute[i].latitude,
          currentRoute[i].longitude);

      if (distance < minDistance) {
        minDistance = distance;
        removeUntilIndex = i;
      }
    }

    // Remove traversed segments
    if (removeUntilIndex > 0) {
      currentRoute.removeRange(0, removeUntilIndex);
    }
  }

  /// Recalculates route from current position to destination
  Future<void> recalculateRoute(LatLng currentPosition) async {
    if (currentRoute.isEmpty) return;

    final destination = currentRoute.last;
    final newRoute = await getRouteCoordinates(currentPosition.latitude,
        currentPosition.longitude, destination.latitude, destination.longitude);

    if (newRoute != null) {
      currentRoute = newRoute;
    }
  }

  /// Fetches route coordinates using OpenStreetMap routing API
  Future<List<LatLng>?> getRouteCoordinates(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final String transportMode = selectedRoute; // selectedRoute is non-nullable
    final String url =
        'https://routing.openstreetmap.de/routed-$transportMode/route/v1/driving/'
        '$startLng,$startLat;$endLng,$endLat'
        '?overview=full&alternatives=true&steps=true';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;

        if (routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry'];
          final decodedGeometry = PolylinePoints().decodePolyline(geometry);

          return decodedGeometry
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching route: $e');
      return null;
    }
  }

  /// Stops the periodic route tracking
  void stopRouteTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Fits the map view to show both user position and destination
  void fitBoundsToMarkers(double destinationLat, double destinationLng) {
    if (userPosition != null) {
      final points = <LatLng>[
        LatLng(userPosition!.latitude, userPosition!.longitude),
        LatLng(destinationLat, destinationLng),
      ];

      // Add route points to get better bounds
      if (remainingRoutePoints.isNotEmpty) {
        points.addAll(remainingRoutePoints);
      }

      final bounds = LatLngBounds.fromPoints(points);

      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
          maxZoom: 16.0,
        ),
      );
    }
  }

  /// Toggles turn-by-turn navigation mode
  void toggleNavigationMode() {
    isNavigationMode = !isNavigationMode;
    if (isNavigationMode) {
      _startNavigationUpdates();
    } else {
      _stopNavigationUpdates();
    }
    notifyListeners();
  }

  /// Starts periodic updates for navigation mode
  void _startNavigationUpdates() {
    _speedUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (userPosition != null) {
        updateSpeedAndETA(userPosition!);
      }
    });

    if (userPosition != null) {
      mapController.move(
        LatLng(userPosition!.latitude, userPosition!.longitude),
        18,
      );
      mapController.rotate(bearing);
    }
  }

  /// Updates current speed and estimated arrival time
  void updateSpeedAndETA(Position position) {
    if (_lastLocationUpdate != null) {
      final duration = position.timestamp.difference(_lastLocationUpdate!);

      if (duration.inMilliseconds > 0) {
        // Calculate instantaneous speed in km/h
        double newSpeed = position.speed * 3.6; // Convert m/s to km/h

        // Filter out unrealistic speeds
        if (newSpeed >= 0 && newSpeed < 200) {
          // Max reasonable speed
          _speedQueue.addLast(newSpeed);
          if (_speedQueue.length > _maxSpeedQueueSize) {
            _speedQueue.removeFirst();
          }

          // Calculate moving average speed
          _averageSpeed = _speedQueue.isNotEmpty
              ? _speedQueue.reduce((a, b) => a + b) / _speedQueue.length
              : 0.0;

          currentSpeed = _averageSpeed;

          // Update ETA based on new speed
          updateETA();
        }
      }
    }

    _lastLocationUpdate = position.timestamp;
    notifyListeners();
  }

  /// Updates estimated time of arrival based on current speed and remaining distance
  void updateETA() {
    if (alternativeRoutes.isEmpty ||
        selectedRouteIndex >= alternativeDistances.length) {
      return;
    }

    final remainingDistance = alternativeDistances[selectedRouteIndex]; // in km

    // Calculate ETA based on current average speed
    if (_averageSpeed > 1.0) {
      // Only update if moving faster than 1 km/h
      final hours = remainingDistance / _averageSpeed;
      final minutes = (hours * 60).round();

      if (minutes < 60) {
        alternativeDurations[selectedRouteIndex] = '$minutes mins';
      } else {
        final wholeHours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;
        alternativeDurations[selectedRouteIndex] =
            '$wholeHours h $remainingMinutes mins';
      }
      notifyListeners();
    } else {
      // If nearly stationary, use default calculation based on transport mode
      double duration =
          remainingDistance * 3600 / getAverageSpeedForMode(); // in seconds
      alternativeDurations[selectedRouteIndex] = formatDuration(duration);
      notifyListeners();
    }
  }

  /// Returns average speed for the selected transportation mode in km/h
  double getAverageSpeedForMode() {
    switch (selectedRoute) {
      case 'foot':
        return 5.0; // Average walking speed in km/h
      case 'bike':
        return 15.0; // Average cycling speed in km/h
      case 'car':
        return 40.0; // Average urban driving speed in km/h
      default:
        return 5.0;
    }
  }

  /// Stops navigation updates and resets map rotation
  void _stopNavigationUpdates() {
    _speedUpdateTimer?.cancel();
    mapController.rotate(0); // Reset rotation
  }

  /// Updates map camera position for navigation mode
  void updateMapForNavigation() {
    if (isNavigationMode && userPosition != null) {
      // Calculate position slightly ahead of user for better visibility
      final followPoint = _calculateFollowPoint();

      mapController.move(
        followPoint,
        18, // High zoom level for navigation
      );
      mapController.rotate(bearing);
    }
  }

  /// Calculates a point slightly ahead of the user for better map visibility during navigation
  LatLng _calculateFollowPoint() {
    if (userPosition == null) return const LatLng(0, 0);

    // Offset the camera point slightly ahead of user position
    const double offsetMeters = 50.0; // Show 50m ahead
    final double bearingRad = bearing * (pi / 180);

    // Calculate offset position using bearing
    final double latOffset =
        (offsetMeters * cos(bearingRad)) / 111111.0; // approx meters per degree
    final double lngOffset = (offsetMeters * sin(bearingRad)) /
        (111111.0 * cos(userPosition!.latitude * (pi / 180)));

    return LatLng(
      userPosition!.latitude + latOffset,
      userPosition!.longitude + lngOffset,
    );
  }

  /// Cleans up resources when the provider is disposed
  @override
  void dispose() {
    // Cancel all timers
    _locationTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _speedUpdateTimer?.cancel();
    _headingSmootherTimer?.cancel();

    // Cancel all subscriptions
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();

    // Dispose optimized services
    _locationService.dispose();
    _tileService.clearTileCache();

    // Clear data structures
    _bearingQueue.clear();
    _speedQueue.clear();
    alternativeRoutes.clear();
    alternativeDistances.clear();
    alternativeDurations.clear();
    remainingRoutePoints.clear();
    routePoints.clear();
    currentRoute.clear();

    // Dispose controllers
    mapController.dispose();

    // Reset state variables
    userPosition = null;
    _lastRouteUpdate = null;
    _lastLocationUpdate = null;
    // _previousPosition = null; // Legacy field, now handled by OptimizedLocationService
    currentInstruction = null;
    isNavigationMode = false;
    showRoutes = false;
    _isInitialized = false;
    _disposed = true;

    super.dispose();
  }

  /// Fetches a route through multiple destinations (up to 4)
  /// Starts from user's current location and visits each destination in sequence
  Future<void> getMultipleRoute({
    required List<Map<String, double>> destinations,
  }) async {
    if (_disposed || userPosition == null) return;
    if (destinations.isEmpty || destinations.length > 4) {
      throw ArgumentError('Must provide between 1 and 4 destinations');
    }

    totalDestinations = destinations.length;
    currentDestinationIndex = 0;
    multiDestinationPoints = [];

    void clearRouteData() {
      alternativeRoutes.clear();
      alternativeDistances.clear();
      alternativeDurations.clear();
      remainingRoutePoints.clear();
      print("Routes cleared for multiple destinations");
    }

    if (!isGeneratingNewRoute) {
      previousRoutePoints = List.from(remainingRoutePoints);
      clearRouteData();
    }

    try {
      // Build waypoints string for the API call
      String waypointsString = '';

      // Start with user position
      waypointsString = '${userPosition!.longitude},${userPosition!.latitude}';

      // Add all destinations
      for (var destination in destinations) {
        waypointsString += ';${destination['lng']},${destination['lat']}';
      }

      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/$selectedRoute/'
        '$waypointsString'
        '?overview=full&geometries=geojson&alternatives=false&steps=true',
      );

      if (response.data['code'] == 'Ok') {
        final route = response.data['routes'][0];
        final geometry = route['geometry']['coordinates'] as List;
        final distance = (route['distance'] as num).toDouble();
        double duration = (route['duration'] as num).toDouble();
        final List<LatLng> routeCoordinates = [];

        // Get route legs (segments between waypoints)        // The 'legs' can be used to identify specific sections between waypoints if needed
        // Extract coordinates
        try {
          // Process all coordinates for the complete route
          for (var coord in geometry) {
            final double lng = (coord[0] is int)
                ? (coord[0] as int).toDouble()
                : coord[0] as double;
            final double lat = (coord[1] is int)
                ? (coord[1] as int).toDouble()
                : coord[1] as double;
            routeCoordinates.add(LatLng(lat, lng));
          }

          // Save the full multi-destination route
          multiDestinationPoints = List.from(routeCoordinates);

          // Adjust duration based on transportation mode
          switch (selectedRoute) {
            case 'foot':
              duration *= 16;
              break;
            case 'bike':
              duration *= 2.5;
              break;
            case 'car':
              duration *= 1.5;
              break;
          }

          // Set as the primary route
          if (distance != 0) {
            alternativeRoutes = [routeCoordinates];
            alternativeDistances = [distance / 1000];
            alternativeDurations = [formatDuration(duration)];
            remainingRoutePoints = List.from(routeCoordinates);
          }
        } catch (e) {
          print('Error processing multiple route coordinates: $e');
          rethrow;
        }

        selectedRouteIndex = 0;
        notifyListeners();
      }
    } catch (e) {
      // Restore previous route on error
      if (isGeneratingNewRoute) {
        remainingRoutePoints = previousRoutePoints;
      }
      print('Error fetching multiple destination route: $e');
      rethrow;
    }

    notifyListeners();
  }

  /// Advances to the next destination in a multi-destination route
  /// Returns true if successfully advanced, false if at the last destination
  bool advanceToNextDestination() {
    if (currentDestinationIndex < totalDestinations - 1) {
      currentDestinationIndex++;
      // You could update UI elements here to show progress
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Gets the current destination index and total count
  Map<String, int> getMultiDestinationProgress() {
    return {
      'current': currentDestinationIndex + 1, // 1-indexed for display
      'total': totalDestinations,
    };
  }
}
