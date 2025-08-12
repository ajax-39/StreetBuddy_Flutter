import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/search_provider.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/screens/MainScreens/Explore/search_page_screen.dart';
import 'package:street_buddy/screens/MainScreens/Locations/category_list_screen.dart';
import 'package:street_buddy/widgets/explore_cuisines.dart';
import 'package:street_buddy/widgets/explore_native_ad_widget.dart';

class ExplorePlacesScreen extends StatelessWidget {
  const ExplorePlacesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer2<SearchProvider, ExploreProvider>(
        builder: (context, searchProvider, exploreProvider, _) {
      // Initialize on first build
      if (!searchProvider.isInitialized) {
        searchProvider.initializeFeaturedCitiesSync();
      }

      // Initialize cities if not already done
      if (exploreProvider.cities.isEmpty && !exploreProvider.isLoadingCities) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          exploreProvider.initializeCities();
        });
      }

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom AppBar with city image and overlay
            Builder(builder: (context) {
              final city = exploreProvider.selectedLocation;
              final cityAsset = _getCityAsset(city);
              final screenHeight = MediaQuery.of(context).size.height;
              final headerHeight = screenHeight * 0.35; // 35% of screen height

              return Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: headerHeight,
                    child: Image.asset(
                      'assets/city_card/$cityAsset',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: headerHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 32,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Explore ${exploreProvider.selectedLocation?.name ?? 'City'}',
                              style: const TextStyle(
                                fontFamily: 'SFUI',
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Let ${exploreProvider.selectedLocation?.name ?? 'Mumbai'} Surprise You!',
                          style: TextStyle(
                            fontFamily: 'SFUI',
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width *
                                0.08, // Responsive font size
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            shadows: const [
                              Shadow(blurRadius: 8, color: Colors.black38)
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Taste. Shop. Discover.',
                          style: TextStyle(
                            fontFamily: 'SFUI',
                            color: Colors.white70,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            // Search bar (as per current implementation)
            _buildTopBar(context, searchProvider, exploreProvider),
            const SizedBox(height: 24),
            // New Explore Options Row (circular orange buttons)
            _buildExploreOptionsRow(context, exploreProvider),
            const SizedBox(height: 24),
            // Trending food places (unchanged)
            const ExploreFoodWidget(),
            // Native Ad Widget - shows below trending food places
            const ExploreNativeAdWidget(),
            // const SizedBox(height: AppSpacing.md),

            // const Padding(
            //   padding: EdgeInsets.only(left: 20),
            //   child: Text('Hidden Gems',
            //       style: TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.w400,
            //       )),
            // ),
            // const SizedBox(height: 5),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Card(
            //     elevation: 2,
            //     shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(5)),
            //     child: Padding(
            //       padding: const EdgeInsets.all(5),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Image.asset('assets/explore/hg-alt.png'),
            //           const SizedBox(height: 5),
            //           Text(
            //             'The most hidden places in {globalUser?.city ?? 'Your'} district',
            //             style: const TextStyle(
            //                 fontSize: 12, fontWeight: FontWeight.w600),
            //           ),
            //           const SizedBox(height: 10),
            //           Row(
            //             crossAxisAlignment: CrossAxisAlignment.center,
            //             children: [
            //               const Icon(
            //                 Icons.location_on,
            //                 size: 9,
            //               ),
            //               Expanded(
            //                 child: Text(
            //                   '{globalUser?.city ?? 'Mumbai'}, {globalUser?.state ?? 'Maharashtra'}',
            //                   maxLines: 1,
            //                   overflow: TextOverflow.ellipsis,
            //                   style: const TextStyle(
            //                     fontSize: 9,
            //                     fontWeight: FontWeight.w400,
            //                     color: AppColors.textSecondary,
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //           const Row(
            //             mainAxisAlignment: MainAxisAlignment.end,
            //             children: [
            //               Icon(
            //                 Icons.star_half_rounded,
            //                 size: 15,
            //                 color: AppColors.primary,
            //               ),
            //               SizedBox(width: 2),
            //               Text('4.5',
            //                   style: TextStyle(
            //                     fontSize: 10,
            //                     fontWeight: FontWeight.bold,
            //                   )),
            //             ],
            //           )
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: AppSpacing.lg),
          ],
        ),
      );
    });
  }

  Widget _buildTopBar(BuildContext context, SearchProvider searchProvider,
      ExploreProvider exploreProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final searchBarHeight = screenWidth * 0.12; // Responsive height

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Search Bar (now takes full width)
          Expanded(
            child: SizedBox(
              height: searchBarHeight,
              child: TextField(
                controller: searchProvider.searchController,
                onTap: () {
                  debugPrint('🔍 Search bar tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchPageScreen(),
                    ),
                  );
                },
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Explore in Mumbai...',
                  hintStyle: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color(0xff1E1E1E).withOpacity(0.4),
                    fontWeight: FontWeight.w400,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: searchBarHeight * 0.25,
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.03),
                    child: Icon(
                      Icons.mic_none_outlined,
                      color: Colors.grey.shade600,
                      size: screenWidth * 0.06,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color(0xffE0E0E0),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(searchBarHeight * 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color(0xffE0E0E0),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(searchBarHeight * 0.5),
                  ),
                ),
                onChanged: (value) {
                  if (value.length > 2) {
                    debugPrint('🔎 Search input: $value');
                    searchProvider.performSearch(value.toLowerCase(), context,
                        loadedCities: exploreProvider.cities);
                  }
                },
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreOptionsRow(
      BuildContext context, ExploreProvider exploreProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * 0.18; // Responsive button size

    final options = [
      {
        'label': 'Foods',
        'icon': Icons.restaurant_menu,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF6C00), Color(0xFFFFA600)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        'onTap': () => context.push('/explore/food'),
      },
      {
        'label': 'Shops',
        'icon': Icons.shopping_bag,
        'gradient': const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFD11A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        'onTap': () => context.push('/explore/shops'),
      },
      {
        'label': 'Places',
        'icon': Icons.place,
        'gradient': const LinearGradient(
          colors: [Color(0xFF0FA8A3), Color(0xFF50D0CC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        'onTap': () {
          if (exploreProvider.selectedLocation != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryListScreen(
                  location: exploreProvider.selectedLocation!,
                  category: 'tourist_attraction',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a city first')),
            );
          }
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: options.map((option) {
          return Expanded(
            child: GestureDetector(
              onTap: option['onTap'] as void Function(),
              child: Column(
                children: [
                  Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      gradient: option['gradient'] as LinearGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        option['icon'] as IconData,
                        color: Colors.white,
                        size: buttonSize * 0.4, // Icon size relative to button
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.025),
                  Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontFamily: 'SFUI',
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.042, // Responsive font size
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getCityAsset(LocationModel? city) {
    if (city == null) return 'default_city.jpg';
    const cityAssetMap = {
      'amritsar': 'amritsar.png',
      'bangalore': 'bangalore.png',
      'chandigarh': 'chandigarh.png',
      'chennai': 'chennai.png',
      'dehradun': 'dehradun.png',
      'delhi': 'delhi.png',
      'goa': 'goa.png',
      'hyderabad': 'hyderabad.png',
      'indore': 'indore.png',
      'jaipur': 'jaipur.png',
      'kolkata': 'kolkata.png',
      'lucknow': 'lucknow.png',
      'manali': 'manali.png',
      'mumbai': 'mumbai.png',
      'nagpur': 'nagpur.png',
      'nashik': 'nashik.png',
      'pune': 'pune.png',
      'shimla': 'shimla.png',
      'udaipur': 'udaipur.png',
    };
    final key = city.name.toLowerCase();
    if (cityAssetMap.containsKey(key)) return cityAssetMap[key]!;
    String normalizedKey =
        key.replaceAll(' ', '').replaceAll('-', '').replaceAll('_', '');
    for (final mapKey in cityAssetMap.keys) {
      String normalizedMapKey =
          mapKey.replaceAll(' ', '').replaceAll('-', '').replaceAll('_', '');
      if (normalizedKey == normalizedMapKey ||
          normalizedKey.contains(normalizedMapKey) ||
          normalizedMapKey.contains(normalizedKey)) {
        return cityAssetMap[mapKey]!;
      }
    }
    return '$key.png';
  }
}
