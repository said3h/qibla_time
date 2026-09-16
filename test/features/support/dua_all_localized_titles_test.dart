import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dua titles are not exact English copies in supported locales', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const locales = [
      'ar',
      'es',
      'fr',
      'de',
      'id',
      'it',
      'nl',
      'pt',
      'ru',
      'tr'
    ];

    for (final entry in entries) {
      final translations = entry['translations'] as Map<String, dynamic>;
      final englishTitle = translations['en']['title'];
      for (final locale in locales) {
        expect(
          translations[locale]['title'],
          isNot(englishTitle),
          reason: 'English title copy remains for ${entry['id']} ($locale)',
        );
      }
    }
  });
}
