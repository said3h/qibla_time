import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duas_multilang loads and new Hisn entries include all app languages',
      () async {
    final file = File('assets/data/duas_multilang.json');
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);

    expect(decoded, isA<List<dynamic>>());
    final duas = decoded as List<dynamic>;
    expect(duas.length, greaterThanOrEqualTo(125));
    expect(raw.contains('\uFFFD'), isFalse);
    expect(_containsArabic(raw), isTrue);

    final hisnEntries = duas
        .cast<Map<String, dynamic>>()
        .where((dua) => (dua['id'] as String).startsWith('hisn_'))
        .toList();
    expect(hisnEntries.length, greaterThanOrEqualTo(25));

    const requiredLanguages = {
      'ar',
      'de',
      'en',
      'es',
      'fr',
      'id',
      'it',
      'nl',
      'pt',
      'ru',
      'tr',
    };

    for (final dua in hisnEntries) {
      final translations = dua['translations'] as Map<String, dynamic>;
      expect(translations.keys.toSet().containsAll(requiredLanguages), isTrue);
      for (final language in requiredLanguages) {
        final translation = translations[language] as Map<String, dynamic>;
        expect((translation['title'] as String).trim(), isNotEmpty);
        expect((translation['translation'] as String).trim(), isNotEmpty);
        expect((translation['reference'] as String).trim(), contains('Hisn'));
      }
    }
  });
}

bool _containsArabic(String value) {
  for (final codeUnit in value.codeUnits) {
    if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) {
      return true;
    }
  }
  return false;
}
