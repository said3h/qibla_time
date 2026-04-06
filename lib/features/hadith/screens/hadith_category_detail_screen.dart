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

class HadithCategoryDetailScreen extends ConsumerStatefulWidget {
  const HadithCategoryDetailScreen({
    super.key,
    required this.categoryKey,
    required this.categoryLabel,
    required this.categoryArabicLabel,
    required this.hadiths,
  });

  final String categoryKey;
  final String categoryLabel;
  final String categoryArabicLabel;
  final List<Hadith> hadiths;

  @override
  ConsumerState<HadithCategoryDetailScreen> createState() =>
      _HadithCategoryDetailScreenState();
}

class _HadithCategoryDetailScreenState
    extends ConsumerState<HadithCategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _headerOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );
    _headerOffset = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    );
    _contentOffset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(int hadithId) async {
    await ref.read(hadithServiceProvider).toggleFavorite(hadithId);
    ref.invalidate(hadithFavoritesProvider);
  }

  Future<void> _shareImage(Hadith hadith) {
    return showHadithSharePreviewSheet(
      context: context,
      hadith: hadith,
      shareService: ref.read(hadithShareServiceProvider),
      tokens: QiblaThemes.current,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final favorites =
        ref.watch(hadithFavoritesProvider).valueOrNull ?? const <int>{};
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabicOnly = languageCode == 'ar';
    final showArabicSubtitle =
        widget.categoryArabicLabel.isNotEmpty &&
        widget.categoryArabicLabel != widget.categoryLabel;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _headerOpacity,
              child: SlideTransition(
                position: _headerOffset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: tokens.textPrimary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.categoryLabel,
                        textAlign: TextAlign.center,
                        style: isArabicOnly
                            ? GoogleFonts.amiri(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: tokens.primary,
                                height: 1.2,
                              )
                            : GoogleFonts.dmSerifDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                color: tokens.primary,
                                height: 1.2,
                              ),
                      ),
                    ),
                    if (showArabicSubtitle) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              widget.categoryArabicLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: 18,
                                height: 1.6,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.hadithLibraryAllHadiths(widget.hadiths.length),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: tokens.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _contentOpacity,
                child: SlideTransition(
                  position: _contentOffset,
                  child: widget.hadiths.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_stories_outlined,
                                  size: 48,
                                  color: tokens.textMuted,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.l10n.hadithLibraryEmptyTitle,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: widget.hadiths.length,
                          itemBuilder: (context, index) {
                            final hadith = widget.hadiths[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CategoryHadithCard(
                                hadith: hadith,
                                isArabicOnly: isArabicOnly,
                                isFavorite: favorites.contains(hadith.id),
                                onToggleFavorite: () =>
                                    _toggleFavorite(hadith.id),
                                onShare: () => _shareImage(hadith),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHadithCard extends StatelessWidget {
  const _CategoryHadithCard({
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
                    color: _getGradeColor(hadith.grade).withOpacity(0.1),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onShare,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.bgSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: tokens.textPrimary,
                        ),
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
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.red : tokens.textPrimary,
                  ),
                  label: Text(
                    isFavorite
                        ? context.l10n.commonSaved
                        : context.l10n.commonSave,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.textPrimary,
                  ),
                ),
              ],
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
