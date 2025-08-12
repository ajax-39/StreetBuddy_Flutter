import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/comment.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/widgets/ambassador.dart';
import 'package:street_buddy/widgets/like_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/Profile/view_profile_screen.dart';
import 'package:street_buddy/screens/MainScreens/home_page_screen.dart';
import 'package:street_buddy/widgets/custom_video_player.dart';
import 'package:street_buddy/widgets/heart_animation_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class PostDetailCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onCommentAdded;

  const PostDetailCard({
    super.key,
    required this.post,
    this.onCommentAdded,
  });

  @override
  State<PostDetailCard> createState() => _PostDetailCardState();
}

class _PostDetailCardState extends State<PostDetailCard>
    with AutomaticKeepAliveClientMixin {
  final _supabase = supabase.Supabase.instance.client;

  // Cache VIP status to avoid redundant calls
  final Map<String, bool> _userVipCache = {};

  // Local state for showing comments (default: false - show only first 3)
  bool _showAllComments = false;
  // Store loaded comments to avoid rebuilding

  @override
  bool get wantKeepAlive =>
      true; // Keep this widget alive when scrolled off screen

  void _navigateToProfile(BuildContext context, String userId) {
    final currentUser = globalUser;
    if (currentUser == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfileScreen(
          userId: userId,
          isOwnProfile: currentUser.uid == userId,
        ),
      ),
    );
  }

  Future<bool> _checkUserVIP(String userId) async {
    // Check cache first
    if (_userVipCache.containsKey(userId)) {
      return _userVipCache[userId]!;
    }

    try {
      final response = await _supabase
          .from('users')
          .select('is_vip')
          .eq('uid', userId)
          .single();

      final isVip = response['is_vip'] ?? false;
      // Cache the result
      _userVipCache[userId] = isVip;
      return isVip;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _getUserToken(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('token')
          .eq('uid', userId)
          .single();
      return response['token'];
    } catch (e) {
      return null;
    }
  }

  void _toggleShowAllComments() {
    setState(() {
      _showAllComments = !_showAllComments;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final currentUser = globalUser;
    if (currentUser == null) return const SizedBox.shrink();

    final postProvider = Provider.of<PostProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header - Rarely changes so doesn't need Consumer
          PostHeader(
            post: widget.post,
            onProfileTap: () => _navigateToProfile(context, widget.post.userId),
            checkUserVIP: _checkUserVIP,
          ),

          // Media Content with Heart Animation
          _buildMediaContent(context, postProvider, currentUser.uid),

          // Post Interactions (Likes, Comments)
          StreamBuilder<PostModel>(
            stream: postProvider.getPost(widget.post.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final updatedPost = snapshot.data!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  _buildActionButtons(
                      context, postProvider, updatedPost, currentUser),

                  // Like Count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${updatedPost.likes} ${updatedPost.likes == 1 ? 'like' : 'likes'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Post Description
                  if (widget.post.description.isNotEmpty)
                    _buildPostDescription(context),

                  // Comments Section - Optimized with local state
                  _buildCommentsSection(context, postProvider),

                  // Post Timestamp
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      timeago.format(widget.post.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(
      BuildContext context, PostProvider postProvider, String userId) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onDoubleTap: () {
            postProvider.toggleLike(
              widget.post,
              userId,
              globalUser?.name.toString() ?? '',
            );
            postProvider.showHeartAnimation(widget.post.id);
          },
          child: widget.post.type == PostType.image
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: MediaQuery.sizeOf(context).shortestSide,
                      maxHeight: MediaQuery.sizeOf(context).longestSide * 0.6),
                  child: CachedNetworkImage(
                    imageUrl: widget.post.mediaUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error, size: 40),
                      ),
                    ),
                  ),
                )
              : widget.post.type == PostType.video
                  ? CustomVideoPlayer(videoUrl: widget.post.mediaUrls.first)
                  : Container(),
        ),
        // Heart animation with selective Consumer
        Consumer<PostProvider>(
          builder: (context, provider, _) {
            return provider.isHeartAnimationVisible(widget.post.id)
                ? const HeartAnimationWidget()
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PostProvider postProvider,
      PostModel post, dynamic currentUser) {
    // Only listen to changes for this specific post's like status
    return Consumer<PostProvider>(
      builder: (context, provider, child) {
        final isLiked = provider.isPostLikedByUser(post, currentUser.uid);

        return Row(
          children: [
            LikeWidget(
              isLiked: isLiked,
              callback: () => provider.toggleLike(
                post,
                currentUser.uid,
                currentUser.name ?? 'Someone',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.comment_outlined),
              onPressed: () => provider.toggleCommentField(post.id),
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () =>
                  ShareService().sharePost(context, currentUser.uid, post),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '${widget.post.username} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _navigateToProfile(context, widget.post.userId),
            ),
            TextSpan(text: widget.post.description),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(
      BuildContext context, PostProvider postProvider) {
    return StreamBuilder<List<CommentModel>>(
      stream: postProvider.getPostComments(widget.post.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final comments = snapshot.data!;
        // Cache comments for future use

        // Determine which comments to display based on local state
        final displayComments =
            _showAllComments ? comments : comments.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show More/Less Comments Button
            if (comments.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: _toggleShowAllComments,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _showAllComments
                        ? 'Hide comments'
                        : 'View all ${comments.length} comments',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),

            // Comment items - using ListView.builder for better performance with larger lists
            ...displayComments.map((comment) => CommentItem(
                  comment: comment,
                  checkUserVIP: _checkUserVIP,
                  onProfileTap: (userId) => _navigateToProfile(context, userId),
                )),

            // Comment Input Field - only rebuild when comment field visibility changes
            Consumer<PostProvider>(
              builder: (context, provider, _) {
                if (!provider.isCommentFieldVisible(widget.post.id)) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      ProfileImage(
                        imageUrl: globalUser?.profileImageUrl,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller:
                              provider.getCommentController(widget.post.id),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final controller =
                              provider.getCommentController(widget.post.id);
                          if (controller.text.isNotEmpty) {
                            provider.addComment(widget.post, controller.text);
                            controller.clear();
                            if (widget.onCommentAdded != null) {
                              widget.onCommentAdded!();
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Extract PostHeader as a separate widget to avoid rebuilds
class PostHeader extends StatelessWidget {
  final PostModel post;
  final VoidCallback onProfileTap;
  final Future<bool> Function(String) checkUserVIP;

  const PostHeader({
    Key? key,
    required this.post,
    required this.onProfileTap,
    required this.checkUserVIP,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: onProfileTap,
        child: ProfileImage(imageUrl: post.userProfileImage),
      ),
      title: GestureDetector(
        onTap: onProfileTap,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              post.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            FutureBuilder<bool>(
              future: checkUserVIP(post.userId),
              builder: (context, snapshot) =>
                  snapshot.hasData && snapshot.data == true
                      ? const BrandAmbassadorBadge(
                          isVip: true,
                          color: Colors.black,
                        )
                      : const SizedBox(),
            )
          ],
        ),
      ),
      subtitle: post.location.isNotEmpty ? Text(post.location) : null,
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          final currentUser = globalUser;
          if (currentUser != null && post.userId == currentUser.uid) {
            _showPostOptions(context, post);
          }
        },
      ),
    );
  }

  void _showPostOptions(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Post'),
              onTap: () async {
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final postProvider =
                      Provider.of<PostProvider>(context, listen: false);
                  await postProvider.deletePost(post);

                  if (context.mounted) {
                    context.pop(); // Close loading dialog
                    context.pop(); // Close options dialog
                    context.pop(); // Return to previous screen

                    // Show success snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Post deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Pop loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Failed to delete post: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Optimized CommentItem with proper caching
class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final Future<bool> Function(String) checkUserVIP;
  final Function(String) onProfileTap;

  const CommentItem({
    Key? key,
    required this.comment,
    required this.checkUserVIP,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onProfileTap(comment.userId),
            child: ProfileImage(
              imageUrl: comment.userProfileImage,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => onProfileTap(comment.userId),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        comment.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<bool>(
                        future: checkUserVIP(comment.userId),
                        builder: (context, snapshot) =>
                            snapshot.hasData && snapshot.data == true
                                ? const BrandAmbassadorBadge(
                                    isVip: true,
                                    size: 15,
                                  )
                                : const SizedBox(),
                      )
                    ],
                  ),
                ),
                Text(comment.content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostDetailView extends StatefulWidget {
  final String initialPostId;
  final List<PostModel> posts;
  final int initialIndex;

  const PostDetailView({
    super.key,
    required this.initialPostId,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: 0, // Start at the top
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      // Use ListView.builder with keep alive functionality
      body: ListView.builder(
        controller: _scrollController,
        itemCount: widget.posts.length - widget.initialIndex,
        itemBuilder: (context, index) {
          final currentIndex = index + widget.initialIndex;
          final post = widget.posts[currentIndex];
          if (post.type == PostType.guide) return Container();

          return KeepAliveWrapper(
            child: PostDetailCard(
              key: ValueKey('post-${post.id}'),
              post: post,
              onCommentAdded: () {
                // Maintain scroll position when keyboard appears
                _scrollController.jumpTo(_scrollController.position.pixels);
              },
            ),
          );
        },
      ),
    );
  }
}

// Add this wrapper to ensure child widgets maintain state even when
// scrolled out of view in a ListView
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
