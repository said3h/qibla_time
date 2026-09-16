import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German title batch 08 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_morning_evening_82',
      'hisn_morning_evening_83',
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
        translations['de']['title'],
        isNot(translations['en']['title']),
        reason: 'German title remains an English copy for $id',
      );
      expect(translations['de']['title'], isNotEmpty);
    }
  });
}
