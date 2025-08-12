import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:street_buddy/models/user_analytic.dart';
import 'package:street_buddy/widgets/graphs/no_data_available_for_graph_widget.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/time_filter_enum.dart';

class AnalyticsLineChart extends StatelessWidget {
  final String title;
  final List<UserAnalytics> analytics;
  final double Function(UserAnalytics) getValue;
  final double growthRate;
  final TimeFilter selectedTimeFilter;
  final Animation<double> animation;

  const AnalyticsLineChart({
    super.key,
    required this.title,
    required this.analytics,
    required this.getValue,
    required this.growthRate,
    required this.selectedTimeFilter,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (analytics.isEmpty || analytics.length < 3) {
      return buildNoDataAvailable();
    }

    final sortedAnalytics = List<UserAnalytics>.from(analytics)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double pointSpacing = _getPointSpacing();
    final spots = _createSpots(sortedAnalytics);
    final maxY = spots.fold(0.0, (max, spot) => spot.y > max ? spot.y : max);
    final interval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();
    final safeMaxY = (maxY + interval).ceilToDouble();

    final minWidth = MediaQuery.of(context).size.width - 64;
    final calculatedWidth =
        max(minWidth, sortedAnalytics.length * pointSpacing);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedSpots = spots
            .map((spot) => FlSpot(spot.x, spot.y * animation.value))
            .toList();

        return _buildChartCard(
          context,
          sortedAnalytics,
          animatedSpots,
          safeMaxY,
          interval,
          calculatedWidth,
          minWidth,
        );
      },
    );
  }

  double _getPointSpacing() {
    switch (selectedTimeFilter) {
      case TimeFilter.today:
        return 55;
      case TimeFilter.month:
        return 60;
      case TimeFilter.threeMonths:
        return 60;
      case TimeFilter.sixMonths:
        return 80;
    }
  }

  List<FlSpot> _createSpots(List<UserAnalytics> sortedAnalytics) {
    return sortedAnalytics.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), getValue(entry.value));
    }).toList();
  }

  Widget _buildChartCard(
    BuildContext context,
    List<UserAnalytics> sortedAnalytics,
    List<FlSpot> animatedSpots,
    double safeMaxY,
    double interval,
    double calculatedWidth,
    double minWidth,
  ) {
    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildChart(
              context,
              sortedAnalytics,
              animatedSpots,
              safeMaxY,
              interval,
              calculatedWidth,
              minWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        _buildGrowthRateIndicator(),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<UserAnalytics> sortedAnalytics,
    List<FlSpot> animatedSpots,
    double safeMaxY,
    double interval,
    double calculatedWidth,
    double minWidth,
  ) {
    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: calculatedWidth > minWidth
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: calculatedWidth,
          child: LineChart(
            _createLineChartData(
              sortedAnalytics,
              animatedSpots,
              safeMaxY,
              interval,
            ),
          ),
        ),
      ),
    );
  }

  LineChartData _createLineChartData(
    List<UserAnalytics> sortedAnalytics,
    List<FlSpot> animatedSpots,
    double safeMaxY,
    double interval,
  ) {
    return LineChartData(
      minY: 0,
      maxY: safeMaxY,
      titlesData: _createTitlesData(sortedAnalytics, interval),
      gridData: FlGridData(
        show: false,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      clipData: const FlClipData.all(),
      lineBarsData: [
        LineChartBarData(
          spots: animatedSpots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  FlTitlesData _createTitlesData(
    List<UserAnalytics> sortedAnalytics,
    double interval,
  ) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: interval,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ),
      bottomTitles: _createBottomTitles(sortedAnalytics),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  AxisTitles _createBottomTitles(List<UserAnalytics> sortedAnalytics) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        getTitlesWidget: (value, meta) {
          if (value.toInt() >= sortedAnalytics.length || value < 0) {
            return const SizedBox.shrink();
          }
          int index = value.toInt();
          EdgeInsets paddingInsets = const EdgeInsets.only(top: 3);
          if (index == 0) {
            paddingInsets = const EdgeInsets.only(top: 3, left: 16);
          } else if (index == sortedAnalytics.length - 1) {
            paddingInsets = const EdgeInsets.only(top: 3, right: 33);
          }
          return Padding(
            padding: paddingInsets,
            child: Transform.rotate(
              angle: 0,
              child: Text(
                _getXAxisLabel(sortedAnalytics[index].timestamp),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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

  Widget _buildGrowthRateIndicator() {
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
}
