import 'package:street_buddy/constants.dart';

class UrlUtils {
  static String removeApiKeyFromPhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Constant.DEFAULT_PLACE_IMAGE;
    }
    if (_isAssetPath(photoUrl) || photoUrl == Constant.DEFAULT_PLACE_IMAGE) {
      return photoUrl;
    }
    return photoUrl.split('&key=')[0];
  }

  static String processLocationImageUrl(String url) {
    // For Foursquare URLs, return as is (don't add API key)
    if (url.startsWith('https://fastly.4sqi.net/') ||
        url.startsWith('https://ss3.4sqi.net/')) {
      return url;
    }

    // For Google Photos or other URLs, return as is
    return url;
  }

  static String addApiKeyToPhotoUrl(String? photoUrl, String apiKey) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Constant.DEFAULT_PLACE_IMAGE;
    }
    if (_isAssetPath(photoUrl) || photoUrl == Constant.DEFAULT_PLACE_IMAGE) {
      return photoUrl;
    }
    if (photoUrl.contains('&key=')) return photoUrl;
    return '$photoUrl&key=$apiKey';
  }

  static bool _isAssetPath(String path) {
    return path.startsWith('assets/') || path.startsWith('asset:');
  }

  static String validatePhotoUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Constant.DEFAULT_PLACE_IMAGE;
    }
    if (_isAssetPath(photoUrl) || photoUrl == Constant.DEFAULT_PLACE_IMAGE) {
      return photoUrl;
    }
    if (!photoUrl.startsWith('https://')) {
      return Constant.DEFAULT_PLACE_IMAGE;
    }
    return photoUrl;
  }
}
