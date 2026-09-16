import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German title batch 04 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_salah_opening_31',
      'hisn_salah_ruku_33',
      'hisn_salah_ruku_34',
      'hisn_salah_ruku_35',
      'hisn_salah_ruku_36',
      'hisn_salah_ruku_37',
      'hisn_salah_rise_38',
      'hisn_salah_rise_39',
      'hisn_salah_rise_40',
      'hisn_salah_sujud_41',
    ];
    for (final id in ids) {
      final entry = entries.singleWhere((e) => e['id'] == id);
      final translations = entry['translations'] as Map<String, dynamic>;
      expect(
        translations['de']['title'],
        isNot(translations['en']['title']),
        reason: 'German title remains an English copy for $id',
      );
      expect(translations['de']['title'], isNotEmpty);
    }
  });
}
