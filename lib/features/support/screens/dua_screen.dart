// Pantalla de Duas con diseño del prototipo
// Cards organizadas por categorías con íconos

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class Dua {
  final String category;
  final String arabic;
  final String translation;
  final IconData icon;

  const Dua({
    required this.category,
    required this.arabic,
    required this.translation,
    required this.icon,
  });
}

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    final duas = [
      const Dua(
        category: '🌅 Al despertar',
        arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
        translation: 'Alabado sea Allah quien nos dio vida después de habernos hecho morir, y a Él es el retorno.',
        icon: Icons.wb_sunny_outlined,
      ),
      const Dua(
        category: '🍽️ Antes de comer',
        arabic: 'بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ',
        translation: 'En el nombre de Allah y con la bendición de Allah.',
        icon: Icons.restaurant,
      ),
      const Dua(
        category: '🕌 Para pedir perdón',
        arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
        translation: 'Oh Allah, ciertamente Tú eres Indulgente y amas la indulgencia, así que perdóname.',
        icon: Icons.favorite_outline,
      ),
      const Dua(
        category: '🌙 Antes de dormir',
        arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
        translation: 'En Tu nombre, oh Allah, muero y vivo.',
        icon: Icons.nights_stay_outlined,
      ),
      const Dua(
        category: '🚗 Al salir de casa',
        arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
        translation: 'En el nombre de Allah, me encomiendo a Allah y no hay fuerza ni poder excepto con Allah.',
        icon: Icons.directions_car_outlined,
      ),
      const Dua(
        category: '🕌 Al entrar a la mezquita',
        arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
        translation: 'Oh Allah, ábreme las puertas de Tu misericordia.',
        icon: Icons.mosque,
      ),
      const Dua(
        category: '🤲 Por el conocimiento',
        arabic: 'رَبِّ زِدْنِي عِلْمًا',
        translation: 'Señor mío, auméntame en conocimiento.',
        icon: Icons.school_outlined,
      ),
      const Dua(
        category: '💪 Por la paciencia',
        arabic: 'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَتَوَفَّنَا مُسْلِمِينَ',
        translation: 'Señor nuestro, derrama sobre nosotros paciencia y haznos morir sumisos a Ti.',
        icon: Icons.self_improvement_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgApp,
        title: Text(
          'Duas',
          style: GoogleFonts.amiri(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...duas.map((dua) => _buildDuaCard(dua, tokens)),
        ],
      ),
    );
  }

  Widget _buildDuaCard(Dua dua, QiblaTokens tokens) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categoría con ícono
          Row(
            children: [
              Icon(dua.icon, size: 18, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                dua.category,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Árabe
          Text(
            dua.arabic,
            style: GoogleFonts.amiri(
              fontSize: 20,
              height: 2,
              color: tokens.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 12),
          
          // Traducción
          Text(
            dua.translation,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: tokens.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
