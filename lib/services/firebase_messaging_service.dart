import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/services/local_notification_service.dart';
import 'package:street_buddy/globals.dart';

/// Top-level function to handle background messages
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Payload: ${message.data}');
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationService _notificationService = NotificationService();

  /// Initialize Firebase Messaging
  Future<void> initializeFirebaseMessaging() async {
    try {
      // Initialize local notifications first
      await _notificationService.initNotification();

      // Request permission from user
      await _requestPermission();

      // Get and print FCM token
      await _getFCMToken();

      // Initialize push notification handlers
      await _initPushNotifications();

      debugPrint('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional permission');
    } else {
      debugPrint('❌ User declined or has not accepted permission');
    }
  }

  /// Get FCM token for this device
  Future<String?> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();

      // Print token with emojis for easy identification in debug console
      debugPrint('');
      debugPrint('🚀🚀🚀🚀🚀🚀�🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀');
      debugPrint('🔥 FIREBASE CLOUD MESSAGING TOKEN 🔥');
      debugPrint('🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀');
      debugPrint('📱 Device Token: $token');
      debugPrint('');
      debugPrint(
          '💡 Copy this token to test push notifications from Firebase Console:');
      debugPrint('🌐 https://console.firebase.google.com/');
      debugPrint('📧 Go to: Cloud Messaging > Send test message');
      debugPrint('');
      debugPrint('🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀');
      debugPrint('');

      // You can send this token to your server to target this device
      // TODO: Send token to your backend server

      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Get the current FCM token (public method)
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Initialize push notification event handlers
  Future<void> _initPushNotifications() async {
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Handle notification if the app was terminated and now opened
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);

    // Handle notification when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    debugPrint('✅ Push notification handlers initialized');
  }

  /// Handle received messages when app is opened from notification
  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;

    debugPrint('📱 Handling message: ${message.messageId}');
    debugPrint('📱 Message data: ${message.data}');

    // Navigate to specific screen based on message data
    _navigateToScreen(message);
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message: ${message.notification?.title}');

    // Show local notification when app is in foreground
    _notificationService.showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Navigate to appropriate screen based on message data
  void _navigateToScreen(RemoteMessage message) {
    try {
      final data = message.data;

      // Handle different notification types
      if (data.containsKey('type')) {
        switch (data['type']) {
          case 'chat':
            // Navigate to chat screen
            if (data.containsKey('chatId')) {
              navigatorKey.currentState?.pushNamed('/messages');
              debugPrint('🗨️ Navigating to chat: ${data['chatId']}');
            }
            break;

          case 'post':
            // Navigate to post detail
            if (data.containsKey('postId')) {
              navigatorKey.currentState
                  ?.pushNamed('/post-detail/${data['postId']}');
              debugPrint('📝 Navigating to post: ${data['postId']}');
            }
            break;

          case 'location':
            // Navigate to location detail
            if (data.containsKey('locationId')) {
              navigatorKey.currentState
                  ?.pushNamed('/location-detail/${data['locationId']}');
              debugPrint('📍 Navigating to location: ${data['locationId']}');
            }
            break;

          case 'general':
          default:
            // Navigate to push notification detail screen
            final encodedData = Uri.encodeComponent(jsonEncode(data));
            navigatorKey.currentState
                ?.pushNamed('/push-notification-detail?data=$encodedData');
            debugPrint('🔔 Navigating to push notification detail screen');
            break;
        }
      } else {
        // Default navigation to push notification detail screen
        final encodedData = Uri.encodeComponent(jsonEncode(data));
        navigatorKey.currentState
            ?.pushNamed('/push-notification-detail?data=$encodedData');
        debugPrint('🔔 Default navigation to push notification detail screen');
      }
    } catch (e) {
      debugPrint('❌ Error navigating from notification: $e');
      // Fallback to notifications screen
      navigatorKey.currentState?.pushNamed('/notif');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}
