import 'package:street_buddy/models/rating.dart';

enum PlaceCategory { restaurant, hotel, shopping, attraction, unknown }

class PlaceModel {
  final String id;
  final String name;
  final String? vicinity;
  final String? description;
  final double rating;
  final int userRatingsTotal;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final List<String> mediaUrls;
  final String? googlePlacesId; // Google Places API ID for custom places
  final bool openNow;
  final List<String> types;
  double? distanceFromUser;
  final Map<PlaceEmoji, int> emojiCounts;
  final int reviewCount;
  final double customRating;
  final List<String> reviewIds;
  final String? phoneNumber;
  final Map<String, String> openingHours;
  final PriceRange? priceRange;
  final String? city;
  final String? state;
  final bool isHiddenGem;
  final String? tips;
  final String? extras;
  final bool isPremium;
  final DateTime? photoCachedAt;
  final DateTime? photoExpiresAt;
  final DateTime? photoLastValidatedAt;
  final bool photoRefreshNeeded;
  final DateTime? mediaCachedAt;
  final DateTime? mediaExpiresAt;
  final DateTime? mediaLastValidatedAt;
  final bool mediaRefreshNeeded;

  PlaceModel({
    required this.id,
    required this.name,
    this.vicinity,
    this.description,
    required this.rating,
    required this.userRatingsTotal,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    List<String>? mediaUrls,
    this.googlePlacesId,
    required this.openNow,
    required this.types,
    this.distanceFromUser,
    Map<PlaceEmoji, int>? emojiCounts,
    this.reviewCount = 0,
    this.customRating = 0.0,
    List<String>? reviewIds,
    this.phoneNumber,
    Map<String, String>? openingHours,
    this.priceRange,
    this.city,
    this.state,
    this.isHiddenGem = false,
    this.tips,
    this.extras,
    this.isPremium = false,
    this.photoCachedAt,
    this.photoExpiresAt,
    this.photoLastValidatedAt,
    this.photoRefreshNeeded = false,
    this.mediaCachedAt,
    this.mediaExpiresAt,
    this.mediaLastValidatedAt,
    this.mediaRefreshNeeded = false,
  })  : emojiCounts = emojiCounts ?? {},
        reviewIds = reviewIds ?? [],
        openingHours = openingHours ?? {},
        mediaUrls = mediaUrls ?? [];
  factory PlaceModel.fromSupabase(Map<String, dynamic> data) {
    // Parse opening hours from jsonb
    Map<String, String> openingHours = {};
    if (data['opening_hours'] != null) {
      final hours = data['opening_hours'] as Map<String, dynamic>;
      hours.forEach((key, value) {
        if (value is String) {
          openingHours[key] = value;
        }
      });
    }

    // Parse price range
    PriceRange? priceRange;
    if (data['price_range'] != null) {
      priceRange =
          PriceRange.fromMap(data['price_range'] as Map<String, dynamic>);
    }

    return PlaceModel(
      id: data['id'],
      name: data['name'],
      vicinity: data['vicinity'],
      description: data['description'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      photoUrl: data['photo_url'],
      mediaUrls: data['media_urls'] != null
          ? List<String>.from(data['media_urls'])
          : [],
      googlePlacesId: data['google_places_id'],
      types: List<String>.from(data['types'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: data['user_ratings_total'] ?? 0,
      city: data['city'],
      state: data['state'],
      openNow: false, // We don't store real-time open status in the DB
      isHiddenGem: data['is_hidden_gem'] ?? false,
      tips: data['tips'],
      extras: data['extras'],
      phoneNumber: data['phone_number'],
      openingHours: openingHours,
      priceRange: priceRange,
      customRating: (data['custom_rating'] ?? 0.0).toDouble(),

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
      isPremium: data['is_premium'] ?? false,
    );
  }

  @override
  String toString() {
    return 'PlaceModel{\n'
        '  id: $id,\n'
        '  name: $name,\n'
        '  vicinity: $vicinity,\n'
        '  description: ${description != null ? (description!.length > 50 ? "${description!.substring(0, 50)}..." : description) : null},\n'
        '  rating: $rating,\n'
        '  userRatingsTotal: $userRatingsTotal,\n'
        '  location: ($latitude, $longitude),\n'
        '  photoUrl: ${photoUrl != null ? "Available" : "None"},\n'
        '  mediaUrls: ${mediaUrls.isNotEmpty ? "${mediaUrls.length} URLs" : "None"},\n'
        '  openNow: $openNow,\n'
        '  types: $types,\n'
        '  reviewCount: $reviewCount,\n'
        '  customRating: $customRating,\n'
        '  phoneNumber: $phoneNumber,\n'
        '  city: $city,\n'
        '  state: $state,\n'
        '  isHiddenGem: $isHiddenGem,\n'
        '  priceRange: ${priceRange != null ? "${priceRange!.minPrice}-${priceRange!.maxPrice}" : "None"}\n'
        '}';
  }

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    // Handle both Google Places API and Supabase database formats
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    // If location is null, use direct latitude/longitude from database
    final double lat = location?['lat'] ?? json['latitude'] ?? 0.0;
    final double lng = location?['lng'] ?? json['longitude'] ?? 0.0;

    // Handle opening hours from both sources
    final Map<String, String> parsedOpeningHours = {};
    if (json['opening_hours'] != null) {
      if (json['opening_hours'] is Map) {
        final Map<String, dynamic> hours =
            json['opening_hours'] as Map<String, dynamic>;
        hours.forEach((key, value) {
          if (value is String) {
            parsedOpeningHours[key] = value;
          }
        });
      } else if (json['opening_hours']['periods'] != null) {
        final periods = json['opening_hours']['periods'] as List;
        for (var period in periods) {
          if (period['open'] != null && period['close'] != null) {
            final day = _getDayString(period['open']['day']);
            final openTime = _formatTime(period['open']['time']);
            final closeTime = _formatTime(period['close']['time']);
            parsedOpeningHours[day] = '$openTime-$closeTime';
          }
        }
      }
    }

    // Handle price range
    PriceRange? priceRange;
    if (json['price_range'] != null) {
      priceRange =
          PriceRange.fromMap(json['price_range'] as Map<String, dynamic>);
    }

    return PlaceModel(
      id: json['place_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      vicinity: json['vicinity'],
      description: json['description'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      latitude: lat,
      longitude: lng,
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      mediaUrls: json['media_urls'] != null
          ? List<String>.from(json['media_urls'])
          : [],
      googlePlacesId: json['google_places_id'],
      openNow: json['open_now'] ?? false,
      types: List<String>.from(json['types'] ?? []),
      phoneNumber: json['phone_number'] ?? json['formatted_phone_number'],
      openingHours: parsedOpeningHours,
      priceRange: priceRange,
      city: json['city'],
      state: json['state'],
      isHiddenGem: json['is_hidden_gem'] ?? false,
      tips: json['tips'],
      extras: json['extras'],
      customRating: (json['custom_rating'] ?? 0.0).toDouble(),
      emojiCounts: {}, // Initialize empty
      reviewIds: [], // Initialize empty
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'vicinity': vicinity,
      'description': description,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'mediaUrls': mediaUrls,
      'openNow': openNow,
      'types': types,
      'distanceFromUser': distanceFromUser,
      'emojiCounts': emojiCounts.map((k, v) => MapEntry(k.name, v)),
      'reviewCount': reviewCount,
      'customRating': customRating,
      'reviewIds': reviewIds,
      'phoneNumber': phoneNumber,
      'openingHours': openingHours,
      'priceRange': priceRange?.toMap(),
      'city': city,
      'state': state,
      'isHiddenGem': isHiddenGem,
      'tips': tips,
      'extras': extras,
      'isPremium': isPremium,
    };
  }

  factory PlaceModel.fromFirestore(Map<String, dynamic> data) {
    Map<String, String> openingHours = {};
    if (data['openingHours'] is Map) {
      final hours = data['openingHours'] as Map;
      hours.forEach((key, value) {
        if (key is String && value is String) {
          openingHours[key] = value;
        }
      });
    }

    return PlaceModel(
      id: data['id'],
      name: data['name'],
      vicinity: data['vicinity'],
      description: data['description'],
      rating: data['rating'] ?? 0.0,
      userRatingsTotal: data['userRatingsTotal'] ?? 0,
      latitude: data['latitude'],
      longitude: data['longitude'],
      photoUrl: data['photoUrl'],
      mediaUrls:
          data['mediaUrls'] != null ? List<String>.from(data['mediaUrls']) : [],
      openNow: data['openNow'] ?? false,
      types: List<String>.from(data['types'] ?? []),
      distanceFromUser: data['distanceFromUser'],
      emojiCounts: (data['emojiCounts'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(PlaceEmoji.values.byName(k), v as int)) ??
          {},
      reviewCount: data['reviewCount'] ?? 0,
      customRating: (data['customRating'] ?? 0.0).toDouble(),
      reviewIds: List<String>.from(data['reviewIds'] ?? []),
      phoneNumber: data['phoneNumber']?.toString(),
      openingHours: openingHours,
      priceRange: data['priceRange'] is Map
          ? PriceRange.fromMap(Map<String, dynamic>.from(data['priceRange']))
          : null,
      city: data['city']?.toString(),
      state: data['state']?.toString(),
      isHiddenGem: data['isHiddenGem'] ?? false,
      tips: data['tips']?.toString(),
      extras: data['extras']?.toString(),
      isPremium: data['is_premium'] ?? false,
    );
  }

  static String _getDayString(int day) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[day];
  }

  static String _formatTime(String time) {
    // Convert "0900" to "09:00"
    return '${time.substring(0, 2)}:${time.substring(2)}';
  }

  PlaceModel copyWith({
    double? rating,
    int? userRatingsTotal,
    bool? openNow,
    double? distanceFromUser,
    String? photoUrl,
    List<String>? mediaUrls,
    String? tips,
    String? extras,
    bool? isPremium,
    DateTime? mediaCachedAt,
    DateTime? mediaExpiresAt,
    DateTime? mediaLastValidatedAt,
    bool? mediaRefreshNeeded,
  }) {
    return PlaceModel(
      id: id,
      name: name,
      vicinity: vicinity,
      description: description,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      latitude: latitude,
      longitude: longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      openNow: openNow ?? this.openNow,
      types: types,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      phoneNumber: phoneNumber,
      openingHours: openingHours,
      priceRange: priceRange,
      city: city,
      state: state,
      isHiddenGem: isHiddenGem,
      tips: tips ?? this.tips,
      extras: extras ?? this.extras,
      isPremium: isPremium ?? this.isPremium,
      mediaCachedAt: mediaCachedAt ?? this.mediaCachedAt,
      mediaExpiresAt: mediaExpiresAt ?? this.mediaExpiresAt,
      mediaLastValidatedAt: mediaLastValidatedAt ?? this.mediaLastValidatedAt,
      mediaRefreshNeeded: mediaRefreshNeeded ?? this.mediaRefreshNeeded,
    );
  }
}

class PriceRange {
  final int minPrice;
  final int maxPrice;

  PriceRange({required this.minPrice, required this.maxPrice});

  factory PriceRange.fromPriceLevel(int minPrice, int maxPrice) {
    return PriceRange(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    };
  }

  factory PriceRange.fromMap(Map<String, dynamic> map) {
    return PriceRange(
      minPrice: map['minPrice'] ?? 0,
      maxPrice: map['maxPrice'] ?? 0,
    );
  }
}
