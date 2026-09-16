import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Portuguese batch 02 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_social_209',
      'hisn_food_181',
      'hisn_food_182',
      'hisn_food_183',
      'hisn_rain_170',
      'hisn_salah_opening_29',
      'hisn_salah_opening_30',
      'hisn_salah_opening_31',
      'hisn_salah_ruku_33',
      'hisn_salah_ruku_34',
    ];
    for (final id in ids) {
      final entry = entries.singleWhere((e) => e['id'] == id);
      final translations = entry['translations'] as Map<String, dynamic>;
      expect(
        translations['pt']['translation'],
        isNot(translations['en']['translation']),
        reason: 'Portuguese copy remains for $id',
      );
      expect(translations['pt']['translation'], isNotEmpty);
    }
  });
}
