import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { image, video, guide }

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String userProfileImage;
  final String title;
  final String description;
  final String location;
  final List<String> tags;
  final bool isPrivate;
  final List<String> mediaUrls;
  final String? thumbnailUrl;
  final PostType type;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final List<String> likedBy;
  final int dislikes;
  final List<String> dislikedBy;
  final double rating;
  final int reviews;
  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    required this.title,
    required this.description,
    required this.location,
    required this.tags,
    required this.mediaUrls,
    this.thumbnailUrl,
    required this.type,
    required this.createdAt,
    this.isPrivate = false,
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
    this.dislikes = 0,
    this.dislikedBy = const [],
    this.rating = 0.0,
    this.reviews = 0,
  });
  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    // Handle conversion from old format (single mediaUrl) to new format (mediaUrls list)
    List<String> getMediaUrls() {
      if (map['mediaUrls'] != null) {
        return List<String>.from(map['mediaUrls']);
      } else if (map['media_urls'] != null) {
        return List<String>.from(map['media_urls']);
      } else if (map['media_url'] != null || map['mediaUrl'] != null) {
        // Convert old single URL to a list with one item
        String url = map['media_url'] ?? map['mediaUrl'] ?? '';
        return url.isEmpty ? [] : [url];
      }
      return [];
    }

    return PostModel(
      id: id,
      userId: map['user_id'] ?? map['userId'] ?? '',
      username: map['username'] ?? '',
      userProfileImage:
          map['user_profile_image'] ?? map['userProfileImage'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      mediaUrls: getMediaUrls(),
      thumbnailUrl: map['thumbnail_url'] ?? map['thumbnailUrl'],
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] ?? 'image'),
        orElse: () => PostType.image,
      ),
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']),
      isPrivate: map['is_private'] ?? map['isPrivate'] ?? false,
      likes: (map['likes'] ?? 0).toInt(),
      comments: (map['comments'] ?? 0).toInt(),
      likedBy: List<String>.from(map['liked_by'] ?? map['likedBy'] ?? []),
      dislikes: (map['dislikes'] ?? 0).toInt(),
      dislikedBy:
          List<String>.from(map['disliked_by'] ?? map['dislikedBy'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviews: (map['reviews'] ?? 0).toInt(),
    );
  }

  PostModel copyWith({
    String? title,
    String? description,
    String? location,
    List<String>? tags,
    bool? isPrivate,
    int? likes,
    int? comments,
    List<String>? likedBy,
    int? dislike, // Kept as 'dislike' for parameter name compatibility
    List<String>? dislikedBy,
    String? thumbnailUrl,
    List<String>? mediaUrls,
    double? rating,
    int? reviews,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      username: username,
      userProfileImage: userProfileImage,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      type: type,
      createdAt: createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedBy: likedBy ?? this.likedBy,
      dislikes: dislike ?? this.dislikes,
      dislikedBy: dislikedBy ?? this.dislikedBy,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'user_profile_image': userProfileImage,
      'title': title,
      'description': description,
      'location': location,
      'tags': tags,
      'is_private': isPrivate,
      'media_urls': mediaUrls,
      'thumbnail_url': thumbnailUrl,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'liked_by': likedBy,
      'dislikes': dislikes,
      'disliked_by': dislikedBy,
      'rating': rating,
      'reviews': reviews,
    };
  }

  // Extract hashtags from description
  static List<String> extractTags(String description) {
    final RegExp hashtagRegExp = RegExp(r'#\w+');
    return hashtagRegExp
        .allMatches(description)
        .map((match) => match.group(0)!)
        .toList();
  }
}
