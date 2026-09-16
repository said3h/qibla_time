import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German batch 01 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_waking_up_2',
      'hisn_clothing_5',
      'hisn_clothing_6',
      'hisn_home_16',
      'hisn_home_17',
      'hisn_after_prayer_27',
      'hisn_after_prayer_28',
      'hisn_stress_120',
      'hisn_stress_122',
      'hisn_stress_125',
    ];
    for (final id in ids) {
      final entry = entries.singleWhere((e) => e['id'] == id);
      final translations = entry['translations'] as Map<String, dynamic>;
      expect(
        translations['de']['translation'],
        isNot(translations['en']['translation']),
        reason: 'German copy remains for $id',
      );
      expect(translations['de']['translation'], isNotEmpty);
    }
  });
}
