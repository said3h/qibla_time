import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema de QiblaTime inspirado en diseño night/profesional
/// Basado en el prototipo qiblatime-prototype.html
class AppTheme {
  // ═══════════════════════════════════════════════════════════
  // PALETA DE COLORES (Del prototipo)
  // ═══════════════════════════════════════════════════════════
  
  // Colores principales - Gold & Night theme
  static const Color gold = Color(0xFFC9A84C);           // Oro principal
  static const Color goldLight = Color(0xFFE8C97A);      // Oro claro
  static const Color night = Color(0xFF0A0E14);          // Fondo principal (night)
  static const Color deep = Color(0xFF141B27);           // Superficie oscura
  static const Color surface = Color(0xFF1C2535);        // Cards
  static const Color surface2 = Color(0xFF243044);       // Surface secundario
  
  // Colores de texto
  static const Color text = Color(0xFFEEE8D5);           // Texto principal
  static const Color muted = Color(0xFF8A9BAD);          // Texto secundario
  
  // Colores de acento
  static const Color accent = Color(0xFF4FC3A1);         // Verde agua (success)
  static const Color border = Color(0x0FFFFFFF);         // Borde sutil (6% opacity)
  
  // ═══════════════════════════════════════════════════════════
  // COLORES LEGACY (Para compatibilidad)
  // ═══════════════════════════════════════════════════════════
  
  static const Color primaryGreen = gold;                // Alias para compatibilidad
  static const Color accentGold = goldLight;             // Alias para compatibilidad
  static const Color backgroundWhite = night;            // Alias para compatibilidad
  static const Color textDark = text;                    // Alias para compatibilidad
  static const Color textLight = muted;                  // Alias para compatibilidad

  // ═══════════════════════════════════════════════════════════
  // GRADIENTES
  // ═══════════════════════════════════════════════════════════
  
  /// Gradiente para el Hero de la próxima oración
  static const LinearGradient prayerHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A3A5C),  // Azul oscuro
      Color(0xFF0F2840),  // Azul noche
      Color(0xFF1A3525),  // Verde oscuro
    ],
  );

  /// Gradiente dorado para tarjetas especiales
  static LinearGradient get goldGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, Color(0xFFB8963C)],
  );

  // ═══════════════════════════════════════════════════════════
  // TEXT THEMES
  // ═══════════════════════════════════════════════════════════
  
  /// TextTheme con Google Fonts
  static TextTheme get textTheme => TextTheme(
    // Títulos grandes - Amiri para estilo árabe/caligráfico
    displayLarge: GoogleFonts.amiri(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: goldLight,
    ),
    displayMedium: GoogleFonts.amiri(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: goldLight,
    ),
    displaySmall: GoogleFonts.amiri(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: goldLight,
    ),
    
    // Títulos de sección
    headlineLarge: GoogleFonts.dmSans(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: text,
    ),
    headlineMedium: GoogleFonts.dmSans(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: text,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: text,
    ),
    
    // Cuerpo de texto
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      color: text,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      color: muted,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 12,
      color: muted,
    ),
    
    // Labels y botones
    labelLarge: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: text,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: muted,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: muted,
      letterSpacing: 1.5,
    ),
  );

  // ═══════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: gold,
      onPrimary: night,
      secondary: goldLight,
      onSecondary: night,
      surface: deep,
      onSurface: text,
      background: night,
      onBackground: text,
      error: Colors.redAccent,
    ),
    
    // Scaffold
    scaffoldBackgroundColor: night,
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: deep,
      foregroundColor: gold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.amiri(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: gold,
      ),
    ),
    
    // Typography con Google Fonts
    textTheme: textTheme,
    
    // Card Theme
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x0FFFFFFF)),
      ),
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: night,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: gold,
        textStyle: GoogleFonts.dmSans(fontSize: 14),
      ),
    ),
    
    // Icon Button
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: gold,
      ),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: deep,
      selectedItemColor: gold,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0x0FFFFFFF),
      thickness: 1,
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x0FFFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x0FFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
      labelStyle: GoogleFonts.dmSans(color: muted),
      hintStyle: GoogleFonts.dmSans(color: muted.withOpacity(0.5)),
    ),
    
    // Navigation Bar (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: deep,
      indicatorColor: gold.withOpacity(0.15),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: gold,
          );
        }
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: muted,
        );
      }),
    ),
  );
}
