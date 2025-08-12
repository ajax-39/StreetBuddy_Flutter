import 'package:flutter/material.dart';
import 'package:street_buddy/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<ScaffoldMessengerState> uploadsnackbarKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

UserModel? globalUser;
final supabase = Supabase.instance.client;

Future<void> getGlobalUser() async {
  final uid = Supabase.instance.client.auth.currentUser?.id;

  if (uid != null) {
    try {
      final response =
          await supabase.from('users').select().eq('uid', uid).single();
      debugPrint("User data fetched successfully: ${response.toString()}");
      final userData = response;
      globalUser = UserModel.fromMap(userData['uid'], userData);
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      // Don't set globalUser if there's an error
    }
  } else {
    debugPrint("No authenticated user found");
  }
}
