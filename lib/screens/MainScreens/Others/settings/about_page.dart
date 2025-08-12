import 'package:flutter/material.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/help_support.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/buttons/custom_leading_button.dart';

class StreetBuddyScreen extends StatelessWidget {
  const StreetBuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomLeadingButton(),
        title: const Text(
          'Street Buddy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: fontregular,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Placeholder for logo

              const SizedBox(height: 20),
              const Text(
                'Street Buddy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: fontregular,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Discover Your City Together',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: fontmedium,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              // Our Mission Card
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/icon/mission.png',
                            width: 25,
                            color: AppColors
                                .primary), // Changed from Color(0xFFFF7E36)
                        const SizedBox(width: 10),
                        const Text(
                          'Our Mission',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: fontregular,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'To transform urban exploration into an engaging adventure, connecting people with their cities in ways never imagined before.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Key Features Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Key Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Interactive Maps Feature
              _buildFeatureCard(
                icon: 'maps',
                title: 'Interactive Maps',
                description:
                    'Real-time discovery of nearby spots and events with AI-powered recommendations',
              ),
              const SizedBox(height: 15),
              // Rewards System Feature
              _buildFeatureCard(
                icon: 'star',
                title: 'Rewards System',
                description:
                    'Real-time discovery of nearby spots and events with AI-powered recommendations',
              ),
              const SizedBox(height: 15),
              // Community Engagement Feature
              _buildFeatureCard(
                icon: 'people',
                title: 'Community Engagement',
                description:
                    'Connect with fellow explorers and join local events and meetups',
              ),
              const SizedBox(height: 30),

              // NEW CONTENT STARTS HERE

              // Our Story Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Our Story',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Story image placeholder
              // Container(
              //   width: double.infinity,
              //   height: 174,
              //   decoration: BoxDecoration(
              //     color: Colors.grey[300],
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              // ),
              // const SizedBox(height: 15),
              const Text(
                'Started in 2023, Street Buddy was born from a passion for urban exploration and community building. What began as a simple idea to help people discover their cities has grown into a global community of urban adventurers.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: fontregular,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              // Community Impact Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Community Impact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: 'people 2',
                      value: '500K+',
                      label: 'Active Users',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      icon: 'pin-alt',
                      value: '1000+',
                      label: 'Cities',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: 'heart',
                      value: '2M+',
                      label: 'Places Shared',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      icon: 'rocket',
                      value: '4.8',
                      label: 'App Rating',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Testimonial
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: const NetworkImage(
                              'https://v0.dev/placeholder.svg'),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diwakar',
                              style: TextStyle(
                                fontWeight: fontmedium,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Kurnool, Andhra pradesh',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: fontregular,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '"Street Buddy has completely changed how I explore my city. I\'ve discovered amazing places I never knew existed!"',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: fontregular,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Connect With Us Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Connect With Us',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Social Media Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(icon: 'fb', color: Colors.blue),
                  const SizedBox(width: 30),
                  _buildSocialButton(icon: 'ig', color: Colors.pink),
                  const SizedBox(width: 30),
                  _buildSocialButton(icon: 'in', color: Colors.blue.shade700),
                ],
              ),
              const SizedBox(height: 20),
              // Contact Support Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HelpSupport())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: fontmedium,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Version & Updates Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Version & Updates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Current Version: 2.1.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: fontmedium,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Version History
              _buildVersionItem(
                version: 'Version 2.1.0',
                date: 'January 15, 2024',
                description: 'Enhanced AI recommendations, New reward system',
              ),
              const SizedBox(height: 15),
              _buildVersionItem(
                version: 'Version 2.0.0',
                date: 'December 1, 2023',
                description: 'Major UI overhaul, Community features added',
              ),
              const AspectRatio(aspectRatio: 3)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/icon/$icon.png',
                  width: 25,
                  color: AppColors.primary), // Changed from Color(0xFFFF7E36)
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: fontregular,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Image.asset('assets/icon/$icon.png',
              color: AppColors.primary,
              width: 24), // Changed from Color(0xFFFF7E36)
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: fontregular,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: fontmedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({required String icon, required Color color}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary
            .withOpacity(0.1), // Changed from Colors.orange.shade50
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Image.asset('assets/icon/$icon.png', width: 20),
        onPressed: () {},
      ),
    );
  }

  Widget _buildVersionItem({
    required String version,
    required String date,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              version,
              style: const TextStyle(
                fontWeight: fontregular,
                fontSize: 12,
              ),
            ),
            Text(
              date,
              style: const TextStyle(
                color: Color(0xff666666),
                fontWeight: fontregular,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: fontregular,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
