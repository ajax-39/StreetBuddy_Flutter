import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/globals.dart';

class SearchService {
  static final _supabase = Supabase.instance.client;

  /// Log a search query when user clicks on a search result
  static Future<void> logSearchQuery({
    required String queryText,
    required String resultType, // 'location' or 'place'
    required String resultName,
  }) async {
    try {
      // Check if user is logged in
      final currentUser = globalUser;
      if (currentUser?.uid == null) {
        debugPrint('⚠️ User not logged in - skipping search query logging');
        return;
      }

      // Get username from users table
      final userResponse = await _supabase
          .from('users')
          .select('username')
          .eq('uid', currentUser!.uid)
          .maybeSingle();

      if (userResponse == null || userResponse['username'] == null) {
        debugPrint('⚠️ Username not found for user ${currentUser.uid}');
        return;
      }

      final username = userResponse['username'] as String;
      final executedAt = DateTime.now();

      // Insert search query into database (using only existing columns)
      await _supabase.from('search_queries').insert({
        'username': username,
        'query_text': queryText,
        'executed_at': executedAt.toIso8601String(),
      });

      debugPrint('✅ 📊 Search Query Logged Successfully!');
      debugPrint('👤 Username: $username');
      debugPrint('🔍 Query: "$queryText"');
      debugPrint('📍 Result Type: $resultType');
      debugPrint('🎯 Result Name: "$resultName"');
      debugPrint('📅 Date: ${executedAt.toString().split('.')[0]}');
      debugPrint('🔗 Full Log: $queryText → $resultName ($resultType)');
    } catch (e) {
      debugPrint('❌ Error logging search query: $e');
      // Don't throw error to avoid disrupting user experience
    }
  }

  /// Log search query with privacy check
  static Future<void> logSearchQueryWithPrivacyCheck({
    required String queryText,
    required String resultType,
    required String resultName,
    required bool historyEnabled,
  }) async {
    // Only log if user has search history enabled
    if (!historyEnabled) {
      debugPrint('🔒 Search history disabled - skipping query logging');
      return;
    }

    await logSearchQuery(
      queryText: queryText,
      resultType: resultType, 
      resultName: resultName,
    );
  }

  /// Get user's search analytics (optional feature for future)
  static Future<List<Map<String, dynamic>>> getUserSearchHistory({
    required String username,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('search_queries')
          .select()
          .eq('username', username)
          .order('executed_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching search history: $e');
      return [];
    }
  }

  /// Get popular searches (optional feature for future)
  static Future<List<Map<String, dynamic>>> getPopularSearches({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .rpc('get_popular_searches', params: {'search_limit': limit});

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('❌ Error fetching popular searches: $e');
      return [];
    }
  }
}
