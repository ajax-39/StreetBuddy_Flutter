import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/Location/map_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/navigation_instruction_widget.dart';
import 'package:street_buddy/widgets/direction_cursor.dart';
import 'package:street_buddy/widgets/speedometer_widget.dart';

class MapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String placeName;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapProvider(),
      child: Builder(
        builder: (context) {
          final provider = Provider.of<MapProvider>(context, listen: false);

          Future.microtask(() async {
            await provider.initializeLocation();
            if (!provider.disposed) {
              await provider.getRoute(
                destinationLat: latitude,
                destinationLng: longitude,
              );
              if (!provider.disposed) {
                provider.fitBoundsToMarkers(latitude, longitude);
              }
            }
          });

          return WillPopScope(
            onWillPop: () async {
              provider.dispose();
              return true;
            },
            child: MapScreenContent(
              latitude: latitude,
              longitude: longitude,
              placeName: placeName,
            ),
          );
        },
      ),
    );
  }
}

class MapScreenContent extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String placeName;

  const MapScreenContent({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.placeName,
  });

  Widget _buildTransportButton({
    required IconData icon,
    required String mode,
    required String label,
    required MapProvider provider,
  }) {
    final isSelected = provider.selectedRoute == mode;
    return GestureDetector(
      onTap: () {
        provider.setSelectedRoute(mode);
        provider.getRoute(
          destinationLat: latitude,
          destinationLng: longitude,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

// Update the _buildRoutesDropdown method in MapScreenContent class
  Widget _buildRoutesDropdown(MapProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showRoutes ? 120 : -1000,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Routes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => provider.toggleRoutes(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.alternativeRoutes.length > 2
                  ? 2
                  : provider.alternativeRoutes.length,
              itemBuilder: (context, i) => ListTile(
                selected: provider.selectedRouteIndex == i,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                leading: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: provider.selectedRouteIndex == i
                        ? Colors.blue
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Route ${String.fromCharCode(65 + i)}',
                    style: TextStyle(
                      color: provider.selectedRouteIndex == i
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                title: Text(
                  '${provider.alternativeDistances[i].toStringAsFixed(2)} km',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(provider.alternativeDurations[i]),
                trailing: Icon(
                  Icons.chevron_right,
                  color: provider.selectedRouteIndex == i
                      ? Colors.blue
                      : Colors.grey,
                ),
                onTap: () {
                  provider.setSelectedRouteIndex(i);
                  // Optionally close the routes dropdown after selection
                  provider.toggleRoutes();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(placeName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (!provider.isNavigationMode &&
                  provider.alternativeRoutes.isNotEmpty)
                IconButton(
                  icon: Icon(
                      provider.showRoutes ? Icons.route : Icons.route_outlined),
                  onPressed: () => provider.toggleRoutes(),
                ),
              IconButton(
                icon: Icon(provider.isNavigationMode
                    ? Icons.navigation_outlined
                    : Icons.navigation),
                onPressed: () => provider.toggleNavigationMode(),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Main map layer
              Positioned.fill(
                child: FlutterMap(
                  mapController: provider.mapController,
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: provider.isNavigationMode ? 18 : 13,
                    initialRotation:
                        provider.isNavigationMode ? provider.bearing : 0,
                  ),
                  children: [
                    // Use optimized tile layer for better performance
                    provider.getOptimizedTileLayer(),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: provider.remainingRoutePoints,
                          color: Colors.blue,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),
                          width: 80,
                          height: 80,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                        if (provider.userPosition != null)
                          Marker(
                            point: LatLng(
                              provider.userPosition!.latitude,
                              provider.userPosition!.longitude,
                            ),
                            width: 30,
                            height: 30,
                            child: AnimatedRotation(
                              turns: provider.userBearing / (2 * pi),
                              duration: const Duration(milliseconds: 200),
                              child: DirectionalCursor(
                                  bearing: provider.userBearing),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transport mode selector - only visible when not in navigation mode
              if (!provider.isNavigationMode)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTransportButton(
                          icon: Icons.directions_walk,
                          mode: 'foot',
                          label: 'Walk',
                          provider: provider,
                        ),
                        const SizedBox(width: 16),
                        _buildTransportButton(
                          icon: Icons.directions_bike,
                          mode: 'bike',
                          label: 'Bike',
                          provider: provider,
                        ),
                        const SizedBox(width: 16),
                        _buildTransportButton(
                          icon: Icons.directions_car,
                          mode: 'car',
                          label: 'Drive',
                          provider: provider,
                        ),
                      ],
                    ),
                  ),
                ),

              // Routes dropdown - only visible when not in navigation mode
              if (!provider.isNavigationMode &&
                  provider.alternativeRoutes.isNotEmpty)
                _buildRoutesDropdown(provider),

              // Speedometer - only visible in navigation mode
              if (provider.isNavigationMode)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Speedometer(
                    speed: provider.currentSpeed,
                    eta: provider
                        .alternativeDurations[provider.selectedRouteIndex],
                  ),
                ),

              // Navigation instruction - only visible in navigation mode
              if (provider.isNavigationMode &&
                  provider.currentInstruction != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: NavigationInstructionWidget(
                    key: ValueKey(provider.currentInstruction.hashCode),
                    instruction: provider.currentInstruction!.instruction,
                    distance: provider.currentInstruction!.distanceInMeters,
                  ),
                ),
            ],
          ),
          floatingActionButton: provider.isNavigationMode
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    if (provider.userPosition != null) {
                      provider.mapController.move(
                        LatLng(
                          provider.userPosition!.latitude,
                          provider.userPosition!.longitude,
                        ),
                        16,
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
        );
      },
    );
  }
}
