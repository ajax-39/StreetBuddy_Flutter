import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/Auth/auth_notifier.dart';
import 'package:street_buddy/services/app_initialization_service.dart';

// Animation constants to ensure consistent timing
class SplashConstants {
  static const Duration totalAnimationDuration = Duration(milliseconds: 3000);
  static const Duration minimumSplashDuration = Duration(
      milliseconds: 3500); // Slightly longer to ensure full animation + buffer
  static const Duration celebrationDelay = Duration(milliseconds: 800);
  static const Duration errorRetryDelay = Duration(seconds: 2);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _progressValue;
  late Animation<double> _shimmerPosition;

  bool _isInitialized = false;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Main sequence animation controller for the 4-stage animation
    _logoController = AnimationController(
      duration: SplashConstants
          .totalAnimationDuration, // Use constant for consistency
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Individual stage controller for precise timing
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Repeating animation controller for loading states
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Stage 1: Logo appears in center (0.0 - 0.25)
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    ));

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.25, curve: Curves.elasticOut),
    ));

    // Stage 2: Logo rotates -135 degrees then back to original (0.25 - 0.5)
    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0, // This will be used to calculate the rotation phases
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.25, 0.5, curve: Curves.easeInOut),
    ));

    // Stage 3: Logo slides to left (0.5 - 0.75) with smooth transition
    _shimmerPosition = Tween<double>(
      begin: 0.0, // Center position
      end: 1.0, // Left position
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.5, 0.75,
          curve: Curves.easeOut), // Changed to easeOut for smoother ending
    ));

    // Stage 4: Text appears (0.75 - 1.0)
    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    ));

    // Start the animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    debugPrint('🎬 Starting splash screen animation sequence...');

    // Start the main 4-stage animation
    _logoController.forward();

    // Wait for the animation sequence to complete
    await Future.delayed(SplashConstants.totalAnimationDuration);

    debugPrint('🎬 Animation sequence completed (3 seconds)');

    // If initialization is still ongoing, start subtle repeating animation
    if (!_isInitialized && mounted) {
      debugPrint(
          '🔄 Initialization still in progress, starting pulse animation...');
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Record the start time to ensure minimum splash duration
      final startTime = DateTime.now();
      debugPrint(
          '🚀 Starting app initialization at ${startTime.toIso8601String()}');

      // Start initialization in parallel with animation, but don't wait for it initially
      Future<void> initializationFuture = AppInitializationService.initialize(
        onStatusUpdate: (status) {
          if (mounted) {
            // Update progress based on initialization status
            _updateProgressBasedOnStatus(status);
          }
        },
      );

      // Always wait for the minimum splash duration regardless of initialization speed
      debugPrint(
          '⏱️ Waiting for minimum splash duration: ${SplashConstants.minimumSplashDuration.inMilliseconds}ms');
      await Future.delayed(SplashConstants.minimumSplashDuration);

      // Now wait for initialization to complete if it hasn't already
      debugPrint('🔄 Waiting for initialization to complete...');
      await initializationFuture;

      // Ensure minimum time has actually passed (double check for edge cases)
      final elapsedTime = DateTime.now().difference(startTime);
      debugPrint('⏱️ Total elapsed time: ${elapsedTime.inMilliseconds}ms');

      if (elapsedTime < SplashConstants.minimumSplashDuration) {
        final remainingTime =
            SplashConstants.minimumSplashDuration - elapsedTime;
        debugPrint(
            '⏳ Additional wait needed: ${remainingTime.inMilliseconds}ms');
        await Future.delayed(remainingTime);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentProgress = 1.0;
        });

        // Complete progress animation
        await _progressController.animateTo(1.0);

        // Stop repeating animations when initialization is complete
        _pulseController.stop();

        // Mark first launch complete
        try {
          if (mounted) {
            final authNotifier =
                Provider.of<AuthStateNotifier>(context, listen: false);
            await authNotifier.markFirstLaunchComplete();
          }
        } catch (e) {
          debugPrint('⚠️ Error marking first launch complete: $e');
        }

        // Small celebration delay to show final state
        debugPrint('🎉 Showing celebration delay...');
        await Future.delayed(SplashConstants.celebrationDelay);

        if (mounted) {
          // Check authentication state and navigate accordingly
          final authNotifier =
              Provider.of<AuthStateNotifier>(context, listen: false);

          debugPrint(
              '🧭 Navigating based on auth state: ${authNotifier.isLoggedIn ? "home" : "intro"}');

          if (authNotifier.isLoggedIn) {
            // User is already signed in, go to home
            if (mounted) context.go('/home');
          } else {
            // User is not signed in, show intro screen
            if (mounted) context.go('/i');
          }
        }
      }
    } catch (e) {
      // Even on error, ensure minimum animation time
      debugPrint(
          '❌ Error during initialization, ensuring minimum splash time...');
      await Future.delayed(SplashConstants.minimumSplashDuration);

      if (mounted) {
        debugPrint('🚨 Initialization error: $e');

        // Stop animations on error
        _pulseController.stop();

        // Retry after delay or navigate anyway
        await Future.delayed(SplashConstants.errorRetryDelay);
        if (mounted) {
          // Check authentication state even on error
          final authNotifier =
              Provider.of<AuthStateNotifier>(context, listen: false);

          if (authNotifier.isLoggedIn) {
            if (mounted) context.go('/home');
          } else {
            if (mounted) context.go('/i');
          }
        }
      }
    }
  }

  void _updateProgressBasedOnStatus(String status) {
    double progress = _currentProgress;

    if (status.toLowerCase().contains('local services') ||
        status.toLowerCase().contains('setting up')) {
      progress = 0.15;
    } else if (status.toLowerCase().contains('firebase') ||
        status.toLowerCase().contains('connecting')) {
      progress = 0.35;
    } else if (status.toLowerCase().contains('database') ||
        status.toLowerCase().contains('supabase')) {
      progress = 0.55;
    } else if (status.toLowerCase().contains('background') ||
        status.toLowerCase().contains('services')) {
      progress = 0.75;
    } else if (status.toLowerCase().contains('finalizing') ||
        status.toLowerCase().contains('completing')) {
      progress = 0.90;
    } else if (status.toLowerCase().contains('welcome') ||
        status.toLowerCase().contains('ready')) {
      progress = 1.0;
    }

    if (progress > _currentProgress) {
      _currentProgress = progress;
      _progressController.animateTo(progress);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive sizing based on screen width
    final logoSize = screenWidth < 360
        ? 100.0
        : screenWidth < 400
            ? 120.0
            : 140.0;
    final fontSize = screenWidth < 360
        ? 24.0
        : screenWidth < 400
            ? 28.0
            : 34.0;
    final letterSpacing = screenWidth < 360 ? 0.5 : 1.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFFFDFC7)),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, // 5% of screen width
              vertical: screenHeight * 0.02, // 2% of screen height
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 4-Stage Animation Sequence exactly like the images
                Flexible(
                  child: AnimatedBuilder(
                    animation:
                        Listenable.merge([_logoController, _pulseController]),
                    builder: (context, child) {
                      // Calculate logo position based on animation stage
                      double logoOffset = 0.0;
                      bool showText = false;

                      // Calculate zoom scale for stage 2 (rotation stage)
                      double currentZoom = 1.0;
                      if (_logoController.value >= 0.3 &&
                          _logoController.value <= 0.45) {
                        // Zoom in during first part of stage 2
                        double zoomProgress =
                            (_logoController.value - 0.3) / 0.15;
                        currentZoom = 1.0 + (0.2 * zoomProgress);
                      } else if (_logoController.value > 0.45 &&
                          _logoController.value <= 0.5) {
                        // Zoom out during second part of stage 2
                        double zoomProgress =
                            (_logoController.value - 0.45) / 0.05;
                        currentZoom = 1.2 - (0.2 * zoomProgress);
                      }

                      // Calculate rotation angle for stage 2: -135° then back to 0°
                      double rotationAngle = 0.0;
                      if (_logoRotation.value > 0 &&
                          _logoController.value < 0.5) {
                        if (_logoRotation.value <= 0.5) {
                          // First half: rotate to -135 degrees
                          rotationAngle = -135 *
                              (_logoRotation.value * 2) *
                              (3.14159 / 180);
                        } else {
                          // Second half: rotate back to 0 degrees
                          rotationAngle = -135 *
                              (2 - _logoRotation.value * 2) *
                              (3.14159 / 180);
                        }
                      }
                      // After stage 2 (rotation), rotationAngle stays at 0 for smooth transition

                      if (_shimmerPosition.value > 0) {
                        logoOffset = -0 * _shimmerPosition.value;
                      }

                      if (_progressValue.value > 0) {
                        // Stage 4: Text appears
                        showText = true;
                      }

                      return Center(
                        child: Transform.scale(
                          scale: _logoScale.value * currentZoom,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Logo with position animation - always visible once appeared
                                Transform.translate(
                                  offset: Offset(logoOffset, 0),
                                  child: Transform.rotate(
                                    angle:
                                        rotationAngle, // Use the calculated rotation angle
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      width: logoSize,
                                      height: logoSize,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Image.asset(
                                        'assets/icon/newlogo.png',
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),

                                if (showText)
                                  Flexible(
                                    child: AnimatedOpacity(
                                      opacity: _progressValue.value,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Transform.translate(
                                        offset: Offset(
                                            (1 - _progressValue.value) * 80, 0),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'STREET BUDDY',
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                letterSpacing: letterSpacing,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
