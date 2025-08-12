import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/screens/home_screen.dart';

class ExploreCitiesScreen extends StatelessWidget {
  const ExploreCitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, exploreProvider, _) {
        final cities = exploreProvider.cities;
        final isLoading = exploreProvider.isLoadingCities;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Explore Cities'),
            centerTitle: true,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio:
                          2.8, // Increased aspect ratio for shorter cards
                    ),
                    itemCount: cities.length,
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      // Define a list of your requested gradient color pairs
                      final gradients = [
                        [const Color(0xFFf953c6), const Color(0xFFb91d73)],
                        [const Color(0xFFf12711), const Color(0xFFf5af19)],
                        [const Color(0xFF1f4037), const Color(0xFF99f2c8)],
                        [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                        [const Color(0xFFcb356b), const Color(0xFFbd3f32)],
                      ];
                      final gradient = gradients[index % gradients.length];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          splashColor: gradient[1].withOpacity(0.2),
                          onTap: () {
                            exploreProvider.setSelectedLocation(city);
                            Navigator.of(context)
                                .pop(); // Just pop, do not push HomeScreen
                          },
                          child: Container(
                            // height: 60, // Remove fixed height for flexibility
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[1].withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8), // Less vertical padding
                              child: Text(
                                city.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  // Helper function to determine if white text should be used based on gradient brightness
  bool _useWhiteText(List<Color> gradient) {
    // Calculate average luminance of the gradient colors
    double luminance =
        (gradient[0].computeLuminance() + gradient[1].computeLuminance()) / 2;
    return luminance < 0.5;
  }
}
