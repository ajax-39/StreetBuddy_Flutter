import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/Explore/food_list_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/explore_place_card.dart';

class ExploreCuisinesWidget extends StatelessWidget {
  const ExploreCuisinesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // places =
    //     places.where((place) => place.types.contains('shopping_mall')).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text('Top Trending Cuisines',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              )),
        ),
        const SizedBox(height: 10),
        FutureBuilder(
            future: getTrendingCuisines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<PlaceModel> places = snapshot.data!;
              places.shuffle();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              context.push('/locations/place',
                                  extra: places[index]);
                            },
                            child: explorePlaceCard(places[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
      ],
    );
  }
}

class ExploreFoodWidget extends StatelessWidget {
  const ExploreFoodWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FoodListProvider(),
      child: Consumer2<ExploreProvider, FoodListProvider>(
        builder: (context, exploreProvider, foodProvider, _) {
          final currentCity = exploreProvider.selectedLocation?.name ?? "City";

          // Load food places when city changes or initial load
          if (foodProvider.currentCity != currentCity) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              foodProvider.loadFoodPlacesForCity(currentCity);
            });
          } else if (foodProvider.allFoodPlaces.isEmpty &&
              !foodProvider.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              foodProvider.loadFoodPlacesForCity(currentCity);
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  'Trending food places in $currentCity',
                  style: const TextStyle(
                    fontFamily: 'SF UI Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
                    height: 1.0, // 100% line height
                    letterSpacing: 0.0, // 0% letter spacing
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (foodProvider.isLoading)
                exploreCuisineShimmer()
              else
                _buildFoodPlacesList(foodProvider.filteredFoodPlaces, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFoodPlacesList(List<PlaceModel> places, BuildContext context) {
    // Limit to 5 places
    final displayPlaces = places.take(3).toList();
    final hasMorePlaces = places.length > 3;

    if (places.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: Text(
            'No food places found for this city',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 20),
          SizedBox(
            height: 250, // Increased from 217
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayPlaces.length + (hasMorePlaces ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == displayPlaces.length) {
                  // See All button - Circular
                  return Container(
                    width: 120, // Increased from 100
                    margin: const EdgeInsets.only(
                        right: 20), // Match gap from Figma
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.push('/explore/food');
                          },
                          child: Container(
                            width: 70, // Increased from 60
                            height: 70, // Increased from 60
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 24, // Increased from 20
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Increased from 8
                        const Text(
                          'See All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14, // Increased from 12
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  width: 370, // Increased from 340
                  height: 240, // Increased from 210
                  margin: const EdgeInsets.only(right: 20), // Gap from Figma
                  child: GestureDetector(
                    onTap: () {
                      context.push('/locations/place',
                          extra: displayPlaces[index]);
                    },
                    child: explorePlaceCard(displayPlaces[index]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class ExploreFoodWidget2 extends StatelessWidget {
  const ExploreFoodWidget2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text('Trending Places',
              style: TextStyle(
                fontSize: 16,
                fontWeight: fontregular,
              )),
        ),
        const SizedBox(height: 5),
        FutureBuilder(
            future: getTrendingCuisines(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return exploreCuisineShimmer();
              }

              List<PlaceModel> places = snapshot.data!;
              places = places
                  .where((place) => place.types.contains('restaurant'))
                  .toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              context.push('/locations/place',
                                  extra: places[index]);
                            },
                            child: explorePlaceCard(places[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
      ],
    );
  }
}

Widget exploreCuisineShimmer() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        const SizedBox(width: 20),
        Shimmer(
          gradient: AppColors.shimmerGradient,
          child: Container(
            height: 250, // Increased from 217 to match new card height
            width: 370, // Increased from 340 to match new card width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[300],
            ),
          ),
        ),
        const SizedBox(width: 20), // Match Figma gap
        Shimmer(
          gradient: AppColors.shimmerGradient,
          child: Container(
            height: 250, // Increased from 217 to match new card height
            width: 370, // Increased from 340 to match new card width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[300],
            ),
          ),
        ),
      ],
    ),
  );
}
