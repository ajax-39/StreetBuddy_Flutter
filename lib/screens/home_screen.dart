import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/globals.dart';
import 'package:street_buddy/provider/MainScreen/upload_provider.dart';
import 'package:street_buddy/provider/MainScreen/explore_provider.dart';
import 'package:street_buddy/provider/ad_provider.dart';
import 'package:street_buddy/screens/MainScreens/Explore/explore_guides_newscreen.dart';
import 'package:street_buddy/screens/MainScreens/Explore/explore_places_screen.dart';
import 'package:street_buddy/screens/MainScreens/Search/search_screen.dart';
import 'package:street_buddy/screens/MainScreens/Upload/upload_media_screen.dart';
import 'package:street_buddy/screens/MainScreens/home_page_screen.dart';
import 'package:street_buddy/screens/MainScreens/Profile/profile_screen.dart';
import 'package:street_buddy/services/auth_sync_service.dart';
import 'package:street_buddy/services/push_notification_service.dart';
import 'package:street_buddy/services/screenshot_protection_service.dart';
import 'package:street_buddy/services/settings_service.dart';
import 'package:street_buddy/utils/styles.dart';

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final int tabIndex;
  final bool showOnlyExplorePlaces;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
    this.tabIndex = 0,
    this.showOnlyExplorePlaces = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  bool _isCreateSelected = false;
  // Import needed for Firebase User info
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Sync Supabase auth to Firebase
    _syncFirebaseAuth();

    // Initialize AdProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdProvider>().initializeAds();
    });

    // _getUser();
    // PushNotificationService().getFirebaseMessagingToken();
    PushNotificationService().initNotificationListening(context);
  }

  Future<void> _getUser() async {
    if (globalUser != null) {
      await getGlobalUser();
    }
  }

  /// Sync Supabase auth to Firebase to ensure
  /// users can upload guides even if they're only logged in with Supabase
  Future<void> _syncFirebaseAuth() async {
    try {
      // Use our sync service to ensure Firebase auth is synchronized with Supabase
      final firebaseUser = await AuthSyncService.syncSupabaseToFirebase();

      if (firebaseUser != null) {
        debugPrint('✅ Firebase auth sync successful: ${firebaseUser.uid}');
      } else if (globalUser != null) {
        debugPrint('⚠️ Firebase auth sync failed, but Supabase user exists');
      }
    } catch (e) {
      debugPrint('❌ Error syncing Firebase auth: $e');
    }
  }

  @override
  void dispose() {
    // _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // If we're in the showOnlyExplorePlaces mode, navigate to appropriate routes
    if (widget.showOnlyExplorePlaces) {
      switch (index) {
        case 0: // Home
          context.go('/home');
          break;
        case 1: // Explore - already on explore places, no need to navigate
          break;
        case 3: // Guides
          context.go('/home/3');
          break;
        case 4: // Profile
          context.go('/home/4');
          break;
      }
      return;
    }

    // Custom navigation for Explore (Search) tab
    if (index == 1) {
      // Explore tab index (adjust if needed)
      final exploreProvider =
          Provider.of<ExploreProvider>(context, listen: false);
      exploreProvider.clearLocation();
    }

    // Handle screenshot protection for guides tab (index 3)
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    if (index == 3 && settingsService.screenshotProtection) {
      // Navigating TO guides tab - enable protection only if setting is enabled
      ScreenshotProtectionService.enableProtection();
    } else if (_selectedIndex == 3 && index != 3) {
      // Navigating AWAY FROM guides tab - disable protection
      ScreenshotProtectionService.forceDisableProtection();
    }

    setState(() {
      _selectedIndex = index;
      _isCreateSelected = false;
    });
  }

  Widget _buildBottomNavBtn(int index, String label) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 800;
    final buttonWidth = screenSize.width / 5;

    // Scale icon sizes based on screen size
    final iconSize = isLargeScreen ? 32 : (isTablet ? 28 : 24);
    final vectorSize = isLargeScreen ? 40 : (isTablet ? 36 : 30);
    final fontSize = isLargeScreen ? 18 : (isTablet ? 16 : 14);
    final spacing = isLargeScreen ? 8 : (isTablet ? 6 : 4);

    // Determine if this button should be selected
    bool isSelected;
    if (widget.showOnlyExplorePlaces) {
      // In explore places mode, only the Explore tab (index 1) should be selected
      isSelected = index == 1;
    } else {
      // Normal mode - use the current selected index
      isSelected = _selectedIndex == index;
    }

    return SizedBox(
      width: buttonWidth,
      child: InkWell(
        onTap: () {
          debugPrint('🔘 $label nav tapped');
          _onItemTapped(index);
        },
        borderRadius: BorderRadius.circular(100),
        splashColor: AppColors.primaryLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/icon/vector.png',
                  width: vectorSize.toDouble(),
                  color: isSelected ? AppColors.primary.withOpacity(0.2) : null,
                ),
                Image.asset(
                  'assets/icon/${label.toLowerCase()}.png',
                  width: iconSize.toDouble(),
                  color: isSelected ? AppColors.primary : null,
                ),
              ],
            ),
            SizedBox(height: spacing.toDouble()),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize.toDouble(),
                fontWeight: fontsemibold,
                color: isSelected ? AppColors.primary : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCreateBtn() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 800;
    final buttonWidth = screenSize.width / 5;

    // Scale icon sizes based on screen size
    final iconSize = isLargeScreen ? 32 : (isTablet ? 28 : 24);
    final vectorSize = isLargeScreen ? 40 : (isTablet ? 36 : 30);
    final fontSize = isLargeScreen ? 18 : (isTablet ? 16 : 14);
    final spacing = isLargeScreen ? 8 : (isTablet ? 6 : 4);

    return SizedBox(
      width: buttonWidth,
      child: InkWell(
        onTap: () {
          debugPrint(
              '✅ Create button clicked'); // Debug statement with tick emoji
          setState(() {
            _isCreateSelected = !_isCreateSelected;
          });
        },
        borderRadius: BorderRadius.circular(100),
        splashColor: AppColors.primaryLight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/icon/vector.png',
                  width: vectorSize.toDouble(),
                  color: _isCreateSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : null,
                ),
                Transform.rotate(
                  angle: _isCreateSelected ? 0.785 : 0,
                  child: Image.asset(
                    'assets/icon/create.png',
                    width: iconSize.toDouble(),
                    color: _isCreateSelected ? AppColors.primary : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.toDouble()),
            Text(
              'Create',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize.toDouble(),
                fontWeight: fontsemibold,
                color: _isCreateSelected ? AppColors.primary : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadFab(CreatePostType createPostType) {
    return InkWell(
      splashColor: AppColors.primary,
      onTap: () {
        debugPrint(
            '✅ Upload FAB tapped: ${createPostType == CreatePostType.guide ? 'Guide' : 'Gallery'}');
        setState(() {
          _isCreateSelected = false;
        });
        Provider.of<UploadProvider>(context, listen: false)
            .setCreatePostType(createPostType);

        // For Guide, skip directly to upload guide screen
        if (createPostType == CreatePostType.guide) {
          context.push('/upload/guide');
        } else {
          // For regular posts, go directly to upload post screen with integrated picker
          context.push('/upload/post');
        }
      },
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 0.7,
            )),
        child: Center(
          child: Wrap(
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Image.asset(
                'assets/icon/${createPostType == CreatePostType.guide ? 'upload2' : 'upload1'}.png',
                width: 14,
              ),
              Text(
                createPostType == CreatePostType.guide ? 'Guide' : 'Post',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: fontsemibold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show the Firebase user info
  void _showFirebaseUserInfo() {
    final User? currentUser = _auth.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase User Info'),
        content: SingleChildScrollView(
          child: currentUser != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('User is logged in',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 8),
                    Text('UID: ${currentUser.uid}'),
                    if (currentUser.email != null)
                      Text('Email: ${currentUser.email}'),
                    if (currentUser.phoneNumber != null)
                      Text('Phone: ${currentUser.phoneNumber}'),
                    if (currentUser.displayName != null)
                      Text('Name: ${currentUser.displayName}'),
                    Text(
                        'Email Verified: ${currentUser.emailVerified ? 'Yes' : 'No'}'),
                    if (currentUser.photoURL != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Image.network(
                          currentUser.photoURL!,
                          height: 100,
                          errorBuilder: (_, __, ___) => const Icon(Icons.error),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text('Provider Data:'),
                    ...currentUser.providerData.map(
                      (provider) =>
                          Text('- ${provider.providerId} (${provider.uid})'),
                    ),
                  ],
                )
              : const Text('User is not logged in with Firebase'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showOnlyExplorePlaces) {
      // Only show ExplorePlacesScreen with bottom nav bar
      return Scaffold(
        body: const _KeepAlivePage(child: ExplorePlacesScreen()),
        bottomNavigationBar: Container(
          height: MediaQuery.of(context).size.width > 800
              ? 95
              : (MediaQuery.of(context).size.width > 600 ? 85 : 90),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavBtn(0, 'Home'),
                  _buildBottomNavBtn(1, 'Explore'),
                  _buildBottomCreateBtn(),
                  _buildBottomNavBtn(3, 'Guides'),
                  _buildBottomNavBtn(4, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const _KeepAlivePage(child: HomePage()),
          _KeepAlivePage(child: SearchScreen(tabIndex: widget.tabIndex)),
          const _KeepAlivePage(child: AddScreen()),
          const _KeepAlivePage(child: ExploreGuidesNewScreen()),
          const _KeepAlivePage(child: ProfileScreen()),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: Stack(
        children: [
          // Original FAB functionality
          if (_isCreateSelected)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUploadFab(CreatePostType.post),
                  const SizedBox(width: 7),
                  _buildUploadFab(CreatePostType.guide),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: MediaQuery.of(context).size.width > 800
            ? 95
            : (MediaQuery.of(context).size.width > 600 ? 85 : 90),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavBtn(0, 'Home'),
                _buildBottomNavBtn(1, 'Explore'),
                _buildBottomCreateBtn(),
                _buildBottomNavBtn(3, 'Guides'),
                _buildBottomNavBtn(4, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
