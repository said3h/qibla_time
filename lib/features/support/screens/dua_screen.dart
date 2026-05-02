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
import 'dua_category_detail_screen.dart';

class DuasScreen extends ConsumerStatefulWidget {
  const DuasScreen({super.key});

  @override
  ConsumerState<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends ConsumerState<DuasScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  static const _categoryOrder = [
    'morning',
    'night',
    'sleep',
    'wudu',
    'after_prayer',
    'zikr',
    'travel',
    'food',
    'sickness',
    'protection',
    'repentance',
    'mosque',
    'rain',
    'stress',
    'gratitude',
    'parents',
    'hajj',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final languageCode = ref.watch(currentLanguageCodeProvider);
    final duasAsync = ref.watch(allDuasProvider);

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: duasAsync.when(
          data: (duas) => _buildLoadedState(
            context,
            tokens,
            duas,
            languageCode,
          ),
          loading: () => Center(
            child: CircularProgressIndicator(color: tokens.primary),
          ),
          error: (_, __) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                DuaLocalePresentation.screenTitle(languageCode),
                style: GoogleFonts.amiri(
                  fontSize: 26,
                  color: tokens.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DuaLocalePresentation.screenSubtitle(languageCode),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  DuaLocalePresentation.loadError(languageCode),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    QiblaTokens tokens,
    List<Dua> duas,
    String languageCode,
  ) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleDuas = normalizedQuery.isEmpty
        ? duas
        : duas.where((dua) => _matchesSearch(dua, normalizedQuery)).toList();
    final grouped = <String, List<Dua>>{};
    for (final dua in visibleDuas) {
      grouped.putIfAbsent(dua.category, () => <Dua>[]).add(dua);
    }

    final categoryKeys = _categoryOrder
        .where(grouped.containsKey)
        .followedBy(grouped.keys.where((key) => !_categoryOrder.contains(key)))
        .toList();

    final featured = duas.where((dua) => dua.isFeatured).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          DuaLocalePresentation.screenTitle(languageCode),
          style: GoogleFonts.amiri(
            fontSize: 26,
            color: tokens.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          DuaLocalePresentation.screenSubtitle(languageCode),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.primaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.primaryBorder),
          ),
          child: Text(
            DuaLocalePresentation.introBody(languageCode),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.6,
              color: tokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: tokens.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: DuaLocalePresentation.searchHint(languageCode),
            hintStyle: GoogleFonts.dmSans(
              fontSize: 13,
              color: tokens.textMuted,
            ),
            prefixIcon:
                Icon(Icons.search, color: tokens.textSecondary, size: 20),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip:
                        DuaLocalePresentation.clearSearchTooltip(languageCode),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: Icon(
                      Icons.close,
                      color: tokens.textSecondary,
                      size: 18,
                    ),
                  ),
            filled: true,
            fillColor: tokens.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: tokens.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: tokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: tokens.primaryBorder),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (normalizedQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: tokens.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      DuaLocalePresentation.resultsMessage(
                        languageCode,
                        _searchQuery,
                        visibleDuas.length,
                      ),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (visibleDuas.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.bgSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DuaLocalePresentation.noResultsTitle(languageCode),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DuaLocalePresentation.noResultsBody(languageCode),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    height: 1.6,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Text(
            DuaLocalePresentation.categoriesLabel(languageCode),
            style: GoogleFonts.dmSans(
              fontSize: 9,
              letterSpacing: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryKeys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (_, index) {
              final key = categoryKeys[index];
              final meta = DuaLocalePresentation.categoryMetaFor(
                key,
                languageCode,
              );
              final count = grouped[key]?.length ?? 0;
              final isArabicOnly =
                  DuaLocalePresentation.isArabicOnly(languageCode);
              final showArabicLabel = meta.arabicLabel != meta.label;

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DuaCategoryDetailScreen(
                        categoryKey: key,
                        categoryLabel: meta.label,
                        categoryArabicLabel: meta.arabicLabel,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Row(
                    children: [
                      Icon(meta.icon, size: 22, color: tokens.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              meta.label,
                              style: isArabicOnly
                                  ? GoogleFonts.amiri(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    )
                                  : GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: tokens.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                            ),
                            if (showArabicLabel)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  meta.arabicLabel,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.amiri(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ),
                            Text(
                              DuaLocalePresentation.categoryCountLabel(
                                languageCode,
                                count,
                                meta.hint,
                              ),
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (normalizedQuery.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              DuaLocalePresentation.featuredLabel(languageCode),
              style: GoogleFonts.dmSans(
                fontSize: 9,
                letterSpacing: 1.4,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ...featured.take(6).map(
                  (dua) => _DuaCard(
                    dua: dua,
                    compact: true,
                    languageCode: languageCode,
                  ),
                ),
          ],
        ],
      ],
    );
  }

  bool _matchesSearch(Dua dua, String query) {
    final tagString = dua.tags?.join(' ') ?? '';
    return [
      dua.title,
      dua.arabicText,
      dua.transliteration,
      dua.translation,
      dua.category,
      dua.reference ?? '',
      tagString,
    ].any((field) => field.toLowerCase().contains(query));
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({
    required this.dua,
    required this.languageCode,
    this.compact = false,
  });

  final Dua dua;
  final String languageCode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final meta = DuaLocalePresentation.categoryMetaFor(
      dua.category,
      languageCode,
    );
    final arabicReference = (dua.reference ?? '').isEmpty
        ? null
        : ReligiousReferenceFormatter.buildArabicReference(dua.reference!);
    final isArabicOnly = DuaLocalePresentation.isArabicOnly(languageCode);
    final primaryReference = isArabicOnly ? arabicReference : dua.reference;
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
                    if ((primaryReference ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              primaryReference!,
                              textAlign: isArabicOnly
                                  ? TextAlign.right
                                  : TextAlign.left,
                              textDirection: isArabicOnly
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ),
                          if (!isArabicOnly && arabicReference != null) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                arabicReference,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
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
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tokens.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: tokens.primary.withOpacity(0.16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isArabicOnly)
                      Text(
                        meta.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: tokens.primary,
                        ),
                      ),
                    Text(
                      meta.arabicLabel,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Text(
              dua.arabicText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: tokens.arabicTextStyle(
                fontSize: compact ? 17 : 19,
                height: 1.9,
              ),
            ),
          ),
          if (hasTransliteration) ...[
            const SizedBox(height: 8),
            Text(
              dua.transliteration,
              style: tokens.transliterationTextStyle(
                fontSize: 11,
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
