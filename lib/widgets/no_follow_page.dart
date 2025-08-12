import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class NoFollowPage extends StatelessWidget {
  const NoFollowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/icon/blob.png',
                scale: 3,
              ),
              Image.asset(
                'assets/icon/pics.png',
                scale: 3,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Text Content
          const Text(
            'Ready to start your journey?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: fontsemibold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Follow fellow travelers and discover\namazing experiences',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1,
                color: Colors.black.withOpacity(0.6),
                fontSize: 16,
                fontWeight: fontregular,
              ),
            ),
          ),

          const SizedBox(height: 20),
          // Discover Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () => context.push('/people'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Discover People to Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: fontmedium,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
          // Suggested for You
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(
                'Suggested for You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: fontsemibold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<UserModel>>(
              future: getPeople(PeopleFilter.popular),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                List users = snapshot.data ?? [];
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                context
                                    .push('/profile?uid=${users[index].uid}');
                              },
                              child: _buildPeopleCard(users[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              })
        ],
      ),
    );
  }

  Widget _buildPeopleCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      width: 105,
      child: Column(
        children: [
          SizedBox(
            height: 74,
            width: 74,
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                user.profileImageUrl ?? Constant.DEFAULT_USER_IMAGE,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              user.city ?? '@${user.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 24,
            width: 85,
            child: Builder(builder: (context) {
              final currentUserId = globalUser?.uid;
              if (currentUserId == null || currentUserId == user.uid) {
                return const SizedBox.shrink();
              }

              bool isFollowing = user.isFollowedBy(currentUserId);
              return Consumer<ProfileProvider>(builder: (context, provider, _) {
                return StatefulBuilder(builder: (context, setState) {
                  return TextButton(
                    onPressed: () {
                      if (isFollowing) {
                        provider.unfollowUser(currentUserId, user.uid);
                      } else if (user.isPrivate) {
                        provider.requestFollow(currentUserId, user.uid);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Follow request sent!')));
                      } else {
                        provider.followUser(currentUserId, user.uid);
                      }
                      setState(() {
                        isFollowing = !isFollowing;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(),
                      backgroundColor: isFollowing
                          ? Colors.transparent
                          : AppColors.primaryLight,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(
                            color:
                                isFollowing ? Colors.black : AppColors.primary,
                            width: 0.5,
                          )),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                });
              });
            }),
          ),
        ],
      ),
    );
  }
}
