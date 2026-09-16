import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dutch batch 06 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_after_salam_72',
      'hisn_after_salam_73',
      'hisn_istikhara_74',
      'hisn_morning_evening_75',
      'hisn_morning_evening_76',
      'hisn_morning_evening_78',
      'hisn_morning_evening_79',
      'hisn_morning_evening_80',
      'hisn_morning_evening_81',
      'hisn_morning_evening_82',
    ];
    for (final id in ids) {
      final entry = entries.singleWhere((e) => e['id'] == id);
      final translations = entry['translations'] as Map<String, dynamic>;
      expect(
        translations['nl']['translation'],
        isNot(translations['en']['translation']),
        reason: 'Dutch copy remains for $id',
      );
      expect(translations['nl']['translation'], isNotEmpty);
    }
  });
}
