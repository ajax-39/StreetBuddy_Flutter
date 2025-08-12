import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:street_buddy/models/message.dart';
import 'package:street_buddy/provider/MainScreen/message_provider.dart';
import 'package:street_buddy/services/push_notification_service.dart';
import 'package:video_compress/video_compress.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/constants.dart';
import 'package:http/http.dart' as http;

// Simple Media class for backward compatibility
class Media {
  final String id;
  final Widget widget;
  File file;

  Media({
    required this.id,
    required this.widget,
    required this.file,
  });

  // For backward compatibility with old assetEntity.id references
  MockAssetEntity get assetEntity => MockAssetEntity(id);
}

class MockAssetEntity {
  final String id;
  final MockSize size;

  MockAssetEntity(this.id) : size = MockSize();
}

class MockSize {
  final double aspectRatio = 1.0; // Default to square aspect ratio
}

enum CreatePostType {
  post,
  guide,
}

class UploadProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _selectedMedia;
  File? _thumbnail;
  PostType? _mediaType;
  String _title = '';
  String _description = '';
  String? _location;
  bool _isUploading = false;
  int _duration = 0;

  CreatePostType? _createPostType;
  List<Media> _selectedMedias = [];
  bool _isPublic = true;
  final tagsController = TextEditingController();
  final List<String> _tags = [];

  List<PostModel>? _previousUserPosts;
  List<PostModel>? _previousUserGuides;

  // Getters
  File? get selectedMedia => _selectedMedia;
  File? get thumbnail => _thumbnail;
  PostType? get mediaType => _mediaType;
  String get title => _title;
  String get description => _description;
  String? get location => _location;
  bool get isUploading => _isUploading;
  bool get isValid =>
      _selectedMedias.isNotEmpty &&
      _title.isNotEmpty &&
      _description.isNotEmpty;
  bool get isMsgValid {
    final isValid = _selectedMedia != null;
    print(
        '🔍 [DEBUG] isMsgValid check: $isValid (selectedMedia: ${_selectedMedia?.path})');
    return isValid;
  }

  int get duration => _duration;

  CreatePostType? get createPostType => _createPostType;
  List<Media> get selectedMedias => _selectedMedias;
  bool get isPublic => _isPublic;
  List<String> get tags => _tags;

  List<PostModel>? get previousUserPosts => _previousUserPosts;
  List<PostModel>? get previousUserGuides => _previousUserGuides;

  void setDuration(int seconds) {
    _duration = seconds;
    print("Duration set to: $_duration seconds");
    notifyListeners();
  }

  void setCreatePostType(CreatePostType type) {
    _createPostType = type;
    notifyListeners();
  }

  void setSelectedMedias(List<Media> medias) {
    _selectedMedias = medias;
    notifyListeners();
  }

  void setSingleSelectedMedias(File file, int index) {
    _selectedMedias[index].file = file;
    notifyListeners();
  }

  void setPublic(bool value) {
    _isPublic = value;
    notifyListeners();
  }

  void onTextChanged(String value) {
    if (value.endsWith(' ')) {
      _tags.add("#${value.split(' ').first.toLowerCase()}");
      tagsController.clear();
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  PostType getPostType(File file) {
    if (file.path.endsWith('.mp4') ||
        file.path.endsWith('.mov') ||
        file.path.endsWith('.avi')) {
      return PostType.video;
    } else {
      return PostType.image;
    }
  }

  // Generate thumbnail for video using video_compress
  Future<void> generateThumbnail(File videoFile) async {
    if (_mediaType != PostType.video) return;

    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 50, // Lower number means smaller file size
        position: -1, // -1 means center of video
      );

      _thumbnail = thumbnailFile;
      notifyListeners();
      print("Thumbnail generated successfully");
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  // Set media and generate thumbnail if it's a video
  Future<void> setMedia(File media, PostType type) async {
    print('🔧 [DEBUG] setMedia called with: ${media.path}, type: $type');
    _selectedMedia = media;
    _mediaType = type;
    _thumbnail = null;

    if (type == PostType.video) {
      print('🎥 [DEBUG] Generating thumbnail for video');
      await generateThumbnail(media);
    }

    print(
        '✅ [DEBUG] Media set successfully - _selectedMedia: ${_selectedMedia?.path}, _mediaType: $_mediaType');
    notifyListeners();
  }

  // Reset all states
  void reset() {
    _selectedMedia = null;
    _tags.clear();
    _thumbnail = null;
    _mediaType = null;
    _title = '';
    _description = '';
    _location = null;
    _isUploading = false;
    // _selectedMedias = [];
    notifyListeners();
  }

  void setTitle(String title) {
    _title = title;
    notifyListeners();
  }

  void setDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void setLocation(String? location) {
    _location = location;
    notifyListeners();
  }

  void setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  // Upload media (video/image) and thumbnail if it's a video
  Future<Map<String, String>> _uploadMedia(File file, PostType type) async {
    try {
      final String postId = DateTime.now().millisecondsSinceEpoch.toString();
      String mediaUrl;
      String? thumbnailUrl;

      if (type == PostType.video) {
        // Create a folder for this specific video post
        final String videoPath = 'posts/$postId/video.mp4';
        final String thumbnailPath = 'posts/$postId/thumbnail.jpg';

        // Upload video
        final videoRef = _storage.ref().child(videoPath);
        final videoUploadTask = videoRef.putFile(file);
        final videoSnapshot = await videoUploadTask.whenComplete(() {});
        mediaUrl = await videoSnapshot.ref.getDownloadURL();

        // Upload thumbnail if available
        if (_thumbnail != null) {
          final thumbnailRef = _storage.ref().child(thumbnailPath);
          final thumbnailUploadTask = thumbnailRef.putFile(_thumbnail!);
          final thumbnailSnapshot =
              await thumbnailUploadTask.whenComplete(() {});
          thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
        }
      } else {
        // For images, just upload to images folder
        final String imagePath = 'posts/images/$postId.jpg';
        final ref = _storage.ref().child(imagePath);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        mediaUrl = await snapshot.ref.getDownloadURL();
      }

      return {
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl ?? '',
      };
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<Map<String, String>> _uploadMediaMessage(
      File file, PostType type, String time, String convId) async {
    try {
      // final String postId = DateTime.now().millisecondsSinceEpoch.toString();
      String mediaUrl;
      String? thumbnailUrl;

      if (type == PostType.video) {
        // Create a folder for this specific video post
        final String videoPath = 'chats/$convId/$time/video.mp4';
        final String thumbnailPath = 'chats/$convId/$time/thumbnail.jpg';

        // Upload video
        final videoRef = _storage.ref().child(videoPath);
        final videoUploadTask = videoRef.putFile(file);
        final videoSnapshot = await videoUploadTask.whenComplete(() {});
        mediaUrl = await videoSnapshot.ref.getDownloadURL();

        // Upload thumbnail if available
        if (_thumbnail != null) {
          final thumbnailRef = _storage.ref().child(thumbnailPath);
          final thumbnailUploadTask = thumbnailRef.putFile(_thumbnail!);
          final thumbnailSnapshot =
              await thumbnailUploadTask.whenComplete(() {});
          thumbnailUrl = await thumbnailSnapshot.ref.getDownloadURL();
        }
      } else {
        // For images, just upload to images folder
        final String imagePath = 'chats/$convId/$time/image.jpg';
        final ref = _storage.ref().child(imagePath);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        mediaUrl = await snapshot.ref.getDownloadURL();
      }

      return {
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl ?? '',
      };
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<void> createPost({
    required UserModel user,
  }) async {
    if (!isValid) {
      throw Exception('Please fill in all required fields');
    }

    try {
      setUploading(true);

      // Upload media and get URLs
      List<String> urls = [];
      String? thumbnailUrl;
      for (var media in _selectedMedias) {
        final data = await _uploadMedia(media.file, getPostType(media.file));
        urls.add(data['mediaUrl'].toString());
        if (_selectedMedias.first.assetEntity.id == media.assetEntity.id) {
          thumbnailUrl = data['thumbnailUrl'];
        }
      }

      // // Extract tags from description
      // final List<String> tags = PostModel.extractTags(_description);

      // Get user's Supabase UUID using the uid from Firebase
      // final supabaseUser = await _supabase
      //     .from('users')
      //     .select('id')
      //     .eq('uid', user.uid)
      //     .single();
      // debugPrint('User  supabase ID: ${supabaseUser['uid']}');
      // debugPrint('User ID: ${user.uid}');
      // Create post in Supabase using the correct schema
      await _supabase
          .from('posts')
          .insert({
            'user_id': user.uid,
            'username': user.username,
            'user_profile_image': user.profileImageUrl ?? '',
            'title': _title,
            'description': _description,
            'location': _location ?? '',
            'tags': _tags,
            'type': getPostType(_selectedMedias.first.file)
                .toString()
                .split('.')
                .last,
            'media_urls': urls,
            'thumbnail_url': thumbnailUrl ?? '',
            'is_private': false // Default value
          })
          .select('id')
          .single();

      // Update user's post count
      final currentUser = await _supabase
          .from('users')
          .select('post_count')
          .eq('uid', user.uid)
          .single();

      await _supabase
          .from('users')
          .update({'post_count': (currentUser['post_count'] ?? 0) + 1}).eq(
              'uid', user.uid);

      // Refresh user's posts cache to immediately show the new post
      await refreshUserPosts(user.uid);

      // Trigger refresh for other parts of the app that show posts
      notifyListeners();

      reset();
    } catch (e) {
      debugPrint('Create post error: $e');
      throw Exception('Failed to create post: $e');
    } finally {
      setUploading(false);
    }
  }

  Future<void> createMediaMessage({
    required UserModel chatUser,
    required UserModel user,
  }) async {
    if (!isMsgValid) {
      throw Exception('Please select media to send');
    }

    if (_selectedMedia == null) {
      throw Exception('No media selected');
    }

    if (_mediaType == null) {
      throw Exception('Media type not determined');
    }

    try {
      setUploading(true);

      // Upload media and get URLs
      final time = DateTime.now().millisecondsSinceEpoch.toString();

      final urls = await _uploadMediaMessage(_selectedMedia!, _mediaType!, time,
          MessageProvider.getConversationID(chatUser.uid));

      final ChatMessageModel message = ChatMessageModel(
          toId: chatUser.uid,
          msg: '${urls['mediaUrl']} ${urls['thumbnailUrl']}',
          read: '',
          type: _mediaType == PostType.video ? 'video' : 'image',
          fromId: user.uid,
          sent: time);

      // Add to Firestore
      final ref = _firestore.collection(
          'chats/${MessageProvider.getConversationID(chatUser.uid)}/messages/');
      await ref.doc(time).set(message.toJson());
      await _firestore
          .collection('users/${user.uid}/myusers/')
          .doc(chatUser.uid)
          .set({'convId': MessageProvider.getConversationID(chatUser.uid)});
      await _firestore
          .collection('users/${chatUser.uid}/myusers/')
          .doc(user.uid)
          .set({'convId': MessageProvider.getConversationID(chatUser.uid)});

      await _firestore
          .collection('users/${chatUser.uid}/pref')
          .doc('token')
          .get()
          .then(
        (token) {
          if (token.exists) {
            PushNotificationService.sendPushNotification(
                token.data()!['token'].toString(),
                'New Message',
                '${chatUser.username} sent you a media',
                '/messages?uid=${chatUser.uid}',
                'message');
          }
        },
      );

      reset();
    } catch (e) {
      throw Exception('Failed to create post: $e');
    } finally {
      setUploading(false);
    }
  }

  // New methods for FutureBuilder support
  Future<List<PostModel>> getUserPostsFuture(String userId) async {
    try {
      final data = await _supabase
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data.map((post) => PostModel.fromMap(post['id'], post)).toList();
    } catch (e) {
      debugPrint('Error in getUserPostsFuture: $e');
      return [];
    }
  }

  Future<List<PostModel>> getUserGuidesFuture(String userId) async {
    try {
      final data = await _supabase
          .from('guides')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data
          .map((guide) => PostModel.fromMap(guide['id'], guide))
          .toList();
    } catch (e) {
      debugPrint('Error in getUserGuidesFuture: $e');
      return [];
    }
  }

  // Cache for post and guide data
  final Map<String, Future<List<PostModel>>> _postsCache = {};
  final Map<String, Future<List<PostModel>>> _guidesCache = {};

  // Methods to refresh data
  Future<List<PostModel>> refreshUserPosts(String userId) async {
    if (_previousUserPosts != null) {
      // Keep previous posts available while fetching new ones
      final posts = getUserPostsFuture(userId);
      posts
          .then((newPosts) => {savePreviousPosts(newPosts), notifyListeners()});
      _postsCache[userId] = posts;
      return posts;
    } else {
      final posts = getUserPostsFuture(userId);
      _postsCache[userId] = posts;
      posts
          .then((newPosts) => {savePreviousPosts(newPosts), notifyListeners()});
      return posts;
    }
  }

  Future<List<PostModel>> refreshUserGuides(String userId) async {
    if (_previousUserGuides != null) {
      // Keep previous guides available while fetching new ones
      final guides = getUserGuidesFuture(userId);
      guides.then(
          (newGuides) => {savePreviousGuides(newGuides), notifyListeners()});
      _guidesCache[userId] = guides;
      return guides;
    } else {
      final guides = getUserGuidesFuture(userId);
      _guidesCache[userId] = guides;
      guides.then(
          (newGuides) => {savePreviousGuides(newGuides), notifyListeners()});
      return guides;
    }
  }

  // Get cached data or refresh if not available
  Future<List<PostModel>> getCachedOrFreshUserPosts(String userId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || !_postsCache.containsKey(userId)) {
      return refreshUserPosts(userId);
    }
    return _postsCache[userId] ?? refreshUserPosts(userId);
  }

  Future<List<PostModel>> getCachedOrFreshUserGuides(String userId,
      {bool forceRefresh = false}) async {
    if (forceRefresh || !_guidesCache.containsKey(userId)) {
      return refreshUserGuides(userId);
    }
    return _guidesCache[userId] ?? refreshUserGuides(userId);
  }

  Stream<List<PostModel>> getUserPosts(String firebaseUid) async* {
    try {
      // No need to look up the user in Supabase first
      // The firebaseUid is directly stored in the 'user_id' field of posts table
      yield* _supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .eq('user_id', firebaseUid) // Use the Firebase UID directly
          .order('created_at', ascending: false)
          .map((data) {
            return data
                .map((post) => PostModel.fromMap(post['id'], post))
                .toList();
          });
    } catch (e) {
      debugPrint('Error in getUserPosts: $e');
      yield [];
    }
  }

  Stream<List<PostModel>> getUserGuides(String userId) {
    return _supabase
        .from('guides')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((guide) => PostModel.fromMap(guide['id'], guide))
            .toList());
  }

  Future<void> incrementPostCount(String userId) async {
    try {
      final user = await _supabase
          .from('users')
          .select('post_count')
          .eq('uid', userId)
          .single();

      await _supabase.from('users').update(
          {'post_count': (user['post_count'] ?? 0) + 1}).eq('uid', userId);
    } catch (e) {
      debugPrint('Error incrementing post count: $e');
      throw Exception('Failed to increment post count');
    }
  }

  Future<void> decrementPostCount(String userId) async {
    try {
      final user = await _supabase
          .from('users')
          .select('post_count')
          .eq('uid', userId)
          .single();

      await _supabase.from('users').update(
          {'post_count': (user['post_count'] ?? 1) - 1}).eq('uid', userId);
    } catch (e) {
      debugPrint('Error decrementing post count: $e');
      throw Exception('Failed to decrement post count');
    }
  }

  void savePreviousPosts(List<PostModel> posts) {
    _previousUserPosts = List.from(posts);
  }

  void savePreviousGuides(List<PostModel> guides) {
    _previousUserGuides = List.from(guides);
  }

  // Google Places search functionality for guides
  Future<List<PlaceModel>> searchPlacesWithGoogle(String query) async {
    try {
      if (query.length < 2) return [];

      debugPrint('Searching Google Places for: $query');

      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/place/textsearch/json')
            .replace(queryParameters: {
          'query': query,
          'key': Constant.GOOGLE_API,
          'type': 'establishment',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        final places = <PlaceModel>[];

        for (final result in results) {
          try {
            final geometry = result['geometry']?['location'];
            if (geometry == null) continue;

            final types =
                (result['types'] as List?)?.map((t) => t.toString()).toList() ??
                    [];

            final rating = result['rating']?.toDouble() ?? 0.0;
            final userRatingsTotal = result['user_ratings_total'] ?? 0;
            final openNow = result['opening_hours']?['open_now'] ?? false;

            places.add(PlaceModel(
              id: result['place_id'] ?? '',
              name: result['name'] ?? 'Unknown Place',
              city: result['formatted_address'] ?? '',
              rating: rating,
              userRatingsTotal: userRatingsTotal,
              openNow: openNow,
              latitude: geometry['lat']?.toDouble() ?? 0,
              longitude: geometry['lng']?.toDouble() ?? 0,
              types: types,
            ));
          } catch (e) {
            debugPrint('Error processing Google Places result: $e');
          }
        }

        return places;
      } else {
        debugPrint('Google Places API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Google Places search error: $e');
      return [];
    }
  }
}
