import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../models/book_model.dart';
import '../services/islamhouse_book_service.dart';
import '../screens/islamic_books_screen.dart';

/// Widget para mostrar el libro del día de IslamHouse
class DailyBookWidget extends ConsumerWidget {
  const DailyBookWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final featuredAsync = ref.watch(islamHouseFeaturedBooksProvider);

    return featuredAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return _BooksUnavailableWidget(
            tokens: tokens,
            onOpenLibrary: () => _openLibrary(context),
          );
        }

        final book = IslamHouseBook.getBookOfDay(books);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.15),
                Colors.amber.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'LIBRO DEL DÍA',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    book.category,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: tokens.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Título y autor
              Text(
                book.title,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Descripción corta
              if (book.description.isNotEmpty)
                Text(
                  book.description.length > 120
                      ? '${book.description.substring(0, 117)}...'
                      : book.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.5,
                    color: tokens.textPrimary,
                  ),
                ),

              const SizedBox(height: 14),

              // Info chips
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.description,
                    label: '${book.pages} págs',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.storage,
                    label: book.size,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.star,
                    label: book.rating.toStringAsFixed(1),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Botones de acción
              Row(
                children: [
                  // Botón leer
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(book.readUrl),
                      icon: const Icon(Icons.read_more, size: 16),
                      label: const Text('Leer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón biblioteca
                  IconButton.filled(
                    onPressed: () => _openLibrary(context),
                    icon: const Icon(Icons.library_books, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _LoadingBookWidget(tokens: tokens),
      error: (_, __) => _BooksUnavailableWidget(
        tokens: tokens,
        onOpenLibrary: () => _openLibrary(context),
      ),
    );
  }

  void _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openLibrary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IslamicBooksScreen()),
    );
  }
}

// ── Widgets Auxiliares ──────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.amber[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.amber[800],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBookWidget extends StatelessWidget {
  const _LoadingBookWidget({required this.tokens});

  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 150,
            height: 18,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BooksUnavailableWidget extends StatelessWidget {
  const _BooksUnavailableWidget({
    required this.tokens,
    required this.onOpenLibrary,
  });

  final QiblaTokens tokens;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.library_books_outlined, color: tokens.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'La biblioteca de libros no pudo cargar contenido ahora mismo.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onOpenLibrary,
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}
