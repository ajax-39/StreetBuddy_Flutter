import 'package:flutter/material.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/responsive_util.dart';

class ProfileAmbassadorCard extends StatelessWidget {
  final UserModel userData;
  final BuildContext context;
  const ProfileAmbassadorCard(
      {super.key, required this.userData, required this.context});

  double parseEngagementRate() {
    double likeRate = userData.totalLikes / 1000;
    double monthlyGuideRate = userData.guideCountMnt / 5;
    double guiderating = userData.avgGuideReview / 4;
    double total = (likeRate + monthlyGuideRate + guiderating) / 3;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtil.getPadding(context,
        small: 16.0, medium: 20.0, large: 24.0);

    final verticalPadding = ResponsiveUtil.getPadding(context,
        small: 8.0, medium: 10.0, large: 12.0);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding, vertical: verticalPadding),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 4,
              color: Color(0x88ED7014),
            )
          ],
          gradient: const LinearGradient(
            colors: [
              Color(0xffED7014),
              Color(0xDDFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.5],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed('/ambassador');
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffFFE6E6),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16).copyWith(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon/medal-reward.png',
                          width: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Become a Legendary Explorer...🔥',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: fontsemibold,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.primary,
                        backgroundColor: Colors.grey.shade100,
                        value: parseEngagementRate(),
                      ),
                    ),
                    const Text(
                      'You are just a few steps away from becoming a Brand Ambassador!',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: fontregular,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(0),
                        children: [
                          Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Image.asset(
                                  'assets/icon/location-pin-map.png',
                                  height: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userData.totalLikes.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Likes Received',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: fontregular),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Image.asset(
                                  'assets/icon/map.png',
                                  height: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userData.guideCount.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Guides Created',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: fontregular),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Image.asset(
                                  'assets/icon/star-check.png',
                                  height: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${userData.avgGuideReview}/5',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Avg Ratings',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: fontregular),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
