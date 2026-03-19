import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    const categories = [
      ('🌅', 'Manana', '12 adhkar'),
      ('🌇', 'Tarde', '12 adhkar'),
      ('🌙', 'Dormir', '8 adhkar'),
      ('✈️', 'Viaje', '6 duas'),
      ('🍽️', 'Comida', '4 duas'),
      ('💊', 'Enfermedad', '5 duas'),
    ];
    const duas = [
      ('🌅 Al despertar', 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا', 'Al-ḥamdu lillahi alladhi ahyana ba da ma amatana', 'Alabado sea Allah quien nos devolvio la vida despues del sueno.'),
      ('🤍 Para pedir perdon', 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', 'Allahumma innaka afuwwun tuhibb al-afwa fa fu anni', 'Oh Allah, Tu eres Indulgente y amas perdonar, asi que perdoname.'),
      ('🚗 Al salir de casa', 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', 'Bismi llah tawakkaltu ala llah wa la hawla wa la quwwata illa billah', 'En el nombre de Allah, me encomiendo a Allah y no hay fuerza sino en El.'),
    ];

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Dua & Adhkar', style: GoogleFonts.amiri(fontSize: 26, color: tokens.primary, fontWeight: FontWeight.bold)),
            Text('الأدعية والأذكار', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
            const SizedBox(height: 16),
            Text('CATEGORIAS', style: GoogleFonts.dmSans(fontSize: 9, letterSpacing: 1.4, color: tokens.textSecondary)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (_, index) {
                final category = categories[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Row(
                    children: [
                      Text(category.$1, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(category.$2, style: GoogleFonts.dmSans(fontSize: 12, color: tokens.textPrimary, fontWeight: FontWeight.w500)),
                            Text(category.$3, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('FAVORITOS', style: GoogleFonts.dmSans(fontSize: 9, letterSpacing: 1.4, color: tokens.textSecondary)),
            const SizedBox(height: 10),
            ...duas.map(
              (dua) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(dua.$1, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primary, letterSpacing: 1.0)),
                        ),
                        const Text('❤️', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(dua.$2, textAlign: TextAlign.right, style: GoogleFonts.amiri(fontSize: 18, color: tokens.textPrimary, height: 1.9)),
                    const SizedBox(height: 8),
                    Text(dua.$3, style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary, fontStyle: FontStyle.italic, height: 1.6)),
                    const SizedBox(height: 6),
                    Text(dua.$4, style: GoogleFonts.dmSans(fontSize: 12, color: tokens.textPrimary, height: 1.7)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
