class GuideModel {
  final String id;
  final String userId;
  final String postId;
  final String username;
  final String userProfileImage;
  final String place;
  final String placeName;
  final String experience;
  final List<dynamic> mediaUrls;
  final DateTime createdAt;
  final double? lat;
  final double? long;

  GuideModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.username,
    required this.userProfileImage,
    required this.place,
    required this.placeName,
    required this.experience,
    required this.mediaUrls,
    required this.createdAt,
    this.lat,
    this.long,
  });

  factory GuideModel.fromMap(String id, Map<String, dynamic> map) {
    return GuideModel(
      id: id,
      userId: map['user_id'] ?? map['userId'] ?? '',
      postId: map['post_id'] ?? map['postId'] ?? '',
      username: map['username'] ?? '',
      userProfileImage:
          map['user_profile_image'] ?? map['userProfileImage'] ?? '',
      place: map['place'] ?? '',
      placeName: map['place_name'] ?? map['placeName'] ?? '',
      experience: map['experience'] ?? '',
      mediaUrls: _parseMediaUrls(map),
      createdAt: _parseDateTime(map),
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      long: map['long'] != null ? (map['long'] as num).toDouble() : null,
    );
  }

  static List<dynamic> _parseMediaUrls(Map<String, dynamic> map) {
    if (map['media_urls'] != null) {
      if (map['media_urls'] is String) {
        return [map['media_urls']];
      } else if (map['media_urls'] is List) {
        return List<dynamic>.from(map['media_urls']);
      }
    } else if (map['mediaUrls'] != null) {
      if (map['mediaUrls'] is String) {
        return [map['mediaUrls']];
      } else if (map['mediaUrls'] is List) {
        return List<dynamic>.from(map['mediaUrls']);
      }
    }
    return [];
  }

  static DateTime _parseDateTime(Map<String, dynamic> map) {
    if (map['created_at'] != null) {
      return map['created_at'] is DateTime
          ? map['created_at']
          : DateTime.parse(map['created_at'].toString());
    } else if (map['createdAt'] != null) {
      return map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'].toString());
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'post_id': postId,
      'username': username,
      'user_profile_image': userProfileImage,
      'place': place,
      'place_name': placeName,
      'experience': experience,
      'media_urls': mediaUrls,
      'created_at': createdAt.toIso8601String(),
      'lat': lat,
      'long': long,
    };
  }

  GuideModel copyWith({
    String? place,
    String? placeName,
    String? experience,
    List<dynamic>? mediaUrls,
    double? lat,
    double? long,
  }) {
    return GuideModel(
      id: id,
      userId: userId,
      postId: postId,
      username: username,
      userProfileImage: userProfileImage,
      place: place ?? this.place,
      placeName: placeName ?? this.placeName,
      experience: experience ?? this.experience,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt,
      lat: lat ?? this.lat,
      long: long ?? this.long,
    );
  }
}
