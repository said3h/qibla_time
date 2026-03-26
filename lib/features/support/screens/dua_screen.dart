import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/dua_model.dart';
import '../services/dua_service.dart';

class DuasScreen extends ConsumerStatefulWidget {
  const DuasScreen({super.key});

  @override
  ConsumerState<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends ConsumerState<DuasScreen> {
  String _selectedCategory = 'morning';

  static const _categoryOrder = [
    'morning',
    'night',
    'sleep',
    'travel',
    'food',
    'sickness',
    'protection',
    'repentance',
    'mosque',
    'rain',
    'stress',
    'gratitude',
  ];

  static const _categoryMeta = <String, ({IconData icon, String label, String hint})>{
    'morning': (
      icon: Icons.wb_sunny_outlined,
      label: 'Manana',
      hint: 'Inicio del dia',
    ),
    'night': (
      icon: Icons.nights_stay_outlined,
      label: 'Noche',
      hint: 'Cierre del dia',
    ),
    'sleep': (
      icon: Icons.bedtime_outlined,
      label: 'Sueno',
      hint: 'Antes de dormir',
    ),
    'travel': (
      icon: Icons.connecting_airports_outlined,
      label: 'Viaje',
      hint: 'Salida y trayecto',
    ),
    'food': (
      icon: Icons.restaurant_outlined,
      label: 'Comida',
      hint: 'Antes y despues',
    ),
    'sickness': (
      icon: Icons.local_hospital_outlined,
      label: 'Enfermedad',
      hint: 'Curacion y visita',
    ),
    'protection': (
      icon: Icons.shield_outlined,
      label: 'Proteccion',
      hint: 'Refugio y cuidado',
    ),
    'repentance': (
      icon: Icons.refresh_outlined,
      label: 'Arrepentimiento',
      hint: 'Perdon y vuelta',
    ),
    'mosque': (
      icon: Icons.mosque_outlined,
      label: 'Mezquita',
      hint: 'Entrar y salir',
    ),
    'rain': (
      icon: Icons.water_drop_outlined,
      label: 'Lluvia',
      hint: 'Durante la lluvia',
    ),
    'stress': (
      icon: Icons.self_improvement_outlined,
      label: 'Dificultad',
      hint: 'Tristeza y carga',
    ),
    'gratitude': (
      icon: Icons.favorite_border_outlined,
      label: 'Gratitud',
      hint: 'Agradecimiento',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final duasAsync = ref.watch(allDuasProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: duasAsync.when(
          data: (duas) => _buildLoadedState(context, tokens, duas),
          loading: () => Center(
            child: CircularProgressIndicator(color: tokens.primary),
          ),
          error: (_, __) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'Dua & Adhkar',
                style: GoogleFonts.amiri(
                  fontSize: 26,
                  color: tokens.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  'No pudimos cargar el contenido de Dua ahora mismo.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    QiblaTokens tokens,
    List<Dua> duas,
  ) {
    final grouped = <String, List<Dua>>{};
    for (final dua in duas) {
      grouped.putIfAbsent(dua.category, () => <Dua>[]).add(dua);
    }

    final categoryKeys = _categoryOrder
        .where(grouped.containsKey)
        .followedBy(grouped.keys.where((key) => !_categoryOrder.contains(key)))
        .toList();

    final effectiveCategory = categoryKeys.contains(_selectedCategory)
        ? _selectedCategory
        : (categoryKeys.isNotEmpty ? categoryKeys.first : '');

    final selected = grouped[effectiveCategory] ?? const <Dua>[];
    final featured = duas.where((dua) => dua.isFeatured).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Dua & Adhkar',
          style: GoogleFonts.amiri(
            fontSize: 26,
            color: tokens.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'الادعية والاذكار',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.primaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.primaryBorder),
          ),
          child: Text(
            'Coleccion ampliada con duas y adhkar para el dia a dia. Elige una categoria y tendras arabe, transliteracion, traduccion y referencia cuando este disponible.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'CATEGORIAS',
          style: GoogleFonts.dmSans(
            fontSize: 9,
            letterSpacing: 1.4,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoryKeys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (_, index) {
            final key = categoryKeys[index];
            final meta = _categoryMeta[key] ??
                (
                  icon: Icons.auto_awesome_outlined,
                  label: key,
                  hint: 'Categoria',
                );
            final selectedCategory = key == effectiveCategory;
            final count = grouped[key]?.length ?? 0;

            return InkWell(
              onTap: () => setState(() => _selectedCategory = key),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selectedCategory ? tokens.activeBg : tokens.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedCategory
                        ? tokens.activeBorder
                        : tokens.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(meta.icon, size: 22, color: tokens.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            meta.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$count adhkar',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: tokens.textSecondary,
                            ),
                          ),
                          Text(
                            meta.hint,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: tokens.textMuted,
                            ),
                          ),
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
        Text(
          'SELECCIONADA',
          style: GoogleFonts.dmSans(
            fontSize: 9,
            letterSpacing: 1.4,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ...selected.map((dua) => _DuaCard(dua: dua)),
        const SizedBox(height: 12),
        Text(
          'DESTACADAS',
          style: GoogleFonts.dmSans(
            fontSize: 9,
            letterSpacing: 1.4,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ...featured.take(6).map((dua) => _DuaCard(dua: dua, compact: true)),
      ],
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({
    required this.dua,
    this.compact = false,
  });

  final Dua dua;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dua.title.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: tokens.primary,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((dua.reference ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dua.reference!,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                dua.isFeatured
                    ? Icons.favorite_rounded
                    : Icons.bookmark_border_rounded,
                size: 18,
                color: dua.isFeatured ? tokens.primary : tokens.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dua.arabicText,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              fontSize: compact ? 17 : 19,
              color: tokens.textPrimary,
              height: 1.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dua.transliteration,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: tokens.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dua.translation,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: tokens.textPrimary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
