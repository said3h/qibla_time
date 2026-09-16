import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Spanish title batch 01 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'repentance_1',
      'mosque_5',
      'gratitude_4',
      'after_prayer_2',
      'after_prayer_3',
      'after_prayer_4',
      'hajj_1',
      'zikr_2',
      'zikr_3',
      'zikr_4',
    ];
    for (final id in ids) {
      final entry = entries.singleWhere((e) => e['id'] == id);
      final translations = entry['translations'] as Map<String, dynamic>;
      expect(
        translations['es']['title'],
        isNot(translations['en']['title']),
        reason: 'Spanish title remains an English copy for $id',
      );
      expect(translations['es']['title'], isNotEmpty);
    }
  });
}
