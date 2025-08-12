import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:street_buddy/models/rating.dart';

class ReviewModel {
  final String id;
  final String placeId;
  final String userId;
  final List<PlaceEmoji>? emojis;
  final String? text;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likes;
  final List<String> reports;
  final int? rating;
  final String? safety;
  final String? cost;
  final List<String> mediaUrls;

  ReviewModel({
    required this.id,
    required this.placeId,
    required this.userId,
    this.emojis,
    this.text,
    required this.createdAt,
    this.updatedAt,
    List<String>? likes,
    List<String>? reports,
    this.rating,
    this.safety,
    this.cost,
    List<String>? mediaUrls,
  })  : likes = likes ?? [],
        reports = reports ?? [],
        mediaUrls = mediaUrls ?? [],
        assert(
            emojis?.isNotEmpty == true ||
                text != null ||
                rating != null ||
                safety != null ||
                cost != null ||
                (mediaUrls?.isNotEmpty ?? false),
            'Review must have either emojis, text, rating, safety, cost, or media');

  Map<String, dynamic> toMap() => {
        'place_id': placeId,
        'user_id': userId,
        'emojis': emojis?.map((e) => e.name).toList(),
        'text': text,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'likes': likes,
        'reports': reports,
        'rating': rating,
        'safety': safety,
        'cost': cost,
        'media_urls': mediaUrls,
      };

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      placeId: map['place_id'] ?? '',
      userId: map['user_id'] ?? '',
      emojis: (map['emojis'] as List<dynamic>?)
          ?.map((e) => PlaceEmoji.values.byName(e))
          .toList(),
      text: map['text'],
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'])
          : (map['created_at'] as Timestamp).toDate(),
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] is String
              ? DateTime.parse(map['updated_at'])
              : (map['updated_at'] as Timestamp).toDate())
          : null,
      likes: List<String>.from(map['likes'] ?? []),
      reports: List<String>.from(map['reports'] ?? []),
      rating: map['rating'] != null ? (map['rating'] as num).toInt() : null,
      safety: map['safety'],
      cost: map['cost'],
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
    );
  }
}
