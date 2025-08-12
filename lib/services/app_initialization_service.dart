import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:street_buddy/firebase_options.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/services/auth_sync_service.dart';
import 'package:street_buddy/services/background_task_service.dart';
import 'package:street_buddy/services/local_notification_service.dart';
import 'package:street_buddy/services/screenshot_protection_service.dart';
import 'package:street_buddy/services/settings_service.dart';
import 'package:street_buddy/utils/app_check_debug.dart';

/// Service responsible for handling all app initialization tasks
/// with proper priority, parallelization, and error handling
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._();
  static AppInitializationService get instance => _instance;

  AppInitializationService._();

  static bool _isInitialized = false;
  static final List<String> _initializationErrors = [];

  /// Initialize the app with progress callbacks
  static Future<void> initialize({
    Function(String)? onStatusUpdate,
  }) async {
    if (_isInitialized) return;

    try {
      // Phase 1: Critical local initialization (fast)
      _updateStatus('Setting up local services...', onStatusUpdate);
      await _initializeCriticalServices();

      // Phase 2: Firebase initialization (network dependent)
      _updateStatus('Connecting to Firebase...', onStatusUpdate);
      await _initializeFirebase();

      // Phase 3: Database initialization (parallel where possible)
      _updateStatus('Setting up databases...', onStatusUpdate);
      await _initializeDatabases();

      // Phase 4: Background services (non-blocking)
      _updateStatus('Starting background services...', onStatusUpdate);
      _initializeBackgroundServices(); // Fire and forget

      // Phase 5: Optional sync operations (background)
      _updateStatus('Syncing data...', onStatusUpdate);
      _performBackgroundSync(); // Fire and forget

      _updateStatus('Finalizing...', onStatusUpdate);
      _isInitialized = true;
    } catch (e) {
      _initializationErrors.add(e.toString());
      debugPrint('❌ App initialization error: $e');
      rethrow;
    }
  }

  /// Phase 1: Critical services that must be initialized first
  static Future<void> _initializeCriticalServices() async {
    final settingsInstance = SettingsService();

    // Configure screenshot protection (fast local operation)
    if (settingsInstance.screenshotProtection) {
      if (settingsInstance.globalScreenshotProtection) {
        await ScreenshotProtectionService.enableProtection();
      } else {
        await ScreenshotProtectionService.forceDisableProtection();
      }
    } else {
      await ScreenshotProtectionService.forceDisableProtection();
    }
  }

  /// Phase 2: Firebase initialization with timeout
  static Future<void> _initializeFirebase() async {
    try {
      // Initialize Firebase with timeout
      await Future.any([
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        Future.delayed(const Duration(seconds: 10)).then((_) =>
            throw TimeoutException('Firebase initialization timeout',
                const Duration(seconds: 10))),
      ]);

      // Configure Firebase Storage with reasonable timeouts
      FirebaseStorage.instance
          .setMaxUploadRetryTime(const Duration(seconds: 30));
      FirebaseStorage.instance
          .setMaxOperationRetryTime(const Duration(seconds: 30));
      FirebaseStorage.instance
          .setMaxDownloadRetryTime(const Duration(seconds: 30));

      // App Check initialization (non-blocking, best effort)
      AppCheckDebugService.initializeAppCheck().catchError((e) {
        debugPrint('⚠️ App Check initialization failed: $e');
      });
    } catch (e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
      // Don't rethrow - app can work in offline mode
    }
  }

  /// Phase 3: Database initialization
  static Future<void> _initializeDatabases() async {
    // Initialize local storage and other services in parallel
    // Supabase is already initialized in main() to avoid provider issues
    await Future.wait([
      _initializeHive(),
      _initializeGlobalUser(),
    ], eagerError: false); // Continue even if some fail
  }

  static Future<void> _initializeHive() async {
    try {
      await Hive.initFlutter();
      // Open boxes in parallel
      await Future.wait([
        Hive.openBox('search_history'),
        Hive.openBox('prefs'),
      ]);
    } catch (e) {
      debugPrint('⚠️ Hive initialization failed: $e');
    }
  }

  static Future<void> _initializeGlobalUser() async {
    try {
      await Future.any([
        getGlobalUser(),
        Future.delayed(const Duration(seconds: 5)).then((_) =>
            throw TimeoutException(
                'Global user loading timeout', const Duration(seconds: 5))),
      ]);
    } catch (e) {
      debugPrint('⚠️ Global user initialization failed: $e');
    }
  }

  /// Phase 4: Background services (non-blocking)
  static void _initializeBackgroundServices() {
    // These run in the background and don't block app startup

    // Notifications
    NotificationService().initNotification().catchError((e) {
      debugPrint('⚠️ Notification service failed: $e');
    });

    // Mobile ads
    MobileAds.instance.initialize().then((_) {
      debugPrint('✅ Mobile ads initialized');
    }).catchError((e) {
      debugPrint('⚠️ Mobile ads initialization failed: $e');
    });

    // Background tasks
    try {
      final backgroundTaskService = BackgroundTaskService();
      backgroundTaskService.startBackgroundTasks();
    } catch (e) {
      debugPrint('⚠️ Background task service failed: $e');
    }
  }

  /// Phase 5: Optional sync operations (background)
  static void _performBackgroundSync() {
    // Auth sync (best effort)
    if (globalUser != null) {
      AuthSyncService.syncSupabaseToFirebase().then((_) {
        debugPrint('✅ Auth sync completed');
      }).catchError((e) {
        debugPrint('⚠️ Auth sync failed: $e');
      });
    }
  }

  static void _updateStatus(String status, Function(String)? onStatusUpdate) {
    debugPrint('🚀 App Init: $status');
    onStatusUpdate?.call(status);
  }

  /// Get initialization status
  static bool get isInitialized => _isInitialized;

  /// Get any initialization errors
  static List<String> get initializationErrors =>
      List.unmodifiable(_initializationErrors);

  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
    _initializationErrors.clear();
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}s)';
}
