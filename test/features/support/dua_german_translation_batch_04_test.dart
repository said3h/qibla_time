import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German batch 04 is not an English copy', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_salah_between_sujud_48',
      'hisn_salah_between_sujud_49',
      'hisn_salah_tilawah_sujud_50',
      'hisn_salah_tilawah_sujud_51',
      'hisn_salah_tashahhud_52',
      'hisn_salah_tashahhud_53',
      'hisn_salah_tashahhud_54',
      'hisn_salah_before_salam_55',
      'hisn_salah_before_salam_56',
      'hisn_salah_before_salam_57',
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
