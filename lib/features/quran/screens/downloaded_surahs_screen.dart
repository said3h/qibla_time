import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../services/quran_audio_download_service.dart';
import '../services/quran_service.dart';
import 'quran_screen.dart';

class DownloadedSurahsScreen extends ConsumerWidget {
  const DownloadedSurahsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final surahs = ref.watch(quranSurahsProvider);
    final downloadedAsync = ref.watch(downloadedSurahNumbersProvider);
    final favoritesAsync = ref.watch(favoriteDownloadedSurahsProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(
          'Suras descargadas',
          style: GoogleFonts.amiri(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
      ),
      body: downloadedAsync.when(
        data: (downloadedNumbers) {
          final favoriteNumbers = favoritesAsync.valueOrNull ?? const <int>{};
          final downloadedSurahs = surahs
              .where((surah) => downloadedNumbers.contains(surah.number))
              .toList();

          if (downloadedSurahs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Todavía no has descargado audio de ninguna sura.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: tokens.textSecondary),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: downloadedSurahs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final surah = downloadedSurahs[index];
              final isFavorite = favoriteNumbers.contains(surah.number);
              return Container(
                padding: const EdgeInsets.all(14),
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
                        CircleAvatar(
                          backgroundColor: tokens.primaryBg,
                          foregroundColor: tokens.primary,
                          child: Text(
                            '${surah.number}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surah.nameLatin,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                surah.nameArabic,
                                style: GoogleFonts.amiri(
                                  fontSize: 18,
                                  color: tokens.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isFavorite)
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: tokens.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuranDetailScreen(summary: surah),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Abrir'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final service = ref.read(quranAudioDownloadServiceProvider);
                            await service.toggleDownloadedSurahFavorite(surah.number);
                            ref.invalidate(favoriteDownloadedSurahsProvider);
                          },
                          icon: Icon(
                            isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                          ),
                          label: Text(
                            isFavorite ? 'Favorita' : 'Marcar favorita',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final service = ref.read(quranAudioDownloadServiceProvider);
                            await service.removeSurahDownload(surah.number);
                            ref.invalidate(downloadedSurahNumbersProvider);
                            ref.invalidate(favoriteDownloadedSurahsProvider);
                          },
                          icon: const Icon(Icons.cloud_off_outlined),
                          label: const Text('Quitar descarga'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: tokens.primary),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar la lista de descargas ahora mismo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: tokens.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
