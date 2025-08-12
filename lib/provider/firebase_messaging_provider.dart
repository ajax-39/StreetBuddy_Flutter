import 'package:flutter/material.dart';
import 'package:street_buddy/services/firebase_messaging_service.dart';

class FirebaseMessagingProvider extends ChangeNotifier {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();

  String? _fcmToken;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize Firebase Messaging
  Future<void> initializeMessaging() async {
    if (_isInitialized) return;

    _setLoading(true);
    _setError(null);

    try {
      await _messagingService.initializeFirebaseMessaging();
      _fcmToken = await _messagingService.getToken();
      _isInitialized = true;

      // Print initialization success with token
      debugPrint('');
      debugPrint('✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅');
      debugPrint('🎉 FIREBASE MESSAGING INITIALIZED! 🎉');
      debugPrint('✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅');
      debugPrint('🔑 Your FCM Token: $_fcmToken');
      debugPrint('');
      debugPrint('📋 INSTRUCTIONS FOR TESTING:');
      debugPrint('1️⃣ Copy the token above');
      debugPrint(
          '2️⃣ Go to Firebase Console: https://console.firebase.google.com/');
      debugPrint('3️⃣ Navigate to: Cloud Messaging > Send test message');
      debugPrint('4️⃣ Paste your token in the "FCM registration token" field');
      debugPrint('5️⃣ Write your test message and send! 🚀');
      debugPrint('');
      debugPrint('✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅✅');
      debugPrint('');
    } catch (e) {
      _setError('Failed to initialize Firebase Messaging: $e');
      debugPrint('❌ Firebase Messaging Provider error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get current FCM token
  Future<void> refreshToken() async {
    try {
      _fcmToken = await _messagingService.getToken();

      // Print token with emojis when refreshed
      debugPrint('');
      debugPrint('🔄 FCM TOKEN REFRESHED 🔄');
      debugPrint('🔑 New Token: $_fcmToken');
      debugPrint('');

      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh FCM token: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messagingService.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      _setError('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messagingService.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      _setError('Failed to unsubscribe from topic: $e');
    }
  }

  /// Clear FCM token
  Future<void> clearToken() async {
    try {
      await _messagingService.deleteToken();
      _fcmToken = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear FCM token: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Print current FCM token to debug console
  void printTokenToConsole() {
    debugPrint('');
    debugPrint('🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯');
    debugPrint('📱 CURRENT FCM REGISTRATION TOKEN 📱');
    debugPrint('🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯');
    if (_fcmToken != null) {
      debugPrint('🔑 Token: $_fcmToken');
      debugPrint('');
      debugPrint('📝 HOW TO TEST:');
      debugPrint('1️⃣ Copy the token above');
      debugPrint('2️⃣ Open Firebase Console');
      debugPrint('3️⃣ Go to Cloud Messaging > Send test message');
      debugPrint('4️⃣ Paste token and send! 🚀');
    } else {
      debugPrint('❌ No token available');
      debugPrint('💡 Try calling refreshToken() first');
    }
    debugPrint('🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯🎯');
    debugPrint('');
  }
}
