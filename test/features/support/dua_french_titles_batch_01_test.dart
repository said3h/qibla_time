import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('French title batch 01 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'repentance_1',
      'gratitude_4',
      'after_prayer_2',
      'after_prayer_3',
      'after_prayer_4',
      'hajj_1',
      'zikr_2',
      'zikr_3',
      'zikr_4',
      'zikr_5',
      'zikr_8',
    ];
    for (final id in ids) {
      final entry = entries.singleWhere((e) => e['id'] == id);
      final translations = entry['translations'] as Map<String, dynamic>;
      expect(
        translations['fr']['title'],
        isNot(translations['en']['title']),
        reason: 'French title remains an English copy for $id',
      );
      expect(translations['fr']['title'], isNotEmpty);
    }
  });
}
