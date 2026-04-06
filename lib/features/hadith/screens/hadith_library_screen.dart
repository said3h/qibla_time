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
import '../utils/hadith_category_presentation.dart';
import '../utils/hadith_collection_presentation.dart';
import '../widgets/hadith_share_preview_sheet.dart';
import 'hadith_category_detail_screen.dart';
import 'hadith_collection_detail_screen.dart';
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
  static const _allCategoriesValue = '__all__';

  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  String _selectedCollection = _allCollectionsValue;
  String _selectedGrade = _allGradesValue;
  String _selectedCategory = _allCategoriesValue;
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
    final categoriesAsync = ref.watch(hadithCategoriesProvider);

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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      const SizedBox(height: 8),
                      categoriesAsync.when(
                        data: (categories) => _FilterDropdown(
                          label: l10n.commonCategory,
                          value: _selectedCategory,
                          items: [_allCategoriesValue, ...categories.keys],
                          itemLabelBuilder: (value) => value == _allCategoriesValue
                              ? l10n.hadithLibraryAllCategories
                              : value,
                          onChanged: (v) => setState(() => _selectedCategory = v ?? _allCategoriesValue),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
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
                    if (_searchController.text.trim().isEmpty)
                      collectionsAsync.when(
                        data: (collections) => _buildCollectionSection(
                          context: context,
                          collections: collections,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                    if (_searchController.text.trim().isEmpty)
                      categoriesAsync.when(
                        data: (categories) => _buildCategorySection(
                          context: context,
                          hadiths: hadiths,
                          categories: categories,
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

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

    if (_selectedCategory != _allCategoriesValue) {
      filtered = filtered
          .where((h) => h.category.trim().toLowerCase() == _selectedCategory)
          .toList();
    }

    return filtered;
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required List<Hadith> hadiths,
    required Map<String, int> categories,
  }) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = QiblaThemes.current;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabicOnly = languageCode == 'ar';
    final categoryEntries = categories.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.commonCategory,
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
            itemCount: categoryEntries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (_, index) {
              final entry = categoryEntries[index];
              final categoryHadiths = hadiths
                  .where((hadith) => hadith.category.trim().toLowerCase() == entry.key)
                  .toList();
              final meta = HadithCategoryPresentation.metaFor(
                entry.key,
                languageCode,
              );
              final showArabicLabel =
                  meta.arabicLabel.isNotEmpty && meta.arabicLabel != meta.label;

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HadithCategoryDetailScreen(
                        categoryKey: entry.key,
                        categoryLabel: meta.label,
                        categoryArabicLabel: meta.arabicLabel,
                        hadiths: categoryHadiths,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.border),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: isArabicOnly
                                  ? GoogleFonts.amiri(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    )
                                  : GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textPrimary,
                                    ),
                            ),
                            if (showArabicLabel)
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
                              context.l10n.hadithLibraryAllHadiths(entry.value),
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
        ],
      ),
    );
  }

  Widget _buildCollectionSection({
    required BuildContext context,
    required Map<String, int> collections,
  }) {
    if (collections.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = QiblaThemes.current;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabicOnly = languageCode == 'ar';
    final collectionEntries = collections.entries.toList()
      ..sort((a, b) {
        final leftOrder = HadithCollectionPresentation.orderedCollections.indexOf(
          a.key,
        );
        final rightOrder =
            HadithCollectionPresentation.orderedCollections.indexOf(b.key);
        if (leftOrder != -1 || rightOrder != -1) {
          if (leftOrder == -1) return 1;
          if (rightOrder == -1) return -1;
          return leftOrder.compareTo(rightOrder);
        }
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.commonCollection,
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
            itemCount: collectionEntries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (_, index) {
              final entry = collectionEntries[index];
              final meta = HadithCollectionPresentation.metaFor(
                entry.key,
                languageCode,
              );
              final showArabicLabel =
                  meta.arabicLabel.isNotEmpty && meta.arabicLabel != meta.label;

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HadithCollectionDetailScreen(
                        collectionKey: entry.key,
                        collectionLabel: meta.label,
                        collectionArabicLabel: meta.arabicLabel,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.border),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: isArabicOnly
                                  ? GoogleFonts.amiri(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    )
                                  : GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textPrimary,
                                    ),
                            ),
                            if (showArabicLabel)
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
                              context.l10n.hadithLibraryAllHadiths(entry.value),
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
        ],
      ),
    );
  }

  String _collectionLabel(BuildContext context, String value) {
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';
    if (value == _allCollectionsValue) {
      return context.l10n.hadithLibraryAllCollections;
    }
    if (value == 'Other' || value == 'Otros') {
      return context.l10n.commonOther;
    }
    if (isArabicOnly) {
      return _getArabicCollectionLabel(value) ?? value;
    }
    return value;
  }

  String _gradeLabel(BuildContext context, String value) {
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';
    if (value == _allGradesValue) {
      return context.l10n.hadithLibraryAllGrades;
    }
    if (isArabicOnly) {
      return _getArabicGradeLabel(value) ?? value;
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
          initialValue: items.contains(value) ? value : items.first,
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
    final collection = _extractCollection(hadith.reference);
    final arabicCollectionLabel = _getArabicCollectionLabel(collection);
    final collectionLabel =
        isArabicOnly ? (arabicCollectionLabel ?? collection) : collection;
    final arabicGradeLabel = _getArabicGradeLabel(hadith.grade);
    final gradeLabel =
        isArabicOnly ? (arabicGradeLabel ?? hadith.grade) : hadith.grade;
    final primaryReference =
        isArabicOnly ? (arabicReference ?? '') : hadith.reference;
    final hasTranslation = hadith.translation.trim().isNotEmpty;
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
                  color: tokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      collectionLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tokens.primary,
                      ),
                    ),
                    if (!isArabicOnly && arabicCollectionLabel != null)
                      Text(
                        arabicCollectionLabel,
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
          if (!isArabicOnly && hasTranslation) ...[
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
                    if (primaryReference.isNotEmpty)
                      Text(
                        primaryReference,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                    if (!isArabicOnly && arabicReference != null) ...[
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
                  color: _getGradeColor(hadith.grade).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      gradeLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getGradeColor(hadith.grade),
                      ),
                    ),
                    if (!isArabicOnly && arabicGradeLabel != null)
                      Text(
                        arabicGradeLabel,
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
    final arabicGradeLabel = _getArabicGradeLabel(hadith.grade);
    final gradeLabel =
        isArabicOnly ? (arabicGradeLabel ?? hadith.grade) : hadith.grade;
    final primaryReference =
        isArabicOnly ? (arabicReference ?? '') : hadith.reference;
    final hasTranslation = hadith.translation.trim().isNotEmpty;
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
                      if (primaryReference.isNotEmpty)
                        Text(
                          primaryReference,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: tokens.textSecondary,
                          ),
                        ),
                      if (!isArabicOnly && arabicReference != null) ...[
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
                    color: _getGradeColor(hadith.grade).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        gradeLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getGradeColor(hadith.grade),
                        ),
                      ),
                      if (!isArabicOnly && arabicGradeLabel != null)
                        Text(
                          arabicGradeLabel,
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
            if (!isArabicOnly && hasTranslation) ...[
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

final hadithCategoriesProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(hadithServiceProvider).getCategories();
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
  return 'Otros';
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
