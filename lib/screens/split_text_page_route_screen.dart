import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:street_buddy/utils/styles.dart';

class SplitCityAnimationRoute extends PageRouteBuilder {
  final Widget page;
  final String cityName;

  SplitCityAnimationRoute({required this.page, required this.cityName})
      : super(
          transitionDuration: const Duration(milliseconds: 1200),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const showNameDuration =
                Interval(0.0, 0.7, curve: Curves.easeInOut);
            final splitAnimation = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
            );

            return Scaffold(
              body: Stack(
                children: [
                  // Vibrant Background Gradient
                  Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.backgroundGradient),
                  ),

                  // Animated Circles with Vibrant Colors
                  Positioned(
                    left: -60,
                    top: -60,
                    child: AnimatedCircle(
                      animation: animation,
                      size: 200,
                      color: Colors.yellow.withOpacity(0.3),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    bottom: -40,
                    child: AnimatedCircle(
                      animation: animation,
                      size: 150,
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                  ),

                  // Clipped Destination Page with Animation
                  AnimatedBuilder(
                    animation: splitAnimation,
                    builder: (context, _) {
                      return ClipPath(
                        clipper: SplitClipper(splitAnimation.value),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: (1 - splitAnimation.value) * 5,
                            sigmaY: (1 - splitAnimation.value) * 5,
                          ),
                          child: child,
                        ),
                      );
                    },
                  ),

                  // Graffiti Text Overlay
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      if (showNameDuration.transform(animation.value) < 1.0) {
                        return Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Colors.pinkAccent,
                                Colors.orangeAccent,
                                Colors.yellowAccent,
                                Colors.cyan,
                              ],
                              tileMode: TileMode.mirror,
                            ).createShader(bounds),
                            child: Text(
                              cityName,
                              style: GoogleFonts.permanentMarker(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final splitDistance = MediaQuery.of(context).size.height *
                          0.6 *
                          splitAnimation.value;
                      final rotation = splitAnimation.value * 0.05;

                      return Stack(
                        children: [
                          // Top half
                          Center(
                            child: Transform.translate(
                              offset: Offset(0, -splitDistance),
                              child: Transform.rotate(
                                angle: -rotation,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Colors.purple,
                                      Colors.pink,
                                      Colors.orange,
                                    ],
                                    tileMode: TileMode.mirror,
                                  ).createShader(bounds),
                                  child: Text(
                                    cityName,
                                    style: GoogleFonts.permanentMarker(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bottom half
                          Center(
                            child: Transform.translate(
                              offset: Offset(0, splitDistance),
                              child: Transform.rotate(
                                angle: rotation,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Colors.cyan,
                                      Colors.lightBlue,
                                      Colors.greenAccent,
                                    ],
                                    tileMode: TileMode.mirror,
                                  ).createShader(bounds),
                                  child: Text(
                                    cityName,
                                    style: GoogleFonts.permanentMarker(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
}

class AnimatedCircle extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;

  const AnimatedCircle({
    super.key,
    required this.animation,
    required this.size,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = 1 + sin(animation.value * pi) * 0.05;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class SplitClipper extends CustomClipper<Path> {
  final double progress;

  SplitClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final gapHeight = size.height * 0.6 * progress;
    final centerY = size.height / 2;

    if (progress == 0) {
      return path;
    }

    path.addRect(Rect.fromLTRB(
      0,
      centerY - gapHeight,
      size.width,
      centerY + gapHeight,
    ));

    return path;
  }

  @override
  bool shouldReclip(SplitClipper oldClipper) => progress != oldClipper.progress;
}
