import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  final entries = (jsonDecode(
    File('assets/data/duas_multilang.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>();

  for (final item
      in {'hisn_sickness_148': 7, 'hisn_after_salam_72': 10}.entries) {
    test('${item.key} exposes the verified count in all 11 locales', () {
      final raw = entries.singleWhere((e) => e['id'] == item.key);
      final translations = raw['translations'] as Map<String, dynamic>;
      expect(raw['count'], item.value);
      expect(translations.length, 11);
      final model = DuaMultilenguaje.fromJson(raw);
      for (final locale in translations.keys) {
        expect(model.getDua(locale).count, item.value, reason: locale);
        expect(model.getDua(locale).reference, raw['reference']);
      }
    });
  }

  test('ten repetitions retain their Fajr and Maghrib context', () {
    final raw = entries.singleWhere((e) => e['id'] == 'hisn_after_salam_72');
    final model = DuaMultilenguaje.fromJson(raw);
    expect(model.getDua('es').title, 'Después de Fajr y Maghrib');
    expect(model.getDua('en').title, 'After Fajr and Maghrib');
    expect(model.getDua('ar').title, 'بعد صلاتي الفجر والمغرب');
  });

  test('ruqyah reference uses Muslim 2186 regardless of locale', () {
    final raw = entries.singleWhere((e) => e['id'] == 'sickness_5');
    expect(raw['reference'], 'Muslim 2186');
    final model = DuaMultilenguaje.fromJson(raw);
    for (final locale in (raw['translations'] as Map).keys) {
      expect(model.getDua(locale as String).reference, 'Muslim 2186');
    }
  });
}
