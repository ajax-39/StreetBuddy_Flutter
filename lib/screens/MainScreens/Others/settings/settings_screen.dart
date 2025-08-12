import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/screens/MainScreens/Others/VIPs/vip_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/about_page.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/data_usage.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/help_support.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/personal_info.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/privacy_settings.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/saved_post_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/search_history.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/security_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/terms_service.dart';
import 'package:street_buddy/screens/TestScreens/image_loading_test_screen.dart';
import 'package:street_buddy/screens/home_screen.dart';
import 'package:street_buddy/services/push_notification_service.dart';
import 'package:street_buddy/utils/responsive_util.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;

  Future<bool> _getVIPStatus() async {
    try {
      final user = globalUser;
      if (user == null) return false;

      final response = await supabase
          .from('users')
          .select('is_vip')
          .eq('uid', user.uid)
          .maybeSingle();

      // Handle the case where no record is found
      if (response == null) {
        // debugPrint('No user record found for uid: ${user.uid}');
        return false;
      }

      return response['is_vip'] ?? false;
    } catch (e) {
      // debugPrint('Error fetching VIP status: $e');
      return false;
    }
  }

  Future<void> _updateVIPStatus(bool value) async {
    try {
      final user = globalUser;
      // debugPrint('Supabase User: ${user?.uid}');
      if (user == null) return;

      final result = await supabase
          .from('users')
          .update({'is_vip': value})
          .eq('uid', user.uid)
          .select();

      debugPrint('Update result: $result');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('VIP status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating VIP status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update VIP status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget label(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtil.getPadding(context,
            small: 16, medium: 20, large: 24),
        vertical: 8,
      ).copyWith(top: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ResponsiveUtil.getFontSize(context,
              small: 13, medium: 14, large: 16),
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget card({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool topRad = false,
    bool botRad = false,
  }) {
    final horizontalMargin =
        ResponsiveUtil.getPadding(context, small: 16, medium: 20, large: 24);

    final iconSize = ResponsiveUtil.getIconSize(
      context,
      small: 20,
      medium: 22,
      large: 24,
    );

    final fontSize = ResponsiveUtil.getFontSize(
      context,
      small: 14,
      medium: 16,
      large: 18,
    );

    final trailingIconSize = ResponsiveUtil.getIconSize(
      context,
      small: 16,
      medium: 18,
      large: 20,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: topRad ? const Radius.circular(12) : Radius.zero,
            bottom: botRad ? const Radius.circular(12) : Radius.zero),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: ListTile(
        textColor: Colors.black87,
        iconColor: Colors.black87,
        leading: Icon(
          icon,
          size: iconSize,
        ),
        titleTextStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        title: Text(title),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: topRad ? const Radius.circular(12) : Radius.zero,
              bottom: botRad ? const Radius.circular(12) : Radius.zero),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.black87,
          size: trailingIconSize,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
              fontSize: ResponsiveUtil.getFontSize(
                context,
                small: 18,
                medium: 20,
                large: 22,
              ),
              fontWeight: FontWeight.w500,
              color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtil.getPadding(context,
                      small: 16, medium: 20, large: 24),
                  vertical: ResponsiveUtil.getPadding(context,
                      small: 12, medium: 14, large: 16)),
              padding: EdgeInsets.all(ResponsiveUtil.getPadding(context,
                  small: 14, medium: 17, large: 20)),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                gradient: RadialGradient(
                  colors: [
                    Color(0xffED7014),
                    Color(0xffFF8D3A),
                  ],
                  stops: [0.5, 1.0],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/icon/crown.png',
                        height: ResponsiveUtil.getIconSize(context,
                            small: 20, medium: 24, large: 28),
                        width: ResponsiveUtil.getIconSize(context,
                            small: 20, medium: 24, large: 28),
                      ),
                      SizedBox(
                          width: ResponsiveUtil.getPadding(context,
                              small: 4, medium: 5, large: 8)),
                      Text(
                        'Street Buddy VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtil.getFontSize(context,
                              small: 18, medium: 20, large: 22),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: ResponsiveUtil.getPadding(context,
                          small: 16, medium: 20, large: 24)),
                  ...[
                    'Ad-free experience',
                    'Priority support',
                    'Exclusive features'
                  ].map(
                    (e) => Padding(
                      padding: EdgeInsets.only(
                          bottom: ResponsiveUtil.getPadding(context,
                              small: 10, medium: 14, large: 16)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: ResponsiveUtil.getIconSize(context,
                                small: 18, medium: 20, large: 22),
                          ),
                          SizedBox(
                              width: ResponsiveUtil.getPadding(context,
                                  small: 4, medium: 5, large: 8)),
                          Text(
                            e,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtil.getFontSize(context,
                                  small: 12, medium: 14, large: 16),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtil.getResponsiveValue(context,
                        small: 44.0, medium: 48.0, large: 52.0),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VIPScreen(),
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtil.getPadding(context,
                              small: 10, medium: 12, large: 14),
                        ),
                      ),
                      child: Text(
                        'Upgrade to VIP',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: ResponsiveUtil.getFontSize(context,
                              small: 14, medium: 16, large: 18),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(
                    color: AppColors.textSecondary,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Account',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              NetworkImage(globalUser?.profileImageUrl ?? ''),
                          radius: 24,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              globalUser?.name ??
                                  globalUser?.username ??
                                  'name',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              globalUser?.email ?? 'email',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Dismiss',
                        barrierColor: Colors.black.withOpacity(0.5),
                        transitionDuration: const Duration(milliseconds: 200),
                        pageBuilder: (context, _, __) {
                          return Center(
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sign Out',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: fontmedium,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Are you sure you want to sign out?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: fontmedium,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              padding: EdgeInsets.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          TextButton(
                                            onPressed: () async {
                                              await Future.delayed(
                                                  const Duration(
                                                      milliseconds: 100));
                                              try {
                                                await Supabase
                                                    .instance.client.auth
                                                    .signOut();
                                                if (context.mounted) {
                                                  context.go('/signin');
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Failed to sign out: ${e.toString()}'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              padding: EdgeInsets.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'sign out',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      child: Wrap(
                        spacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: Colors.red,
                            size: 17,
                          ),
                          Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )),
            label('Accounts & Privacy'),
            card(
                topRad: true,
                title: 'Personal Information',
                icon: Icons.account_circle_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PersonalInfo()))),
            card(
                title: 'Privacy Settings',
                icon: Icons.privacy_tip_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrivacySettings()))),
            card(
                title: 'Security',
                icon: CupertinoIcons.shield,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SecurityScreen()))),
            card(
                botRad: true,
                title: 'Language',
                icon: Icons.translate_outlined,
                onTap: () => showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) => languages(),
                    )),
            label('Accounts & Privacy'),
            card(
                topRad: true,
                title: 'Notifications',
                icon: Icons.notifications_outlined,
                onTap: () => showModalBottomSheet(
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) => notifications(),
                    )),
            card(
                botRad: true,
                title: 'App Settings',
                icon: Icons.settings,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DataUsageScreen()))),
            label('Safety & Support'),
            card(
                topRad: true,
                botRad: true,
                title: 'Help & Support',
                icon: Icons.account_circle_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HelpSupport()))),
            label('Exploration'),
            card(
              topRad: true,
              title: 'Saved Posts',
              icon: Icons.bookmark_outline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedPostScreen(),
                ),
              ),
            ),
            card(
              title: 'Saved Places',
              icon: Icons.book_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialIndex: 3),
                ),
              ),
            ),
            card(
                title: 'Search History',
                icon: Icons.history_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchHistory()))),
            card(
                botRad: true,
                title: 'Register Business',
                icon: Icons.business_outlined,
                onTap: () => context.push('/business/add')),
            label('Legal'),
            card(
                topRad: true,
                title: 'Terms of Service',
                icon: Icons.description_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TermsOfServiceScreen()))),
            card(
                title: 'Image Loading Test',
                icon: Icons.speed_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ImageLoadingTestScreen()))),
            card(
                botRad: true,
                title: 'About Street Buddy',
                icon: Icons.info_outline,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StreetBuddyScreen()))),

            const SizedBox(height: 20),
            Center(child: Text('Version 1.0.0')),
            const SizedBox(height: 20),
            const AspectRatio(aspectRatio: 3)

            //////////////////////////////////
            // ListTile(
            //   leading: const Icon(Icons.business),
            //   title: const Text(
            //     'Register your Business',
            //     style: TextStyle(fontWeight: FontWeight.bold),
            //   ),
            //   subtitle: const Text(
            //       'Share your interesting place visitors might like'),
            //   onTap: () => context.push('/register'),
            // ),
            // const Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            //   child: Text(
            //     'Admin',
            //     style: AppTypography.link,
            //   ),
            // ),
            // FutureBuilder<bool>(
            //   future: _getVIPStatus(),
            //   builder: (context, snapshot) {
            //     return SwitchListTile(
            //       title: const Text('Dev Check Verify'),
            //       value: snapshot.data ?? false,
            //       onChanged: (value) async {
            //         await _updateVIPStatus(value);
            //         // Trigger rebuild
            //         setState(() {});
            //       },
            //     );
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.developer_mode),
            //   title: const Text('Dev Database'),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () async {
            //     await Future.delayed(const Duration(milliseconds: 100));
            //     if (context.mounted) {
            //       context.push('/dev/locationdb');
            //     }
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.public),
            //   title: const Text('Dev Notifications'),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () => context.push('/dev/notification'),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.wifi),
            //   title: const Text('Internet Test'),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () => context.push('/dev/internetcheck'),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.ads_click_rounded),
            //   title: const Text('Ads Test'),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () => context.push('/dev/ads_test'),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.supervised_user_circle),
            //   title: const Text('User Info'),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () => context.push('/dev/user_info'),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.business),
            //   title: const Text('Registry for businesses'),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () => context.push('/dev/registry'),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.report),
            //   title: const Text('Reports Monitor'),
            //   trailing: const Icon(Icons.arrow_forward_ios),
            //   onTap: () => context.push('/dev/reports'),
            // ),
          ],
        ),
      ),
    );
  }

  Widget notifications() {
    bool notifications = true;
    return StatefulBuilder(builder: (context, setState) {
      return FutureBuilder(
          future: supabase
              .from('users')
              .select('token')
              .eq('uid', globalUser?.uid ?? '')
              .single(),
          builder: (context, snapshot) {
            notifications = snapshot.data?['token'] != null;
            return Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('All Notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            )),
                        const Spacer(),
                        Switch(
                          value: notifications,
                          onChanged: (value) async {
                            if (value) {
                              await PushNotificationService()
                                  .getFirebaseMessagingToken();
                              setState(() {});
                            } else {
                              await supabase.from('users').update({
                                'token': null,
                              }).eq('uid', globalUser?.uid ?? '');
                            }
                            setState(() {});
                          },
                        )
                      ],
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          CupertinoIcons.bell,
                          size: 25,
                          color: Colors.blue,
                          weight: 50,
                        ),
                      ),
                      title: Text(
                        'All Notifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Turning this off will disable all alerts except security updates',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
    });
  }

  Widget languages() {
    String language = 'English (US)';
    return StatefulBuilder(builder: (context, setState) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Language Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                      dropdownColor: AppColors.cardBackground,
                      isExpanded: true,
                      value: language,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 30,
                        color: Colors.black,
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.normal, color: Colors.black),
                      items: [
                        DropdownMenuItem(
                            value: 'English (US)', child: Text('English (US)')),
                        DropdownMenuItem(
                            value: 'English (UK)', child: Text('English (UK)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          language = value.toString();
                        });
                      }),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm',
                    style: AppTypography.button.copyWith(
                      color: AppColors.buttonText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
