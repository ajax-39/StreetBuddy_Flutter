import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/user.dart';
import 'dart:async';

class BenefitItem {
  final String iconPath;
  final String title;
  final String description;

  BenefitItem({
    required this.iconPath,
    required this.title,
    required this.description,
  });
}

class AmbassadorScreen extends StatefulWidget {
  const AmbassadorScreen({super.key});

  static final List<BenefitItem> benefits = [
    BenefitItem(
      iconPath: 'assets/icon/star-check.png',
      title: 'Verified Badge',
      description: 'Get a special verification badge on your profile',
    ),
    BenefitItem(
      iconPath: 'assets/icon/money.png',
      title: 'Monetization opportunities',
      description:
          'Earn a share of ad revenue from their guides or reels on views and engagement',
    ),
    BenefitItem(
      iconPath: 'assets/icon/wrench.png',
      title: 'Exclusive Features',
      description: 'Access tp exclusive app features and analytics',
    ),
    BenefitItem(
      iconPath: 'assets/icon/rocket.png',
      title: 'Networking and Growth',
      description:
          'Opportunities to collaborate with local businesses, tourism boards,or Street Buddy events.',
    ),
  ];

  @override
  State<AmbassadorScreen> createState() => _AmbassadorScreenState();
}

class _AmbassadorScreenState extends State<AmbassadorScreen> {
  final _supabase = Supabase.instance.client;
  Timer? _timer;
  StreamController<Map<String, dynamic>>? _streamController;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<Map<String, dynamic>>();
    _startFetching();
  }

  void _startFetching() {
    _fetchUserData();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = globalUser;
      if (currentUser == null) {
        print('DEBUG: No Firebase user found');
        return;
      }

      print('DEBUG: Fetching data for uid: ${currentUser.uid}');

      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', currentUser.uid)
          .single();

      print('DEBUG: Supabase Response: ${response.toString()}');

      if (!_streamController!.isClosed) {
        _streamController!.add(response);
      }
    } catch (e) {
      print('DEBUG: Error fetching data: $e');
      if (!_streamController!.isClosed) {
        _streamController!.addError(e);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 77, 110, 255), // Solid blue background
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                title: const Text(
                  'Ambassador Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Gold/XP Card
                      _buildGoldXPCard(),
                      const SizedBox(height: 24),

                      // Top Ambassadors Section
                      _buildTopAmbassadorsSection(),
                      const SizedBox(height: 24),

                      // Your Position Section
                      _buildYourPositionSection(),
                      const SizedBox(height: 24),

                      // Active Challenges Section
                      _buildActiveChallengesSection(),
                      const SizedBox(height: 24),

                      // Benefits Section
                      _buildBenefitsSection(),
                      const SizedBox(height: 24),
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

  Widget _buildGoldXPCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/bg/animatedcity.gif',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.2),
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    'Gold',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '8,750 / 10,000 XP',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: LinearProgressIndicator(
                    value: 0.875, // 8750/10000
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Level up in 1,250 XP',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _selectedAmbassadorTimeframe = 0;

  Widget _buildTopAmbassadorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Ambassadors',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ToggleButtons(
            isSelected: [
              _selectedAmbassadorTimeframe == 0,
              _selectedAmbassadorTimeframe == 1
            ],
            onPressed: (int index) {
              setState(() {
                _selectedAmbassadorTimeframe = index;
              });
            },
            borderRadius: BorderRadius.circular(20),
            selectedColor: Colors.orange,
            color: Colors.white,
            fillColor: Colors.white,
            borderColor: Colors.white54,
            selectedBorderColor: Colors.white,
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Weekly',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'All Time',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAmbassadorItem(
                'Karthik', '22,150 XP', 'assets/icon/profile.png', false, 50),
            _buildAmbassadorItem('Diwakar', '22,150 XP',
                'assets/icon/profile-alt.png', true, 80),
            _buildAmbassadorItem('Poorna Hari', '22,150 XP',
                'assets/icon/profile-circle.png', false, 40),
          ],
        ),
      ],
    );
  }

  Widget _buildAmbassadorItem(String name, String xp, String imagePath,
      bool isTop, double chartHeight) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: isTop ? Colors.pink : Colors.transparent,
              child: CircleAvatar(
                radius: 32,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
            if (isTop)
              Positioned(
                top: -5,
                child: Image.asset(
                  'assets/icon/crown.png',
                  width: 30,
                  height: 30,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          xp,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: chartHeight, // Dynamic height for chart
          decoration: BoxDecoration(
            color: name == 'Karthik' ? Colors.yellow : Colors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildYourPositionSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Position: #7',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Top 5% of all Ambassadors',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange, size: 24),
                SizedBox(width: 4),
                Text(
                  '+2 this week',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Challenges',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildChallengeCard(
                'Post 5 City Guides',
                '2 days',
                '+200 XP',
                0.7,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChallengeCard(
                'Gain 500 Followers',
                '2 days',
                '+500 XP',
                0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
      String title, String time, String xp, double progress) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time,
                        color: Colors.grey.shade600, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  xp,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Benefits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...AmbassadorScreen.benefits
                .map((benefit) => _buildBenefitItem(benefit))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BenefitItem benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            benefit.iconPath,
            width: 24,
            height: 24,
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  benefit.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
