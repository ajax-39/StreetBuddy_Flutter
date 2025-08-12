import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/MainScreen/Location/bookmark_provider.dart';
import 'package:street_buddy/screens/MainScreens/Locations/explore_places_detail_screen.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/url_util.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:street_buddy/widgets/transparent_appbar.dart';

class HiddenGemsScreen extends StatefulWidget {
  final LocationModel location;

  const HiddenGemsScreen({required this.location, super.key});

  @override
  State<HiddenGemsScreen> createState() => _HiddenGemsScreenState();
}

class _HiddenGemsScreenState extends State<HiddenGemsScreen> {
  List<PlaceModel> _hiddenGems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHiddenGems();
  }

// Add this new function to LocationService class
  Future<List<PlaceModel>> searchHiddenGemsFromCache(double lat, double lng,
      {double radiusInKm = 200}) async {
    try {
      debugPrint('Searching for hidden gems in cache...');
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Query places where isHiddenGem is true
      final querySnapshot = await firestore
          .collection('places')
          .where('isHiddenGem', isEqualTo: true)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} hidden gems in database');

      final List<PlaceModel> hiddenGems = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Calculate distance from user location
        final distance = Geolocator.distanceBetween(
          lat,
          lng,
          data['latitude'],
          data['longitude'],
        );

        // Only include places within radius
        if (distance <= (radiusInKm * 1000)) {
          debugPrint('Processing hidden gem: ${data['name']}');

          final place = PlaceModel.fromFirestore(data);
          hiddenGems.add(place);
        }
      }

      // Sort by distance
      hiddenGems.sort((a, b) => (a.distanceFromUser ?? double.infinity)
          .compareTo(b.distanceFromUser ?? double.infinity));

      debugPrint(
          'Returning ${hiddenGems.length} hidden gems within ${radiusInKm}km');
      return hiddenGems;
    } catch (e) {
      debugPrint('Error searching hidden gems: $e');
      return [];
    }
  }

  // Update _loadHiddenGems() in HiddenGemsScreen
  Future<void> _loadHiddenGems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('Starting to load hidden gems...');

      final gems = await searchHiddenGemsFromCache(
        widget.location.latitude,
        widget.location.longitude,
        radiusInKm: 200,
      );

      setState(() {
        _hiddenGems = gems;
        _isLoading = false;
      });

      debugPrint('Loaded ${_hiddenGems.length} hidden gems');
    } catch (e) {
      debugPrint('Error loading hidden gems: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Hidden Gems',
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const CustomLeadingButton()),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 41,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search hidden places & Gems...',
                    hintStyle: AppTypography.searchBar,
                    contentPadding: const EdgeInsets.only(left: 20),
                    suffixIcon: IconButton(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/icon/mic.png',
                        height: 16,
                        width: 16,
                      ),
                    ),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildTrendingSlider(),
            const SizedBox(height: 18),
            _buildFilterChips(),
            const SizedBox(height: 18),
            Container(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSlider() {
    int currentImageIndex = 0;
    var imglist = [
      Image.network('https://picsum.photos/400?random=1', fit: BoxFit.cover),
      Image.network('https://picsum.photos/400?random=2', fit: BoxFit.cover),
      Image.network('https://picsum.photos/400?random=3', fit: BoxFit.cover),
    ];
    return StatefulBuilder(builder: (context, setState) {
      return Stack(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 1,
                initialPage: 0,
                enableInfiniteScroll: true,
                reverse: false,
                disableCenter: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index, reason) {
                  setState(() {
                    currentImageIndex = index;
                  });
                },
              ),
              items: imglist,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: 20,
                  width: 70,
                  decoration: BoxDecoration(
                      color: const Color(0xff7BFF00),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      )),
                  child: const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child:
                            Text('Trending', style: TextStyle(fontSize: 10))),
                  ),
                ),
                const Text(
                  'Discover Hidden Treasures Near You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  'Explore unique local spots',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Explore Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: imglist.asMap().entries.map((entry) {
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentImageIndex == entry.key
                            ? AppColors.primary
                            : Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          )
        ],
      );
    });
  }

  Widget _buildFilterChips() {
    int selectedIndex = 0;
    List filters = [
      'All',
      'Cafes',
      'Street art',
      'Local Shops',
      'Historical Places'
    ];
    return StatefulBuilder(
      builder: (context, setState) {
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
                          setState(() {
                            selectedIndex = index;
                          });
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: AppTypography.body),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadHiddenGems,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_hiddenGems.isEmpty) {
      return const AspectRatio(
        aspectRatio: 4 / 3,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Oops!', style: AppTypography.headline),
              SizedBox(height: 16),
              Text('No hidden gems found in this area',
                  style: AppTypography.body),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _hiddenGems.length,
      itemBuilder: (context, index) {
        final place = _hiddenGems[index];
        // return Text(place.name);
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaceDetailsScreen(place: place),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    // UrlUtils.addApiKeyToPhotoUrl(
                    //     place.photoUrl, Constant.FOURSQUARE_API_KEY),
                    Constant.DEFAULT_PLACE_IMAGE,
                    height: 144,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  maxLines: 2,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Explore the most scenic rooftop cafés in Jaipur with breathtaking sunset views.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/icon/share.png',
                              width: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircleAvatar(),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "${place.city}, ${place.state}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.star_half_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '4.5',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
