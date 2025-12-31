import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized color palette for the app.
/// Use these instead of hardcoded Color values.
class AppColors {
  // Primary palette
  static const Color primaryDark = Color(0xFF1E293B); // Deep Slate
  static const Color accentBlue = Color(0xFF38BDF8); // Vibrant Sky Blue
  static const Color accentGold = Color(0xFFF59E0B); // Gold for highlights

  // Surface colors (for backgrounds, cards, etc.)
  static const Color surfaceDark = Color(0xFF0F172A); // Darker Slate
  static const Color surfaceLight = Color(0xFF334155); // Lighter Slate

  // Semantic text colors
  static const Color textOnDark = Colors.white;
  static const Color textOnLight = Colors.black;

  // App bar colors
  static const Color appBarLight = Color(0xB3FFFFFF); // Colors.white70 equivalent
  static const Color appBarDark = Color(0xFF212121); // Colors.grey.shade900 equivalent

  // CTA gradient colors (blue tones)
  static const Color ctaDarkStart = Color(0xFF0D47A1); // Colors.blue.shade900 equivalent
  static const Color ctaDarkEnd = Color(0xFF1976D3); // Colors.blue.shade700 equivalent
  static const Color ctaLightStart = Color(0xFF01579B); // Colors.lightBlue.shade900 equivalent
  static const Color ctaLightEnd = Color(0xFF00E5FF); // Colors.cyanAccent.shade700 equivalent

  // Card colors
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  // Input/Form colors
  static const Color inputBorderLight = Color(0xFFE0E0E0);
  static const Color inputBorderDark = Color(0xFF424242);
  static const Color inputFillLight = Colors.white;
  static const Color inputFillDark = Color(0xFF263238);
}

class AppTheme {
  // Legacy colors (kept for backward compatibility, use AppColors instead)
  static const Color primaryColor = AppColors.primaryDark;
  static const Color accentColor = AppColors.accentBlue;
  static const Color accentGold = AppColors.accentGold;

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        tertiary: accentGold,
        surface: Colors.grey[50]!,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.inter(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.inputBorderLight,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: accentColor, // Lighter primary for dark mode
        secondary: accentColor,
        tertiary: accentGold,
        surface: AppColors.cardDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.surfaceDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.inputBorderDark,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey[400],
      ),
    );
  }
}
