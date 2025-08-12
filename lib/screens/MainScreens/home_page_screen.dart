import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/comment.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/ad_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/discover_page_screen.dart';
import 'package:street_buddy/screens/MainScreens/Profile/view_profile_screen.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/custom_video_player.dart';
import 'package:street_buddy/widgets/feed_native_ad_widget.dart';
import 'package:street_buddy/widgets/heart_animation_widget.dart';
import 'package:street_buddy/widgets/hidden_post_placeholder.dart';
import 'package:street_buddy/widgets/like_widget.dart';
import 'package:street_buddy/widgets/post_options_modal.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
 
class HomePage extends StatelessWidget {
  const HomePage({super.key}); 

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: isTablet ? 70 : 56,
        title: Text('Street Buddy',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 22 : 20,
            )),
        actions: [
          IconButton(
            padding: EdgeInsets.symmetric(
                vertical: isTablet ? 12 : 8, horizontal: isTablet ? 8 : 0),
            onPressed: () {
              context.push('/notif');
            },
            icon:
                Image.asset('assets/icon/notif.png', width: isTablet ? 28 : 24),
          ),
          IconButton(
            padding: EdgeInsets.symmetric(
                vertical: isTablet ? 12 : 8, horizontal: isTablet ? 16 : 10),
            onPressed: () => context.push('/messages'),
            icon:
                Image.asset('assets/icon/chats.png', width: isTablet ? 28 : 24),
          ),
          SizedBox(width: isTablet ? 16 : 10),
        ],
      ),
      body: const PostFeed(),
    );
  }
}

class PostFeed extends StatefulWidget {
  const PostFeed({super.key});
  @override
  _PostFeedState createState() => _PostFeedState();
}

class _PostFeedState extends State<PostFeed>
    with AutomaticKeepAliveClientMixin {
  UserModel? _user;
  Future<UserModel>? _userFuture;
  Future<List<PostModel>>? _postsFuture;
  bool _initDone = false;
  int _lastRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if posts were refreshed and update future accordingly
    final postProvider = context.watch<PostProvider>();
    if (_lastRefreshKey != postProvider.refreshKey && _initDone) {
      _lastRefreshKey = postProvider.refreshKey;
      _refreshPosts();
    }
  }

  void _refreshPosts() {
    if (mounted) {
      setState(() {
        _postsFuture = _getInitialPosts();
      });
    }
  }

  Future<void> _initialize() async {
    try {
      await getGlobalUser();
      final currentUser = globalUser;
      if (currentUser != null) {
        // Start both operations in parallel instead of sequential
        final userFuture = context
            .read<ProfileProvider>()
            .fetchUserDataFuture(currentUser.uid);

        // Start background tasks that don't block UI
        ProfileProvider().systemHandlerUpdateOnline(currentUser.uid);

        final user = await userFuture;

        // Load first 10 posts in chronological order for fast initial render
        final postsFuture = _getInitialPosts();

        setState(() {
          _user = user;
          _userFuture = Future.value(user);
          _postsFuture = postsFuture;
          _initDone = true;
        });
      } else {
        setState(() => _initDone = true);
      }
    } catch (e) {
      debugPrint('Error initializing: $e');
      setState(() => _initDone = true);
      // Enable ads as fallback even if posts fail to load
      _enableAdsAfterDelay();
    }
  }

  // Load first 10 posts in chronological order for fast initial render
  Future<List<PostModel>> _getInitialPosts() async {
    try {
      final postProvider = context.read<PostProvider>();
      // Use cached method for super fast loading
      final posts = await postProvider.getPostsWithCache(
        limit: 10,
        offset: 0,
      );

      // Preload critical images in background
      if (posts.isNotEmpty && mounted) {
        postProvider.preloadCriticalData(posts, context);
      }

      return posts;
    } catch (e) {
      debugPrint('Error loading initial posts: $e');
      return [];
    }
  }

  // Enable ads with a small delay to ensure posts are fully rendered
  void _enableAdsAfterDelay() {
    debugPrint('🎯 Scheduling ad initialization after posts load...');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final adProvider = context.read<AdProvider>();
        adProvider.allowAdInitialization();
        debugPrint('🎯 Posts loaded successfully - ads can now be initialized');
        debugPrint(
            '🎯 Ad initialization flag: ${adProvider.isAdInitializationAllowed}');
      }
    }); 
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_initDone) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Unable to load user data'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _initDone = false;
                });
                _initialize();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return FutureBuilder<UserModel>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        // Remove unused user variable since we already have _user
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _initDone = false);
            await _initialize();
          },
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Divider(color: AppColors.textSecondary.withAlpha(50)),
                const TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 1,
                  dividerColor: Colors.grey,
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3.0,
                      color: Colors.orange,
                    ),
                  ),
                  tabs: [
                    Tab(text: 'All Posts'),
                    Tab(text: 'Discover'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // All Posts Tab - Shows chronological feed with ads
                      FutureBuilder<List<PostModel>>(
                        future: _postsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.post_add,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No posts available yet'),
                                  SizedBox(height: 8),
                                  Text('Check back later for new content!',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }

                          final allPosts = snapshot.data!;
                          final posts = allPosts
                              .where((post) => !context
                                  .read<PostProvider>()
                                  .isPostHidden(post.id))
                              .toList();

                          // Trigger ad initialization when posts are successfully displayed
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final adProvider = context.read<AdProvider>();
                            if (!adProvider.isAdInitializationAllowed &&
                                posts.isNotEmpty) {
                              debugPrint(
                                  '🎯 Posts displayed successfully - enabling ads');
                              adProvider.allowAdInitialization();
                            }
                          });

                          if (posts.isEmpty) {
                            return const Center(
                              child: Text('No visible posts'),
                            );
                          }

                          return _buildAllPostsList(posts);
                        },
                      ),
                      // Discover Tab
                      const DiscoverPageScreen(),
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

  // Build the all posts list with ads (same logic as discover)
  Widget _buildAllPostsList(List<PostModel> posts) {
    // Filter out guide posts for the all posts tab
    final visiblePosts =
        posts.where((post) => post.type != PostType.guide).toList();

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
        itemCount: _calculateItemCount(visiblePosts.length),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.width > 600 ? 100 : 80,
        ),
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
}

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProfileImage({
    super.key,
    this.imageUrl,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    // Check if imageUrl is not null and not empty
    final bool hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasValidImage
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildErrorWidget(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: size * 0.7,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.error,
        size: size * 0.7,
        color: Colors.grey[400],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});
  void _navigateToProfile(BuildContext context, String userId) {
    Navigator.push( 
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfileScreen(
          userId: userId,
          isOwnProfile: globalUser?.uid == userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final currentUser = globalUser;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final cardMargin = isTablet ? 16.0 : 8.0;
    final horizontalPadding = isTablet ? 20.0 : 10.0;

    // Check if post is hidden
    if (postProvider.isPostHidden(post.id)) {
      return HiddenPostPlaceholder(
        postId: post.id,
        cardMargin: cardMargin,
        isTablet: isTablet,
      );
    }

    return Card(
      margin: EdgeInsets.only(bottom: cardMargin),
      elevation: 0,
      color: AppColors.surfaceBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Header - Simplified version that doesn't refetch user data
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: isTablet ? 12 : 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context, post.userId),
                  child: ProfileImage(
                    imageUrl: post.userProfileImage, // Use cached image
                    size: isTablet ? 40 : 32,
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(context, post.userId),
                        child: Text(
                          post.username[0].toUpperCase() +
                              post.username.substring(1),
                          style: TextStyle(
                            fontWeight: fontsemibold,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                      if (post.location.isNotEmpty)
                        SizedBox(height: isTablet ? 2 : 1),
                      if (post.location.isNotEmpty)
                        Text(
                          post.location,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: fontregular,
                            color: const Color(0xff262626),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  iconSize: isTablet ? 28 : 24,
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    // Show post options and pass share callback
                    final currentUser = globalUser;
                    showPostOptionsModal(
                      context,
                      currentUserId: currentUser?.uid ?? '',
                      targetUserId: post.userId,
                      postId: post.id,
                      onShare: () {
                        Navigator.pop(context); // Close modal before sharing
                        if (currentUser != null) {
                          ShareService()
                              .sharePost(context, currentUser.uid, post);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Post Media
          GestureDetector(
            onDoubleTap: () {
              final postProvider = context.read<PostProvider>();
              postProvider.toggleLike(
                  post, currentUser?.uid ?? '', currentUser?.name ?? 'Someone');
              postProvider.showHeartAnimation(post.id);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                post.type == PostType.image
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: screenSize.width,
                            maxHeight: isTablet
                                ? screenSize.height * 0.7
                                : screenSize.height * 0.6),
                        child: CachedNetworkImage(
                          imageUrl: post.mediaUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                          ),
                          errorWidget: (context, url, error) => AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error, size: 40),
                              ),
                            ),
                          ),
                        ),
                      )
                    : post.type == PostType.video
                        ? CustomVideoPlayer(videoUrl: post.mediaUrls.first)
                        : Container(),
                if (postProvider.isHeartAnimationVisible(post.id))
                  const HeartAnimationWidget(),
              ],
            ),
          ),

          // Action Buttons - Use cached data instead of streams for first render
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: horizontalPadding,
            ),
            child: Row(
              children: [
                LikeWidget(
                  isLiked: currentUser != null &&
                      post.likedBy.contains(currentUser.uid),
                  callback: () => postProvider.toggleLike(
                    post,
                    currentUser?.uid ?? '',
                    currentUser?.name ?? 'Someone',
                  ),
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Visibility(
                  visible: post.likes > 0,
                  child: Text(
                    '${post.likes}',
                    style: TextStyle(
                      fontWeight: fontregular,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                GestureDetector(
                  onTap: () {
                    // Toggle comment visibility with animation
                    postProvider.toggleCommentField(post.id);
                  },
                  child: Image.asset(
                    'assets/icon/comment.png',
                    width: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Visibility(
                  visible: post.comments != 0,
                  child: Text(
                    post.comments.toString(),
                    style: TextStyle(
                      fontWeight: fontregular,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                GestureDetector(
                  onTap: () =>
                      ShareService().sharePost(context, currentUser!.uid, post),
                  child: Image.asset(
                    'assets/icon/share.png',
                    width: isTablet ? 24 : 18,
                  ),
                ),
                const Spacer(),
                StreamBuilder<List<String>>(
                  stream: postProvider.getSavedPostsStream(currentUser!.uid),
                  builder: (context, snapshot) {
                    final savedPosts = snapshot.data ?? [];
                    final isSaved = postProvider.isPostSavedByUser(
                      postId: post.id,
                      savedPosts: savedPosts,
                    );
                    return GestureDetector(
                      onTap: () async {
                        print(
                            'Saving post ${post.id} for user ${currentUser.uid} to database...');
                        await postProvider.toggleSavePost(
                          userId: currentUser.uid,
                          postId: post.id,
                        );
                        // Fetch updated savedPosts to determine new state
                        final data = await postProvider.supabase
                            .from('users')
                            .select('saved_post')
                            .eq('uid', post.id)
                            .single();
                        final List<String> updatedSavedPosts =
                            List<String>.from(data['saved_post'] ?? []);
                        final nowSaved = updatedSavedPosts.contains(post.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(nowSaved
                                ? 'Post saved for later!'
                                : 'Post removed from saved!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Icon(
                        isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border_outlined,
                        size: isTablet ? 28 : 24,
                        color: isSaved ? Colors.orange : Colors.black,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Likes Count - Simplified without streams for first render
          Visibility(
            visible: post.likedBy.isNotEmpty,
            child: Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: isTablet ? 6 : 4,
                bottom: isTablet ? 2 : 1,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: isTablet ? 10 : 8,
                    backgroundImage: NetworkImage(
                        post.userProfileImage.isNotEmpty
                            ? post.userProfileImage
                            : Constant.DEFAULT_USER_IMAGE),
                  ),
                  SizedBox(width: isTablet ? 8 : 6),
                  Expanded(
                    child: Text.rich(TextSpan(
                        text: 'Liked by ',
                        style: TextStyle(
                          fontWeight: fontregular,
                          fontSize: isTablet ? 14 : 12,
                        ),
                        children: [
                          TextSpan(
                            text: post.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: post.likedBy.length > 1 ? ' and others' : '',
                          ),
                        ])),
                  ),
                ],
              ),
            ),
          ),

          // Post Description
          if (post.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: isTablet ? 8 : 6,
                bottom: isTablet ? 4 : 2,
              ),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 15,
                      ),
                  children: [
                    TextSpan(
                      text: '${post.username} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap =
                            () => _navigateToProfile(context, post.userId),
                    ),
                    TextSpan(text: post.description),
                  ],
                ),
              ),
            ),

          // Comments Section - Only show when comment button is clicked
          if (postProvider.isCommentFieldVisible(post.id))
            FutureBuilder<List<CommentModel>>(
              future: postProvider.getPostCommentsFuture(post.id),
              key: ValueKey('comments_${post.id}_${postProvider.refreshKey}'),
              builder: (context, snapshot) {
                // Handle loading state with fade animation
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return FadeTransition(
                    opacity: const AlwaysStoppedAnimation(0.6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          2, // Show 2 skeleton comment placeholders
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Skeleton avatar
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Skeleton comment text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final comments = snapshot.data ?? [];
                final displayComments = comments.isEmpty
                    ? []
                    : (postProvider.showAllComments(post.id)
                        ? comments
                        : comments.take(3).toList());

                // Use AnimatedOpacity to show loaded comments with fade-in
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comments
                      if (displayComments.isNotEmpty)
                        ...displayComments.map((comment) => Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: isTablet ? 6 : 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Comment Text
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context)
                                            .style
                                            .copyWith(
                                              fontSize: isTablet ? 15 : 14,
                                            ),
                                        children: [
                                          TextSpan(
                                            text: '${comment.username} ',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () =>
                                                  _navigateToProfile(
                                                      context, comment.userId),
                                          ),
                                          TextSpan(text: comment.content),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),

                      // Show More/Less Comments Button - only if there are more than 3 comments
                      if (comments.length > 3)
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding),
                          child: TextButton(
                            onPressed: () =>
                                postProvider.toggleShowAllComments(post.id),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              postProvider.showAllComments(post.id)
                                  ? 'Hide comments'
                                  : 'View all ${comments.length} comments',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isTablet ? 15 : 13,
                              ),
                            ),
                          ),
                        ),

                      // Comment Input Field with animation - Always include this, but animated based on visibility
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: postProvider.isCommentFieldVisible(post.id)
                            ? (isTablet ? 80 : 70)
                            : 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: postProvider.isCommentFieldVisible(post.id)
                              ? 1
                              : 0,
                          child: Padding(
                            padding: EdgeInsets.all(horizontalPadding),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _navigateToProfile(
                                      context, currentUser.uid),
                                  child: ProfileImage(
                                    imageUrl: currentUser.profileImageUrl,
                                    size: isTablet ? 36 : 32,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: TextField(
                                    controller: postProvider
                                        .getCommentController(post.id),
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Add a comment...',
                                      hintStyle: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onSubmitted: (content) async {
                                      if (content.isNotEmpty) {
                                        await postProvider.addComment(
                                            post, content);
                                        postProvider
                                            .getCommentController(post.id)
                                            .clear();
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  iconSize: isTablet ? 28 : 24,
                                  icon: const Icon(Icons.send),
                                  onPressed: () async {
                                    final controller = postProvider
                                        .getCommentController(post.id);
                                    if (controller.text.isNotEmpty) {
                                      await postProvider.addComment(
                                          post, controller.text);
                                      controller.clear();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Post Time
          Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: isTablet ? 6 : 4,
              bottom: isTablet ? 16 : 12,
            ),
            child: Text(
              timeago.format(post.createdAt),
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                fontWeight: fontregular,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Divider between posts
          Container(
            height: 1,
            color: Colors.grey[200],
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
          ),
          SizedBox(height: isTablet ? 8 : 6),
        ],
      ),
    );
  }
}

class CustomTabIndicator extends Decoration {
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  const CustomTabIndicator({
    required this.activeColor,
    required this.inactiveColor,
    this.height = 3.0,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomTabIndicatorPainter(
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      height: height,
    );
  }
}

class _CustomTabIndicatorPainter extends BoxPainter {
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  _CustomTabIndicatorPainter({
    required this.activeColor,
    required this.inactiveColor,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint();

    // Get the tab width
    final double tabWidth = configuration.size!.width;
    final double tabHeight = configuration.size!.height;

    // Draw active tab indicator (orange)
    paint.color = activeColor;
    final Rect activeRect = Rect.fromLTWH(
      offset.dx,
      offset.dy + tabHeight - height,
      tabWidth,
      height,
    );
    canvas.drawRect(activeRect, paint);

    // Draw inactive tab indicators (grey) - we'll draw them for all tabs
    // The active one will be drawn over in orange
    paint.color = inactiveColor;

    // For a 2-tab layout, we need to draw the other tab's indicator
    final double totalWidth = tabWidth * 2; // Assuming 2 tabs
    final double currentTabPosition = offset.dx;

    // Draw indicator for the other tab (inactive)
    if (currentTabPosition < totalWidth / 2) {
      // Current tab is the first one, draw indicator for second tab
      final Rect inactiveRect = Rect.fromLTWH(
        offset.dx + tabWidth,
        offset.dy + tabHeight - height,
        tabWidth,
        height,
      );
      canvas.drawRect(inactiveRect, paint);
    } else {
      // Current tab is the second one, draw indicator for first tab
      final Rect inactiveRect = Rect.fromLTWH(
        offset.dx - tabWidth,
        offset.dy + tabHeight - height,
        tabWidth,
        height,
      );
      canvas.drawRect(inactiveRect, paint);
    }
  }
}
