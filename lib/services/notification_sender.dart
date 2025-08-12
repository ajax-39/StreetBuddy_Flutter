import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/post.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/services/push_notification_service.dart';
import 'package:flutter/foundation.dart';

class NotificationSender {
  /// * This class maintains each and every notification messages
  ///
  /// ! edit this file whenever needed

//? firebase messaging token
  Future<String> getToken(String userId) async {
    debugPrint('🔍 [NotificationSender] Fetching FCM token for user: $userId');
    String token = await supabase
        .from('users')
        .select('token')
        .eq('uid', userId)
        .single()
        .then((value) => value['token'] ?? '');
    debugPrint('📦 [NotificationSender] Fetched token: $token');
    return token;
  }

  sendLiked(PostModel post, String userId, String username) async {
    debugPrint(
        '👍 [NotificationSender] Like event triggered by $username for post ${post.id}');
    String token = await getToken(post.userId);
    if (token.isEmpty) {
      debugPrint(
          '⚠️ [NotificationSender] No FCM token found for user ${post.userId}, notification not sent.');
      return;
    }
    debugPrint('🚀 [NotificationSender] Sending push notification for like...');
    await PushNotificationService.sendPushNotification(
        token,
        post.type == PostType.guide ? post.title : post.description,
        '$username liked your ${post.type == PostType.guide ? 'guide' : 'post'}!',
        '/${post.type == PostType.guide ? 'guide' : 'post'}?id=${post.id}',
        'like',
        image: post.thumbnailUrl == null || post.thumbnailUrl!.isEmpty
            ? post.mediaUrls.first
            : post.thumbnailUrl);
    debugPrint(
        '✅ [NotificationSender] Like notification sent to user ${post.userId}');
  }

  sendCommented(PostModel post) async {
    final user = globalUser;
    if (user == null) return;
    String token = await getToken(user.uid);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(
        token,
        post.type == PostType.guide ? post.title : post.description,
        '${user.name} commented on your ${post.type == PostType.guide ? 'guide' : 'post'}!',
        '/${post.type == PostType.guide ? 'guide' : 'post'}?id=${post.id}',
        'comment');
  }

  sendFollowed(String currentUserId, String targetUserId) async {
    String token = await getToken(targetUserId);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(token, 'New follow',
        'You have a new follower!', '/profile?uid=$currentUserId', 'follow');
  }

  sendRequested(String targetUserId) async {
    String token = await getToken(targetUserId);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(token, 'New follow rewquest',
        'Someone sent you a follow request!', '/requests', 'request');
  }

  sendAccepted(String targetUserId) async {
    String token = await getToken(targetUserId);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(
        token,
        'Follow request accepted',
        'You are now following ',
        '/notif',
        'follow');
  }

  sendMessage(UserModel chatUser, String msg) async {
    String token = await getToken(chatUser.uid);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(
        token,
        'New Message',
        '${chatUser.username}: $msg',
        '/messages?uid=${chatUser.uid}',
        'message');
  }

  sendMessageMedia(UserModel chatUser) async {
    String token = await getToken(chatUser.uid);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(
        token,
        'New Message',
        '${chatUser.username} sent you a media',
        '/messages?uid=${chatUser.uid}',
        'message');
  }

  sendContentViolationAlert(PostModel post) async {
    final user = globalUser;
    if (user == null) return;
    String token = await getToken(user.uid);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(
        token,
        'Content Violation',
        'We have found your recent activity contains clear violation of our social policies',
        '/${post.type == PostType.guide ? 'guide' : 'post'}?id=${post.id}',
        'alert');
  }

  sendPostRestrictedAlert(PostModel post) async {
    String token = await getToken(post.userId);
    if (token.isEmpty) return;

    PushNotificationService.sendPushNotification(
        token,
        'Your post is restricted',
        'We have hidden your post from public since your post contains explicit data!',
        '/${post.type == PostType.guide ? 'guide' : 'post'}?id=${post.id}',
        'alert');
  }
}
