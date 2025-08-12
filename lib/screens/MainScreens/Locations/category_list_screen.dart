import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/Location/category_list_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:street_buddy/widgets/premium_lock_overlay.dart';
import 'package:street_buddy/widgets/place_card.dart';

class ShimmerPlaceCard extends StatelessWidget {
  const ShimmerPlaceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppSpacing.md)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryListScreen extends StatelessWidget {
  final LocationModel location;
  final String category;

  const CategoryListScreen({
    required this.location,
    required this.category,
    super.key,
  });
  Widget _buildSearchBar(CategoryListProvider provider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 41,
        child: TextField(
          controller: provider.searchController,
          decoration: InputDecoration(
            hintText: 'Search places...',
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: fontregular,
              color: const Color(0xff1E1E1E).withOpacity(0.21),
            ),
            contentPadding: const EdgeInsets.only(left: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Voice search button
                if (provider.searchController.text.isEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: _buildMicIcon(provider),
                    onPressed: () => _handleVoiceSearch(provider, context),
                  ),
                // Clear button
                if (provider.searchController.text.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      provider.searchController.clear();
                      provider.filterPlaces('');
                    },
                  ),
              ],
            ),
            border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50))),
          ),
          onChanged: (value) {
            debugPrint('🔎 Search input: $value');
            provider.filterPlaces(value);
          },
        ),
      ),
    );
  }

  /// Handle voice search functionality
  void _handleVoiceSearch(
      CategoryListProvider provider, BuildContext context) async {
    if (provider.isListening) {
      // If already listening, stop voice search
      await provider.stopVoiceSearch();
    } else {
      // Start voice search
      await provider.startVoiceSearch(context);
    }
  }

  /// Build mic icon with voice search states
  Widget _buildMicIcon(CategoryListProvider provider) {
    if (provider.isListening) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        child: const Icon(
          Icons.mic,
          color: AppColors.primary,
          size: 20,
        ),
      );
    } else if (provider.isVoiceSearching) {
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

  Widget _buildContent(BuildContext context, CategoryListProvider provider) {
    if (provider.isLoading && provider.filteredPlaces.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show static message and top rated places from other cities if error is set (i.e., no custom places found)
    if (provider.error != null && provider.filteredPlaces.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    provider.error!,
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (provider.filteredPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No places found',
              style: AppTypography.body,
            ),
          ],
        ),
      );
    }
    final isVIP =
        Provider.of<ProfileProvider>(context, listen: false).userData?.isVIP ??
            false;
    return ListView.builder(
      controller: provider.scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount:
          provider.filteredPlaces.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.filteredPlaces.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final place = provider.filteredPlaces[index];
        return PlaceCard(
          place: place,
          index: index,
          isVIP: isVIP,
          blurAfter: 3,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryListProvider(
        location: location,
        category: category,
      ),
      child: Consumer<CategoryListProvider>(
        builder: (context, provider, _) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Explore ${location.name}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: fontregular,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.surfaceBackground,
            flexibleSpace: Container(
              color: AppColors.surfaceBackground,
            ),
            leading: const CustomLeadingButton(),
            elevation: 0,
            actions: const [
              // IconButton(
              //     onPressed: () {
              //       context.push('/locations/bookmarks');
              //     },
              //     icon: const Icon(Icons.bookmarks_outlined)),
              // IconButton(
              //     onPressed: () {
              //       context.push('/dev/local_db');
              //     },
              //     icon: const Icon(Icons.data_array)),
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(provider, context),
              _buildFilterChips(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.loadInitialPlaces,
                  child: _buildContent(context, provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    List filters = ['All', 'Trending', 'New', 'Popular'];
    return Consumer<CategoryListProvider>(
      builder: (context, provider, _) {
        int selectedIndex = PlaceFilter.values.indexOf(provider.currentFilter);
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
                          debugPrint(
                              '🏷 Filter chip tapped: ${filters[index]}');
                          provider.setFilter(PlaceFilter.values[index]);
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
