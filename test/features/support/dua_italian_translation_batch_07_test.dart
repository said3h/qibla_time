import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Italian batch 07 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_morning_evening_85',
      'hisn_morning_evening_86',
      'hisn_morning_evening_87',
      'hisn_morning_evening_88',
      'hisn_morning_evening_89',
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
