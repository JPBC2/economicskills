import 'package:flutter/material.dart';

/// Centralized spacing constants for consistent layout across the app.
/// Use these instead of hardcoded values to maintain design consistency.
class AppSpacing {
  // Base spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;

  // Common EdgeInsets presets
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);

  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
  
  // Drawer header padding
  static const EdgeInsets drawerHeaderPadding = EdgeInsets.all(md);
  
  // Nav item content padding
  static const EdgeInsets navItemPadding = EdgeInsets.only(left: 53.0);
}
