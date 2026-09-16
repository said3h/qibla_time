import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  final entries =
      (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();
  test('German morning protection translates the shared Arabic', () {
    final raw = entries.singleWhere((e) => e['id'] == 'morning_3');
    final dua = DuaMultilenguaje.fromJson(raw).getDua('de');
    expect(dua.translation,
        'Ich suche Zuflucht in den vollkommenen Worten Allahs vor dem Bösen dessen, was Er erschaffen hat.');
    expect(dua.reference, 'At-Tirmidhi 3604b');
    expect(dua.arabicText, raw['arabicText']);
  });

  test('adhan invocation is complete and consistent in every locale', () {
    final raw = entries.singleWhere((e) => e['id'] == 'mosque_4');
    final model = DuaMultilenguaje.fromJson(raw);
    final translations = raw['translations'] as Map<String, dynamic>;
    expect(translations.length, 11);
    expect(raw['arabicText'], contains('وَعَدْتَهُ'));
    expect(raw['transliteration'], endsWith('wa‘adtah.'));
    for (final locale in translations.keys) {
      final dua = model.getDua(locale);
      expect(dua.id, 'mosque_4');
      expect(dua.reference, 'Al-Bukhari 614');
      expect(dua.count, 1);
      expect(dua.arabicText, raw['arabicText']);
      expect(dua.translation.length, greaterThan(100), reason: locale);
      expect(dua.translation, isNot(contains('http')));
    }
    expect(model.getDua('ar').translation, raw['arabicText']);
    expect(model.getDua('es').title, 'Después del adhan');
    expect(model.getDua('de').translation, contains('Muhammad'));
    expect(model.getDua('de').title, 'Nach dem Adhan');
    expect(entries, hasLength(200));
    expect(entries.map((e) => e['id']).toSet(), hasLength(200));
  });
}
