import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/MainScreen/edit_profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/Admin/admin_dashboard_screen.dart';
import 'package:street_buddy/screens/MainScreens/Guides/view_guide_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/settings_screen.dart';
import 'package:street_buddy/screens/MainScreens/Profile/edit_profile_screen.dart';
import 'package:street_buddy/screens/MainScreens/Post/post_detail_view.dart';
import 'package:street_buddy/screens/MainScreens/Profile/follow_list_screen.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/responsive_util.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/widgets/ambassador.dart';
import 'package:street_buddy/widgets/city_state_missing_modal.dart';
import 'package:street_buddy/screens/MainScreens/Profile/profile_ambassador_card.dart';
import 'package:street_buddy/screens/MainScreens/Profile/profile_posts_guides_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final _supabase = Supabase.instance.client;
  bool _isFirstLoad = true;
  UserModel? _previousUserData;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      if (_isFirstLoad) {
        _isFirstLoad = false;
        context.read<ProfileProvider>().initialize(uid);
        context.read<UploadProvider>().getCachedOrFreshUserPosts(uid);
        context.read<UploadProvider>().getCachedOrFreshUserGuides(uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer3<AuthenticationProvider, ProfileProvider, PostProvider>(
      builder: (context, authProvider, profileProvider, postProvider, child) {
        final userModel = authProvider.userModel ?? globalUser;

        if (userModel == null) {
          return const Scaffold(
            body: Center(
                child: Text('Authentication error. Please sign in again.')),
          );
        }

        if (profileProvider.userData != null && _previousUserData == null) {
          _previousUserData = profileProvider.userData;
        }

        final userData =
            profileProvider.userData ?? _previousUserData ?? userModel;

        return Scaffold(
          extendBodyBehindAppBar: true,
          // appBar: _buildAppBar(userData),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await context
                    .read<ProfileProvider>()
                    .fetchUserData(userData.uid);
                if (userData.state == null || userData.city == null) {
                  showMissingStateCityBottomSheet(context, userData.uid);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                        parent: animation, curve: Curves.easeInOut),
                    child: child,
                  );
                },
                child: _buildProfileContent(context, userData, profileProvider),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel userData,
      ProfileProvider profileProvider) {
    final isLoading = profileProvider.isLoading;
    final horizontalPadding = ResponsiveUtil.getPadding(
      context,
      small: AppSpacing.md,
      medium: AppSpacing.lg,
      large: AppSpacing.xl,
    );

    return Stack(
      children: [
        SingleChildScrollView(
          key: ValueKey<String>('profile-content-${userData.hashCode}'),
          physics: const AlwaysScrollableScrollPhysics(),
          controller: ScrollController(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackgroundImage(userData.coverImageUrl, uid: userData.uid),
              _buildActionButtons(context, userData),

              // Profile image with proper spacing
              Transform.translate(
                offset: const Offset(0, -100),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: _buildProfileImage(
                            context, userData.profileImageUrl),
                      ),
                    ],
                  ),
                ),
              ),

              // User info section with adjusted spacing
              Transform.translate(
                offset: const Offset(0, -80),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtil.getFontSize(
                            context,
                            small: 20,
                            medium: 22,
                            large: 24,
                          ),
                        ),
                      ),
                      if (userData.bio?.isNotEmpty ?? false) ...[
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: ResponsiveUtil.getWidthPercentage(context,
                              ResponsiveUtil.isTablet(context) ? 50 : 75),
                          child: Text(
                            userData.bio!,
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: ResponsiveUtil.getFontSize(
                                context,
                                small: 14,
                                medium: 15,
                                large: 16,
                              ),
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Stats section with better spacing
              Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
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
                            userData.followingCount.toString(), 'Following'),
                      ),
                      Container(
                        color: AppColors.border,
                        width: 1,
                        height: 40,
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
                            userData.followersCount.toString(), 'Followers'),
                      ),
                      Container(
                        color: AppColors.border,
                        width: 1,
                        height: 40,
                      ),
                      _buildStat(userData.postCount.toString(), 'Posts'),
                    ],
                  ),
                ),
              ),
              ProfilePostsGuidesSection(
                  userData: userData, supabase: _supabase),
            ],
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: _buildLoadingOverlay(),
          ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.3),
      child: const Center(
        child: ShimmerLoading(
          isLoading: true,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Card(
              elevation: 2,
              shape: CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(UserModel userData) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Expanded(
            child: Text(
              '@${userData.username}',
              style: AppTypography.headline.copyWith(color: Colors.white),
            ),
          ),
          BrandAmbassadorBadge(isVip: userData.isVIP),
        ],
      ),
      actions: const [
        SizedBox(width: AppSpacing.sm),
        SizedBox(width: AppSpacing.lg),
      ],
    );
  }

  Widget _privateButton(UserModel userData, BuildContext context) {
    bool value = userData.isPrivate;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: value ? Colors.white : null,
        foregroundColor:
            value ? AppColors.textPrimary : Colors.pinkAccent.shade700,
        side: BorderSide(color: value ? AppColors.border : Colors.pinkAccent),
      ),
      onPressed: () {
        Provider.of<ProfileProvider>(context, listen: false)
            .profilePrivateToggle(!value, userData.uid);
      },
      child: Icon(value ? Icons.lock_outline : Icons.lock_open_outlined),
    );
  }

  Widget _buildBackgroundImage(String? url, {required String uid}) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileProvider(),
      child: Builder(
        builder: (context) {
          final editProfileProvider = Provider.of<EditProfileProvider>(context);
          return Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: url ?? 'https://picsum.photos/400',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer(
                        gradient: AppColors.shimmerGradient,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (editProfileProvider.isCoverUploading)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    Positioned(
                      top: 2,
                      right: 20,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: IconButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              )),
                          icon: Image.asset(
                            'assets/icon/setting.png',
                            width: 18,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              backgroundColor: AppColors.surfaceBackground,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(AppSpacing.md)),
                              ),
                              builder: (BuildContext sheetContext) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.md),
                                        child: Text(
                                          'Choose Cover Picture',
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt,
                                            color: AppColors.primary),
                                        title: const Text('Take Photo',
                                            style: AppTypography.body),
                                        onTap: () {
                                          Navigator.pop(sheetContext);
                                          editProfileProvider.pickImage(
                                              ImageSource.camera, context,
                                              isCover: true, uid: uid);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library,
                                            color: AppColors.primary),
                                        title: const Text('Choose from Gallery',
                                            style: AppTypography.body),
                                        onTap: () {
                                          Navigator.pop(sheetContext);
                                          editProfileProvider.pickImage(
                                              ImageSource.gallery, context,
                                              isCover: true, uid: uid);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.close,
                                            color: AppColors.textSecondary),
                                        title: Text(
                                          'Cancel',
                                          style: AppTypography.body.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        onTap: () => Navigator.pop(context),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          icon: Image.asset(
                            'assets/icon/pen.png',
                            width: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _refreshProfileData(BuildContext context, String userId) {
    final overlay = LoadingOverlay.of(context);
    overlay.show();

    Future.wait([
      context.read<ProfileProvider>().fetchUserData(userId),
      context.read<UploadProvider>().refreshUserPosts(userId),
      context.read<UploadProvider>().refreshUserGuides(userId),
    ]).then((_) {
      overlay.hide();
    });
  }

  Widget _buildProfileImage(BuildContext context, String? imageUrl) {
    final profileProvider = context.watch<ProfileProvider>();
    final profileRadius = ResponsiveUtil.getResponsiveValue(context,
        small: 45.0, medium: 50.0, large: 60.0);

    final iconSize = ResponsiveUtil.getResponsiveValue(context,
        small: 45.0, medium: 50.0, large: 60.0);

    if (profileProvider.isImageLoading) {
      return CircleAvatar(
        radius: profileRadius,
        backgroundColor: Colors.grey[200],
        child: const CircularProgressIndicator(),
      );
    }

    if (imageUrl == null ||
        imageUrl.isEmpty ||
        profileProvider.imageLoadError) {
      return CircleAvatar(
        radius: profileRadius,
        backgroundColor: Colors.grey[300],
        child: Icon(
          Icons.person,
          size: iconSize,
          color: Colors.grey,
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => EditProfileProvider(),
      child: Builder(
        builder: (context) {
          final editProfileProvider = Provider.of<EditProfileProvider>(context);
          return Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onLongPress: () => _showEnlargedProfilePic(imageUrl, context),
                child: Hero(
                  tag: 'profile-pic',
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: profileRadius * 2,
                      height: profileRadius * 2,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: const CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) {
                        profileProvider.setImageLoadError(true);
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.error,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (profileProvider.imageLoadError)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: profileProvider.retryLoadingImage,
                  color: Colors.black54,
                ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final userData =
                          context.read<AuthenticationProvider>().userModel ??
                              globalUser;
                      if (userData == null) return;

                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.surfaceBackground,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(AppSpacing.md)),
                        ),
                        builder: (BuildContext sheetContext) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Text(
                                    'Choose Profile Picture',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt,
                                      color: AppColors.primary),
                                  title: const Text('Take Photo',
                                      style: AppTypography.body),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    editProfileProvider.pickImage(
                                        ImageSource.camera, context,
                                        isCover: false, uid: userData.uid);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library,
                                      color: AppColors.primary),
                                  title: const Text('Choose from Gallery',
                                      style: AppTypography.body),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    editProfileProvider.pickImage(
                                        ImageSource.gallery, context,
                                        isCover: false, uid: userData.uid);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close,
                                      color: AppColors.textSecondary),
                                  title: Text(
                                    'Cancel',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(context),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: Image.asset(
                      'assets/icon/pen.png',
                      width: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(String count, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: ResponsiveUtil.getFontSize(
                context,
                small: 16,
                medium: 18,
                large: 20,
              ),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtil.getFontSize(
                context,
                small: 12,
                medium: 13,
                large: 14,
              ),
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVIPBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              'VIP Member',
              style: AppTypography.caption.copyWith(
                color: Colors.amber[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserModel userData) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Only show Admin Dashboard button for developers
          if (userData.isDev) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icon/people_2.png',
                        height: 14,
                        width: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Admin Dashboard',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostsGrid(String userId) {
    Future<void> updateTotalLikesCount(List<PostModel> posts) async {
      int m = 0;
      for (var i in posts) {
        m += i.likes;
      }
      await _supabase
          .from('users')
          .update({'total_likes': m}).eq('uid', userId);
    }

    return Consumer2<UploadProvider, PostProvider>(
      builder: (context, uploadProvider, postProvider, child) {
        final previousPosts = uploadProvider.previousUserPosts;

        return FutureBuilder<List<PostModel>>(
          future: uploadProvider.getCachedOrFreshUserPosts(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                previousPosts != null) {
              return Stack(
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: _buildPostsGridContent(
                        previousPosts, userId, uploadProvider, context),
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
              debugPrint('Posts future error: ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AspectRatio(
                aspectRatio: 3 / 2,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 200),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      direction: Axis.vertical,
                      children: [
                        Icon(Icons.auto_awesome_outlined, size: 30),
                        SizedBox(height: 10),
                        Text('No Posts!', style: AppTypography.headline),
                      ],
                    ),
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
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.0,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
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

  Widget _buildGuidesGrid(String userId) {
    Future<void> updateGuidesCount(String userId, int count) async {
      await _supabase
          .from('users')
          .update({'guide_count': count}).eq('uid', userId);
    }

    Future<void> updateMonthlyGuidesCount(
        String userId, List<PostModel> posts) async {
      int monthlyCount = posts.where((post) {
        var now = DateTime.now();
        return now.difference(post.createdAt).inDays <= 31;
      }).length;

      await _supabase
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

      await _supabase
          .from('users')
          .update({'avg_guide_review': avgRating}).eq('uid', userId);
    }

    return Consumer2<UploadProvider, PostProvider>(
      builder: (context, uploadProvider, postProvider, child) {
        return FutureBuilder<List<PostModel>>(
          future: uploadProvider.getCachedOrFreshUserGuides(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print(snapshot.error);
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AspectRatio(
                aspectRatio: 3 / 2,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 200),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      direction: Axis.vertical,
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 30,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'No Guides!',
                          style: AppTypography.headline,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final posts = snapshot.data!.toList();

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
              child: ListView.builder(
                key: ValueKey<String>(
                    'guides-grid-${DateTime.now().toString()}'),
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xs),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGuideItem(PostModel post, String userId, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        color: Colors.white,
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: post.thumbnailUrl ?? Constant.DEFAULT_PLACE_IMAGE,
            height: 120,
            width: double.maxFinite,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 120,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: fontsemibold,
                    color: Colors.black,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/icon/pin.png',
                                width: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  post.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: fontregular,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Image.asset(
                                'assets/icon/time 5.png',
                                scale: 4,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                timeago.format(post.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: fontregular,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icon/heart.png',
                              width: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${post.likes} saves',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: fontmedium,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Read More',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: fontmedium,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEnlargedProfilePic(String imageUrl, BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: 'profile-pic',
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerGridPlaceholder extends StatelessWidget {
  const ShimmerGridPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          isLoading: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
          ),
        );
      },
    );
  }
}

class LoadingOverlay {
  final BuildContext _context;
  OverlayEntry? _overlayEntry;

  LoadingOverlay._(this._context);

  static LoadingOverlay of(BuildContext context) {
    return LoadingOverlay._(context);
  }

  void show() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        opacity: 0.3,
        duration: const Duration(milliseconds: 250),
        child: Container(
          color: Colors.black26,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 80,
            height: 80,
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: ShimmerLoading(
                  isLoading: true,
                  child: Icon(Icons.refresh, size: 40),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(_context).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class ShimmerLoading extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Colors.grey,
                Colors.white,
                Colors.grey,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.2),
              end: const Alignment(1.0, 0.2),
              tileMode: TileMode.clamp,
              transform: SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SlidingGradientTransform extends GradientTransform {
  const SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class ShimmerProfilePlaceholder extends StatelessWidget {
  final UserModel? userData;

  const ShimmerProfilePlaceholder({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (userData != null)
          Opacity(
            opacity: 0.6,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 24,
                          width: 150,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 100,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ShimmerLoading(
          isLoading: true,
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
