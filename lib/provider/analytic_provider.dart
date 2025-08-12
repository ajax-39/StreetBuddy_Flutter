import 'package:flutter/foundation.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/utils/time_filter_enum.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/models/user_analytic.dart';

/// Manages user analytics data collection and processing.
/// Handles interaction with Firestore and Supabase for storing analytics data.
class AnalyticsProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  final int updateInterval;

  AnalyticsProvider({this.updateInterval = 60});

  /// Records or updates user analytics data in Supabase.
  ///
  /// Takes [userId] and stores current metrics including followers, following count,
  /// total likes and posts. Updates existing record if last update was within
  /// [updateInterval] minutes, otherwise creates new record.
  Future<void> recordDailyAnalytics(PostModel post, String userId) async {
    try {
      debugPrint('Recording analytics for user: $userId');
      debugPrint('Recording analytics for post: $post');

      // Use Supabase instead of Firestore to fetch user data
      final userData =
          await _supabase.from('users').select().eq('uid', userId).single();

      if (userData == null) {
        debugPrint('User not found in Supabase: $userId');
        return;
      }

      final updateData = {
        'followers': (userData['followers'] as List?)?.length ?? 0,
        'following': (userData['following'] as List?)?.length ?? 0,
        'total_likes': userData['total_likes'] ?? 0,
        'posts': userData['post_count'] ?? 0,
      };

      final istNow =
          DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

      try {
        final recentAnalytics = await _supabase
            .from('analytics')
            .select()
            .eq('user_id', userId)
            .order('timestamp', ascending: false)
            .limit(1)
            .single();

        final lastTimestamp =
            DateTime.parse(recentAnalytics['timestamp']).toUtc();

        final timeDifference = istNow.difference(lastTimestamp).inMinutes;
        debugPrint('Last record timestamp (IST): ${lastTimestamp.toString()}');
        debugPrint('Current time (IST): ${istNow.toString()}');
        debugPrint('Time difference in minutes: $timeDifference');

        if (timeDifference.abs() < updateInterval) {
          await _supabase
              .from('analytics')
              .update(updateData)
              .eq('id', recentAnalytics['id']);
          debugPrint('Updated existing record for user: $userId');
          return;
        }
      } catch (e) {
        debugPrint('No recent analytics found for user: $userId');
      }

      // Create new record if no recent record exists or time difference is too large
      final newRecordData = {
        ...updateData,
        'user_id': userId,
        'timestamp': istNow.toIso8601String(),
      };

      await _supabase.from('analytics').insert(newRecordData);
      debugPrint('Created new analytics record for user: $userId');
    } catch (e) {
      debugPrint('Error recording analytics: $e');
      rethrow;
    }
  }

  /// Retrieves analytics data for specified time period.
  ///
  /// [userId] The user ID to fetch analytics for
  /// [filter] TimeFilter enum specifying the date range (today/month/3months/6months)
  ///
  /// Returns processed list of [UserAnalytics] data points based on the filter.
  Future<List<UserAnalytics>> getAnalytics(
      String userId, TimeFilter filter) async {
    try {
      debugPrint('Fetching analytics for user: $userId');
      DateTime startDate;
      final now = DateTime.now();

      // Set start date based on filter
      switch (filter) {
        case TimeFilter.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case TimeFilter.month:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case TimeFilter.threeMonths:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case TimeFilter.sixMonths:
          startDate = now.subtract(const Duration(days: 180));
          break;
      }

      final response = await _supabase
          .from('analytics')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', startDate.toIso8601String())
          .order('timestamp', ascending: true);

      List<UserAnalytics> rawData = (response as List).map((data) {
        return UserAnalytics.fromSupabaseMap(data);
      }).toList();
      return _processAnalyticsData(rawData, filter);
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      return [];
    }
  }

  /// Processes raw analytics data into standardized time-based data points.
  ///
  /// [rawData] List of raw analytics entries
  /// [filter] TimeFilter determining the processing strategy
  ///
  /// Returns processed list with consistent intervals based on filter.
  List<UserAnalytics> _processAnalyticsData(
      List<UserAnalytics> rawData, TimeFilter filter) {
    if (rawData.isEmpty) {
      debugPrint('🔴 ProcessAnalyticsData: Raw data is empty');
      return [];
    }

    debugPrint(
        '🟢 ProcessAnalyticsData: Starting with ${rawData.length} data points');
    debugPrint(
        '🟢 Raw data timestamps: ${rawData.map((d) => d.timestamp.toIso8601String()).toList()}');
    debugPrint(
        '🟢 Raw data followers: ${rawData.map((d) => d.followers).toList()}');
    debugPrint(
        '🟢 Raw data likes: ${rawData.map((d) => d.totalLikes).toList()}');
    debugPrint('🟢 Raw data posts: ${rawData.map((d) => d.posts).toList()}');

    final now = DateTime.now();
    List<UserAnalytics> processed = [];

    switch (filter) {
      case TimeFilter.today:
        // 24 hourly points
        final startOfDay = DateTime(now.year, now.month, now.day);
        processed = _generateHourlyPoints(rawData, startOfDay, now);
        break;

      case TimeFilter.month:
        // 30 daily points
        final startDate = now.subtract(const Duration(days: 30));
        processed = _generateDailyPoints(rawData, startDate, now);
        break;

      case TimeFilter.threeMonths:
        // 12 weekly points
        final startDate = now.subtract(const Duration(days: 90));
        processed = _generateWeeklyPoints(rawData, startDate, now);
        break;

      case TimeFilter.sixMonths:
        // 6 monthly points
        final startDate = now.subtract(const Duration(days: 180));
        processed = _generateMonthlyPoints(rawData, startDate, now);
        break;
    }

    debugPrint(
        '🟢 ProcessAnalyticsData: Returning ${processed.length} processed data points');
    debugPrint(
        '🟢 Processed timestamps: ${processed.map((d) => d.timestamp.toIso8601String()).toList()}');
    debugPrint(
        '🟢 Processed followers: ${processed.map((d) => d.followers).toList()}');
    debugPrint(
        '🟢 Processed likes: ${processed.map((d) => d.totalLikes).toList()}');
    debugPrint('🟢 Processed posts: ${processed.map((d) => d.posts).toList()}');

    return processed;
  }

  /// Generates 24 hourly data points for the given day.
  ///
  /// Fills gaps with values from the most recent data point if no data exists for specific hours.
  List<UserAnalytics> _generateHourlyPoints(
      List<UserAnalytics> rawData, DateTime start, DateTime end) {
    List<UserAnalytics> hourlyPoints = [];

    // Sort data by timestamp to ensure proper processing
    final sortedData = List<UserAnalytics>.from(rawData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Track the most recent analytics seen so far to fill gaps
    UserAnalytics? mostRecentData;

    for (int hour = 0; hour < 24; hour++) {
      final pointTime = start.add(Duration(hours: hour));
      if (pointTime.isAfter(end)) break;

      final hourData = sortedData
          .where((data) =>
              data.timestamp.year == pointTime.year &&
              data.timestamp.month == pointTime.month &&
              data.timestamp.day == pointTime.day &&
              data.timestamp.hour == pointTime.hour)
          .toList();

      if (hourData.isNotEmpty) {
        mostRecentData = hourData.last;
        hourlyPoints.add(mostRecentData);
      } else if (pointTime.isBefore(sortedData.first.timestamp)) {
        // For hours before our first data point, use zeros
        hourlyPoints.add(UserAnalytics(
          userId: sortedData.first.userId,
          timestamp: pointTime,
          followers: 0,
          following: 0,
          totalLikes: 0,
          posts: 0,
        ));
      } else {
        // Use the most recent data we've seen
        if (mostRecentData != null) {
          hourlyPoints.add(UserAnalytics(
            userId: mostRecentData.userId,
            timestamp: pointTime,
            followers: mostRecentData.followers,
            following: mostRecentData.following,
            totalLikes: mostRecentData.totalLikes,
            posts: mostRecentData.posts,
          ));
        } else {
          // Find the closest preceding data point
          final precedingData = sortedData.lastWhere(
            (data) => data.timestamp.isBefore(pointTime),
            orElse: () => sortedData.first,
          );

          hourlyPoints.add(UserAnalytics(
            userId: precedingData.userId,
            timestamp: pointTime,
            followers: precedingData.followers,
            following: precedingData.following,
            totalLikes: precedingData.totalLikes,
            posts: precedingData.posts,
          ));
        }
      }
    }

    return hourlyPoints;
  }

  /// Generates 30 daily data points starting from the given start date.
  ///
  /// Fills gaps with zero-value data points if no data exists for specific days.
  /// Uses the most recent data available for filling the values.
  List<UserAnalytics> _generateDailyPoints(
      List<UserAnalytics> rawData, DateTime start, DateTime end) {
    List<UserAnalytics> dailyPoints = [];

    // Sort data by timestamp to ensure proper processing
    final sortedData = List<UserAnalytics>.from(rawData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Track the most recent analytics seen so far to fill gaps
    UserAnalytics? mostRecentData;

    for (int day = 0; day < 30; day++) {
      final pointTime = start.add(Duration(days: day));
      if (pointTime.isAfter(end)) break;

      final dayData = sortedData
          .where((data) =>
              data.timestamp.year == pointTime.year &&
              data.timestamp.month == pointTime.month &&
              data.timestamp.day == pointTime.day)
          .toList();

      if (dayData.isNotEmpty) {
        // Use the latest data point for this day
        mostRecentData = dayData.last;
        dailyPoints.add(mostRecentData);
      } else if (pointTime.isBefore(sortedData.first.timestamp)) {
        // For dates before our first data point, use zeros
        dailyPoints.add(UserAnalytics(
          userId: sortedData.first.userId,
          timestamp: pointTime,
          followers: 0,
          following: 0,
          totalLikes: 0,
          posts: 0,
        ));
      } else {
        // Use the most recent data we've seen so far
        if (mostRecentData != null) {
          dailyPoints.add(UserAnalytics(
            userId: mostRecentData.userId,
            timestamp: pointTime,
            followers: mostRecentData.followers,
            following: mostRecentData.following,
            totalLikes: mostRecentData.totalLikes,
            posts: mostRecentData.posts,
          ));
        } else {
          // Find the closest preceding data point
          final precedingData = sortedData.lastWhere(
            (data) => data.timestamp.isBefore(pointTime),
            orElse: () => sortedData.first,
          );

          dailyPoints.add(UserAnalytics(
            userId: precedingData.userId,
            timestamp: pointTime,
            followers: precedingData.followers,
            following: precedingData.following,
            totalLikes: precedingData.totalLikes,
            posts: precedingData.posts,
          ));
        }
      }
    }

    debugPrint(
        '📅 _generateDailyPoints: Generated ${dailyPoints.length} daily points');
    debugPrint(
        '📅 Daily points posts: ${dailyPoints.map((d) => d.posts).toList()}');
    debugPrint(
        '📅 Daily points likes: ${dailyPoints.map((d) => d.totalLikes).toList()}');
    return dailyPoints;
  }

  /// Generates 12 weekly data points starting from the given start date.
  ///
  /// Fills gaps with the most recent data available.
  List<UserAnalytics> _generateWeeklyPoints(
      List<UserAnalytics> rawData, DateTime start, DateTime end) {
    List<UserAnalytics> weeklyPoints = [];

    // Sort data by timestamp to ensure proper processing
    final sortedData = List<UserAnalytics>.from(rawData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Track the most recent analytics seen so far to fill gaps
    UserAnalytics? mostRecentData;

    for (int week = 0; week < 12; week++) {
      final weekStart = start.add(Duration(days: week * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      if (weekStart.isAfter(end)) break;

      final weekData = sortedData
          .where((data) =>
              data.timestamp.isAfter(weekStart) &&
              data.timestamp.isBefore(weekEnd))
          .toList();

      if (weekData.isNotEmpty) {
        // Use the latest data point for this week
        mostRecentData = weekData.last;
        weeklyPoints.add(mostRecentData);
      } else if (weekStart.isBefore(sortedData.first.timestamp)) {
        // For weeks before our first data point, use zeros
        weeklyPoints.add(UserAnalytics(
          userId: sortedData.first.userId,
          timestamp: weekStart,
          followers: 0,
          following: 0,
          totalLikes: 0,
          posts: 0,
        ));
      } else {
        // Use the most recent data we've seen so far
        if (mostRecentData != null) {
          weeklyPoints.add(UserAnalytics(
            userId: mostRecentData.userId,
            timestamp: weekStart,
            followers: mostRecentData.followers,
            following: mostRecentData.following,
            totalLikes: mostRecentData.totalLikes,
            posts: mostRecentData.posts,
          ));
        } else {
          // Find the closest preceding data point
          final precedingData = sortedData.lastWhere(
            (data) => data.timestamp.isBefore(weekStart),
            orElse: () => sortedData.first,
          );

          weeklyPoints.add(UserAnalytics(
            userId: precedingData.userId,
            timestamp: weekStart,
            followers: precedingData.followers,
            following: precedingData.following,
            totalLikes: precedingData.totalLikes,
            posts: precedingData.posts,
          ));
        }
      }
    }

    debugPrint(
        '📊 _generateWeeklyPoints: Generated ${weeklyPoints.length} weekly points');
    debugPrint(
        '📊 Weekly points posts: ${weeklyPoints.map((d) => d.posts).toList()}');
    debugPrint(
        '📊 Weekly points likes: ${weeklyPoints.map((d) => d.totalLikes).toList()}');
    return weeklyPoints;
  }

  /// Generates 6 monthly data points starting from the given start date.
  ///
  /// Fills gaps with the most recent data available.
  List<UserAnalytics> _generateMonthlyPoints(
      List<UserAnalytics> rawData, DateTime start, DateTime end) {
    List<UserAnalytics> monthlyPoints = [];

    // Sort data by timestamp to ensure proper processing
    final sortedData = List<UserAnalytics>.from(rawData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Track the most recent analytics seen so far to fill gaps
    UserAnalytics? mostRecentData;

    for (int month = 0; month < 6; month++) {
      final monthStart = DateTime(start.year, start.month + month);
      final monthEnd = DateTime(start.year, start.month + month + 1);
      if (monthStart.isAfter(end)) break;

      final monthData = sortedData
          .where((data) =>
              data.timestamp.year == monthStart.year &&
              data.timestamp.month == monthStart.month)
          .toList();

      if (monthData.isNotEmpty) {
        // Use the latest data point for this month
        mostRecentData = monthData.last;
        monthlyPoints.add(mostRecentData);
      } else if (monthStart.isBefore(sortedData.first.timestamp)) {
        // For months before our first data point, use zeros
        monthlyPoints.add(UserAnalytics(
          userId: sortedData.first.userId,
          timestamp: monthStart,
          followers: 0,
          following: 0,
          totalLikes: 0,
          posts: 0,
        ));
      } else {
        // Use the most recent data we've seen so far
        if (mostRecentData != null) {
          monthlyPoints.add(UserAnalytics(
            userId: mostRecentData.userId,
            timestamp: monthStart,
            followers: mostRecentData.followers,
            following: mostRecentData.following,
            totalLikes: mostRecentData.totalLikes,
            posts: mostRecentData.posts,
          ));
        } else {
          // Find the closest preceding data point
          final precedingData = sortedData.lastWhere(
            (data) => data.timestamp.isBefore(monthStart),
            orElse: () => sortedData.first,
          );

          monthlyPoints.add(UserAnalytics(
            userId: precedingData.userId,
            timestamp: monthStart,
            followers: precedingData.followers,
            following: precedingData.following,
            totalLikes: precedingData.totalLikes,
            posts: precedingData.posts,
          ));
        }
      }
    }

    debugPrint(
        '📈 _generateMonthlyPoints: Generated ${monthlyPoints.length} monthly points');
    debugPrint(
        '📈 Monthly points posts: ${monthlyPoints.map((d) => d.posts).toList()}');
    debugPrint(
        '📈 Monthly points likes: ${monthlyPoints.map((d) => d.totalLikes).toList()}');
    return monthlyPoints;
  }

  /// Calculates daily growth rates for key metrics over the given time period.
  ///
  /// Returns a map containing percentage growth rates for followers, likes and posts.
  Map<String, double> calculateGrowthRates(List<UserAnalytics> analytics) {
    if (analytics.length < 2) return {};

    final latest = analytics.first;
    final oldest = analytics.last;
    final daysDiff = latest.timestamp.difference(oldest.timestamp).inDays;

    return {
      'followers':
          _calculateGrowthRate(oldest.followers, latest.followers, daysDiff),
      'likes':
          _calculateGrowthRate(oldest.totalLikes, latest.totalLikes, daysDiff),
      'posts': _calculateGrowthRate(oldest.posts, latest.posts, daysDiff),
    };
  }

  double _calculateGrowthRate(int start, int end, int days) {
    if (start == 0) return 0;
    return ((end - start) / start) * 100 / days; // Daily growth rate percentage
  }
}
