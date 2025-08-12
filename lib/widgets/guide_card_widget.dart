import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/widgets/smart_image_widget.dart';

class GuideCardWidget extends StatelessWidget {
  final PostModel guide;
  final VoidCallback? onTap;

  const GuideCardWidget({
    super.key,
    required this.guide,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          child: SmartImageWidget(
            imageUrl: _getValidImageUrl(guide.thumbnailUrl),
            fit: BoxFit.cover,
            placeholder: Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: FutureBuilder<bool>(
          future: GuideProvider().isGuideSaved(globalUser!.uid, guide.id),
          builder: (context, isSavedSnapshot) {
            bool isSaved = isSavedSnapshot.data ?? false;
            return StatefulBuilder(builder: (context, setState) {
              return GestureDetector(
                onTap: () async {
                  await PostProvider()
                      .toggleSaveGuideFromUsers(globalUser!.uid, guide.id);
                  setState(() {
                    isSaved = !isSaved;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSaved ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    color: isSaved ? Colors.red : Colors.grey[600],
                    size: 18,
                  ),
                ),
              );
            });
          }),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleAndShareSection(),
          const SizedBox(height: 12),
          _buildUserAndRatingSection(),
        ],
      ),
    );
  }

  Widget _buildTitleAndShareSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guide.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                guide.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildShareButton(),
      ],
    );
  }

  Widget _buildShareButton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Icon(
        Icons.share_outlined,
        size: 20,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildUserAndRatingSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildUserInfo(),
        _buildRating(),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: ClipOval(
            child: SmartImageWidget(
              imageUrl: guide.userProfileImage,
              fit: BoxFit.cover,
              placeholder: Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "@${guide.username}",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 4),
        const Text(
          '4.5',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
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
}
