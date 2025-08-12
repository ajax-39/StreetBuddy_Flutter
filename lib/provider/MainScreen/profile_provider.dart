import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/services/push_notification_service.dart';

class ProfileProvider extends ChangeNotifier {
  bool isPrivate = false;
  bool _isImageLoading = false; 
  bool _imageLoadError = false;
  bool _isUpdating = false;
  String? _error;
  UserModel? _userData;
  bool isLoading = false; 
  bool get isImageLoading => _isImageLoading;
  bool get imageLoadError => _imageLoadError;
  bool get isUpdating => _isUpdating;
  String? get error => _error;
  UserModel? get userData => _userData;

  final _supabase = Supabase.instance.client;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> fetchUserData(String uid) async {
    debugPrint('Fetching user data for uid: $uid');
    try {
      final response =
          await _supabase.from('users').select().eq('uid', uid).maybeSingle();

      if (response != null) {
        _userData = UserModel.fromMap(uid, response);
        _error = null;
        debugPrint('User data fetched successfully');
      } else {
        _error = 'User data not found';
        debugPrint('User data not found for uid: $uid');
      }
    } catch (e) {
      _error = 'Error fetching user data: $e';
      debugPrint(_error);
    } finally {
      notifyListeners();
    }
  }

  Future<UserModel> fetchUserDataFuture(String uid) async {
    try {
      final response =
          await _supabase.from('users').select().eq('uid', uid).single();

      _userData = UserModel.fromMap(uid, response);
      _error = null;
      notifyListeners();
      return _userData!;
    } catch (e) {
      _error = 'Error fetching user data: $e';
      throw Exception(_error);
    }
  }

  // Methods to add to ProfileProvider class
  Stream<List<dynamic>> getRequestsStream(String uid) {
    return Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('uid', uid)
        .map((data) => data.isNotEmpty ? (data.first['requests'] ?? []) : []);
  }

  Future<bool> isUserVIP(String userId) async {
    final data = await Supabase.instance.client
        .from('users')
        .select('is_vip')
        .eq('uid', userId)
        .maybeSingle();
    return data?['is_vip'] == true;
  }

  void systemHandlerUpdateOnline(String uid) {
    updateOnlineStatus(true, uid);

    SystemChannels.lifecycle.setMessageHandler(
      (message) {
        if (message.toString().contains('resume')) {
          updateOnlineStatus(true, uid);
        }
        if (message.toString().contains('pause')) {
          updateOnlineStatus(false, uid);
        }
        return Future.value(message);
      },
    );
  }

  Future<void> updateOnlineStatus(bool status, String uid) async {
    await _supabase.from('users').update({'is_online': status}).eq('uid', uid);
  }

  Future<bool> checkOnlineStatus(String uid) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_online')
          .eq('uid', uid)
          .single();
      return response['is_online'] ?? false;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  // In ProfileProvider class
  Future<void> profilePrivateToggle(bool value, String uid) async {
    try {
      // Set local value first to prevent UI lag
      isPrivate = value;

      // Only notify specific listeners
      notifyListeners();

      // Update backend asynchronously without triggering another notification
      await _supabase.from('users').update({
        'is_private': value,
        'requests': [],
      }).eq('uid', uid);

      // Update posts visibility
      await _supabase
          .from('posts')
          .update({'is_private': value}).eq('user_id', uid);
    } catch (e) {
      // Reset on failure
      isPrivate = !value;
      debugPrint(e.toString());
      notifyListeners();
    }
  }

  Future<bool> checkAnyProfilePrivateToggle(String uid) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_private')
          .eq('uid', uid)
          .single();
      return response['is_private'] ?? false;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  void setImageLoadError(bool value) {
    _imageLoadError = value;
    notifyListeners();
  }

  Future<void> retryLoadingImage() async {
    _imageLoadError = false;
    _isImageLoading = true;
    notifyListeners();

    try {
      if (_userData != null) {
        await fetchUserData(_userData!.uid);
      }
    } finally {
      _isImageLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .limit(1);
      return response.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username availability');
    }
  }

  Future<void> updateProfile(
    String uid, {
    String? username,
    String? name,
    Gender? gender,
    String? bio,
    String? phoneNumber,
    DateTime? birthdate,
    File? profileImage,
    File? coverImage,
  }) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();

      final response =
          await _supabase.from('users').select().eq('uid', uid).single();

      final currentUser = UserModel.fromMap(uid, response);

      Map<String, dynamic> updates = {
        if (username != null) 'username': username,
        if (name != null) 'name': name,
        if (gender != null) 'gender': _convertGenderToString(gender),
        if (bio != null) 'bio': bio,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (birthdate != null) 'birthdate': birthdate.toIso8601String(),
      };

      if (profileImage != null) {
        var ref = _storage.ref().child(
            'profile_images/$uid/${DateTime.now().millisecondsSinceEpoch}');

        if (currentUser.profileImageUrl != null) {
          try {
            final oldImageRef =
                _storage.refFromURL(currentUser.profileImageUrl!);
            await oldImageRef.delete();

            ref = oldImageRef;
          } catch (e) {
            debugPrint('Error deleting old profile image: $e');
          }
        }

        await ref.putFile(profileImage);
        final url = await ref.getDownloadURL();
        updates['profile_image_url'] = url;
      }

      if (coverImage != null) {
        var ref = _storage.ref().child(
            'cover_images/$uid/${DateTime.now().millisecondsSinceEpoch}');

        if (currentUser.profileImageUrl != null) {
          try {
            final oldImageRef = _storage.refFromURL(currentUser.coverImageUrl!);
            await oldImageRef.delete();

            ref = oldImageRef;
          } catch (e) {
            debugPrint('Error deleting old cover image: $e');
          }
        }

        await ref.putFile(coverImage);
        final url = await ref.getDownloadURL();
        updates['cover_image_url'] = url;
      }

      await _supabase.from('users').update(updates).eq('uid', uid);
      await fetchUserData(uid);
    } catch (e) {
      _error = 'Failed to update profile: $e';
      debugPrint(_error);
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // Add this helper method to convert Gender enum to proper database format
  String _convertGenderToString(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }

  // Modify the streamUserData method to be more robust
  Stream<UserModel?> streamUserData(String uid) {
    // debugPrint('Streaming user data for uid: $uid');

    // Add retry logic to handle temporary connection issues
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('uid', uid)
        .handleError((error) {
          debugPrint('Error in user data stream: $error');
          // Return empty data instead of error to prevent stream termination
          return [];
        })
        .map((data) {
          if (data.isEmpty) {
            debugPrint('Empty data received for uid: $uid');
            return null;
          }
          try {
            debugPrint('User data received successfully');
            return UserModel.fromMap(uid, data.first);
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            return null;
          }
        });
  }

  Future<List<UserModel>> searchUsers(String searchQuery) async {
    if (searchQuery.isEmpty) return [];

    try {
      final currentUserId = globalUser?.uid;
      if (currentUserId == null) return [];

      final response = await _supabase
          .from('users')
          .select()
          .ilike('username', '%$searchQuery%')
          .neq('uid', currentUserId)
          .limit(20);

      return response
          .map<UserModel>((user) => UserModel.fromMap(user['uid'], user))
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      // Get both users' current data
      final currentUserData = await _supabase
          .from('users')
          .select()
          .eq('uid', currentUserId)
          .single();

      final targetUserData = await _supabase
          .from('users')
          .select()
          .eq('uid', targetUserId)
          .single();

      // Update current user's following list
      List<String> following =
          List<String>.from(currentUserData['following'] ?? []);
      following.add(targetUserId);

      // Update target user's followers list
      List<String> followers =
          List<String>.from(targetUserData['followers'] ?? []);
      followers.add(currentUserId);

      // Perform both updates in a transaction-like manner
      await Future.wait([
        _supabase
            .from('users')
            .update({'following': following}).eq('uid', currentUserId),
        _supabase
            .from('users')
            .update({'followers': followers}).eq('uid', targetUserId)
      ]);

      // Handle notification
      final token = await _supabase
          .from('users')
          .select('token')
          .eq('uid', targetUserId)
          .single();

      if (token['token'] != null) {
        await PushNotificationService.sendPushNotification(
          token['token'],
          'New follow',
          'You have a new follower!',
          '/profile?uid=$currentUserId',
          'follow',
        );
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to follow user: $e';
      debugPrint(_error);
      throw Exception(_error);
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      // Get both users' current data
      final currentUserData = await _supabase
          .from('users')
          .select()
          .eq('uid', currentUserId)
          .single();

      final targetUserData = await _supabase
          .from('users')
          .select()
          .eq('uid', targetUserId)
          .single();

      // Update current user's following list
      List<String> following =
          List<String>.from(currentUserData['following'] ?? []);
      following.remove(targetUserId);

      // Update target user's followers list
      List<String> followers =
          List<String>.from(targetUserData['followers'] ?? []);
      followers.remove(currentUserId);

      // Perform both updates in a transaction-like manner
      await Future.wait([
        _supabase
            .from('users')
            .update({'following': following}).eq('uid', currentUserId),
        _supabase
            .from('users')
            .update({'followers': followers}).eq('uid', targetUserId)
      ]);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to unfollow user: $e';
      debugPrint(_error);
      throw Exception(_error);
    }
  }

  Future<void> requestFollow(String currentUserId, String targetUserId) async {
    try {
      final targetUserData = await _supabase
          .from('users')
          .select()
          .eq('uid', targetUserId)
          .single();

      List<String> requests =
          List<String>.from(targetUserData['requests'] ?? []);
      requests.add(currentUserId);

      await _supabase
          .from('users')
          .update({'requests': requests}).eq('uid', targetUserId);

      final token = await _supabase
          .from('users')
          .select('token')
          .eq('uid', targetUserId)
          .single();

      if (token['token'] != null) {
        await PushNotificationService.sendPushNotification(
          token['token'],
          'New follow request',
          'Someone sent you a follow request!',
          '/requests',
          'request',
        );
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to request follow: $e';
      debugPrint(_error);
      throw Exception(_error);
    }
  }

  Future<void> unrequestFollow(
      String currentUserId, String targetUserId) async {
    try {
      final targetUserData = await _supabase
          .from('users')
          .select()
          .eq('uid', targetUserId)
          .single();

      List<String> requests =
          List<String>.from(targetUserData['requests'] ?? []);
      requests.remove(currentUserId);

      await _supabase
          .from('users')
          .update({'requests': requests}).eq('uid', targetUserId);

      final token = await _supabase
          .from('users')
          .select('token')
          .eq('uid', currentUserId)
          .single();

      if (token['token'] != null) {
        await PushNotificationService.sendPushNotification(
          token['token'],
          'Follow request accepted',
          'You are now following',
          '/notif',
          'follow',
        );
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to unrequest follow: $e';
      debugPrint(_error);
      throw Exception(_error);
    }
  }

  Stream<List<UserModel>> streamFollowers(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('uid', userId)
        .asyncMap((data) async {
          if (data.isEmpty) return [];

          final userData = UserModel.fromMap(userId, data.first);
          if (userData.followers.isEmpty) return [];

          // Get all followers using the correct Supabase filter syntax
          final followersData = await _supabase
              .from('users')
              .select()
              .filter('uid', 'in', userData.followers);

          return followersData
              .map<UserModel>((user) => UserModel.fromMap(user['uid'], user))
              .toList();
        });
  }

  Stream<List<UserModel>> streamFollowing(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('uid', userId)
        .asyncMap((data) async {
          if (data.isEmpty) return [];

          final userData = UserModel.fromMap(userId, data.first);
          if (userData.following.isEmpty) return [];

          // Get all following users using the correct Supabase filter syntax
          final followingData = await _supabase
              .from('users')
              .select()
              .filter('uid', 'in', userData.following);

          return followingData
              .map<UserModel>((user) => UserModel.fromMap(user['uid'], user))
              .toList();
        });
  }

  void setImageLoading(bool value) {
    _isImageLoading = value;
    notifyListeners();
  }

  // Modify the initialize method to be more reliable
  Future<void> initialize(String? uid) async {
    if (uid == null) {
      debugPrint('Cannot initialize ProfileProvider with null uid');
      return;
    }

    // debugPrint('Initializing ProfileProvider for uid: $uid');

    try {
      // Try fetching user data multiple times with increasing delays
      int attempts = 0;
      bool success = false;

      while (attempts < 3 && !success) {
        try {
          await fetchUserData(uid);
          success = _userData != null;
          if (success) {
            debugPrint(
                'Successfully initialized user data on attempt ${attempts + 1}');
          }
        } catch (e) {
          debugPrint(
              'Error initializing user data (attempt ${attempts + 1}): $e');
        }

        if (!success) {
          attempts++;
          await Future.delayed(Duration(seconds: attempts));
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize user data after multiple attempts: $e');
    }
  }

  Future<void> updateVIPStatus(bool isVIP, String uid) async {
    try {
      await _supabase.from('users').update({'is_vip': isVIP}).eq('uid', uid);
      if (_userData != null) {
        _userData = UserModel.fromMap(uid, {
          ..._userData!.toMap(),
          'is_vip': isVIP,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update VIP status: $e');
    }
  }
}
