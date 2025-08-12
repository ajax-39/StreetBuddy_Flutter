import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/Guides/view_guide_screen.dart';
import 'package:street_buddy/screens/MainScreens/Post/post_detail_view.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/responsive_util.dart';
import 'package:street_buddy/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/screens/MainScreens/Profile/profile_screen.dart'
    show ShimmerLoading, ShimmerGridPlaceholder;

class ProfilePostsGuidesSection extends StatelessWidget {
  final UserModel userData;
  final dynamic supabase;
  const ProfilePostsGuidesSection(
      {super.key, required this.userData, required this.supabase});

  @override
  Widget build(BuildContext context) {
    return _buildTabsSection(context, userData);
  }

  Widget _buildTabsSection(BuildContext context, UserModel userData) {
    final horizontalPadding = ResponsiveUtil.getPadding(
      context,
      small: 16.0,
      medium: 20.0,
      large: 24.0,
    );

    final tabFontSize = ResponsiveUtil.getFontSize(
      context,
      small: 14.0,
      medium: 15.0,
      large: 16.0,
    );

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 1,
              dividerColor: Colors.grey[300],
              labelColor: Colors.black,
              indicatorColor: AppColors.primary,
              labelStyle: TextStyle(fontSize: tabFontSize),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(vertical: 12),
              tabs: [
                const Tab(child: Text('Posts')),
                Consumer<UploadProvider>(
                  builder: (context, uploadProvider, child) {
                    return FutureBuilder<List<PostModel>>(
                      future: uploadProvider
                          .getCachedOrFreshUserGuides(userData.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Tab(child: Text('Guides'));
                        }
                        var c = snapshot.data?.length ?? 0;
                        return Tab(
                          icon: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Guides'),
                              const SizedBox(width: 5),
                              c != 0
                                  ? CircleAvatar(
                                      radius: ResponsiveUtil.getResponsiveValue(
                                        context,
                                        small: 10.0,
                                        medium: 11.0,
                                        large: 12.0,
                                      ),
                                      child: Text('$c',
                                          style: AppTypography.link.copyWith(
                                              fontSize:
                                                  ResponsiveUtil.getFontSize(
                                            context,
                                            small: 10.0,
                                            medium: 11.0,
                                            large: 12.0,
                                          ))))
                                  : Container(width: 0),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate available height minus TabBar height
                final screenHeight = MediaQuery.of(context).size.height;
                final availableHeight =
                    screenHeight * 0.6; // Use 60% of screen height

                return SizedBox(
                  height: availableHeight,
                  child: TabBarView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildPostsGrid(context, userData.uid),
                      _buildGuidesGrid(context, userData.uid),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsGrid(BuildContext context, String userId) {
    final supabase = this.supabase;
    Future<void> updateTotalLikesCount(List<PostModel> posts) async {
      int m = 0;
      for (var i in posts) {
        m += i.likes;
      }
      await supabase.from('users').update({'total_likes': m}).eq('uid', userId);
    }

    return Consumer2<UploadProvider, PostProvider>(
      builder: (context, uploadProvider, postProvider, child) {
        final previousPosts = uploadProvider.previousUserPosts;

        return FutureBuilder<List<PostModel>>(
          future: uploadProvider.getCachedOrFreshUserPosts(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                previousPosts != null) {
              return _buildPostsGridContent(
                  previousPosts, userId, uploadProvider, context);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerGridPlaceholder();
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading posts'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 30),
                      SizedBox(height: 10),
                      Text('No Posts!', style: AppTypography.headline),
                    ],
                  ),
                ),
              );
            }

            final posts = snapshot.data!;
            uploadProvider.savePreviousPosts(posts);
            updateTotalLikesCount(posts);

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildPostsGridContent(
                  posts, userId, uploadProvider, context),
            );
          },
        );
      },
    );
  }

  Widget _buildPostsGridContent(List<PostModel> posts, String userId,
      UploadProvider uploadProvider, BuildContext context) {
    return GridView.builder(
      key: ValueKey<String>('posts-grid-${DateTime.now().toString()}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: GestureDetector(
            onTap: () {
              if (post.type != PostType.guide) {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => PostDetailView(
                              initialPostId: post.id,
                              posts: posts,
                              initialIndex: index,
                            )))
                    .then((_) {
                  uploadProvider.refreshUserPosts(userId);
                  context.read<ProfileProvider>().fetchUserData(userId);
                });
              } else {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => ViewGuideScreen(
                              post: post,
                              isOwnProfile: true,
                            )))
                    .then((_) {
                  uploadProvider.refreshUserPosts(userId);
                  context.read<ProfileProvider>().fetchUserData(userId);
                });
              }
            },
            child: post.type == PostType.image
                ? CachedNetworkImage(
                    imageUrl: post.mediaUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerLoading(
                      isLoading: true,
                      child: SizedBox.expand(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.error_outline, color: Colors.grey),
                    ),
                  )
                : _buildPostThumbnail(post),
          ),
        );
      },
    );
  }

  Widget _buildPostThumbnail(PostModel post) {
    if (post.type == PostType.guide) {
      return post.thumbnailUrl?.isEmpty == true
          ? Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                colors: [Color(0xffcc2b5e), Color(0xff753a88)],
                stops: [0, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: AppSpacing.xl,
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: post.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          post.thumbnailUrl?.isEmpty == true
              ? Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: post.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.grey,
                    ),
                  ),
                ),
          const Positioned(
            top: 8,
            right: 8,
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildGuidesGrid(BuildContext context, String userId) {
    final supabase = this.supabase;
    Future<void> updateGuidesCount(String userId, int count) async {
      await supabase
          .from('users')
          .update({'guide_count': count}).eq('uid', userId);
    }

    Future<void> updateMonthlyGuidesCount(
        String userId, List<PostModel> posts) async {
      int monthlyCount = posts.where((post) {
        var now = DateTime.now();
        return now.difference(post.createdAt).inDays <= 31;
      }).length;

      await supabase
          .from('users')
          .update({'guide_count_mnt': monthlyCount}).eq('uid', userId);
    }

    Future<void> updateAvgGuidesReview(
        String userId, List<PostModel> posts) async {
      var reviewPosts = posts.where((post) => post.description.isNotEmpty);
      if (reviewPosts.isEmpty) return;

      double totalRating = reviewPosts.fold(0.0, (sum, post) {
        return sum + double.parse(post.description.split('|').first);
      });

      double avgRating =
          double.parse((totalRating / reviewPosts.length).toStringAsFixed(1));

      await supabase
          .from('users')
          .update({'avg_guide_review': avgRating}).eq('uid', userId);
    }

    return Consumer2<UploadProvider, PostProvider>(
      builder: (context, uploadProvider, postProvider, child) {
        final previousGuides = uploadProvider.previousUserGuides;

        return FutureBuilder<List<PostModel>>(
          future: uploadProvider.getCachedOrFreshUserGuides(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                previousGuides != null) {
              return Stack(
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: _buildGuidesGridContent(
                        previousGuides, userId, uploadProvider, context),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withOpacity(0.2),
                      child: const ShimmerLoading(
                        isLoading: true,
                        child: SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ShimmerGridPlaceholder();
            }

            if (snapshot.hasError) {
              print(snapshot.error);
              return const Center(child: Text('Error loading guides'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 30),
                      SizedBox(height: 10),
                      Text('No Guides!', style: AppTypography.headline),
                    ],
                  ),
                ),
              );
            }

            final posts = snapshot.data!.toList();
            uploadProvider.savePreviousGuides(posts);

            Future.microtask(() {
              updateGuidesCount(userId, posts.length);
              updateMonthlyGuidesCount(userId, posts);
              updateAvgGuidesReview(userId, posts);
            });

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildGuidesGridContent(
                  posts, userId, uploadProvider, context),
            );
          },
        );
      },
    );
  }

  Widget _buildGuidesGridContent(List<PostModel> posts, String userId,
      UploadProvider uploadProvider, BuildContext context) {
    return ListView.builder(
      key: ValueKey<String>('guides-grid-${DateTime.now().toString()}'),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => ViewGuideScreen(
                  post: post,
                  isOwnProfile: true,
                ),
              ),
            )
                .then((_) {
              uploadProvider.refreshUserGuides(userId);
              context.read<ProfileProvider>().fetchUserData(userId);
            });
          },
          child: _buildGuideItem(post, userId, context),
        );
      },
    );
  }

  Widget _buildGuideItem(PostModel post, String userId, BuildContext context) {
    // Responsive spacing and dimensions using ResponsiveUtil
    final imageHeight = ResponsiveUtil.getResponsiveValue(
      context,
      small: 90.0,
      medium: 100.0,
      large: 110.0,
    );

    final horizontalPadding = ResponsiveUtil.getPadding(
      context,
      small: 10.0,
      medium: 11.0,
      large: 12.0,
    );

    final verticalPadding = ResponsiveUtil.getPadding(
      context,
      small: 7.0,
      medium: 8.0,
      large: 9.0,
    );

    final bottomMargin = ResponsiveUtil.getPadding(
      context,
      small: 18.0,
      medium: 19.0,
      large: 20.0,
    );

    final borderRadius = ResponsiveUtil.getResponsiveValue(
      context,
      small: 16.0,
      medium: 17.0,
      large: 18.0,
    );

    final titleFontSize = ResponsiveUtil.getFontSize(
      context,
      small: 14.0,
      medium: 15.0,
      large: 16.0,
    );

    final iconSize = ResponsiveUtil.getIconSize(
      context,
      small: 15.0,
      medium: 16.0,
      large: 17.0,
    );

    final textFontSize = ResponsiveUtil.getFontSize(
      context,
      small: 11.0,
      medium: 11.5,
      large: 12.0,
    );

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFD2D2D2),
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: post.thumbnailUrl ?? Constant.DEFAULT_PLACE_IMAGE,
            height: imageHeight,
            width: double.maxFinite,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
            child: Text(
              post.title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: fontsemibold,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/pin.png',
                          width: iconSize,
                          color: Colors.black,
                        ),
                        Text(
                          post.location,
                          style: TextStyle(
                            fontSize: textFontSize,
                            fontWeight: fontregular,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/time 5.png',
                          scale: ResponsiveUtil.getResponsiveValue(
                            context,
                            small: 4.0,
                            medium: 3.7,
                            large: 3.5,
                          ),
                          color: Colors.black,
                        ),
                        Text(
                          timeago.format(post.createdAt),
                          style: TextStyle(
                            fontSize: textFontSize,
                            fontWeight: fontregular,
                            color: Colors.black,
                          ),
                        )
                      ],
                    )
                  ],
                ),
                const Spacer(),
                Column(
                  children: [
                    Wrap(
                      spacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/heart.png',
                          width: iconSize,
                          color: Colors.black,
                        ),
                        Text(
                          '${post.likes} saves',
                          style: TextStyle(
                            fontSize: textFontSize,
                            fontWeight: fontregular,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Read More',
                          style: TextStyle(
                            fontSize: textFontSize,
                            fontWeight: fontmedium,
                            color: const Color(0xff3B4CFF),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: Color(0xff3B4CFF),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
