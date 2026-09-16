import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German title batch 07 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_after_salam_66',
      'hisn_after_salam_71',
      'hisn_after_salam_73',
      'hisn_istikhara_74',
      'hisn_morning_evening_75',
      'hisn_morning_evening_76',
      'hisn_morning_evening_78',
      'hisn_morning_evening_79',
      'hisn_morning_evening_80',
      'hisn_morning_evening_81',
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
