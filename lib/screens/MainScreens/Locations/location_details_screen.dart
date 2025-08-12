import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/screens/MainScreens/Locations/category_list_screen.dart';
import 'package:street_buddy/screens/MainScreens/Locations/hidden_gem_screen.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/smart_image_widget.dart';

class LocationDetailsScreen extends StatefulWidget {
  final LocationModel location;

  const LocationDetailsScreen({required this.location, super.key});

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  int _currentImageIndex = 0;

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error),
        ),
      );
    }
    return SmartImageWidget.fromUrl(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.location.name,
          style: AppTypography.headline.copyWith(
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CarouselSlider(
                  items: widget.location.imageUrls.isEmpty
                      ? [
                          SmartImageWidget.fromLocation(
                              location: widget.location)
                        ]
                      : widget.location.imageUrls
                          .map((url) => _buildImage(url))
                          .toList(),
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        widget.location.imageUrls.asMap().entries.map((entry) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(
                              _currentImageIndex == entry.key ? 0.9 : 0.4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      height: 56,
                      child: Stack(
                        children: [
                          // Shimmer background
                          Positioned.fill(
                            child: Shimmer.fromColors(
                              period: const Duration(seconds: 2),
                              baseColor: const Color(0xFF8E2DE2),
                              highlightColor:
                                  const Color(0xFF8E2DE2).withOpacity(0.8),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8E2DE2),
                                      Color(0xFF4A00E0)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8E2DE2)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Content layer
                          Positioned.fill(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HiddenGemsScreen(
                                        location: widget.location),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.diamond,
                                        color: Colors.white, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Discover Hidden Gems',
                                      style: AppTypography.headline.copyWith(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.location.rating > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.rating.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.rating, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            widget.location.rating.toString(),
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.rating,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.location.description,
                    style: AppTypography.body.copyWith(
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Explore',
                    style: AppTypography.headline.copyWith(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1,
                    children: [
                      _buildFeatureCard(context, 'Restaurants',
                          Icons.restaurant, 'restaurant'),
                      _buildFeatureCard(context, 'Attractions', Icons.explore,
                          'tourist_attraction'),
                      _buildFeatureCard(
                          context, 'Hotels', Icons.hotel, 'lodging'),
                      _buildFeatureCard(context, 'Shopping', Icons.shopping_bag,
                          'shopping_mall'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, String title, IconData icon, String type) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.md),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryListScreen(
              location: widget.location,
              category: type,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Explore →',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
