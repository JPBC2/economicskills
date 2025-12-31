import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeService {
  static ThemeModeService? _instance;

  ThemeModeService._();

  static ThemeModeService get instance {
    _instance ??= ThemeModeService._();
    return _instance!;
  }

  Future<bool> saveThemeMode(bool darkMode) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("darkMode", darkMode);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns user's theme preference.
  /// Returns null if user hasn't set a preference (use system theme).
  Future<bool?> getThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool("darkMode"); // null means use system theme
    } catch (e) {
      return null;
    }
  }

  /// Check if user has explicitly set a theme preference.
  Future<bool> hasThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.containsKey("darkMode");
    } catch (e) {
      return false;
    }
  }
}

