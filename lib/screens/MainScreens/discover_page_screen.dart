import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/ad_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/home_page_screen.dart';
import 'package:street_buddy/widgets/feed_native_ad_widget.dart';

/// * Explore Screen 2 :
/// ? fetches posts using futures
/// ? has trending, suggested and recent catagories
/// ? optimized for minimum rebuilds and smooth transitions

class DiscoverPageScreen extends StatefulWidget {
  const DiscoverPageScreen({super.key});

  @override
  State<DiscoverPageScreen> createState() => _DiscoverPageScreenState();
}

class _DiscoverPageScreenState extends State<DiscoverPageScreen>
    with AutomaticKeepAliveClientMixin {
  // Cache for posts to enable smooth transitions
  List<PostModel>? _cachedSuggestedPosts;
  List<PostModel>? _cachedTrendingPosts;
  final List<String> _privateUsers = [];
  UserModel? _userData;
  bool _isInitialLoading = true;

  // Keys for triggering refreshes
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  final ValueNotifier<bool> _refreshNotifier = ValueNotifier<bool>(false);

  // Future holders to avoid duplicate requests
  Future<UserModel?>? _userDataFuture;
  Future<List<PostModel>>? _suggestedPostsFuture;
  Future<List<PostModel>>? _trendingPostsFuture;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (globalUser != null) {
      _userDataFuture = fetchUserData(globalUser!.uid);
      _userDataFuture!.then((userData) {
        _userData = userData;
        if (userData != null) {
          _loadInitialData(userData.interests);
        }
      });
    }
  }

  Future<void> _loadInitialData(List<String> interests) async {
    // Load suggested and trending posts in parallel
    await Future.wait([
      _fetchSuggestedPosts(interests)
          .then((posts) => _cachedSuggestedPosts = posts),
      _fetchTrendingPosts().then((posts) => _cachedTrendingPosts = posts),
    ]);

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if we already have data (don't duplicate initial load)
    if (!_isInitialLoading) {
      _refreshData(silent: true);
    }
  }

  Future<void> _refreshData({bool silent = false}) async {
    // Prevent multiple concurrent refreshes
    if (_suggestedPostsFuture != null && !silent) {
      _refreshIndicatorKey.currentState?.show();
    }

    // Reset futures to force refresh
    if (globalUser != null) {
      _userDataFuture = fetchUserData(globalUser!.uid);

      // Wait for user data before fetching posts
      final userData = await _userDataFuture;
      if (userData != null && mounted) {
        _userData = userData;
        _suggestedPostsFuture = _fetchSuggestedPosts(userData.interests);
        _trendingPostsFuture = _fetchTrendingPosts();

        // Notify listeners that data is refreshing
        _refreshNotifier.value = !_refreshNotifier.value;
      }
    }
  }

  Future<List<PostModel>> _fetchSuggestedPosts(List<String> interests) async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('is_private', false)
          .order('created_at', ascending: false);

      final newPosts = response
          .where((element) => !_privateUsers.contains(element['user_id']))
          .map((e) => PostModel.fromMap(e['id'], e))
          .toList();

      // Store the fetched posts in cache
      _cachedSuggestedPosts = newPosts;
      return newPosts;
    } catch (e) {
      // Return cached data on error if available
      if (_cachedSuggestedPosts != null) {
        return _cachedSuggestedPosts!;
      }
      rethrow;
    }
  }

  Future<List<PostModel>> _fetchTrendingPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .eq('is_private', false)
          .order('likes', ascending: false);

      final newPosts = response
          .where((element) => !_privateUsers.contains(element['user_id']))
          .map((e) => PostModel.fromMap(e['id'], e))
          .toList();

      // Store the fetched posts in cache
      _cachedTrendingPosts = newPosts;
      return newPosts;
    } catch (e) {
      // Return cached data on error if available
      if (_cachedTrendingPosts != null) {
        return _cachedTrendingPosts!;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (globalUser == null) {
      return const Center(child: Text('Please log in'));
    }

    // Show loading screen until initial data is loaded
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<ExploreProvider>(
      builder: (context, state, child) {
        return Scaffold(
          body: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () => _refreshData(silent: false),
            child: ValueListenableBuilder<bool>(
              valueListenable: _refreshNotifier,
              builder: (context, _, __) {
                final interests = _userData?.interests ?? [];

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Extract static UI components to const widgets
                      // ListTile(
                      //   title: Text(
                      //     interests.isEmpty ? 'Suggested' : 'Interests',
                      //     style: AppTypography.headline,
                      //   ),
                      // ),
                      _buildSuggestedPostsSection(interests),
                      // const ListTile(
                      //   title: Text(
                      //     'Trending',
                      //     style: AppTypography.headline,
                      //   ),
                      // ),
                      _buildTrendingPostsSection(interests),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedPostsSection(List<String> interests) {
    // Reuse existing future if available or create new one
    _suggestedPostsFuture ??= _fetchSuggestedPosts(interests);

    return FutureBuilder<List<PostModel>>(
      future: _suggestedPostsFuture,
      builder: (context, snapshot) {
        // Show cached data immediately while loading new data
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedSuggestedPosts != null) {
          return _buildPostsList(_cachedSuggestedPosts!);
        }

        if (snapshot.hasError) {
          // Show cached data if available, otherwise show error
          if (_cachedSuggestedPosts != null) {
            return _buildPostsList(_cachedSuggestedPosts!);
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No posts found'));
        }

        // Update cache and build list
        _cachedSuggestedPosts = snapshot.data;
        return _buildPostsList(snapshot.data!);
      },
    );
  }

  Widget _buildTrendingPostsSection(List<String> interests) {
    // Only show trending section if user has interests
    if (interests.isEmpty) {
      return const SizedBox.shrink();
    }

    // Reuse existing future if available or create new one
    _trendingPostsFuture ??= _fetchTrendingPosts();

    return FutureBuilder<List<PostModel>>(
      future: _trendingPostsFuture,
      builder: (context, snapshot) {
        // Show cached data immediately while loading new data
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedTrendingPosts != null) {
          return _buildPostsList(_cachedTrendingPosts!);
        }

        if (snapshot.hasError) {
          // Show cached data if available, otherwise show error
          if (_cachedTrendingPosts != null) {
            return _buildPostsList(_cachedTrendingPosts!);
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No posts found'));
        }

        // Update cache and build list
        _cachedTrendingPosts = snapshot.data;
        return _buildPostsList(snapshot.data!);
      },
    );
  }

  // Use a const key for the list to prevent unnecessary rebuilds
  Widget _buildPostsList(List<PostModel> posts) {
    // Filter out hidden posts
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final visiblePosts =
        posts.where((post) => !postProvider.isPostHidden(post.id)).toList();

    // Preload ads for all visible ad positions (after every 3 posts)
    // Only load ads if initialization is allowed (after posts are loaded)
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    if (adProvider.isAdInitializationAllowed) {
      final adCount = (visiblePosts.length / 3).floor();
      for (int i = 1; i <= adCount; i++) {
        adProvider.loadFeedNativeAd(i);
      }
    }

    // Use a more stable key generation approach
    final key = ValueKey<int>(
        visiblePosts.fold(0, (prev, post) => prev + post.id.hashCode));
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final cardMargin = isTablet ? 16.0 : 8.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: ListView.builder(
        key: key,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _calculateItemCount(visiblePosts.length),
        itemBuilder: (context, index) {
          // Show ad after every 3 posts
          if ((index + 1) % 4 == 0) {
            final adPosition = (index + 1) ~/ 4;
            return FeedNativeAdWidget(
              position: adPosition,
              cardMargin: cardMargin,
              isTablet: isTablet,
            );
          }

          // Calculate the actual post index (accounting for ads)
          final postIndex = _getPostIndex(index);
          if (postIndex >= visiblePosts.length) {
            return const SizedBox.shrink();
          }

          // Use const constructor for list items when possible
          return PostCard(
            key: ValueKey<String>(visiblePosts[postIndex].id),
            post: visiblePosts[postIndex],
          );
        },
      ),
    );
  }

  // Calculate total item count including ads
  int _calculateItemCount(int postCount) {
    // For every 3 posts, we add 1 ad
    final adCount = (postCount / 3).floor();
    return postCount + adCount;
  }

  // Get the actual post index from the list index (accounting for ads)
  int _getPostIndex(int listIndex) {
    // Calculate how many ads appear before this index (ad after every 3 posts)
    final adsBeforeIndex = ((listIndex + 1) ~/ 4);
    return listIndex - adsBeforeIndex;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }
}

Future<UserModel?> fetchUserData(String uid) async {
  try {
    final response =
        await supabase.from('users').select().eq('uid', uid).single();

    return UserModel.fromMap(uid, response);
  } catch (e) {
    debugPrint('Error fetching user data: $e');
  }
  return null;
}
