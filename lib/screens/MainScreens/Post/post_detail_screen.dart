import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/comment.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/screens/MainScreens/Guides/view_guide_screen.dart';
import 'package:street_buddy/services/share_service.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final bool isEmbedded;
  final TextEditingController _commentController = TextEditingController();

  PostDetailScreen({
    super.key,
    required this.postId,
    this.isEmbedded = false,
  });

  Widget _buildCommentSection(BuildContext context, List<CommentModel> comments,
      PostProvider postProvider) {
    final showAllComments = postProvider.showAllComments(postId);
    final limitedComments =
        showAllComments ? comments : comments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comments.length > 3 && !showAllComments)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: GestureDetector(
              onTap: () => postProvider.toggleShowAllComments(postId),
              child: Text(
                'View all ${comments.length} comments',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ...limitedComments
            .map((comment) => _buildCommentTile(comment, postProvider)),
      ],
    );
  }

  Widget _buildCommentTile(CommentModel comment, PostProvider postProvider) {
    return StreamBuilder(
      stream: postProvider.getUserData(comment.userId),
      builder: (context, userSnapshot) {
        final username = userSnapshot.hasData
            ? userSnapshot.data!.username
            : comment.username;
        final profileImage = userSnapshot.hasData
            ? userSnapshot.data!.profileImageUrl
            : comment.userProfileImage;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(profileImage!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '$username ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: comment.content),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentField(
      BuildContext context, PostProvider postProvider, PostModel post) {
    if (!postProvider.isCommentFieldVisible(post.id)) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          TextButton(
            onPressed: () {
              if (_commentController.text.isNotEmpty) {
                postProvider.addComment(post, _commentController.text);
                _commentController.clear();
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Consumer<PostProvider>(
      builder: (context, postProvider, _) {
        return StreamBuilder<PostModel>(
          stream: postProvider.getPost(postId),
          builder: (context, postSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!postSnapshot.hasData) {
              return const Center(child: Text('Post not found'));
            }

            final post = postSnapshot.data!;
            final currentUser = globalUser;

            if (post.type == PostType.guide) {
              return ViewGuideScreen(
                  post: post, isOwnProfile: currentUser!.uid == post.userId);
            }

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          // Post Header
                          SliverToBoxAdapter(
                            child: StreamBuilder(
                              stream: postProvider.getUserData(post.userId),
                              builder: (context, userSnapshot) {
                                final username = userSnapshot.hasData
                                    ? userSnapshot.data!.username
                                    : post.username;
                                final profileImage = userSnapshot.hasData
                                    ? userSnapshot.data!.profileImageUrl
                                    : post.userProfileImage;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(profileImage!),
                                  ),
                                  title: Text(username),
                                  subtitle: Text(post.location),
                                );
                              },
                            ),
                          ),
                          // Post Media
                          SliverToBoxAdapter(
                            child: post.type == PostType.image
                                ? Image.network(
                                    post.mediaUrls.first,
                                    fit: BoxFit.cover,
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        post.mediaUrls.first,
                                        fit: BoxFit.cover,
                                      ),
                                      const Center(
                                        child: Icon(
                                          Icons.play_circle_filled,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          // Action Buttons and Post Info
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        post.likedBy.contains(currentUser?.uid)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: post.likedBy
                                                .contains(currentUser?.uid)
                                            ? Colors.red
                                            : null,
                                      ),
                                      onPressed: currentUser == null
                                          ? null
                                          : () => postProvider.toggleLike(
                                                post,
                                                currentUser.uid,
                                                currentUser.name.toString(),
                                              ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.comment_outlined),
                                      onPressed: () => postProvider
                                          .toggleCommentField(postId),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined),
                                      onPressed: () => ShareService().sharePost(
                                          context, currentUser!.uid, post),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark_border),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    '${post.likes} likes',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: StreamBuilder(
                                    stream:
                                        postProvider.getUserData(post.userId),
                                    builder: (context, userSnapshot) {
                                      final username = userSnapshot.hasData
                                          ? userSnapshot.data!.username
                                          : post.username;

                                      return RichText(
                                        text: TextSpan(
                                          style: DefaultTextStyle.of(context)
                                              .style,
                                          children: [
                                            TextSpan(
                                              text: '$username ',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: post.description),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Comments
                          StreamBuilder<List<CommentModel>>(
                            stream: postProvider.getPostComments(post.id),
                            builder: (context, commentsSnapshot) {
                              if (!commentsSnapshot.hasData) {
                                return const SliverToBoxAdapter(
                                    child: SizedBox());
                              }

                              final comments = commentsSnapshot.data!;
                              return SliverToBoxAdapter(
                                child: _buildCommentSection(
                                    context, comments, postProvider),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (currentUser != null)
                      _buildCommentField(context, postProvider, post),
                  ],
                ),
                // Loading overlay
                if (postProvider.isLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                // Error message
                if (postProvider.error != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          postProvider.error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );

    // If this is a standalone screen, wrap in Scaffold
    if (!isEmbedded) {
      content = Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: content,
      );
    }

    return content;
  }
}
