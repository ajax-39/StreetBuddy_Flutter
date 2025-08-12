import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/models/rating.dart';
import 'package:street_buddy/utils/styles.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final Function(List<PlaceEmoji>? emojis, String? text) onSubmit;

  const AddReviewBottomSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  Set<PlaceEmoji> selectedEmojis = {};
  final textController = TextEditingController();

  final List<Map<String, dynamic>> emojiCategories = [
    {
      'title': 'Overall Experience',
      'emojis': [
        PlaceEmoji.awesome,
        PlaceEmoji.great,
        PlaceEmoji.good,
        PlaceEmoji.meh,
        PlaceEmoji.bad,
        PlaceEmoji.terrible,
      ]
    },
    {
      'title': 'Safety',
      'emojis': [PlaceEmoji.safe, PlaceEmoji.unsafe]
    },
    {
      'title': 'Cost',
      'emojis': [PlaceEmoji.affordable, PlaceEmoji.expensive]
    },
  ];

  String _getEmojiString(PlaceEmoji emoji) {
    switch (emoji) {
      case PlaceEmoji.awesome:
        return '😍';
      case PlaceEmoji.great:
        return '😊';
      case PlaceEmoji.good:
        return '🙂';
      case PlaceEmoji.meh:
        return '😐';
      case PlaceEmoji.bad:
        return '😕';
      case PlaceEmoji.terrible:
        return '😡';
      case PlaceEmoji.safe:
        return '🛡️';
      case PlaceEmoji.unsafe:
        return '⚠️';
      case PlaceEmoji.expensive:
        return '💰';
      case PlaceEmoji.affordable:
        return '💵';
    }
  }

  String _getEmojiLabel(PlaceEmoji emoji) {
    return emoji.name.toUpperCase();
  }

  void toggleEmoji(PlaceEmoji emoji) {
    setState(() {
      if (selectedEmojis.contains(emoji)) {
        selectedEmojis.remove(emoji);
      } else {
        final category = emojiCategories.firstWhere(
          (cat) => (cat['emojis'] as List<PlaceEmoji>).contains(emoji),
        );
        selectedEmojis.removeWhere(
          (e) => (category['emojis'] as List<PlaceEmoji>).contains(e),
        );
        selectedEmojis.add(emoji);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Review', style: AppTypography.headline),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...emojiCategories.map((category) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category['title'], style: AppTypography.caption),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: (category['emojis'] as List<PlaceEmoji>)
                                .map((emoji) => GestureDetector(
                                      onTap: () => toggleEmoji(emoji),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: selectedEmojis.contains(emoji)
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.sm),
                                          border: selectedEmojis.contains(emoji)
                                              ? Border.all(color: Colors.blue)
                                              : null,
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              _getEmojiString(emoji),
                                              style:
                                                  const TextStyle(fontSize: 24),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _getEmojiLabel(emoji),
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      )),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add your detailed review (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              if (selectedEmojis.isEmpty &&
                  textController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please add either emojis or text review'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              widget.onSubmit(
                selectedEmojis.isEmpty ? null : selectedEmojis.toList(),
                textController.text.trim().isEmpty ? null : textController.text,
              );
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.md),
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }
}

class ReviewScreen extends StatefulWidget {
  final PlaceModel place;
  const ReviewScreen({super.key, required this.place});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _overallRating = 0;
  String _safetyRating = '';
  String _costRating = '';
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  List<File> _imageFiles = [];

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images =
          await ImagePicker().pickMultiImage(imageQuality: 60, limit: 5);
      if (images != null && images.length <= 5) {
        setState(() {
          _imageFiles = images.map((image) => File(image.path)).toList();
        });
      } else {
        // Handle the case where more than 5 images are picked
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can select up to 5 images only.')),
        );
      }
    } catch (e) {
      // Handle any errors that occur during the image picking process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<String> _uploadMedia(File file) async {
    try {
      final String postId = DateTime.now().millisecondsSinceEpoch.toString();
      String mediaUrl;

      final FirebaseStorage _storage = FirebaseStorage.instance;
      // For images, just upload to images folder
      final String imagePath = 'posts/images/$postId.jpg';
      final ref = _storage.ref().child(imagePath);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      mediaUrl = await snapshot.ref.getDownloadURL();

      return mediaUrl;
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black12, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  const Text(
                    'Add Your Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: fontregular,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey[300],
                            ),
                            child: const Icon(Icons.restaurant,
                                color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.place.name,
                                  style: const TextStyle(
                                    fontWeight: fontsemibold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.place.vicinity ??
                                      widget.place.city ??
                                      'Unknown',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: fontregular,
                                  ),
                                  softWrap: true,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: Colors.black12,
                    ),
                    // Overall Experience
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Experience',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: fontmedium,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildRatingItem(1, 'Terrible'),
                              _buildRatingItem(2, 'Bad'),
                              _buildRatingItem(3, 'Okay'),
                              _buildRatingItem(4, 'Good'),
                              _buildRatingItem(5, 'Awesome'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: Colors.black12,
                    ),

                    // Safety Rating
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Safety Rating',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: fontmedium,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _safetyRating = 'safe';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _safetyRating == 'safe'
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icon/safe.png',
                                          scale: 4,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Safe'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _safetyRating = 'unsafe';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _safetyRating == 'unsafe'
                                            ? Colors.red
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/icon/unsafe.png',
                                          scale: 4,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Unsafe'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: Colors.black12,
                    ),

                    // Cost
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cost',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: fontmedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _costRating = 'affordable';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _costRating == 'affordable'
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/icon/money.png',
                                          scale: 4,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Affordable'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _costRating = 'moderate';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _costRating == 'moderate'
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/icon/money.png',
                                              scale: 4,
                                            ),
                                            const SizedBox(width: 2),
                                            Image.asset(
                                              'assets/icon/money.png',
                                              scale: 4,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Moderate'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _costRating = 'expensive';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _costRating == 'expensive'
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/icon/money.png',
                                              scale: 4,
                                            ),
                                            const SizedBox(width: 2),
                                            Image.asset(
                                              'assets/icon/money.png',
                                              scale: 4,
                                            ),
                                            const SizedBox(width: 2),
                                            Image.asset(
                                              'assets/icon/money.png',
                                              scale: 4,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Expensive'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color: Colors.black12,
                    ),
                    // Review text
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffAAAAAA)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Share your thoughts about this place...',
                            hintStyle: TextStyle(
                              color: Color(0xffAAAAAA),
                              fontSize: 14,
                              fontWeight: fontregular,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Colors.black12,
                    ),

                    // Add Photos
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Photos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: fontmedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 66,
                            child: Row(
                              children: [
                                DottedBorder(
                                  borderType: BorderType.RRect,
                                  radius: const Radius.circular(10),
                                  padding: const EdgeInsets.all(0),
                                  child: InkWell(
                                    onTap: () => _pickImages(),
                                    child: Container(
                                      width: 60,
                                      height: 66,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/icon/image-plus.png',
                                          color: const Color(0xffBAB1B1),
                                          width: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      children: _imageFiles.map((imageFile) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: DottedBorder(
                                            borderType: BorderType.RRect,
                                            radius: const Radius.circular(10),
                                            padding: const EdgeInsets.all(0),
                                            child: Container(
                                              width: 60,
                                              height: 66,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.file(
                                                  imageFile,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList()),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_overallRating == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please add rating or text review'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            setState(() {
                              _isLoading = true;
                            });
                            List<String> imageUrls = [];
                            if (_imageFiles.isNotEmpty) {
                              for (var imageFile in _imageFiles) {
                                final data = await _uploadMedia(imageFile);
                                imageUrls.add(data);
                              }
                            }
                            await supabase.from('reviews').insert(
                              {
                                'place_id': widget.place.id,
                                'user_id': globalUser?.uid ?? '',
                                'rating': _overallRating,
                                'text': _textController.text.trim(),
                                'cost': _costRating,
                                'safety': _safetyRating,
                                'media_urls': imageUrls,
                              },
                            );
                            setState(() {
                              _isLoading = false;
                            });
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Review added successfully'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            debugPrint('Error adding review: $e');
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Review',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: fontmedium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingItem(int rating, String label) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _overallRating = rating;
            });
          },
          child: Icon(
            rating <= _overallRating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: rating <= _overallRating ? Colors.orange : Colors.black,
            size: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, fontWeight: fontregular, color: Colors.black),
        ),
      ],
    );
  }
}
