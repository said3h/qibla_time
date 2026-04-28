import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TajweedText {
  const TajweedText._();

  static const _ghunnahColor = Color(0xFF2E7D5B);
  static const _maddColor = Color(0xFF2F6FA3);
  static const _qalqalahColor = Color(0xFFB75B5B);

  static List<InlineSpan> buildSpans({
    required String html,
    required TextStyle baseStyle,
    String? plainText,
    int? surahNumber,
    int? ayahNumber,
  }) {
    if (html.trim().isEmpty) {
      return const <InlineSpan>[];
    }

    // Disable tajweed per ayah when normalized markup differs from the base
    // Uthmani text; Quran text integrity takes priority over visual color.
    if (plainText != null &&
        !_canUseTajweed(
          html: html,
          plainText: plainText,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        )) {
      return const <InlineSpan>[];
    }

    final spans = <InlineSpan>[];
    final tagPattern = RegExp(
      r"""<(?:tajweed|span)\s+class=["']?([^"'>\s]+)["']?[^>]*>(.*?)</(?:tajweed|span)>""",
      caseSensitive: false,
      dotAll: true,
    );

    var cursor = 0;
    for (final match in tagPattern.allMatches(html)) {
      if (match.start > cursor) {
        _addPlainSpan(spans, html.substring(cursor, match.start), baseStyle);
      }

      final className = match.group(1) ?? '';
      final content = match.group(2) ?? '';
      if (className == 'end') {
        cursor = match.end;
        continue;
      }

      final text = _decodeHtml(_stripTags(content));
      if (text.isNotEmpty) {
        spans.add(
          TextSpan(
            text: text,
            style: baseStyle.copyWith(color: _colorForClass(className)),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < html.length) {
      _addPlainSpan(spans, html.substring(cursor), baseStyle);
    }

    return spans.isEmpty
        ? <InlineSpan>[
            TextSpan(text: _decodeHtml(_stripTags(html)), style: baseStyle),
          ]
        : spans;
  }

  static void _addPlainSpan(
    List<InlineSpan> spans,
    String rawText,
    TextStyle baseStyle,
  ) {
    final text = _decodeHtml(_stripTags(rawText));
    if (text.isEmpty) return;
    spans.add(TextSpan(text: text, style: baseStyle));
  }

  static Color? _colorForClass(String className) {
    final normalized = className.toLowerCase().replaceAll('_', '-');
    if (normalized.contains('ghunnah')) return _ghunnahColor;
    if (normalized.contains('madd') || normalized.contains('madda')) {
      return _maddColor;
    }
    if (normalized.contains('qalaqah') || normalized.contains('qalqalah')) {
      return _qalqalahColor;
    }
    return null;
  }

  static bool isEquivalentToPlainText(String html, String plainText) {
    final tajweedText = _decodeHtml(_stripTagsWithoutEndMarkers(html));
    return _normalizeForComparison(tajweedText) ==
            _normalizeForComparison(plainText) ||
        _normalizeArabicSkeleton(tajweedText) ==
            _normalizeArabicSkeleton(plainText);
  }

  static String plainTextFromHtml(String html) {
    return _decodeHtml(_stripTagsWithoutEndMarkers(html));
  }

  static String _stripTagsWithoutEndMarkers(String value) {
    return value
        .replaceAll(
          RegExp(
            r"""<span\s+class=["']?end["']?[^>]*>.*?</span>""",
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static String _stripTags(String value) {
    return value.replaceAll(RegExp(r'<[^>]+>'), '');
  }

  static String _normalizeForComparison(String value) {
    return value
        .replaceAll(_invisiblePattern, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _canUseTajweed({
    required String html,
    required String plainText,
    int? surahNumber,
    int? ayahNumber,
  }) {
    final tajweedPlain = _decodeHtml(_stripTagsWithoutEndMarkers(html));
    final normalizedBase = _normalizeForComparison(plainText);
    final normalizedTajweed = _normalizeForComparison(tajweedPlain);
    if (normalizedBase == normalizedTajweed) return true;

    final baseSkeleton = _normalizeArabicSkeleton(plainText);
    final tajweedSkeleton = _normalizeArabicSkeleton(tajweedPlain);
    if (baseSkeleton == tajweedSkeleton) return true;

    final baseConsonants = _normalizeArabicConsonantSkeleton(plainText);
    final tajweedConsonants = _normalizeArabicConsonantSkeleton(tajweedPlain);
    if (baseConsonants == tajweedConsonants) return true;

    _logRejectedTajweed(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      normalizedBase: normalizedBase,
      normalizedTajweed: normalizedTajweed,
      baseSkeleton: baseSkeleton,
      tajweedSkeleton: tajweedSkeleton,
      classes: _extractClasses(html),
    );
    return false;
  }

  static String _normalizeArabicSkeleton(String value) {
    return _normalizeForComparison(value)
        .replaceAll(_arabicDiacriticsPattern, '')
        .replaceAll(_quranPausePattern, '')
        .replaceAll('\u0640', '')
        .replaceAll('\u0672', '\u0627')
        .replaceAll('\u0671', '\u0627')
        .replaceAll('\u0623', '\u0627')
        .replaceAll('\u0625', '\u0627')
        .replaceAll('\u0622', '\u0627')
        .replaceAll('\u0649', '\u064A')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }

  static String _normalizeArabicConsonantSkeleton(String value) {
    return _normalizeArabicSkeleton(value)
        .replaceAll('\u0627', '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }

  static List<String> _extractClasses(String html) {
    final classes = <String>{};
    final tagPattern = RegExp(
      r"""<(?:tajweed|span)\s+class=["']?([^"'>\s]+)["']?""",
      caseSensitive: false,
    );
    for (final match in tagPattern.allMatches(html)) {
      final className = match.group(1);
      if (className == null || className == 'end') continue;
      classes.add(className);
    }
    return classes.toList()..sort();
  }

  static void _logRejectedTajweed({
    required int? surahNumber,
    required int? ayahNumber,
    required String normalizedBase,
    required String normalizedTajweed,
    required String baseSkeleton,
    required String tajweedSkeleton,
    required List<String> classes,
  }) {
    if (!kDebugMode) return;

    final reference = surahNumber == null || ayahNumber == null
        ? 'unknown'
        : '$surahNumber:$ayahNumber';
    debugPrint(
      '[TajweedText] Tajweed rejected for $reference\n'
      'base="$normalizedBase"\n'
      'tajweed="$normalizedTajweed"\n'
      'diff="${_firstDifference(baseSkeleton, tajweedSkeleton)}"\n'
      'classes=${classes.join(', ')}',
    );
  }

  static String _firstDifference(String base, String tajweed) {
    final maxLength =
        base.length < tajweed.length ? base.length : tajweed.length;
    for (var index = 0; index < maxLength; index++) {
      if (base[index] != tajweed[index]) {
        return 'index $index: base "${base[index]}" vs tajweed "${tajweed[index]}"';
      }
    }
    if (base.length != tajweed.length) {
      return 'length differs: base ${base.length} vs tajweed ${tajweed.length}';
    }
    return 'none';
  }

  static final _invisiblePattern = RegExp(r'[\u200B-\u200D\uFEFF\u2060]');
  static final _arabicDiacriticsPattern = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
  );
  static final _quranPausePattern = RegExp(r'[ۖۗۘۙۚۛۜ۝۞]');

  static String _decodeHtml(String value) {
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }
}
