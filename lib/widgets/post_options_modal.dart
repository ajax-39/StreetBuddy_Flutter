import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/widgets/report_popup.dart';

import 'package:street_buddy/screens/MainScreens/Profile/view_profile_screen.dart';

typedef PostOptionCallback = void Function();

showPostOptionsModal(
  BuildContext context, {
  required String currentUserId,
  required String targetUserId,
  required String postId,
  PostOptionCallback? onShare,
}) =>
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => PostOptionsModal(
        onShare: onShare,
        currentUserId: currentUserId,
        targetUserId: targetUserId,
        postId: postId,
      ),
    );

class PostOptionsModal extends StatelessWidget {
  final PostOptionCallback? onShare;
  final String currentUserId;
  final String targetUserId;
  final String postId;

  const PostOptionsModal({
    super.key,
    this.onShare,
    required this.currentUserId,
    required this.targetUserId,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          OptionItem(
            imagePath: 'assets/icon/save-alt.png',
            title: 'Save',
            subtitle: 'Save for later',
            onTap: () async {
              Navigator.pop(context);
              final postProvider =
                  Provider.of<PostProvider>(context, listen: false);
              await postProvider.toggleSavePost(
                  userId: currentUserId, postId: postId);
              // Optionally, you can check if the post is now saved or unsaved for a more specific message
              final data = await postProvider.supabase
                  .from('users')
                  .select('saved_post')
                  .eq('uid', currentUserId)
                  .single();
              final List<String> savedPosts =
                  List<String>.from(data['saved_post'] ?? []);
              final isSaved = savedPosts.contains(postId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSaved
                      ? 'Post saved for later!'
                      : 'Post removed from saved!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          OptionItem(
            imagePath: 'assets/icon/share-alt.png',
            title: 'Share',
            subtitle: 'Share with friends or groups',
            onTap: () {
              if (onShare != null) {
                onShare!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Divider(height: 1),
          OptionItem(
            imagePath: 'assets/icon/unfollow.png',
            title: 'Unfollow',
            subtitle: 'Stop seeing posts from this creator',
            onTap: () async {
              debugPrint('Unfollow button pressed for user: $targetUserId');
              final shouldUnfollow = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Unfollow'),
                  content: const Text(
                      'Are you sure you want to unfollow this user?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Unfollow'),
                    ),
                  ],
                ),
              );
              debugPrint('Unfollow confirmation result: $shouldUnfollow');
              if (shouldUnfollow == true) {
                Navigator.pop(context);
                final profileProvider =
                    Provider.of<ProfileProvider>(context, listen: false);
                try {
                  debugPrint(
                      'Calling unfollowUser($currentUserId, $targetUserId)');
                  await profileProvider.unfollowUser(
                      currentUserId, targetUserId);
                  debugPrint('Unfollowed successfully');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unfollowed successfully!')),
                  );
                } catch (e) {
                  debugPrint('Failed to unfollow: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to unfollow: $e')),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          OptionItem(
            imagePath: 'assets/icon/hide.png',
            title: 'Hide Post',
            subtitle: 'Remove from your feed',
            onTap: () {
              Navigator.pop(context);
              final postProvider =
                  Provider.of<PostProvider>(context, listen: false);
              postProvider.hidePost(postId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post hidden from your feed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 1),
          OptionItem(
            imagePath: 'assets/icon/profile-circle.png',
            title: 'About this Account',
            subtitle: 'View account details',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewProfileScreen(
                    userId: targetUserId,
                    isOwnProfile: currentUserId == targetUserId,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          OptionItem(
            imagePath: 'assets/icon/report.png',
            title: 'Report',
            subtitle: '',
            titleColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              showReportPopup(context, postId: postId);
            },
          ),
        ],
      ),
    );
  }
}

class OptionItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const OptionItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              height: imagePath.contains('save') ? 35 : 25,
              width: 25,
              fit: BoxFit.cover,
              color: titleColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
