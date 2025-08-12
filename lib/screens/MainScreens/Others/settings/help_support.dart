import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/live_chat.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/feedback_form.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});

  Widget card({
    required String title,
    required String icon,
    required VoidCallback onTap,
    bool topRad = false,
    bool botRad = false,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: topRad ? const Radius.circular(12) : Radius.zero,
          bottom: botRad ? const Radius.circular(12) : Radius.zero,
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        textColor: Colors.black,
        iconColor: Colors.black,
        leading: Image.asset(
          icon,
          width: 22,
        ),
        title: Text(title),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: fontregular,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: topRad ? const Radius.circular(12) : Radius.zero,
            bottom: botRad ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.black,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: fontmedium,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: fontregular,
                        color: const Color(0xff1E1E1E).withOpacity(0.5),
                      ),
                      contentPadding: const EdgeInsets.only(left: 20),
                      prefixIconConstraints: const BoxConstraints(
                        maxHeight: 24,
                        maxWidth: 44,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset(
                          'assets/icon/search.png',
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(50),
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 157 / 77,
                  children: [
                    InkWell(
                      onTap: () async => await launchUrl(
                        Uri.parse('https://${ShareService().hostalt}/help/faq'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                            ),
                            Text(
                              'FAQs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LiveSupportScreen(),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_comment_outlined,
                              color: AppColors.primary,
                            ),
                            Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await launchUrl(
                          Uri.parse(
                            "mailto:${Constant.EMAIL_USERNAME}?subject=REPORT A PROBLEM",
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.report_problem_outlined,
                              color: AppColors.primary,
                            ),
                            Text(
                              'Report Problem',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        builder: (context) => const FeedbackForm(),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_outline_rounded,
                              color: AppColors.primary,
                            ),
                            Text(
                              'Give Feedback',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Popular Topics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                card(
                  topRad: true,
                  title: 'Account & Security',
                  icon: 'assets/icon/lock.png',
                  onTap: () async => await launchUrl(
                    Uri.parse('https://${ShareService().hostalt}/help/faq/1'),
                  ),
                ),
                card(
                  title: 'Payment Issues',
                  icon: 'assets/icon/cash.png',
                  onTap: () async => await launchUrl(
                    Uri.parse('https://${ShareService().hostalt}/help/faq/2'),
                  ),
                ),
                card(
                  title: 'App Navigation',
                  icon: 'assets/icon/pointer.png',
                  onTap: () async => await launchUrl(
                    Uri.parse('https://${ShareService().hostalt}/help/faq/3'),
                  ),
                ),
                card(
                  botRad: true,
                  title: 'Technical Problems',
                  icon: 'assets/icon/wrench.png',
                  onTap: () async => await launchUrl(
                    Uri.parse('https://${ShareService().hostalt}/help/faq/4'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Need More Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveSupportScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      elevation: 0,
                    ),
                    icon: Image.asset(
                      'assets/icon/live-chat.png',
                      width: 20,
                    ),
                    label: Text(
                      'Start Live Chat',
                      style: AppTypography.button.copyWith(
                        color: AppColors.buttonText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await launchUrl(
                          Uri.parse("mailto:${Constant.EMAIL_USERNAME}"));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      elevation: 0,
                    ),
                    icon: Image.asset(
                      'assets/icon/mail.png',
                      width: 20,
                    ),
                    label: Text(
                      'Email Support',
                      style: AppTypography.button.copyWith(
                        color: AppColors.buttonText,
                      ),
                    ),
                  ),
                ),
                const AspectRatio(aspectRatio: 2)
              ],
            ),
          ),
        ));
  }
}
