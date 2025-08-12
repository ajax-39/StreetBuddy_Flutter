import 'package:flutter/material.dart';
import 'package:street_buddy/utils/styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'SFUI',
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surfaceBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceBackground,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      scaffoldBackgroundColor: AppColors.surfaceBackground,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceBackground,
      ),
      cardTheme: const CardTheme(
        color: AppColors.surfaceBackground,
        elevation: 0,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        backgroundColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: const BorderSide(
            color: AppColors.primary,
            width: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          borderSide: BorderSide(
            color: AppColors.primary,
          ),
        ),
      ),
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: AppColors.primary),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.surfaceBackground;
          },
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceBackground,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceBackground,
      ),
      primaryColor: AppColors.primary,
      useMaterial3: true,
    );
  }
}
