import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/guide.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/tip.dart';
import 'package:street_buddy/services/auth_sync_service.dart';
import 'package:street_buddy/services/location_services.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:uuid/uuid.dart';

enum SavedGuideFilter {
  all,
  recent,
  popular,
  nearby,
  others,
}

class GuideProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<List<File>> selectedImages = [];
  String _title = '';
  String _city = '';
  String _description = '';
  File? thumbnail;
  bool _isUploading = false;
  String _lastCreatedGuideId = ''; // Store the last created guide ID
  List<String> _tags = []; // Add tags property

  final TextEditingController cityController = TextEditingController();
  List<LocationModel> locationResults = [];
  final LocationService _locationService = LocationService();
  bool isSearching = false;
  bool citySearchBoxOpen = false;
  // Getters
  String get title => _title;
  String get city => _city;
  String get description => _description;
  bool get isUploading => _isUploading;
  bool get isValid => _title.isNotEmpty && _city.isNotEmpty;
  List<String> get tags => _tags; // Add tags getter
  String get lastCreatedGuideId =>
      _lastCreatedGuideId; // Getter for the last created guide ID
  SavedGuideFilter selectedFilter = SavedGuideFilter.all;
  TextEditingController searchQueryController = TextEditingController();

  // Ensure the selectedImages list has enough elements to prevent range errors
  void ensureGuideImageSpace(int guideNumber) {
    // Expand the list if needed
    while (selectedImages.length <= guideNumber) {
      selectedImages.add([]);
    }
    notifyListeners();
  }

  void notify() => notifyListeners();

  void citySearchBoxClose() {
    citySearchBoxOpen = false;
    notifyListeners();
  }

  void setFilter(SavedGuideFilter filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  Future<Color> getImagePalette(String url) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(NetworkImage(url));
    return paletteGenerator.dominantColor!.color;
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      citySearchBoxOpen = false;
      cityController.clear();
      locationResults = [];
      isSearching = false;
      notifyListeners();
      return;
    }
    citySearchBoxOpen = true;
    isSearching = true;
    notifyListeners();

    try {
      // Search citys (cities)
      locationResults = await _locationService.searchLocations(query);

      // Search places with user's location
      // if (_userPosition != null) {
      //   placeResults = await _locationService.searchPlacesByQuery(
      //     query,
      //     _userPosition!.latitude,
      //     _userPosition!.longitude,
      //   );
      // }

      notifyListeners();
    } catch (e) {
      debugPrint('Search error: $e');
      // cityController.clear();
      locationResults = [];
      isSearching = false;
      citySearchBoxClose();
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  // Reset all states
  void reset() {
    selectedImages = [];
    _title = '';
    _city = '';
    _description = '';
    _isUploading = false;
    cityController.clear();
    citySearchBoxClose();
    notifyListeners();
  }

  resetOnly(int i) {
    selectedImages[i].clear();
    notifyListeners();
  }

  void setImages(List<File> images, int i) {
    // Make sure the list has enough slots by filling with empty lists
    while (selectedImages.length <= i) {
      selectedImages.add([]);
    }

    selectedImages[i] = images;
    notifyListeners();
  }

  void setTitle(String title) {
    _title = title;
    notifyListeners();
  }

  void setcity(String city) {
    _city = city;
    notifyListeners();
  }

  void setDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void setLocation(double latitude, double longitude, int i) {
    // guideModels[i].lat = latitude;
    // guideModels[i].long = longitude;
    print('$latitude $longitude');
    notifyListeners();
  }

  void setThumbnail(File file) {
    thumbnail = file;
    notifyListeners();
  }

  void setPlace(String place, int i) {
    // if (guideModels.length <= i) {
    //   guideModels.add(GuideModel(
    //     id: '',
    //     userId: '',
    //     postId: '',
    //     username: '',
    //     userProfileImage: '',
    //     place: '',
    //     placeName: '',
    //     experience: '',
    //     tips: <TipModel>[],
    //     mediaUrls: [],
    //     createdAt: DateTime.now(),
    //   ));
    // }
    // guideModels[i].place = place;
    notifyListeners();
  }

  void setPlaceName(String placeName, int i) {
    // if (guideModels.length <= i) {
    //   guideModels.add(GuideModel(
    //     id: '',
    //     userId: '',
    //     postId: '',
    //     username: '',
    //     userProfileImage: '',
    //     place: '',
    //     placeName: '',
    //     experience: '',
    //     tips: <TipModel>[],
    //     mediaUrls: [],
    //     createdAt: DateTime.now(),
    //   ));
    // }
    // guideModels[i].placeName = placeName;
    notifyListeners();
  }

  void setExperience(String experience, int i) {
    // if (guideModels.length <= i) {
    //   guideModels.add(GuideModel(
    //     id: '',
    //     userId: '',
    //     postId: '',
    //     username: '',
    //     userProfileImage: '',
    //     place: '',
    //     placeName: '',
    //     experience: '',
    //     tips: <TipModel>[],
    //     mediaUrls: [],
    //     createdAt: DateTime.now(),
    //   ));
    // }
    // guideModels[i].experience = experience;
    notifyListeners();
  }

  // We no longer need tips as they're not in our updated models
  // Ensure guidePosts initialized
  List<GuideModel> guidePosts = [];

  void setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  Future<String> _uploadThumnail(File file) async {
    try {
      final String postId = DateTime.now().millisecondsSinceEpoch.toString();
      String thumbnailUrl = ''; // For images, just upload to images folder
      final String imagePath = 'guides/thumb/$postId.jpg';
      final ref = _storage.ref().child(imagePath);

      // Verify file exists and has valid path before upload
      if (!file.existsSync()) {
        debugPrint('⚠️ File does not exist: ${file.path}');
        throw Exception('File does not exist: ${file.path}');
      }
      try {
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {
          debugPrint('✅ Thumbnail upload completed');
        });
        // Wait briefly to ensure state transitions complete properly
        await Future.delayed(const Duration(milliseconds: 100));
        thumbnailUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint('❌ Thumbnail upload error: ${e.toString()}');
        // Try to sync auth in case that's the issue
        try {
          await AuthSyncService.syncSupabaseToFirebase();
          debugPrint('✅ Re-synced Firebase auth after upload error');

          // Try again after auth sync with error handling
          try {
            final uploadTask = ref.putFile(file);
            final snapshot = await uploadTask.whenComplete(() {
              debugPrint('✅ Thumbnail retry upload completed');
            });
            // Wait briefly to ensure state transitions complete properly
            await Future.delayed(const Duration(milliseconds: 100));
            thumbnailUrl = await snapshot.ref.getDownloadURL();
          } catch (uploadError) {
            // Handle specific task state errors that might occur during upload
            debugPrint('Upload error details: $uploadError');
            rethrow;
          }
        } catch (retryError) {
          debugPrint(
              '❌ Thumbnail upload retry failed: ${retryError.toString()}');
          rethrow;
        }
      }

      return thumbnailUrl;
    } catch (e) {
      debugPrint('❌ Thumbnail upload failed: $e');
      throw Exception('Failed to upload thumbnail: $e');
    }
  }

  Future<List<String>> _uploadMedia(int index) async {
    try {
      final String postId = DateTime.now().millisecondsSinceEpoch.toString();
      List<String> urls = []; // Ensure we're returning a string array

      // Make sure the index is valid
      if (selectedImages.length <= index || selectedImages[index].isEmpty) {
        debugPrint('⚠️ No images to upload for guide #$index');
        return []; // Return empty array
      }

      for (final (i, v) in selectedImages[index].indexed) {
        // Check if file exists and path is valid
        if (!v.existsSync()) {
          debugPrint('⚠️ File does not exist or has invalid path: ${v.path}');
          continue; // Skip this file and move to the next one
        }

        final String fileExtension = v.path.split('.').last.toLowerCase();
        final String imagePath = fileExtension == 'mp4'
            ? 'guides/$postId/vid$i.mp4'
            : 'guides/$postId/image$i.jpg';
        final ref = _storage.ref().child(imagePath);
        String mediaUrl = '';

        try {
          // Use the v file directly without recreating File object
          final uploadTask = ref.putFile(v);

          // Handle task completion with graceful error handling
          final snapshot = await uploadTask.whenComplete(() {
            debugPrint('✅ Media upload completed for item $i');
          });

          // Wait briefly to ensure state transitions complete properly
          await Future.delayed(const Duration(milliseconds: 100));

          mediaUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          debugPrint('❌ Media upload error: ${e.toString()}');
          // Try to sync auth in case that's the issue
          try {
            await AuthSyncService.syncSupabaseToFirebase();
            debugPrint('✅ Re-synced Firebase auth after upload error');

            // Try again after auth sync with improved error handling
            try {
              final uploadTask = ref.putFile(v);

              // Handle task completion with graceful error handling
              final snapshot = await uploadTask.whenComplete(() {
                debugPrint('✅ Media retry upload completed for item $i');
              });

              // Wait briefly to ensure state transitions complete properly
              await Future.delayed(const Duration(milliseconds: 100));

              mediaUrl = await snapshot.ref.getDownloadURL();
            } catch (uploadError) {
              debugPrint('Upload error details: $uploadError');
              // If this is the only image and it fails completely, throw an exception
              if (selectedImages[index].length == 1) {
                throw Exception('Failed to upload media: $uploadError');
              } else {
                // If we have other images, just log the error and continue with what we have
                debugPrint('⚠️ Skipping problematic image: ${v.path}');
                continue;
              }
            }
          } catch (retryError) {
            debugPrint('❌ Media upload retry failed: ${retryError.toString()}');
            // If this is the only image and it fails completely, throw an exception
            if (selectedImages[index].length == 1) {
              throw Exception('Failed to upload media: $retryError');
            } else {
              // If we have other images, just log the error and continue with what we have
              debugPrint('⚠️ Skipping problematic image: ${v.path}');
              continue;
            }
          }
        }

        // Only add URLs that were successfully obtained
        if (mediaUrl.isNotEmpty) {
          urls.add(mediaUrl);
        }
      }

      return urls;
    } catch (e) {
      debugPrint('❌ Media upload failed: $e');
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<void> createPost({
    required UserModel user,
    required String postId,
    required int i,
    required DateTime date,
  }) async {
    try {
      setUploading(true);

      final urls = await _uploadMedia(i);

      // Insert the guide post - ensure media_urls is sent as a string array
      await supabase.from('guide_posts').insert({
        'user_id': user.uid,
        'post_id': postId,
        'username': user.username,
        'user_profile_image': user.profileImageUrl ?? '',
        'place': '',
        'place_name': '',
        'experience': '',
        'media_urls': urls, // Already a string array from _uploadMedia
        'created_at': date.toIso8601String(),
        'lat': 0.0,
        'long': 0.0,
      });

      // If this is the first post (i == 0) and we have media URLs,
      // update the main guide's thumbnail_url with the first image
      if (i == 0 && urls.isNotEmpty) {
        await supabase.from('guides').update({
          'thumbnail_url': urls[0], // Use the first image URL as thumbnail
          'media_url': urls[0], // Also update media_url for consistency
        }).eq('id', postId);

        debugPrint(
            '✅ Updated main guide thumbnail with first image URL: ${urls[0]}');
      }
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  Future<void> createGuide({required UserModel user}) async {
    if (!isValid) {
      throw Exception('Please fill in all required fields');
    }

    final createdDate = DateTime.now();
    try {
      setUploading(true);
      String thumbnailUrl = '';

      if (selectedImages.isEmpty ||
          selectedImages.every((images) => images.isEmpty)) {
        throw Exception('At least one image is required to create a guide');
      }

      if (thumbnail != null) {
        thumbnailUrl = await _uploadThumnail(thumbnail!);
      } else if (selectedImages.isNotEmpty && selectedImages[0].isNotEmpty) {
        thumbnailUrl = await _uploadThumnail(selectedImages[0][0]);
      }
      final guideId = const Uuid().v4();
      _lastCreatedGuideId = guideId; // Save the guide ID for later use

      // Create the main guide entry in the 'guides' table
      await supabase.from('guides').insert({
        'id': guideId,
        'user_id': user.uid,
        'username': user.username,
        'user_profile_image': user.profileImageUrl ?? '',
        'title': _title,
        'description': _description,
        'location': _city,
        'tags': _tags, // Using the tags array set by setTags
        'is_private': false,
        'media_urls': [], // Empty array of strings
        'thumbnail_url': thumbnailUrl,
        'type': 'guide',
        'created_at': createdDate.toIso8601String(),
        'likes': 0,
        'comments': 0,
        'liked_by': [],
        'dislikes': 0,
        'disliked_by': [],
        'rating': 0.0, 'reviews': 0
      });

      // Process each guide post
      for (int i = 0; i < guidePosts.length; i++) {
        final post = guidePosts[i];
        // Upload images for this place
        List<String> mediaUrls = [];
        if (selectedImages.length > i && selectedImages[i].isNotEmpty) {
          mediaUrls = await _uploadMedia(i);
        }

        // Create a new map with the uploaded media_urls
        final postMap = {
          'user_id': user.uid,
          'post_id': guideId,
          'username': user.username,
          'user_profile_image': user.profileImageUrl ?? '',
          'place': post.place,
          'place_name': post.placeName,
          'experience': post.experience,
          'media_urls': mediaUrls, // Use the array of URLs we just uploaded
          'created_at': createdDate.toIso8601String(),
          'lat': post.lat,
          'long': post.long,
        };
        await supabase.from('guide_posts').insert(postMap);

        // If this is the first post, update the main guide's media_urls as well
        if (i == 0 && mediaUrls.isNotEmpty) {
          await supabase
              .from('guides')
              .update({'media_urls': mediaUrls}).eq('id', guideId);
        }
      }

      // Store the last created guide ID
      _lastCreatedGuideId = guideId;

      reset();
    } catch (e) {
      throw Exception('Failed to create guide: $e');
    } finally {
      setUploading(false);
    }
  }

  // Convert from Stream to Future
  Future<List<GuideModel>> getGuidePosts(String postId) async {
    try {
      final response = await supabase
          .from('guide_posts')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: false);
      return response
          .map<GuideModel>((data) => GuideModel.fromMap(data['id'], data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching guide posts: $e');
      return [];
    }
  }

  Future<List<PostModel>> getUserSavedGuidesFuture(
      String userId, String searchQuery) async {
    try {
      // Handle empty userId case
      if (userId.isEmpty) {
        return [];
      }

      // Get the user's saved guides
      final userResponse = await supabase
          .from('users')
          .select('saved_guides')
          .eq('uid', userId)
          .maybeSingle();

      // If user not found or saved_guides is null, return empty list
      if (userResponse == null) {
        debugPrint('User not found: $userId');
        return [];
      }

      List savedGuides = userResponse['saved_guides'] ?? [];
      List<PostModel> savedGuidesList = [];

      // Fetch each guide individually and handle non-existent guides gracefully
      for (var guideId in savedGuides) {
        try {
          final response = await supabase
              .from('guides')
              .select()
              .eq('id', guideId)
              .maybeSingle();

          // Skip if guide not found
          if (response == null) {
            debugPrint('Guide not found: $guideId');
            continue;
          }

          final post = PostModel.fromMap(response['id'], response);
          savedGuidesList.add(post);
        } catch (guideError) {
          // Log error but continue with other guides
          debugPrint('Error fetching guide $guideId: $guideError');
          continue;
        }
      }

      if (selectedFilter == SavedGuideFilter.recent) {
        savedGuidesList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else if (selectedFilter == SavedGuideFilter.popular) {
        savedGuidesList.sort((a, b) => b.likes
            .compareTo(a.likes)); // Changed to sort by most likes (descending)
      }

      if (searchQuery.isNotEmpty) {
        savedGuidesList = savedGuidesList
            .where((post) =>
                post.title.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }
      return savedGuidesList;
    } catch (e) {
      debugPrint('Error in getUserSavedGuidesFuture: $e');
      return [];
    }
  }

  Future<bool> isGuideSaved(String userId, String guideId) async {
    try {
      if (userId.isEmpty || guideId.isEmpty) {
        return false;
      }

      final data = await supabase
          .from('users')
          .select('saved_guides')
          .eq('uid', userId)
          .single();

      List savedGuides = data['saved_guides'] ?? [];

      if (savedGuides.contains(guideId)) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error in saveGuide: $e');
      return false;
    }
  }

  Future<void> deleteGuide(PostModel post) async {
    try {
      final user = globalUser;
      if (user == null) return;

      // Delete main guide
      await supabase
          .from('guides')
          .delete()
          .eq('id', post.id)
          .eq('user_id', user.uid);

      // Delete associated guide posts
      await supabase.from('guide_posts').delete().eq('post_id', post.id);
    } catch (e) {
      debugPrint('Error deleting guide: $e');
    }
  }

  Future<void> deleteGuidePost(GuideModel gpost) async {
    try {
      final user = globalUser;
      if (user == null) return;

      await supabase
          .from('guide_posts')
          .delete()
          .eq('id', gpost.id)
          .eq('user_id', user.uid);
    } catch (e) {
      debugPrint('Error deleting guide post: $e');
    }
  }

  Future<void> updateThumbnail(PostModel post, String url) async {
    try {
      final user = globalUser;
      if (user == null) return;

      await supabase
          .from('guides')
          .update({'thumbnail_url': url}).eq('id', post.id);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

//? update guide rating
  Future<void> updateRating(
      PostModel post, String ratingtext, int i, int myrating) async {
    try {
      final user = globalUser;
      if (user == null) return;

      // First get the existing guide post
      final data = await supabase
          .from('guides')
          .select('description, user_id, rating, reviews')
          .eq('id', post.id)
          .single();

      String currentDescription = data['description'] ?? '';
      String postUserId = data['user_id'];
      double currentRating = (data['rating'] ?? 0.0).toDouble();
      int currentReviews = (data['reviews'] ?? 0).toInt();

      // Check if this user is the owner of the post
      if (postUserId != user.uid) {
        throw Exception('You can only review guides you created');
      }

      // Format new review text with timestamp
      String timestamp = DateTime.now().toIso8601String();
      String reviewEntry = '[${user.email} - $timestamp - Rating: $i]';

      String newDescription;
      if (currentDescription.isEmpty) {
        newDescription = reviewEntry;
      } else {
        newDescription = '$currentDescription\n$reviewEntry';
      }

      // Calculate new average rating
      double newRating =
          ((currentRating * currentReviews) + i) / (currentReviews + 1);
      int newReviews = currentReviews + 1;

      // Update the guide with new review data
      await supabase.from('guides').update({
        'description': newDescription,
        'rating': newRating,
        'reviews': newReviews
      }).eq('id', post.id);
    } catch (e) {
      debugPrint('Error updating review: $e');
      rethrow; // Rethrow to handle in UI
    }
  } // Methods for handling tips

  Future<List<TipModel>> getGuideTips(String guideId) async {
    try {
      final response = await supabase
          .from('tips')
          .select()
          .eq('guide_id', guideId)
          .order('id', ascending: true);
      return response
          .map<TipModel>((data) => TipModel.fromMap(data['id'], data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching guide tips: $e');
      return [];
    }
  }

  Future<void> addTipToGuide(String guideId, String tipText) async {
    try {
      final tipData = {
        'guide_id': guideId,
        'tip_text': tipText,
        'likes': 0,
        'dislikes': 0,
      };

      await supabase.from('tips').insert(tipData);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding tip: $e');
      throw Exception('Failed to add tip: $e');
    }
  }

  Future<void> likeTip(String tipId, bool isLike) async {
    if (globalUser == null) {
      debugPrint('Cannot like/dislike tip: No user logged in');
      return;
    }

    String userId = globalUser!.uid;

    try {
      // Step 1: Get current tip counts
      final response = await supabase
          .from('tips')
          .select('likes, dislikes')
          .eq('id', tipId)
          .single();

      int likes = response['likes'] ?? 0;
      int dislikes = response['dislikes'] ?? 0;

      // Step 2: Check if tip_interactions table exists, create if it doesn't
      bool tableExists = await _checkTableExists('tip_interactions');
      if (!tableExists) {
        debugPrint('Creating tip_interactions table');
        try {
          // Note: In a production app, this should be done via database migration,
          // not in the app code. This is just for demonstration purposes.
          await supabase.rpc('create_tip_interactions_table');
        } catch (e) {
          debugPrint('Error creating tip_interactions table: $e');
          // Continue execution, will try to use local tracking instead
        }
      }

      // Step 3: Check user's current interaction
      Map<String, dynamic> userInteraction =
          await getUserTipInteraction(tipId, userId);
      bool hasLiked = userInteraction['has_liked'];
      bool hasDisliked = userInteraction['has_disliked'];

      // Step 4: Handle like/dislike logic with mutual exclusivity
      try {
        // Like case
        if (isLike) {
          // If already liked, do nothing
          if (hasLiked) return;

          // If previously disliked, remove dislike first
          if (hasDisliked) {
            // Decrement dislike count
            await supabase.from('tips').update(
                {'dislikes': dislikes > 0 ? dislikes - 1 : 0}).eq('id', tipId);

            // Increment like count and update interaction
            await supabase
                .from('tips')
                .update({'likes': likes + 1}).eq('id', tipId);

            // Update interaction record (if table exists)
            if (tableExists) {
              await supabase.from('tip_interactions').upsert({
                'tip_id': tipId,
                'user_id': userId,
                'interaction_type': 'like'
              });
            }
          } else {
            // Just add like
            await supabase
                .from('tips')
                .update({'likes': likes + 1}).eq('id', tipId);

            // Create interaction record (if table exists)
            if (tableExists) {
              await supabase.from('tip_interactions').upsert({
                'tip_id': tipId,
                'user_id': userId,
                'interaction_type': 'like'
              });
            }
          }
        }
        // Dislike case
        else {
          // If already disliked, do nothing
          if (hasDisliked) return;

          // If previously liked, remove like first
          if (hasLiked) {
            // Decrement like count
            await supabase
                .from('tips')
                .update({'likes': likes > 0 ? likes - 1 : 0}).eq('id', tipId);

            // Increment dislike count and update interaction
            await supabase
                .from('tips')
                .update({'dislikes': dislikes + 1}).eq('id', tipId);

            // Update interaction record (if table exists)
            if (tableExists) {
              await supabase.from('tip_interactions').upsert({
                'tip_id': tipId,
                'user_id': userId,
                'interaction_type': 'dislike'
              });
            }
          } else {
            // Just add dislike
            await supabase
                .from('tips')
                .update({'dislikes': dislikes + 1}).eq('id', tipId);

            // Create interaction record (if table exists)
            if (tableExists) {
              await supabase.from('tip_interactions').upsert({
                'tip_id': tipId,
                'user_id': userId,
                'interaction_type': 'dislike'
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error updating tip interaction: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error in likeTip: $e');
    }
  }

  Future<void> removeTip(String tipId) async {
    try {
      await supabase.from('tips').delete().eq('id', tipId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing tip: $e');
    }
  }

  void setTags(List<String> tags) {
    _tags = List<String>.from(tags);
    notifyListeners();
  }

  // Add to GuideProvider class
  Future<Map<String, dynamic>> getUserTipInteraction(
      String tipId, String userId) async {
    try {
      // First check if tip_interactions table exists
      bool tableExists = await _checkTableExists('tip_interactions');
      if (!tableExists) {
        // If table doesn't exist, return default no interaction state
        return {
          'has_liked': false,
          'has_disliked': false,
        };
      }

      final response = await supabase
          .from('tip_interactions')
          .select('interaction_type')
          .eq('tip_id', tipId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return {
          'has_liked': false,
          'has_disliked': false,
        };
      }

      final String interactionType = response['interaction_type'];
      return {
        'has_liked': interactionType == 'like',
        'has_disliked': interactionType == 'dislike',
      };
    } catch (e) {
      debugPrint('Error getting user tip interaction: $e');
      return {
        'has_liked': false,
        'has_disliked': false,
      };
    }
  }

  // Helper method to check if a table exists
  Future<bool> _checkTableExists(String tableName) async {
    try {
      await supabase.from(tableName).select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshSavedGuides(String userId, String searchQuery) async {
    try {
      // Get the data and explicitly notify listeners to update UI
      await getUserSavedGuidesFuture(userId, searchQuery);
      notifyListeners();
    } catch (e) {
      debugPrint('Error in refreshSavedGuides: $e');
    }
  }
}
