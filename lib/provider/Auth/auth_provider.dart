import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/models/user.dart';
import 'package:street_buddy/services/auth_sync_service.dart';

class AuthenticationProvider extends ChangeNotifier {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _auth = Supabase.instance.client.auth;
  final _supabase = Supabase.instance.client;

  User? _firebaseUser;
  UserModel? _userModel;

  User? get user => _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isSignedIn => _firebaseUser != null;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isPhoneLogin = false;
  bool showOtpField = false;
  String? verificationId; 

  bool isTermsAccepted = false;

  void setTermsAccepted() {
    isTermsAccepted = !isTermsAccepted;
    notifyListeners();
  }

  AuthenticationProvider() {
    _auth.onAuthStateChange.listen((event) async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _firebaseUser = session.user;
        _userModel = await _fetchUserModel(_firebaseUser!.id);

        // Sync Firebase auth with Supabase auth - this ensures users can use Firebase Storage
        await AuthSyncService.handleSupabaseLogin();
      } else {
        _firebaseUser = null;
        _userModel = null;

        // Make sure Firebase is also logged out
        await AuthSyncService.handleSupabaseLogout();
      }
      notifyListeners();
    });
  }

  Future<UserModel?> _fetchUserModel(String uid) async {
    try {
      final response =
          await _supabase.from('users').select().eq('uid', uid).maybeSingle();

      if (response != null) {
        return UserModel.fromMap(uid, response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user model in auth provider: $e');
      return null;
    }
  }

  String _convertPhoneToEmail(String identifier) {
    String cleanPhone = identifier.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      return '$cleanPhone@temp.com';
    }
    return identifier;
  }

  Future<void> signInWithEmail(String identifier, String password) async {
    try {
      String email = _convertPhoneToEmail(identifier);

      final result = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      _firebaseUser = result.user;
      _userModel = await _fetchUserModel(_firebaseUser!.id);

      if (_firebaseUser != null &&
          _userModel != null &&
          !_userModel!.isEmailVerified) {
        await updateEmailVerificationStatus(true);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<void> signInWithPhone(String identifier, String password) async {
    try {
      String phone = "+91$identifier";

      final result = await _auth.signInWithPassword(
        phone: phone,
        password: password,
      );
      _firebaseUser = result.user;
      _userModel = await _fetchUserModel(_firebaseUser!.id);

      if (_firebaseUser != null &&
          _userModel != null &&
          !_userModel!.isEmailVerified) {
        await updateEmailVerificationStatus(true);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error signing in with phone: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // First, trigger the native Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        debugPrint('Google Sign-In was canceled by the user');
        return;
      }

      // Get authentication details from Google Sign-In
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Use the OAuth token to sign in with Supabase
      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      // Get the user from the response
      _firebaseUser = response.user;

      // Check if user exists in your database
      _userModel = await _fetchUserModel(_firebaseUser!.id);

      // If user doesn't exist in your database, create a new record
      if (_userModel == null) {
        // Create a new user entry in your Supabase 'users' table
        // Adjust fields to match your actual schema
        await _supabase.from('users').insert({
          'uid': _firebaseUser!.id,
          'email': _firebaseUser!.email,
          'username': generateUniqueUsername(googleUser.displayName ?? 'User'),
          'name': googleUser.displayName ?? 'User',
          'profile_image_url': googleUser.photoUrl,
          'is_email_verified': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Fetch the newly created user model
        _userModel = await _fetchUserModel(_firebaseUser!.id);
      }

      // Notify listeners about the sign-in
      notifyListeners();
      debugPrint('Successfully signed in with Google: ${googleUser.email}');
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

// Helper method to generate a unique username
// (since your schema has a unique constraint on username)
  String generateUniqueUsername(String baseName) {
    // Remove spaces and special characters
    String cleanName = baseName.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
    // Add random numbers to make it unique
    String randomDigits =
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '${cleanName}_$randomDigits';
  }

  Future<void> updateEmailVerificationStatus(bool isVerified) async {
    try {
      if (_firebaseUser != null && _userModel != null) {
        await _supabase.from('users').update(
            {'is_email_verified': isVerified}).eq('uid', _firebaseUser!.id);

        _userModel = _userModel!.copyWith(isEmailVerified: isVerified);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating email verification status: $e');
      rethrow;
    }
  }

  Future<void> updateVIPStatus(bool isVIP) async {
    try {
      if (_firebaseUser != null && _userModel != null) {
        await _supabase
            .from('users')
            .update({'is_vip': isVIP}).eq('uid', _firebaseUser!.id);

        _userModel = _userModel!.copyWith(isVIP: isVIP);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating VIP status: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(String username, String? imageUrl) async {
    try {
      if (_firebaseUser != null) {
        await _supabase.from('users').update({
          'username': username,
          'profile_image_url': imageUrl,
        }).eq('uid', _firebaseUser!.id);

        if (_userModel != null) {
          _userModel = _userModel!.copyWith(
            username: username,
            profileImageUrl: imageUrl,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_firebaseUser != null) {
        final response = await _supabase
            .from('users')
            .select()
            .eq('uid', _firebaseUser!.id)
            .single();
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Also ensure Firebase Auth is signed out through our sync service
      await AuthSyncService.handleSupabaseLogout();

      _firebaseUser = null;
      _userModel = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> checkEmailVerification() async {
    try {
      if (_firebaseUser != null) {
        // await _firebaseUser!.reload();
        if (_userModel != null && !_userModel!.isEmailVerified) {
          await updateEmailVerificationStatus(true);
        }
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
