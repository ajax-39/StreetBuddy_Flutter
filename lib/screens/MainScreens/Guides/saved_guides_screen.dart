import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class SavedGuidesScreen extends StatelessWidget {
  const SavedGuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text.rich(TextSpan(text: 'Your ', children: [
            TextSpan(
              text: 'Favorite ',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(
              text: 'Spots',
            ),
          ])),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await context
                .read<GuideProvider>()
                .refreshSavedGuides(globalUser?.uid ?? '', '');
          },
          child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Consumer<GuideProvider>(builder: (context, guideProvider, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 41,
                        child: TextField(
                          controller: guideProvider.searchQueryController,
                          decoration: InputDecoration(
                            hintText: 'Search your saved guides',
                            contentPadding: EdgeInsets.zero,
                            hintStyle: AppTypography.searchBar,
                            prefixIconConstraints: const BoxConstraints(
                              maxHeight: 24,
                              maxWidth: 44,
                            ),
                            prefixIcon: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Image.asset(
                                'assets/icon/search.png',
                              ),
                            ),
                            border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50))),
                          ),
                          onSubmitted: (value) {
                            guideProvider.notify();
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildFilterChips(),
                  const SizedBox(height: 18),
                  _buildContent()
                ],
              )),
        ));
  }

  Widget _buildContent() {
    return Consumer<GuideProvider>(builder: (context, guideProvider, child) {
      return FutureBuilder(
          future: guideProvider.getUserSavedGuidesFuture(
              globalUser?.uid ?? '', guideProvider.searchQueryController.text),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Text('Error: ${snapshot.error}');
            }
            List<PostModel> guides = snapshot.data ?? [];

            if (guides.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    direction: Axis.vertical,
                    children: [
                      Icon(Icons.error_outline, size: 30),
                      SizedBox(height: 10),
                      Text('No Saved Guides!', style: AppTypography.cardTitle),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 30),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: guides.length,
              itemBuilder: (context, index) {
                return _buildSavedGuide(context, guides[index]);
              },
            );
          });
    });
  }

  Widget _buildFilterChips() {
    List filters = ['All', 'Recent', 'Popular', 'Near by', 'Historical Places'];
    List savedGuideFilters = SavedGuideFilter.values;
    return Consumer<GuideProvider>(
      builder: (context, guideProvider, _) {
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
                          color: guideProvider.selectedFilter ==
                                  savedGuideFilters[index]
                              ? Colors.white
                              : Colors.black,
                        ),
                        label: Text(filters[index]),
                        selected: guideProvider.selectedFilter ==
                            savedGuideFilters[index],
                        onSelected: (bool selected) {
                          guideProvider.setFilter(savedGuideFilters[index]);
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

  Widget _buildSavedGuide(BuildContext context, PostModel guide) {
    return GestureDetector(
      onTap: () {
        context.push('/guide?id=${guide.id}');
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
        elevation: 1,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius:
                      const BorderRadius.only(bottomLeft: Radius.circular(15)),
                ),
                // child: Image.asset(
                //   'assets/icon/map-loc.png',
                //   height: 26,
                //   width: 26,
                // ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12).copyWith(bottom: 7),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          guide.thumbnailUrl ?? Constant.DEFAULT_PLACE_IMAGE,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              guide.description.isNotEmpty
                                  ? guide.description
                                  : 'Tap to find out',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Image.asset('assets/icon/location-pin.png',
                                    height: 15, width: 15),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    guide.location,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: IconButton(
                            color: AppColors.primary,
                            style: IconButton.styleFrom(
                              shape: const OvalBorder(
                                  side: BorderSide(color: AppColors.primary)),
                            ),
                            onPressed: () async {
                              await PostProvider().toggleSaveGuideFromUsers(
                                  globalUser?.uid ?? '', guide.id);
                              await context
                                  .read<GuideProvider>()
                                  .refreshSavedGuides(
                                      globalUser?.uid ?? '', '');
                            },
                            icon: Image.asset('assets/icon/delete.png')),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: IconButton(
                            color: AppColors.primary,
                            style: IconButton.styleFrom(
                              shape: const OvalBorder(
                                  side: BorderSide(color: AppColors.primary)),
                            ),
                            onPressed: () {},
                            icon: Image.asset(
                              'assets/icon/share.png',
                              color: AppColors.primary,
                              height: 12,
                              width: 12,
                            )),
                      ),
                      const SizedBox(width: 10),
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
}
