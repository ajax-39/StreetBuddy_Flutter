import 'package:flutter/foundation.dart';
import 'package:street_buddy/models/rating.dart';
import 'package:street_buddy/models/review.dart';
import 'package:street_buddy/services/review_service.dart';
import 'package:street_buddy/utils/review_sort.dart';

/// Provider for handling place details, reviews, ratings and associated metrics
///
/// This class manages the state and logic related to place reviews,
/// including sorting, rating calculations, and converting data
/// to user-friendly formats.
class PlaceDetailsProvider extends ChangeNotifier {
  /// Service for handling review-related API calls
  final ReviewService _reviewService = ReviewService();

  /// Current sorting method for reviews
  ReviewSort _currentSort = ReviewSort.mostRecent;

  /// Getter for the current sort method
  ReviewSort get currentSort => _currentSort;

  /// Updates the sort order for reviews
  ///
  /// @param newSort The new sort order to apply
  void updateSort(ReviewSort newSort) {
    _currentSort = newSort;
    notifyListeners();
  }

  /// Sorts reviews based on the currently selected sort method
  ///
  /// Creates a copy of the original list to avoid modifying the source list.
  ///
  /// @param reviews List of reviews to sort
  /// @return A new sorted list of reviews
  List<ReviewModel> sortReviews(List<ReviewModel> reviews) {
    switch (_currentSort) {
      case ReviewSort.mostRecent:
        return List.from(reviews)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReviewSort.oldest:
        return List.from(reviews)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ReviewSort.mostLiked:
        return List.from(reviews)
          ..sort((a, b) => b.likes.length.compareTo(a.likes.length));
      case ReviewSort.leastLiked:
        return List.from(reviews)
          ..sort((a, b) => a.likes.length.compareTo(b.likes.length));
    }
  }

  /// Calculates rating statistics from review data and updates the place's rating in the database
  ///
  /// Prioritizes numerical ratings if available, falls back to emoji-based ratings
  ///
  /// @param reviews List of reviews to analyze
  /// @param placeId The ID of the place for which to calculate ratings
  /// @return A map containing 'average' (0-5 scale) and 'percent' (0-100 scale) ratings
  Future<Map<String, double>> calculateRatingStats(
      List<ReviewModel> reviews, String placeId) async {
    // Return default values if no reviews available
    if (reviews.isEmpty) {
      await _reviewService.updatePlaceCustomRating(placeId, 0.0);
      return {'average': 0.0, 'percent': 0.0};
    }

    var total = 0.0;
    var count = 0;

    // First, prioritize numerical ratings from the rating field
    for (var review in reviews) {
      if (review.rating != null && review.rating! > 0) {
        total += review.rating!.toDouble();
        count++;
      }
    }

    // If no numerical ratings available, fall back to emoji-based ratings
    if (count == 0) {
      for (var review in reviews) {
        if (review.emojis != null) {
          for (var emoji in review.emojis!) {
            switch (emoji) {
              case PlaceEmoji.awesome:
                total += 5.0;
                count++;
                break;
              case PlaceEmoji.great:
                total += 4.0;
                count++;
                break;
              case PlaceEmoji.good:
                total += 3.0;
                count++;
                break;
              case PlaceEmoji.meh:
                total += 2.0;
                count++;
                break;
              case PlaceEmoji.bad:
                total += 1.0;
                count++;
                break;
              case PlaceEmoji.terrible:
                count++; // Zero points but still counts as a rating
                break;
              default:
                break; // Safety and cost emojis don't affect overall rating
            }
          }
        }
      }
    }

    final average = count > 0 ? total / count : 0.0;
    final percent = (average / 5.0) * 100;

    // Update the place's rating in the database
    await _reviewService.updatePlaceCustomRating(placeId, average);

    return {
      'average':
          double.parse(average.toStringAsFixed(1)), // Round to 1 decimal place
      'percent': percent
    };
  }

  /// Calculates the safety metric from review data
  ///
  /// Prioritizes safety field values, falls back to emoji-based safety ratings
  /// The metric is calculated as the ratio of safe ratings to total safety-related ratings.
  /// Returns a value between 0 (completely unsafe) and 1 (completely safe).
  ///
  /// @param reviews List of reviews to analyze
  /// @return A value between 0 and 1 representing safety
  double calculateSafetyMetric(List<ReviewModel> reviews) {
    int safeCount = 0;
    int unsafeCount = 0;

    // First, prioritize the safety field
    for (var review in reviews) {
      if (review.safety != null && review.safety!.isNotEmpty) {
        if (review.safety!.toLowerCase() == 'safe') safeCount++;
        if (review.safety!.toLowerCase() == 'unsafe') unsafeCount++;
      }
    }

    // If no safety field data, fall back to emojis
    if (safeCount + unsafeCount == 0) {
      for (var review in reviews) {
        if (review.emojis != null) {
          if (review.emojis!.contains(PlaceEmoji.safe)) safeCount++;
          if (review.emojis!.contains(PlaceEmoji.unsafe)) unsafeCount++;
        }
      }
    }

    // Return neutral value if no safety data is available
    if (safeCount + unsafeCount == 0) return 0.5;
    return safeCount / (safeCount + unsafeCount);
  }

  /// Calculates the affordability metric from review data
  ///
  /// Prioritizes cost field values, falls back to emoji-based cost ratings
  /// The metric is calculated as the ratio of affordable ratings to total cost-related ratings.
  /// Returns a value between 0 (completely expensive) and 1 (completely affordable).
  ///
  /// @param reviews List of reviews to analyze
  /// @return A value between 0 and 1 representing affordability
  double calculateCostMetric(List<ReviewModel> reviews) {
    int expensiveCount = 0;
    int affordableCount = 0;
    int moderateCount = 0;

    // First, prioritize the cost field
    for (var review in reviews) {
      if (review.cost != null && review.cost!.isNotEmpty) {
        switch (review.cost!.toLowerCase()) {
          case 'affordable':
            affordableCount++;
            break;
          case 'moderate':
            moderateCount++;
            break;
          case 'expensive':
            expensiveCount++;
            break;
        }
      }
    }

    // If no cost field data, fall back to emojis
    if (expensiveCount + affordableCount + moderateCount == 0) {
      for (var review in reviews) {
        if (review.emojis != null) {
          if (review.emojis!.contains(PlaceEmoji.expensive)) expensiveCount++;
          if (review.emojis!.contains(PlaceEmoji.affordable)) affordableCount++;
        }
      }
    }

    // Calculate affordability score: affordable = 1, moderate = 0.5, expensive = 0
    // Return neutral value if no cost data is available
    final totalCount = expensiveCount + affordableCount + moderateCount;
    if (totalCount == 0) return 0.5;

    return (affordableCount + (moderateCount * 0.5)) / totalCount;
  }

  /// Converts a numeric metric to a human-readable label
  ///
  /// @param value A metric value between 0 and 1
  /// @return A descriptive label (Very Low, Low, Moderate, High, Very High)
  String getMetricLabel(double value) {
    if (value < 0.2) return 'Very Low';
    if (value < 0.4) return 'Low';
    if (value < 0.6) return 'Moderate';
    if (value < 0.8) return 'High';
    return 'Very High';
  }

  /// Converts a PlaceEmoji enum to its corresponding emoji character
  ///
  /// @param emoji The PlaceEmoji enum value
  /// @return The string representation of the emoji
  String getEmojiString(PlaceEmoji emoji) {
    switch (emoji) {
      case PlaceEmoji.awesome:
        return '😍';
      case PlaceEmoji.great:
        return '😊';
      case PlaceEmoji.good:
        return '🙂';
      case PlaceEmoji.meh:
        return '😐';
      case PlaceEmoji.bad:
        return '😕';
      case PlaceEmoji.terrible:
        return '😡';
      case PlaceEmoji.safe:
        return '🛡️';
      case PlaceEmoji.unsafe:
        return '⚠️';
      case PlaceEmoji.expensive:
        return '💰';
      case PlaceEmoji.affordable:
        return '💵';
    }
  }

  /// Formats a DateTime object into a human-readable date string
  ///
  /// @param date The DateTime to format
  /// @return A string in the format "DD/MM/YYYY"
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
