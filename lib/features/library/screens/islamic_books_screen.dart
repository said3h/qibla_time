import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../models/book_model.dart';
import '../services/book_download_service.dart';
import '../services/islamhouse_book_service.dart';
import '../utils/book_link_launcher.dart';

/// Pantalla de Biblioteca de Libros de IslamHouse
class IslamicBooksScreen extends ConsumerStatefulWidget {
  const IslamicBooksScreen({super.key});

  @override
  ConsumerState<IslamicBooksScreen> createState() => _IslamicBooksScreenState();
}

class _IslamicBooksScreenState extends ConsumerState<IslamicBooksScreen>
    with SingleTickerProviderStateMixin {
  static const _allCategoriesValue = '__all__';

  final _searchController = TextEditingController();
  late TabController _tabController;

  String _selectedCategory = _allCategoriesValue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final booksAsync = ref.watch(islamHouseBooksProvider);
    final featuredAsync = ref.watch(islamHouseFeaturedBooksProvider);
    final categoriesAsync = ref.watch(islamHouseCategoriesProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          l10n.booksLibraryTitle,
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAbout,
            tooltip: l10n.commonAbout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: tokens.primary,
          unselectedLabelColor: tokens.textSecondary,
          indicatorColor: tokens.primary,
          tabs: [
            Tab(icon: const Icon(Icons.library_books), text: l10n.commonBooks),
            Tab(icon: const Icon(Icons.star), text: l10n.commonFeatured),
            Tab(icon: const Icon(Icons.folder), text: l10n.booksCategoriesTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBooksTab(booksAsync),
          _buildFeaturedTab(featuredAsync),
          _buildCategoriesTab(categoriesAsync),
        ],
      ),
    );
  }

  Widget _buildBooksTab(AsyncValue<List<IslamHouseBook>> booksAsync) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.booksSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.border),
              ),
              filled: true,
              fillColor: tokens.bgSurface,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Contenido
        Expanded(
          child: booksAsync.when(
            data: (books) {
              final filtered = _filterBooks(books);

              if (filtered.isEmpty) {
                return _EmptyState(
                  message: l10n.booksEmptySearch,
                  icon: Icons.search_off,
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final book = filtered[index];
                  return _BookCard(book: book);
                },
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: tokens.primary),
            ),
            error: (_, e) => _ErrorState(error: e.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedTab(AsyncValue<List<IslamHouseBook>> featuredAsync) {
    final tokens = QiblaThemes.current;

    return featuredAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return _EmptyState(
            message: context.l10n.booksEmptyFeatured,
            icon: Icons.star_border,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BookListCard(book: book, isFeatured: true),
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.primary),
      ),
      error: (_, e) => _ErrorState(error: e.toString()),
    );
  }

  Widget _buildCategoriesTab(AsyncValue<List<IslamHouseCategory>> categoriesAsync) {
    final tokens = QiblaThemes.current;

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _EmptyState(
            message: context.l10n.booksEmptyCategories,
            icon: Icons.folder_off_outlined,
          );
        }

        final allCategories = [_allCategoriesValue, ...categories.map((c) => c.name)];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allCategories.length,
          itemBuilder: (context, index) {
            final category = allCategories[index];
            final isSelected = category == _selectedCategory;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = category);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tokens.primary.withOpacity(0.1)
                        : tokens.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? tokens.primary : tokens.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.folder_open : Icons.folder_outlined,
                        color: isSelected ? tokens.primary : tokens.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category == _allCategoriesValue
                              ? context.l10n.booksAllCategories
                              : category,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? tokens.primary : tokens.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: tokens.primary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: tokens.primary),
      ),
      error: (_, e) => _ErrorState(error: e.toString()),
    );
  }

  List<IslamHouseBook> _filterBooks(List<IslamHouseBook> books) {
    var filtered = books;

    // Filtro por categoría
    if (_selectedCategory != _allCategoriesValue) {
      filtered = filtered
          .where((b) => b.category.contains(_selectedCategory))
          .toList();
    }

    // Filtro por búsqueda
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((b) =>
              b.title.toLowerCase().contains(query) ||
              b.author.toLowerCase().contains(query) ||
              b.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  void _showAbout() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.booksLibraryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.booksAboutBody),
            const SizedBox(height: 16),
            Text(
              '• ${l10n.booksAboutBulletCatalog}',
              style: GoogleFonts.dmSans(fontSize: 12),
            ),
            Text(
              '• ${l10n.booksAboutBulletVerified}',
              style: GoogleFonts.dmSans(fontSize: 12),
            ),
            Text(
              '• ${l10n.booksAboutBulletCategories}',
              style: GoogleFonts.dmSans(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
          TextButton(
            onPressed: () {
              openBookUrl(context, 'https://islamhouse.com/es/');
            },
            child: Text(l10n.booksVisitIslamHouse),
          ),
        ],
      ),
    );
  }
}

// ── Widgets de Libros ──────────────────────────────────────────

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final IslamHouseBook book;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;

    return GestureDetector(
      onTap: () => _openBook(context),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tokens.primary.withOpacity(0.2),
                      tokens.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: book.coverUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.book, size: 40),
                      )
                    : const Icon(Icons.menu_book, size: 48),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        book.rating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        book.format,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: tokens.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookDetailSheet(book: book),
    );
  }
}

class _BookListCard extends StatelessWidget {
  const _BookListCard({required this.book, this.isFeatured = false});

  final IslamHouseBook book;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return GestureDetector(
      onTap: () => _openBook(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            // Cover
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isFeatured ? Colors.amber.withOpacity(0.3) : tokens.primary.withOpacity(0.2),
                    tokens.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: book.coverUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: book.coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.book, size: 40),
                      ),
                    )
                  : const Icon(Icons.menu_book),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            l10n.commonFeatured,
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.description, size: 12, color: tokens.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        l10n.booksPageCount(book.pages),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.download, size: 12, color: tokens.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        book.size,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              color: tokens.primary,
              onPressed: () => _openBook(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openBook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BookDetailSheet(book: book),
    );
  }
}

class _BookDetailSheet extends ConsumerStatefulWidget {
  const _BookDetailSheet({required this.book});

  final IslamHouseBook book;

  @override
  ConsumerState<_BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends ConsumerState<_BookDetailSheet> {
  bool _isCheckingDownload = true;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double? _downloadProgress;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _refreshDownloadState();
  }

  Future<void> _refreshDownloadState() async {
    final service = ref.read(bookDownloadServiceProvider);
    final localPath = await service.getLocalPath(widget.book);
    final isDownloaded = await service.isDownloaded(widget.book);
    if (!mounted) return;
    setState(() {
      _localPath = localPath;
      _isDownloaded = isDownloaded;
      _isCheckingDownload = false;
      if (!isDownloaded && !_isDownloading) {
        _downloadProgress = null;
      }
    });
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) {
      return;
    }

    final l10n = context.l10n;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      await ref.read(bookDownloadServiceProvider).downloadBook(
            widget.book,
            onProgress: (progress) {
              if (!mounted) return;
              setState(() {
                _downloadProgress = progress;
              });
            },
          );
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadProgress = 1;
      });
      await _refreshDownloadState();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadProgress = null;
      });
      _showSnackBar(l10n.bookDownloadError);
    }
  }

  Future<void> _handleOpenOffline() async {
    final l10n = context.l10n;
    final service = ref.read(bookDownloadServiceProvider);
    final localPath = _localPath ?? await service.getLocalPath(widget.book);
    final file = Uri.file(localPath);
    final launched = await launchUrl(file);
    if (!mounted) return;
    if (!launched) {
      _showSnackBar(l10n.bookLinkOpenError);
    }
  }

  Future<void> _handleDeleteDownload() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bookDeleteConfirm),
        content: Text(l10n.bookDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(bookDownloadServiceProvider).deleteBook(widget.book);
    if (!mounted) return;
    await _refreshDownloadState();
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final book = widget.book;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            book.title,
            style: GoogleFonts.amiri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          if (book.titleArabic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              book.titleArabic,
              style: GoogleFonts.amiri(
                fontSize: 18,
                color: tokens.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  book.author,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.folder, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  book.category,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.description,
                label: l10n.booksPageCount(book.pages),
              ),
              _InfoChip(icon: Icons.storage, label: book.size),
              _InfoChip(icon: Icons.star, label: book.rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.booksDescription,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.description,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.6,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => openBookUrl(context, book.readUrl),
                  icon: const Icon(Icons.read_more),
                  label: Text(l10n.commonRead),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDownloadAction(context, tokens, l10n),
              ),
            ],
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bookDownloading,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _downloadProgress,
                  minHeight: 6,
                  backgroundColor: tokens.border,
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                if (_downloadProgress != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${(_downloadProgress! * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDownloadAction(
    BuildContext context,
    QiblaTokens tokens,
    AppLocalizations l10n,
  ) {
    if (_isDownloaded) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleOpenOffline,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.bookReadOffline),
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: IconButton(
              onPressed: _handleDeleteDownload,
              tooltip: l10n.bookDeleteDownload,
              icon: const Icon(Icons.delete_outline),
              color: tokens.textSecondary,
            ),
          ),
        ],
      );
    }

    final isBusy = _isCheckingDownload || _isDownloading;
    return OutlinedButton.icon(
      onPressed: isBusy ? null : _handleDownload,
      icon: _isCheckingDownload || _isDownloading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.primary,
              ),
            )
          : const Icon(Icons.download_outlined),
      label: Text(
        _isDownloading ? l10n.bookDownloading : l10n.bookDownload,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tokens.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: tokens.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.booksLoadErrorTitle,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
