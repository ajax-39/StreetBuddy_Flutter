import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/models/location.dart';
import 'package:street_buddy/models/place.dart';
import 'package:street_buddy/provider/Auth/auth_notifier.dart';
import 'package:street_buddy/screens/Auth/intro_screen.dart';
import 'package:street_buddy/screens/Auth/password_reset_screen.dart';
import 'package:street_buddy/screens/Auth/password_update_screen.dart';
import 'package:street_buddy/screens/Auth/signup/state_city_select_screen.dart';
import 'package:street_buddy/screens/Auth/signup/birthdate_screen.dart';
import 'package:street_buddy/screens/Auth/signup/otp_screen.dart';
import 'package:street_buddy/screens/Auth/sign_in_screen.dart';
import 'package:street_buddy/screens/Auth/signup/otp_screen_phone.dart';

import 'package:street_buddy/screens/Auth/signup/profile_picture_screen.dart';
import 'package:street_buddy/screens/Auth/signup/sign_up_screen.dart';
import 'package:street_buddy/screens/Auth/signup/terms_and_policies_screen.dart';
import 'package:street_buddy/screens/Auth/signup/username_screen.dart';
import 'package:street_buddy/screens/Auth/signup/welcome_screen.dart';
import 'package:street_buddy/screens/Dev/AdsTest/ad_test_screen.dart';
import 'package:street_buddy/screens/Dev/registry_dev_screen.dart';
import 'package:street_buddy/screens/Dev/report_db_screen.dart';
import 'package:street_buddy/screens/Dev/user_info_screen.dart';
import 'package:street_buddy/screens/MainScreens/Explore/explore_food_screen.dart';
import 'package:street_buddy/screens/MainScreens/Explore/explore_guides_newscreen.dart';

import 'package:street_buddy/screens/MainScreens/Explore/explore_shops_screen.dart';
import 'package:street_buddy/screens/MainScreens/Explore/change_location_screen.dart';
import 'package:street_buddy/screens/MainScreens/Guides/guide_router.dart';
import 'package:street_buddy/screens/MainScreens/Locations/Bookmarks/bookmark_screen.dart';
import 'package:street_buddy/screens/MainScreens/Locations/Bookmarks/category_bookmarks_screen.dart';
import 'package:street_buddy/screens/MainScreens/Locations/category_list_screen.dart';
import 'package:street_buddy/screens/MainScreens/Locations/map_screen.dart';
import 'package:street_buddy/screens/MainScreens/Locations/explore_places_detail_screen.dart';
import 'package:street_buddy/screens/MainScreens/Messages/message_screen.dart';
import 'package:street_buddy/screens/MainScreens/Messages/personal_message_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/VIPs/vip_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/VIPs/city_plans_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/register_place_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/VIPs/ambassador_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/analytics/analytic_screen.dart';
import 'package:street_buddy/screens/Dev/notification_dev.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/settings_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/settings/terms_service.dart';
import 'package:street_buddy/screens/MainScreens/Post/post_detail_screen.dart';
import 'package:street_buddy/screens/MainScreens/Profile/view_profile_screen.dart';
import 'package:street_buddy/screens/MainScreens/Upload/add_details_screen.dart';
import 'package:street_buddy/screens/MainScreens/Upload/add_post.dart';
import 'package:street_buddy/screens/MainScreens/Upload/edit_media_screen.dart';
import 'package:street_buddy/screens/MainScreens/Upload/select_media_screen.dart';
import 'package:street_buddy/screens/MainScreens/Business/add_business_screen.dart';
import 'package:street_buddy/screens/DEV/connectivity_test_screen.dart';
import 'package:street_buddy/screens/DEV/local_db_screen.dart';
import 'package:street_buddy/screens/DEV/location_places_dev_db.dart';
import 'package:street_buddy/screens/MainScreens/Others/notifications/notification_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/notifications/push_notification_detail_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/notifications/notification_settings_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/requests_screen.dart';
import 'package:street_buddy/screens/MainScreens/Upload/upload_guide_screen.dart';
import 'package:street_buddy/screens/MainScreens/Upload/upload_post_screen.dart';
import 'package:street_buddy/screens/home_screen.dart';
// import 'package:street_buddy/screens/splash_screen.dart';
import 'package:street_buddy/screens/user_test_screen.dart';
import 'package:street_buddy/widgets/crop_image_screen.dart';
import 'package:street_buddy/screens/Auth/signup/optional_phone_screen.dart';
import 'package:street_buddy/screens/MainScreens/Others/VIPs/vip_membership_screen.dart';
import 'package:street_buddy/services/screenshot_protection_route_observer.dart';

import '../screens/splash_screen_new.dart';

final authNotifier = AuthStateNotifier(); 

final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  refreshListenable: authNotifier,
  observers: [
    ScreenshotProtectionRouteObserver()
  ], // Add route observer for optimized screenshot protection
  routes: <RouteBase>[
    // Initial Routes
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),

    GoRoute(
      path: '/i',
      builder: (BuildContext context, GoRouterState state) {
        return const IntroScreen();
      },
    ),

    // Authentication Routes
    GoRoute(
      path: '/signin',
      builder: (BuildContext context, GoRouterState state) {
        return const SignInScreen();
      },
      pageBuilder: (context, state) =>
          CupertinoStylePage(child: const SignInScreen(), state: state),
    ),
    GoRoute(
      path: '/forget',
      builder: (BuildContext context, GoRouterState state) {
        return const PasswordResetScreen();
      },
      pageBuilder: (context, state) =>
          CupertinoStylePage(child: const PasswordResetScreen(), state: state),
    ),
    GoRoute(
      path: '/update-password',
      builder: (BuildContext context, GoRouterState state) {
        debugPrint('Password code: ${state.uri.queryParameters}');
        final String code = state.uri.queryParameters['code'] ?? '';
        return PasswordUpdateScreen(code: code);
      },
      pageBuilder: (context, state) {
        final String code = state.uri.queryParameters['code'] ?? '';
        return CupertinoStylePage(
            child: PasswordUpdateScreen(code: code), state: state);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (BuildContext context, GoRouterState state) {
        final code = state.uri.queryParameters['code'];
        final type = state.uri.queryParameters['type'];

        if (code != null && type == 'recovery') {
          return PasswordUpdateScreen(code: code);
        }
        return const SignInScreen(); // Redirect to signin if invalid
      },
      pageBuilder: (context, state) {
        final code = state.uri.queryParameters['code'];
        final type = state.uri.queryParameters['type'];

        if (code != null && type == 'recovery') {
          return CupertinoStylePage(
              child: PasswordUpdateScreen(code: code), state: state);
        }
        return CupertinoStylePage(child: const SignInScreen(), state: state);
      },
    ),

    // Sign Up Flow Routes
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        final bool isPhoneSignUp = state.extra as bool? ?? true;
        return SignUpScreen(initialIsPhoneSignUp: isPhoneSignUp);
      },
      pageBuilder: (context, state) {
        final bool isPhoneSignUp = state.extra as bool? ?? true;
        return CupertinoStylePage(
            state: state,
            child: SignUpScreen(initialIsPhoneSignUp: isPhoneSignUp));
      },
    ),

    GoRoute(
      path: '/signup/birthday',
      builder: (BuildContext context, GoRouterState state) {
        return const BirthdayScreen();
      },
      pageBuilder: (context, state) =>
          CupertinoStylePage(child: const BirthdayScreen(), state: state),
    ),
    GoRoute(
      path: '/signup/addstatecity',
      builder: (BuildContext context, GoRouterState state) {
        return const StateCitySelectorScreen();
      },
      pageBuilder: (context, state) => CupertinoStylePage(
          child: const StateCitySelectorScreen(), state: state),
    ),
    GoRoute(
      path: '/signup/username',
      builder: (BuildContext context, GoRouterState state) {
        return const UsernameScreen();
      },
    ),
    GoRoute(
      path: '/signup/terms',
      builder: (BuildContext context, GoRouterState state) {
        return const TermsAndPoliciesScreen();
      },
    ),
    GoRoute(
      path: '/signup/otp',
      builder: (BuildContext context, GoRouterState state) {
        final String identifier = state.uri.queryParameters['identifier'] ?? '';
        return OTPScreen(identifier: identifier);
      },
    ),
    GoRoute(
      path: '/signup/otpphone',
      builder: (BuildContext context, GoRouterState state) {
        final String identifier = state.uri.queryParameters['identifier'] ?? '';
        return OTPScreenPhone(identifier: identifier);
      },
    ),
    GoRoute(
      path: '/signup/profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfilePictureScreen();
      },
      pageBuilder: (context, state) =>
          CupertinoStylePage(child: const ProfilePictureScreen(), state: state),
    ),
    GoRoute(
      path: '/signup/welcome',
      builder: (BuildContext context, GoRouterState state) {
        return const WelcomePage();
      },
    ),
    GoRoute(
      path: '/signup/optional-phone',
      builder: (BuildContext context, GoRouterState state) {
        return const OptionalPhoneScreen();
      },
      pageBuilder: (context, state) =>
          CupertinoStylePage(child: const OptionalPhoneScreen(), state: state),
    ),

    // Main App Routes
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/home/:index',
      builder: (BuildContext context, GoRouterState state) {
        final indexParam = state.pathParameters['index'];
        final index = int.tryParse(indexParam ?? '0') ?? 0;
        return HomeScreen(initialIndex: index);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen(
          initialIndex: 1,
        );
      },
    ),
    GoRoute(
      path: '/people',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen(
          initialIndex: 1,
          tabIndex: 1,
        );
      },
    ),

    // Profile and User Related Routes
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) {
        var currentUser = globalUser;
        var uid = state.uri.queryParameters['uid'];
        if (uid != null && uid.toString().isNotEmpty) {
          return ViewProfileScreen(
              userId: uid.toString(),
              isOwnProfile:
                  currentUser != null && currentUser.uid == uid.toString());
        } else {
          return const HomeScreen(
            initialIndex: 4,
          );
        }
      },
    ),
    GoRoute(
      path: '/analytics',
      builder: (BuildContext context, GoRouterState state) {
        return const AnalyticsScreen();
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) {
        return const SettingsScreen();
      },
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (BuildContext context, GoRouterState state) {
        return const TermsOfServiceScreen();
      },
    ),

    // Notification and Request Routes
    GoRoute(
      path: '/notif',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationScreen();
      },
    ),
    GoRoute(
      path: '/push-notification-detail',
      builder: (BuildContext context, GoRouterState state) {
        final notificationData = state.uri.queryParameters['data'];
        return PushNotificationDetailScreen(
          notificationData: notificationData,
        );
      },
    ),
    GoRoute(
      path: '/notification-settings',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationSettingsScreen();
      },
    ),
    GoRoute(
      path: '/requests',
      builder: (BuildContext context, GoRouterState state) {
        return const RequestsScreen();
      },
    ),

    // Business Routes
    GoRoute(
      path: '/business/add',
      builder: (BuildContext context, GoRouterState state) {
        return const AddBusinessScreen();
      },
    ),

    // Content Routes
    GoRoute(
      path: '/post',
      builder: (BuildContext context, GoRouterState state) {
        if (state.uri.queryParameters['id'] != null &&
            state.uri.queryParameters['id'].toString().isNotEmpty) {
          return PostDetailScreen(
              postId: state.uri.queryParameters['id'].toString());
        } else {
          return const HomeScreen(
            initialIndex: 1,
          );
        }
      },
    ),
    GoRoute(
      path: '/guide',
      builder: (BuildContext context, GoRouterState state) {
        if (state.uri.queryParameters['id'] != null &&
            state.uri.queryParameters['id'].toString().isNotEmpty) {
          return GuideRouter(
              postId: state.uri.queryParameters['id'].toString());
        } else {
          return const HomeScreen(
            initialIndex: 1,
          );
        }
      },
    ),
    GoRoute(
      path: '/crop-image',
      builder: (BuildContext context, GoRouterState state) {
        final image = state.extra as File;
        return CropImageScreen(image: image);
      },
    ),
    // Explore Routes
    GoRoute(
      path: '/explore/food',
      builder: (BuildContext context, GoRouterState state) {
        return const ExploreFoodScreen();
      },
    ),
    GoRoute(
      path: '/explore/guides',
      builder: (BuildContext context, GoRouterState state) {
        return const ExploreGuidesNewScreen();
      },
    ),
    GoRoute(
      path: '/explore/shops',
      builder: (BuildContext context, GoRouterState state) {
        return const ExploreShopsScreen();
      },
    ),
    GoRoute(
      path: '/change-location',
      builder: (BuildContext context, GoRouterState state) {
        return const ChangeLocationScreen();
      },
    ),
    // Location Related Routes
    GoRoute(
      path: '/locations/category',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>;
        final location = extra['location'] as LocationModel;
        return CategoryListScreen(
          location: location,
          category: extra['category'] as String,
        );
      },
    ),
    GoRoute(
      path: '/locations/place',
      builder: (BuildContext context, GoRouterState state) {
        final place = state.extra as PlaceModel;
        return PlaceDetailsScreen(place: place);
      },
    ),
    GoRoute(
      path: '/locations/bookmarks',
      builder: (BuildContext context, GoRouterState state) {
        return const BookmarksScreen();
      },
    ),
    GoRoute(
      path: '/locations/bookmarks/category',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>;
        return CategoryBookmarksScreen(
          category: extra['category'] as String,
          places: extra['places'] as List<PlaceModel>,
        );
      },
    ),
    GoRoute(
      path: '/map',
      builder: (BuildContext context, GoRouterState state) {
        final params = state.uri.queryParameters;
        return MapScreen(
          latitude: double.parse(params['latitude']!),
          longitude: double.parse(params['longitude']!),
          placeName: params['placeName']!,
        );
      },
    ),

    // Upload Routes
    GoRoute(
        path: '/upload',
        pageBuilder: (context, state) {
          return CupertinoStylePage(
            state: state,
            child: const AddPostScreen(),
          );
        }),
    GoRoute(
        path: '/upload/select',
        pageBuilder: (context, state) {
          return CupertinoStylePage(
            state: state,
            child: const SelectMediaScreen(),
          );
        }),
    GoRoute(
        path: '/upload/select/:number',
        pageBuilder: (context, state) {
          var number = state.pathParameters['number'] ?? '0';

          return CupertinoStylePage(
            state: state,
            child: SelectMediaScreen(
              guideNumber: int.parse(number),
            ),
          );
        }),
    GoRoute(
        path: '/upload/edit/:index',
        pageBuilder: (context, state) {
          var index = state.pathParameters['index'] ?? '0';
          return SlideUpPage(
            state: state,
            child: EditMediaScreen(
              index: int.parse(index),
            ),
          );
        }),
    GoRoute(
        path: '/upload/edit/:index/:number',
        pageBuilder: (context, state) {
          var index = state.pathParameters['index'] ?? '0';
          var number = state.pathParameters['number'] ?? '0';
          return SlideUpPage(
            state: state,
            child: EditMediaScreen(
              index: int.parse(index),
              guideNumber: int.parse(number),
            ),
          );
        }),
    GoRoute(
        path: '/upload/post',
        pageBuilder: (context, state) {
          return CupertinoStylePage(
            state: state,
            child: const UploadPostScreen(),
          );
        }),
    GoRoute(
        path: '/upload/guide',
        pageBuilder: (context, state) {
          return CupertinoStylePage(
            state: state,
            child: const UploadGuideScreen(),
          );
        }),
    GoRoute(
      path: '/upload/info',
      builder: (BuildContext context, GoRouterState state) {
        return const AddDetailsScreen();
      },
    ),

    // Messages Routes
    GoRoute(
      path: '/messages',
      builder: (context, state) {
        if (state.uri.queryParameters['uid'] != null &&
            state.uri.queryParameters['uid'].toString().isNotEmpty) {
          return PersonalMessageScreen(
              currentUserid: state.uri.queryParameters['uid'].toString());
        } else {
          return const MessagesScreen();
        }
      },
    ),
    //Other Routes
    GoRoute(
      path: '/ambassador',
      builder: (BuildContext context, GoRouterState state) {
        return const AmbassadorScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterPlaceScreen();
      },
    ),
    // Development & Testing Routes
    GoRoute(
      path: '/test',
      builder: (BuildContext context, GoRouterState state) {
        return const UserTestScreen();
      },
    ),
    GoRoute(
      path: '/dev/locationdb',
      builder: (BuildContext context, GoRouterState state) {
        return const LocationPlacesDevDB();
      },
    ),
    GoRoute(
      path: '/dev/notification',
      builder: (BuildContext context, GoRouterState state) {
        return const NotificationDev();
      },
    ),
    GoRoute(
      path: '/dev/internetcheck',
      builder: (BuildContext context, GoRouterState state) {
        return const ConnectivityStatusScreen();
      },
    ),
    GoRoute(
      path: '/dev/local_db',
      builder: (BuildContext context, GoRouterState state) {
        return const CacheVisualizationScreen();
      },
    ),
    GoRoute(
      path: '/dev/ads_test',
      builder: (BuildContext context, GoRouterState state) {
        return const ExampleAdScreen();
      },
    ),
    GoRoute(
      path: '/dev/user_info',
      builder: (BuildContext context, GoRouterState state) {
        return const UserInfoScreen();
      },
    ),
    GoRoute(
      path: '/dev/registry',
      builder: (BuildContext context, GoRouterState state) {
        return const RegistryDevScreen();
      },
    ),
    GoRoute(
      path: '/dev/reports',
      builder: (BuildContext context, GoRouterState state) {
        return const ReportDbScreen();
      },
    ),
    GoRoute(
      path: '/vip',
      builder: (BuildContext context, GoRouterState state) {
        return const VIPScreen();
      },
    ),
    GoRoute(
      path: '/vip/city-plans',
      builder: (BuildContext context, GoRouterState state) {
        return const CityPlansScreen();
      },
    ),
    GoRoute(
      path: '/vip/membership',
      builder: (BuildContext context, GoRouterState state) {
        return const VIPMembershipScreen();
      },
    ),
    GoRoute(
      path: '/explore/places',
      builder: (BuildContext context, GoRouterState state) {
        // Show HomeScreen with only ExplorePlacesScreen as content
        return const HomeScreen(
          initialIndex: 1, // Set to Explore tab if needed
          showOnlyExplorePlaces: true,
        );
      },
    ),
  ],
  redirect: (BuildContext context, GoRouterState state) {
    if (!authNotifier.isInitialized) {
      return null;
    }

    final isLoggedIn = authNotifier.isLoggedIn;
    final isFirstLaunch = authNotifier.isFirstLaunch;
    final isRegistrationComplete = authNotifier.isRegistrationComplete;
    final hasSeenWelcome = authNotifier.hasSeenWelcome;
    final currentPath = state.uri.path;

    // Define path categories
    final isAuthPath = currentPath == '/signin' ||
        currentPath.startsWith('/signup') ||
        currentPath == '/forget' ||
        currentPath == '/update-password';
    final isProtectedPath = !isAuthPath && currentPath != '/';

    // Handle root path ('/')
    if (currentPath == '/') {
      if (isFirstLaunch) {
        // Allow splash screen only on first launch
        return null;
      } else {
        // Not first launch - redirect based on auth status
        return isLoggedIn ? '/home' : '/i';
      }
    }

    // Registration and welcome flow
    if (isRegistrationComplete &&
        !hasSeenWelcome &&
        currentPath != '/signup/welcome') {
      return '/signup/welcome';
    }

    // Authentication logic
    if (isLoggedIn) {
      // Redirect to home if trying to access auth paths while logged in
      if (isAuthPath && !isRegistrationComplete) {
        return '/home';
      }
    } else {
      // If not logged in, redirect to signin for protected paths
      if (isProtectedPath) {
        return '/i';
      }
    }

    // Allow the navigation to proceed
    return null;
  },
);

CustomStylePage({required Widget child, required GoRouterState state}) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
        position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
        child: child,
      ),
    );

SlideUpPage({required Widget child, required GoRouterState state}) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
        child: child,
      ),
    );

CupertinoStylePage({required Widget child, required GoRouterState state}) =>
    CupertinoPage(
      key: state.pageKey,
      child: child,
    );
