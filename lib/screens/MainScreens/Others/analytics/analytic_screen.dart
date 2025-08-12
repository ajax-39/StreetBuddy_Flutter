import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/models/user_analytic.dart';
import 'package:street_buddy/provider/analytic_provider.dart';
import 'package:street_buddy/widgets/graphs/bar_graph_widget.dart';
import 'package:street_buddy/widgets/graphs/line_graph_widget.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/time_filter_enum.dart';
import 'dart:async';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  TimeFilter selectedTimeFilter = TimeFilter.month;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _supabase = Supabase.instance.client;
  Timer? _timer;
  StreamController<Map<String, dynamic>>? _streamController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _streamController = StreamController<Map<String, dynamic>>();
    _startFetching();
  }

  void _startFetching() {
    // Initial fetch
    _fetchUserData();

    // Set up periodic fetching every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = globalUser;
      if (currentUser == null) {
        debugPrint('DEBUG: No Firebase user found');
        return;
      }

      debugPrint('DEBUG: Fetching data for uid: ${currentUser.uid}');

      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', currentUser.uid)
          .single();

      debugPrint('DEBUG: Supabase Response: ${response.toString()}');

      if (!_streamController!.isClosed) {
        _streamController!.add(response);
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching data: $e');
      if (!_streamController!.isClosed) {
        _streamController!.addError(e);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _streamController?.close();
    super.dispose();
  }

  /// Handles the change in time filter by resetting and restarting the animation.
  void _onTimeFilterChanged(TimeFilter? newValue) {
    if (newValue != null && newValue != selectedTimeFilter) {
      _animationController.reset();
      setState(() {
        selectedTimeFilter = newValue;
      });
      _animationController.forward();
    }
  }

  /// Returns the number of days corresponding to the selected time filter.
  int _getFilterDays() {
    switch (selectedTimeFilter) {
      case TimeFilter.today:
        return 1;
      case TimeFilter.month:
        return 30;
      case TimeFilter.threeMonths:
        return 90;
      case TimeFilter.sixMonths:
        return 180;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('My Analytics Dashboard', style: AppTypography.headline),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.buttonText,
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<Map<String, dynamic>>(
            stream: _streamController?.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = UserModel.fromMap(
                snapshot.data!['uid'],
                snapshot.data!,
              );
              // debugPrint('DEBUG: User Data: ${userData.uid.toString()}');
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _buildExpandedMetricsCard(userData),
                    const SizedBox(height: 20),
                    _buildTimeFilterDropdown(),
                    const SizedBox(height: 20),
                    FutureBuilder<List<UserAnalytics>>(
                      future: provider.getAnalytics(
                        userData.uid,
                        selectedTimeFilter,
                      ),
                      builder: (context, analyticsSnapshot) {
                        if (!analyticsSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _buildAnalyticsCharts(analyticsSnapshot.data!);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExpandedMetricsCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Posts', user.postCount, Icons.post_add),
                _buildMetricColumn('Guides', user.guideCount, Icons.map),
                _buildMetricColumn('Likes', user.totalLikes, Icons.favorite),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                    'Followers', user.followersCount, Icons.people),
                _buildMetricColumn(
                    'Following', user.followingCount, Icons.person_add),
                _buildMetricColumn(
                    'Avg Rating', user.avgGuideReview, Icons.star,
                    isDouble: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, dynamic value, IconData icon,
      {bool isDouble = false}) {
    String displayValue =
        value is double && value.isNaN ? '0' : value.toString();

    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<TimeFilter>(
        value: selectedTimeFilter,
        onChanged: _onTimeFilterChanged,
        items: const [
          DropdownMenuItem(
            value: TimeFilter.today,
            child: Text('Today'),
          ),
          DropdownMenuItem(
            value: TimeFilter.month,
            child: Text('Last 30 Days'),
          ),
          DropdownMenuItem(
            value: TimeFilter.threeMonths,
            child: Text('Last 3 Months'),
          ),
          DropdownMenuItem(
            value: TimeFilter.sixMonths,
            child: Text('Last 6 Months'),
          ),
        ],
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        style: const TextStyle(color: AppColors.primary, fontSize: 16),
      ),
    );
  }

  /// Builds the analytics charts using both line and bar chart types.
  Widget _buildAnalyticsCharts(List<UserAnalytics> analytics) {
    if (analytics.isEmpty || analytics.length < 3) {
      return Column(
        children: [
          _buildNoDataAvailable(),
          const SizedBox(height: 20),
          _buildNoDataAvailable(),
          const SizedBox(height: 20),
          _buildNoDataAvailable(),
        ],
      );
    }

    debugPrint('Analytics data count: ${analytics.length}');
    debugPrint('First analytics date: ${analytics.first.timestamp}');
    debugPrint('Last analytics date: ${analytics.last.timestamp}');
    debugPrint('likes counts: ${analytics.map((a) => a.totalLikes).toList()}');

    return Column(
      children: [
        _buildLineChart(
            'Followers',
            analytics,
            (data) => data.followers.toDouble(),
            _calculateGrowthRate(
                analytics, (data) => data.followers.toDouble())),
        const SizedBox(height: 20),
        _buildLineChart(
            'Likes',
            analytics,
            (data) => data.totalLikes.toDouble(),
            _calculateGrowthRate(
                analytics, (data) => data.totalLikes.toDouble())),
        const SizedBox(height: 20),
        _buildBarChart('Posts', analytics, (data) => data.posts.toDouble(),
            _calculateGrowthRate(analytics, (data) => data.posts.toDouble())),
      ],
    );
  }

  /// Builds a bar chart for the provided analytics data.
  Widget _buildBarChart(
    String title,
    List<UserAnalytics> analytics,
    double Function(UserAnalytics) getValue,
    double growthRate,
  ) {
    return AnalyticsBarChart(
      title: title,
      analytics: analytics,
      getValue: getValue,
      growthRate: growthRate,
      selectedTimeFilter: selectedTimeFilter,
      animation: _animation,
    );
  }

  /// Builds a line chart for the provided analytics data.
  Widget _buildLineChart(
    String title,
    List<UserAnalytics> analytics,
    double Function(UserAnalytics) getValue,
    double growthRate,
  ) {
    return AnalyticsLineChart(
      title: title,
      analytics: analytics,
      getValue: getValue,
      growthRate: growthRate,
      selectedTimeFilter: selectedTimeFilter,
      animation: _animation,
    );
  }

  /// Calculates the percentage growth rate between the first and last analytics data points.
  double _calculateGrowthRate(
    List<UserAnalytics> analytics,
    double Function(UserAnalytics) getValue,
  ) {
    if (analytics.length < 2) return 0.0;

    final latest = analytics.last;
    final oldest = analytics.first;

    final latestValue = getValue(latest);
    final oldestValue = getValue(oldest);

    if (oldestValue == 0) return 0.0;

    return ((latestValue - oldestValue) / oldestValue) * 100;
  }

  /// Formats the timestamp for display on the x-axis based on the selected time filter.
  String _getXAxisLabel(DateTime timestamp) {
    switch (selectedTimeFilter) {
      case TimeFilter.today:
        return DateFormat('HH:mm').format(timestamp);
      case TimeFilter.month:
        return DateFormat('dd MMM').format(timestamp);
      case TimeFilter.threeMonths:
        return DateFormat('dd MMM').format(timestamp);
      case TimeFilter.sixMonths:
        return DateFormat('MMM yy').format(timestamp);
    }
  }

  Widget _buildGrowthRateIndicator(double growthRate) {
    final isPositive = growthRate >= 0;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final color = isPositive ? Colors.green : Colors.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '${growthRate.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataAvailable() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Data Available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
