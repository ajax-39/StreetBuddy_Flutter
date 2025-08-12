import 'package:flutter/foundation.dart';
import 'package:street_buddy/services/image_url_service.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/models/location.dart';

/// Provider for managing image URL services and caching
class ImageUrlProvider extends ChangeNotifier {
  final ImageUrlService _imageUrlService = ImageUrlService();

  /// Get the image URL service instance
  ImageUrlService get service => _imageUrlService;

  /// Get valid image URL for a place
  Future<String> getValidPlaceImageUrl(PlaceModel place) async {
    try {
      final url = await _imageUrlService.getValidPlaceImageUrl(place);
      return url;
    } catch (e) {
      debugPrint('❌ Error getting valid place image URL: $e');
      return place.photoUrl ?? '';
    }
  }

  /// Get valid image URLs for a location
  Future<List<String>> getValidLocationImageUrls(LocationModel location) async {
    try {
      final urls = await _imageUrlService.getValidLocationImageUrls(location);
      return urls;
    } catch (e) {
      debugPrint('❌ Error getting valid location image URLs: $e');
      return location.imageUrls;
    }
  }

  /// Validate and refresh expired images in batch
  Future<void> validateAndRefreshExpiredImages() async {
    try {
      await _imageUrlService.validateAndRefreshExpiredImages();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error during batch image validation: $e');
    }
  }

  /// Clear validation cache
  void clearValidationCache() {
    _imageUrlService.clearValidationCache();
    notifyListeners();
  }
}
