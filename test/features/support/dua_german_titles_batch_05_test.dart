import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('German title batch 05 is localized', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    const ids = [
      'hisn_salah_sujud_44',
      'hisn_salah_sujud_46',
      'hisn_salah_sujud_47',
      'hisn_salah_between_sujud_48',
      'hisn_salah_between_sujud_49',
      'hisn_salah_tilawah_sujud_50',
      'hisn_salah_tilawah_sujud_51',
      'hisn_salah_tashahhud_52',
      'hisn_salah_tashahhud_53',
      'hisn_salah_tashahhud_54',
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
