import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Spanish title batch 02 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'zikr_5',
      'zikr_6',
      'zikr_7',
      'zikr_8',
      'stress_9',
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
