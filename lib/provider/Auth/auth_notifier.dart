import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateNotifier extends ChangeNotifier {
  late SharedPreferences _prefs;

  AuthStateNotifier() {
    _initializeApp();
    // Check current auth state immediately
    final session = Supabase.instance.client.auth.currentSession;
    _isLoggedIn = session != null;

    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = Supabase.instance.client.auth.currentSession;
      _isLoggedIn = session != null;
      debugPrint('🔐 Auth state changed: isLoggedIn = $_isLoggedIn');
      notifyListeners();
    });
  }

  bool _isLoggedIn = false;
  bool _isFirstLaunch = true;
  bool _isInitialized = false;
  bool _isRegistrationComplete = false;
  bool _hasSeenWelcome = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isInitialized => _isInitialized;
  bool get isRegistrationComplete => _isRegistrationComplete;
  bool get hasSeenWelcome => _hasSeenWelcome;

  Future<void> _initializeApp() async {
    _prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = _prefs.getBool('first_launch') ?? true;
    print('🚀 First launch: $_isFirstLaunch');
    _hasSeenWelcome = _prefs.getBool('has_seen_welcome') ?? false;
    _isRegistrationComplete = _prefs.getBool('registration_complete') ?? false;

    // Check auth state after SharedPreferences are loaded
    final session = Supabase.instance.client.auth.currentSession;
    _isLoggedIn = session != null;
    print('🔐 Initial auth state: isLoggedIn = $_isLoggedIn');

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> markRegistrationComplete() async {
    _isRegistrationComplete = true;
    await _prefs.setBool('registration_complete', true);
    notifyListeners();
  }

  Future<void> markWelcomeScreenComplete() async {
    _hasSeenWelcome = true;
    _isRegistrationComplete = false;
    await _prefs.setBool('has_seen_welcome', true);
    await _prefs.setBool('registration_complete', false);
    notifyListeners();
  }

  Future<void> markFirstLaunchComplete() async {
    _isFirstLaunch = false;
    await _prefs.setBool('first_launch', false);
    notifyListeners();
  }
}
