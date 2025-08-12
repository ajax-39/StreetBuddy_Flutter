import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';

class AllCityAccessTab extends StatefulWidget {
  const AllCityAccessTab({super.key});

  @override
  State<AllCityAccessTab> createState() => _AllCityAccessTabState();
}

class _AllCityAccessTabState extends State<AllCityAccessTab> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExploreProvider>(context, listen: false);
    if (provider.cities.isEmpty && !provider.isLoadingCities) {
      provider.initializeCities();
    }
  }

  // Map city names to asset filenames (same as explore city screen)
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

    // Direct mapping first
    if (_cityAssetMap.containsKey(key)) {
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
        return _cityAssetMap[mapKey]!;
      }
    }

    return '$key.png';
  }

  Widget _buildPrivilegeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Color? bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // No background color, no border
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'SFUI',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontFamily: 'SFUI',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoadingCities;
        final cities = provider.cities;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unlock All Cities',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SFUI',
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'One Plan for All Adventures',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SFUI',
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFED7014),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Best for Explorers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'SFUI',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cities Grid
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (cities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 53,
                            height: 53,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/city_card/${_getCityAsset(city)}',
                                fit: BoxFit.cover,
                                width: 53,
                                height: 53,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 53,
                                    height: 53,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_city,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            city.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SFUI',
                              color: Color(0xFF000000),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Pricing Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹999',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'SFUI',
                            color: Color(0xFF000000),
                          ),
                        ),
                        SizedBox(width: 2),
                        Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            '/month',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'SFUI',
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Best for Explorers',
                      style: TextStyle(
                        color: Color(0xFFED7014),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SFUI',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Premium Benefits Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Benefits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SFUI',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Premium benefits
                    _buildPrivilegeCard(
                      icon: Icons.headphones,
                      color: Colors.deepPurple,
                      title: 'Add Free Experience',
                      subtitle: 'Enjoy uninterrupted travel planning',
                      bgColor: const Color(0xFFF0E6FF),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.flash_on,
                      color: Colors.orange,
                      title: 'Faster Access',
                      subtitle: 'See new cafes and spots before anyone else',
                      bgColor: const Color(0xFFFFF0E6),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.verified_user,
                      color: Colors.red,
                      title: 'Verified VIP Badge',
                      subtitle: 'Exclusive guides and secret travel spots',
                      bgColor: const Color(0xFFFFEEEE),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.article,
                      color: Colors.blue,
                      title: 'Premium Content',
                      subtitle: 'Get easy list of the best places to visit',
                      bgColor: const Color(0xFFE6F4FF),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.support_agent,
                      color: Colors.purple,
                      title: 'Priority Support',
                      subtitle: 'Get help faster when you need support',
                      bgColor: const Color(0xFFF5E6FF),
                    ),

                    const SizedBox(height: 24),

                    // Buy Now Button (matching City Plans screen style)
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle purchase
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C3B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Buy Now – ₹299 for All Cities',
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

                    // Guarantees (matching City Plans screen style)
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

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
