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
  }) {
    if (html.trim().isEmpty) {
      return const <InlineSpan>[];
    }

    // Disable tajweed per ayah when normalized markup differs from the base
    // Uthmani text; Quran text integrity takes priority over visual color.
    if (plainText != null && !isEquivalentToPlainText(html, plainText)) {
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
    return _normalizeForComparison(
            _decodeHtml(_stripTagsWithoutEndMarkers(html))) ==
        _normalizeForComparison(plainText);
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
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u2060]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

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
