import 'dart:async';

import 'package:flutter/material.dart';
import 'package:street_buddy/services/notification_sender.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/comment.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/provider/analytic_provider.dart';

class PostProvider extends ChangeNotifier {
  /// Returns a stream of the current user's saved post IDs (for real-time UI updates)
  Stream<List<String>> getSavedPostsStream(String userId) {
    return supabase
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('uid', userId)
        .map((data) => data.isNotEmpty
            ? List<String>.from(data[0]['saved_post'] ?? [])
            : <String>[]);
  }

  /// Returns true if the post is saved by the user (sync, for use with UserModel if available)
  bool isPostSavedByUser(
      {required String postId, required List<String> savedPosts}) {
    return savedPosts.contains(postId);
  }

  /// Toggles save/unsave for a post for the current user
  Future<void> toggleSavePost(
      {required String userId, required String postId}) async {
    try {
      final data = await supabase
          .from('users')
          .select('saved_post')
          .eq('uid', userId)
          .single();

      List<String> savedPosts = List<String>.from(data['saved_post'] ?? []);

      if (savedPosts.contains(postId)) {
        savedPosts.remove(postId);
      } else {
        savedPosts.add(postId);
      }

      await supabase.from('users').update({
        'saved_post': savedPosts,
      }).eq('uid', userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error in toggleSavePost: $e');
    }
  }

  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  final Map<String, bool> _commentFieldVisibility = {};
  final Map<String, bool> _showAllComments = Map<String, bool>.fromEntries([]);
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, bool> _heartAnimations = {};

  // Add hidden posts functionality
  final Set<String> _hiddenPosts = <String>{};

  bool isCommentFieldVisible(String postId) {
    return _commentFieldVisibility[postId] ?? false;
  }

  bool showAllComments(String postId) {
    return _showAllComments[postId] ?? false;
  }

// Get all posts in chronological order with real-time updates
  Stream<List<PostModel>> getAllPostsStream() {
    // Create a stream controller to manage the stream
    final controller = StreamController<List<PostModel>>();

    // Initial fetch
    _fetchAllPosts(controller);

    // Set up subscription to update when data changes
    final subscription = supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          final posts =
              data.map((post) => PostModel.fromMap(post['id'], post)).toList();
          controller.add(posts);
        });

    // Clean up when stream is no longer needed
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

// Helper method to fetch all posts initially
  void _fetchAllPosts(StreamController<List<PostModel>> controller) async {
    try {
      final data = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);
      final posts =
          data.map((post) => PostModel.fromMap(post['id'], post)).toList();
      if (!controller.isClosed) {
        controller.add(posts);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Get all posts in chronological order (Future version)
  Future<List<PostModel>> getAllPostsFuture() async {
    try {
      final data = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      return data.map((post) => PostModel.fromMap(post['id'], post)).toList();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  void toggleCommentField(String postId) {
    _commentFieldVisibility[postId] =
        !(_commentFieldVisibility[postId] ?? false);
    notifyListeners();
  }

  void toggleShowAllComments(String postId) {
    _showAllComments[postId] = !(_showAllComments[postId] ?? false);
    notifyListeners();
  }

  TextEditingController getCommentController(String postId) {
    if (!_commentControllers.containsKey(postId)) {
      _commentControllers[postId] = TextEditingController();
    }
    return _commentControllers[postId]!;
  }

  bool isHeartAnimationVisible(String postId) {
    return _heartAnimations[postId] ?? false;
  }

  void showHeartAnimation(String postId) {
    _heartAnimations[postId] = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1000), () {
      _heartAnimations[postId] = false;
      notifyListeners();
    });
  }

  Stream<PostModel> getPost(String postId) {
    return supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .map((data) => PostModel.fromMap(data[0]['id'], data[0]));
  }

  Stream<PostModel> getGuide(String postId) {
    return supabase.from('guides').stream(primaryKey: ['id']).map((data) => data
        .where((post) => post['id'] == postId)
        .map((post) => PostModel.fromMap(post['id'], post))
        .first);
  }

  Future<PostModel> getGuideOnce(String postId) async {
    try {
      final response =
          await supabase.from('guides').select().eq('id', postId).single();

      return PostModel.fromMap(response['id'], response);
    } catch (e) {
      debugPrint('Error getting guide: $e');
      rethrow; // Rethrow to let the caller handle the error
    }
  }

  Future<void> toggleLikeGuide(
      PostModel guide, String userId, String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current guide data
      final guideResponse = await supabase
          .from('guides')
          .select('likes, liked_by, dislikes, disliked_by')
          .eq('id', guide.id)
          .single();

      // Get current user data
      final userData = await supabase
          .from('users')
          .select('total_likes, guide_likes, total_dislikes, guide_dislikes')
          .eq('uid', guide.userId)
          .single();

      final currentLikes = guideResponse['likes'] as int? ?? 0;
      final likedBy = List<String>.from(guideResponse['liked_by'] ?? []);
      final userTotalLikes = userData['total_likes'] as int? ?? 0;
      final userGuideLikes = userData['guide_likes'] as int? ?? 0;

      // For dislike removal if needed
      final currentDislikes = guideResponse['dislikes'] as int? ?? 0;
      final dislikedBy = List<String>.from(guideResponse['disliked_by'] ?? []);
      final userTotalDislikes = userData['total_dislikes'] as int? ?? 0;
      final userGuideDislikes = userData['guide_dislikes'] as int? ?? 0;
      final wasDisliked = dislikedBy.contains(userId);

      if (likedBy.contains(userId)) {
        // Unlike the guide
        if (currentLikes > 0) {
          await Future.wait([
            // Update guide likes
            supabase.from('guides').update({
              'likes': currentLikes - 1,
              'liked_by': likedBy..remove(userId),
            }).eq('id', guide.id),

            // Update user total likes and guide likes
            supabase.from('users').update({
              'total_likes': userTotalLikes > 0 ? userTotalLikes - 1 : 0,
              'guide_likes': userGuideLikes > 0 ? userGuideLikes - 1 : 0,
            }).eq('uid', guide.userId),
          ]);
        } else {
          // Just remove from liked_by without decrementing
          await supabase.from('guides').update({
            'liked_by': likedBy..remove(userId),
          }).eq('id', guide.id);
        }
      } else {
        // Like the guide and remove any existing dislike
        final updates = [
          // Update guide likes
          supabase.from('guides').update({
            'likes': currentLikes + 1,
            'liked_by': [...likedBy, userId],
          }).eq('id', guide.id),

          // Update user total likes and guide likes
          supabase.from('users').update({
            'total_likes': userTotalLikes + 1,
            'guide_likes': userGuideLikes + 1,
          }).eq('uid', guide.userId),
        ];

        // If the user already disliked the guide, remove the dislike
        if (wasDisliked) {
          updates.add(supabase.from('guides').update({
            'dislikes': currentDislikes > 0 ? currentDislikes - 1 : 0,
            'disliked_by': dislikedBy..remove(userId),
          }).eq('id', guide.id));

          updates.add(supabase.from('users').update({
            'total_dislikes': userTotalDislikes > 0 ? userTotalDislikes - 1 : 0,
            'guide_dislikes': userGuideDislikes > 0 ? userGuideDislikes - 1 : 0,
          }).eq('uid', guide.userId));
        }

        await Future.wait(updates);

        debugPrint('Liked guide: ${guide.id}');
        await addInterests(guide.tags);

        // Send notification
        NotificationSender().sendLiked(guide, userId, username);
      }

      final analyticsProvider = AnalyticsProvider();
      await analyticsProvider.recordDailyAnalytics(guide, guide.userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error toggling guide like: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleDislikeGuide(
      PostModel guide, String userId, String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current guide data
      final guideResponse = await supabase
          .from('guides')
          .select('dislikes, disliked_by, likes, liked_by')
          .eq('id', guide.id)
          .single();

      // Get current user data
      final userData = await supabase
          .from('users')
          .select('total_dislikes, guide_dislikes, total_likes, guide_likes')
          .eq('uid', guide.userId)
          .single();

      final currentDislikes = guideResponse['dislikes'] as int? ?? 0;
      final dislikedBy = List<String>.from(guideResponse['disliked_by'] ?? []);
      final userTotalDislikes = userData['total_dislikes'] as int? ?? 0;
      final userGuideDislikes = userData['guide_dislikes'] as int? ?? 0;

      // For like removal if needed
      final currentLikes = guideResponse['likes'] as int? ?? 0;
      final likedBy = List<String>.from(guideResponse['liked_by'] ?? []);
      final userTotalLikes = userData['total_likes'] as int? ?? 0;
      final userGuideLikes = userData['guide_likes'] as int? ?? 0;
      final wasLiked = likedBy.contains(userId);

      if (dislikedBy.contains(userId)) {
        // Remove dislike from the guide
        if (currentDislikes > 0) {
          await Future.wait([
            // Update guide dislikes
            supabase.from('guides').update({
              'dislikes': currentDislikes - 1,
              'disliked_by': dislikedBy..remove(userId),
            }).eq('id', guide.id),

            // Update user total dislikes and guide dislikes
            supabase.from('users').update({
              'total_dislikes':
                  userTotalDislikes > 0 ? userTotalDislikes - 1 : 0,
              'guide_dislikes':
                  userGuideDislikes > 0 ? userGuideDislikes - 1 : 0,
            }).eq('uid', guide.userId),
          ]);
        } else {
          // Just remove from disliked_by without decrementing
          await supabase.from('guides').update({
            'disliked_by': dislikedBy..remove(userId),
          }).eq('id', guide.id);
        }
      } else {
        // Dislike the guide and remove any existing like
        final updates = [
          // Update guide dislikes
          supabase.from('guides').update({
            'dislikes': currentDislikes + 1,
            'disliked_by': [...dislikedBy, userId],
          }).eq('id', guide.id),

          // Update user total dislikes and guide dislikes
          supabase.from('users').update({
            'total_dislikes': userTotalDislikes + 1,
            'guide_dislikes': userGuideDislikes + 1,
          }).eq('uid', guide.userId),
        ];

        // If the user already liked the guide, remove the like
        if (wasLiked) {
          updates.add(supabase.from('guides').update({
            'likes': currentLikes > 0 ? currentLikes - 1 : 0,
            'liked_by': likedBy..remove(userId),
          }).eq('id', guide.id));

          updates.add(supabase.from('users').update({
            'total_likes': userTotalLikes > 0 ? userTotalLikes - 1 : 0,
            'guide_likes': userGuideLikes > 0 ? userGuideLikes - 1 : 0,
          }).eq('uid', guide.userId));
        }

        await Future.wait(updates);

        debugPrint('Disliked guide: ${guide.id}');
      }

      final analyticsProvider = AnalyticsProvider();
      await analyticsProvider.recordDailyAnalytics(guide, guide.userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error toggling guide dislike: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSaveGuideFromUsers(String userId, String guideId) async {
    try {
      if (userId.isEmpty || guideId.isEmpty) {
        return;
      }

      final data = await supabase
          .from('users')
          .select('saved_guides')
          .eq('uid', userId)
          .single();

      List savedGuides = data['saved_guides'] ?? [];

      if (savedGuides.contains(guideId)) {
        savedGuides.remove(guideId);
      } else {
        savedGuides.add(guideId);
      }

      await supabase.from('users').update({
        'saved_guides': savedGuides,
      }).eq('uid', userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error in saveGuide: $e');
    }
  }

  Stream<List<CommentModel>> getPostComments(String postId) {
    // Create a stream controller to manage the stream with better error handling
    final controller = StreamController<List<CommentModel>>();

    // Initial fetch using future to populate data quickly even if stream is slow
    _fetchCommentsInitial(postId, controller);

    // Set up more robust realtime subscription with error handling
    try {
      final subscription = supabase
          .from('comments')
          .stream(primaryKey: ['id'])
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .listen((data) {
            try {
              final comments = data
                  .map<CommentModel>(
                      (doc) => CommentModel.fromMap(doc['id'], doc))
                  .toList();
              if (!controller.isClosed) {
                controller.add(comments);
              }
            } catch (e) {
              debugPrint('Error processing comments data: $e');
              // Don't add error to controller here, let the stream continue
            }
          }, onError: (error) {
            debugPrint('Comments stream error: $error');
            if (!controller.isClosed) {
              // Don't propagate the error if we already have data
              // Just log it and let the UI continue with existing data
              _fetchCommentsInitial(postId, controller);
            }
          });

      // Clean up when stream is no longer needed
      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };
    } catch (e) {
      debugPrint('Error setting up comments stream: $e');
      // Still fetch data once even if realtime fails
      _fetchCommentsInitial(postId, controller);

      // Add a dummy cleanup function
      controller.onCancel = () {
        controller.close();
      };
    }

    return controller.stream;
  }

  // Helper method to fetch initial comments data
  void _fetchCommentsInitial(
      String postId, StreamController<List<CommentModel>> controller) async {
    try {
      final data = await supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      final comments = data
          .map<CommentModel>((doc) => CommentModel.fromMap(doc['id'], doc))
          .toList();

      if (!controller.isClosed) {
        controller.add(comments);
      }
    } catch (e) {
      debugPrint('Error fetching initial comments: $e');
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Future<void> toggleLike(
      PostModel post, String userId, String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await supabase
          .from('posts')
          .select('likes, liked_by')
          .eq('id', post.id)
          .single();

      final currentLikes = response['likes'] as int;
      final likedBy = List<String>.from(response['liked_by'] ?? []);

      if (likedBy.contains(userId)) {
        if (currentLikes > 0) {
          await supabase.from('posts').update({
            'likes': currentLikes - 1,
            'liked_by': likedBy..remove(userId),
          }).eq('id', post.id);
        } else {
          await supabase.from('posts').update({
            'liked_by': likedBy..remove(userId),
          }).eq('id', post.id);
        }
      } else {
        await supabase.from('posts').update({
          'likes': currentLikes + 1,
          'liked_by': [...likedBy, userId],
        }).eq('id', post.id);

        debugPrint('Liked post: ${post.id}');
        await addInterests(post.tags);

        // Send notification
        NotificationSender().sendLiked(post, userId, username);
      }

      final analyticsProvider = AnalyticsProvider();
      await analyticsProvider.recordDailyAnalytics(post, post.userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error toggling like: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInterests(List<String> tags) async {
    var currentUser = globalUser;

    if (currentUser != null) {
      try {
        final currentUser = await supabase
            .from('users')
            .select('interests')
            .eq('uid', "TEMP")

            /// FIX TEMP WITH ACTUAL USER ID
            .single();

        final currentInterests =
            List<String>.from(currentUser['interests'] ?? []);
        final newInterests = {...currentInterests, ...tags}.toList();

        await supabase
            .from('users')
            .update({'interests': newInterests}).eq('uid', "TEMP");

        /// FIX TEMP WITH ACTUAL USER ID
      } catch (e) {
        debugPrint('error ${e.toString()}');
      }
    }
  }

  Future<void> deletePost(PostModel post) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = globalUser;
      if (user == null) return;

      await supabase.from('posts').delete().eq('id', post.id);

      final userData = await supabase
          .from('users')
          .select('post_count')
          .eq('uid', "user.id") //FIX user.id with actual user id
          .single();

      final currentPostCount = userData['post_count'] as int;

      await supabase.from('users').update({
        'post_count': currentPostCount > 0 ? currentPostCount - 1 : 0,
      }).eq('uid', "user.id"); //FIX user.id with actual user id
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting post: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<UserModel> getUserData(String userId) {
    return supabase
        .from('users')
        .stream(primaryKey: ['uid'])
        .eq('uid', userId)
        .map((data) => UserModel.fromMap(userId, data[0]));
  }

// Add these methods to your PostProvider class

// Check if a post is liked by a user
  bool isPostLikedByUser(PostModel post, String? userId) {
    if (userId == null) return false;
    return post.likedBy.contains(userId);
  }

// Check if a guide is disliked by a user
  Future<bool> isGuideDislikedByUser(String guideId, String? userId) async {
    if (userId == null) return false;

    try {
      final response = await supabase
          .from('guides')
          .select('disliked_by')
          .eq('id', guideId)
          .single();

      final dislikedBy = List<String>.from(response['disliked_by'] ?? []);
      return dislikedBy.contains(userId);
    } catch (e) {
      debugPrint('Error checking if guide is disliked: $e');
      return false;
    }
  }

// Stream to get real-time updates on a specific post's likes
  Stream<int> getLikesStream(String postId) {
    return supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .map((data) => data.isNotEmpty ? data[0]['likes'] as int : 0);
  }

// Stream to get real-time updates on a post's liked_by array
  Stream<List<String>> getLikedByStream(String postId) {
    return supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .map((data) => data.isNotEmpty
            ? List<String>.from(data[0]['liked_by'] ?? [])
            : <String>[]);
  }

// Add a refresh key to trigger UI updates
  int _refreshKey = 0;
  int get refreshKey => _refreshKey;

  // Method to refresh posts data
  void refreshPosts() {
    clearPostsCache(); // Clear cache on refresh
    _refreshKey++;
    notifyListeners();
    debugPrint('🔄 Posts refresh triggered');
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    _commentControllers.clear();
    super.dispose();
  }

// Map to store local comments before they're confirmed from the server
  final Map<String, List<CommentModel>> _localComments = {};

  // Get comments combining both confirmed and pending comments
  Future<List<CommentModel>> getPostCommentsFuture(String postId) async {
    try {
      final data = await supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      final serverComments = data
          .map<CommentModel>((doc) => CommentModel.fromMap(doc['id'], doc))
          .toList();

      // Combine with any local comments that may not be confirmed yet
      final localComments = _localComments[postId] ?? [];

      return [...localComments, ...serverComments];
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return _localComments[postId] ?? [];
    }
  }

// Enhanced addComment with optimistic updates
  Future<CommentModel> addComment(PostModel post, String content) async {
    final user = globalUser;
    if (user == null) throw Exception("User not logged in");

    try {
      // Create a temporary comment for optimistic UI update
      final optimisticComment = CommentModel(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        postId: post.id,
        userId: user.uid,
        username: user.name,
        userProfileImage: user.profileImageUrl ?? '',
        content: content,
        createdAt: DateTime.now(),
      );

      // Add to local comments
      if (_localComments[post.id] == null) {
        _localComments[post.id] = [];
      }
      _localComments[post.id]!.insert(0, optimisticComment);

      // Notify listeners immediately for UI update
      notifyListeners();

      // Proceed with actual server update
      _isLoading = true;
      final userData =
          await supabase.from('users').select().eq('uid', user.uid).single();

      final userModel = UserModel.fromMap(user.uid, userData);

      final comment = CommentModel(
        id: '',
        postId: post.id,
        userId: user.uid,
        username: userModel.username,
        userProfileImage: userModel.profileImageUrl ?? '',
        content: content,
        createdAt: DateTime.now(),
      );

      final result =
          await supabase.from('comments').insert(comment.toMap()).select();

      await supabase.from('posts').update({
        'comments': post.comments + 1,
      }).eq('id', post.id);

      await addInterests(post.tags);

      NotificationSender().sendCommented(post);

      // Remove the optimistic comment once confirmed
      _localComments[post.id]?.removeWhere((c) => c.id == optimisticComment.id);

      return CommentModel.fromMap(result[0]['id'], result[0]);
    } catch (e) {
      // Remove the optimistic comment on error
      _localComments[post.id]?.removeWhere((c) => c.id.startsWith('temp-'));
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to add comment: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Add this method to clear local comments when switching posts or refreshing
  void clearLocalComments(String? postId) {
    if (postId != null) {
      _localComments.remove(postId);
    } else {
      _localComments.clear();
    }
  }

  // Get local comments for a post
  List<CommentModel> getLocalComments(String postId) {
    return _localComments[postId] ?? [];
  }

// Modify refreshComments to clear cache and local comments
  void refreshComments() {
    clearLocalComments(null);
    clearPostsCache(); // Also clear posts cache
    _refreshKey++;
    notifyListeners();
  }

  // Hidden posts methods
  bool isPostHidden(String postId) {
    return _hiddenPosts.contains(postId);
  }

  void hidePost(String postId) {
    _hiddenPosts.add(postId);
    notifyListeners();
    debugPrint('🔒 Post hidden: $postId');
  }

  void unhidePost(String postId) {
    _hiddenPosts.remove(postId);
    notifyListeners();
    debugPrint('🔓 Post unhidden: $postId');
  }

  Set<String> get hiddenPosts => Set.unmodifiable(_hiddenPosts);

  void clearHiddenPosts() {
    _hiddenPosts.clear();
    notifyListeners();
    debugPrint('🧹 All hidden posts cleared');
  }

  // Optimized pagination method for faster initial load
  Future<List<PostModel>> getPostsPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final data = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return data.map((post) => PostModel.fromMap(post['id'], post)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading paginated posts: $e');
      return [];
    }
  }

  // Cache for posts to avoid repeated fetches
  List<PostModel>? _cachedPosts;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Get posts with caching for super fast subsequent loads
  Future<List<PostModel>> getPostsWithCache({
    int limit = 10,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not expired
    if (!forceRefresh &&
        _cachedPosts != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry &&
        offset == 0) {
      return _cachedPosts!.take(limit).toList();
    }

    try {
      final data = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final posts =
          data.map((post) => PostModel.fromMap(post['id'], post)).toList();

      // Cache the first batch
      if (offset == 0) {
        _cachedPosts = posts;
        _lastFetchTime = DateTime.now();
      }

      return posts;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading posts with cache: $e');
      return _cachedPosts?.take(limit).toList() ?? [];
    }
  }

  // Clear cache when new post is added or data changes
  void clearPostsCache() {
    _cachedPosts = null;
    _lastFetchTime = null;
    debugPrint('🧹 Posts cache cleared');
  }

  // Add method to preload essential data only
  Future<void> preloadCriticalData(
      List<PostModel> posts, BuildContext context) async {
    // Preload only essential images (first few posts)
    final criticalPosts = posts.take(3).toList();

    for (final post in criticalPosts) {
      if (post.type == PostType.image && post.mediaUrls.isNotEmpty) {
        // Trigger image preloading in background
        try {
          await precacheImage(
            NetworkImage(post.mediaUrls.first),
            context,
          );
        } catch (e) {
          debugPrint('Error precaching image: $e');
        }
      }
    }
  }
}
