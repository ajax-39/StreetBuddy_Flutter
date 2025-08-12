import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:street_buddy/services/image_url_service.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/utils/styles.dart';

/// A smart image widget that automatically handles expired Google Places image URLs
/// and refreshes them in the background using ImageUrlService
class SmartImageWidget extends StatefulWidget {
  final PlaceModel? place;
  final LocationModel? location;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showErrorDetails;

  const SmartImageWidget({
    super.key,
    this.place,
    this.location,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.showErrorDetails = false,
  }) : assert(place != null || location != null || imageUrl != null,
            'Either place, location, or imageUrl must be provided');

  const SmartImageWidget.fromPlace({
    super.key,
    required PlaceModel this.place,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.showErrorDetails = false,
  })  : location = null,
        imageUrl = null;

  const SmartImageWidget.fromLocation({
    super.key,
    required LocationModel this.location,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.showErrorDetails = false,
  })  : place = null,
        imageUrl = null;

  const SmartImageWidget.fromUrl({
    super.key,
    required String this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
    this.showErrorDetails = false,
  })  : place = null,
        location = null;

  @override
  State<SmartImageWidget> createState() => _SmartImageWidgetState();
}

class _SmartImageWidgetState extends State<SmartImageWidget> {
  final ImageUrlService _imageUrlService = ImageUrlService();
  String? _currentImageUrl;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(SmartImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place != widget.place ||
        oldWidget.location != widget.location ||
        oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      String imageUrl;

      if (widget.place != null) {
        // Load place media URLs (use primary image)
        final mediaUrls =
            await _imageUrlService.getValidPlaceMediaUrls(widget.place!);
        imageUrl = mediaUrls.isNotEmpty
            ? mediaUrls.first
            : Constant.DEFAULT_PLACE_IMAGE;
      } else if (widget.location != null) {
        // Load location image URLs (use primary image)
        final urls =
            await _imageUrlService.getValidLocationImageUrls(widget.location!);
        imageUrl = urls.isNotEmpty ? urls.first : Constant.DEFAULT_PLACE_IMAGE;
      } else if (widget.imageUrl != null) {
        // Direct URL provided
        imageUrl = widget.imageUrl!;
      } else {
        imageUrl = Constant.DEFAULT_PLACE_IMAGE;
      }

      if (mounted) {
        setState(() {
          _currentImageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading image: $e');
      if (mounted) {
        setState(() {
          _currentImageUrl = Constant.DEFAULT_PLACE_IMAGE;
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildShimmerContainer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1200), // Slightly faster shimmer
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: widget.borderRadius > 0
              ? BorderRadius.circular(widget.borderRadius)
              : null,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return _buildShimmerContainer();
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: AppColors.error, size: 40),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: AppTypography.caption.copyWith(
              color: AppColors.error,
            ),
          ),
          if (widget.showErrorDetails && _errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentImageUrl == null) {
      return _buildPlaceholder();
    }

    Widget imageWidget;

    // Use asset image for default images
    if (_currentImageUrl == Constant.DEFAULT_PLACE_IMAGE) {
      imageWidget = Image.asset(
        Constant.DEFAULT_PLACE_IMAGE,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    } else {
      // Use CachedNetworkImage for network images
      imageWidget = CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildShimmerContainer(),
        errorWidget: (context, url, error) {
          debugPrint('🚫 Image error for URL: $url, Error: $error');

          // If it's a 400 error (expired photo reference), try to refresh
          if (error.toString().contains('400') ||
              error.toString().contains('Failed host lookup')) {
            _handleImageError(url);
          }

          return _buildErrorWidget();
        },
      );
    }

    // Apply border radius if specified
    if (widget.borderRadius > 0) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Handle image loading errors, particularly for expired URLs
  void _handleImageError(String failedUrl) {
    debugPrint('🔄 Handling image error for URL: $failedUrl');

    // Trigger background refresh for expired URLs
    if (widget.place != null) {
      _imageUrlService.refreshPlaceMediaUrls(widget.place!.id).then((newUrls) {
        if (newUrls != null && newUrls.isNotEmpty && mounted) {
          setState(() {
            _currentImageUrl = newUrls.first;
          });
        }
      });
    } else if (widget.location != null) {
      _imageUrlService
          .refreshLocationImageUrls(widget.location!.id)
          .then((newUrls) {
        if (newUrls != null && newUrls.isNotEmpty && mounted) {
          setState(() {
            _currentImageUrl = newUrls.first;
          });
        }
      });
    }
  }
}

/// Extension methods for easy migration from existing Image widgets
extension SmartImageExtensions on Widget {
  /// Wrap an existing Image widget with smart refresh capabilities
  Widget wrapWithSmartRefresh({
    PlaceModel? place,
    LocationModel? location,
    String? imageUrl,
  }) {
    return SmartImageWidget(
      place: place,
      location: location,
      imageUrl: imageUrl,
    );
  }
}
