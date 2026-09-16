import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German title batch 01 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'repentance_1',
      'hajj_1',
      'zikr_3',
      'hisn_waking_up_2',
      'hisn_clothing_5',
      'hisn_clothing_6',
      'hisn_home_16',
      'hisn_home_17',
      'hisn_after_prayer_27',
      'hisn_after_prayer_28',
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
