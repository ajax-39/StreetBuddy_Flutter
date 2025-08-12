import 'package:flutter/material.dart';
import 'package:street_buddy/utils/styles.dart';

class UploadingSnackbar {
  static SnackBar start() {
    return SnackBar(
      content: Row(
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.pinkAccent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              "Uploading...",
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.surfaceBackground,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
    );
  }

  static SnackBar stop() {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.done,
            color: Colors.green,
            size: 24.0,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              "Uploaded",
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.surfaceBackground,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
    );
  }

  static SnackBar error() {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24.0,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              "Something went wrong",
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.surfaceBackground,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      margin: const EdgeInsets.all(AppSpacing.md),
    );
  }
}
