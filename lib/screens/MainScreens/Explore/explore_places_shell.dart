import 'package:flutter/material.dart';
import 'package:street_buddy/screens/MainScreens/Explore/explore_places_screen.dart';

/// This widget is used to show ExplorePlacesScreen with the bottom nav bar (HomeScreen)
class ExplorePlacesShell extends StatelessWidget {
  const ExplorePlacesShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Just return the ExplorePlacesScreen, HomeScreen will handle the nav bar
    return const ExplorePlacesScreen();
  }
}
