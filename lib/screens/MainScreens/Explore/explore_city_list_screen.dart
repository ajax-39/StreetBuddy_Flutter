import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/services/voice_search_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:go_router/go_router.dart';

class ExploreCityListScreen extends StatefulWidget {
  final void Function(LocationModel)? onCitySelected;
  const ExploreCityListScreen({super.key, this.onCitySelected});

  @override
  State<ExploreCityListScreen> createState() => _ExploreCityListScreenState();
}

class _ExploreCityListScreenState extends State<ExploreCityListScreen> {
  List<LocationModel> _filteredCities = [];
  final TextEditingController _searchController = TextEditingController();

  // Voice search properties
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  bool _isVoiceSearching = false;
  bool _isListening = false;
  String _voiceSearchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Initialize cities after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExploreProvider>(context, listen: false);
      if (provider.cities.isEmpty && !provider.isLoadingCities) {
        provider.initializeCities().then((_) {
          if (mounted) {
            setState(() {
              _filteredCities = List.from(provider.cities);
            });
          }
        });
      } else {
        setState(() {
          _filteredCities = List.from(provider.cities);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _voiceSearchService.dispose();
    super.dispose(); 
  }

  void _onSearchChanged() {
    final provider = Provider.of<ExploreProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCities = provider.cities
          .where((city) => city.name.toLowerCase().contains(query))
          .toList();
    });
  }

  // Map city names to asset filenames
  static const Map<String, String> _cityAssetMap = {
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

  String _getCityAsset(LocationModel city) {
    final key = city.name.toLowerCase();
    debugPrint('🖼️ Looking for asset for city: "${city.name}" (key: "$key")');

    // Direct mapping first
    if (_cityAssetMap.containsKey(key)) {
      debugPrint('✅ Found direct mapping: ${_cityAssetMap[key]}');
      return _cityAssetMap[key]!;
    }

    // Try to handle variations and common spellings
    String normalizedKey = key
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .toLowerCase();

    // Check for partial matches or common variations
    for (String mapKey in _cityAssetMap.keys) {
      String normalizedMapKey = mapKey
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('_', '')
          .toLowerCase();

      if (normalizedKey == normalizedMapKey ||
          normalizedKey.contains(normalizedMapKey) ||
          normalizedMapKey.contains(normalizedKey)) {
        debugPrint(
            '✅ Found partial match: $mapKey -> ${_cityAssetMap[mapKey]}');
        return _cityAssetMap[mapKey]!;
      }
    }

    debugPrint('❌ No asset found for city: $key, using fallback: $key.png');
    return '$key.png';
  }

  /// Start voice search
  Future<void> _startVoiceSearch() async {
    setState(() {
      _isVoiceSearching = true;
      _voiceSearchText = '';
    });
    final initialized = await _voiceSearchService.initialize();
    if (!initialized) {
      _stopVoiceSearch();
      return;
    }
    setState(() {
      _isListening = true;
    });
    await _voiceSearchService.startListening(
      onResult: (String result) {
        setState(() {
          _voiceSearchText = result;
          _searchController.text = result;
        });
        _onSearchChanged();
        _stopVoiceSearch();
      },
      onError: (String error) {
        _stopVoiceSearch();
      },
    );
  }

  /// Stop voice search
  Future<void> _stopVoiceSearch() async {
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
      await _stopVoiceSearch();
    } else {
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
          size: 22,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search cities...',
            hintStyle: AppTypography.searchBar,
            contentPadding: const EdgeInsets.only(left: 16, right: 12),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.grey,
              size: 22,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged();
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
            _onSearchChanged();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(builder: (context, provider, _) {
      final isLoading = provider.isLoadingCities;
      List<LocationModel> cities =
          _filteredCities.isEmpty && _searchController.text.isEmpty
              ? provider.cities
              : _filteredCities;
      // Sort alphabetically by name
      cities = List<LocationModel>.from(cities)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 12),
            child: Text(
              'Select a City to Explore',
              style: TextStyle(
                fontFamily: 'SF UI Display',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
                height: 1.0, // 100% line height
                letterSpacing: 0.0, // 0% letter spacing
              ),
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (!isLoading)
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 150.62 / 105.53,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return GestureDetector(
                    onTap: () {
                      provider.setSelectedLocation(city);
                      // Navigate to ExplorePlacesScreen with bottom nav bar
                      Future.delayed(Duration.zero, () {
                        if (mounted) {
                          GoRouter.of(context).push('/explore/places');
                        }
                      });
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/city_card/${_getCityAsset(city)}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                  '❌ Failed to load image for ${city.name}: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      city.name,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 12,
                          child: Text(
                            city.name,
                            style: const TextStyle(
                              fontFamily: 'SF UI Display',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFFFFFF),
                              height: 1.0, // 100% line height
                              letterSpacing: 0.0, // 0% letter spacing
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}
