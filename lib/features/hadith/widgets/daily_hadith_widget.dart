// Widget para mostrar el Hadiz del Día en el home
// Muestra árabe + traducción + referencia con diseño atractivo

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/religious_reference_formatter.dart';
import '../../hadith/models/hadith.dart';
import '../../hadith/screens/hadith_library_screen.dart';
import '../../hadith/services/hadith_service.dart';
import '../../hadith/services/hadith_share_service.dart';
import 'hadith_share_preview_sheet.dart';
import '../widgets/hadith_widget_service.dart';

class DailyHadithWidget extends ConsumerWidget {
  const DailyHadithWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final hadithSnapshotAsync = ref.watch(dailyHadithSnapshotProvider);
    final favoritesAsync = ref.watch(hadithFavoritesProvider);

    return hadithSnapshotAsync.when(
      data: (snapshot) {
        if (snapshot == null) {
          return _HadithUnavailableWidget(
            tokens: tokens,
            onOpenLibrary: () => _openHadithLibrary(context),
          );
        }

        final hadithService = ref.read(hadithServiceProvider);
        final hadithShareService = ref.read(hadithShareServiceProvider);

        return FutureBuilder<Hadith?>(
          future: hadithService.getHadithOfDay(),
          builder: (context, hadithSnapshot) {
            if (hadithSnapshot.connectionState == ConnectionState.waiting) {
              return _LoadingHadithWidget();
            }

            final hadith = hadithSnapshot.data;
            if (hadith == null) {
              return _HadithUnavailableWidget(
                tokens: tokens,
                onOpenLibrary: () => _openHadithLibrary(context),
              );
            }

            final isFavorite = favoritesAsync.valueOrNull?.contains(hadith.id) ?? false;
            final arabicReference = ReligiousReferenceFormatter
                .buildArabicReference(snapshot.reference);

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.primary.withOpacity(0.08),
                    tokens.primary.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con título y colección
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 14,
                              color: tokens.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HADIZ DEL DÍA',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: tokens.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Colección
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCollectionColor(snapshot.collection)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              snapshot.collection,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _getCollectionColor(snapshot.collection),
                              ),
                            ),
                            if (_getArabicCollectionLabel(snapshot.collection) != null)
                              Text(
                                _getArabicCollectionLabel(snapshot.collection)!,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.amiri(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _getCollectionColor(snapshot.collection),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Texto en árabe
                  Text(
                    snapshot.arabic,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      height: 1.8,
                      color: tokens.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Traducción al español
                  Text(
                    snapshot.translation,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      height: 1.5,
                      color: tokens.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Referencia y grado de autenticidad
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.reference,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
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
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor(snapshot.grade)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              snapshot.grade,
                              style: GoogleFonts.dmSans(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: _getGradeColor(snapshot.grade),
                              ),
                            ),
                            if (_getArabicGradeLabel(snapshot.grade) != null)
                              Text(
                                _getArabicGradeLabel(snapshot.grade)!,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.amiri(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _getGradeColor(snapshot.grade),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'text') {
                              await hadithShareService.shareHadithAsText(hadith);
                              return;
                            }

                            await showHadithSharePreviewSheet(
                              context: context,
                              hadith: hadith,
                              shareService: hadithShareService,
                              tokens: tokens,
                            );
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
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tokens.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.share_outlined,
                                  size: 16,
                                  color: tokens.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Compartir',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón favoritos
                      IconButton.filled(
                        onPressed: () => _toggleFavorite(ref, hadith.id),
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isFavorite
                              ? Colors.red
                              : tokens.bgSurface,
                          foregroundColor: isFavorite
                              ? Colors.white
                              : tokens.textPrimary,
                        ),
                      ),
                      // Botón Hadices
                      SizedBox(
                        height: 40,
                        child: FilledButton.icon(
                          onPressed: () => _openHadithLibrary(context),
                          icon: const Icon(
                            Icons.auto_stories_outlined,
                            size: 18,
                          ),
                          label: const Text('Hadices'),
                          style: FilledButton.styleFrom(
                            backgroundColor: tokens.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => _LoadingHadithWidget(),
      error: (_, __) => _HadithUnavailableWidget(
        tokens: tokens,
        onOpenLibrary: () => _openHadithLibrary(context),
      ),
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, int hadithId) async {
    await ref.read(hadithServiceProvider).toggleFavorite(hadithId);
    ref.invalidate(hadithFavoritesProvider);
  }

  void _openHadithLibrary(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HadithLibraryScreen()),
    );
  }

  Color _getCollectionColor(String collection) {
    switch (collection.toLowerCase()) {
      case 'bukhari':
        return Colors.green;
      case 'muslim':
        return Colors.blue;
      case 'tirmidhi':
        return Colors.orange;
      case 'abu dawud':
        return Colors.purple;
      case 'nasai':
        return Colors.teal;
      case 'ibn majah':
        return Colors.indigo;
      case 'malik':
        return Colors.amber;
      case 'ahmad':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Color _getGradeColor(String grade) {
    if (grade == 'Sahih') return Colors.green;
    if (grade == 'Hasan') return Colors.orange;
    if (grade == 'Da\'if') return Colors.red;
    return Colors.grey;
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
}

// ── Widget de carga ────────────────────────────────────────────

class _LoadingHadithWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                width: 80,
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
            height: 40,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: tokens.border,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 20,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

class _HadithUnavailableWidget extends StatelessWidget {
  const _HadithUnavailableWidget({
    required this.tokens,
    required this.onOpenLibrary,
  });

  final QiblaTokens tokens;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_outlined, color: tokens.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'El hadiz del dia no pudo cargarse ahora mismo.',
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
