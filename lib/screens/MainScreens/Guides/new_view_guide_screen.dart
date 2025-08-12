import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:street_buddy/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/comment.dart';
import 'package:street_buddy/models/guide.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/widgets/custom_video_player.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:ui';

class ViewGuideScreen extends StatelessWidget {
  final PostModel post;
  final bool isOwnProfile;
  final supabase = Supabase.instance.client;

  ViewGuideScreen({
    super.key,
    required this.post,
    required this.isOwnProfile,
  });

  String _getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return Constant.DEFAULT_PLACE_IMAGE;
    }
    Uri? uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme == 'file' && (uri.path.isEmpty || uri.path == '/'))) {
      return Constant.DEFAULT_PLACE_IMAGE;
    }
    return url;
  }

  // Fetch similar guides based on location
  Future<List<PostModel>> _fetchSimilarGuides() async {
    try {
      final response = await supabase
          .from('guides')
          .select()
          .eq('location', post.location)
          .neq('id', post.id)
          .order('created_at', ascending: false)
          .limit(5);

      return response
          .map<PostModel>((data) => PostModel.fromMap(data['id'], data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching similar guides: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = globalUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Carousel Section
            Stack(
              children: [
                _buildImageCarousel(context),
                // Gradient overlay for better text visibility
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 40,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.arrow_left,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(CupertinoIcons.share,
                                  color: Colors.white),
                              onPressed: () => ShareService()
                                  .shareGuide(context, currentUser.uid, post),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Align(
                            alignment: Alignment.topRight,
                            child: FutureBuilder<bool>(
                                future: GuideProvider()
                                    .isGuideSaved(globalUser!.uid, post.id),
                                builder: (context, isSavedSnapshot) {
                                  bool isSaved = isSavedSnapshot.data ?? false;
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    return IconButton(
                                      color: Colors.white,
                                      icon: Icon(
                                        isSaved
                                            ? CupertinoIcons.heart_fill
                                            : CupertinoIcons.heart,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        await PostProvider()
                                            .toggleSaveGuideFromUsers(
                                                globalUser!.uid, post.id);
                                        setState(() {
                                          isSaved = !isSaved;
                                        });
                                      },
                                    );
                                  });
                                }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 10,
                  left: 20,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                            _getValidImageUrl(post.userProfileImage)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@${post.username}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                        ),
                        child: const Text('Follow'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Guide Information Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location_solid,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        post.location,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: post.tags
                          .map((tag) =>
                              _buildFeatureChip(tag, CupertinoIcons.tag_fill))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Places in the Guide Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Places in this Guide',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // Places list from guide_posts table
                  FutureBuilder<List<GuideModel>>(
                    future: GuideProvider().getGuidePosts(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildPlacesLoadingShimmer();
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Text(
                              'No places found in this guide.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }

                      final places = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          final place = places[index];
                          return _buildPlaceCard(context, place, index);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Likes Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Likes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Consumer<PostProvider>(
                    builder: (context, postProvider, child) {
                      return StreamBuilder<PostModel>(
                        stream: postProvider.getGuide(post.id),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final updatedPost = snapshot.data!;
                          final isLiked = postProvider.isPostLikedByUser(
                              updatedPost, currentUser.uid);
                          return FutureBuilder<bool>(
                            future: postProvider.isGuideDislikedByUser(
                                updatedPost.id, currentUser.uid),
                            builder: (context, dislikeSnapshot) {
                              final isDisliked = dislikeSnapshot.data ?? false;

                              return Row(
                                children: [
                                  _buildLikeButton(
                                    icon: CupertinoIcons.hand_thumbsup_fill,
                                    count: updatedPost.likes,
                                    isSelected: isLiked,
                                    onPressed: () =>
                                        postProvider.toggleLikeGuide(
                                      updatedPost,
                                      currentUser.uid,
                                      currentUser.name,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  _buildLikeButton(
                                    icon: CupertinoIcons.hand_thumbsdown_fill,
                                    count: updatedPost.dislikes,
                                    isSelected: isDisliked,
                                    onPressed: () =>
                                        postProvider.toggleDislikeGuide(
                                      updatedPost,
                                      currentUser.uid,
                                      currentUser.name,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Comments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comments (${post.comments})',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildCommentInputField(context),
                  const SizedBox(height: 20),
                  _buildCommentsSection(context, post.id),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Similar Guides Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Similar Guides',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 230,
                    child: FutureBuilder<List<PostModel>>(
                      future: _fetchSimilarGuides(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No similar guides found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        final guides = snapshot.data!;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: guides.length,
                          itemBuilder: (context, index) {
                            final guide = guides[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: _buildSimilarGuideCard(
                                context,
                                title: guide.title,
                                description: guide.description,
                                username: guide.username,
                                rating: guide.rating.toString(),
                                imageUrl: _getValidImageUrl(guide.thumbnailUrl),
                                userProfileImageUrl: guide.userProfileImage,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Place Card Widget
  Widget _buildPlaceCard(BuildContext context, GuideModel place, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place Number and Image
          Stack(
            children: [
              // Place Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: place.mediaUrls.isNotEmpty
                    ? _buildPlaceMedia(context, place)
                    : Image.asset(
                        'assets/map_placeholder.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),

              // Place Number Badge
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: 18,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Place Details
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Place Name
                Text(
                  place.placeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Place Type
                Row(
                  children: [
                    const Icon(CupertinoIcons.tag,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      place.place,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location coordinates if available
                if (place.lat != null && place.long != null)
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        '${place.lat!.toStringAsFixed(4)}, ${place.long!.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 15),

                // Place Description/Experience
                Text(
                  place.experience,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 15),

                // Additional Place Media as a horizontal list (thumbnails)
                if (place.mediaUrls.length > 1)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'More Photos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: place.mediaUrls.length -
                              1, // Skip the first one that's already displayed
                          itemBuilder: (context, mediaIndex) {
                            final mediaUrl = place.mediaUrls[mediaIndex + 1];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  // Show full-screen image viewer
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => _FullScreenImageView(
                                        imageUrls:
                                            List<String>.from(place.mediaUrls),
                                        initialIndex: mediaIndex + 1,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _getValidImageUrl(mediaUrl.toString()),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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

  // Helper method to handle different media types
  Widget _buildPlaceMedia(BuildContext context, GuideModel place) {
    final firstMediaUrl = place.mediaUrls.first.toString();

    if (firstMediaUrl.toLowerCase().endsWith('.mp4')) {
      return CustomVideoPlayer(
        videoUrl: firstMediaUrl,
      );
    } else {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _FullScreenImageView(
                imageUrls: List<String>.from(place.mediaUrls),
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Image.network(
          _getValidImageUrl(firstMediaUrl),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.error_outline, size: 40, color: Colors.grey),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildPlacesLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    final List<String> imageUrls = [
      if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty)
        post.thumbnailUrl!
      else if (post.mediaUrls.isNotEmpty)
        post.mediaUrls.first
      else
        Constant.DEFAULT_PLACE_IMAGE,
    ];

    if (post.mediaUrls.isNotEmpty) {
      for (var url in post.mediaUrls) {
        if (url != post.thumbnailUrl) {
          imageUrls.add(url);
        }
      }
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 300,
        viewportFraction: 1.0,
        enableInfiniteScroll: imageUrls.length > 1,
        autoPlay: imageUrls.length > 1,
      ),
      items: imageUrls.map((url) {
        return Builder(
          builder: (context) {
            return Stack(
              children: [
                // Blurred background for aspect ratio consistency
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Image.network(
                      _getValidImageUrl(url),
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.5),
                    ),
                  ),
                ),
                // Main image
                Center(
                  child: Image.network(
                    _getValidImageUrl(url),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Text('Image not available'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildLikeButton({
    required IconData icon,
    required int count,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.orange : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      backgroundColor: Colors.grey[200],
      avatar: Icon(icon, size: 16, color: Colors.grey[700]),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    );
  }

  Widget _buildSimilarGuideCard(
    BuildContext context, {
    required String title,
    required String description,
    required String username,
    required String rating,
    required String imageUrl,
    required String userProfileImageUrl,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  _getValidImageUrl(imageUrl),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    color: Colors.white,
                    icon: const Icon(
                      CupertinoIcons.heart,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              _getValidImageUrl(userProfileImageUrl),
                            ),
                            radius: 10,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            username,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w500),
                          )
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.star_fill,
                            color: Colors.amber,
                            size: 10,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            rating,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Comment Input Field widget
  Widget _buildCommentInputField(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    return StatefulBuilder(builder: (context, setState) {
      return Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(
              globalUser?.profileImageUrl ?? Constant.DEFAULT_USER_IMAGE,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange,
            ),
            child: IconButton(
              icon: isSubmitting
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (commentController.text.trim().isEmpty) return;

                      setState(() => isSubmitting = true);

                      try {
                        final user = globalUser;
                        if (user == null) return;

                        // Get the current post provider
                        final postProvider =
                            Provider.of<PostProvider>(context, listen: false);

                        // Add comment - adjust this according to your PostProvider implementation
                        await postProvider.addComment(
                          post,
                          commentController.text.trim(),
                        );

                        commentController.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error submitting comment: $e')),
                        );
                      } finally {
                        setState(() => isSubmitting = false);
                      }
                    },
            ),
          ),
        ],
      );
    });
  }

  // Comments Section widget
  Widget _buildCommentsSection(BuildContext context, String postId) {
    // This is a simplified mock implementation since we don't have access to the actual comments functionality
    return FutureBuilder<List<CommentModel>>(
      future: Future.value(
          []), // Return empty list for now, implement actual comments retrieval later
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text('No comments yet.'),
            ),
          );
        }

        final comments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      comment.userProfileImage.isNotEmpty
                          ? comment.userProfileImage
                          : Constant.DEFAULT_USER_IMAGE,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '@${comment.username}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              timeago.format(comment.createdAt),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          comment.content,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Full Screen Image Viewer
class _FullScreenImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageView(
      {required this.imageUrls, required this.initialIndex});

  @override
  _FullScreenImageViewState createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: CarouselSlider(
            options: CarouselOptions(
              height: double.infinity,
              initialPage: widget.initialIndex,
              enableInfiniteScroll: false,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            items: widget.imageUrls.map((url) {
              return Builder(
                builder: (context) {
                  String validUrl = url;
                  if (url.isEmpty) {
                    validUrl = Constant.DEFAULT_PLACE_IMAGE;
                  }

                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      validUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Text(
                              'Image not available',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
