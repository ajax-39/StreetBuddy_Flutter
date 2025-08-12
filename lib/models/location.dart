class LocationModel {
  final String id;
  final String name;
  final String nameLowercase;
  final List<String> imageUrls;
  final String description;
  final double latitude;
  final double longitude;
  final double rating;
  final DateTime? cachedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? imageCachedAt;
  final DateTime? imageExpiresAt;
  final DateTime? imageLastValidatedAt;
  final bool imageRefreshNeeded;

  LocationModel({
    required this.id,
    required this.name,
    required this.nameLowercase,
    required this.imageUrls,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.rating = 0.0,
    this.cachedAt,
    this.createdAt,
    this.updatedAt,
    this.imageCachedAt,
    this.imageExpiresAt,
    this.imageLastValidatedAt,
    this.imageRefreshNeeded = false,
  });

  // Get primary image (first image or placeholder)
  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameLowercase: json['name_lowercase'] as String,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      cachedAt: json['cached_at'] != null
          ? DateTime.parse(json['cached_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      imageCachedAt: json['image_cached_at'] != null
          ? DateTime.parse(json['image_cached_at'] as String)
          : null,
      imageExpiresAt: json['image_expires_at'] != null
          ? DateTime.parse(json['image_expires_at'] as String)
          : null,
      imageLastValidatedAt: json['image_last_validated_at'] != null
          ? DateTime.parse(json['image_last_validated_at'] as String)
          : null,
      imageRefreshNeeded: json['image_refresh_needed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_lowercase': nameLowercase,
      'image_urls': imageUrls,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'cached_at': cachedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  LocationModel copyWith({
    String? id,
    String? name,
    String? nameLowercase,
    List<String>? imageUrls,
    String? description,
    double? latitude,
    double? longitude,
    double? rating,
    DateTime? cachedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLowercase: nameLowercase ?? this.nameLowercase,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      cachedAt: cachedAt ?? this.cachedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LocationModel{id: $id, name: $name, latitude: $latitude, longitude: $longitude, '
        'imageUrls: ${imageUrls.length} images, rating: $rating, '
        'description: ${description.length > 20 ? '${description.substring(0, 20)}...' : description}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
