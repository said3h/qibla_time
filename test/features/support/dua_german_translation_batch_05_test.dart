import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German batch 05 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_salah_before_salam_58',
      'hisn_salah_before_salam_60',
      'hisn_salah_before_salam_61',
      'hisn_salah_before_salam_62',
      'hisn_salah_before_salam_63',
      'hisn_salah_before_salam_64',
      'hisn_salah_before_salam_65',
      'hisn_after_salam_66',
      'hisn_after_salam_71',
      'hisn_after_salam_72',
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
