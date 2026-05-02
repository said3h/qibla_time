import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// QiblaTime Design Tokens v2.0
/// Basado en qiblatime-palettes-v2.js
/// 5 temas: dark, light, amoled, deuteranopia, monochrome
class QiblaTokens {
  // Fondos
  final Color bgPage;
  final Color bgApp;
  final Color bgSurface;
  final Color bgSurface2;

  // Acento principal
  final Color primary;
  final Color primaryLight;
  final Color primaryBg;
  final Color primaryBorder;

  // Estado activo
  final Color activeBg;
  final Color activeBorder;

  // Texto
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Semánticos
  final Color accent;
  final Color confirm;
  final Color danger;

  // Bordes
  final Color border;
  final Color borderMed;

  // Hero dinámico por oración
  final QiblaHero fajr;
  final QiblaHero dhuhr;
  final QiblaHero asr;
  final QiblaHero maghrib;
  final QiblaHero isha;

  const QiblaTokens({
    required this.bgPage,
    required this.bgApp,
    required this.bgSurface,
    required this.bgSurface2,
    required this.primary,
    required this.primaryLight,
    required this.primaryBg,
    required this.primaryBorder,
    required this.activeBg,
    required this.activeBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.confirm,
    required this.danger,
    required this.border,
    required this.borderMed,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// Obtener hero por nombre de oración
  QiblaHero getHero(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return fajr;
      case 'dhuhr':
        return dhuhr;
      case 'asr':
        return asr;
      case 'maghrib':
        return maghrib;
      case 'isha':
        return isha;
      default:
        return asr;
    }
  }

  Color get transliterationText => primary.withValues(alpha: 0.78);

  Color get arabicText => primaryLight;

  TextStyle arabicTextStyle({
    double fontSize = 22,
    double height = 1.8,
    FontWeight fontWeight = FontWeight.w400,
    Color? backgroundColor,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      color: arabicText,
      backgroundColor: backgroundColor,
    );
  }

  TextStyle transliterationTextStyle({
    double fontSize = 13,
    double height = 1.7,
    FontStyle fontStyle = FontStyle.italic,
    FontWeight fontWeight = FontWeight.w500,
    double? letterSpacing,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      height: height,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: transliterationText,
    );
  }

  QiblaTokens copyWith({
    Color? bgPage,
    Color? bgApp,
    Color? bgSurface,
    Color? bgSurface2,
    Color? primary,
    Color? primaryLight,
    Color? primaryBg,
    Color? primaryBorder,
    Color? activeBg,
    Color? activeBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? confirm,
    Color? danger,
    Color? border,
    Color? borderMed,
  }) {
    return QiblaTokens(
      bgPage: bgPage ?? this.bgPage,
      bgApp: bgApp ?? this.bgApp,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurface2: bgSurface2 ?? this.bgSurface2,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryBg: primaryBg ?? this.primaryBg,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      activeBg: activeBg ?? this.activeBg,
      activeBorder: activeBorder ?? this.activeBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      confirm: confirm ?? this.confirm,
      danger: danger ?? this.danger,
      border: border ?? this.border,
      borderMed: borderMed ?? this.borderMed,
      fajr: fajr,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );
  }
}

/// Hero dinámico por oración
class QiblaHero {
  final Color bg;
  final Color tint;
  final Color label;

  const QiblaHero({
    required this.bg,
    required this.tint,
    required this.label,
  });
}

/// Temas disponibles
class QiblaThemes {
  // ═══════════════════════════════════════════════════════════
  // TEMA 1: DARK (Por defecto)
  // Cielo antes del Fajr. Dorado espiritual, marino profundo.
  // ═══════════════════════════════════════════════════════════
  static const QiblaTokens dark = QiblaTokens(
    // Fondos
    bgPage: Color(0xFF0A0E14),
    bgApp: Color(0xFF141B27),
    bgSurface: Color(0xFF1C2535),
    bgSurface2: Color(0xFF243044),

    // Acento principal
    primary: Color(0xFFC9A84C),
    primaryLight: Color(0xFFE8C97A),
    primaryBg: Color(0x21C9A84C),
    primaryBorder: Color(0x52C9A84C),

    // Estado activo
    activeBg: Color(0x2EC9A84C),
    activeBorder: Color(0xFFC9A84C),

    // Texto
    textPrimary: Color(0xFFEEE8D5),
    textSecondary: Color(0xFF8A9BAD),
    textMuted: Color(0xFF5A6A7A),

    // Semánticos
    accent: Color(0xFF2E8B70),
    confirm: Color(0xFFC9A84C),
    danger: Color(0xFFC94A4A),

    // Bordes
    border: Color(0x12FFFFFF),
    borderMed: Color(0x21FFFFFF),

    // Hero dinámico
    fajr: QiblaHero(
        bg: Color(0xFF0D1F35),
        tint: Color(0xFF1A3A5C),
        label: Color(0xFF6A9BB5)),
    dhuhr: QiblaHero(
        bg: Color(0xFF1A2E1A),
        tint: Color(0xFF243824),
        label: Color(0xFF6A9B7A)),
    asr: QiblaHero(
        bg: Color(0xFF1A2A3A),
        tint: Color(0xFF1E3248),
        label: Color(0xFF7A9AB5)),
    maghrib: QiblaHero(
        bg: Color(0xFF2D1A0E),
        tint: Color(0xFF3D2510),
        label: Color(0xFFC4784A)),
    isha: QiblaHero(
        bg: Color(0xFF14101E),
        tint: Color(0xFF1E1530),
        label: Color(0xFF7A6A9B)),
  );

  // ═══════════════════════════════════════════════════════════
  // TEMA 2: LIGHT
  // Pergamino y arena. Luz solar del mediodía.
  // ═══════════════════════════════════════════════════════════
  static const QiblaTokens light = QiblaTokens(
    bgPage: Color(0xFFFAF7F0),
    bgApp: Color(0xFFF5F0E6),
    bgSurface: Color(0xFFFFFFFF),
    bgSurface2: Color(0xFFEDE8DC),
    primary: Color(0xFF8B6914),
    primaryLight: Color(0xFF6B4F0E),
    primaryBg: Color(0x1A8B6914),
    primaryBorder: Color(0x478B6914),
    activeBg: Color(0x298B6914),
    activeBorder: Color(0xFF8B6914),
    textPrimary: Color(0xFF2C2416),
    textSecondary: Color(0xFF7A6E5E),
    textMuted: Color(0xFFA89880),
    accent: Color(0xFF1E6B52),
    confirm: Color(0xFF8B6914),
    danger: Color(0xFF9B2222),
    border: Color(0x14000000),
    borderMed: Color(0x26000000),
    fajr: QiblaHero(
        bg: Color(0xFFDDE8F0),
        tint: Color(0xFFC8DCE8),
        label: Color(0xFF4A7A9B)),
    dhuhr: QiblaHero(
        bg: Color(0xFFE8F0DC),
        tint: Color(0xFFD4E8C8),
        label: Color(0xFF4A7A5A)),
    asr: QiblaHero(
        bg: Color(0xFFE0E8F0),
        tint: Color(0xFFCCD8E8),
        label: Color(0xFF4A6A8B)),
    maghrib: QiblaHero(
        bg: Color(0xFFF0E0C8),
        tint: Color(0xFFE8CCA8),
        label: Color(0xFF9B5A28)),
    isha: QiblaHero(
        bg: Color(0xFFE0DCF0),
        tint: Color(0xFFCCC8E8),
        label: Color(0xFF5A4A8B)),
  );

  // ═══════════════════════════════════════════════════════════
  // TEMA 3: AMOLED
  // Negro puro. Ahorro máximo de batería en OLED/AMOLED.
  // ═══════════════════════════════════════════════════════════
  static const QiblaTokens amoled = QiblaTokens(
    bgPage: Color(0xFF000000),
    bgApp: Color(0xFF000000),
    bgSurface: Color(0xFF0D0D0D),
    bgSurface2: Color(0xFF1A1A1A),
    primary: Color(0xFFC9A84C),
    primaryLight: Color(0xFFE8C97A),
    primaryBg: Color(0x1AC9A84C),
    primaryBorder: Color(0x47C9A84C),
    activeBg: Color(0x33C9A84C),
    activeBorder: Color(0xFFE8C97A),
    textPrimary: Color(0xFFF5F2EA),
    textSecondary: Color(0xFF7A8A96),
    textMuted: Color(0xFF4A5A66),
    accent: Color(0xFF2A7A62),
    confirm: Color(0xFFC9A84C),
    danger: Color(0xFFB84444),
    border: Color(0x0FFFFFFF),
    borderMed: Color(0x1CFFFFFF),
    fajr: QiblaHero(
        bg: Color(0xFF050D18),
        tint: Color(0xFF0A1A2E),
        label: Color(0xFF5A8AAA)),
    dhuhr: QiblaHero(
        bg: Color(0xFF051005),
        tint: Color(0xFF0A1E0A),
        label: Color(0xFF5A8A6A)),
    asr: QiblaHero(
        bg: Color(0xFF080D14),
        tint: Color(0xFF0D1828),
        label: Color(0xFF6A8AAA)),
    maghrib: QiblaHero(
        bg: Color(0xFF150800),
        tint: Color(0xFF261200),
        label: Color(0xFFB06030)),
    isha: QiblaHero(
        bg: Color(0xFF08050F),
        tint: Color(0xFF100A1E),
        label: Color(0xFF6A5A8A)),
  );

  // ═══════════════════════════════════════════════════════════
  // TEMA 4: DEUTERANOPIA
  // Daltonismo rojo-verde. Sistema azul-amarillo.
  // ═══════════════════════════════════════════════════════════
  static const QiblaTokens deuteranopia = QiblaTokens(
    bgPage: Color(0xFF0D1016),
    bgApp: Color(0xFF131924),
    bgSurface: Color(0xFF1B2230),
    bgSurface2: Color(0xFF222C3D),
    primary: Color(0xFFD4A827),
    primaryLight: Color(0xFFF0C84A),
    primaryBg: Color(0x21D4A827),
    primaryBorder: Color(0x59D4A827),
    activeBg: Color(0x33D4A827),
    activeBorder: Color(0xFFF0C84A),
    textPrimary: Color(0xFFE8E4D8),
    textSecondary: Color(0xFF8896AA),
    textMuted: Color(0xFF5A6678),
    accent: Color(0xFF4A8EC4),
    confirm: Color(0xFFD4A827),
    danger: Color(0xFFD4721A),
    border: Color(0x12FFFFFF),
    borderMed: Color(0x21FFFFFF),
    fajr: QiblaHero(
        bg: Color(0xFF0E1A28),
        tint: Color(0xFF162436),
        label: Color(0xFF5A8AB0)),
    dhuhr: QiblaHero(
        bg: Color(0xFF201A08),
        tint: Color(0xFF30280A),
        label: Color(0xFFA08828)),
    asr: QiblaHero(
        bg: Color(0xFF0E1828),
        tint: Color(0xFF142030),
        label: Color(0xFF5A7AA0)),
    maghrib: QiblaHero(
        bg: Color(0xFF241408),
        tint: Color(0xFF341E0C),
        label: Color(0xFFB07040)),
    isha: QiblaHero(
        bg: Color(0xFF0E0E1E),
        tint: Color(0xFF14142E),
        label: Color(0xFF6A6A9A)),
  );

  // ═══════════════════════════════════════════════════════════
  // TEMA 5: MONOCROMA
  // Acromatopsia total + baja visión. Solo luminosidad.
  // ═══════════════════════════════════════════════════════════
  static const QiblaTokens monochrome = QiblaTokens(
    bgPage: Color(0xFF0C0C0C),
    bgApp: Color(0xFF161616),
    bgSurface: Color(0xFF222222),
    bgSurface2: Color(0xFF2E2E2E),
    primary: Color(0xFFE8E8E8),
    primaryLight: Color(0xFFFFFFFF),
    primaryBg: Color(0x14FFFFFF),
    primaryBorder: Color(0x38FFFFFF),
    activeBg: Color(0x23FFFFFF),
    activeBorder: Color(0xFFFFFFFF),
    textPrimary: Color(0xFFF0EFEA),
    textSecondary: Color(0xFF909090),
    textMuted: Color(0xFF606060),
    accent: Color(0xFFD0D0D0),
    confirm: Color(0xFFE8E8E8),
    danger: Color(0xFFAAAAAA),
    border: Color(0x1AFFFFFF),
    borderMed: Color(0x33FFFFFF),
    fajr: QiblaHero(
        bg: Color(0xFF111111),
        tint: Color(0xFF1A1A1A),
        label: Color(0xFF707070)),
    dhuhr: QiblaHero(
        bg: Color(0xFF181818),
        tint: Color(0xFF202020),
        label: Color(0xFF808080)),
    asr: QiblaHero(
        bg: Color(0xFF141414),
        tint: Color(0xFF1C1C1C),
        label: Color(0xFF757575)),
    maghrib: QiblaHero(
        bg: Color(0xFF1C1C1C),
        tint: Color(0xFF242424),
        label: Color(0xFF888888)),
    isha: QiblaHero(
        bg: Color(0xFF0E0E0E),
        tint: Color(0xFF161616),
        label: Color(0xFF686868)),
  );

  static String currentName = 'dark';

  /// Tema actual
  static QiblaTokens get current => fromName(currentName);

  /// Obtener tema por nombre
  static QiblaTokens fromName(String name) {
    switch (name.toLowerCase()) {
      case 'light':
        return light;
      case 'amoled':
        return amoled;
      case 'deuteranopia':
        return deuteranopia;
      case 'monochrome':
        return monochrome;
      default:
        return dark;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// ALIAS PARA COMPATIBILIDAD
// ═══════════════════════════════════════════════════════════

class AppTheme {
  final tokens = QiblaThemes.dark;

  // Colores legacy (usando tema dark por defecto)
  static const Color primaryGreen = Color(0xFFC9A84C);
  static const Color accentGold = Color(0xFFE8C97A);
  static const Color backgroundWhite = Color(0xFF0A0E14);
  static const Color textDark = Color(0xFFF3EBD1);
  static const Color textLight = Color(0xFF9BA7B4);

  // Nuevos colores del diseño v2
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8C97A);
  static const Color night = Color(0xFF0A0E14);
  static const Color deep = Color(0xFF141B27);
  static const Color surface = Color(0xFF1C2535);
  static const Color surface2 = Color(0xFF243044);
  static const Color text = Color(0xFFF3EBD1);
  static const Color muted = Color(0xFF9BA7B4);
  static const Color accent = Color(0xFF66D9EF);
  static const Color confirm = Color(0xFF69C08A);
  static const Color danger = Color(0xFFE57373);
  static const Color border = Color(0x1FE8C97A);
  static const Color borderMed = Color(0x38E8C97A);
  static const Color activeBg = Color(0x2BC9A84C);
  static const Color activeBorder = Color(0x52C9A84C);
  static const Color primaryBg = Color(0x21C9A84C);
  static const Color primaryBorder = Color(0x52C9A84C);

  // Gradientes
  static LinearGradient get prayerHeroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A3A5C), Color(0xFF0F2840), Color(0xFF1A3525)],
      );

  static LinearGradient goldGradient() => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [QiblaThemes.dark.primary, const Color(0xFFB8963C)],
      );

  // Theme Data para Material
  static ThemeData buildTheme(QiblaTokens tokens) {
    final brightness = ThemeData.estimateBrightnessForColor(tokens.bgPage);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: brightness,
    ).copyWith(
      primary: tokens.primary,
      onPrimary: tokens.bgPage,
      secondary: tokens.primaryLight,
      onSecondary: tokens.bgPage,
      surface: tokens.bgSurface,
      onSurface: tokens.textPrimary,
      error: tokens.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.bgPage,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgApp,
        foregroundColor: tokens.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.amiri(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: tokens.primary,
        ),
      ),
      textTheme: _buildTextTheme(tokens),
      cardTheme: CardThemeData(
        color: tokens.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.bgPage,
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.bgApp,
        indicatorColor: tokens.primaryBg,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final color = states.contains(MaterialState.selected)
              ? tokens.primary
              : tokens.textSecondary;
          return GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final color = states.contains(MaterialState.selected)
              ? tokens.primary
              : tokens.textSecondary;
          return IconThemeData(color: color, size: 22);
        }),
      ),
    );
  }

  static ThemeData get darkTheme => buildTheme(QiblaThemes.dark);

  static TextTheme _buildTextTheme(QiblaTokens tokens) {
    return TextTheme(
      displayLarge: GoogleFonts.amiri(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: tokens.primaryLight,
      ),
      displayMedium: GoogleFonts.amiri(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: tokens.primaryLight,
      ),
      displaySmall: GoogleFonts.amiri(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: tokens.primaryLight,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        color: tokens.textPrimary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        color: tokens.textSecondary,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        color: tokens.textMuted,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: tokens.textPrimary,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: tokens.textSecondary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: tokens.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}
