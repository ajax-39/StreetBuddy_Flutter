import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/services/local_notification_service.dart';

class PushNotificationService { 
  static UserModel get user => globalUser!;

  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  void initNotificationListening(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // NotificationService().showNotification(
      //     title: message.notification!.title, body: message.notification!.body);
      print("Notification received: ${message.notification?.title} - ${message.notification?.body}");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      context.push(message.data['route']);
    });
  }

  Future<void> getFirebaseMessagingToken() async {
    await messaging.requestPermission();
    String uid = user.uid;
    messaging.getToken().then(
      (value) async {
        if (value != null) {
          try {
            await supabase.from('users').update({
              'token': value,
            }).eq('uid', uid);
          } catch (e) {
            debugPrint('Error updating token: $e');
          }
        } else {
          debugPrint('error in fetching token!!!!!'); 
        }
      },
    );
  }

  static Future<void> sendPushNotification(
      String token, String body, String title, String route, String type,
      {String? image}) async {
    final jsonbody = {
      "message": {
        "token": token,
        "notification": {"title": title, "body": body},
        "data": {
          "route": route,
          "type": type,
        }
      }
    };

    try {
      final bearerToken = await AccessFirebaseToken().getAccessToken();
      await post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/streetbuddy-bd84d/messages:send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: "Bearer $bearerToken"
          },
          body: jsonEncode(jsonbody));

      final time = DateTime.now().millisecondsSinceEpoch.toString();

      if (type != 'message') {
        await supabase.from('notifications').insert({
          'id': time,
          'user_id': user.uid,
          'token': token,
          'type': type, 
          'title': title,
          'body': body,
          'route': route,
          'image': image,
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {} catch (e) {
    print(e.toString());
  }
}
