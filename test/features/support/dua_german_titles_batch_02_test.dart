import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German title batch 02 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_stress_120',
      'hisn_stress_122',
      'hisn_stress_125',
      'hisn_protection_126',
      'hisn_stress_193',
      'hisn_social_194',
      'hisn_gathering_195',
      'hisn_social_197',
      'hisn_social_202',
      'hisn_social_204',
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
