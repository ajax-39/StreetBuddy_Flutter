import 'package:cloud_firestore/cloud_firestore.dart';

class UserAnalytics {
  final String userId;
  final DateTime timestamp;
  final int followers;
  final int following;
  final int totalLikes;
  final int posts;

  UserAnalytics({
    required this.userId,
    required this.timestamp,
    required this.followers,
    required this.following,
    required this.totalLikes,
    required this.posts,
  });
  static Map<String, dynamic> createInitialMetrics() {
    return {
      'followers': 0,
      'following': 0,
      'totalLikes': 0,
      'posts': 0,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': timestamp,
      'followers': followers,
      'following': following,
      'totalLikes': totalLikes,
      'posts': posts,
    };
  }

  factory UserAnalytics.fromMap(Map<String, dynamic> map) {
    return UserAnalytics(
      userId: map['userId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      followers: map['followers'],
      following: map['following'],
      totalLikes: map['totalLikes'],
      posts: map['posts'],
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'followers': followers,
      'following': following,
      'total_likes': totalLikes,
      'posts': posts,
    };
  }

  factory UserAnalytics.fromSupabaseMap(Map<String, dynamic> map) {
    return UserAnalytics(
      userId: map['user_id'],
      timestamp: DateTime.parse(map['timestamp']),
      followers: map['followers'],
      following: map['following'],
      totalLikes: map['total_likes'],
      posts: map['posts'],
    );
  }
}
