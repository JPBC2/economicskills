import 'package:flutter/material.dart';
import 'package:economicskills/infrastructure/res/theme_mode.service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeVM extends ChangeNotifier {
  final ThemeModeService _themeModeService;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeModeVM(this._themeModeService) {
    loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> loadThemeMode() async {
    final preference = await _themeModeService.getThemePreference();
    if (preference == null) {
      // First-time user: use system preference
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = preference ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    // Cycle: system -> light -> dark -> system
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        await _themeModeService.saveThemeMode(false);
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        await _themeModeService.saveThemeMode(true);
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        // Clear preference to return to system mode
        await _clearThemePreference();
        break;
    }
    notifyListeners();
  }

  Future<void> _clearThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("darkMode");
    } catch (e) {
      // Ignore errors
    }
  }
}

final themeModeProvider =
    ChangeNotifierProvider((_) => ThemeModeVM(ThemeModeService.instance));

