import 'package:flutter/material.dart';

/// Centralized text styles for consistent typography across the app.
/// Use these instead of inline TextStyle definitions.
class AppTextStyles {
  /// Brand font used for app name and headings
  static const String brandFont = 'ContrailOne';

  /// App bar title style (used for "Economic skills" text)
  static TextStyle appBarTitle({required Color color}) => TextStyle(
    fontFamily: brandFont,
    fontSize: 22,
    fontWeight: FontWeight.normal,
    color: color,
  );

  /// Drawer header style (white text on gradient background)
  static TextStyle drawerHeader({Color color = Colors.white}) => TextStyle(
    fontFamily: brandFont,
    fontSize: 22,
    color: color,
  );

  /// Navigation item text style
  static TextStyle navItem({required Color color}) => TextStyle(
    color: color,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// Navigation sub-item text style (lighter weight)
  static TextStyle navSubItem({required Color color}) => TextStyle(
    color: color,
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  /// Call-to-action button text style
  static TextStyle ctaButton({required Color color}) => TextStyle(
    color: color,
    fontSize: 19,
    fontFamily: brandFont,
  );
}
