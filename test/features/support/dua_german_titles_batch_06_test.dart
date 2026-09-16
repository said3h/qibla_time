import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German title batch 06 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_salah_before_salam_55',
      'hisn_salah_before_salam_56',
      'hisn_salah_before_salam_57',
      'hisn_salah_before_salam_58',
      'hisn_salah_before_salam_60',
      'hisn_salah_before_salam_61',
      'hisn_salah_before_salam_62',
      'hisn_salah_before_salam_63',
      'hisn_salah_before_salam_64',
      'hisn_salah_before_salam_65',
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
