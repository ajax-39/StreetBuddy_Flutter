import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/models/review.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/Location/bookmark_provider.dart';
import 'package:street_buddy/screens/MainScreens/Locations/add_review_bottomsheet.dart';
import 'package:street_buddy/services/review_service.dart';
import 'package:street_buddy/utils/review_sort.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/provider/MainScreen/Location/place_detail_provider.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';
import 'package:street_buddy/widgets/smart_image_widget.dart';
import 'package:street_buddy/widgets/smart_image_carousel.dart';
import 'dart:collection';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

extension StringExtension on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
}

class PlaceDetailsScreen extends StatefulWidget {
  final PlaceModel place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final ReviewService _reviewService = ReviewService();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    // Initial refresh
    debugPrint(widget.place.toString());
    _refreshController.add(null);
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  static const List<String> ORDERED_DAYS = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint('\n🏢 PLACE DETAILS DATA:');
    debugPrint('ID: ${widget.place.id}');
    debugPrint('Name: ${widget.place.name}');
    debugPrint('Rating: ${widget.place.rating}');
    debugPrint('Total Ratings: ${widget.place.userRatingsTotal}');
    debugPrint('Photo URL: ${widget.place.photoUrl}');
    debugPrint('Open Now: ${widget.place.openNow}');
    debugPrint('Vicinity: ${widget.place.vicinity}');
    debugPrint('Types: ${widget.place.types.join(", ")}');
    debugPrint('Description: ${widget.place.description}');
    debugPrint('Extras: ${widget.place.extras}');
    debugPrint('Tips: ${widget.place.tips}');
    debugPrint('Opening Hours: ${widget.place.openingHours}\n');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlaceDetailsProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const CustomLeadingButton(),
          actions: [
            // Share button
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Bookmark button
            Consumer<BookmarkProvider>(
              builder: (context, provider, _) => FutureBuilder<bool>(
                future: provider.isBookmarked(widget.place.id),
                builder: (context, snapshot) {
                  final isBookmarked = snapshot.data ?? false;
                  return CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                        isBookmarked
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: isBookmarked ? AppColors.primary : Colors.black,
                      ),
                      onPressed: () => provider.toggleBookmark(widget.place),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageHeader(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceHeader(),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoCards(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildActionButtons(context),
                    DottedBorder(
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(2),
                      color: Colors.black,
                      dashPattern: const [3, 3],
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => _showAddReviewDialog(context),
                        child: Container(
                          color: const Color(0xffFFE4E0),
                          height: 39,
                          width: 118,
                          child: const Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.black,
                                ),
                                Text('Add Review',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: fontregular,
                                      color: Colors.black,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildReviewSection(context),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    // debugPrint('📸 Loading image URLs: ${widget.place.mediaUrls}');

    return SizedBox(
      width: double.infinity,
      height: 400, // Increased height from square aspect ratio
      child: SmartImageCarousel.fromPlace(
        place: widget.place,
        height: 400,
        fit: BoxFit.cover,
        showErrorDetails: true,
        showIndicators: true,
        autoPlay: false,
        borderRadius: 0,
      ),
    );
  }

  Widget _buildPlaceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baseline widget showing open/closed status is commented out as requested
        // Baseline(
        //   baseline: -50,
        //   baselineType: TextBaseline.alphabetic,
        //   child: Row(
        //     children: [
        //       Container(
        //         decoration: BoxDecoration(
        //           borderRadius: BorderRadius.circular(20),
        //         ),
        //         child: Padding(
        //           padding:
        //               const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        //           child: Wrap(
        //             crossAxisAlignment: WrapCrossAlignment.center,
        //             spacing: 5,
        //             children: [
        //               CircleAvatar(
        //                 radius: 6,
        //                 backgroundColor: widget.place.openNow
        //                     ? AppColors.openGreen
        //                     : AppColors.closedRed,
        //               ),
        //               Text(
        //                 widget.place.openNow ? 'Open Now' : 'Closed',
        //                 style: AppTypography.caption.copyWith(
        //                     fontWeight: FontWeight.bold,
        //                     color: widget.place.openNow
        //                         ? AppColors.openGreen
        //                         : AppColors.closedRed),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Row(
          children: [
            Expanded(
              child: Text(widget.place.name, style: AppTypography.headline),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Dynamic rating display that updates with reviews
        StreamBuilder<List<ReviewModel>>(
          stream: _reviewService.getPlaceReviews(widget.place.id),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final reviews = snapshot.data!;
              final reviewsWithRating =
                  reviews.where((r) => r.rating != null).toList();

              if (reviewsWithRating.isNotEmpty) {
                final averageRating = reviewsWithRating
                        .map((r) => r.rating!)
                        .reduce((a, b) => a + b) /
                    reviewsWithRating.length;

                return Row(
                  children: [
                    const Icon(Icons.star,
                        color: AppColors.ratingYellow, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: AppTypography.body
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' (${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})',
                      style: AppTypography.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                );
              }
            }

            // Fallback to original place rating if no reviews with ratings
            if (widget.place.rating > 0) {
              return Row(
                children: [
                  const Icon(Icons.star,
                      color: AppColors.ratingYellow, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    widget.place.rating.toStringAsFixed(1),
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' (${widget.place.userRatingsTotal} ${widget.place.userRatingsTotal == 1 ? 'review' : 'reviews'})',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              );
            }

            // No rating available
            return const SizedBox.shrink();
          },
        ),
        _buildDescriptionSection(),
      ],
    );
  }

  String _getExtrasHeading() {
    if (widget.place.types.contains('restaurant') ||
        widget.place.types.contains('food')) {
      return 'What We Serve';
    } else if (widget.place.types.contains('lodging') ||
        widget.place.types.contains('hotel')) {
      return 'What We Offer';
    } else if (widget.place.types.contains('tourist_attraction')) {
      return 'What To Expect';
    } else if (widget.place.types.contains('transit_station')) {
      return 'Transit Information';
    } else {
      return 'Additional Information';
    }
  }

  Widget _buildDescriptionSection() {
    // debugPrint("place.desription: ${widget.place.toString()} ");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // // Description (if available)
        // if (!widget.place.description.isNullOrEmpty) ...[
        //   const SizedBox(height: AppSpacing.md),
        //   Text(
        //     'About',
        //     style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
        //   ),
        //   const SizedBox(height: AppSpacing.xs),
        //   Text(
        //     widget.place.description!,
        //     style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        //   ),
        // ],

        // Address (if available)
        if (widget.place.vicinity != null) ...[
          const SizedBox(height: AppSpacing.sm),
          // Text(
          //   'Address',
          //   style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(height: AppSpacing.xs),
          Text(
            widget.place.vicinity!,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],

        // Category-specific extras
        if (!widget.place.extras.isNullOrEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _getExtrasHeading(),
            style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.place.extras!,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],

        // Tips (if available)
        if (!widget.place.tips.isNullOrEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tips',
            style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.place.tips!,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],

        if (widget.place.priceRange != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  color: AppColors.textPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '₹${widget.place.priceRange!.minPrice} - ₹${widget.place.priceRange!.maxPrice} per person',
                style: AppTypography.body,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        if (widget.place.phoneNumber != null)
          _buildInfoCard(
            icon: Icons.phone,
            title: 'Call us',
            content: widget.place.phoneNumber!,
            color: AppColors.primary,
            onTap: () {
              //TODO: Add phone number functionality
            },
          ),
        if (widget.place.openingHours.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildOpeningHoursCard(),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppDecorations.card,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: AppTypography.cardTitle),
        subtitle: Text(content, style: AppTypography.body),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: onTap,
      ),
    );
  }

  Widget _buildOpeningHoursCard() {
    return ExpansionTile(
      leading: const Icon(Icons.access_time, color: AppColors.primary),
      title: const Text('Opening Hours', style: AppTypography.cardTitle),
      shape: const Border(),
      children: SplayTreeMap<String, String>.from(
              widget.place.openingHours,
              (a, b) =>
                  ORDERED_DAYS.indexOf(a).compareTo(ORDERED_DAYS.indexOf(b)))
          .entries
          .map((entry) {
        final timeRanges = entry.value.split(',');
        final formattedTimes =
            timeRanges.where((range) => range.trim().isNotEmpty).map((range) {
          final times = range.trim().split(RegExp(r'[-–—]'));
          if (times.length != 2) return range.trim();
          return '${_convert24To12Hour(times[0].trim())} - ${_convert24To12Hour(times[1].trim())}';
        }).join(', ');

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  entry.key,
                  style:
                      AppTypography.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(formattedTimes, style: AppTypography.body),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client
          .from('users')
          .stream(primaryKey: ['uid'])
          .eq('uid', globalUser?.uid ?? '')
          .limit(1),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildRegularActionButtons(context);
        }

        final userData = snapshot.data!.first;
        final isDev = userData['is_dev'] ?? false;

        return Column(
          children: [
            _buildRegularActionButtons(context),
            if (isDev) ...[
              const SizedBox(height: AppSpacing.md),
              // Dev Controls Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer Controls',
                      style: AppTypography.subtitle.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Edit Tags'),
                            onPressed: () => _showEditTagsDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete Place'),
                            onPressed: () =>
                                _showDeleteConfirmationDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRegularActionButtons(BuildContext context) {
    return const Row(
      children: [],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Consumer<PlaceDetailsProvider>(
      builder: (context, provider, _) {
        return StreamBuilder<List<ReviewModel>>(
          stream: _reviewService.getPlaceReviews(widget.place.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: AppDecorations.card,
                child: Text('Error: ${snapshot.error}',
                    style: AppTypography.body.copyWith(color: AppColors.error)),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            final reviews = provider.sortReviews(snapshot.data!);
            final statsFuture =
                provider.calculateRatingStats(reviews, widget.place.id);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reviews',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: fontmedium,
                      color: Colors.black,
                    )),
                const SizedBox(height: AppSpacing.md),
                _buildRatingSummary(context, statsFuture, reviews),
                _buildSortDropdown(context),
                _buildReviewsList(reviews),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRatingSummary(BuildContext context,
      Future<Map<String, double>> statsFuture, List<ReviewModel> reviews) {
    final provider = Provider.of<PlaceDetailsProvider>(context, listen: false);

    return FutureBuilder<Map<String, double>>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall Rating',
                            style: AppTypography.caption),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Text(
                              stats['average']!.toStringAsFixed(1),
                              style: AppTypography.headline.copyWith(
                                fontSize: 32,
                                color: Colors.amber[700],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRatingBar(stats['percent']!),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${reviews.length} reviews',
                                    style: AppTypography.caption,
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
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Previous implementation - navigate to internal map screen
                        // context.push(
                        //     '/map?latitude=${widget.place.latitude}&longitude=${widget.place.longitude}&placeName=${widget.place.name}');

                        // New implementation - open Google Maps
                        _launchGoogleMaps();
                      },
                      style: ElevatedButton.styleFrom(
                        // minimumSize: const Size.fromHeight(60),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                      ),
                      icon: Image.asset(
                        'assets/icon/map.png',
                        color: AppColors.buttonText,
                        width: 25,
                      ),
                      label: const Text('View on map',
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontSize: 14,
                            fontWeight: fontregular,
                          )),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Safety',
                    provider.calculateSafetyMetric(reviews),
                    Icons.security,
                    Colors.blue[700]!,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Cost',
                    provider.calculateCostMetric(reviews),
                    Icons.attach_money,
                    Colors.green[700]!,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingBar(double percent) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: FractionallySizedBox(
        widthFactor: percent / 100,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber[600]!, Colors.amber[700]!],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, double value,
      IconData icon, Color color) {
    final provider = Provider.of<PlaceDetailsProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            provider.getMetricLabel(value),
            style: AppTypography.body.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildMetricBar(value, color),
        ],
      ),
    );
  }

  Widget _buildMetricBar(double value, Color color) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, ReviewModel review) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: const Text('Are you sure you want to delete this review?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  await _reviewService.deleteReview(
                    reviewId: review.id,
                    placeId: review.placeId,
                    userId: review.userId,
                    emojis: review.emojis,
                  );
                } catch (e) {
                  debugPrint('Error deleting review: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(BuildContext context, ReviewModel review) {
    final provider = Provider.of<PlaceDetailsProvider>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('users')
          .select()
          .eq('uid', review.userId)
          .single(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final user = userData != null
            ? UserModel.fromMap(review.userId, userData)
            : null;
        final currentUser = globalUser;
        // final isCurrentUserReview = currentUser?.uid == review.userId;
        final isLiked = review.likes.contains(currentUser?.uid);

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Profile picture with navigation
                    GestureDetector(
                      onTap: () {
                        if (review.userId.isNotEmpty) {
                          // Navigate to profile screen
                          context.push('/profile?uid=${review.userId}');
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: ClipOval(
                          child: SmartImageWidget(
                            imageUrl: user?.profileImageUrl ?? '',
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Username with navigation
                          GestureDetector(
                            onTap: () {
                              if (review.userId.isNotEmpty) {
                                // Navigate to profile screen
                                context.push('/profile?uid=${review.userId}');
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.username ?? 'Anonymous',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  provider.formatDate(review.createdAt),
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () {
                                      if (currentUser != null) {
                                        _reviewService.toggleLike(
                                            review.id, currentUser.uid);
                                      }
                                    },
                                  ),
                                  Text('${review.likes.length}'),
                                ],
                              ),
                              if (currentUser?.uid == review.userId)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _showDeleteConfirmation(context, review),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (review.emojis != null && review.emojis!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: review.emojis!
                        .map((emoji) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                provider.getEmojiString(emoji),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (review.text != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.text!,
                    style: AppTypography.body,
                  ),
                ],
                // Display media images if available
                if (review.mediaUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: review.mediaUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              // Show full screen image
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.black,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: SmartImageWidget(
                                          imageUrl: review.mediaUrls[index],
                                          fit: BoxFit.contain,
                                          placeholder: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 40,
                                        right: 20,
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white, size: 30),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SmartImageWidget(
                                imageUrl: review.mediaUrls[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                // Display rating, safety, and cost if available
                if (review.rating != null ||
                    review.safety != null ||
                    review.cost != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (review.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text('${review.rating}/5',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.orange)),
                            ],
                          ),
                        ),
                      if (review.safety != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: review.safety == 'safe'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: review.safety == 'safe'
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                review.safety == 'safe'
                                    ? Icons.security
                                    : Icons.warning,
                                size: 14,
                                color: review.safety == 'safe'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                review.safety!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: review.safety == 'safe'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (review.cost != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCostColor(review.cost!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _getCostColor(review.cost!)
                                    .withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_money,
                                  size: 14, color: _getCostColor(review.cost!)),
                              const SizedBox(width: 4),
                              Text(
                                review.cost!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getCostColor(review.cost!),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddReviewDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: ReviewScreen(place: widget.place),
          // child: AddReviewBottomSheet(
          //   onSubmit: (emojis, text) async {
          //     final user = globalUser;
          //     if (user != null) {
          //       try {
          //         await _reviewService.addReview(
          //           place: widget.place,
          //           placeId: widget.place.id,
          //           userId: user.uid,
          //           emojis: emojis,
          //           text: text,
          //         );
          //         if (context.mounted) {
          //           Navigator.pop(context);

          //           // No need for manual refresh with properly configured Supabase stream
          //           // Just show confirmation
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(
          //               content: Text('Review added successfully'),
          //               duration: Duration(seconds: 2),
          //             ),
          //           );
          //         }
          //       } catch (e) {
          //         debugPrint('Error adding review: $e');
          //       }
          //     }
          //   },
          // ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Consumer<PlaceDetailsProvider>(
      builder: (context, provider, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: DropdownButton<ReviewSort>(
            value: provider.currentSort,
            isExpanded: true,
            underline: Container(),
            items: ReviewSort.values.map((sort) {
              return DropdownMenuItem(
                value: sort,
                child: Text(sort.label),
              );
            }).toList(),
            onChanged: (newSort) {
              if (newSort != null) {
                provider.updateSort(newSort);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
      itemBuilder: (context, index) =>
          _buildReviewItem(context, reviews[index]),
    );
  }

  String _convert24To12Hour(String time24) {
    try {
      final components = time24.trim().split(':');
      if (components.length != 2) return time24;

      int hours = int.parse(components[0]);
      final minutes = components[1];

      final period = hours >= 12 ? 'PM' : 'AM';
      hours = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);

      return '$hours:$minutes $period';
    } catch (e) {
      print('Error converting time: $e');
      return time24;
    }
  }

  Future<void> _showEditTagsDialog(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final tagController =
        TextEditingController(text: widget.place.types.join(', '));

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tags'),
        content: TextField(
          controller: tagController,
          decoration: const InputDecoration(
            hintText: 'Enter tags separated by commas',
            helperText: 'Example: restaurant, food, chinese',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              try {
                final tags = tagController.text
                    .split(',')
                    .map((e) => e.trim().toLowerCase())
                    .where((e) => e.isNotEmpty)
                    .toList();

                await supabase
                    .from('places')
                    .update({'types': tags}).eq('id', widget.place.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tags updated successfully')),
                  );
                  Navigator.pop(context);
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating tags: $error')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final supabase = Supabase.instance.client;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: const Text(
            'Are you sure you want to delete this place? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              try {
                // First delete all reviews for this place
                await supabase
                    .from('reviews')
                    .delete()
                    .eq('place_id', widget.place.id);

                // Then delete the place itself
                await supabase
                    .from('places')
                    .delete()
                    .eq('id', widget.place.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Place deleted successfully')),
                  );
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                }
              } catch (error) {
                if (context.mounted) {
                  debugPrint('Error deleting place: $error');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting place: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchGoogleMaps() async {
    final double lat = widget.place.latitude;
    final double lng = widget.place.longitude;

    // Try to open Google Maps app first, then fallback to web
    final String googleMapsUrl = 'google.navigation:q=$lat,$lng';
    final String webUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=${widget.place.id}';
    final String fallbackUrl = 'https://www.google.com/maps/@$lat,$lng,15z';

    try {
      // Try Google Maps app first
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      } else {
        // Fallback to web browser
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Final fallback
      try {
        await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Could not launch Google Maps: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getCostColor(String cost) {
    switch (cost.toLowerCase()) {
      case 'affordable':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'expensive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
