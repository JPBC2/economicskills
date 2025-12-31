import 'package:flutter/material.dart';
import 'package:shared/config/theme.dart';

/// Centralized gradient definitions for consistent visual effects across the app.
class AppGradients {
  /// Drawer header gradient (slate colors)
  static LinearGradient drawerHeader({required bool isDark}) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: isDark
        ? [AppColors.surfaceDark, AppColors.primaryDark]
        : [AppColors.primaryDark, AppColors.surfaceLight],
  );

  /// Call-to-action section gradient (blue tones)
  static LinearGradient callToAction({required bool isDark}) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: isDark
        ? [AppColors.ctaDarkStart, AppColors.ctaDarkEnd]
        : [AppColors.ctaLightStart, AppColors.ctaLightEnd],
  );
}
