import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized color palette for the app.
/// Use these instead of hardcoded Color values.
class AppColors {
  // Primary palette
  static const Color primaryDark = Color(0xFF1E293B);   // Deep Slate
  static const Color accentBlue = Color(0xFF38BDF8);    // Vibrant Sky Blue
  static const Color accentGold = Color(0xFFF59E0B);    // Gold for highlights

  // Surface colors (for backgrounds, cards, etc.)
  static const Color surfaceDark = Color(0xFF0F172A);   // Darker Slate
  static const Color surfaceLight = Color(0xFF334155);  // Lighter Slate
  
  // Semantic text colors
  static const Color textOnDark = Colors.white;
  static const Color textOnLight = Colors.black;
  
  // App bar colors
  static Color appBarLight = Colors.white70;
  static Color appBarDark = Colors.grey.shade900;
  
  // CTA gradient colors (blue tones)
  static Color ctaDarkStart = Colors.blue.shade900;
  static Color ctaDarkEnd = Colors.blue.shade700;
  static Color ctaLightStart = Colors.lightBlue.shade900;
  static Color ctaLightEnd = Colors.cyanAccent.shade700;
}

class AppTheme {
  // Legacy colors (kept for backward compatibility, use AppColors instead)
  static const Color primaryColor = AppColors.primaryDark;
  static const Color accentColor = AppColors.accentBlue;
  static const Color accentGold = AppColors.accentGold;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        tertiary: accentGold,
        surface: Colors.grey[50]!,
      ),
      scaffoldBackgroundColor: Colors.grey[50],
      textTheme: GoogleFonts.interTextTheme(),
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
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Darker Slate
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: accentColor, // Lighter primary for dark mode
        surface: const Color(0xFF1E293B),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
       appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
