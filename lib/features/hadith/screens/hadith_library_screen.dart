import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../models/hadith.dart';
import '../services/hadith_service.dart';
import '../services/hadith_share_service.dart';

class HadithLibraryScreen extends ConsumerStatefulWidget {
  const HadithLibraryScreen({super.key});

  @override
  ConsumerState<HadithLibraryScreen> createState() =>
      _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends ConsumerState<HadithLibraryScreen> {
  String _selectedCategory = 'Todas';

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final allHadithsAsync = ref.watch(allHadithsProvider);
    final dailyHadithAsync = ref.watch(dailyHadithProvider);
    final favoritesAsync = ref.watch(hadithFavoritesProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          'Hadith',
          style: GoogleFonts.amiri(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
      ),
      body: allHadithsAsync.when(
        data: (hadiths) {
          final favorites = favoritesAsync.valueOrNull ?? const <int>{};
          final categories = [
            'Todas',
            ...{
              for (final hadith in hadiths) _formatCategory(hadith.category),
            },
          ]..sort((a, b) {
              if (a == 'Todas') return -1;
              if (b == 'Todas') return 1;
              return a.compareTo(b);
            });

          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'Todas';
          }

          final filteredHadiths = _selectedCategory == 'Todas'
              ? hadiths
              : hadiths
                  .where(
                    (hadith) =>
                        _formatCategory(hadith.category) == _selectedCategory,
                  )
                  .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              dailyHadithAsync.when(
                data: (dailyHadith) => dailyHadith == null
                    ? const SizedBox.shrink()
                    : _FeaturedHadithCard(
                        hadith: dailyHadith,
                        isFavorite: favorites.contains(dailyHadith.id),
                        onToggleFavorite: () => _toggleFavorite(dailyHadith.id),
                        onShareText: () => _shareText(dailyHadith),
                        onShareImage: () => _shareImage(dailyHadith),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              Text(
                'EXPLORAR POR TEMA',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = categories[index];
                    final selected = category == _selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                      backgroundColor: tokens.bgSurface,
                      selectedColor: tokens.primaryBg,
                      side: BorderSide(
                        color: selected ? tokens.primaryBorder : tokens.border,
                      ),
                      labelStyle: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: selected ? tokens.primary : tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (filteredHadiths.isEmpty)
                _EmptyCategoryState(category: _selectedCategory)
              else
                ...filteredHadiths.map(
                  (hadith) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HadithCard(
                      hadith: hadith,
                      isFavorite: favorites.contains(hadith.id),
                      onToggleFavorite: () => _toggleFavorite(hadith.id),
                      onShareText: () => _shareText(hadith),
                      onShareImage: () => _shareImage(hadith),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: tokens.primary),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudieron cargar los hadiths ahora mismo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: tokens.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(int hadithId) async {
    await ref.read(hadithServiceProvider).toggleFavorite(hadithId);
    ref.invalidate(hadithFavoritesProvider);
  }

  Future<void> _shareText(Hadith hadith) async {
    await Share.share('${hadith.translation}\n\n${hadith.reference}');
  }

  Future<void> _shareImage(Hadith hadith) async {
    try {
      await ref.read(hadithShareServiceProvider).shareHadithAsImage(
            hadith,
            QiblaThemes.current,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar la imagen del hadith ahora mismo.'),
        ),
      );
    }
  }

  String _formatCategory(String rawCategory) {
    if (rawCategory.isEmpty) return 'Sin tema';
    return rawCategory[0].toUpperCase() + rawCategory.substring(1);
  }
}

class _FeaturedHadithCard extends StatelessWidget {
  const _FeaturedHadithCard({
    required this.hadith,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShareText,
    required this.onShareImage,
  });

  final Hadith hadith;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HADITH DEL DIA',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              Text(
                _formatCategory(hadith.category),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hadith.arabic,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              fontSize: 22,
              height: 1.7,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hadith.translation,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${hadith.reference} - ${hadith.grade}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _HadithActions(
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
            onShareText: onShareText,
            onShareImage: onShareImage,
          ),
        ],
      ),
    );
  }

  String _formatCategory(String rawCategory) {
    if (rawCategory.isEmpty) return 'Sin tema';
    return rawCategory[0].toUpperCase() + rawCategory.substring(1);
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    required this.hadith,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShareText,
    required this.onShareImage,
  });

  final Hadith hadith;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hadith.reference,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              Text(
                _formatCategory(hadith.category),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hadith.arabic,
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              fontSize: 19,
              height: 1.7,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hadith.translation,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hadith.grade,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: tokens.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          _HadithActions(
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
            onShareText: onShareText,
            onShareImage: onShareImage,
          ),
        ],
      ),
    );
  }

  String _formatCategory(String rawCategory) {
    if (rawCategory.isEmpty) return 'Sin tema';
    return rawCategory[0].toUpperCase() + rawCategory.substring(1);
  }
}

class _HadithActions extends StatelessWidget {
  const _HadithActions({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShareText,
    required this.onShareImage,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onShareText,
          icon: const Icon(Icons.short_text_outlined),
          label: const Text('Compartir texto'),
        ),
        OutlinedButton.icon(
          onPressed: onShareImage,
          icon: const Icon(Icons.image_outlined),
          label: const Text('Compartir PNG'),
        ),
        OutlinedButton.icon(
          onPressed: onToggleFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
          label: Text(isFavorite ? 'Guardado' : 'Guardar'),
        ),
      ],
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        'No hay hadiths disponibles en la categoria $category todavia.',
        style: GoogleFonts.dmSans(
          fontSize: 12,
          height: 1.6,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}
