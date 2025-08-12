import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFED7014);
  static const Color secondary = Color(0xFF00376B);

  static const Color primary2 = Color(0xFFED7014);
  static const Color primaryLight = Color(0xFFFEF8F3);

  // Background gradient colors
  static const Color gradientStart =
      Color.fromARGB(255, 205, 215, 245); // Light blue
  static const Color gradientMiddle = Colors.white;
  static const Color gradientEnd =
      Color.fromARGB(245, 251, 223, 255); // Light pink

  // Create LinearGradient for consistent usage
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStart,
      gradientMiddle,
      gradientEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient shimmerGradient = LinearGradient(colors: [
    Colors.grey[400]!,
    Colors.grey[50]!,
    Colors.grey[400]!,
  ]);

  // Surface colors
  static const Color surfaceBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color textLink = Color(0xFFFFEF0C);
  static const Color textFill = Color(0xFFF0F0F0);

  // Border colors
  static const Color border = Color(0xFFDBDBDB);

  // Button colors
  static const Color buttonText = Colors.white;
  static const Color buttonDisabled = Color(0xFFFCD9B2);

  // Card colors
  static const Color cardShadow = Color(0x1A000000);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);

  // Rating color
  static const Color rating = Color(0xFFFFB300);
  static const Color cardBackground = Color(0xFFFFFFFD);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color ratingYellow = Color(0xFFFFB300);
  static const Color openGreen = Color(0xFF4CAF50);
  static const Color closedRed = Color(0xFFE53935);

  // Analytics colors
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartLightGreen = Color(0xFF81C784);
  static const Color chartYellow = Color(0xFFFFEB3B);
  static const Color chartBlueGradientStart = Color(0xFF64B5F6);
  static const Color chartBlueGradientEnd = Color(0xFF1976D2);
}

class AppTypography {
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'SFUI',
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontFamily: 'SFUI',
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    fontFamily: 'SFUI',
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.buttonText,
    fontFamily: 'SFUI',
  );

  static const TextStyle button2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonText,
    fontFamily: 'SFUI',
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontFamily: 'SFUI',
  );

  static const TextStyle searchBar = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.normal,
    fontFamily: 'SFUI',
  );

  static const TextStyle searchBar16 = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.normal,
    fontFamily: 'SFUI',
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.secondary,
    fontFamily: 'SFUI',
  );

  static const TextStyle link2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textLink,
    fontFamily: 'SFUI',
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'SFUI',
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'SFUI',
  );
}

class AppDecorations {
  static BoxDecoration card = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppSpacing.md),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class AppSpacing {
  static const double blur = 4.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

const fontregular = FontWeight.normal;
const fontmedium = FontWeight.w500;
const fontsemibold = FontWeight.w600;
