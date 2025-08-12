import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumUpgradeDialog extends StatelessWidget {
  const PremiumUpgradeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Premium Content',
                      style: TextStyle(
                        fontFamily: 'SFUI',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child:
                          const Icon(Icons.close, size: 22, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Think you\'ve seen it all?\nThink again.\nUnlock Street Buddy VIP and get\naccess to the city\'s best-kept secrets.',
                  style: TextStyle(
                      fontFamily: 'SFUI', fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/vip');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontFamily: 'SFUI',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontFamily: 'SFUI',
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
