import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:street_buddy/widgets/premium_upgrade_dialog.dart';

class PremiumLockOverlay extends StatelessWidget {
  const PremiumLockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => const PremiumUpgradeDialog(),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Blur effect
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              // Premium badge at top-left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 100,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800),
                    borderRadius: BorderRadius.circular(
                        20 * 0.8), // 80% of height (25*0.8=20)
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                         child: FaIcon(FontAwesomeIcons.lock,
                            color: Colors.white, size: 15),
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontFamily: 'SFUI',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lock icon
                    const Icon(Icons.lock_outline,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 6),
                    // VIP Access Only
                    const Text(
                      'VIP Access Only',
                      style: TextStyle(
                        fontFamily: 'SFUI',
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Unlock exclusive locations
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Unlock exclusive locations',
                            style: TextStyle(
                              fontFamily: 'SFUI',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
