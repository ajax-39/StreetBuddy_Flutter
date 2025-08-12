import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/Guides/view_guide_screen.dart';
import 'package:street_buddy/screens/MainScreens/Post/post_detail_view.dart';
import 'package:street_buddy/screens/MainScreens/Profile/edit_profile_screen.dart';
import 'package:street_buddy/screens/MainScreens/Profile/follow_list_screen.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/profile_options_modal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewProfileScreen extends StatelessWidget {
  final String userId;
  final bool isOwnProfile;

  const ViewProfileScreen({
    super.key,
    required this.userId,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    void showEnlargedProfilePic(String imageUrl) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (context) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Hero(
              tag: 'profile-pic',
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    }

    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        return StreamBuilder<UserModel?>(
          stream: profileProvider.streamUserData(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userData = snapshot.data;
            if (userData == null) {
              return const Scaffold(
                body: Center(child: Text('User not found')),
              );
            }

            return Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackgroundImage(
                          userData.coverImageUrl, context, userData),

                      // Profile Image (overlapping background)
                      _buildProfileImageSection(
                          context, userData, showEnlargedProfilePic),

                      // Profile Header - Name and Bio
                      _buildProfileInfo(context, userData),

                      const SizedBox(height: AppSpacing.sm),

                      // Stats
                      _buildStatsSection(context, userData),

                      const SizedBox(height: AppSpacing.md),

                      // Action Buttons (only for own profile)
                      if (isOwnProfile) _buildActionButtons(context, userData),

                      // Follow button for other users
                      if (!isOwnProfile) _buildFollowButton(context, userData),

                      const SizedBox(height: AppSpacing.lg),

                      // Tabs
                      _buildTabsSection(context, userData),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods for better code organization and responsiveness
  Widget _buildActionButtons(BuildContext context, UserModel userData) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final horizontalPadding = isTablet ? 24.0 : AppSpacing.md;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isTablet ? AppSpacing.sm : AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              icon: Icon(
                Icons.edit_outlined,
                size: isTablet ? 20 : 18,
                color: AppColors.primary,
              ),
              label: Text(
                'Edit Profile',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 12 : 10,
                ),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Share.share(
                    'https://${ShareService().host}/profile?uid=${userData.uid}');
              },
              icon: Icon(
                Icons.share,
                size: isTablet ? 20 : 18,
                color: AppColors.primary,
              ),
              label: Text(
                'Share Profile',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 12 : 10,
                ),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(BuildContext context, UserModel userData,
      Function(String) showEnlargedProfilePic) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final profileImageSize = isTablet ? 120.0 : 100.0;

    return Transform.translate(
      offset: Offset(
          0, -(profileImageSize / 2)), // Move image up by half its height
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: isTablet ? 5 : 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () => showEnlargedProfilePic(userData.profileImageUrl ?? ''),
            child: Hero(
              tag: 'profile-pic',
              child: CircleAvatar(
                radius: profileImageSize / 2,
                backgroundColor: Colors.grey[300],
                backgroundImage: userData.profileImageUrl != null &&
                        userData.profileImageUrl!.isNotEmpty
                    ? NetworkImage(userData.profileImageUrl!)
                    : null,
                child: userData.profileImageUrl == null ||
                        userData.profileImageUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: profileImageSize * 0.6,
                        color: Colors.grey[600],
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, UserModel userData) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final horizontalPadding = isTablet ? 32.0 : AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isTablet
            ? AppSpacing.xs
            : 4.0, // Reduced top spacing since image overlaps
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            userData.name,
            style: AppTypography.headline.copyWith(
              fontSize: isTablet ? 26 : 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (userData.username.isNotEmpty) ...[
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              '@${userData.username}',
              style: AppTypography.body.copyWith(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (userData.bio != null && userData.bio!.isNotEmpty) ...[
            SizedBox(height: isTablet ? AppSpacing.sm : 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 8 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                userData.bio!,
                style: AppTypography.body.copyWith(
                  fontSize: isTablet ? 16 : 14,
                  height: 1.4,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, UserModel userData) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final horizontalPadding = isTablet ? 32.0 : AppSpacing.lg;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowListScreen(
                      userId: userData.uid,
                      type: FollowListType.following,
                    ),
                  ),
                ),
                child: _buildStat(
                    context, userData.followingCount.toString(), 'Following'),
              ),
              Container(
                color: AppColors.primary2,
                width: 1,
                height: 35,
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FollowListScreen(
                      userId: userData.uid,
                      type: FollowListType.followers,
                    ),
                  ),
                ),
                child: _buildStat(
                    context, userData.followersCount.toString(), 'Followers'),
              ),
              Container(
                color: AppColors.primary2,
                width: 1,
                height: 35,
              ),
              _buildStat(context, userData.postCount.toString(), 'Posts'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, UserModel userData) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final horizontalPadding = isTablet ? 24.0 : AppSpacing.md;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          final currentUserId = globalUser?.uid;
          if (currentUserId == null) {
            return const SizedBox.shrink();
          }

          final isFollowing = userData.isFollowedBy(currentUserId);

          return StreamBuilder(
              stream: provider
                  .checkAnyProfilePrivateToggle(userData.uid)
                  .asStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final isPrivate = snapshot.data ?? false;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isTablet ? 50 : 44,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: userData.allowRequests
                          ? () {
                              if (isFollowing) {
                                provider.unfollowUser(
                                    currentUserId, userData.uid);
                              } else {
                                if (!isPrivate) {
                                  provider.followUser(
                                      currentUserId, userData.uid);
                                } else {
                                  provider.requestFollow(
                                      currentUserId, userData.uid);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Follow request sent!')));
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFollowing ? Colors.grey[100] : AppColors.primary,
                        foregroundColor:
                            isFollowing ? Colors.grey[700] : Colors.white,
                        elevation: isFollowing ? 0 : 2,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                        side: isFollowing
                            ? BorderSide(color: Colors.grey[300]!, width: 1.5)
                            : null,
                        padding: EdgeInsets.symmetric(
                            vertical: isTablet ? AppSpacing.md : AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          key: ValueKey(isFollowing),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isFollowing) ...[
                              Icon(
                                Icons.add,
                                size: isTablet ? 22 : 20,
                                color: Colors.white, // Fixed to white
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                            ] else ...[
                              Icon(
                                Icons.check,
                                size: isTablet ? 20 : 18,
                                color: Colors.grey[700],
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                            ],
                            Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isTablet ? 16 : 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: isTablet ? 50 : 44,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              });
        },
      ),
    );
  }

  Widget _buildTabsSection(BuildContext context, UserModel userData) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              labelColor: Colors.black,
              indicatorColor: AppColors.primary,
              labelStyle: TextStyle(fontSize: isTablet ? 16 : 14),
              tabs: [
                const Tab(child: Text('Posts')),
                Consumer<UploadProvider>(
                  builder: (context, uploadProvider, child) {
                    return FutureBuilder<List<PostModel>>(
                      future: _fetchUserGuides(userData.uid),
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
                                      radius: isTablet ? 12 : 10,
                                      child: Text('$c',
                                          style: AppTypography.link.copyWith(
                                              fontSize: isTablet ? 12 : 10)))
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height:
                  MediaQuery.of(context).size.height * (isTablet ? 0.5 : 0.6),
              child: TabBarView(
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildPostsGrid(userData.uid),
                  _buildGuidesGrid(userData.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(
      String? url, BuildContext context, UserModel userData) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 800;

    // Responsive height and spacing
    final backgroundHeight = isLargeScreen ? 200.0 : (isTablet ? 180.0 : 150.0);
    final iconSize = isTablet ? 22.0 : 18.0;
    final buttonSize = isTablet ? 44.0 : 40.0;

    return Container(
      height: backgroundHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300], // Fallback color if image fails
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with proper error handling
          url != null && url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.8),
                            AppColors.primary.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.landscape,
                          size: 48,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.8),
                            AppColors.primary.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.8),
                        AppColors.primary.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.landscape,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                ),

          // Safe area for top buttons
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16.0 : 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Share the profile using the provided userData
                        if (globalUser != null) {
                          ShareService()
                              .shareProfile(context, globalUser!.uid, userData);
                        }
                      },
                      icon: Image.asset(
                        'assets/icon/share-alt.png',
                        width: iconSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () =>
                          showProfileOptionsModal(context, userData.uid),
                      icon: Icon(
                        Icons.more_vert,
                        size: iconSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String count, String label) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
              fontSize: isTablet ? 20 : 18, // Increased size
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: isTablet ? 14 : 13, // Slightly increased
              fontWeight: FontWeight.w600,
              color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPostsGrid(String userId) {
    return Consumer2<UploadProvider, PostProvider>(
      builder: (context, uploadProvider, postProvider, child) {
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.width > 600;
        final isLargeScreen = screenSize.width > 800;

        // Responsive grid columns and spacing
        final crossAxisCount = isLargeScreen ? 3 : (isTablet ? 3 : 2);
        final crossAxisSpacing = isTablet ? 6.0 : 4.0;
        final mainAxisSpacing = isTablet ? 6.0 : 4.0;
        final gridPadding = isTablet ? AppSpacing.sm : AppSpacing.xs;

        return FutureBuilder<List<PostModel>>(
          future: uploadProvider.getCachedOrFreshUserPosts(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final posts = snapshot.data ?? [];

            if (posts.isEmpty) {
              return const Center(
                child: Text(
                  'No Posts!',
                  style: AppTypography.headline,
                ),
              );
            }

            return GridView.builder(
              key: ValueKey<String>('posts-grid-${DateTime.now().toString()}'),
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(gridPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
                    if (post.type != PostType.guide) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostDetailView(
                            initialPostId: post.id,
                            posts: posts,
                            initialIndex: index,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ViewGuideScreen(
                            post: post,
                            isOwnProfile: false,
                          ),
                        ),
                      );
                    }
                  },
                  child: post.type == PostType.image
                      ? Image.network(
                          post.mediaUrls.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : post.type == PostType.guide
                          ? post.thumbnailUrl?.isEmpty == true
                              ? Container(
                                  decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                    colors: [
                                      Color(0xffcc2b5e),
                                      Color(0xff753a88)
                                    ],
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
                                    Image.network(
                                      post.thumbnailUrl ?? '',
                                      fit: BoxFit.cover,
                                      frameBuilder: (context, child, frame,
                                          wasSynchronouslyLoaded) {
                                        return child;
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.error_outline,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
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
                                )
                          : Stack(
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
                                    : Image.network(
                                        post.thumbnailUrl ?? '',
                                        fit: BoxFit.cover,
                                        frameBuilder: (context, child, frame,
                                            wasSynchronouslyLoaded) {
                                          return child;
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.error_outline,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
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
                            ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGuidesGrid(String userId) {
    return Consumer2<UploadProvider, PostProvider>(
      builder: (context, uploadProvider, postProvider, child) {
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.width > 600;
        final isLargeScreen = screenSize.width > 800;

        // Responsive aspect ratio and spacing
        final childAspectRatio = isLargeScreen ? 3.5 : (isTablet ? 3.2 : 2.8);
        final gridPadding = isTablet ? AppSpacing.sm : AppSpacing.xs;
        final mainAxisSpacing = isTablet ? 12.0 : 8.0;

        return FutureBuilder<List<PostModel>>(
          future: _fetchUserGuides(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print(snapshot.error);
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final posts = snapshot.data ?? [];

            if (posts.isEmpty) {
              return const Center(
                child: Text(
                  'No Guides!',
                  style: AppTypography.headline,
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(gridPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ViewGuideScreen(
                          post: post,
                          isOwnProfile: false,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // Background image or gradient
                          post.thumbnailUrl?.isEmpty == true
                              ? Container(
                                  width: double.maxFinite,
                                  height: double.maxFinite,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white.withOpacity(0.7),
                                      size: isTablet ? 48 : 40,
                                    ),
                                  ),
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      post.thumbnailUrl ?? '',
                                      fit: BoxFit.cover,
                                      frameBuilder: (context, child, frame,
                                          wasSynchronouslyLoaded) {
                                        return child;
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primary
                                                    .withOpacity(0.7),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary,
                                                AppColors.primary
                                                    .withOpacity(0.7),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Dark overlay for better text readability
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                          // Guide icon
                          Positioned(
                            top: isTablet ? 12 : 8,
                            right: isTablet ? 12 : 8,
                            child: Container(
                              padding: EdgeInsets.all(isTablet ? 6 : 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: isTablet ? 20 : 16,
                              ),
                            ),
                          ),

                          // Content
                          Positioned(
                            left: isTablet ? 16 : 12,
                            right: isTablet ? 16 : 12,
                            bottom: isTablet ? 16 : 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Location
                                if (post.location.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 8 : 6,
                                      vertical: isTablet ? 4 : 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.fmd_good_outlined,
                                          color: Colors.white,
                                          size: isTablet ? 14 : 12,
                                        ),
                                        SizedBox(width: isTablet ? 4 : 2),
                                        Flexible(
                                          child: Text(
                                            post.location,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isTablet ? 12 : 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(height: isTablet ? 8 : 6),

                                // Title
                                Text(
                                  post.title.toUpperCase(),
                                  style: GoogleFonts.oswald(
                                    color: Colors.white,
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Share button
                          Positioned(
                            bottom: isTablet ? 12 : 8,
                            right: isTablet ? 12 : 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.share,
                                  color: Colors.white,
                                  size: isTablet ? 20 : 18,
                                ),
                                padding: EdgeInsets.all(isTablet ? 8 : 6),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<PostModel>> _fetchUserGuides(String userId) async {
    try {
      final supabase = Supabase.instance.client;

      // Query the guides table for this user's guides
      final response = await supabase
          .from('guides')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Convert guides to PostModel using the proper mapping
      return response
          .map((guide) => PostModel.fromMap(guide['id'], guide))
          .toList();
    } catch (e) {
      print('Error fetching guides: $e');
      return [];
    }
  }
}
