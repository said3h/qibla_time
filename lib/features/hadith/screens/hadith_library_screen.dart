import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/religious_reference_formatter.dart';
import '../../../l10n/l10n.dart';
import '../models/hadith.dart';
import '../services/hadith_service.dart';
import '../services/hadith_share_service.dart';
import '../widgets/hadith_share_preview_sheet.dart';
import 'hadith_detail_screen.dart';
import 'hadith_offline_screen.dart';

class HadithLibraryScreen extends ConsumerStatefulWidget {
  const HadithLibraryScreen({super.key});

  @override
  ConsumerState<HadithLibraryScreen> createState() =>
      _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends ConsumerState<HadithLibraryScreen> {
  static const _allCollectionsValue = '__all__';
  static const _allGradesValue = '__all__';

  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  String _selectedCollection = _allCollectionsValue;
  String _selectedGrade = _allGradesValue;
  List<Hadith> _searchResults = [];
  bool _isSearching = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debouncer.run(() {
      if (_searchController.text.trim().isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      } else {
        setState(() => _isSearching = true);
        _searchHadiths(_searchController.text.trim());
      }
    });
  }

  Future<void> _searchHadiths(String query) async {
    final results = await ref.read(hadithServiceProvider).searchHadiths(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';
    final allHadithsAsync = ref.watch(allHadithsProvider);
    final dailyHadithAsync = ref.watch(dailyHadithProvider);
    final favoritesAsync = ref.watch(hadithFavoritesProvider);
    final collectionsAsync = ref.watch(hadithCollectionsProvider);
    final gradesAsync = ref.watch(hadithGradesProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.hadithLibraryTitle,
          style: GoogleFonts.amiri(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: l10n.commonFilter,
          ),
          IconButton(
            icon: const Icon(Icons.offline_pin_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HadithOfflineScreen(),
                ),
              );
            },
            tooltip: l10n.hadithOfflineTitle,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.hadithLibrarySearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tokens.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tokens.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tokens.primary, width: 2),
                ),
                filled: true,
                fillColor: tokens.bgSurface,
              ),
            ),
          ),

          // Filtros desplegables
          if (_showFilters)
            collectionsAsync.when(
              data: (collections) => gradesAsync.when(
                data: (grades) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown(
                          label: l10n.commonCollection,
                          value: _selectedCollection,
                          items: [_allCollectionsValue, ...collections.keys],
                          itemLabelBuilder: (value) => _collectionLabel(context, value),
                          onChanged: (v) => setState(() => _selectedCollection = v ?? _allCollectionsValue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterDropdown(
                          label: l10n.commonAuthenticity,
                          value: _selectedGrade,
                          items: [_allGradesValue, ...grades],
                          itemLabelBuilder: (value) => _gradeLabel(context, value),
                          onChanged: (v) => setState(() => _selectedGrade = v ?? _allGradesValue),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => _FilterStatusBanner(
                  message: l10n.hadithLibraryFiltersLoading,
                ),
                error: (_, __) => _FilterStatusBanner(
                  message: l10n.hadithLibraryFiltersError,
                ),
              ),
              loading: () => _FilterStatusBanner(
                message: l10n.hadithLibraryFiltersLoading,
              ),
              error: (_, __) => _FilterStatusBanner(
                message: l10n.hadithLibraryFiltersError,
              ),
            ),

          // Contenido principal
          Expanded(
            child: allHadithsAsync.when(
              data: (hadiths) {
                final favorites = favoritesAsync.valueOrNull ?? const <int>{};

                // Determinar qué hadices mostrar
                List<Hadith> displayHadiths;

                if (_isSearching) {
                  // Mostrando resultados de búsqueda
                  displayHadiths = _applyFilters(_searchResults);
                } else if (_searchResults.isNotEmpty && _searchController.text.isEmpty) {
                  // Búsqueda previa, volver a todos
                  displayHadiths = _applyFilters(hadiths);
                } else {
                  // Vista normal con filtros
                  displayHadiths = _applyFilters(hadiths);
                }

                // Ordenar: hadiz del día primero si existe
                final dailyHadith = dailyHadithAsync.valueOrNull;
                if (dailyHadith != null && displayHadiths.any((h) => h.id == dailyHadith.id)) {
                  displayHadiths.removeWhere((h) => h.id == dailyHadith.id);
                  displayHadiths.insert(0, dailyHadith);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Hadiz del día destacado
                    if (dailyHadith != null && !_isSearching)
                      _FeaturedHadithCard(
                        hadith: dailyHadith,
                        isArabicOnly: isArabicOnly,
                        isFavorite: favorites.contains(dailyHadith.id),
                        onToggleFavorite: () => _toggleFavorite(dailyHadith.id),
                        onShare: () => _shareImage(dailyHadith),
                      ),

                    if (dailyHadith != null && !_isSearching)
                      const SizedBox(height: 16),

                    // Contador de resultados
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(
                            _isSearching || _searchController.text.isNotEmpty
                                ? l10n.hadithLibraryResultsCount(displayHadiths.length)
                                : l10n.hadithLibraryAllHadiths(hadiths.length),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.3,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de hadices
                    if (displayHadiths.isEmpty)
                      _EmptyState(
                        isSearch: _searchController.text.isNotEmpty,
                        query: _searchController.text,
                      )
                    else
                      ...displayHadiths.map(
                        (hadith) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HadithCard(
                            hadith: hadith,
                            isArabicOnly: isArabicOnly,
                            isFavorite: favorites.contains(hadith.id),
                            onToggleFavorite: () => _toggleFavorite(hadith.id),
                            onShare: () => _shareImage(hadith),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: tokens.primary),
              ),
              error: (_, e) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.hadithLibraryLoadError(e.toString()),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(color: tokens.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Hadith> _applyFilters(List<Hadith> hadiths) {
    var filtered = hadiths;

    if (_selectedCollection != _allCollectionsValue) {
      filtered = filtered
          .where((h) => _extractCollection(h.reference) == _selectedCollection)
          .toList();
    }

    if (_selectedGrade != _allGradesValue) {
      filtered = filtered
          .where((h) => h.grade == _selectedGrade)
          .toList();
    }

    return filtered;
  }

  String _collectionLabel(BuildContext context, String value) {
    if (value == _allCollectionsValue) {
      return context.l10n.hadithLibraryAllCollections;
    }
    if (value == 'Other') {
      return context.l10n.commonOther;
    }
    return value;
  }

  String _gradeLabel(BuildContext context, String value) {
    if (value == _allGradesValue) {
      return context.l10n.hadithLibraryAllGrades;
    }
    return value;
  }

  String _extractCollection(String reference) {
    return _extractHadithCollection(reference);
  }

  Future<void> _toggleFavorite(int hadithId) async {
    await ref.read(hadithServiceProvider).toggleFavorite(hadithId);
    ref.invalidate(hadithFavoritesProvider);
  }

  Future<void> _shareImage(Hadith hadith) async {
    await showHadithSharePreviewSheet(
      context: context,
      hadith: hadith,
      shareService: ref.read(hadithShareServiceProvider),
      tokens: QiblaThemes.current,
    );
  }
}

// ── Widgets Auxiliares ──────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final String Function(String value) itemLabelBuilder;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : items.first,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(itemLabelBuilder(item)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: tokens.border),
            ),
            filled: true,
            fillColor: tokens.bgSurface,
          ),
          dropdownColor: tokens.bgSurface,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FilterStatusBanner extends StatelessWidget {
  const _FilterStatusBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: tokens.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  height: 1.4,
                  color: tokens.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedHadithCard extends StatelessWidget {
  const _FeaturedHadithCard({
    required this.hadith,
    required this.isArabicOnly,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final Hadith hadith;
  final bool isArabicOnly;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final arabicReference = ReligiousReferenceFormatter.buildArabicReference(
      hadith.reference,
    );
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
                  context.l10n.hadithDailyBadge,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _extractCollection(hadith.reference),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tokens.primary,
                      ),
                    ),
                    if (_getArabicCollectionLabel(_extractCollection(hadith.reference)) !=
                        null)
                      Text(
                        _getArabicCollectionLabel(
                          _extractCollection(hadith.reference),
                        )!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tokens.primary,
                        ),
                      ),
                  ],
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
          if (!isArabicOnly) ...[
            const SizedBox(height: 10),
            Text(
              hadith.translation,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.6,
                color: tokens.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hadith.reference,
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGradeColor(hadith.grade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hadith.grade,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getGradeColor(hadith.grade),
                      ),
                    ),
                    if (_getArabicGradeLabel(hadith.grade) != null)
                      Text(
                        _getArabicGradeLabel(hadith.grade)!,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getGradeColor(hadith.grade),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _HadithActions(
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
            onShare: onShare,
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade == 'Sahih') return Colors.green;
    if (grade == 'Hasan') return Colors.orange;
    return Colors.grey;
  }

  String _extractCollection(String reference) {
    return _extractHadithCollection(reference);
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    required this.hadith,
    required this.isArabicOnly,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final Hadith hadith;
  final bool isArabicOnly;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final arabicReference = ReligiousReferenceFormatter.buildArabicReference(
      hadith.reference,
    );
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HadithDetailScreen(hadith: hadith),
          ),
        );
      },
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hadith.reference,
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
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(hadith.grade).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hadith.grade,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getGradeColor(hadith.grade),
                        ),
                      ),
                      if (_getArabicGradeLabel(hadith.grade) != null)
                        Text(
                          _getArabicGradeLabel(hadith.grade)!,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getGradeColor(hadith.grade),
                          ),
                        ),
                    ],
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
            if (!isArabicOnly) ...[
              const SizedBox(height: 8),
              Text(
                hadith.translation,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  height: 1.6,
                  color: tokens.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _HadithActions(
              isFavorite: isFavorite,
              onToggleFavorite: onToggleFavorite,
              onShare: onShare,
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade == 'Sahih') return Colors.green;
    if (grade == 'Hasan') return Colors.orange;
    return Colors.grey;
  }
}

class _HadithActions extends StatelessWidget {
  const _HadithActions({
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onShare,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_outlined, size: 18, color: tokens.textPrimary),
                const SizedBox(width: 8),
                Text(
                  context.l10n.commonShare,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onToggleFavorite,
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.red : tokens.textPrimary,
          ),
          label: Text(
            isFavorite ? context.l10n.commonSaved : context.l10n.commonSave,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearch, required this.query});

  final bool isSearch;
  final String query;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.library_books_outlined,
            size: 64,
            color: tokens.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? context.l10n.hadithLibraryEmptySearchTitle(query)
                : context.l10n.hadithLibraryEmptyTitle,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? context.l10n.hadithLibraryEmptySearchBody
                : context.l10n.hadithLibraryEmptyBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Debouncer para búsqueda ─────────────────────────────────────

class Debouncer {
  Debouncer({required this.delay});
  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}

// ── Providers adicionales ───────────────────────────────────────

final hadithCollectionsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(hadithServiceProvider).getCollections();
});

final hadithGradesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(hadithServiceProvider).getAvailableGrades();
});

String _extractHadithCollection(String reference) {
  final refLower = reference.toLowerCase();
  if (refLower.contains('bujari') || refLower.contains('bukhari')) {
    return 'Bukhari';
  }
  if (refLower.contains('muslim')) return 'Muslim';
  if (refLower.contains('tirmidhi')) return 'Tirmidhi';
  if (refLower.contains('abu dawud') || refLower.contains('abudawud')) {
    return 'Abu Dawud';
  }
  if (refLower.contains('nasai')) return 'Nasai';
  if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) {
    return 'Ibn Majah';
  }
  if (refLower.contains('malik') || refLower.contains('muwatta')) {
    return 'Malik';
  }
  if (refLower.contains('ahmad')) return 'Ahmad';
  return 'Other';
}

String? _getArabicCollectionLabel(String collection) {
  switch (collection.trim().toLowerCase()) {
    case 'bukhari':
      return 'البخاري';
    case 'muslim':
      return 'مسلم';
    case 'tirmidhi':
      return 'الترمذي';
    case 'abu dawud':
      return 'أبو داود';
    case 'nasai':
      return 'النسائي';
    case 'ibn majah':
      return 'ابن ماجه';
    case 'malik':
      return 'مالك';
    case 'ahmad':
      return 'أحمد';
    default:
      return null;
  }
}

String? _getArabicGradeLabel(String grade) {
  switch (grade.trim().toLowerCase()) {
    case 'sahih':
      return 'صحيح';
    case 'hasan':
      return 'حسن';
    case 'da\'if':
    case 'daif':
      return 'ضعيف';
    default:
      return null;
  }
}
