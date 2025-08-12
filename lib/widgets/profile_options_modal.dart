import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/services/share_service.dart';
import 'package:street_buddy/widgets/report_popup.dart';

showProfileOptionsModal(BuildContext context, String userId) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => ProfileOptionsModal(userId: userId),
    );

class ProfileOptionsModal extends StatelessWidget {
  final String userId;

  const ProfileOptionsModal({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Safety & Control'),
                  // _buildOptionItem(
                  //   'assets/icon/mute.png',
                  //   'Mute User',
                  //   'Stop seeing posts or stories',
                  //   onTap: () {},
                  // ),
                  // _buildOptionItem(
                  //   'assets/icon/security.png',
                  //   'Restrict User',
                  //   'Limit unwanted interactions',
                  //   onTap: () {},
                  // ),
                  _buildOptionItem(
                    'assets/icon/block.png',
                    'Block User',
                    '',
                    textColor: Colors.red,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildOptionItem(
                    'assets/icon/report.png',
                    'Report User',
                    '',
                    textColor: Colors.red,
                    onTap: () {
                      Navigator.of(context).pop();
                      showReportPopup(context, userId: userId);
                    },
                  ),
                  const Divider(
                    color: Color(0xffE0E0E0),
                  ),
                  _buildSectionHeader('Profile Information'),
                  _buildOptionItem(
                    'assets/icon/profile-circle.png',
                    'About this User',
                    'View account details',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(
                    color: Color(0xffE0E0E0),
                  ),
                  _buildSectionHeader('Safety & Control'),
                  _buildOptionItem(
                    'assets/icon/link.png',
                    'Copy Profile Link',
                    '',
                    onTap: () {
                      Navigator.of(context).pop();
                      // Copy the same URL format as used in share modal
                      Clipboard.setData(const ClipboardData(
                          text: 'https://streetbuddy-bd84d.web.app'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile link copied to clipboard!')),
                      );
                    },
                  ),
                  _buildOptionItem(
                    'assets/icon/share-alt.png',
                    'Share Profile',
                    '',
                    onTap: () {
                      Navigator.of(context).pop();
                      // Get user data from provider and share profile
                      final profileProvider = context.read<ProfileProvider>();
                      profileProvider
                          .fetchUserDataFuture(userId)
                          .then((userData) {
                        ShareService()
                            .shareProfile(context, globalUser!.uid, userData);
                      });
                    },
                  ),
                  // _buildOptionItem(
                  //   'assets/icon/qr-code.png',
                  //   'QR Code',
                  //   '',
                  //   onTap: () {},
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  //option model
  Widget _buildOptionItem(
    String imagePath,
    String title,
    String subtitle, {
    Color textColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 24,
              height: 24,
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
                      fontWeight: FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.normal,
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
