import 'package:flutter/material.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/services/database_helper.dart';
import 'package:street_buddy/utils/url_util.dart';

class CacheVisualizationScreen extends StatefulWidget {
  const CacheVisualizationScreen({super.key});

  @override
  _CacheVisualizationScreenState createState() =>
      _CacheVisualizationScreenState();
}

class _CacheVisualizationScreenState extends State<CacheVisualizationScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _showingLocations = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cached Data'),
          bottom: TabBar(
            dividerHeight: 1,
            dividerColor: Colors.grey[300],
            onTap: (index) {
              setState(() {
                _showingLocations = index == 0;
              });
            },
            tabs: const [
              Tab(text: 'Locations'),
              Tab(text: 'Places'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteDialog(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildLocationsList(),
            _buildPlacesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    return FutureBuilder<List<LocationModel>>(
      future: _dbHelper.getAllLocations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final locations = snapshot.data!;
        if (locations.isEmpty) {
          return const Center(child: Text('No cached locations'));
        }

        return ListView.builder(
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final location = locations[index];
            return ListTile(
              title: Text(location.name),
              subtitle: Text(location.description),
              leading: location.primaryImageUrl.startsWith('assets/')
                  ? Image.asset(location.primaryImageUrl, width: 50, height: 50)
                  : Image.network(location.primaryImageUrl,
                      width: 50, height: 50),
              trailing: Text('${location.rating.toStringAsFixed(1)}★'),
            );
          },
        );
      },
    );
  }

  Widget _buildPlacesList() {
    return FutureBuilder<List<PlaceModel>>(
      future: _dbHelper.getAllPlaces(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final places = snapshot.data!;
        if (places.isEmpty) {
          return const Center(child: Text('No cached places'));
        }

        return ListView.builder(
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return ListTile(
              title: Text(place.name),
              subtitle: Text(place.vicinity ?? ''),
              leading: place.photoUrl != null
                  ? Image.network(
                      UrlUtils.addApiKeyToPhotoUrl(
                          place.photoUrl, Constant.GOOGLE_API),
                      width: 50,
                      height: 50)
                  : const Icon(Icons.place),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${place.rating.toStringAsFixed(1)}★'),
                  Text('(${place.userRatingsTotal})'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Choose data to clear:'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Clear Locations'),
            onPressed: () async {
              await _dbHelper.clearAllLocations();
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All locations cleared')),
              );
            },
          ),
          TextButton(
            child: const Text('Clear Places'),
            onPressed: () async {
              await _dbHelper.clearAllPlaces();
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All places cleared')),
              );
            },
          ),
          TextButton(
            child: const Text('Clear Everything'),
            onPressed: () async {
              await _dbHelper.clearAllData();
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
          ),
          TextButton(
            child: const Text('Old Data (>24h)'),
            onPressed: () async {
              await _dbHelper.deleteOldData(const Duration(hours: 24));
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Old data cleared')),
              );
            },
          ),
        ],
      ),
    );
  }
}
