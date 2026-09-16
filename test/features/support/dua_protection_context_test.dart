import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  test('protection_1 preserves its ID and uses evening context in all locales',
      () {
    final entries =
        (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
                as List)
            .cast<Map<String, dynamic>>();
    final raw = entries.singleWhere((e) => e['id'] == 'protection_1');
    final evening = DuaMultilenguaje.fromJson(
        entries.singleWhere((e) => e['id'] == 'morning_3'));
    final model = DuaMultilenguaje.fromJson(raw);
    const locales = [
      'es',
      'en',
      'ar',
      'fr',
      'de',
      'nl',
      'id',
      'ru',
      'it',
      'pt',
      'tr'
    ];
    expect((raw['translations'] as Map).keys, unorderedEquals(locales));
    expect(raw['reference'], 'At-Tirmidhi 3604b');
    expect(raw['count'], 3);
    for (final locale in locales) {
      final dua = model.getDua(locale);
      expect(dua.id, 'protection_1');
      expect(dua.title, evening.getDua(locale).title);
      expect(dua.reference, 'At-Tirmidhi 3604b');
      expect(dua.source, 'Jami at-Tirmidhi');
      expect(dua.count, 3);
      expect(dua.times, ['night']);
      expect(dua.arabicText, evening.getDua(locale).arabicText);
      expect(dua.isFeatured, isTrue);
    }
    expect(model.getDua('es').title, 'Protección de la tarde');
    expect(model.getDua('es').category, 'protection');
    expect(entries, hasLength(200));
    expect(entries.map((e) => e['id']).toSet(), hasLength(200));
  });
}
