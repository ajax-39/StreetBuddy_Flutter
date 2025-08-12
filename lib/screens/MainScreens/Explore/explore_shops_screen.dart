import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/Location/bookmark_provider.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/services/voice_search_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:street_buddy/widgets/place_card.dart';
import 'package:street_buddy/widgets/smart_image_widget.dart';

class ExploreShopsScreen extends StatefulWidget {
  const ExploreShopsScreen({super.key});

  @override
  State<ExploreShopsScreen> createState() => _ExploreShopsScreenState();
}

class _ExploreShopsScreenState extends State<ExploreShopsScreen> {
  List<PlaceModel> _allPlaces = [];
  List<PlaceModel> _filteredPlaces = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _lastSelectedLocationName;

  // Voice search properties
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  bool _isVoiceSearching = false;
  bool _isListening = false;
  String _voiceSearchText = '';

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _voiceSearchService.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exploreProvider =
          Provider.of<ExploreProvider>(context, listen: false);
      final selectedLocation = exploreProvider.selectedLocation;

      List<PlaceModel> places = [];

      if (selectedLocation != null) {
        // Fetch places for the selected city using the 'city' column (case-insensitive) and types array
        final response = await supabase
            .from('explore_places')
            .select()
            .ilike('city', selectedLocation.name.trim())
            .contains('types', ['shopping_mall']);

        debugPrint(
            '🗂️ Places fetched from backend: count=${response.length}, names=${response.map((e) => e['name']).toList()}');
        places = response.map((e) => PlaceModel.fromJson(e)).toList();
        debugPrint(
            '🏪 Found ${places.length} shopping malls in ${selectedLocation.name}');
      } // Remove fallback to all places

      setState(() {
        _allPlaces = List<PlaceModel>.from(places)
          ..sort((a, b) =>
              (b.rating as num? ?? 0).compareTo(a.rating as num? ?? 0));
        _filteredPlaces = _allPlaces;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading places: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPlaces(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlaces = _allPlaces;
      } else {
        _filteredPlaces = _allPlaces
            .where((place) =>
                place.name.toLowerCase().contains(query.toLowerCase()) ||
                (place.vicinity?.toLowerCase().contains(query.toLowerCase()) ??
                    false))
            .toList();
      }
      _filteredPlaces.sort(
          (a, b) => (b.rating as num? ?? 0).compareTo(a.rating as num? ?? 0));
    });
  }

  Future<List<PlaceModel>> getTrendingCuisines() async {
    // This method is kept for compatibility but now returns filtered places
    return _filteredPlaces;
  }

  /// Start voice search
  Future<void> _startVoiceSearch() async {
    debugPrint('🎤 Starting voice search...');

    try {
      setState(() {
        _isVoiceSearching = true;
        _voiceSearchText = '';
      });

      // Initialize voice search service
      final initialized = await _voiceSearchService.initialize();
      if (!initialized) {
        debugPrint('❌ Voice search initialization failed');
        _stopVoiceSearch();
        return;
      }

      setState(() {
        _isListening = true;
      });

      await _voiceSearchService.startListening(
        onResult: (String result) {
          debugPrint('🎤 Voice search result: $result');
          setState(() {
            _voiceSearchText = result;
            _searchController.text = result;
          });
          _filterPlaces(result);
          _stopVoiceSearch();
        },
        onError: (String error) {
          debugPrint('❌ Voice search error: $error');
          _stopVoiceSearch();
        },
      );
    } catch (e) {
      debugPrint('❌ Error starting voice search: $e');
      _stopVoiceSearch();
    }
  }

  /// Stop voice search
  Future<void> _stopVoiceSearch() async {
    debugPrint('🎤 Stopping voice search...');
    await _voiceSearchService.stopListening();
    setState(() {
      _isVoiceSearching = false;
      _isListening = false;
      _voiceSearchText = '';
    });
  }

  /// Handle voice search functionality
  void _handleVoiceSearch() async {
    if (_isListening) {
      // If already listening, stop voice search
      await _stopVoiceSearch();
    } else {
      // Start voice search
      await _startVoiceSearch();
    }
  }

  /// Build mic icon with voice search states
  Widget _buildMicIcon() {
    if (_isListening) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        child: const Icon(
          Icons.mic,
          color: AppColors.primary,
          size: 20,
        ),
      );
    } else if (_isVoiceSearching) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    } else {
      return Image.asset(
        'assets/icon/mic.png',
        height: 16,
        width: 16,
        color: Colors.grey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomLeadingButton(),
        automaticallyImplyLeading: true,
        title: const Text('Explore Shops'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Consumer<ExploreProvider>(builder: (context, provider, _) {
          // Check if location changed and reload places
          final currentLocationName = provider.selectedLocation?.name;
          if (currentLocationName != _lastSelectedLocationName) {
            _lastSelectedLocationName = currentLocationName;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadPlaces();
            });
          }

          return Column(
            children: [
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildFilterChips(),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _buildFeaturedShopsContent(_filteredPlaces, context),
                const SizedBox(height: 16),
                // _buildPopularContent(_filteredPlaces, context), // Popular Choices commented out
              ],
              const SizedBox(height: 22),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 41,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search stores,items..',
            hintStyle: AppTypography.searchBar,
            contentPadding: const EdgeInsets.only(left: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterPlaces('');
                    },
                  )
                else
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: _buildMicIcon(),
                    onPressed: _handleVoiceSearch,
                  ),
              ],
            ),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50))),
          ),
          onChanged: (value) {
            _filterPlaces(value);
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedShopsContent(
      List<PlaceModel> places, BuildContext context) {
    places =
        places.where((place) => place.types.contains('shopping_mall')).toList();
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (places.isEmpty) {
      // Show error and (previously) top rated shops from other cities
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.store_mall_directory_outlined,
                  size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "We're adding shopping places for this city. Please explore other cities for now.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final isVIP =
        Provider.of<ProfileProvider>(context, listen: false).userData?.isVIP ??
            false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text('Featured Shops',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              )),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return PlaceCard(
              place: place,
              index: index,
              isVIP: isVIP,
              blurAfter: 1,
            );
          },
        ),
      ],
    );
  }

  Future<List<PlaceModel>> _fetchTopRatedShopsFromOtherCities() async {
    try {
      final response = await supabase.from('explore_places').select('*');
      final allPlaces = response
          .map<PlaceModel>((e) => PlaceModel.fromJson(e))
          .where((place) => place.types.contains('shopping_mall'))
          .toList();
      allPlaces.sort(
          (a, b) => (b.rating as num? ?? 0).compareTo(a.rating as num? ?? 0));
      return allPlaces.take(20).toList();
    } catch (e) {
      debugPrint('Error fetching top rated shops from other cities: $e');
      return [];
    }
  }

  Widget _buildShopCard(BuildContext context, PlaceModel place) {
    return Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            debugPrint('📍 Shop card tapped: ${place.name}');
            context.push('/locations/place', extra: place);
          },
          child: Hero(
            tag: 'place_${place.id}',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        SmartImageWidget.fromPlace(
                          place: place,
                          height: 145,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: const TextStyle(
                                  fontWeight: fontmedium,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (place.vicinity != null)
                                Text(
                                  place.vicinity!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: fontregular,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_half_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    place.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: GestureDetector(
                        //     onTap: () {
                        //       debugPrint('🔗 Share icon tapped for:  ${place.name}');
                        //     },
                        //     child: Image.asset(
                        //       'assets/icon/share.png',
                        //       width: 15,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  // Widget _buildPopularContent(List<PlaceModel> places, BuildContext context) {
  //   places =
  //       places.where((place) => place.types.contains('shop_item')).toList();
  //   // places.shuffle();
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Padding(
  //         padding: EdgeInsets.only(left: 20),
  //         child: Text('Popular Choices',
  //             style: TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.w400,
  //             )),
  //       ),
  //       const SizedBox(height: 10),
  //       GridView.builder(
  //         padding: const EdgeInsets.symmetric(horizontal: 20),
  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 2,
  //           childAspectRatio: 155 / 205,
  //           crossAxisSpacing: 10,
  //           mainAxisSpacing: 5,
  //         ),
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         itemCount: places.length,
  //         itemBuilder: (context, index) {
  //           return GestureDetector(
  //               onTap: () {
  //                 context.push('/locations/place', extra: places[index]);
  //               },
  //               child: shopCard(places[index]));
  //         },
  //       )
  //     ],
  //   );
  // }

  Widget shopCard(PlaceModel place) {
    bool isSaved = false;
    return SizedBox(
      width: 155,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          children: [
            Stack(
              children: [
                SmartImageWidget.fromPlace(
                  place: place,
                  height: 121,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: StatefulBuilder(builder: (context, setState) {
                    return IconButton(
                      color: isSaved ? Colors.red : Colors.white,
                      icon: const Icon(
                        CupertinoIcons.heart_fill,
                        size: 15,
                      ),
                      onPressed: () async {
                        setState(() {
                          isSaved = !isSaved;
                        });
                        await BookmarkProvider().toggleBookmark(place);
                        // print('done');
                      },
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 9,
                        ),
                        Expanded(
                          child: Text(
                            place.vicinity ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.star_half_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(place.rating.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    List filters = ['Top', 'Local markets', 'Hand made', 'Fashion'];
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        int selectedIndex = ShopFilter.values.indexOf(provider.shopFilter);
        return SizedBox(
          height: 50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 5),
                ListView.builder(
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: FilterChip(
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedIndex == index
                              ? Colors.white
                              : Colors.black,
                        ),
                        label: Text(filters[index]),
                        selected: selectedIndex == index,
                        onSelected: (bool selected) {
                          provider.setShopFilter(ShopFilter.values[index]);
                          _loadPlaces(); // Reload places when filter changes
                        },
                      ),
                    );
                  },
                  itemCount: filters.length,
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                ),
                const SizedBox(width: 15),
              ],
            ),
          ),
        );
      },
    );
  }
}
