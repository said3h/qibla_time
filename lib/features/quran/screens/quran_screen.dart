import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../models/quran_models.dart';
import '../services/quran_service.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final surahs = ref.watch(quranSurahsProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Coran', style: GoogleFonts.amiri(fontSize: 26, color: tokens.primary, fontWeight: FontWeight.bold)),
            Text('القرآن الكريم · 114 suras', style: GoogleFonts.dmSans(fontSize: 10, color: tokens.textSecondary)),
            const SizedBox(height: 16),
            ...surahs.map((surah) => _SurahTile(surah: surah)),
          ],
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah});

  final SurahSummary surah;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => QuranDetailScreen(summary: surah),
          ));
        },
        leading: CircleAvatar(
          backgroundColor: tokens.primaryBg,
          foregroundColor: tokens.primary,
          child: Text('${surah.number}', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        title: Text(surah.nameLatin, style: GoogleFonts.dmSans(color: tokens.textPrimary, fontWeight: FontWeight.w500)),
        subtitle: Text('${surah.revelationType} · ${surah.ayahCount} ayas', style: GoogleFonts.dmSans(fontSize: 11, color: tokens.textSecondary)),
        trailing: Text(surah.nameArabic, style: GoogleFonts.amiri(fontSize: 20, color: tokens.primaryLight)),
      ),
    );
  }
}

class QuranDetailScreen extends ConsumerWidget {
  const QuranDetailScreen({super.key, required this.summary});

  final SurahSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final detailAsync = ref.watch(surahDetailProvider(summary));

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(summary.nameLatin),
      ),
      body: detailAsync.when(
        data: (detail) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: detail.ayahs.length,
          itemBuilder: (_, index) {
            final ayah = detail.ayahs[index];
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
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: tokens.primaryBg,
                        foregroundColor: tokens.primary,
                        child: Text('${ayah.numberInSurah}', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text(summary.nameArabic, style: GoogleFonts.amiri(fontSize: 18, color: tokens.primaryLight)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ayah.arabic,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiri(fontSize: 22, height: 1.8, color: tokens.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ayah.translation,
                    style: GoogleFonts.dmSans(fontSize: 13, height: 1.7, color: tokens.textPrimary),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator(color: tokens.primary)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar esta sura ahora mismo. Comprueba la conexion e intentalo de nuevo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: tokens.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
