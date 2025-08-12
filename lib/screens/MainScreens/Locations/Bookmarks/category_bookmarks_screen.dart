import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/Location/bookmark_provider.dart';
import 'package:street_buddy/services/database_helper.dart';
import 'package:street_buddy/utils/connectivity_util.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/url_util.dart';

class CategoryBookmarksScreen extends StatelessWidget {
  final String category;
  final List<PlaceModel> places;

  const CategoryBookmarksScreen({
    required this.category,
    required this.places,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookmarkProvider(),
      child: Consumer<BookmarkProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                category.replaceAll('_', ' ').toUpperCase(),
                style: AppTypography.headline.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              backgroundColor: AppColors.primary,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
              child: FutureBuilder<List<PlaceModel>>(
                future: _getFilteredPlaces(provider),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(context);
                  }

                  final filteredPlaces = snapshot.data ?? [];

                  if (filteredPlaces.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    itemCount: filteredPlaces.length,
                    itemBuilder: (context, index) {
                      final place = filteredPlaces[index];
                      return _buildPlaceCard(context, place);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return FutureBuilder<String>(
      future: ConnectivityUtils.getCurrentConnectivity(),
      builder: (context, snapshot) {
        final hasInternet =
            snapshot.data != null && !snapshot.data!.contains('No Internet');

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasInternet ? Icons.bookmark_border : Icons.wifi_off,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hasInternet ? 'No bookmarked places' : 'No internet connection',
                style: AppTypography.subtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                hasInternet
                    ? 'Start exploring and save your favorite places'
                    : 'Connect to internet to see your bookmarks',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
              if (!hasInternet) ...[
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<List<PlaceModel>> _getFilteredPlaces(BookmarkProvider provider) async {
    // First check connectivity
    final connectivityStatus = await ConnectivityUtils.getCurrentConnectivity();
    final hasInternet = !connectivityStatus.contains('No Internet');

    try {
      final filteredPlaces = <PlaceModel>[];

      if (hasInternet) {
        // Online mode - check bookmarks status from Firebase
        for (final place in places) {
          final isStillBookmarked = await provider.isBookmarked(place.id);
          if (isStillBookmarked) {
            filteredPlaces.add(place);
          }
        }
      } else {
        // Offline mode - try loading from local cache
        final db = DatabaseHelper();
        for (final place in places) {
          final cachedPlace = await db.getPlace(place.id);
          if (cachedPlace != null) {
            filteredPlaces.add(cachedPlace);
          }
        }
      }

      return filteredPlaces;
    } catch (e) {
      debugPrint('Error getting filtered places: $e');
      return [];
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppSpacing.md),
          Text('Loading places...', style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          const Text('Something went wrong', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () {
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, PlaceModel place) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: InkWell(
        onTap: () {
          context.push('/locations/place', extra: place);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, AppColors.surfaceBackground],
            ),
          ),
          child: Column(
            children: [
              Hero(
                tag: 'place_${place.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.md),
                  ),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: _buildPlaceImage(place),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: AppTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (place.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.rating, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toString(),
                            style: AppTypography.body,
                          ),
                          if (place.userRatingsTotal > 0)
                            Text(
                              ' (${place.userRatingsTotal})',
                              style: AppTypography.caption,
                            ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    if (place.vicinity != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.vicinity!,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceImage(PlaceModel place) {
    if (place.photoUrl == null ||
        place.photoUrl == Constant.DEFAULT_PLACE_IMAGE) {
      return Image.asset(
        Constant.DEFAULT_PLACE_IMAGE,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return FutureBuilder<List<int>?>(
      future: DatabaseHelper().getCachedImage(place.photoUrl!),
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          return Image.memory(
            Uint8List.fromList(snapshot.data!),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading cached image: $error');
              return _buildDefaultImage();
            },
          );
        }

        return FutureBuilder<String>(
          future: ConnectivityUtils.getCurrentConnectivity(),
          builder: (context, connectivitySnapshot) {
            final hasInternet = connectivitySnapshot.data != null &&
                !connectivitySnapshot.data!.contains('No Internet');

            if (hasInternet) {
          

              return Image.network(
                place.photoUrl??Constant.DEFAULT_PLACE_IMAGE,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    _cacheLoadedImage(place.photoUrl!, place.photoUrl!);
                    return child;
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultImage(),
              );
            }

            return _buildDefaultImage();
          },
        );
      },
    );
  }

  Future<void> _cacheLoadedImage(String originalUrl, String fullUrl) async {
    try {
      final response = await Dio().get<List<int>>(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (response.data != null) {
        await DatabaseHelper().cacheImage(originalUrl, response.data!);
        debugPrint('✅ Successfully cached image: $originalUrl');
      }
    } catch (e) {
      debugPrint('❌ Error caching loaded image: $e');
    }
  }

  Widget _buildDefaultImage() {
    return Image.asset(
      Constant.DEFAULT_PLACE_IMAGE,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
