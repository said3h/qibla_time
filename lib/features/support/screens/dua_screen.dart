import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class DuaItem {
  const DuaItem({
    required this.categoryId,
    required this.categoryLabel,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.favorite,
  });

  final String categoryId;
  final String categoryLabel;
  final String arabic;
  final String transliteration;
  final String translation;
  final bool favorite;
}

class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  String _selectedCategory = 'morning';

  static const _categories = [
    ('morning', '🌅', 'Manana', '12 adhkar'),
    ('evening', '🌇', 'Tarde', '12 adhkar'),
    ('sleep', '🌙', 'Dormir', '8 adhkar'),
    ('travel', '✈️', 'Viaje', '6 duas'),
    ('food', '🍽️', 'Comida', '4 duas'),
    ('sickness', '💊', 'Enfermedad', '5 duas'),
  ];

  static const _duas = [
    DuaItem(categoryId: 'morning', categoryLabel: '🌅 Al despertar', arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا', transliteration: 'Al-hamdu lillahi alladhi ahyana bada ma amatana', translation: 'Alabado sea Allah quien nos devolvio la vida despues del sueno.', favorite: true),
    DuaItem(categoryId: 'morning', categoryLabel: '☀️ Dhikr de la manana', arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ', transliteration: 'Asbahna wa asbahal mulku lillah', translation: 'Hemos amanecido y el reino pertenece a Allah.', favorite: false),
    DuaItem(categoryId: 'evening', categoryLabel: '🌇 Al caer la tarde', arabic: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ', transliteration: 'Amsayna wa amsal mulku lillah', translation: 'Hemos llegado a la tarde y el reino pertenece a Allah.', favorite: true),
    DuaItem(categoryId: 'sleep', categoryLabel: '🌙 Antes de dormir', arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', transliteration: 'Bismika Allahumma amutu wa ahya', translation: 'En Tu nombre, oh Allah, muero y vivo.', favorite: false),
    DuaItem(categoryId: 'travel', categoryLabel: '✈️ Al viajar', arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا', transliteration: 'Subhana alladhi sakhkhara lana hadha', translation: 'Glorificado sea Quien puso esto a nuestro servicio.', favorite: false),
    DuaItem(categoryId: 'travel', categoryLabel: '🚗 Al salir de casa', arabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ', transliteration: 'Bismi llah tawakkaltu ala llah', translation: 'En el nombre de Allah, me encomiendo a Allah.', favorite: true),
    DuaItem(categoryId: 'food', categoryLabel: '🍽️ Antes de comer', arabic: 'بِسْمِ اللَّهِ', transliteration: 'Bismi llah', translation: 'En el nombre de Allah.', favorite: false),
    DuaItem(categoryId: 'food', categoryLabel: '🙏 Despues de comer', arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَٰذَا', transliteration: 'Al-hamdu lillahi alladhi atamani hadha', translation: 'Alabado sea Allah, que me alimento con esto.', favorite: false),
    DuaItem(categoryId: 'sickness', categoryLabel: '💊 En enfermedad', arabic: 'اللَّهُمَّ رَبَّ النَّاسِ أَذْهِبِ الْبَأْسَ', transliteration: 'Allahumma rabb an-nas adhhib al-bas', translation: 'Oh Allah, Senor de la humanidad, aleja el dano.', favorite: true),
    DuaItem(categoryId: 'sickness', categoryLabel: '🤍 Para pedir perdon', arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي', transliteration: 'Allahumma innaka afuwwun tuhibb al-afwa fa fu anni', translation: 'Oh Allah, Tu eres Indulgente y amas perdonar, asi que perdoname.', favorite: true),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final filtered = _duas.where((item) => item.categoryId == _selectedCategory).toList();
    final favorites = _duas.where((item) => item.favorite).toList();

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
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (_, index) {
                final category = _categories[index];
                final selected = category.$1 == _selectedCategory;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category.$1),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? tokens.activeBg : tokens.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? tokens.activeBorder : tokens.border),
                    ),
                    child: Row(
                      children: [
                        Text(category.$2, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(category.$3, style: GoogleFonts.dmSans(fontSize: 12, color: tokens.textPrimary, fontWeight: FontWeight.w500)),
                              Text(category.$4, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('SELECCIONADA', style: GoogleFonts.dmSans(fontSize: 9, letterSpacing: 1.4, color: tokens.textSecondary)),
            const SizedBox(height: 10),
            ...filtered.map((dua) => _DuaCard(dua: dua)),
            const SizedBox(height: 14),
            Text('FAVORITOS', style: GoogleFonts.dmSans(fontSize: 9, letterSpacing: 1.4, color: tokens.textSecondary)),
            const SizedBox(height: 10),
            ...favorites.map((dua) => _DuaCard(dua: dua)),
          ],
        ),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.dua});

  final DuaItem dua;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
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
                child: Text(dua.categoryLabel, style: GoogleFonts.dmSans(fontSize: 10, color: tokens.primary, letterSpacing: 1.0)),
              ),
              Text(dua.favorite ? '❤️' : '🤍', style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(dua.arabic, textAlign: TextAlign.right, style: GoogleFonts.amiri(fontSize: 18, color: tokens.textPrimary, height: 1.9)),
          const SizedBox(height: 8),
          Text(dua.transliteration, style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary, fontStyle: FontStyle.italic, height: 1.6)),
          const SizedBox(height: 6),
          Text(dua.translation, style: GoogleFonts.dmSans(fontSize: 12, color: tokens.textPrimary, height: 1.7)),
        ],
      ),
    );
  }
}
