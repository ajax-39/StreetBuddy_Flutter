import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/comment.dart';
import 'package:street_buddy/models/guide.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/tip.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/widgets/custom_video_player.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ViewGuideScreen extends StatefulWidget {
  final PostModel post;
  final bool isOwnProfile;

  const ViewGuideScreen({
    super.key,
    required this.post,
    required this.isOwnProfile,
  });

  @override
  State<ViewGuideScreen> createState() => _ViewGuideScreenState();
}

class _ViewGuideScreenState extends State<ViewGuideScreen> {
  final supabase = Supabase.instance.client;
  // Guide data state
  PostModel? _guideData;

  @override
  void initState() {
    super.initState();
    _loadGuideData();
  } // Load guide data once (non-realtime)

  Future<void> _loadGuideData() async {
    try {
      // Try to get the latest data from the database
      final response = await supabase
          .from('guides')
          .select()
          .eq('id', widget.post.id)
          .single();

      final updatedGuide = PostModel.fromMap(response['id'], response);

      if (mounted) {
        setState(() {
          _guideData = updatedGuide;
        });
      }
    } catch (e) {
      debugPrint('Error loading guide data: $e');
      if (mounted) {
        setState(() {
          _guideData = widget.post; // Fallback to original post
        });
      }
    }
  }

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
          .eq('location', widget.post.location)
          .neq('id', widget.post.id)
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

  // Fetch all media related to this guide
  Future<List<String>> _fetchGuideMedia() async {
    try {
      // First, get all media from the current guide
      List<String> mediaUrls = List<String>.from(widget.post.mediaUrls);

      // Then check if there are any posts associated with this guide
      final response = await supabase
          .from('posts')
          .select('media_urls')
          .eq('id', widget.post.id);

      // Add all media from associated posts
      for (var item in response) {
        if (item['media_urls'] != null) {
          List<dynamic> postMedia = item['media_urls'];
          for (var url in postMedia) {
            if (url is String && url.isNotEmpty && !mediaUrls.contains(url)) {
              mediaUrls.add(url);
            }
          }
        }
      }

      return mediaUrls;
    } catch (e) {
      debugPrint('Error fetching guide media: $e');
      return widget.post.mediaUrls;
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
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Navigation Bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(CupertinoIcons.arrow_left,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(CupertinoIcons.share,
                                  color: Colors.white, size: 20),
                              onPressed: () => ShareService().shareGuide(
                                  context, currentUser.uid, widget.post),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: FutureBuilder<bool>(
                                future: GuideProvider().isGuideSaved(
                                    globalUser!.uid, widget.post.id),
                                builder: (context, isSavedSnapshot) {
                                  bool isSaved = isSavedSnapshot.data ?? false;
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    return IconButton(
                                      icon: Icon(
                                        isSaved
                                            ? CupertinoIcons.heart_fill
                                            : CupertinoIcons.heart,
                                        color: isSaved
                                            ? Colors.orange
                                            : Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () async {
                                        await PostProvider()
                                            .toggleSaveGuideFromUsers(
                                                globalUser!.uid,
                                                widget.post.id);
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

                // Bottom User Info Section
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                              _getValidImageUrl(widget.post.userProfileImage)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@${widget.post.username}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Follow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),

            // Guide Information Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.post.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(
                    color: AppColors.textSecondary.withAlpha(100),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location_solid,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.post.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price and rating section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.money_dollar_circle,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '₹35 - ₹50 per person',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.star_fill,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.post.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: widget.post.tags
                          .map((tag) =>
                              _buildFeatureChip(tag, CupertinoIcons.tag_fill))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Map Section
            Column(
              children: [
                Stack(
                  children: [
                    FutureBuilder<List<GuideModel>>(
                      future: GuideProvider().getGuidePosts(widget.post.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                            ),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.orange)),
                          );
                        }

                        // Check if we have places with valid coordinates
                        if (!snapshot.hasData ||
                            snapshot.data!.isEmpty ||
                            snapshot.data!.every((place) =>
                                place.lat == null || place.long == null)) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/map_placeholder.png',
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        }

                        final validPlaces = snapshot.data!
                            .where((place) =>
                                place.lat != null && place.long != null)
                            .toList();

                        if (validPlaces.isEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/map_placeholder.png',
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        }

                        double centerLat = 0;
                        double centerLong = 0;
                        for (var place in validPlaces) {
                          centerLat += place.lat!;
                          centerLong += place.long!;
                        }
                        centerLat /= validPlaces.length;
                        centerLong /= validPlaces.length;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 250,
                            width: double.infinity,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(centerLat, centerLong),
                                initialZoom: 12.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.street_buddy.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    for (int i = 0; i < validPlaces.length; i++)
                                      Marker(
                                        width: 40,
                                        height: 40,
                                        point: LatLng(validPlaces[i].lat!,
                                            validPlaces[i].long!),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_pin,
                                              color: Colors.orange,
                                              size: 40,
                                            ),
                                            Positioned(
                                              top: 6,
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: Colors.orange,
                                                      width: 1),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${i + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Navigation Button positioned at bottom center of map
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final places = await GuideProvider()
                                .getGuidePosts(widget.post.id);

                            final validPlaces = places
                                .where((place) =>
                                    place.lat != null && place.long != null)
                                .toList();

                            if (validPlaces.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No valid locations found in this guide')));
                              return;
                            }

                            final destination =
                                '${validPlaces.last.lat},${validPlaces.last.long}';
                            final destinationName =
                                Uri.encodeComponent(validPlaces.last.placeName);

                            String waypoints = '';
                            String waypointNames = '';
                            if (validPlaces.length > 1) {
                              waypoints = '&waypoints=';
                              for (int i = 0; i < validPlaces.length - 1; i++) {
                                waypoints +=
                                    '${validPlaces[i].lat},${validPlaces[i].long}';
                                if (i < validPlaces.length - 2) {
                                  waypoints += '|';
                                }
                              }

                              waypointNames = '&waypoint_place_names=';
                              for (int i = 0; i < validPlaces.length - 1; i++) {
                                waypointNames += Uri.encodeComponent(
                                    validPlaces[i].placeName);
                                if (i < validPlaces.length - 2) {
                                  waypointNames += '|';
                                }
                              }
                            }

                            final url = 'https://www.google.com/maps/dir/?api=1'
                                '&destination=$destination'
                                '&destination_name=$destinationName'
                                '$waypoints'
                                '$waypointNames';

                            final Uri uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not launch Google Maps')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                          ),
                          child: const Text(
                            'Start Navigation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Itinerary Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Itinerary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Places list from guide_posts table
                  FutureBuilder<List<GuideModel>>(
                    future: GuideProvider().getGuidePosts(widget.post.id),
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
                          return _buildItineraryCard(context, place, index);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 16),

            // Likes and Comments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Likes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<PostProvider>(
                    builder: (context, postProvider, child) {
                      final currentGuide = _guideData ?? widget.post;
                      final isLiked = postProvider.isPostLikedByUser(
                          currentGuide, currentUser.uid);

                      return FutureBuilder<bool>(
                        future: postProvider.isGuideDislikedByUser(
                            currentGuide.id, currentUser.uid),
                        builder: (context, dislikeSnapshot) {
                          final isDisliked = dislikeSnapshot.data ?? false;

                          return Container(
                            width: 160,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await postProvider.toggleLikeGuide(
                                      currentGuide,
                                      currentUser.uid,
                                      currentUser.name,
                                    );
                                    _loadGuideData();
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.hand_thumbsup,
                                        color: isLiked
                                            ? Colors.orange
                                            : Colors.black,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentGuide.likes.toString(),
                                        style: TextStyle(
                                          color: isLiked
                                              ? Colors.orange
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () async {
                                    await postProvider.toggleDislikeGuide(
                                      currentGuide,
                                      currentUser.uid,
                                      currentUser.name,
                                    );
                                    _loadGuideData();
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.hand_thumbsdown,
                                        color: isDisliked
                                            ? Colors.red
                                            : Colors.black,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentGuide.dislikes.toString(),
                                        style: TextStyle(
                                          color: isDisliked
                                              ? Colors.red
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 16),

            // Comments Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCommentInputField(context),
                  const SizedBox(height: 20),
                  _buildCommentsSection(context, widget.post.id),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 16),

            // Travel Tips Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Travel Tips',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<TipModel>>(
                    future: GuideProvider().getGuideTips(widget.post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: Colors.orange, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'No tips available',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'This guide doesn\'t have any tips yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final tip = snapshot.data![index];
                            return _buildTipCard(tip);
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 16),

            // Photos Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Photos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to all photos view
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPhotosGrid(context),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Similar Guides Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Similar Guides',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: FutureBuilder<List<PostModel>>(
                      future: _fetchSimilarGuides(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildSimilarGuidesLoadingShimmer();
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No similar guides found.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        final similarGuides = snapshot.data!;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          itemCount: similarGuides.length,
                          itemBuilder: (context, index) {
                            final guide = similarGuides[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: index == similarGuides.length - 1
                                      ? 0
                                      : 16),
                              child: _buildSimilarGuideCard(
                                context,
                                title: guide.title,
                                description: guide.description,
                                username: guide.username,
                                rating: guide.rating.toStringAsFixed(1),
                                imageUrl: guide.mediaUrls.isNotEmpty
                                    ? guide.mediaUrls[0]
                                    : Constant.DEFAULT_PLACE_IMAGE,
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

  // New method for itinerary cards
  Widget _buildItineraryCard(
      BuildContext context, GuideModel place, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Place info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.placeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.place,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (place.experience.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      place.experience,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Place image
            if (place.mediaUrls.isNotEmpty)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_getValidImageUrl(place.mediaUrls[0])),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // New method for tip cards
  Widget _buildTipCard(TipModel tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                    _getValidImageUrl(widget.post.userProfileImage)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.post.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.orange,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tip',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip.tipText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: globalUser != null
                ? GuideProvider().getUserTipInteraction(tip.id, globalUser!.uid)
                : Future.value({'has_liked': false, 'has_disliked': false}),
            builder: (context, snapshot) {
              bool hasLiked = false;
              bool hasDisliked = false;

              if (snapshot.hasData) {
                hasLiked = snapshot.data!['has_liked'];
                hasDisliked = snapshot.data!['has_disliked'];
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 16,
                          color: hasLiked ? Colors.orange : Colors.grey,
                        ),
                        onPressed: () async {
                          if (globalUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please log in to like tips')),
                            );
                            return;
                          }
                          await GuideProvider().likeTip(tip.id, true);
                          setState(() {});
                        },
                      ),
                      Text(
                        '${tip.likes}',
                        style: TextStyle(
                          color: hasLiked ? Colors.orange : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          hasDisliked
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          size: 16,
                          color: hasDisliked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () async {
                          if (globalUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please log in to dislike tips')),
                            );
                            return;
                          }
                          await GuideProvider().likeTip(tip.id, false);
                          setState(() {});
                        },
                      ),
                      Text(
                        '${tip.dislikes}',
                        style: TextStyle(
                          color: hasDisliked ? Colors.red : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // New method for photos grid
  Widget _buildPhotosGrid(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _fetchGuideMedia(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildMediaGridLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text(
                'No photos available for this guide.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        final mediaUrls = snapshot.data!;
        final displayUrls = mediaUrls.take(6).toList(); // Show only first 6

        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: displayUrls.length,
              itemBuilder: (context, index) {
                final url = displayUrls[index];
                final isLast = index == displayUrls.length - 1;
                final hasMore = mediaUrls.length > 6;

                return GestureDetector(
                  onTap: () {
                    _showMediaFullscreen(context, url, mediaUrls, index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _getValidImageUrl(url),
                          fit: BoxFit.cover,
                        ),
                        if (isLast && hasMore)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                            ),
                            child: Center(
                              child: Text(
                                '+${mediaUrls.length - 6}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaDisplay(String url) {
    if (url.contains('mp4') || url.contains('video') || url.contains('mov')) {
      return CustomVideoPlayer(videoUrl: url);
    } else {
      return Image.network(
        _getValidImageUrl(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            Constant.DEFAULT_PLACE_IMAGE,
            fit: BoxFit.cover,
          );
        },
      );
    }
  }

  Widget _buildImageCarousel(BuildContext context) {
    if (widget.post.mediaUrls.isEmpty) {
      return Image.network(
        Constant.DEFAULT_PLACE_IMAGE,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 280,
        viewportFraction: 1.0,
        enableInfiniteScroll: widget.post.mediaUrls.length > 1,
        autoPlay: widget.post.mediaUrls.length > 1,
        autoPlayInterval: const Duration(seconds: 5),
      ),
      items: widget.post.mediaUrls.map((url) {
        if (url.contains('mp4') ||
            url.contains('video') ||
            url.contains('mov')) {
          return CustomVideoPlayer(videoUrl: url);
        } else {
          return Image.network(
            _getValidImageUrl(url),
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.network(
                Constant.DEFAULT_PLACE_IMAGE,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            },
          );
        }
      }).toList(),
    );
  }

  Widget _buildCommentInputField(BuildContext context) {
    final commentController = TextEditingController();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(
              _getValidImageUrl(globalUser?.profileImageUrl),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              String commentText = commentController.text.trim();
              if (commentText.isNotEmpty) {
                final provider =
                    Provider.of<PostProvider>(context, listen: false);
                await provider.addComment(
                  widget.post,
                  commentText,
                );
                commentController.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, String postId) {
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        return StreamBuilder<List<CommentModel>>(
          stream: postProvider.getPostComments(postId),
          builder: (context, snapshot) {
            // Get any local/optimistic comments
            final localComments = postProvider.getLocalComments(postId);

            // Handle error state - show error but keep the UI functional
            if (snapshot.hasError) {
              debugPrint('Comments stream error: ${snapshot.error}');

              // If we have local comments, still show them
              if (localComments.isNotEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Unable to load latest comments. Showing local comments only.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Force rebuild to retry
                              setState(() {});
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: localComments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentTile(localComments[index]);
                      },
                    ),
                  ],
                );
              }

              // No local comments, show error with retry
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.orange, size: 36),
                    const SizedBox(height: 8),
                    const Text('Unable to load comments'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Force rebuild to retry
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    )
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                localComments.isEmpty) {
              return Center(
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              );
            }

            final serverComments = snapshot.data ?? [];
            // Combine server comments with any local optimistic comments
            final allComments = [...localComments, ...serverComments];

            if (allComments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allComments.length,
              itemBuilder: (context, index) {
                final comment = allComments[index];
                return _buildCommentTile(comment);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCommentTile(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                NetworkImage(_getValidImageUrl(comment.userProfileImage)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(comment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with overlay
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_getValidImageUrl(imageUrl)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      CupertinoIcons.heart,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  // Bottom row with user and rating
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          _getValidImageUrl(userProfileImageUrl),
                        ),
                        radius: 12,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          username,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 22,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarGuidesLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 200,
                height: 230,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show media in fullscreen mode
  void _showMediaFullscreen(BuildContext context, String mediaUrl,
      List<String> allMediaUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: allMediaUrls.length,
            itemBuilder: (context, index) {
              final url = allMediaUrls[index];
              return Center(
                child: _buildMediaDisplay(url),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGridLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
