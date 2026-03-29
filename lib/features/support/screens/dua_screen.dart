import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/religious_reference_formatter.dart';
import '../models/dua_model.dart';
import '../services/dua_service.dart';

class DuasScreen extends ConsumerStatefulWidget {
  const DuasScreen({super.key});

  @override
  ConsumerState<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends ConsumerState<DuasScreen> {
  String _selectedCategory = 'morning';
  late final TextEditingController _searchController;
  String _searchQuery = '';

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

  static const _categoryMeta =
      <String, ({IconData icon, String label, String hint, String arabicLabel})>{
        'morning': (
          icon: Icons.wb_sunny_outlined,
          label: 'Mañana',
          hint: 'Inicio del día',
          arabicLabel: 'الصباح',
        ),
        'night': (
          icon: Icons.nights_stay_outlined,
          label: 'Noche',
          hint: 'Cierre del día',
          arabicLabel: 'المساء',
        ),
        'sleep': (
          icon: Icons.bedtime_outlined,
          label: 'Sueño',
          hint: 'Antes de dormir',
          arabicLabel: 'النوم',
        ),
        'travel': (
          icon: Icons.connecting_airports_outlined,
          label: 'Viaje',
          hint: 'Salida y trayecto',
          arabicLabel: 'السفر',
        ),
        'food': (
          icon: Icons.restaurant_outlined,
          label: 'Comida',
          hint: 'Antes y después',
          arabicLabel: 'الطعام',
        ),
        'sickness': (
          icon: Icons.local_hospital_outlined,
          label: 'Enfermedad',
          hint: 'Curación y visita',
          arabicLabel: 'المرض',
        ),
        'protection': (
          icon: Icons.shield_outlined,
          label: 'Protección',
          hint: 'Refugio y cuidado',
          arabicLabel: 'التحصين',
        ),
        'repentance': (
          icon: Icons.refresh_outlined,
          label: 'Arrepentimiento',
          hint: 'Perdón y vuelta',
          arabicLabel: 'التوبة',
        ),
        'mosque': (
          icon: Icons.mosque_outlined,
          label: 'Mezquita',
          hint: 'Entrar y salir',
          arabicLabel: 'المسجد',
        ),
        'rain': (
          icon: Icons.water_drop_outlined,
          label: 'Lluvia',
          hint: 'Durante la lluvia',
          arabicLabel: 'المطر',
        ),
        'stress': (
          icon: Icons.self_improvement_outlined,
          label: 'Dificultad',
          hint: 'Tristeza y carga',
          arabicLabel: 'الكرب',
        ),
        'gratitude': (
          icon: Icons.favorite_border_outlined,
          label: 'Gratitud',
          hint: 'Agradecimiento',
          arabicLabel: 'الشكر',
        ),
      };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                'Dua y adhkar',
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
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleDuas = normalizedQuery.isEmpty
        ? duas
        : duas.where((dua) => _matchesSearch(dua, normalizedQuery)).toList();
    final grouped = <String, List<Dua>>{};
    for (final dua in visibleDuas) {
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
          'Dua y adhkar',
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
            'Colección ampliada con duas y adhkar para el día a día. Elige una categoría y tendrás árabe, transliteración, traducción y referencia cuando esté disponible.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: tokens.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar dua o adhkar',
            hintStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: tokens.textMuted,
            ),
            prefixIcon: Icon(Icons.search, color: tokens.textSecondary, size: 20),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: Icon(Icons.close, color: tokens.textSecondary, size: 18),
                  ),
            filled: true,
            fillColor: tokens.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: tokens.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: tokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: tokens.primaryBorder),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (normalizedQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: tokens.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      visibleDuas.isEmpty
                          ? 'No encontramos resultados para "$_searchQuery".'
                          : '${visibleDuas.length} resultado${visibleDuas.length == 1 ? '' : 's'} para "$_searchQuery".',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (visibleDuas.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin resultados',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Prueba con palabras como lluvia, viaje, protección, sueño o gratitud.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.6,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text(
            'CATEGORÍAS',
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
                    hint: 'Categoría',
                    arabicLabel: 'قسم',
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                meta.arabicLabel,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.amiri(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '$count adhkar · ${meta.hint}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: tokens.textSecondary,
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
          if (normalizedQuery.isEmpty) ...[
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
        ],
      ],
    );
  }

  bool _matchesSearch(Dua dua, String query) {
    return [
      dua.title,
      dua.arabicText,
      dua.transliteration,
      dua.translation,
      dua.category,
      dua.reference ?? '',
    ].any((field) => field.toLowerCase().contains(query));
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
    final meta = _DuasScreenState._categoryMeta[dua.category];
    final arabicReference = (dua.reference ?? '').isEmpty
        ? null
        : ReligiousReferenceFormatter.buildArabicReference(dua.reference!);

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dua.reference!,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              color: tokens.textSecondary,
                            ),
                          ),
                          if (arabicReference != null) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                arabicReference,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.amiri(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (meta != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: tokens.primary.withOpacity(0.16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            meta.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: tokens.primary,
                            ),
                          ),
                          Text(
                            meta.arabicLabel,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.amiri(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tokens.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Icon(
                    dua.isFeatured
                        ? Icons.favorite_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: dua.isFeatured ? tokens.primary : tokens.textMuted,
                  ),
                ],
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
