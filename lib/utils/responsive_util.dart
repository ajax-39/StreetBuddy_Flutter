import 'package:flutter/material.dart';

class ResponsiveUtil {
  /// Returns true if the screen width is considered a tablet/desktop size
  /// (greater than 600dp)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  /// Returns true if the screen width is considered a large phone size
  /// (between 400dp and 600dp)
  static bool isLargePhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 400 && width <= 600;
  }

  /// Returns true if the screen width is considered a small phone size
  /// (less than or equal to 400dp)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width <= 400;
  }

  /// Returns the screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Returns the screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Returns an appropriate font size based on screen size
  static double getFontSize(
    BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    if (isTablet(context)) {
      return large;
    } else if (isLargePhone(context)) {
      return medium;
    } else {
      return small;
    }
  }

  /// Returns an appropriate padding based on screen size
  static double getPadding(
    BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    if (isTablet(context)) {
      return large;
    } else if (isLargePhone(context)) {
      return medium;
    } else {
      return small;
    }
  }

  /// Returns an appropriate icon size based on screen size
  static double getIconSize(
    BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    if (isTablet(context)) {
      return large;
    } else if (isLargePhone(context)) {
      return medium;
    } else {
      return small;
    }
  }

  /// Returns a responsive value based on screen width percentage
  static double getWidthPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  /// Returns a responsive value based on screen height percentage
  static double getHeightPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  /// Returns a responsive SizedBox height based on screen size
  static SizedBox getVerticalSpace(
    BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    if (isTablet(context)) {
      return SizedBox(height: large);
    } else if (isLargePhone(context)) {
      return SizedBox(height: medium);
    } else {
      return SizedBox(height: small);
    }
  }

  /// Returns a responsive SizedBox width based on screen size
  static SizedBox getHorizontalSpace(
    BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    if (isTablet(context)) {
      return SizedBox(width: large);
    } else if (isLargePhone(context)) {
      return SizedBox(width: medium);
    } else {
      return SizedBox(width: small);
    }
  }

  /// Returns a responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T small,
    required T medium,
    required T large,
  }) {
    if (isTablet(context)) {
      return large;
    } else if (isLargePhone(context)) {
      return medium;
    } else {
      return small;
    }
  }
}
