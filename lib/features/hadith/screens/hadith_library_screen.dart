import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/hadith.dart';
import '../services/hadith_service.dart';
import '../services/hadith_share_service.dart';
import 'hadith_detail_screen.dart';

class HadithLibraryScreen extends ConsumerStatefulWidget {
  const HadithLibraryScreen({super.key});

  @override
  ConsumerState<HadithLibraryScreen> createState() =>
      _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends ConsumerState<HadithLibraryScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  String _selectedCollection = 'Todas';
  String _selectedGrade = 'Todos';
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
    final allHadithsAsync = ref.watch(allHadithsProvider);
    final dailyHadithAsync = ref.watch(dailyHadithProvider);
    final favoritesAsync = ref.watch(hadithFavoritesProvider);
    final collectionsAsync = ref.watch(hadithCollectionsProvider);
    final gradesAsync = ref.watch(hadithGradesProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          'Biblioteca de Hadices',
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
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de bÃƒÂºsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar hadices...',
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
                          label: 'ColecciÃƒÂ³n',
                          value: _selectedCollection,
                          items: ['Todas', ...collections.keys],
                          onChanged: (v) => setState(() => _selectedCollection = v ?? 'Todas'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterDropdown(
                          label: 'Autenticidad',
                          value: _selectedGrade,
                          items: ['Todos', ...grades],
                          onChanged: (v) => setState(() => _selectedGrade = v ?? 'Todos'),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Contenido principal
          Expanded(
            child: allHadithsAsync.when(
              data: (hadiths) {
                final favorites = favoritesAsync.valueOrNull ?? const <int>{};

                // Determinar quÃƒÂ© hadices mostrar
                List<Hadith> displayHadiths;

                if (_isSearching) {
                  // Mostrando resultados de bÃƒÂºsqueda
                  displayHadiths = _applyFilters(_searchResults);
                } else if (_searchResults.isNotEmpty && _searchController.text.isEmpty) {
                  // BÃƒÂºsqueda previa, volver a todos
                  displayHadiths = _applyFilters(hadiths);
                } else {
                  // Vista normal con filtros
                  displayHadiths = _applyFilters(hadiths);
                }

                // Ordenar: hadiz del dÃƒÂ­a primero si existe
                final dailyHadith = dailyHadithAsync.valueOrNull;
                if (dailyHadith != null && displayHadiths.any((h) => h.id == dailyHadith.id)) {
                  displayHadiths.removeWhere((h) => h.id == dailyHadith.id);
                  displayHadiths.insert(0, dailyHadith);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Hadiz del dÃƒÂ­a destacado
                    if (dailyHadith != null && !_isSearching)
                      _FeaturedHadithCard(
                        hadith: dailyHadith,
                        isFavorite: favorites.contains(dailyHadith.id),
                        onToggleFavorite: () => _toggleFavorite(dailyHadith.id),
                        onShareText: () => _shareText(dailyHadith),
                        onShareImage: () => _shareImage(dailyHadith),
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
                                ? '${displayHadiths.length} resultado${displayHadiths.length != 1 ? 's' : ''}'
                                : 'TODOS LOS HADICES (${hadiths.length})',
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
              error: (_, e) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No se pudieron cargar los hadices: $e',
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

    // Filtro por colecciÃƒÂ³n
    if (_selectedCollection != 'Todas') {
      filtered = filtered
          .where((h) => _extractCollection(h.reference) == _selectedCollection)
          .toList();
    }

    // Filtro por grado de autenticidad
    if (_selectedGrade != 'Todos') {
      filtered = filtered
          .where((h) => h.grade == _selectedGrade)
          .toList();
    }

    return filtered;
  }

  String _extractCollection(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari')) return 'Bukhari';
    if (refLower.contains('muslim')) return 'Muslim';
    if (refLower.contains('tirmidhi')) return 'Tirmidhi';
    if (refLower.contains('abu dawud') || refLower.contains('abudawud')) return 'Abu Dawud';
    if (refLower.contains('nasai')) return 'Nasai';
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) return 'Ibn Majah';
    if (refLower.contains('malik') || refLower.contains('muwatta')) return 'Malik';
    if (refLower.contains('ahmad')) return 'Ahmad';
    return 'Otros';
  }

  Future<void> _toggleFavorite(int hadithId) async {
    await ref.read(hadithServiceProvider).toggleFavorite(hadithId);
    ref.invalidate(hadithFavoritesProvider);
  }

  Future<void> _shareText(Hadith hadith) async {
    await ref.read(hadithShareServiceProvider).shareHadithAsText(hadith);
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
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Widgets Auxiliares Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
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
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _extractCollection(hadith.reference),
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tokens.primary,
                  ),
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
          Row(
            children: [
              Text(
                hadith.reference,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getGradeColor(hadith.grade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hadith.grade,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _getGradeColor(hadith.grade),
                  ),
                ),
              ),
            ],
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

  Color _getGradeColor(String grade) {
    if (grade == 'Sahih') return Colors.green;
    if (grade == 'Hasan') return Colors.orange;
    return Colors.grey;
  }

  String _extractCollection(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari')) return 'Bukhari';
    if (refLower.contains('muslim')) return 'Muslim';
    if (refLower.contains('tirmidhi')) return 'Tirmidhi';
    if (refLower.contains('abu dawud') || refLower.contains('abudawud')) return 'Abu Dawud';
    if (refLower.contains('nasai')) return 'Nasai';
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) return 'Ibn Majah';
    if (refLower.contains('malik') || refLower.contains('muwatta')) return 'Malik';
    if (refLower.contains('ahmad')) return 'Ahmad';
    return 'Otros';
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getGradeColor(hadith.grade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hadith.grade,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _getGradeColor(hadith.grade),
                  ),
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
    required this.onShareText,
    required this.onShareImage,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShareText;
  final VoidCallback onShareImage;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'text') {
              onShareText();
              return;
            }
            onShareImage();
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'text',
              child: Text('Compartir texto'),
            ),
            PopupMenuItem<String>(
              value: 'image',
              child: Text('Compartir imagen'),
            ),
          ],
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
                  'Compartir',
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
          label: Text(isFavorite ? 'Guardado' : 'Guardar'),
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
                ? 'No se encontraron hadices para "$query"'
                : 'No hay hadices disponibles',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Intenta con otros tÃƒÂ©rminos o quita los filtros'
                : 'Los hadices se cargarÃƒÂ¡n pronto',
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

// Ã¢â€â‚¬Ã¢â€â‚¬ Debouncer para bÃƒÂºsqueda Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

class Debouncer {
  Debouncer({required this.delay});
  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Providers adicionales Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

final hadithCollectionsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(hadithServiceProvider).getCollections();
});

final hadithGradesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(hadithServiceProvider).getAvailableGrades();
});
