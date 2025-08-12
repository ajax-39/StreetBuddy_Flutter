import 'package:flutter/material.dart';
import 'package:street_buddy/utils/styles.dart';

class ConnectivitySnackBar {
  static SnackBar create(String message, bool isOnline) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: AppColors.buttonText,
            size: 24.0,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.buttonText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isOnline ? AppColors.success : AppColors.error,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
    );
  }
}
