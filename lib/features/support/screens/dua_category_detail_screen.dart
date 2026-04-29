import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/religious_reference_formatter.dart';
import '../models/dua_model.dart';
import '../services/dua_service.dart';
import '../utils/dua_locale_presentation.dart';
import '../utils/dua_share_helper.dart';

class DuaCategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryKey;
  final String categoryLabel;
  final String categoryArabicLabel;

  const DuaCategoryDetailScreen({
    super.key,
    required this.categoryKey,
    required this.categoryLabel,
    required this.categoryArabicLabel,
  });

  @override
  ConsumerState<DuaCategoryDetailScreen> createState() =>
      _DuaCategoryDetailScreenState();
}

class _DuaCategoryDetailScreenState
    extends ConsumerState<DuaCategoryDetailScreen>
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

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final languageCode = ref.watch(currentLanguageCodeProvider);
    final duasAsync = ref.watch(allDuasProvider);
    final categoryMeta = DuaLocalePresentation.categoryMetaFor(
      widget.categoryKey,
      languageCode,
    );
    final showArabicSubtitle = categoryMeta.arabicLabel != categoryMeta.label;

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
                        categoryMeta.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSerifDisplay(
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
                              categoryMeta.arabicLabel,
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
                  child: duasAsync.when(
                    data: (duas) {
                      final categoryDuas = duas
                          .where((d) => d.category == widget.categoryKey)
                          .toList();

                      if (categoryDuas.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  size: 48,
                                  color: tokens.textMuted,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  DuaLocalePresentation.emptyCategory(
                                    languageCode,
                                  ),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: categoryDuas.length,
                        itemBuilder: (context, index) {
                          final dua = categoryDuas[index];
                          return _DuaCard(
                            dua: dua,
                            languageCode: languageCode,
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
                          DuaLocalePresentation.detailLoadError(languageCode),
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
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

class _DuaCard extends StatelessWidget {
  const _DuaCard({
    required this.dua,
    required this.languageCode,
  });

  final Dua dua;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final arabicReference = (dua.reference ?? '').isEmpty
        ? null
        : ReligiousReferenceFormatter.buildArabicReference(dua.reference!);
    final isArabicOnly = DuaLocalePresentation.isArabicOnly(languageCode);
    final showSource = !isArabicOnly && (dua.source ?? '').isNotEmpty;
    final primaryReference = isArabicOnly ? arabicReference : dua.reference;
    final showReference = (primaryReference ?? '').isNotEmpty;
    final hasArabicTitle = DuaLocalePresentation.containsArabicText(dua.title);
    final showTitle = !isArabicOnly || hasArabicTitle;
    final hasTransliteration =
        !isArabicOnly && dua.transliteration.trim().isNotEmpty;
    final hasTranslation = !isArabicOnly && dua.translation.trim().isNotEmpty;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTitle)
                      Text(
                        isArabicOnly ? dua.title : dua.title.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: tokens.primary,
                          letterSpacing: isArabicOnly ? 0 : 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (showSource || showReference) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (showSource) ...[
                            Flexible(
                              child: Text(
                                dua.source!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: tokens.primary.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (showReference)
                              Text(
                                ' · ',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: tokens.textMuted,
                                ),
                              ),
                          ],
                          if (showReference)
                            Flexible(
                              child: Text(
                                primaryReference!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (!isArabicOnly && arabicReference != null) ...[
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            arabicReference,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tokens.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dua.arabicText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: 19,
              color: tokens.textPrimary,
              height: 1.9,
            ),
          ),
          if (hasTransliteration) ...[
            const SizedBox(height: 8),
            Text(
              dua.transliteration,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: tokens.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
          if (hasTranslation) ...[
            const SizedBox(height: 8),
            Text(
              dua.translation,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: tokens.textPrimary,
                height: 1.7,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (dua.count != null && dua.count! > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.primaryBorder),
                  ),
                  child: Text(
                    DuaLocalePresentation.repeatCountLabel(
                      languageCode,
                      dua.count!,
                    ),
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: tokens.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Icon(
                  dua.isFeatured
                      ? Icons.favorite_rounded
                      : Icons.bookmark_border_rounded,
                  size: 18,
                  color: dua.isFeatured ? tokens.primary : tokens.textMuted,
                ),
              const Spacer(),
              IconButton(
                tooltip: DuaLocalePresentation.shareTooltip(languageCode),
                onPressed: () => shareDua(context, dua),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                icon: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
