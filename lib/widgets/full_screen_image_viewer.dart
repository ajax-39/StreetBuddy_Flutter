import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:street_buddy/constants.dart';

/// Full-screen image viewer with carousel support
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? placeName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.placeName,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late int _currentIndex;
  late CarouselSliderController _carouselController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _carouselController = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: widget.placeName != null
            ? Text(
                widget.placeName!,
                style: const TextStyle(color: Colors.white),
              )
            : null,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main carousel
          Center(
            child: CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                enableInfiniteScroll: widget.imageUrls.length > 1,
                initialPage: widget.initialIndex,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: widget.imageUrls.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return InteractiveViewer(
                      maxScale: 3.0,
                      child: _buildFullScreenImage(imageUrl),
                    );
                  },
                );
              }).toList(),
            ),
          ),

          // Bottom indicators and navigation
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Image counter
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_currentIndex + 1} of ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.imageUrls.length,
                      (index) => GestureDetector(
                        onTap: () => _carouselController.animateToPage(index),
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullScreenImage(String imageUrl) {
    if (imageUrl == Constant.DEFAULT_PLACE_IMAGE) {
      return Image.asset(
        Constant.DEFAULT_PLACE_IMAGE,
        fit: BoxFit.contain,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(
          Icons.error,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }
}
