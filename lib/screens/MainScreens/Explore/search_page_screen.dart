import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/search_provider.dart';
import 'package:street_buddy/screens/MainScreens/Locations/explore_places_detail_screen.dart';
import 'package:street_buddy/utils/styles.dart';

class SearchPageScreen extends StatefulWidget {
  final bool startVoiceSearch;

  const SearchPageScreen({super.key, this.startVoiceSearch = false});

  @override
  State<SearchPageScreen> createState() => _SearchPageScreenState();
}

class _SearchPageScreenState extends State<SearchPageScreen> {
  @override
  void initState() {
    super.initState();

    // Start voice search if requested
    if (widget.startVoiceSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final searchProvider =
            Provider.of<SearchProvider>(context, listen: false);
        _handleVoiceSearch(searchProvider, context);
      });
    }
  }

  Widget _buildSearchResults(
      SearchProvider searchProvider, BuildContext context) {
    final query = searchProvider.searchController.text.trim();
    final hasResults = searchProvider.userResults.isNotEmpty ||
        searchProvider.locationResults.isNotEmpty ||
        searchProvider.placeResults.isNotEmpty;

    // Always show the custom query tile at the top if query is not empty
    List<Widget> children = [];
    if (query.isNotEmpty) {
      if (searchProvider.isCustomQueryLoading) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      } else if (searchProvider.showNoResultFound) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No results found',
                style: AppTypography.body,
              ),
            ),
          ),
        );
      } else {
        children.add(
          InkWell(
            onTap: () async {
              FocusScope.of(context).unfocus();
              await searchProvider.handleCustomQueryTap(context, query);
            },
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xffECECEC),
                    width: 1,
                  ),
                ),
                color: Color(0xFFF5F5F5),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icon/search.png',
                      width: 25,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: fontregular,
                          color: Color(0xff212121),
                        ),
                      ),
                    ),
                    // No add icon anymore
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    // Add results below the custom tile
    if (searchProvider.locationResults.isNotEmpty) {
      children.addAll(searchProvider.locationResults
          .map((location) => _buildLocationResult(location, context)));
    }
    if (searchProvider.placeResults.isNotEmpty) {
      children.addAll(searchProvider.placeResults
          .map((place) => _buildPlaceResult(place, context)));
    }
    // If no results and not loading or noResultFound, show nothing (custom tile already covers the case)
    if (!hasResults &&
        !searchProvider.isCustomQueryLoading &&
        !searchProvider.showNoResultFound) {
      // Optionally, you can add a SizedBox for spacing
      // children.add(const SizedBox(height: 24));
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _buildPlaceResult(PlaceModel place, BuildContext context) {
    return InkWell(
      onTap: () async {
        final prefs = Hive.box('prefs');
        final searchProvider =
            Provider.of<SearchProvider>(context, listen: false);
        final isHistoryEnabled = prefs.get('history') != false;

        if (isHistoryEnabled) {
          final box = Hive.box('search_history');
          box.add({
            'query': place.name,
            'time': DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch,
            ),
          });
        }

        // Log search query to Supabase
        await searchProvider.logSearchQuery(
          queryText: searchProvider.searchController.text,
          resultType: 'place',
          resultName: place.name,
          historyEnabled: isHistoryEnabled,
        );

        searchProvider.clearSearch();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailsScreen(place: place),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xffECECEC),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Image.asset(
                'assets/icon/search.png',
                width: 25,
                color: Colors.black.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${place.name}, ${place.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: fontregular,
                    color: Color(0xff212121),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
    // return ListTile(
    //   leading: CircleAvatar(
    //     radius: 24,
    //     backgroundColor: Colors.grey[200],
    //     backgroundImage: place.photoUrl != null
    //         ? CachedNetworkImageProvider(place.photoUrl!)
    //         : null,
    //     child: place.photoUrl == null
    //         ? const Icon(Icons.place, color: Colors.grey)
    //         : null,
    //   ),
    //   title: Text(
    //     place.name,
    //     style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
    //   ),
    //   subtitle: Text(
    //     place.vicinity ?? '',
    //     style: AppTypography.caption,
    //     maxLines: 1,
    //     overflow: TextOverflow.ellipsis,
    //   ),
    //   trailing: Column(
    //     children: [
    //       Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Icon(Icons.star, color: Colors.amber[700], size: 16),
    //           const SizedBox(width: 4),
    //           Text(
    //             place.rating.toString(),
    //             style: AppTypography.caption,
    //           ),
    //         ],
    //       ),
    //       Text(
    //         place.distanceFromUser != null
    //             ? '${(place.distanceFromUser! / 1000).toStringAsFixed(1)} km away'
    //             : '',
    //         style: AppTypography.caption,
    //       ),
    //     ],
    //   ),
    //   onTap: () {
    //     final prefs = Hive.box('prefs');
    //     if (prefs.get('history') != false) {
    //       final box = Hive.box('search_history');
    //       box.add({
    //         'query': place.name,
    //         'time': DateTime.fromMillisecondsSinceEpoch(
    //           DateTime.now().millisecondsSinceEpoch,
    //         ),
    //       });
    //     }
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => PlaceDetailsScreen(place: place),
    //       ),
    //     );
    //   },
    // );
  }

  Widget _buildLocationResult(LocationModel location, BuildContext context) {
    return InkWell(
      onTap: () async {
        final prefs = Hive.box('prefs');
        final searchProvider =
            Provider.of<SearchProvider>(context, listen: false);
        final isHistoryEnabled = prefs.get('history') != false;

        if (isHistoryEnabled) {
          final box = Hive.box('search_history');
          box.add({
            'query': location.name,
            'time': DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch,
            ),
          });
        }

        // Log search query to Supabase
        await searchProvider.logSearchQuery(
          queryText: searchProvider.searchController.text,
          resultType: 'location',
          resultName: location.name,
          historyEnabled: isHistoryEnabled,
        );

        // Update the selected location in ExploreProvider (for dropdown)
        Provider.of<ExploreProvider>(context, listen: false)
            .setSelectedLocation(location);

        // Set city name in search bar
        searchProvider.setCityInSearchBar(location.name);

        Navigator.pop(context);
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xffECECEC),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Image.asset(
                'assets/icon/search.png',
                width: 25,
                color: Colors.black.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Text(
                location.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: fontregular,
                  color: Color(0xff212121),
                ),
              )
            ],
          ),
        ),
      ),
    );
    // return ListTile(
    //   leading: CircleAvatar(
    //     radius: 24,
    //     backgroundImage: CachedNetworkImageProvider(location.primaryImageUrl),
    //   ),
    //   title: Text(
    //     location.name,
    //     style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
    //   ),
    //   subtitle: Text(
    //     location.description,
    //     style: AppTypography.caption,
    //     maxLines: 1,
    //     overflow: TextOverflow.ellipsis,
    //   ),
    //   onTap: () {
    //     final prefs = Hive.box('prefs');
    //     if (prefs.get('history') != false) {
    //       final box = Hive.box('search_history');
    //       box.add({
    //         'query': location.name,
    //         'time': DateTime.fromMillisecondsSinceEpoch(
    //           DateTime.now().millisecondsSinceEpoch,
    //         ),
    //       });
    //     }
    //     Provider.of<ExploreProvider>(context, listen: false)
    //         .setLocation(location);
    //     // Navigator.push(
    //     //   context,
    //     //   MaterialPageRoute(
    //     //     builder: (context) => LocationDetailsScreen(location: location),
    //     //   ),
    //     // );
    //   },
    // );
  }

  Widget _buildHistoryResult(BuildContext context) {
    List localResults = [
      'Hotel',
      'Italian',
      'Mumbai',
      'Cafe',
      'Restaurant',
    ];
    final box = Hive.box('search_history');
    List searchHistory = [];
    Future<void> getSearchHistory() async {
      try {
        searchHistory = box.values.toList();
        if (searchHistory.length > 5) {
          searchHistory.removeRange(4, searchHistory.length);
        }
        if (searchHistory.length < 5) {
          localResults = localResults.sublist(0, 5 - searchHistory.length);
        }
      } catch (e) {
        debugPrint('Error fetching search history: $e');
      }
    }

    getSearchHistory();
    return Column(
      children: [
        ...searchHistory.map((history) {
          return InkWell(
            onTap: () async {
              final searchProvider =
                  Provider.of<SearchProvider>(context, listen: false);
              final prefs = Hive.box('prefs');
              final isHistoryEnabled = prefs.get('history') != false;

              searchProvider.setCityInSearchBar(history['query']);
              await searchProvider.performSearch(history['query'], context);

              // Log the search query when user clicks on history item
              await searchProvider.logSearchQuery(
                queryText: history['query'],
                resultType: 'history_search',
                resultName: history['query'],
                historyEnabled: isHistoryEnabled,
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xffECECEC),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 25,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      history['query'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: fontregular,
                        color: Color(0xff212121),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }),
        ...localResults.map((e) {
          return InkWell(
            onTap: () async {
              final searchProvider =
                  Provider.of<SearchProvider>(context, listen: false);
              final prefs = Hive.box('prefs');
              final isHistoryEnabled = prefs.get('history') != false;

              searchProvider.setCityInSearchBar(e);
              await searchProvider.performSearch(e, context);

              // Log the search query when user clicks on suggested search
              await searchProvider.logSearchQuery(
                queryText: e,
                resultType: 'suggested_search',
                resultName: e,
                historyEnabled: isHistoryEnabled,
              );
            },
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xffECECEC),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/icon/search.png',
                      width: 25,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      e,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: fontregular,
                        color: Color(0xff212121),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Handle voice search functionality
  void _handleVoiceSearch(
      SearchProvider searchProvider, BuildContext context) async {
    if (searchProvider.isListening) {
      // If already listening, stop voice search
      await searchProvider.stopVoiceSearch();
    } else {
      // Start voice search
      await searchProvider.startVoiceSearch(context);
    }
  }

  /// Build mic icon with voice search states
  Widget _buildMicIcon(SearchProvider searchProvider) {
    if (searchProvider.isListening) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        child: const Icon(
          Icons.mic,
          color: AppColors.primary,
          size: 20,
        ),
      );
    } else if (searchProvider.isVoiceSearching) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    } else {
      return const Icon(
        Icons.mic_none,
        color: Colors.grey,
        size: 20,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SearchProvider, ExploreProvider>(
        builder: (context, searchProvider, exploreProvider, _) {
      // Initialize on first build
      if (!searchProvider.isInitialized) {
        searchProvider.initializeFeaturedCitiesSync();
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Search page',
            style: TextStyle(
              fontSize: 18,
              fontWeight: fontregular,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: searchProvider.searchController,
                    decoration: InputDecoration(
                      hintText: 'Search places, cities, guides...',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: const Color(0xff1E1E1E).withOpacity(0.5),
                        fontWeight: fontregular,
                      ),
                      contentPadding: const EdgeInsets.only(left: 20),
                      prefixIconConstraints: const BoxConstraints(
                        maxHeight: 20,
                        maxWidth: 40,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset(
                          'assets/icon/search.png',
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Voice search button
                          if (searchProvider.searchController.text.isEmpty)
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: _buildMicIcon(searchProvider),
                              onPressed: () =>
                                  _handleVoiceSearch(searchProvider, context),
                            ),
                          // Clear button
                          if (searchProvider.searchController.text.isNotEmpty)
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.clear),
                              onPressed: () => searchProvider.clearSearch(),
                            ),
                        ],
                      ),
                      enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffD9D9D9)),
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                      focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffD9D9D9)),
                          borderRadius: BorderRadius.all(Radius.circular(50))),
                    ),
                    onChanged: (value) {
                      if (value.length > 2) {
                        // Pass the loaded cities to search only from those
                        searchProvider.performSearch(
                            value.toLowerCase(), context,
                            loadedCities: exploreProvider.cities);
                      }
                    },
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ),
              ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (searchProvider.isSearching) ...[
                        const AspectRatio(
                            aspectRatio: 3,
                            child: Center(child: CircularProgressIndicator()))
                      ] else if (searchProvider
                          .searchController.text.isNotEmpty) ...[
                        _buildSearchResults(searchProvider, context)
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            'Recent Searches',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: fontmedium,
                              color: Color(0xff212121),
                            ),
                          ),
                        ),
                        _buildHistoryResult(context),
                      ],
                    ],
                  )),
              const AspectRatio(aspectRatio: 3)
            ],
          ),
        )),
      );
    });
  }
}
