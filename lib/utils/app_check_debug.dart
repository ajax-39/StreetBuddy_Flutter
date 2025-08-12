import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppCheckDebugService {
  /// This method generates a debug token to be used in debugging mode
  /// The token needs to be registered in the Firebase Console
  static Future<void> getDebugToken() async {
    try {
      // Get the app check token
      final token = await FirebaseAppCheck.instance.getToken(true);

      // Print the debug token to register in Firebase console
      debugPrint('🔑🔑🔑 FIREBASE APP CHECK DEBUG TOKEN 🔑🔑🔑');
      debugPrint('$token');
      debugPrint('🔑🔑🔑 COPY THIS TOKEN TO FIREBASE CONSOLE 🔑🔑🔑');

      // Instructions for the developer
      debugPrint('\nInstructions:');
      debugPrint('1. Go to Firebase Console -> Project Settings');
      debugPrint('2. Navigate to the App Check section');
      debugPrint('3. Under "Debug tokens" section, add this token');
      debugPrint('4. Select your app from the dropdown and paste the token');
      debugPrint('5. Save the changes\n');
    } catch (e) {
      debugPrint('⚠️ Error getting Firebase App Check debug token: $e');
      debugPrint('Make sure you have properly initialized Firebase first.');
    }
  }

  /// Call this method when Firebase is initialized before any Firebase service is used
  static Future<void> initializeAppCheck() async {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    // Print debug reminders during development
    if (kDebugMode) {
      debugPrint('🛡️ Firebase App Check initialized with Debug Provider');
      debugPrint(
          '⚠️ Remember to register your debug token in Firebase Console');
    }
  }
}
