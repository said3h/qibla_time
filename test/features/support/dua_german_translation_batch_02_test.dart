import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German batch 02 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_protection_126',
      'hisn_stress_193',
      'hisn_social_194',
      'hisn_gathering_195',
      'hisn_social_197',
      'hisn_social_202',
      'hisn_social_204',
      'hisn_social_205',
      'hisn_travel_206',
      'hisn_travel_208',
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
