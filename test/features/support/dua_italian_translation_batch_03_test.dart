import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Italian batch 03 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_salah_ruku_35',
      'hisn_salah_ruku_36',
      'hisn_salah_ruku_37',
      'hisn_salah_rise_38',
      'hisn_salah_rise_39',
      'hisn_salah_rise_40',
      'hisn_salah_sujud_41',
      'hisn_salah_sujud_44',
      'hisn_salah_sujud_46',
      'hisn_salah_sujud_47',
    ];
    for (final id in ids) {
      final entry = entries.singleWhere((e) => e['id'] == id);
      final translations = entry['translations'] as Map<String, dynamic>;
      expect(
        translations['it']['translation'],
        isNot(translations['en']['translation']),
        reason: 'Italian copy remains for $id',
      );
      expect(translations['it']['translation'], isNotEmpty);
    }
  });
}
