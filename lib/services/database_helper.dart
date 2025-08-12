import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'street_buddy.db');
    return await openDatabase(
      path,
      version: 2, // Increment version
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint(' Upgrading database from v$oldVersion to v$newVersion');

    // Drop existing tables and recreate
    await db.execute('DROP TABLE IF EXISTS places');
    await db.execute('DROP TABLE IF EXISTS locations');

    // Recreate tables
    await _createDb(db, newVersion);
  }

  // Location methods
  Future<void> insertLocation(LocationModel location) async {
    final db = await database;
    await db.insert(
      'locations',
      {
        'id': location.id,
        'name': location.name,
        'name_lowercase': location.nameLowercase,
        'image_urls': location.imageUrls.join('|'),
        'description': location.description,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'rating': location.rating,
        'cached_at': location.cachedAt?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        'created_at': location.createdAt?.millisecondsSinceEpoch,
        'updated_at': location.updatedAt?.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocationModel?> getLocation(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToLocation(maps[0]);
  }

  Future<List<LocationModel>> getAllLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('locations');

    return maps.map((map) => _mapToLocation(map)).toList();
  }

  LocationModel _mapToLocation(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'],
      name: map['name'],
      nameLowercase: map['name_lowercase'],
      imageUrls: (map['image_urls'] as String).split('|'),
      description: map['description'] ?? '',
      latitude: map['latitude'],
      longitude: map['longitude'],
      rating: map['rating'] ?? 0.0,
      cachedAt: map['cached_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['cached_at'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  // Add new methods to DatabaseHelper class

  Future<bool> placeExists(String id) async {
    final db = await database;
    final result = await db.query(
      'places',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<PlaceModel>> getPlacesByType(String type, double lat, double lng,
      {double radiusInKm = 50}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'places',
        where: 'types LIKE ?',
        whereArgs: ['%$type%'],
      );

      debugPrint(
          'Found ${maps.length} places in local database for type: $type');

      // Convert to PlaceModel list and filter by distance
      List<PlaceModel> places = [];

      for (var map in maps) {
        try {
          // Calculate distance from requested location
          final distance = Geolocator.distanceBetween(
            lat,
            lng,
            map['latitude'],
            map['longitude'],
          );

          // Only include places within the specified radius
          if (distance <= (radiusInKm * 1000)) {
            // Parse opening hours
            Map<String, String> openingHours = {};
            if (map['openingHours'] != null) {
              final hours = map['openingHours'].toString().split('|');
              for (var hour in hours) {
                final parts = hour.split(':');
                if (parts.length == 2) {
                  openingHours[parts[0]] = parts[1];
                }
              }
            }

            // Parse price range
            PriceRange? priceRange;
            if (map['priceRange'] != null) {
              try {
                final priceData = map['priceRange']
                    .toString()
                    .replaceAll('{', '')
                    .replaceAll('}', '')
                    .split(',')
                    .map((e) => e.split(':'))
                    .where((e) => e.length == 2)
                    .map((e) => MapEntry(e[0].trim(), int.parse(e[1].trim())))
                    .toList();

                if (priceData.isNotEmpty) {
                  priceRange = PriceRange(
                      minPrice: priceData.first.value,
                      maxPrice: priceData.last.value);
                }
              } catch (e) {
                debugPrint('Error parsing price range: $e');
              }
            }

            final place = PlaceModel(
              id: map['id'],
              name: map['name'],
              vicinity: map['vicinity'],
              description: map['description'],
              rating: map['rating'] ?? 0.0,
              userRatingsTotal: map['userRatingsTotal'] ?? 0,
              latitude: map['latitude'],
              longitude: map['longitude'],
              photoUrl: map['photoUrl'] == Constant.DEFAULT_PLACE_IMAGE
                  ? Constant.DEFAULT_PLACE_IMAGE
                  : map['photoUrl'],
              openNow: map['openNow'] == 1,
              types: (map['types'] as String).split('|'),
              distanceFromUser: distance,
              customRating: map['customRating'] ?? 0.0,
              reviewCount: map['reviewCount'] ?? 0,
              phoneNumber: map['phoneNumber'],
              openingHours: openingHours,
              priceRange: priceRange,
              city: map['city'],
              state: map['state'],
              isHiddenGem: map['isHiddenGem'] == 1,
            );

            places.add(place);
          }
        } catch (e) {
          debugPrint('Error processing place from database: $e');
          continue;
        }
      }

      // Sort places by distance
      places.sort((a, b) => (a.distanceFromUser ?? double.infinity)
          .compareTo(b.distanceFromUser ?? double.infinity));

      return places;
    } catch (e) {
      debugPrint('Error getting places by type: $e');
      return [];
    }
  }

  Future<void> cleanupOldData() async {
    try {
      final db = DatabaseHelper();
      // Delete data older than 24 hours
      await db.deleteOldData(const Duration(hours: 24));
      debugPrint(' Cleaned up old place data');
    } catch (e) {
      debugPrint(' Error cleaning up old data: $e');
    }
  }

  // Place methods
  Future<void> insertPlace(PlaceModel place) async {
    final db = await database;

    // Convert complex types to strings
    final map = {
      'id': place.id,
      'name': place.name,
      'vicinity': place.vicinity,
      'description': place.description,
      'rating': place.rating,
      'userRatingsTotal': place.userRatingsTotal,
      'latitude': place.latitude,
      'longitude': place.longitude,
      'photoUrl': place.photoUrl,
      'openNow': place.openNow ? 1 : 0,
      'types': place.types.join('|'),
      'distanceFromUser': place.distanceFromUser,
      'emojiCounts': place.emojiCounts.isEmpty
          ? null
          : place.emojiCounts.map((k, v) => MapEntry(k.name, v)).toString(),
      'customRating': place.customRating,
      'reviewCount': place.reviewCount,
      'reviewIds': place.reviewIds.isEmpty ? null : place.reviewIds.join('|'),
      'phoneNumber': place.phoneNumber,
      'city': place.city,
      'state': place.state,
      'isHiddenGem': place.isHiddenGem ? 1 : 0,
      'last_updated': DateTime.now().millisecondsSinceEpoch,
      'openingHours': place.openingHours.isEmpty
          ? null
          : place.openingHours.entries
              .map((e) => '${e.key}:${e.value}')
              .join('|'),
      'priceRange': place.priceRange?.toMap().toString()
    };

    debugPrint(' Caching place: ${place.name}');
    await db.insert('places', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE places (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        vicinity TEXT,
        description TEXT,
        rating REAL DEFAULT 0,
        userRatingsTotal INTEGER DEFAULT 0,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        photoUrl TEXT,
        openNow INTEGER DEFAULT 0,
        types TEXT NOT NULL,
        distanceFromUser REAL,
        emojiCounts TEXT,
        customRating REAL DEFAULT 0,
        reviewCount INTEGER DEFAULT 0,
        reviewIds TEXT,
        phoneNumber TEXT,
        city TEXT,
        state TEXT,
        isHiddenGem INTEGER DEFAULT 0,
        last_updated INTEGER NOT NULL,
        openingHours TEXT,
        priceRange TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_lowercase TEXT NOT NULL,
        image_urls TEXT,
        description TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        rating REAL DEFAULT 0,
        cached_at INTEGER,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_images (
        url TEXT PRIMARY KEY,
        image_data BLOB,
        last_updated INTEGER NOT NULL
      )
    ''');
  }

  Future<PlaceModel?> getPlace(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'places',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return _mapToPlace(maps[0]);
  }

  Future<List<PlaceModel>> getAllPlaces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('places');

    return maps.map((map) => _mapToPlace(map)).toList();
  }

  PlaceModel _mapToPlace(Map<String, dynamic> map) {
    // Parse opening hours
    Map<String, String> openingHours = {};
    if (map['openingHours'] != null) {
      final hours = map['openingHours'].toString().split('|');
      for (var hour in hours) {
        final parts = hour.split(':');
        if (parts.length == 2) {
          openingHours[parts[0]] = parts[1];
        }
      }
    }

    // Parse price range
    PriceRange? priceRange;
    if (map['priceRange'] != null) {
      try {
        final priceData = map['priceRange']
            .toString()
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',')
            .map((e) => e.split(':'))
            .where((e) => e.length == 2)
            .map((e) => MapEntry(e[0].trim(), int.parse(e[1].trim())))
            .toList();

        if (priceData.isNotEmpty) {
          priceRange = PriceRange(
              minPrice: priceData.first.value, maxPrice: priceData.last.value);
        }
      } catch (e) {
        debugPrint('Error parsing price range: $e');
      }
    }

    return PlaceModel(
      id: map['id'],
      name: map['name'],
      vicinity: map['vicinity'],
      description: map['description'],
      rating: map['rating'] ?? 0.0,
      userRatingsTotal: map['userRatingsTotal'] ?? 0,
      latitude: map['latitude'],
      longitude: map['longitude'],
      photoUrl: map['photoUrl'],
      openNow: map['openNow'] == 1,
      types: (map['types'] as String).split('|'),
      distanceFromUser: map['distanceFromUser'],
      customRating: map['customRating'] ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      phoneNumber: map['phoneNumber'],
      openingHours: openingHours,
      priceRange: priceRange,
      city: map['city'],
      state: map['state'],
      isHiddenGem: map['isHiddenGem'] == 1,
    );
  }

  Future<void> updateDynamicData(
    String id, {
    double? rating,
    int? userRatingsTotal,
    bool? openNow,
    double? distanceFromUser,
  }) async {
    final db = await database;
    final map = <String, dynamic>{
      'last_updated': DateTime.now().millisecondsSinceEpoch
    };

    if (rating != null) map['rating'] = rating;
    if (userRatingsTotal != null) map['userRatingsTotal'] = userRatingsTotal;
    if (openNow != null) map['openNow'] = openNow ? 1 : 0;
    if (distanceFromUser != null) map['distanceFromUser'] = distanceFromUser;

    await db.update(
      'places',
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint(' Updated dynamic data for place: $id');
  }

  Future<void> deleteOldData(Duration maxAge) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;

    await db.delete(
      'locations',
      where: 'last_updated < ?',
      whereArgs: [cutoffTime],
    );

    await db.delete(
      'places',
      where: 'last_updated < ?',
      whereArgs: [cutoffTime],
    );
  }

  Future<void> clearAllLocations() async {
    final db = await database;
    await db.delete('locations');
  }

  Future<void> clearAllPlaces() async {
    final db = await database;
    await db.delete('places');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('locations');
    await db.delete('places');
  }

  // Add methods for image caching
  Future<void> cacheImage(String url, List<int> imageData) async {
    try {
      final db = await database;
      await db.insert(
        'cached_images',
        {
          'url': url,
          'image_data': imageData,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint(
          ' Image cached successfully: $url (${imageData.length} bytes)');
    } catch (e) {
      debugPrint(' Error caching image in database: $e');
    }
  }

  Future<List<int>?> getCachedImage(String url) async {
    try {
      final db = await database;
      final result = await db.query(
        'cached_images',
        columns: ['image_data'],
        where: 'url = ?',
        whereArgs: [url],
      );

      if (result.isNotEmpty && result.first['image_data'] != null) {
        final imageData = result.first['image_data'] as List<int>;
        debugPrint(' Retrieved cached image: $url (${imageData.length} bytes)');
        return imageData;
      }
      return null;
    } catch (e) {
      debugPrint(' Error retrieving cached image: $e');
      return null;
    }
  }

  Future<void> removePlace(String placeId) async {
    try {
      final db = await database;
      await db.delete(
        'places',
        where: 'id = ?',
        whereArgs: [placeId],
      );
      debugPrint(' Removed place from cache: $placeId');
    } catch (e) {
      debugPrint('Error removing place from cache: $e');
    }
  }
}
