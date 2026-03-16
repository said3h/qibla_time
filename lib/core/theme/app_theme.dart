import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF004B23);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color backgroundWhite = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: accentGold,
      background: backgroundWhite,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: textDark),
      bodyMedium: TextStyle(color: textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
