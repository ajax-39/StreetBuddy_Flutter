import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/screens/MainScreens/Explore/explore_people_screen.dart';
import 'package:street_buddy/screens/MainScreens/Explore/explore_city_list_screen.dart';
import 'package:street_buddy/utils/styles.dart';

class SearchScreen extends StatelessWidget {
  final int tabIndex;

  const SearchScreen({super.key, this.tabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, exploreProvider, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              'Explore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
            ),
            centerTitle: true,
          ),
          body: DefaultTabController(
            length: 2,
            initialIndex: tabIndex,
            animationDuration: Duration.zero,
            child: const Column(
              children: [
                TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 1,
                  dividerColor: Colors.grey,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.black,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Places'),
                    Tab(text: 'People'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      ExploreCityListScreen(),
                      ExplorePeopleScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
