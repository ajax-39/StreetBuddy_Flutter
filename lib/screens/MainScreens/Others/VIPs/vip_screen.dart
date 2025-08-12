import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/utils/styles.dart';

class VIPScreen extends StatefulWidget {
  const VIPScreen({super.key});

  @override
  State<VIPScreen> createState() => _VIPScreenState();
}

class _VIPScreenState extends State<VIPScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section with VIP logo
              Container(
                color: const Color(0xFFFF8C3B),
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          height: 80,
                          width: 80,
                          'assets/icon/vip.png',
                          scale: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unlock Elite Travel Experiences',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SFUI',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Join the exclusive community of premium explorers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'SFUI',
                      ),
                    ),
                  ],
                ),
              ),

              // VIP Privileges
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VIP Privileges',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SFUI',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Privileges list
                    _buildPrivilegeCard(
                      icon: Icons.headphones,
                      color: Colors.deepPurple,
                      title: 'Add Free Experience',
                      subtitle: 'No interruptions',
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.flash_on,
                      color: Colors.orange,
                      title: 'Faster Access',
                      subtitle: 'Early access to newly listed hidden gems',
                      bgColor: const Color(0xFFFFF0E6),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.verified_user,
                      color: Colors.red,
                      title: 'Verified VIP Badge',
                      subtitle: 'Stand out with an exclusive profile badge',
                      bgColor: const Color(0xFFFFEEEE),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.article,
                      color: Colors.blue,
                      title: 'Premium Content',
                      subtitle: 'Exclusive guides and secret travel spots',
                      bgColor: const Color(0xFFE6F4FF),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.people,
                      color: Colors.green,
                      title: 'VIP Networking',
                      subtitle: 'Access to elite traveler\'s community',
                      bgColor: const Color(0xFFE6FFE6),
                    ),
                    _buildPrivilegeCard(
                      icon: Icons.support_agent,
                      color: Colors.purple,
                      title: 'Priority Support',
                      subtitle: '24/7 direct chat with travel experts',
                      bgColor: const Color(0xFFF5E6FF),
                    ),

                    const SizedBox(height: 24),

                    // What VIP Members Say
                    const Text(
                      'What VIP Members Say',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SFUI',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Rating
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 20),
                        Icon(Icons.star, color: Colors.orange, size: 20),
                        Icon(Icons.star, color: Colors.orange, size: 20),
                        Icon(Icons.star, color: Colors.orange, size: 20),
                        Icon(Icons.star_border, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '4.9/5',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    const Text(
                      '90% of members recommend VIP',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontFamily: 'SFUI',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Testimonials
                    _buildTestimonial(
                      name: 'Diwakar',
                      role: 'Traveler, Explorer',
                      comment:
                          'VIP access transformed my travel experience. The exclusive spots are incredible!',
                    ),

                    const SizedBox(height: 12),

                    _buildTestimonial(
                      name: 'Aryan mishra',
                      role: 'Foodie, Explorer',
                      comment:
                          'Best investment for travelers. The community is amazing!',
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/vip/city-plans');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Upgrade to VIP Now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: fontmedium,
                            color: Colors.white,
                            fontFamily: 'SFUI',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Guarantees
                    const Center(
                      child: Text(
                        '7-day money-back guarantee',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'SFUI',
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Cancel anytime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'SFUI',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivilegeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Color? bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFF0E6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'SFUI',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      fontFamily: 'SFUI',
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

  Widget _buildTestimonial({
    required String name,
    required String role,
    required String comment,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'SFUI',
            ),
          ),
        ],
      ),
    );
  }
}
