import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 900;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 900;

  static T value<T>(
    BuildContext context, {
    required T phone,
    required T tablet,
    required T desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return phone;
    if (w < 900) return tablet;
    return desktop;
  }
}
