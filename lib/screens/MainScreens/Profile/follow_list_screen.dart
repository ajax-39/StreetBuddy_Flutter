import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/screens/MainScreens/Profile/view_profile_screen.dart';
import 'package:street_buddy/utils/styles.dart';

enum FollowListType { followers, following }

class FollowListScreen extends StatelessWidget {
  final String userId;
  final FollowListType type;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(type == FollowListType.followers ? 'Followers' : 'Following'),
        elevation: 1,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<UserModel>>(
            stream: type == FollowListType.followers
                ? provider.streamFollowers(userId)
                : provider.streamFollowing(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading ${type == FollowListType.followers ? 'followers' : 'following'}',
                    style: AppTypography.body.copyWith(color: Colors.red),
                  ),
                );
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return Center(
                  child: Text(
                    type == FollowListType.followers
                        ? 'No followers yet'
                        : 'Not following anyone',
                    style: AppTypography.body.copyWith(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserListTile(user: user);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserModel user;

  const _UserListTile({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ViewProfileScreen(
              userId: user.uid,
              isOwnProfile: false,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Profile Image
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? const Icon(Icons.person, size: 24, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${user.username}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.name,
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Follow Button
            Consumer<ProfileProvider>(
              builder: (context, provider, _) {
                final currentUserId = provider.userData?.uid;
                if (currentUserId == null || currentUserId == user.uid) {
                  return const SizedBox.shrink();
                }

                final isFollowing = user.isFollowedBy(currentUserId);

                return TextButton(
                  onPressed: () {
                    if (isFollowing) {
                      provider.unfollowUser(currentUserId, user.uid);
                    } else if (user.isPrivate) {
                      provider.requestFollow(currentUserId, user.uid);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Follow request sent!')));
                    } else {
                      provider.followUser(currentUserId, user.uid);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    backgroundColor:
                        isFollowing ? Colors.grey[200] : Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: AppTypography.button.copyWith(
                      color: isFollowing ? Colors.black : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
