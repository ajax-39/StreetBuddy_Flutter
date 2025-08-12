import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/constants.dart';
import 'package:street_buddy/firebase_options.dart';
import 'package:street_buddy/services/settings_service.dart';
import 'package:street_buddy/services/firebase_messaging_service.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/MainScreen/guide_provider.dart';
import 'package:street_buddy/provider/analytic_provider.dart';
import 'package:street_buddy/provider/Auth/auth_notifier.dart';
import 'package:street_buddy/provider/Auth/auth_provider.dart';
import 'package:street_buddy/provider/Auth/otp_provider.dart';
import 'package:street_buddy/provider/Auth/sign_up_provider.dart';
import 'package:street_buddy/provider/MainScreen/Location/map_provider.dart';
import 'package:street_buddy/provider/MainScreen/message_provider.dart';
import 'package:street_buddy/provider/MainScreen/profile_provider.dart';
import 'package:street_buddy/provider/MainScreen/search_provider.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/ad_provider.dart';
import 'package:street_buddy/provider/post_provider.dart';
import 'package:street_buddy/provider/image_url_provider.dart';
import 'package:street_buddy/provider/firebase_messaging_provider.dart';
import 'package:street_buddy/routes/routes.dart';
import 'package:street_buddy/utils/theme.dart';
import 'package:street_buddy/widgets/connectivity_wrapper.dart';
import 'package:street_buddy/widgets/firebase_messaging_initializer.dart';
import 'package:street_buddy/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize critical services that providers might need
  await _initializeCriticalServices();

  // Only set orientation - everything else happens in splash screen
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Show app immediately - all other initialization happens in background
  runApp(const MyApp());
}

/// Initialize only the most critical services that providers need
Future<void> _initializeCriticalServices() async {
  try {
    // Initialize Firebase (required by many providers)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    debugPrint('✅ Firebase initialized in main()');

    // Initialize Firebase Messaging
    final messagingService = FirebaseMessagingService();
    await messagingService.initializeFirebaseMessaging();
    debugPrint('✅ Firebase Messaging initialized in main()');

    // Initialize Supabase (required by many providers)
    await Supabase.initialize(
      url: Constant.SUPABASE_URL,
      anonKey: Constant.ANON_KEY,
    ).timeout(const Duration(seconds: 5));
    debugPrint('✅ Supabase initialized in main()');
  } catch (e) {
    debugPrint('⚠️ Critical services initialization failed: $e');
    // Continue anyway - app will handle this gracefully
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ((context) => PostProvider())),
        ChangeNotifierProvider(create: ((context) => AuthenticationProvider())),
        ChangeNotifierProvider(create: ((context) => SignUpProvider())),
        ChangeNotifierProvider(create: ((context) => OTPProvider())),
        ChangeNotifierProvider(create: ((context) => UploadProvider())),
        ChangeNotifierProvider(create: ((context) => GuideProvider())),
        ChangeNotifierProvider(create: ((context) => ProfileProvider())),
        ChangeNotifierProvider(create: ((context) => MessageProvider())),
        ChangeNotifierProvider(create: ((context) => SearchProvider())),
        ChangeNotifierProvider(create: ((context) => SettingsService())),
        ChangeNotifierProvider(create: ((context) => AuthStateNotifier())),
        ChangeNotifierProvider(create: ((context) => MapProvider())),
        ChangeNotifierProvider(create: ((context) => ExploreProvider())),
        ChangeNotifierProvider(create: ((context) => AdProvider())),
        ChangeNotifierProvider(create: ((context) => AnalyticsProvider())),
        ChangeNotifierProvider(create: ((context) => ImageUrlProvider())),
        ChangeNotifierProvider(
            create: ((context) => FirebaseMessagingProvider())),
        StreamProvider<auth.User?>(
          create: (_) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: FirebaseMessagingInitializer(
        child: MaterialApp.router(
          builder: (context, child) {
            return ConnectivityWrapper(
              child: child!,
            );
          },
          scaffoldMessengerKey: uploadsnackbarKey,
          routerConfig: router,
          title: 'Street Buddy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
        ),
      ),
    );
  }
}
