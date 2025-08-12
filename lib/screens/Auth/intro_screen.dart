import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/widgets/custom_overlay_container.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final pageController = PageController();
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView(
              controller: pageController,
              onPageChanged: (value) {
                setState(() {
                  index = value;
                });
              },
              children: [
                page0(),
                page1(),
                page2(),
              ],
            ),
            Positioned(
              bottom: 55,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: pageController,
                    count: 3,
                    effect: const WormEffect(
                      dotHeight: 5,
                      dotWidth: 10,
                      activeDotColor: AppColors.primary2,
                      dotColor: AppColors.surfaceBackground,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: index == 2
                        ? () {
                            context.go('/signin');
                          }
                        : () {
                            pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary2,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(index == 2 ? 'Get Started' : 'Next',
                          style: AppTypography.button2),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget page0() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/city_images/mumbai/page0.jpg',
          fit: BoxFit.fill,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomOverlayContainer(
            height: null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text.rich(TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(
                            text: 'Explore ',
                            style: TextStyle(
                                fontSize: 40, color: Color(0xFF4EDCFF))),
                        TextSpan(text: 'Cities Like Never Before')
                      ])),
                  Text(
                    'Discover hidden gems and popular spots effortlessly.',
                    style: GoogleFonts.openSans(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 120)
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget page1() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/city_images/mumbai/page1.jpg',
          fit: BoxFit.fill,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomOverlayContainer(
            height: null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: 'Go '),
                        TextSpan(
                          text: 'Beyond ',
                          style: TextStyle(
                            fontSize: 40,
                            color: Color(0xFFFFEB00),
                          ),
                        ),
                        TextSpan(text: 'the Map'),
                      ],
                    ),
                  ),
                  Text(
                    'Discover hidden gems and popular spots effortlessly.',
                    style: GoogleFonts.openSans(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 120)
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget page2() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/city_images/mumbai/page2.jpg',
          fit: BoxFit.fill,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomOverlayContainer(
            height: null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.montserrat(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: 'Create Your Own City'),
                        TextSpan(
                          text: ' Guides',
                          style: TextStyle(
                            fontSize: 40,
                            color: Color(0xFFFFEB00),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Share your adventures and inspire fellow explorers',
                    style: GoogleFonts.openSans(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 120)
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
