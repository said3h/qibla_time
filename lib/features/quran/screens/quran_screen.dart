import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../hafiz/screens/hafiz_mode_screen.dart';
import '../../quran_share/services/ayah_share_service.dart';
import '../../quran_share/services/ayah_share_video_service.dart';
import '../../quran_share/widgets/ayah_share_preview_sheet.dart';
import '../models/quran_models.dart';
import 'allah_names_screen.dart';
import '../services/quran_audio_download_service.dart';
import '../services/quran_mini_player_service.dart';
import '../services/quran_reading_service.dart';
import '../services/quran_service.dart';
import 'downloaded_surahs_screen.dart';

class QuranScreen extends ConsumerWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surah = surahs[index];
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

  SurahSummary _summaryFor(List<SurahSummary> surahs, int surahNumber) {
    return surahs.firstWhere(
      (surah) => surah.number == surahNumber,
      orElse: () => surahs.first,
    );
  }
}

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

class _QuranDetailScreenState extends ConsumerState<QuranDetailScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final AudioService _audioService = AudioService.instance;
  bool _initialJumpDone = false;
  bool _initialReadingSaved = false;
  SurahAudioDownloadState? _downloadState;
  bool _isCheckingDownloadState = true;
  bool _hasRequestedDownloadState = false;
  bool _isDownloadedFavorite = false;

  QuranMiniPlayerState get _miniPlayerState =>
      ref.read(quranMiniPlayerControllerProvider);

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.quranReadingPointSaved(ayahNumber)),
      ),
    );
  }

  Future<void> _toggleBookmark(int ayahNumber) async {
    final saved = await ref
        .read(quranReadingServiceProvider)
        .toggleBookmark(widget.summary, ayahNumber);
    ref.invalidate(quranBookmarksProvider);
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? l10n.quranBookmarkSaved(ayahNumber)
              : l10n.quranBookmarkRemoved(ayahNumber),
        ),
      ),
    );
  }

  Future<void> _openAyahSharePreview(SurahAyah ayah) async {
    await showAyahSharePreviewSheet(
      context: context,
      summary: widget.summary,
      ayah: ayah,
      shareService: ref.read(ayahShareServiceProvider),
      videoService: ref.read(ayahShareVideoServiceProvider),
      tokens: QiblaThemes.current,
    );
  }

  Future<void> _showAyahShareOptions(SurahAyah ayah) async {
    final action = await showModalBottomSheet<_AyahShareAction>(
      context: context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final tokens = QiblaThemes.current;
        return SafeArea(
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.quranAyahImageError,
              ),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.videoSaveFailed),
          ),
        );
        return;
      }

      final file = await videoService.exportVideo(draft);
      if (!mounted) return;

      await videoService.saveVideoToGallery(file);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.videoSavedToGallery),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.videoSaveFailed),
        ),
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
    if (widget.initialAyah <= 1) return;

    final targetIndex = detail.ayahs.indexWhere(
      (ayah) => ayah.numberInSurah == widget.initialAyah,
    );
    if (targetIndex < 0) return;

    if (!_itemScrollController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_jumpToInitialAyah(detail));
      });
      return;
    }

    await _itemScrollController.scrollTo(
      index: targetIndex + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.quranDownloadSuccess),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.quranDownloadShortError,
          ),
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.quranDownloadedAudioRemoved),
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? l10n.quranDownloadedFavoriteAdded
              : l10n.quranDownloadedFavoriteRemoved,
        ),
      ),
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
  ) async {
    if (!_canPlayAyahAudio(ayah, source)) return;

    final sourceKey = 'quran:${widget.summary.number}:${ayah.numberInSurah}';
    final controller = ref.read(quranMiniPlayerControllerProvider.notifier);
    try {
      if (_activeAyahNumber == ayah.numberInSurah &&
          _audioService.currentSourceKey == sourceKey) {
        await controller.togglePlayPause();
        return;
      }

      await controller.playAyah(
        summary: widget.summary,
        ayah: ayah,
      );
    } catch (_) {
      if (!mounted) return;
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.quranAyahPlaybackError,
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.quranSurahPlaybackError,
          ),
        ),
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
    ref.watch(quranMiniPlayerControllerProvider);
    final l10n = context.l10n;
    final tokens = QiblaThemes.current;
    final detailAsync = ref.watch(surahLoadResultProvider(widget.summary));
    final bookmarks = ref.watch(quranBookmarksProvider).valueOrNull ?? const [];
    final lastReading = ref.watch(lastReadingProvider).valueOrNull;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text(_surahPrimaryName(context, widget.summary)),
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
              await _jumpToInitialAyah(detail);
            });
          }

          return ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: detail.ayahs.length + 1,
            itemBuilder: (_, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildTopBanner(tokens, result.source, widget.initialAyah),
                    _buildSurahAudioCard(tokens, detail, result.source),
                    if (_activeAyahNumber != null)
                      _buildActiveAudioIndicator(tokens),
                  ],
                );
              }

              final ayah = detail.ayahs[index - 1];
              final canPlayAudio = _canPlayAyahAudio(ayah, result.source);
              final isLastRead =
                  lastReading?.surahNumber == widget.summary.number &&
                      lastReading?.ayahNumber == ayah.numberInSurah;
              final isActiveAudio = _activeAyahNumber == ayah.numberInSurah;
              final isPlayingAudio = isActiveAudio && _isAudioPlaying;
              final isBookmarked = bookmarks.any(
                (bookmark) =>
                    bookmark.surahNumber == widget.summary.number &&
                    bookmark.ayahNumber == ayah.numberInSurah,
              );

              return InkWell(
                onTap: () => _saveReading(ayah.numberInSurah),
                onLongPress: () => _openAyahSharePreview(ayah),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPlayingAudio
                        ? tokens.primaryBg
                        : isActiveAudio
                            ? tokens.activeBg
                            : isLastRead
                                ? tokens.activeBg
                                : tokens.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPlayingAudio
                          ? tokens.primaryBorder
                          : isActiveAudio || isLastRead
                              ? tokens.activeBorder
                              : tokens.border,
                    ),
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
                            child: Text(
                              '${ayah.numberInSurah}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isLastRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.primaryBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: tokens.primaryBorder),
                              ),
                              child: Text(
                                l10n.quranLastReadingBadge,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: tokens.primaryLight,
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: canPlayAudio
                                ? (isPlayingAudio
                                    ? l10n.quranPauseAudio
                                    : isActiveAudio
                                        ? l10n.quranResumeAudio
                                        : l10n.quranPlayAudio)
                                : l10n.quranAudioUnavailable,
                            onPressed: canPlayAudio
                                ? () => _toggleAyahAudio(ayah, result.source)
                                : null,
                            icon: Icon(
                              !canPlayAudio
                                  ? Icons.volume_off_outlined
                                  : isPlayingAudio
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                              color: !canPlayAudio
                                  ? tokens.textMuted
                                  : tokens.primary,
                            ),
                          ),
                          IconButton(
                            tooltip: isBookmarked
                                ? l10n.quranRemoveBookmark
                                : l10n.quranSaveBookmark,
                            onPressed: () =>
                                _toggleBookmark(ayah.numberInSurah),
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? tokens.primary
                                  : tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ayah.arabic,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          height: 1.8,
                          color: tokens.textPrimary,
                        ),
                      ),
                      if (ayah.transliteration.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          ayah.transliteration,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.7,
                            fontStyle: FontStyle.italic,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                      if (ayah.translation.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          ayah.translation,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            height: 1.7,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        l10n.quranAyahFooterHint(
                          _audioStatusLabel(ayah, result.source),
                        ),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
              Icon(Icons.queue_music, color: tokens.primary, size: 18),
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
