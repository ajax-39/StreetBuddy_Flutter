import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:street_buddy/models/user_analytic.dart';
import 'package:street_buddy/widgets/graphs/no_data_available_for_graph_widget.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/utils/time_filter_enum.dart';

class AnalyticsBarChart extends StatelessWidget {
  final String title;
  final List<UserAnalytics> analytics;
  final double Function(UserAnalytics) getValue;
  final double growthRate;
  final TimeFilter selectedTimeFilter;
  final Animation<double> animation;

  const AnalyticsBarChart({
    super.key,
    required this.title,
    required this.analytics,
    required this.getValue,
    required this.growthRate,
    required this.selectedTimeFilter,
    required this.animation,
  });

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

  @override
  Widget build(BuildContext context) {
    if (analytics.isEmpty || analytics.length < 3) {
      return buildNoDataAvailable();
    }

    final sortedAnalytics = List<UserAnalytics>.from(analytics)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double pointSpacing = 0;
    double barWidth = 16;
    switch (selectedTimeFilter) {
      case TimeFilter.today:
        pointSpacing = 55;
        barWidth = 20;
        break;
      case TimeFilter.month:
        pointSpacing = 60;
        barWidth = 16;
        break;
      case TimeFilter.threeMonths:
        pointSpacing = 60;
        barWidth = 14;
        break;
      case TimeFilter.sixMonths:
        pointSpacing = 80;
        barWidth = 12;
        break;
    }

    final minWidth = MediaQuery.of(context).size.width - 64;
    final calculatedWidth =
        max(minWidth, sortedAnalytics.length * pointSpacing);

    final barGroups = sortedAnalytics.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: getValue(entry.value),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.7),
                AppColors.primary,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    final maxY = barGroups.fold(
        0.0,
        (max, group) =>
            group.barRods.first.toY > max ? group.barRods.first.toY : max);
    const minInterval = 1.0;
    final interval = maxY <= 5 ? minInterval : (maxY / 5).ceilToDouble();
    final safeMaxY = max(maxY + interval, 5.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedBarGroups = barGroups.map((group) {
          return group.copyWith(
            barRods: group.barRods.map((rod) {
              return rod.copyWith(
                toY: rod.toY * animation.value,
              );
            }).toList(),
          );
        }).toList();

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headline.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    _buildGrowthRateIndicator(growthRate),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: calculatedWidth > minWidth
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: calculatedWidth,
                      child: BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: safeMaxY,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: interval,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= sortedAnalytics.length ||
                                      value < 0) {
                                    return const Text('');
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Transform.rotate(
                                      angle: 0,
                                      child: Text(
                                        _getXAxisLabel(
                                            sortedAnalytics[value.toInt()]
                                                .timestamp),
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
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
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
                          barGroups: animatedBarGroups,
                          alignment: BarChartAlignment.spaceAround,
                          groupsSpace: pointSpacing - barWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
