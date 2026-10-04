import 'package:flutter/material.dart';

class Responsive {
  const Responsive._();

  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static bool isSmall(BuildContext context) {
    return width(context) < 360;
  }

  static bool isMobile(BuildContext context) {
    return width(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return width(context) >= 600;
  }

  static double widthPercent(BuildContext context, double percent) {
    return width(context) * percent;
  }

  static double heightPercent(BuildContext context, double percent) {
    return height(context) * percent;
  }

  static double scale(
    BuildContext context,
    double value, {
    double min = 0.8,
    double max = 1.2,
  }) {
    final screenWidth = width(context);
    final scaleFactor = screenWidth / 390;

    final scaledValue = value * scaleFactor;

    if (value >= 0) {
      return scaledValue.clamp(value * min, value * max);
    }

    return scaledValue.clamp(value * max, value * min);
  }
}
