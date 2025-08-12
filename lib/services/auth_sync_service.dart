import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/globals.dart';

/// Service to synchronize Supabase auth with Firebase auth
/// This ensures that when a user is logged in with Supabase, they also get logged in to Firebase
class AuthSyncService {
  static final firebase.FirebaseAuth _firebaseAuth =
      firebase.FirebaseAuth.instance;
  static final _supabase = Supabase.instance.client;

  /// Check if the user is logged in with Supabase but not with Firebase
  /// If so, create or sign in to Firebase with a custom token
  static Future<firebase.User?> syncSupabaseToFirebase() async {
    try {
      // Check if we have a Supabase user but no Firebase user
      final supabaseUser = _supabase.auth.currentUser;
      final firebaseUser = _firebaseAuth.currentUser;

      if (supabaseUser != null && firebaseUser == null) {
        debugPrint(
            '🔄 User is logged in with Supabase but not Firebase. Syncing...');
        // Create a password using the Supabase user's ID - this is secure since we only use it internally
        // and the user never has to remember it
        String securePassword = '${supabaseUser.id}_firebase_sync';

        try {
          // Try signing in first (in case this user was previously created)
          String email = supabaseUser.email ??
              '${"${supabaseUser.id}".substring(0, 8)}@streetbuddy.temporary';

          await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: securePassword,
          );
          debugPrint('✅ Successfully signed in existing user to Firebase');
        } catch (e) {
          debugPrint('👤 Creating new Firebase user for Supabase user');

          // If sign in fails, create a new user
          await _firebaseAuth.createUserWithEmailAndPassword(
            email: supabaseUser.email ??
                '${"${supabaseUser.id}".substring(0, 8)}@streetbuddy.temporary',
            password: securePassword,
          );
          debugPrint('✅ Successfully created new Firebase user');
        }

        // Now the user should be logged in to Firebase
        final updatedFirebaseUser = _firebaseAuth.currentUser;

        // Update the Firebase user profile to match Supabase user data if possible
        if (updatedFirebaseUser != null) {
          // If we have user data in Supabase, use it to update Firebase profile
          if (globalUser != null) {
            await updatedFirebaseUser.updateProfile(
              displayName: globalUser!.username,
              photoURL: globalUser!.profileImageUrl,
            );
          }
        }

        return updatedFirebaseUser;
      }

      return firebaseUser;
    } catch (e) {
      debugPrint('❌ Error synchronizing auth: $e');
      return null;
    }
  }

  /// This method should be called after the user logs in to Supabase
  static Future<void> handleSupabaseLogin() async {
    await syncSupabaseToFirebase();
  }

  /// This method should be called when the user logs out from Supabase
  static Future<void> handleSupabaseLogout() async {
    try {
      // Make sure we log out from Firebase as well
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('❌ Error logging out from Firebase: $e');
    }
  }
}
