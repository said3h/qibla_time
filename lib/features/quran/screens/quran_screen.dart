import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/qibla_snackbar.dart';
import '../../../core/utils/share_sheet_origin.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../../hafiz/screens/hafiz_mode_screen.dart';
import '../../quran_share/services/ayah_share_service.dart';
import '../../quran_share/services/ayah_share_video_service.dart';
import '../../quran_share/widgets/ayah_share_preview_sheet.dart';
import '../../tafsir/widgets/tafsir_panel.dart';
import '../domain/quran_ayah_selection.dart';
import '../models/quran_models.dart';
import '../widgets/quran_ayah_card.dart';
import '../widgets/quran_continuous_view.dart';
import 'allah_names_screen.dart';
import '../services/quran_audio_download_service.dart';
import '../services/quran_mini_player_service.dart';
import '../services/quran_reading_service.dart';
import '../services/quran_reader_preferences.dart';
import '../services/quran_service.dart';
import '../services/quran_word_service.dart';
import 'downloaded_surahs_screen.dart';

const _enableQuranTafsirPanels =
    bool.fromEnvironment('QURAN_TAFSIR_PANEL_ENABLED', defaultValue: true);

const _enableQuranWordByWord =
    bool.fromEnvironment('QURAN_WORD_BY_WORD_ENABLED', defaultValue: false);

@visibleForTesting
bool supportsQuranWordByWordOnline(int surahNumber) {
  return _enableQuranWordByWord && surahNumber >= 1 && surahNumber <= 114;
}

@visibleForTesting
bool shouldReplaceQuranDetailForPlaybackSurah({
  required int currentScreenSurahNumber,
  required QuranMiniPlayerState? previous,
  required QuranMiniPlayerState next,
}) {
  return previous != null &&
      previous.playbackMode == QuranMiniPlaybackMode.surah &&
      previous.surahNumber == currentScreenSurahNumber &&
      next.playbackMode == QuranMiniPlaybackMode.surah &&
      next.isVisible &&
      previous.surahNumber != next.surahNumber &&
      next.surahNumber != currentScreenSurahNumber;
}

bool looksLikeQuranReferenceQuery(String query) {
  final trimmed = query.trim();
  return RegExp(r'^\d{1,3}\s*[:/]\s*\d{1,3}$').hasMatch(trimmed) ||
      RegExp(r'^\d{1,3}\s*[:/]\s*$').hasMatch(trimmed) ||
      RegExp(r'^\d{1,3}\s+\d{1,3}$').hasMatch(trimmed);
}

@visibleForTesting
int? partialQuranReferenceSurahNumber(String query) {
  final match = RegExp(r'^\s*(\d{1,3})\s*[:/]\s*$').firstMatch(query);
  if (match == null) return null;
  final surahNumber = int.tryParse(match.group(1) ?? '');
  if (surahNumber == null || surahNumber < 1 || surahNumber > 114) {
    return null;
  }
  return surahNumber;
}

@visibleForTesting
bool shouldApplySavedQuranViewMode({
  required bool userChangedViewMode,
  required bool mounted,
}) {
  return mounted && !userChangedViewMode;
}

@visibleForTesting
int nextQuranViewModeGeneration(int current) => current + 1;

QuranReference? parseQuranReferenceQuery(
  String query,
  List<SurahSummary> surahs,
) {
  final match =
      RegExp(r'^\s*(\d{1,3})(?:\s*[:/]\s*|\s+)(\d{1,3})\s*$').firstMatch(query);
  if (match == null) return null;

  final surahNumber = int.tryParse(match.group(1) ?? '');
  final ayahNumber = int.tryParse(match.group(2) ?? '');
  if (surahNumber == null || ayahNumber == null) return null;
  if (surahNumber < 1 || surahNumber > 114 || ayahNumber < 1) return null;

  SurahSummary? summary;
  for (final surah in surahs) {
    if (surah.number == surahNumber) {
      summary = surah;
      break;
    }
  }
  if (summary == null || ayahNumber > summary.ayahCount) return null;

  return QuranReference(
    surahNumber: surahNumber,
    ayahNumber: ayahNumber,
  );
}

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SurahSummary> _filterSurahs(List<SurahSummary> surahs) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return surahs;

    final partialReferenceSurah = partialQuranReferenceSurahNumber(query);
    if (partialReferenceSurah != null) {
      return surahs
          .where((surah) => surah.number == partialReferenceSurah)
          .toList();
    }

    if (looksLikeQuranReferenceQuery(query)) {
      return const <SurahSummary>[];
    }

    final queryLower = query.toLowerCase();
    final queryNumber = int.tryParse(query);

    return surahs.where((surah) {
      if (queryNumber != null && surah.number == queryNumber) return true;
      if (surah.nameLatin.toLowerCase().contains(queryLower)) return true;
      if (surah.nameArabic.contains(query)) return true;
      return false;
    }).toList();
  }

  SurahSummary _summaryFor(List<SurahSummary> surahs, int surahNumber) {
    return surahs.firstWhere(
      (surah) => surah.number == surahNumber,
      orElse: () => surahs.first,
    );
  }

  void _openQuranReference(
    QuranReference reference,
    List<SurahSummary> surahs,
  ) {
    final summary = _summaryFor(surahs, reference.surahNumber);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuranDetailScreen(
          summary: summary,
          initialAyah: reference.ayahNumber,
        ),
      ),
    );
  }

  void _handleSearchSubmitted(String value, List<SurahSummary> surahs) {
    final reference = parseQuranReferenceQuery(value, surahs);
    if (reference != null) {
      _openQuranReference(reference, surahs);
      return;
    }

    if (!looksLikeQuranReferenceQuery(value)) return;
    showQiblaSnackBar(
      context,
      message: 'Reference not found. Try a valid format like 2:255.',
      icon: Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    final surahs = ref.watch(quranSurahsProvider);
    final lastReading = ref.watch(lastReadingProvider).valueOrNull;
    final bookmarks = ref.watch(quranBookmarksProvider).valueOrNull ?? const [];
    final downloadedSurahs =
        ref.watch(downloadedSurahNumbersProvider).valueOrNull ?? const <int>[];
    final favoriteDownloadedSurahs =
        ref.watch(favoriteDownloadedSurahsProvider).valueOrNull ??
            const <int>{};
    final filteredSurahs = _filterSurahs(surahs);
    final quranReference = parseQuranReferenceQuery(_searchQuery, surahs);
    final isReferenceSearch = looksLikeQuranReferenceQuery(_searchQuery);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.quranTitle,
                        style: GoogleFonts.amiri(
                          fontSize: 26,
                          color: tokens.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.quranSubtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HafizModeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_stories),
                  label: Text(l10n.quranHafizLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _QuranUtilityRow(
              onProtectionTap: () {
                final baqarah = _summaryFor(surahs, 2);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuranDetailScreen(
                      summary: baqarah,
                      initialAyah: 255,
                    ),
                  ),
                );
              },
              onAllahNamesTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AllahNamesScreen(),
                  ),
                );
              },
            ),
            if (lastReading == null && bookmarks.isEmpty) ...[
              const SizedBox(height: 16),
              const _ReadingHintCard(),
            ],
            if (lastReading != null) ...[
              const SizedBox(height: 16),
              _ContinueReadingCard(
                point: lastReading,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuranDetailScreen(
                        summary: _summaryFor(surahs, lastReading.surahNumber),
                        initialAyah: lastReading.ayahNumber,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (bookmarks.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BookmarksCard(
                bookmarks: bookmarks,
                onTap: (bookmark) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuranDetailScreen(
                        summary: _summaryFor(surahs, bookmark.surahNumber),
                        initialAyah: bookmark.ayahNumber,
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            _DailyProtectionCard(
              onOpenAyatAlKursi: () {
                final summary = _summaryFor(surahs, 2);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuranDetailScreen(
                      summary: summary,
                      initialAyah: 255,
                    ),
                  ),
                );
              },
              onOpenSurah: (surahNumber) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QuranDetailScreen(
                      summary: _summaryFor(surahs, surahNumber),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _SurahSearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (value) => _handleSearchSubmitted(value, surahs),
            ),
            const SizedBox(height: 8),
            if (quranReference != null)
              _QuranReferenceResultCard(
                reference: quranReference,
                summary: _summaryFor(surahs, quranReference.surahNumber),
                onTap: () => _openQuranReference(quranReference, surahs),
              )
            else if (isReferenceSearch && filteredSurahs.isEmpty)
              _QuranReferenceInvalidResult(tokens: tokens)
            else if (filteredSurahs.isEmpty)
              _QuranSearchEmpty(tokens: tokens)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSurahs.length,
                itemBuilder: (context, index) {
                  final surah = filteredSurahs[index];
                  return _SurahTile(
                    surah: surah,
                    lastReading: lastReading,
                    bookmarks: bookmarks,
                    isDownloaded: downloadedSurahs.contains(surah.number),
                    isDownloadedFavorite:
                        favoriteDownloadedSurahs.contains(surah.number),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Surah search bar ──────────────────────────────────────────

class _SurahSearchBar extends StatelessWidget {
  const _SurahSearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          color: tokens.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: l10n.quranSearchHint,
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: tokens.textMuted,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: tokens.textMuted),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: tokens.textMuted),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _QuranReferenceResultCard extends StatelessWidget {
  const _QuranReferenceResultCard({
    required this.reference,
    required this.summary,
    required this.onTap,
  });

  final QuranReference reference;
  final SurahSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: tokens.primaryBg,
          foregroundColor: tokens.primary,
          child: const Icon(Icons.my_location_rounded, size: 18),
        ),
        title: Text(
          '${_surahPrimaryName(context, summary)} ${reference.ayahNumber}',
          style: GoogleFonts.dmSans(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Open ${summary.number}:${reference.ayahNumber}',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: tokens.textSecondary,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_rounded, color: tokens.primary),
      ),
    );
  }
}

class _QuranSearchEmpty extends StatelessWidget {
  const _QuranSearchEmpty({required this.tokens});

  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: tokens.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.quranSearchEmpty,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: tokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuranReferenceInvalidResult extends StatelessWidget {
  const _QuranReferenceInvalidResult({required this.tokens});

  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: tokens.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enter a valid reference like 2:255.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Utility row ────────────────────────────────────────────────

class _QuranUtilityRow extends StatelessWidget {
  const _QuranUtilityRow({
    required this.onProtectionTap,
    required this.onAllahNamesTap,
  });

  final VoidCallback onProtectionTap;
  final VoidCallback onAllahNamesTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onProtectionTap,
          icon: const Icon(Icons.shield_moon_outlined),
          label: Text(l10n.quranUtilityAyatAlKursi),
        ),
        OutlinedButton.icon(
          onPressed: onAllahNamesTap,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(l10n.quranUtilityAllahNames),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DownloadedSurahsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.download_done),
          label: Text(l10n.quranUtilityDownloaded),
        ),
      ],
    );
  }
}

class _DailyProtectionCard extends StatefulWidget {
  const _DailyProtectionCard({
    required this.onOpenAyatAlKursi,
    required this.onOpenSurah,
  });

  final VoidCallback onOpenAyatAlKursi;
  final ValueChanged<int> onOpenSurah;

  @override
  State<_DailyProtectionCard> createState() => _DailyProtectionCardState();
}

class _DailyProtectionCardState extends State<_DailyProtectionCard> {
  final Map<String, int> _repeatCounts = {
    'kursi': 0,
    'ikhlas': 0,
    'falaq': 0,
    'nas': 0,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          Text(
            l10n.quranProtectionTitle,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quranProtectionSubtitle,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _ProtectionTile(
            title: l10n.quranUtilityAyatAlKursi,
            helper: l10n.quranProtectionAyatAlKursiHelper,
            count: _repeatCounts['kursi'] ?? 0,
            onIncrement: () => _increment('kursi'),
            onOpen: widget.onOpenAyatAlKursi,
          ),
          const SizedBox(height: 10),
          _ProtectionTile(
            title: l10n.quranProtectionIkhlasTitle,
            helper: l10n.quranProtectionSurahHelper(112),
            count: _repeatCounts['ikhlas'] ?? 0,
            onIncrement: () => _increment('ikhlas'),
            onOpen: () => widget.onOpenSurah(112),
          ),
          const SizedBox(height: 10),
          _ProtectionTile(
            title: l10n.quranProtectionFalaqTitle,
            helper: l10n.quranProtectionSurahHelper(113),
            count: _repeatCounts['falaq'] ?? 0,
            onIncrement: () => _increment('falaq'),
            onOpen: () => widget.onOpenSurah(113),
          ),
          const SizedBox(height: 10),
          _ProtectionTile(
            title: l10n.quranProtectionNasTitle,
            helper: l10n.quranProtectionSurahHelper(114),
            count: _repeatCounts['nas'] ?? 0,
            onIncrement: () => _increment('nas'),
            onOpen: () => widget.onOpenSurah(114),
          ),
        ],
      ),
    );
  }

  void _increment(String key) {
    setState(() {
      final current = _repeatCounts[key] ?? 0;
      _repeatCounts[key] = current >= 3 ? 0 : current + 1;
    });
  }
}

class _ProtectionTile extends StatelessWidget {
  const _ProtectionTile({
    required this.title,
    required this.helper,
    required this.count,
    required this.onIncrement,
    required this.onOpen,
  });

  final String title;
  final String helper;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    final isComplete = count >= 3;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete ? tokens.primaryBg : tokens.bgSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete ? tokens.primaryBorder : tokens.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.quranProtectionRepeatCount(helper, count),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: Icon(
              isComplete ? Icons.check_circle_outline : Icons.repeat_rounded,
              color: tokens.primary,
            ),
            tooltip: isComplete
                ? l10n.quranProtectionCompleteTooltip
                : l10n.quranProtectionIncrementTooltip,
          ),
          OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l10n.commonOpen),
          ),
        ],
      ),
    );
  }
}

class _ReadingHintCard extends StatelessWidget {
  const _ReadingHintCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.menu_book_outlined, color: tokens.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quranReadingHintTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    letterSpacing: 1.4,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.quranReadingHintBody,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.5,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.quranReadingHintSecondary,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.5,
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.point,
    required this.onTap,
  });

  final QuranReadingPoint point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.primaryBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.primaryBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.bookmark_added_outlined,
                color: tokens.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quranContinueReadingTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _readingPointLabel(context, point),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: tokens.primary),
          ],
        ),
      ),
    );
  }
}

class _BookmarksCard extends StatelessWidget {
  const _BookmarksCard({
    required this.bookmarks,
    required this.onTap,
  });

  final List<QuranReadingPoint> bookmarks;
  final ValueChanged<QuranReadingPoint> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          Text(
            l10n.quranBookmarksTitle,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              letterSpacing: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...bookmarks.take(3).map(
                (bookmark) => InkWell(
                  onTap: () => onTap(bookmark),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_outline,
                            size: 16, color: tokens.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _readingPointLabel(context, bookmark),
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: tokens.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.lastReading,
    required this.bookmarks,
    required this.isDownloaded,
    required this.isDownloadedFavorite,
  });

  final SurahSummary surah;
  final QuranReadingPoint? lastReading;
  final List<QuranReadingPoint> bookmarks;
  final bool isDownloaded;
  final bool isDownloadedFavorite;

  String _revelationLabel(BuildContext context, String revelationType) {
    final l10n = context.l10n;
    switch (revelationType) {
      case 'Meccan':
        return l10n.quranRevelationMecca;
      case 'Medinan':
        return l10n.quranRevelationMedina;
      default:
        return revelationType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';
    final isLastRead = lastReading?.surahNumber == surah.number;
    final bookmarkCount = bookmarks
        .where((bookmark) => bookmark.surahNumber == surah.number)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isLastRead ? tokens.activeBorder : tokens.border),
      ),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuranDetailScreen(summary: surah),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: tokens.primaryBg,
          foregroundColor: tokens.primary,
          child: Text(
            '${surah.number}',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          _surahPrimaryName(context, surah),
          style: GoogleFonts.dmSans(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_revelationLabel(context, surah.revelationType)} · ${l10n.quranAyahCount(surah.ayahCount)}',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: tokens.textSecondary,
              ),
            ),
            if (isLastRead)
              Text(
                l10n.quranLastReadingAyah(lastReading!.ayahNumber),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.primary,
                ),
              ),
            if (bookmarkCount > 0)
              Text(
                l10n.quranBookmarkCount(bookmarkCount),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textMuted,
                ),
              ),
            if (isDownloaded)
              Text(
                isDownloadedFavorite
                    ? l10n.quranDownloadedFavoriteOffline
                    : l10n.quranDownloadedAudio,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.primary,
                ),
              ),
          ],
        ),
        trailing: isArabicOnly
            ? null
            : Text(
                surah.nameArabic,
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  color: tokens.primaryLight,
                ),
              ),
      ),
    );
  }
}

enum _QuranPlaybackMode {
  none,
  ayah,
  surah,
}

enum _AyahShareAction {
  text,
  image,
  video,
  saveVideo,
}

enum _VideoExportAction {
  share,
  save,
}

class QuranDetailScreen extends ConsumerStatefulWidget {
  const QuranDetailScreen({
    super.key,
    required this.summary,
    this.initialAyah = 1,
  });

  final SurahSummary summary;
  final int initialAyah;

  @override
  ConsumerState<QuranDetailScreen> createState() => _QuranDetailScreenState();
}

const _kQuranViewModeKey = 'quran_view_mode_page';

class _QuranDetailScreenState extends ConsumerState<QuranDetailScreen> {
  ItemScrollController _itemScrollController = ItemScrollController();
  ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final TextEditingController _ayahJumpController = TextEditingController();
  final AudioService _audioService = AudioService.instance;
  bool _isPageView = false;
  bool _userChangedViewMode = false;
  bool _initialJumpDone = false;
  bool _initialReadingSaved = false;
  SurahAudioDownloadState? _downloadState;
  bool _isCheckingDownloadState = true;
  bool _hasRequestedDownloadState = false;
  bool _isDownloadedFavorite = false;
  DateTime? _lastUserListScrollAt;
  int? _lastAutoScrolledListAyahNumber;
  int? _lastObservedPlayingAyahNumber;
  int _listAutoScrollGeneration = 0;
  int _viewModeGeneration = 0;
  int? _continuousManualScrollAyahIndex;
  int _continuousManualScrollRequestId = 0;
  int? _openTafsirAyahNumber;
  final Set<int> _selectedAyahs = <int>{};
  final Set<String> _loggedTafsirVisibilityReasons = <String>{};

  static const int _maxSelectedAyahs = 5;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
  }

  @override
  void dispose() {
    _ayahJumpController.dispose();
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kQuranViewModeKey);
    if (!shouldApplySavedQuranViewMode(
      userChangedViewMode: _userChangedViewMode,
      mounted: mounted,
    )) {
      return;
    }
    setState(() {
      _isPageView = saved ?? false;
    });
  }

  Future<void> _toggleViewMode() async {
    final newValue = !_isPageView;
    setState(() {
      _userChangedViewMode = true;
      _isPageView = newValue;
      _viewModeGeneration = nextQuranViewModeGeneration(_viewModeGeneration);
      if (!newValue) {
        _itemScrollController = ItemScrollController();
        _itemPositionsListener = ItemPositionsListener.create();
        _lastAutoScrolledListAyahNumber = null;
        _lastObservedPlayingAyahNumber = null;
        _listAutoScrollGeneration++;
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kQuranViewModeKey, newValue);
  }

  Future<void> _toggleTajweed(bool value) async {
    await SettingsService.instance.saveQuranTajweedEnabled(value);
    ref.invalidate(quranTajweedEnabledProvider);
  }

  Future<void> _toggleWordByWord(bool value) async {
    if (!_enableQuranWordByWord) {
      return;
    }

    if (value) {
      final hasConnection = ref.read(connectivityStatusProvider).valueOrNull;
      if (hasConnection == false) {
        if (!mounted) return;
        showQiblaSnackBar(
          context,
          message: 'Word-by-Word requiere conexión',
          icon: Icons.wifi_off_rounded,
        );
        return;
      }
    }

    await SettingsService.instance.saveQuranWordByWordEnabled(value);
    ref.invalidate(quranWordByWordEnabledProvider);
    if (value) {
      ref.invalidate(quranWordsForSurahProvider(widget.summary.number));
    }
  }

  Future<void> _toggleTafsirForAyah(int ayahNumber) async {
    if (!_enableQuranTafsirPanels) {
      _logTafsirVisibility('button ignored: feature flag off');
      return;
    }
    if (_isPageView) {
      _logTafsirVisibility('button ignored: page mode incompatible');
      return;
    }
    if (_isSelectionMode) {
      _logTafsirVisibility('button ignored: selection mode active');
      return;
    }

    if (!mounted) return;
    setState(() {
      _openTafsirAyahNumber =
          _openTafsirAyahNumber == ayahNumber ? null : ayahNumber;
    });
  }

  QuranMiniPlayerState get _miniPlayerState =>
      ref.read(quranMiniPlayerControllerProvider);

  SurahSummary? _summaryForSurahNumber(int surahNumber) {
    for (final summary in QuranService.allSurahs) {
      if (summary.number == surahNumber) return summary;
    }
    return null;
  }

  void _syncScreenWithContinuousPlayback(
    QuranMiniPlayerState? previous,
    QuranMiniPlayerState next,
  ) {
    if (!shouldReplaceQuranDetailForPlaybackSurah(
      currentScreenSurahNumber: widget.summary.number,
      previous: previous,
      next: next,
    )) {
      return;
    }

    final nextSummary = _summaryForSurahNumber(next.surahNumber);
    if (nextSummary == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuranDetailScreen(
            summary: nextSummary,
            initialAyah: next.ayahNumber,
          ),
        ),
      );
    });
  }

  bool get _hasCurrentSurahPlayback =>
      _miniPlayerState.isVisible &&
      _miniPlayerState.surahNumber == widget.summary.number;

  bool get _hasActiveSurahSessionForCurrentScreen {
    final currentSourceKey = _audioService.currentSourceKey ?? '';
    return _miniPlayerState.isVisible &&
        _miniPlayerState.playbackMode == QuranMiniPlaybackMode.surah &&
        _miniPlayerState.surahNumber == widget.summary.number &&
        currentSourceKey.startsWith(
          'quran:surah:${widget.summary.number}:',
        );
  }

  int? get _activeAyahNumber =>
      _hasCurrentSurahPlayback ? _miniPlayerState.ayahNumber : null;

  bool get _isAudioPlaying =>
      _hasCurrentSurahPlayback && _miniPlayerState.isPlaying;

  bool get _isSelectionMode => _selectedAyahs.isNotEmpty;

  bool get _canShowTafsirButton =>
      _enableQuranTafsirPanels && !_isPageView && !_isSelectionMode;

  _QuranPlaybackMode get _playbackMode {
    if (!_hasCurrentSurahPlayback) {
      return _QuranPlaybackMode.none;
    }

    switch (_miniPlayerState.playbackMode) {
      case QuranMiniPlaybackMode.none:
        return _QuranPlaybackMode.none;
      case QuranMiniPlaybackMode.ayah:
        return _QuranPlaybackMode.ayah;
      case QuranMiniPlaybackMode.surah:
        return _QuranPlaybackMode.surah;
    }
  }

  Future<void> _saveReading(int ayahNumber, {bool showFeedback = true}) async {
    await ref
        .read(quranReadingServiceProvider)
        .saveLastReading(widget.summary, ayahNumber);
    ref.invalidate(lastReadingProvider);
    if (!mounted || !showFeedback) return;
    final l10n = context.l10n;
    showQiblaSnackBar(
      context,
      message: l10n.quranReadingPointSaved(ayahNumber),
      icon: Icons.bookmark_added_rounded,
    );
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    final saved = await ref
        .read(quranReadingServiceProvider)
        .toggleBookmark(widget.summary, ayahNumber);
    ref.invalidate(quranBookmarksProvider);
    if (!mounted) return;
    final l10n = context.l10n;
    showQiblaSnackBar(
      context,
      message: saved
          ? l10n.quranBookmarkSaved(ayahNumber)
          : l10n.quranBookmarkRemoved(ayahNumber),
      icon:
          saved ? Icons.bookmark_added_rounded : Icons.bookmark_remove_rounded,
    );
  }

  Future<void> _openSelectedAyahsSharePreview(List<SurahAyah> ayahs) async {
    final selectedAyahs = ayahs
        .where((ayah) => _selectedAyahs.contains(ayah.numberInSurah))
        .toList()
      ..sort((a, b) => a.numberInSurah.compareTo(b.numberInSurah));
    if (selectedAyahs.isEmpty || !mounted) return;

    await showAyahsSharePreviewSheet(
      context: context,
      summary: widget.summary,
      ayahs: selectedAyahs,
      shareService: ref.read(ayahShareServiceProvider),
      videoService: ref.read(ayahShareVideoServiceProvider),
      tokens: QiblaThemes.current,
    );
    if (!mounted) return;
    setState(() {
      _logSelectionMode('EXITING selection mode after share');
      _selectedAyahs.clear();
    });
  }

  // ignore: unused_element
  void _toggleAyahSelection(int ayahNumber) {
    if (!_selectedAyahs.contains(ayahNumber) &&
        _selectedAyahs.length >= _maxSelectedAyahs) {
      showQiblaSnackBar(
        context,
        message: context.l10n.quranMaxAyahsSelected,
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    setState(() {
      if (_selectedAyahs.contains(ayahNumber)) {
        _selectedAyahs.remove(ayahNumber);
        return;
      }

      _selectedAyahs.add(ayahNumber);
    });
  }

  void _toggleContiguousAyahSelection(int ayahNumber) {
    final wasEmpty = _selectedAyahs.isEmpty;
    _cancelPendingListAutoScroll();

    final decision = toggleContiguousAyahSelection(
      selectedAyahs: _selectedAyahs,
      ayahNumber: ayahNumber,
      maxSelectedAyahs: _maxSelectedAyahs,
    );

    switch (decision.type) {
      case QuranAyahSelectionDecisionType.rejectNonConsecutive:
        _showConsecutiveAyahWarning();
        return;
      case QuranAyahSelectionDecisionType.rejectMaxReached:
        showQiblaSnackBar(
          context,
          message: context.l10n.quranMaxAyahsSelected,
          icon: Icons.info_outline_rounded,
        );
        return;
      case QuranAyahSelectionDecisionType.add:
      case QuranAyahSelectionDecisionType.remove:
        break;
    }

    if (wasEmpty && decision.accepted) {
      _logSelectionMode('ENTERING selection mode with ayah $ayahNumber');
    }

    setState(() {
      if (wasEmpty && decision.accepted) {
        _openTafsirAyahNumber = null;
      }
      _selectedAyahs
        ..clear()
        ..addAll(decision.selectedAyahs);
    });
  }

  void _cancelPendingListAutoScroll() {
    _listAutoScrollGeneration++;
    _lastAutoScrolledListAyahNumber = null;
    _lastObservedPlayingAyahNumber = null;
    _logScrollAttempt('cancel pending list auto-scroll');
  }

  void _showConsecutiveAyahWarning() {
    showQiblaSnackBar(
      context,
      message: context.l10n.quranConsecutiveAyahsOnly,
      icon: Icons.info_outline_rounded,
    );
  }

  // ignore: unused_element
  Future<void> _showAyahShareOptions(SurahAyah ayah) async {
    final action = await showModalBottomSheet<_AyahShareAction>(
      context: context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final tokens = QiblaThemes.current;
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  l10n.quranShareAyahTitle(ayah.numberInSurah),
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.short_text_outlined),
                title: Text(l10n.shareActionShareText),
                subtitle: Text(
                  l10n.quranShareTextSubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AyahShareAction.text),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(l10n.shareActionShareImage),
                subtitle: Text(
                  l10n.quranShareImageSubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AyahShareAction.image),
              ),
              ListTile(
                leading: const Icon(Icons.movie_outlined),
                title: Text(l10n.commonVideo),
                subtitle: Text(
                  l10n.quranShareVideoSubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AyahShareAction.video),
              ),
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: Text(l10n.commonSave),
                subtitle: Text(
                  l10n.videoSaveToGallerySubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_AyahShareAction.saveVideo),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _AyahShareAction.text:
        await ref.read(ayahShareServiceProvider).shareAyahAsText(
              widget.summary,
              ayah,
            );
        return;
      case _AyahShareAction.image:
        try {
          await ref.read(ayahShareServiceProvider).shareAyahAsImage(
                widget.summary,
                ayah,
                QiblaThemes.current,
              );
        } catch (_) {
          if (!mounted) return;
          showQiblaSnackBar(
            context,
            message: context.l10n.quranAyahImageError,
            icon: Icons.info_outline_rounded,
          );
        }
        return;
      case _AyahShareAction.video:
        final videoAction = await _chooseVideoExportAction();
        if (!mounted || videoAction == null) return;
        if (videoAction == _VideoExportAction.share) {
          await _shareAyahAsVideo(ayah);
        } else {
          await _saveAyahAsVideo(ayah);
        }
        return;
      case _AyahShareAction.saveVideo:
        await _saveAyahAsVideo(ayah);
        return;
    }
  }

  Future<_VideoExportAction?> _chooseVideoExportAction() {
    final l10n = context.l10n;
    return showModalBottomSheet<_VideoExportAction>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.ios_share_outlined),
                title: Text('${l10n.commonShare} ${l10n.commonVideo}'),
                subtitle: Text(
                  l10n.quranShareVideoSubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_VideoExportAction.share),
              ),
              ListTile(
                leading: const Icon(Icons.save_outlined),
                title: Text('${l10n.commonSave} ${l10n.commonVideo}'),
                subtitle: Text(
                  l10n.videoSaveToGallerySubtitle,
                  style: GoogleFonts.dmSans(fontSize: 12),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_VideoExportAction.save),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareAyahAsVideo(SurahAyah ayah) async {
    final videoService = ref.read(ayahShareVideoServiceProvider);
    final l10n = context.l10n;

    try {
      final draft = await videoService.prepareDraft(
        summary: widget.summary,
        ayah: ayah,
      );
      if (!mounted) return;

      if (draft == null) {
        await _showVideoExportError(
          l10n.quranAyahVideoError,
          l10n.quranAyahVideoNoAudio,
        );
        return;
      }

      final file = await videoService.exportVideo(draft);
      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: l10n.quranAyahVideoShareText(
          ayah.numberInSurah,
          widget.summary.nameLatin,
        ),
        sharePositionOrigin: qiblaShareSheetOrigin,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '_shareAyahAsVideo: FAILED ${e.runtimeType}: $e',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;

      await _showVideoExportError(l10n.quranAyahVideoError, e);
    }
  }

  Future<void> _saveAyahAsVideo(SurahAyah ayah) async {
    final videoService = ref.read(ayahShareVideoServiceProvider);
    final l10n = context.l10n;

    try {
      final draft = await videoService.prepareDraft(
        summary: widget.summary,
        ayah: ayah,
      );
      if (!mounted) return;

      if (draft == null) {
        showQiblaSnackBar(
          context,
          message: l10n.videoSaveFailed,
          icon: Icons.info_outline_rounded,
        );
        return;
      }

      final file = await videoService.exportVideo(draft);
      if (!mounted) return;

      await videoService.saveVideoToGallery(file);
      if (!mounted) return;

      showQiblaSnackBar(
        context,
        message: l10n.videoSavedToGallery,
        icon: Icons.check_circle_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      showQiblaSnackBar(
        context,
        message: l10n.videoSaveFailed,
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _showVideoExportError(String title, Object error) async {
    if (!mounted) return;

    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(error.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  Future<void> _jumpToInitialAyah(SurahDetail detail) async {
    if (_isSelectionMode) {
      _logScrollAttempt('blocked initial ayah jump');
      return;
    }
    if (widget.initialAyah <= 1) return;

    await _scrollToAyah(
      detail: detail,
      ayahNumber: widget.initialAyah,
      reason: 'initial ayah jump',
    );
  }

  Future<void> _scrollToAyah({
    required SurahDetail detail,
    required int ayahNumber,
    required String reason,
  }) async {
    if (_isSelectionMode) {
      _logScrollAttempt('blocked $reason');
      return;
    }

    final targetIndex = detail.ayahs.indexWhere(
      (ayah) => ayah.numberInSurah == ayahNumber,
    );
    if (targetIndex < 0) {
      if (!mounted) return;
      showQiblaSnackBar(
        context,
        message: 'Ayah $ayahNumber is not available in this surah.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    if (_isPageView) {
      setState(() {
        _continuousManualScrollAyahIndex = targetIndex;
        _continuousManualScrollRequestId++;
      });
      return;
    }

    if (!_itemScrollController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isSelectionMode) {
          _logScrollAttempt('blocked deferred $reason');
          return;
        }
        unawaited(
          _scrollToAyah(
            detail: detail,
            ayahNumber: ayahNumber,
            reason: reason,
          ),
        );
      });
      return;
    }

    if (_isSelectionMode) {
      _logScrollAttempt('blocked attached $reason');
      return;
    }
    _logScrollAttempt(reason);
    await _itemScrollController.scrollTo(
      index: targetIndex + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
  }

  Future<void> _submitAyahJump(SurahDetail detail) async {
    final value = int.tryParse(_ayahJumpController.text.trim());
    if (value == null || value < 1) {
      showQiblaSnackBar(
        context,
        message: 'Enter a valid ayah number.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    await _scrollToAyah(
      detail: detail,
      ayahNumber: value,
      reason: 'manual ayah jump',
    );
  }

  void _scheduleActiveAyahListScroll(int ayahNumber) {
    if (_isPageView ||
        _isSelectionMode ||
        ayahNumber <= 0 ||
        ayahNumber == _lastAutoScrolledListAyahNumber) {
      _logScrollAttempt('blocked list audio auto-scroll');
      return;
    }

    final lastUserScrollAt = _lastUserListScrollAt;
    if (lastUserScrollAt != null &&
        DateTime.now().difference(lastUserScrollAt) <
            const Duration(milliseconds: 900)) {
      _logScrollAttempt('blocked list auto-scroll after manual scroll');
      return;
    }

    final generation = _listAutoScrollGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isSelectionMode ||
          generation != _listAutoScrollGeneration ||
          !_itemScrollController.isAttached) {
        _logScrollAttempt('blocked deferred list audio auto-scroll');
        return;
      }
      if (_isAyahVisibleInList(ayahNumber)) return;

      _lastAutoScrolledListAyahNumber = ayahNumber;
      _logScrollAttempt('list audio auto-scroll');
      unawaited(
        _itemScrollController.scrollTo(
          index: ayahNumber,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          alignment: 0.18,
        ),
      );
    });
  }

  bool _isAyahVisibleInList(int ayahNumber) {
    final targetIndex = ayahNumber;
    return _itemPositionsListener.itemPositions.value.any((position) {
      return position.index == targetIndex &&
          position.itemLeadingEdge >= 0.02 &&
          position.itemTrailingEdge <= 0.98;
    });
  }

  void _logScrollAttempt(String reason) {
    if (!kDebugMode) return;
    debugPrint(
      '[QuranScroll] $reason | selectionMode=$_isSelectionMode | '
      'activeAyah=$_activeAyahNumber | pageView=$_isPageView',
    );
  }

  void _logSelectionMode(String reason) {
    if (!kDebugMode) return;
    debugPrint(
      '[QuranSelection] $reason | mode=$_isSelectionMode | '
      'selectedCount=${_selectedAyahs.length}',
    );
  }

  void _logTafsirVisibility(String reason) {
    if (!kDebugMode) return;
    if (!_loggedTafsirVisibilityReasons.add(reason)) return;
    debugPrint(
      '[QuranTafsir] $reason | flag=$_enableQuranTafsirPanels | '
      'selectionMode=$_isSelectionMode | pageView=$_isPageView | '
      'openAyah=$_openTafsirAyahNumber',
    );
  }

  void _logTafsirState({
    required bool showButton,
    required bool showPanel,
  }) {
    if (!kDebugMode) return;
    final readingMode = _isPageView ? 'continuous' : 'list';
    final key = 'state:$readingMode:$_isSelectionMode:'
        '$_enableQuranTafsirPanels:$showButton:$showPanel';
    if (!_loggedTafsirVisibilityReasons.add(key)) return;
    debugPrint('[QuranTafsir] flag=$_enableQuranTafsirPanels');
    debugPrint('[QuranTafsir] readingMode=$readingMode');
    debugPrint('[QuranTafsir] selectionMode=$_isSelectionMode');
    debugPrint('[QuranTafsir] showButton=$showButton');
    debugPrint('[QuranTafsir] showPanel=$showPanel');
  }

  void _ensureDownloadStateLoaded(SurahDetail detail) {
    if (_hasRequestedDownloadState) return;
    _hasRequestedDownloadState = true;
    unawaited(_refreshDownloadState(detail));
  }

  Future<void> _refreshDownloadState(SurahDetail detail) async {
    final service = ref.read(quranAudioDownloadServiceProvider);
    if (mounted) {
      setState(() => _isCheckingDownloadState = true);
    }

    try {
      final state = await service.getDownloadState(detail);
      final isFavorite =
          await service.isFavoriteDownloadedSurah(detail.summary.number);
      if (!mounted) return;
      setState(() {
        _downloadState = state;
        _isDownloadedFavorite = isFavorite;
        _isCheckingDownloadState = false;
        _hasRequestedDownloadState = true;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _downloadState = SurahAudioDownloadState(
          status: SurahAudioDownloadStatus.error,
          availableAyahs:
              detail.ayahs.where((ayah) => ayah.audioUrl.isNotEmpty).length,
          downloadedAyahs: 0,
          errorMessage: l10n.quranDownloadCheckError,
        );
        _isDownloadedFavorite = false;
        _isCheckingDownloadState = false;
        _hasRequestedDownloadState = true;
      });
    }
  }

  Future<void> _downloadSurahAudio(SurahDetail detail) async {
    final service = ref.read(quranAudioDownloadServiceProvider);
    final availableAyahs =
        detail.ayahs.where((ayah) => ayah.audioUrl.isNotEmpty).length;
    if (availableAyahs == 0) return;

    setState(() {
      _downloadState = SurahAudioDownloadState(
        status: SurahAudioDownloadStatus.downloading,
        availableAyahs: availableAyahs,
        downloadedAyahs: 0,
      );
      _isCheckingDownloadState = false;
    });

    try {
      await service.downloadSurahAudio(
        detail,
        onProgress: (downloadedAyahs, totalAyahs) {
          if (!mounted) return;
          setState(() {
            _downloadState = SurahAudioDownloadState(
              status: SurahAudioDownloadStatus.downloading,
              availableAyahs: totalAyahs,
              downloadedAyahs: downloadedAyahs,
            );
          });
        },
      );
      await _refreshDownloadState(detail);
      ref.invalidate(downloadedSurahNumbersProvider);
      ref.invalidate(favoriteDownloadedSurahsProvider);
      if (!mounted) return;
      showQiblaSnackBar(
        context,
        message: context.l10n.quranDownloadSuccess,
        icon: Icons.download_done_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _downloadState = (_downloadState ??
                SurahAudioDownloadState(
                  status: SurahAudioDownloadStatus.notDownloaded,
                  availableAyahs: availableAyahs,
                  downloadedAyahs: 0,
                ))
            .copyWith(
          status: SurahAudioDownloadStatus.error,
          errorMessage: l10n.quranDownloadDetailedError,
        );
      });
      showQiblaSnackBar(
        context,
        message: l10n.quranDownloadShortError,
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _showDownloadedAudioOptions(
    SurahDetail detail,
    SurahLoadSource source,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final tokens = QiblaThemes.current;
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(l10n.commonPlay),
                subtitle: Text(l10n.quranDownloadedAudioPlaySubtitle),
                onTap: () => Navigator.of(sheetContext).pop('play'),
              ),
              ListTile(
                leading:
                    Icon(Icons.cloud_off_outlined, color: tokens.textSecondary),
                title: Text(l10n.commonRemove),
                subtitle: Text(l10n.quranDownloadedAudioRemoveSubtitle),
                onTap: () => Navigator.of(sheetContext).pop('remove'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'play') {
      await _toggleSurahAudio(detail, source);
      return;
    }

    await _stopActiveAudio();
    await ref
        .read(quranAudioDownloadServiceProvider)
        .removeSurahDownload(widget.summary.number);
    await _refreshDownloadState(detail);
    ref.invalidate(downloadedSurahNumbersProvider);
    ref.invalidate(favoriteDownloadedSurahsProvider);
    if (!mounted) return;
    showQiblaSnackBar(
      context,
      message: context.l10n.quranDownloadedAudioRemoved,
      icon: Icons.delete_outline_rounded,
    );
  }

  Future<void> _toggleDownloadedFavorite() async {
    final service = ref.read(quranAudioDownloadServiceProvider);
    final isFavorite = await service.toggleDownloadedSurahFavorite(
      widget.summary.number,
    );
    ref.invalidate(favoriteDownloadedSurahsProvider);
    if (!mounted) return;
    final l10n = context.l10n;
    setState(() => _isDownloadedFavorite = isFavorite);
    showQiblaSnackBar(
      context,
      message: isFavorite
          ? l10n.quranDownloadedFavoriteAdded
          : l10n.quranDownloadedFavoriteRemoved,
      icon: isFavorite
          ? Icons.bookmark_added_rounded
          : Icons.bookmark_remove_rounded,
    );
  }

  bool _canPlayAyahAudio(SurahAyah ayah, SurahLoadSource source) {
    if (ayah.audioUrl.isEmpty) return false;
    return source != SurahLoadSource.placeholder;
  }

  bool _canPlaySurahAudio(SurahDetail detail, SurahLoadSource source) {
    if (source == SurahLoadSource.placeholder) return false;
    return detail.ayahs.any((ayah) => _canPlayAyahAudio(ayah, source));
  }

  List<SurahAyah> _surahQueueFor(
    SurahDetail detail,
    SurahLoadSource source,
  ) {
    return detail.ayahs
        .where((ayah) => _canPlayAyahAudio(ayah, source))
        .toList();
  }

  String _audioStatusLabel(SurahAyah ayah, SurahLoadSource source) {
    final l10n = context.l10n;
    if (!_canPlayAyahAudio(ayah, source)) {
      return l10n.quranAyahAudioUnavailable;
    }
    if (_downloadState?.isDownloaded == true) {
      return l10n.quranAyahAudioDownloaded;
    }
    switch (source) {
      case SurahLoadSource.online:
        return l10n.quranAyahAudioAvailable;
      case SurahLoadSource.offline:
        return l10n.quranAyahAudioRequiresConnection;
      case SurahLoadSource.placeholder:
        return l10n.quranAyahAudioUnavailable;
    }
  }

  String _surahAudioStatusLabel(
    SurahDetail detail,
    SurahLoadSource source,
  ) {
    final l10n = context.l10n;
    final availableCount = _surahQueueFor(detail, source).length;
    if (availableCount == 0) {
      return l10n.quranSurahRecitationUnavailable;
    }

    final downloadState = _downloadState;
    if (downloadState?.isDownloading == true) {
      return l10n.quranSurahAudioDownloading(
        downloadState!.downloadedAyahs,
        downloadState.availableAyahs,
      );
    }
    if (downloadState?.isDownloaded == true) {
      return l10n.quranSurahAudioDownloaded;
    }
    if (downloadState?.status == SurahAudioDownloadStatus.error) {
      return downloadState?.errorMessage ?? l10n.quranDownloadShortError;
    }

    final missingCount = detail.ayahs.length - availableCount;
    final availabilityNote = missingCount > 0
        ? ' ${l10n.quranSurahAudioMissingAyahs(missingCount)}'
        : '';

    final downloadNote = downloadState?.hasPartialDownload == true
        ? ' ${l10n.quranSurahAudioPartialDownload(downloadState!.downloadedAyahs, downloadState.availableAyahs)}'
        : ' ${l10n.quranSurahAudioDownloadAvailable}';

    switch (source) {
      case SurahLoadSource.online:
        return '${l10n.quranSurahAudioPlayOnline}$availabilityNote$downloadNote';
      case SurahLoadSource.offline:
        return '${l10n.quranSurahAudioPlayWithConnection}$availabilityNote$downloadNote';
      case SurahLoadSource.placeholder:
        return l10n.quranSurahRecitationUnavailable;
    }
  }

  Future<void> _toggleAyahAudio(
    SurahAyah ayah,
    SurahLoadSource source,
    List<SurahAyah> ayahs,
  ) async {
    if (!_canPlayAyahAudio(ayah, source)) return;

    final sourceKey = _playbackMode == _QuranPlaybackMode.surah
        ? 'quran:surah:${widget.summary.number}:${ayah.numberInSurah}'
        : 'quran:${widget.summary.number}:${ayah.numberInSurah}';
    final controller = ref.read(quranMiniPlayerControllerProvider.notifier);
    try {
      if (_activeAyahNumber == ayah.numberInSurah &&
          _audioService.currentSourceKey == sourceKey) {
        await controller.togglePlayPause();
        return;
      }

      final queue = quranAudioQueueFromAyah(
        ayahs: ayahs,
        startAyahNumber: ayah.numberInSurah,
      );
      await controller.startQuranPlaybackFromAyah(
        summary: widget.summary,
        allSurahs: QuranService.allSurahs,
        queue: queue,
        preferDownloadedAudio: _downloadState?.isDownloaded == true,
      );
    } catch (_) {
      if (!mounted) return;
      controller.clear();
      showQiblaSnackBar(
        context,
        message: context.l10n.quranAyahPlaybackError,
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _toggleSurahAudio(
    SurahDetail detail,
    SurahLoadSource source,
  ) async {
    final queue = _surahQueueFor(detail, source);
    if (queue.isEmpty) return;

    final controller = ref.read(quranMiniPlayerControllerProvider.notifier);
    try {
      if (_hasActiveSurahSessionForCurrentScreen) {
        await controller.togglePlayPause();
        return;
      }

      await controller.startSurahPlayback(
        summary: widget.summary,
        queue: queue,
        preferDownloadedAudio: _downloadState?.isDownloaded == true,
      );
    } catch (_) {
      if (!mounted) return;
      controller.clear();
      showQiblaSnackBar(
        context,
        message: context.l10n.quranSurahPlaybackError,
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _toggleActiveAudioFromIndicator() async {
    if (_activeAyahNumber == null) return;
    await ref
        .read(quranMiniPlayerControllerProvider.notifier)
        .togglePlayPause();
  }

  Future<void> _stopActiveAudio() async {
    await ref.read(quranMiniPlayerControllerProvider.notifier).stop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuranMiniPlayerState>(
      quranMiniPlayerControllerProvider,
      _syncScreenWithContinuousPlayback,
    );
    ref.watch(quranMiniPlayerControllerProvider);
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    final detailAsync = ref.watch(surahLoadResultProvider(widget.summary));
    final bookmarks = ref.watch(quranBookmarksProvider).valueOrNull ?? const [];
    final lastReading = ref.watch(lastReadingProvider).valueOrNull;
    final tafsirLanguageCode = ref.watch(currentLanguageCodeProvider);
    final wordLanguageCode =
        _enableQuranWordByWord ? ref.watch(currentLanguageCodeProvider) : 'en';
    final showTajweed =
        ref.watch(quranTajweedEnabledProvider).valueOrNull ?? false;
    final wordByWordSupported =
        supportsQuranWordByWordOnline(widget.summary.number);
    final showWordByWord = wordByWordSupported &&
        (ref.watch(quranWordByWordEnabledProvider).valueOrNull ?? false);
    final wordsByAyah = showWordByWord
        ? ref
                .watch(quranWordsForSurahProvider(widget.summary.number))
                .valueOrNull ??
            const <int, List<QuranWord>>{}
        : const <int, List<QuranWord>>{};

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(_surahPrimaryName(context, widget.summary)),
        actions: [
          _QuranReaderToggleChip(
            label: 'Tajweed',
            icon: Icons.color_lens_outlined,
            selected: showTajweed,
            tokens: tokens,
            onTap: () => _toggleTajweed(!showTajweed),
          ),
          if (wordByWordSupported) ...[
            const SizedBox(width: 6),
            _QuranWordByWordToggleButton(
              selected: showWordByWord,
              tokens: tokens,
              onTap: () => _toggleWordByWord(!showWordByWord),
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            tooltip:
                _isPageView ? l10n.quranViewModeAyahs : l10n.quranViewModePage,
            icon: Icon(
              _isPageView
                  ? Icons.view_list_outlined
                  : Icons.auto_stories_outlined,
            ),
            onPressed: _toggleViewMode,
          ),
        ],
      ),
      body: detailAsync.when(
        data: (result) {
          final detail = result.detail;
          _ensureDownloadStateLoaded(detail);
          if (!_initialReadingSaved) {
            _initialReadingSaved = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _saveReading(widget.initialAyah, showFeedback: false);
            });
          }
          if (!_initialJumpDone && widget.initialAyah > 1) {
            _initialJumpDone = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (_isSelectionMode) {
                _logScrollAttempt('blocked deferred initial jump in build');
                return;
              }
              await _jumpToInitialAyah(detail);
            });
          }

          final currentAyahIndex =
              _activeAyahNumber == null ? null : _activeAyahNumber! - 1;
          final showTafsirButton = _canShowTafsirButton;
          final showTafsirPanel =
              showTafsirButton && _openTafsirAyahNumber != null;
          _logTafsirState(
            showButton: showTafsirButton,
            showPanel: showTafsirPanel,
          );

          if (_activeAyahNumber == null) {
            _lastAutoScrolledListAyahNumber = null;
            _lastObservedPlayingAyahNumber = null;
          } else if (!_isSelectionMode &&
              _isAudioPlaying &&
              _activeAyahNumber != _lastObservedPlayingAyahNumber) {
            _lastObservedPlayingAyahNumber = _activeAyahNumber;
            _scheduleActiveAyahListScroll(_activeAyahNumber!);
          }

          final content = KeyedSubtree(
            key: ValueKey<String>(
              'quran_detail_mode_${widget.summary.number}_${_isPageView ? 'continuous' : 'cards'}_$_viewModeGeneration',
            ),
            child: _isPageView
                ? QuranContinuousView(
                    key: ValueKey<String>(
                      'quran_continuous_${widget.summary.number}_$_viewModeGeneration',
                    ),
                    tokens: tokens,
                    ayahs: detail.ayahs,
                    surahNumber: widget.summary.number,
                    currentAyahIndex: currentAyahIndex,
                    manualScrollAyahIndex: _continuousManualScrollAyahIndex,
                    manualScrollRequestId: _continuousManualScrollRequestId,
                    showTajweed: showTajweed,
                    showWordByWord: showWordByWord,
                    wordsByAyah: showWordByWord ? wordsByAyah : const {},
                    onWordTap: showWordByWord
                        ? (word) => _showQuranWordSheet(
                              word,
                              languageCode: wordLanguageCode,
                            )
                        : null,
                    enableAutoScroll: !_isSelectionMode,
                    header: Column(
                      children: [
                        _buildTopBanner(
                          tokens,
                          result.source,
                          widget.initialAyah,
                        ),
                        _buildSurahAudioCard(tokens, detail, result.source),
                        _buildAyahJumpCard(tokens, detail),
                        if (_activeAyahNumber != null)
                          _buildActiveAudioIndicator(tokens),
                      ],
                    ),
                  )
                : NotificationListener<UserScrollNotification>(
                    key: ValueKey<String>(
                      'quran_cards_${widget.summary.number}_$_viewModeGeneration',
                    ),
                    onNotification: (notification) {
                      _lastUserListScrollAt = DateTime.now();
                      return false;
                    },
                    child: ScrollablePositionedList.builder(
                      key: PageStorageKey<String>(
                        'quran_ayah_list_${widget.summary.number}_$_viewModeGeneration',
                      ),
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      padding: const EdgeInsets.all(16),
                      itemCount: detail.ayahs.length + 1,
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return Column(
                            children: [
                              _buildTopBanner(
                                tokens,
                                result.source,
                                widget.initialAyah,
                              ),
                              _buildSurahAudioCard(
                                  tokens, detail, result.source),
                              _buildAyahJumpCard(tokens, detail),
                              if (_activeAyahNumber != null)
                                _buildActiveAudioIndicator(tokens),
                            ],
                          );
                        }

                        final ayah = detail.ayahs[index - 1];
                        final canPlayAudio =
                            _canPlayAyahAudio(ayah, result.source);
                        final isLastRead =
                            lastReading?.surahNumber == widget.summary.number &&
                                lastReading?.ayahNumber == ayah.numberInSurah;
                        final isActiveAudio =
                            _activeAyahNumber == ayah.numberInSurah;
                        final isPlayingAudio = isActiveAudio && _isAudioPlaying;
                        final isSelected =
                            _selectedAyahs.contains(ayah.numberInSurah);
                        final isBookmarked = bookmarks.any(
                          (bookmark) =>
                              bookmark.surahNumber == widget.summary.number &&
                              bookmark.ayahNumber == ayah.numberInSurah,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: () => _isSelectionMode
                                  ? _toggleContiguousAyahSelection(
                                      ayah.numberInSurah,
                                    )
                                  : _saveReading(ayah.numberInSurah),
                              onLongPress: () => _toggleContiguousAyahSelection(
                                ayah.numberInSurah,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: QuranAyahCard(
                                tokens: tokens,
                                l10n: l10n,
                                ayah: ayah,
                                surahNumber: widget.summary.number,
                                canPlayAudio: canPlayAudio,
                                isLastRead: isLastRead,
                                isActiveAudio: isActiveAudio,
                                isPlayingAudio: isPlayingAudio,
                                isBookmarked: isBookmarked,
                                isSelected: isSelected,
                                isSelectionMode: _isSelectionMode,
                                showTajweed: showTajweed,
                                showWordByWord: showWordByWord,
                                audioStatusLabel: _audioStatusLabel(
                                  ayah,
                                  result.source,
                                ),
                                onToggleAudio: () => _toggleAyahAudio(
                                  ayah,
                                  result.source,
                                  detail.ayahs,
                                ),
                                onToggleBookmark: () =>
                                    _toggleBookmark(ayah.numberInSurah),
                                showTafsirAction: showTafsirButton,
                                isTafsirOpen:
                                    _openTafsirAyahNumber == ayah.numberInSurah,
                                onToggleTafsir: () =>
                                    _toggleTafsirForAyah(ayah.numberInSurah),
                                words: showWordByWord
                                    ? wordsByAyah[ayah.numberInSurah] ??
                                        const []
                                    : const [],
                                onWordTap: showWordByWord
                                    ? (word) => _showQuranWordSheet(
                                          word,
                                          languageCode: wordLanguageCode,
                                        )
                                    : null,
                              ),
                            ),
                            if (showTafsirButton &&
                                _openTafsirAyahNumber == ayah.numberInSurah)
                              _TafsirPanelLoader(
                                surahNumber: widget.summary.number,
                                ayahNumber: ayah.numberInSurah,
                                languageCode: tafsirLanguageCode,
                                localeCode:
                                    Localizations.localeOf(context).toString(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          );

          if (!_enableQuranTafsirPanels) {
            _logTafsirVisibility('hidden: feature flag off');
          } else if (_isPageView) {
            _logTafsirVisibility('hidden: page mode incompatible');
          } else if (_isSelectionMode) {
            _logTafsirVisibility('hidden: selection mode active');
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (_isSelectionMode)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: _buildMultiSelectionToolbar(tokens, detail.ayahs),
                  ),
                ),
              if (_miniPlayerState.isVisible && !_isSelectionMode)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: _buildFloatingAudioControl(tokens),
                  ),
                ),
            ],
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: tokens.primary)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.quranDetailLoadError,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: tokens.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectionToolbar(
    QiblaTokens tokens,
    List<SurahAyah> ayahs,
  ) {
    final l10n = context.l10n;
    final selectedCount = _selectedAyahs.length;
    final isCompactWidth = MediaQuery.sizeOf(context).width < 380;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final useCompactActions = isCompactWidth || textScale > 1.15;
    final shareAction = _selectedAyahs.isEmpty
        ? null
        : () => _openSelectedAyahsSharePreview(ayahs);

    void cancelSelection() {
      setState(() {
        _logSelectionMode('EXITING selection mode via cancel button');
        _selectedAyahs.clear();
      });
    }

    return Material(
      elevation: 5,
      color: tokens.bgSurface,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          border: Border(
            bottom: BorderSide(color: tokens.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: tokens.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.quranAyahsSelectedCount(selectedCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: l10n.commonShare,
              child: useCompactActions
                  ? FilledButton(
                      onPressed: shareAction,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(40, 38),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Icon(Icons.ios_share_outlined, size: 18),
                    )
                  : FilledButton.icon(
                      onPressed: shareAction,
                      icon: const Icon(Icons.ios_share_outlined, size: 17),
                      label: Text(
                        l10n.commonShare,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.commonCancel,
              onPressed: cancelSelection,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: tokens.textSecondary,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAudioControl(QiblaTokens tokens) {
    final state = _miniPlayerState;
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Color.lerp(tokens.bgSurface, tokens.bgSurface2, 0.75),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.primaryBorder),
          boxShadow: [
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip:
                  state.isPlaying ? 'Pause recitation' : 'Resume recitation',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              onPressed: _toggleActiveAudioFromIndicator,
              icon: Icon(
                state.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: tokens.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 116),
              child: Text(
                '${state.surahName} · ${state.ayahNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(
    QiblaTokens tokens,
    SurahLoadSource source,
    int initialAyah,
  ) {
    final l10n = context.l10n;
    final hasResume = initialAyah > 1;
    final textParts = <String>[];
    if (hasResume) {
      textParts.add(l10n.quranTopBannerResume(initialAyah));
    }
    final sourceMessage = switch (source) {
      SurahLoadSource.online => l10n.quranTopBannerOnline,
      SurahLoadSource.offline => l10n.quranTopBannerOffline,
      SurahLoadSource.placeholder => l10n.quranTopBannerPlaceholder,
    };
    textParts.add(sourceMessage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: tokens.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              textParts.join(' '),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahAudioCard(
    QiblaTokens tokens,
    SurahDetail detail,
    SurahLoadSource source,
  ) {
    final l10n = context.l10n;
    final canPlaySurah = _canPlaySurahAudio(detail, source);
    final availableAyahs = _surahQueueFor(detail, source).length;
    final isSurahPlayback = _hasActiveSurahSessionForCurrentScreen;
    final downloadState = _downloadState;
    final isDownloading = downloadState?.isDownloading == true;
    final isDownloaded = downloadState?.isDownloaded == true;
    final canDownload = availableAyahs > 0;
    final isCheckingDownloadState =
        _isCheckingDownloadState && downloadState == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSurahPlayback ? tokens.primaryBorder : tokens.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_arrow, color: tokens.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.quranSurahAudioCardTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Text(
                l10n.quranAvailableAyahs(availableAyahs, detail.ayahs.length),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _surahAudioStatusLabel(detail, source),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              height: 1.5,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: canPlaySurah
                    ? () => _toggleSurahAudio(detail, source)
                    : null,
                icon: Icon(
                  isSurahPlayback && _isAudioPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                label: Text(
                  isSurahPlayback
                      ? (_isAudioPlaying
                          ? l10n.quranPauseSurah
                          : l10n.quranResumeSurah)
                      : l10n.quranListenSurah,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _activeAyahNumber != null ? _stopActiveAudio : null,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l10n.quranStop),
              ),
              OutlinedButton.icon(
                onPressed: !canDownload
                    ? null
                    : isCheckingDownloadState
                        ? null
                        : isDownloading
                            ? null
                            : isDownloaded
                                ? () =>
                                    _showDownloadedAudioOptions(detail, source)
                                : () => _downloadSurahAudio(detail),
                icon: Icon(
                  !canDownload
                      ? Icons.volume_off_outlined
                      : isCheckingDownloadState
                          ? Icons.cloud_queue_outlined
                          : isDownloading
                              ? Icons.downloading_outlined
                              : isDownloaded
                                  ? Icons.download_done_outlined
                                  : Icons.download_outlined,
                ),
                label: Text(
                  !canDownload
                      ? l10n.quranAudioUnavailable
                      : isCheckingDownloadState
                          ? l10n.quranCheckingAudio
                          : isDownloading
                              ? l10n.quranDownloadingProgress(
                                  downloadState?.downloadedAyahs ?? 0,
                                  downloadState?.availableAyahs ??
                                      availableAyahs,
                                )
                              : isDownloaded
                                  ? l10n.quranDownloaded
                                  : l10n.quranDownloadAudio,
                ),
              ),
              if (isDownloaded)
                OutlinedButton.icon(
                  onPressed: _toggleDownloadedFavorite,
                  icon: Icon(
                    _isDownloadedFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                  label: Text(
                    _isDownloadedFavorite
                        ? l10n.quranDownloadedFavoriteLabel
                        : l10n.quranMarkFavorite,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAudioIndicator(QiblaTokens tokens) {
    final l10n = context.l10n;
    final ayahNumber = _activeAyahNumber;
    if (ayahNumber == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(
            _isAudioPlaying
                ? Icons.volume_up_outlined
                : Icons.pause_circle_outline,
            color: tokens.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _playbackMode == _QuranPlaybackMode.surah
                      ? (_isAudioPlaying
                          ? l10n.quranPlayingSurahAyah(ayahNumber)
                          : l10n.quranPausedSurahAyah(ayahNumber))
                      : (_isAudioPlaying
                          ? l10n.quranPlayingAyah(ayahNumber)
                          : l10n.quranPausedAyah(ayahNumber)),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _playbackMode == _QuranPlaybackMode.surah
                      ? l10n.quranActiveAudioSurahHint
                      : l10n.quranActiveAudioAyahHint,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip:
                _isAudioPlaying ? l10n.quranPauseAudio : l10n.quranResumeAudio,
            onPressed: _toggleActiveAudioFromIndicator,
            icon: Icon(
              _isAudioPlaying
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
              color: tokens.primary,
            ),
          ),
          IconButton(
            tooltip: l10n.quranStopAudio,
            onPressed: _stopActiveAudio,
            icon: Icon(
              Icons.stop_circle_outlined,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahJumpCard(QiblaTokens tokens, SurahDetail detail) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Icon(Icons.pin_drop_outlined, size: 18, color: tokens.primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ayahJumpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _submitAyahJump(detail),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: tokens.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.quranGoToAyah,
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: tokens.textMuted,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _submitAyahJump(detail),
            child: Text(l10n.quranGoToAyah),
          ),
        ],
      ),
    );
  }

  Future<void> _showQuranWordSheet(
    QuranWord word, {
    required String languageCode,
  }) async {
    final tokens = QiblaThemes.current;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        final translation = word.translationFor(languageCode);
        final translationLanguageCode = word.translationLanguageFor(
          languageCode,
        );
        final translationLanguageLabel = _quranWordTranslationLanguageLabel(
          translationLanguageCode,
          appLanguageCode: languageCode,
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  word.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: tokens.arabicTextStyle(fontSize: 30, height: 1.5),
                ),
                if (word.transliteration.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    word.transliteration,
                    textAlign: TextAlign.center,
                    style: tokens.transliterationTextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
                if (translation.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    translation,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      height: 1.45,
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (translationLanguageLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    translationLanguageLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      height: 1.35,
                      color: tokens.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  '${word.surahNumber}:${word.ayahNumber} · word ${word.position}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String? _quranWordTranslationLanguageLabel(
  String? translationLanguageCode, {
  required String appLanguageCode,
}) {
  if (translationLanguageCode == null || translationLanguageCode.isEmpty) {
    return null;
  }
  final appLanguage = appLanguageCode.trim().toLowerCase().split('_').first;
  final languageName = _quranWordLanguageName(
    translationLanguageCode,
    appLanguageCode: appLanguage,
  );
  if (appLanguage == 'es') {
    return 'Traducción palabra por palabra: $languageName';
  }
  return 'Word-by-Word translation: $languageName';
}

String _quranWordLanguageName(
  String languageCode, {
  required String appLanguageCode,
}) {
  final code = languageCode.trim().toLowerCase().split('_').first;
  if (appLanguageCode == 'es') {
    return switch (code) {
      'en' => 'inglés',
      'tr' => 'turco',
      'id' => 'indonesio',
      'ur' => 'urdu',
      'es' => 'español',
      _ => code.toUpperCase(),
    };
  }
  return switch (code) {
    'en' => 'English',
    'tr' => 'Turkish',
    'id' => 'Indonesian',
    'ur' => 'Urdu',
    'es' => 'Spanish',
    _ => code.toUpperCase(),
  };
}

class _TafsirPanelLoader extends ConsumerWidget {
  const _TafsirPanelLoader({
    required this.surahNumber,
    required this.ayahNumber,
    required this.languageCode,
    required this.localeCode,
  });

  final int surahNumber;
  final int ayahNumber;
  final String languageCode;
  final String localeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.info(
      '[QuranTafsirPanel] open locale=$localeCode '
      'tafsirLanguage=$languageCode ayah=$surahNumber:$ayahNumber',
    );
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2, bottom: 12),
      child: TafsirPanel(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        languageCode: languageCode,
      ),
    );
  }
}

class _QuranReaderToggleChip extends StatelessWidget {
  const _QuranReaderToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final QiblaTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? tokens.primaryLight : tokens.textSecondary;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 9),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? tokens.primaryBg : tokens.bgSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tokens.primaryBorder : tokens.borderMed,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranWordByWordToggleButton extends StatelessWidget {
  const _QuranWordByWordToggleButton({
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  final bool selected;
  final QiblaTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? tokens.primaryLight : tokens.textSecondary;
    return Tooltip(
      message: 'Word by Word',
      child: Semantics(
        button: true,
        toggled: selected,
        label: 'Word by Word',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? tokens.primaryBg : tokens.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? tokens.primaryBorder : tokens.borderMed,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                'A|أ',
                maxLines: 1,
                style: GoogleFonts.dmSans(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _surahPrimaryName(BuildContext context, SurahSummary surah) {
  return Localizations.localeOf(context).languageCode == 'ar'
      ? surah.nameArabic
      : surah.nameLatin;
}

String _readingPointLabel(BuildContext context, QuranReadingPoint point) {
  if (Localizations.localeOf(context).languageCode == 'ar') {
    return '${point.surahNameArabic} · الآية ${point.ayahNumber}';
  }

  return point.shortLabel;
}
