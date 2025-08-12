import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndPoliciesScreen extends StatelessWidget {
  final bool isBottomSheet;
  const TermsAndPoliciesScreen({super.key, this.isBottomSheet = false});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void showTermsAndPoliciesBottomSheet(BuildContext context) =>
      showModalBottomSheet(
        context: context,
        builder: (context) => ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          child: TermsAndPoliciesScreen(
            isBottomSheet: true,
          ),
        ),
      );
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // GifView.asset(
          //   'assets/bg/city.gif',
          //   fit: BoxFit.cover,
          //   frameRate: 20,
          // ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircleAvatar(
                        backgroundColor: AppColors.primary2,
                        child: IconButton(
                          color: AppColors.surfaceBackground,
                          icon: Icon(
                              isBottomSheet ? Icons.close : Icons.arrow_back),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        "Agree to the Street Buddy's terms and policies",
                        style: AppTypography.body2.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Contact Info Text
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body2,
                          children: [
                            const TextSpan(
                              text:
                                  'People who use our service may have uploaded your contact information to the Street Buddy. ',
                            ),
                            TextSpan(
                              text: 'Learn more',
                              style: AppTypography.link
                                  .copyWith(color: Colors.deepOrange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Terms Text
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body2,
                          children: [
                            const TextSpan(
                              text:
                                  'By tapping I agree, you agree to create an account and to the Street Buddy\'s ',
                            ),
                            TextSpan(
                              text: 'Terms, ',
                              style: AppTypography.link
                                  .copyWith(color: Colors.deepOrange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTypography.link
                                  .copyWith(color: Colors.deepOrange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Cookies Policy',
                              style: AppTypography.link
                                  .copyWith(color: Colors.deepOrange),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Privacy Policy Description
                      Text(
                        'The Privacy Policy describes the ways we can use the information we collect when you create an account. For example, we use this information to provide, personalize and improve our products, including ads.',
                        style: AppTypography.body2,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // I Agree Button
                      Visibility(
                        visible: !isBottomSheet,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/signup/profile');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary2,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child:
                                Text('I agree', style: AppTypography.button2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Visibility(
                        visible: !isBottomSheet,
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              context.go('/signin');
                            },
                            child: const Text(
                              'I already have an account',
                              style: AppTypography.link,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildO(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        "Agree to the Street Buddy's terms and policies",
                        style: AppTypography.headline.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Contact Info Text
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body,
                          children: [
                            const TextSpan(
                              text:
                                  'People who use our service may have uploaded your contact information to the Street Buddy. ',
                            ),
                            TextSpan(
                              text: 'Learn more',
                              style: AppTypography.link,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Terms Text
                      RichText(
                        text: TextSpan(
                          style: AppTypography.body,
                          children: [
                            const TextSpan(
                              text:
                                  'By tapping I agree, you agree to create an account and to the Street Buddy\'s ',
                            ),
                            TextSpan(
                              text: 'Terms, ',
                              style: AppTypography.link,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: AppTypography.link,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Cookies Policy',
                              style: AppTypography.link,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchURL(''),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Privacy Policy Description
                      const Text(
                        'The Privacy Policy describes the ways we can use the information we collect when you create an account. For example, we use this information to provide, personalize and improve our products, including ads.',
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // I Agree Button
                      Visibility(
                        visible: !isBottomSheet,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/signup/profile');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.xs),
                              ),
                            ),
                            child: const Text('I agree',
                                style: AppTypography.button),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Visibility(
                        visible: !isBottomSheet,
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              context.go('/signin');
                            },
                            child: const Text(
                              'I already have an account',
                              style: AppTypography.link,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
