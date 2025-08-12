import 'package:flutter/material.dart';
import 'package:street_buddy/utils/styles.dart';
import 'package:street_buddy/screens/MainScreens/Others/analytics/analytic_screen.dart';

class AnalyticsButton extends StatelessWidget {
  const AnalyticsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.buttonText,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text(
              'View Analytics',
              style: AppTypography.button,
            ),
          ],
        ),
      ),
    );
  }
}
