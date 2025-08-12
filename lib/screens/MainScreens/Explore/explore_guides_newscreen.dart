import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/services/screenshot_protection_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:street_buddy/widgets/guide_card_widget.dart';

class ExploreGuidesNewScreen extends StatefulWidget {
  const ExploreGuidesNewScreen({super.key});

  @override
  State<ExploreGuidesNewScreen> createState() => _ExploreGuidesNewScreenState();
}

class _ExploreGuidesNewScreenState extends State<ExploreGuidesNewScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Note: Screenshot protection is now handled by HomeScreen tab switching
    // Initialize cities when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exploreProvider =
          Provider.of<ExploreProvider>(context, listen: false);
      exploreProvider.initializeCities();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Ensure protection is disabled when widget is actually disposed
    ScreenshotProtectionService.disableProtection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Ensure screenshot protection is disabled when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ScreenshotProtectionService.forceDisableProtection();
    }
  }

  Future<List<PostModel>> getGuides(GuideFilter guideFilter) async {
    try {
      var response = await supabase.from('guides').select('*');

      if (guideFilter == GuideFilter.new_) {
        response = await supabase
            .from('guides')
            .select('*')
            .order('created_at', ascending: false);
      } else if (guideFilter == GuideFilter.trending) {
        response = await supabase
            .from('guides')
            .select('*')
            .order('likes', ascending: false);
      } else if (guideFilter == GuideFilter.popular) {
        response = await supabase
            .from('guides')
            .select('*')
            .order('rating', ascending: false);
      }

      return response.map((e) => PostModel.fromMap(e['id'], e)).toList();
    } catch (e) {
      debugPrint('Error in getUserSavedGuidesFuture: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomLeadingButton(),
        automaticallyImplyLeading: true,
        title: const Text(
          'Explore Guides',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<ExploreProvider>(
            builder: (context, provider, _) {
              final selectedLocation = provider.selectedLocation;
              final locationName = selectedLocation?.name ?? 'Mumbai';

              return GestureDetector(
                onTap: () {
                  context.push('/change-location');
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFFFE4B3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        locationName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Consumer<ExploreProvider>(builder: (context, provider, _) {
          return FutureBuilder(
              key: ValueKey(provider
                  .guidesRefreshTrigger), // Refresh when trigger changes
              future: getGuides(provider.guideFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final guides = snapshot.data ?? [];
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 20),
                    _buildGuidesContent(guides, context),
                    const SizedBox(height: 20),
                  ],
                );
              });
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Looking for a guide?...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w400,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: InputBorder.none,
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.mic,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    List<String> filters = ['All', 'Trending', 'New', 'Popular'];
    List<String> icons = [
      'assets/icon/profile-alt.png',
      'assets/icon/star-check.png',
      'assets/icon/location-pin.png',
      'assets/icon/star-check.png',
    ];
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        int selectedIndex = GuideFilter.values.indexOf(provider.guideFilter);
        return Container(
          height: 50,
          alignment: Alignment.centerLeft,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(filters.length, (index) {
                  final isSelected = selectedIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 20 : 0,
                      right: index < filters.length - 1 ? 12 : 20,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: FilterChip(
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        avatar: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Image.asset(
                            icons[index],
                            height: 15,
                            width: 15,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        label: Text(filters[index]),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) {
                            provider.setGuideFilter(GuideFilter.values[index]);
                          }
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidesContent(List<PostModel> guides, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      itemCount: guides.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            context.push('/guide?id=${guides[index].id}');
          },
          child: GuideCardWidget(
            guide: guides[index],
            onTap: () => context.push('/guide?id=${guides[index].id}'),
          ),
        );
      },
    );
  }
}
