import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  final entries =
      (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();
  const references = {
    'morning_3': 'At-Tirmidhi 3604b',
    'after_prayer_5': 'Muslim 597a',
    'zikr_5': 'At-Tirmidhi 3383',
    'zikr_6': 'Al-Bukhari 8',
  };
  for (final item in references.entries) {
    test('${item.key} uses verified context and count in every language', () {
      final raw = entries.singleWhere((e) => e['id'] == item.key);
      final model = DuaMultilenguaje.fromJson(raw);
      final translations = raw['translations'] as Map<String, dynamic>;
      expect(translations.length, 11);
      for (final locale in translations.keys) {
        final dua = model.getDua(locale);
        expect(dua.id, item.key);
        expect(dua.reference, item.value);
        expect(dua.count, item.key == 'morning_3' ? 3 : 1);
        expect(dua.arabicText, raw['arabicText']);
        if (item.key == 'morning_3') {
          expect(dua.category, 'night');
          expect(dua.times, ['night']);
        } else if (item.key.startsWith('zikr')) {
          expect(dua.times, ['general']);
        }
      }
    });
  }
  test('closing formula does not mix in the life and death variant', () {
    final model = DuaMultilenguaje.fromJson(
        entries.singleWhere((e) => e['id'] == 'after_prayer_5'));
    expect(model.getDua('nl').translation, isNot(contains('leven')));
    expect(model.getDua('de').translation, endsWith('Macht über alle Dinge.'));
    expect(model.getDua('es').title,
        'Al completar el dhikr después de la oración');
    expect(entries, hasLength(200));
    expect(entries.map((e) => e['id']).toSet(), hasLength(200));
  });
}
