import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E293B); // Deep Slate
  static const Color accentColor = Color(0xFF38BDF8); // Vibrant Sky Blue
  static const Color accentGold = Color(0xFFF59E0B); // Gold for highlights

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        tertiary: accentGold,
        surface: Colors.white,
        background: Colors.grey[50],
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
