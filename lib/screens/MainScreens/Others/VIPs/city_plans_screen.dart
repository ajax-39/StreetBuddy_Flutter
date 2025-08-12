import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/services/voice_search_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:go_router/go_router.dart';
import 'all_city_access_tab.dart';

class CityPlansScreen extends StatefulWidget {
  const CityPlansScreen({super.key});

  @override
  State<CityPlansScreen> createState() => _CityPlansScreenState();
}

class _CityPlansScreenState extends State<CityPlansScreen> {
  Widget _buildCityPlansTab() {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoadingCities;
        final cities =
            _searchController.text.isEmpty ? provider.cities : _filteredCities;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildSelectedCitiesUI(),
                const SizedBox(height: 16),
                _buildAllCityAccessCard(),
                const SizedBox(height: 20), // Add some bottom padding
              ],
            ),
            if (_showDropdown && !isLoading)
              Positioned(
                left: 0,
                right: 0,
                top: 60,
                child: _buildCityDropdown(cities),
              ),
            if (isLoading) const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  bool _isVoiceSearching = false;
  bool _isListening = false;
  bool _showDropdown = false;
  List<LocationModel> _filteredCities = [];

  // List to store cities added by the user from the dropdown
  final List<LocationModel> _addedCities = []; // New list to track added cities

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExploreProvider>(context, listen: false);
    if (provider.cities.isEmpty && !provider.isLoadingCities) {
      provider.initializeCities().then((_) {
        setState(() {
          _filteredCities = List.from(provider.cities);
        });
      });
    } else {
      _filteredCities = List.from(provider.cities);
    }
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _showDropdown = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _voiceSearchService.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 0),
      child: SizedBox(
        height: 44.31,
        child: Row(
          children: [
            // City Plans Tab
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 157.85,
                height: 44.31,
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFFED7014)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    'City Plans',
                    style: TextStyle(
                      color: _selectedTab == 0 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      fontFamily: 'SFUI',
                    ),
                  ),
                ),
              ),
            ),
            // All City Access Tab
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 157.85,
                height: 44.31,
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFFED7014)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  // No border or shadow for non-selected tab
                ),
                child: Center(
                  child: Text(
                    'All City Access',
                    style: TextStyle(
                      color: _selectedTab == 1 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      fontFamily: 'SFUI',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  /// Start voice search
  Future<void> _startVoiceSearch() async {
    setState(() {
      _isVoiceSearching = true;
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

  double _getSearchBarWidth(BuildContext context) {
    // The search bar has horizontal: 20 padding, so width = screen - 40
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth - 40;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 41,
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search cities...',
            hintStyle: AppTypography.searchBar,
            contentPadding: const EdgeInsets.only(left: 20, right: 12),
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
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
          onTap: () {
            setState(() {
              _showDropdown = true;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCityDropdown(List<LocationModel> cities) {
    // Always show a box that fits 3 cities, scrollable if more
    final visibleCount = cities.length < 3 ? cities.length : 3;
    const itemHeight = 56.0; // Approximate height per city row
    final boxHeight = itemHeight * (visibleCount > 0 ? visibleCount : 1);
    final width = _getSearchBarWidth(context);
    return GestureDetector(
      onTap: () {}, // Prevent tap events from propagating to the screen
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          width: width,
          height: boxHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: cities.length,
            separatorBuilder: (context, idx) => const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFFEAEAEA),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, idx) {
              return _buildCityDropdownTile(cities[idx]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdownTile(LocationModel city) {
    final isUnlocked = _addedCities
        .any((c) => c.id == city.id); // Check if city is in the added list
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Use the city_plans image for all cities
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/city_plans/delhi.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.location_city,
                  color: Colors.orange,
                  size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              city.name,
              style: const TextStyle(
                fontSize: 14, // Updated font size for city name
                fontWeight: FontWeight.w500,
                color: Colors.black,
                fontFamily: 'SFUI',
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isUnlocked) {
                  _addedCities.removeWhere(
                      (c) => c.id == city.id); // Remove city if already added
                } else {
                  _addedCities.add(city); // Add city if not already added
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent, // No background shade
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isUnlocked ? 'Unlocked' : '+ Unlock City',
                style: TextStyle(
                  fontSize: 12, // Updated font size for button text
                  color: isUnlocked
                      ? const Color(0xFF16A34A) // Color for unlocked
                      : const Color(0xFF2563EB), // Color for locked
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SFUI',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(
            IconData(0xf058,
                fontFamily: 'FontAwesomeRegular',
                fontPackage: 'font_awesome_flutter'),
            color: Color(0xFF9747FF),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF2B1B5A),
              fontWeight: FontWeight.w500,
              fontFamily: 'SFUI',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCityAccessCard() {
    return Center(
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width - 40,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9747FF), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9747FF).withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9747FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Best for Explorers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SFUI',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '1 Month All City Access',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B1B5A),
                    fontFamily: 'SFUI',
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹999',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'SFUI',
                      ),
                    ),
                    SizedBox(width: 6),
                    Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text(
                        'only',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SFUI',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAccessFeature('Access to all cities'),
                _buildAccessFeature('Unlimited duration'),
                _buildAccessFeature('Priority support'),
                _buildAccessFeature('Exclusive features'),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            width: MediaQuery.of(context).size.width - 40,
            child: ElevatedButton(
              onPressed: () {
                // Navigation logic will be added later
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'SFUI',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '7-day money-back guarantee',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'SFUI',
              ),
            ),
          ),
          const Center(
            child: Text(
              'Cancel anytime',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'SFUI',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCitiesUI() {
    if (_addedCities.isEmpty) {
      return const SizedBox
          .shrink(); // Return an empty widget if no cities are selected
    }

    final totalCities = _addedCities.length;
    final totalAmount = totalCities * 99;
    const duration = 7; // Fixed duration for all cities

    final searchBarWidth =
        MediaQuery.of(context).size.width - 40; // Match search bar width

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: searchBarWidth,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selected Cities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'SFUI',
                ),
              ),
              const SizedBox(height: 8),
              ..._addedCities.map((city) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SFUI',
                              ),
                            ),
                            const Text(
                              '7 Days Access',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: 'SFUI',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              '₹99',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SFUI',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _addedCities.remove(city);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        Container(
          width: searchBarWidth,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'SFUI',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Cities',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                      fontFamily: 'SFUI',
                    ),
                  ),
                  Text(
                    '$totalCities',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'SFUI',
                    ),
                  ),
                ],
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                      fontFamily: 'SFUI',
                    ),
                  ),
                  Text(
                    '7 Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'SFUI',
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1, color: Color(0xFFEAEAEA)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                      fontFamily: 'SFUI',
                    ),
                  ),
                  Text(
                    '₹$totalAmount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'SFUI',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDropdown = false; // Close the dropdown when tapping anywhere
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Choose Your Premium Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'SFUI',
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          toolbarHeight: 60,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Premium Access Title and Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Access',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        fontFamily: 'SFUI',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose your travel access plan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757575),
                        fontFamily: 'SFUI',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Gradient Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B2C), Color(0xFF9747FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCustomTabBar(),
                ],
              ),
              // Remove the fixed height container to allow proper scrolling
              _selectedTab == 0
                  ? _buildCityPlansTab()
                  : const AllCityAccessTab(),
            ],
          ),
        ),
      ),
    );
  }
}
