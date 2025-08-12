// rating_model.dart
enum PlaceEmoji {
  awesome, // 😍 (10)
  great, // 😊 (8)
  good, // 🙂 (6)
  meh, // 😐 (4)
  bad, // 😕 (2)
  terrible, // 😡 (0)
  safe, // 🛡️
  unsafe, // ⚠️
  expensive, // 💰
  affordable // 💵
}

class RatingModel {
  final String id;
  final String placeId;
  final String userId;
  final PlaceEmoji emoji;
  final String? review;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.emoji,
    this.review,
    required this.createdAt,
  });

  double get numericRating {
    switch (emoji) {
      case PlaceEmoji.awesome:
        return 10;
      case PlaceEmoji.great:
        return 8;
      case PlaceEmoji.good:
        return 6;
      case PlaceEmoji.meh:
        return 4;
      case PlaceEmoji.bad:
        return 2;
      case PlaceEmoji.terrible:
        return 0;
      default:
        return 5; // Neutral for other emojis
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'placeId': placeId,
        'userId': userId,
        'emoji': emoji.name,
        'review': review,
        'createdAt': createdAt,
        'numericRating': numericRating,
      };
}
