import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  test('sickness_5 retains the complete ruqyah in all locales', () {
    final entries =
        (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
                as List)
            .cast<Map<String, dynamic>>();
    final raw = entries.singleWhere((e) => e['id'] == 'sickness_5');
    final model = DuaMultilenguaje.fromJson(raw);
    final translations = raw['translations'] as Map<String, dynamic>;
    expect(translations.length, 11);
    expect(raw['arabicText'], contains('اللَّهُ يَشْفِيكَ'));
    expect((raw['arabicText'] as String).split('بِسْمِ اللَّهِ أَرْقِيكَ'),
        hasLength(3));
    expect(raw['transliteration'], contains('Allāhu yashfīka'));
    for (final locale in translations.keys) {
      final dua = model.getDua(locale);
      expect(dua.id, 'sickness_5');
      expect(dua.reference, 'Muslim 2186');
      expect(dua.count, 1);
      expect(dua.translation.length, greaterThan(100));
      expect(dua.translation, isNot(contains('inviAllahso')));
      expect(dua.translation, isNot(contains('http')));
    }
    expect(model.getDua('ar').translation, raw['arabicText']);
    expect(model.getDua('es').title, 'Ruqyah por una persona enferma');
    expect(model.getDua('en').title, 'Ruqyah for someone who is ill');
    expect(model.getDua('es').translation, contains('Que Allah te cure.'));
    expect(entries, hasLength(200));
  });
}
