import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/services/voice_search_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class ExplorePeopleScreen extends StatefulWidget {
  const ExplorePeopleScreen({super.key});

  @override
  State<ExplorePeopleScreen> createState() => _ExplorePeopleScreenState();
}

class _ExplorePeopleScreenState extends State<ExplorePeopleScreen> {
  final VoiceSearchService _voiceSearchService = VoiceSearchService();
  bool _isVoiceSearching = false;
  bool _isListening = false;
  String _voiceSearchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _voiceSearchService.dispose();
    super.dispose();
  }

  Future<void> _startVoiceSearch() async {
    setState(() {
      _isVoiceSearching = true;
      _voiceSearchText = '';
    });
    final initialized = await _voiceSearchService.initialize();
    if (!initialized) {
      _stopVoiceSearch();
      return;
    }
    setState(() {
      _isListening = true;
    });
    await _voiceSearchService.startListening(
      onResult: (String result) {
        setState(() {
          _voiceSearchText = result;
          _searchController.text = result;
        });
        // No need to call setState again, Autocomplete will update
        _stopVoiceSearch();
      },
      onError: (String error) {
        _stopVoiceSearch();
      },
    );
  }

  Future<void> _stopVoiceSearch() async {
    await _voiceSearchService.stopListening();
    setState(() {
      _isVoiceSearching = false;
      _isListening = false;
      _voiceSearchText = '';
    });
  }

  void _handleVoiceSearch() async {
    if (_isListening) {
      await _stopVoiceSearch();
    } else {
      await _startVoiceSearch();
    }
  }

  Widget _buildMicIcon() {
    if (_isListening) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        child: const Icon(
          Icons.mic,
          color: AppColors.primary,
          size: 22,
        ),
      );
    } else if (_isVoiceSearching) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    } else {
      return Image.asset(
        'assets/icon/mic.png',
        height: 16,
        width: 16,
        color: AppColors.textSecondary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Search Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable.empty();
                } else {
                  try {
                    var query = textEditingValue.text.toLowerCase().trim();
                    final data = await supabase
                        .from('users')
                        .select('*')
                        .ilike(
                            'username', '%$query%') // Case-insensitive search
                        .neq('uid', globalUser?.uid ?? '')
                        .limit(10);
                    return data.map((e) => {
                          'username': e['username'],
                          'uid': e['uid'],
                          'name': e['name'],
                          'profileImageUrl': e['profile_image_url'],
                        });
                  } catch (e) {
                    return const Iterable.empty();
                  }
                }
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        var item = options.elementAt(index);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          title: Text(
                            item['username'],
                            style: AppTypography.body,
                          ),
                          subtitle: Text(
                            item['name'],
                            style: AppTypography.caption,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: item['profileImageUrl'] != null
                                ? NetworkImage(item['profileImageUrl'])
                                : null,
                            child: item['profileImageUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          onTap: () {
                            context.push('/profile?uid=${item['uid']}');
                          },
                        );
                      },
                    ),
                  ),
                );
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                _searchController.text = textEditingController.text;
                return SizedBox(
                  height: 48,
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Find peoples, explorers.....',
                      hintStyle: AppTypography.searchBar,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              icon: const Icon(Icons.clear),
                              onPressed: () => textEditingController.clear(),
                            )
                          : IconButton(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              onPressed: _handleVoiceSearch,
                              icon: _buildMicIcon(),
                            ),
                      prefixIconConstraints: const BoxConstraints(
                        maxHeight: 24,
                        maxWidth: 44,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: Image.asset(
                          'assets/icon/search.png',
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xffF6F6F6),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                );
              },
            ),
          ),
          // const SizedBox(height: AppSpacing.lg),
          // Filter Chips Section (commented out)
          // Center(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          //     child: _buildFilterChips(),
          //   ),
          // ),
          // const SizedBox(height: AppSpacing.xl),
          // People List Section
          _buildExplorePeopleList(context),
          const SizedBox(height: AppSpacing.xl),
          // Recent Activity Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Recent activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder(
              future: getActivity(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }

                final activities = snapshot.data ?? [];
                if (activities.isEmpty) {
                  return const AspectRatio(
                    aspectRatio: 3 / 2,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.face,
                            size: 30,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'No Activity!',
                            style: AppTypography.headline,
                          ),
                          Text(
                            'Follow people to catch up with their activity!',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: activities.length,
                  itemBuilder: (context, index) => InkWell(
                    onTap: () => context.push(
                        '/${activities[index].type == PostType.guide ? 'guide' : 'post'}?id=${activities[index].id}'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundImage: NetworkImage(
                                  activities[index].userProfileImage),
                            ),
                            title: Text(
                              activities[index].username,
                              maxLines: 1,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'added a new ${activities[index].type == PostType.guide ? 'guide' : 'post'}.',
                              style: AppTypography.caption,
                            ),
                            trailing: Text(
                              timeago.format(activities[index].createdAt),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.normal,
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.heart,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                activities[index].likes.toString(),
                                style: AppTypography.caption,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              const Icon(
                                CupertinoIcons.bubble_right,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                activities[index].comments.toString(),
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildExplorePeopleList(BuildContext context) {
    return Consumer<ExploreProvider>(builder: (context, exploreProvider, _) {
      return FutureBuilder<List<UserModel>>(
          future: getPeople(exploreProvider.peopleFilter),
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
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        context.push('/profile?uid=${users[index].uid}');
                      },
                      child: _buildPeopleCard(users[index]),
                    );
                  },
                ),
              ),
            );
          });
    });
  }

  Widget _buildPeopleCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.md),
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                user.profileImageUrl ?? Constant.DEFAULT_USER_IMAGE,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user.city ?? '@${user.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 32,
            width: double.infinity,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      backgroundColor: isFollowing
                          ? Colors.transparent
                          : AppColors.primaryLight,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isFollowing
                              ? AppColors.border
                              : AppColors.primary,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

  Widget _buildFilterChips() {
    List filters = ['New users', 'Popular', 'Near by'];
    List filterEnums = [
      PeopleFilter.newest,
      PeopleFilter.popular,
      PeopleFilter.nearby,
    ];
    return Consumer<ExploreProvider>(builder: (context, exploreProvider, _) {
      int selectedIndex = filterEnums.indexOf(exploreProvider.peopleFilter);
      return SizedBox(
        height: 36,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: filters.map((filter) {
            int index = filters.indexOf(filter);
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : AppSpacing.xs,
                right: index == filters.length - 1 ? 0 : AppSpacing.xs,
              ),
              child: FilterChip(
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFFEF8F3),
                side: BorderSide(
                  color: selectedIndex == index
                      ? AppColors.primary
                      : AppColors.primary,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: TextStyle(
                  color: selectedIndex == index ? Colors.white : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 0,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(
                  filter,
                  textAlign: TextAlign.center,
                ),
                selected: selectedIndex == index,
                onSelected: (bool selected) async {
                  exploreProvider.setFilter(filterEnums[index]);
                  await getPeople(exploreProvider.peopleFilter);
                },
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
