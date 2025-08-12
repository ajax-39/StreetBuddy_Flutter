import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:street_buddy/services/image_url_service.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/full_screen_image_viewer.dart';

/// A smart image carousel widget that displays multiple images with auto-refresh capabilities
class SmartImageCarousel extends StatefulWidget {
  final PlaceModel? place;
  final LocationModel? location;
  final List<String>? imageUrls;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool showIndicators;
  final bool autoPlay;
  final bool showErrorDetails;
  final CarouselOptions? carouselOptions;

  // New properties
  final bool enableTapToView;
  final Duration autoPlayInterval;
  final bool showImageCount;
  final VoidCallback? onImageTap;

  const SmartImageCarousel({
    super.key,
    this.place,
    this.location,
    this.imageUrls,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.showIndicators = true,
    this.autoPlay = false,
    this.showErrorDetails = false,
    this.carouselOptions,
    this.enableTapToView = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.showImageCount = true,
    this.onImageTap,
  }) : assert(place != null || location != null || imageUrls != null,
            'Either place, location, or imageUrls must be provided');

  const SmartImageCarousel.fromPlace({
    super.key,
    required PlaceModel this.place,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.showIndicators = true,
    this.autoPlay = false,
    this.showErrorDetails = false,
    this.carouselOptions,
    this.enableTapToView = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.showImageCount = true,
    this.onImageTap,
  })  : location = null,
        imageUrls = null;

  const SmartImageCarousel.fromLocation({
    super.key,
    required LocationModel this.location,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.showIndicators = true,
    this.autoPlay = false,
    this.showErrorDetails = false,
    this.carouselOptions,
    this.enableTapToView = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.showImageCount = true,
    this.onImageTap,
  })  : place = null,
        imageUrls = null;

  const SmartImageCarousel.fromUrls({
    super.key,
    required List<String> this.imageUrls,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.showIndicators = true,
    this.autoPlay = false,
    this.showErrorDetails = false,
    this.carouselOptions,
    this.enableTapToView = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.showImageCount = true,
    this.onImageTap,
  })  : place = null,
        location = null;

  @override
  State<SmartImageCarousel> createState() => _SmartImageCarouselState();
}

class _SmartImageCarouselState extends State<SmartImageCarousel> {
  final ImageUrlService _imageUrlService = ImageUrlService();
  List<String> _currentImageUrls = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(SmartImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place != widget.place ||
        oldWidget.location != widget.location ||
        oldWidget.imageUrls != widget.imageUrls) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      List<String> imageUrls = [];

      if (widget.place != null) {
        // Load place media URLs
        final mediaUrls =
            await _imageUrlService.getValidPlaceMediaUrls(widget.place!);
        imageUrls =
            mediaUrls.isNotEmpty ? mediaUrls : [Constant.DEFAULT_PLACE_IMAGE];
      } else if (widget.location != null) {
        // Load location image URLs
        final urls =
            await _imageUrlService.getValidLocationImageUrls(widget.location!);
        imageUrls = urls.isNotEmpty ? urls : [Constant.DEFAULT_PLACE_IMAGE];
      } else if (widget.imageUrls != null) {
        // Direct URLs provided
        imageUrls = widget.imageUrls!.isNotEmpty
            ? widget.imageUrls!
            : [Constant.DEFAULT_PLACE_IMAGE];
      } else {
        imageUrls = [Constant.DEFAULT_PLACE_IMAGE];
      }

      if (mounted) {
        setState(() {
          _currentImageUrls = imageUrls;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading images: $e');
      if (mounted) {
        setState(() {
          _currentImageUrls = [Constant.DEFAULT_PLACE_IMAGE];
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: widget.height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: AppColors.error, size: 40),
          const SizedBox(height: 8),
          Text(
            'Failed to load images',
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
          if (widget.showErrorDetails && _errorMessage != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageItem(String imageUrl) {
    Widget imageWidget;

    // Use asset image for default images
    if (imageUrl == Constant.DEFAULT_PLACE_IMAGE) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.asset(
          Constant.DEFAULT_PLACE_IMAGE,
          width: double.infinity,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    } else {
      // Use CachedNetworkImage for network images
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: widget.height,
          fit: widget.fit,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) {
            debugPrint('🚫 Image error for URL: $url, Error: $error');
            _handleImageError(url);
            return _buildErrorWidget();
          },
        ),
      );
    }

    // Wrap with GestureDetector for tap-to-view functionality
    return GestureDetector(
      onTap: () {
        if (widget.enableTapToView) {
          _openFullScreenViewer(imageUrl);
        }
        // Call the optional onImageTap callback if provided
        widget.onImageTap?.call();
      },
      child: imageWidget,
    );
  }

  void _openFullScreenViewer(String tappedImageUrl) {
    // Call custom onImageTap if provided
    if (widget.onImageTap != null) {
      widget.onImageTap!();
      return;
    }

    // Only open full screen if enableTapToView is true
    if (!widget.enableTapToView) return;

    // Find the index of the tapped image
    final int initialIndex = _currentImageUrls.indexOf(tappedImageUrl);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: _currentImageUrls,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          placeName: widget.place?.name ?? widget.location?.name,
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    if (!widget.showIndicators || _currentImageUrls.length <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _currentImageUrls.length,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCount() {
    if (!widget.showImageCount || _currentImageUrls.length <= 1) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentIndex + 1}/${_currentImageUrls.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentImageUrls.isEmpty) {
      return _buildPlaceholder();
    }

    // Single image case
    if (_currentImageUrls.length == 1) {
      return Stack(
        children: [
          _buildImageItem(_currentImageUrls.first),
          _buildImageCount(),
        ],
      );
    }

    // Multiple images case - use carousel
    return Stack(
      children: [
        CarouselSlider(
          options: widget.carouselOptions ??
              CarouselOptions(
                height: widget.height,
                viewportFraction: 1.0,
                enableInfiniteScroll: _currentImageUrls.length > 1,
                autoPlay: widget.autoPlay,
                autoPlayInterval: widget.autoPlayInterval,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
          items: _currentImageUrls.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return _buildImageItem(imageUrl);
              },
            );
          }).toList(),
        ),
        _buildIndicators(),
        _buildImageCount(),
      ],
    );
  }

  /// Handle image loading errors, particularly for expired URLs
  void _handleImageError(String failedUrl) {
    debugPrint('🔄 Handling image error for URL: $failedUrl');

    // Trigger background refresh for expired URLs
    if (widget.place != null) {
      _imageUrlService.refreshPlaceMediaUrls(widget.place!.id).then((newUrls) {
        if (newUrls != null && newUrls.isNotEmpty && mounted) {
          setState(() {
            _currentImageUrls = newUrls;
          });
        }
      });
    } else if (widget.location != null) {
      _imageUrlService
          .refreshLocationImageUrls(widget.location!.id)
          .then((newUrls) {
        if (newUrls != null && newUrls.isNotEmpty && mounted) {
          setState(() {
            _currentImageUrls = newUrls;
          });
        }
      });
    }
  }
}
