import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  test('Qadr entries retain IDs with aligned vocalization and translations',
      () {
    final entries =
        (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
                as List)
            .cast<Map<String, dynamic>>();
    final night = DuaMultilenguaje.fromJson(
        entries.singleWhere((e) => e['id'] == 'night_4'));
    final repentance = DuaMultilenguaje.fromJson(
        entries.singleWhere((e) => e['id'] == 'repentance_4'));
    for (final locale in [
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
    ]) {
      final a = night.getDua(locale);
      final b = repentance.getDua(locale);
      expect(a.id, 'night_4');
      expect(b.id, 'repentance_4');
      expect(a.arabicText, b.arabicText);
      expect(b.arabicText, contains('عَفُوٌّ'));
      expect(b.arabicText, isNot(contains('عُفُوٌّ')));
      expect(a.translation, b.translation);
      expect(a.transliteration, b.transliteration);
      expect(b.transliteration, contains('‘afuwwun karīmun'));
      for (final dua in [a, b]) {
        expect(dua.reference, 'At-Tirmidhi 3513');
        expect(dua.times, ['laylatul_qadr']);
        expect(dua.count, 1);
      }
    }
    expect(night.getDua('de').translation, contains('vergib mir'));
    expect(night.getDua('es').category, 'night');
    expect(repentance.getDua('es').category, 'repentance');
    expect(entries, hasLength(200));
    expect(entries.map((e) => e['id']).toSet(), hasLength(200));
  });
}
