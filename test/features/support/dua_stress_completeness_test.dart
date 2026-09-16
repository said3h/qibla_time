import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  test('stress 120 keeps the complete Names clause in every translation', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    final raw = entries.singleWhere((e) => e['id'] == 'hisn_stress_120');
    final model = DuaMultilenguaje.fromJson(raw);

    expect(raw['reference'], 'Hisn al-Muslim 120');
    expect(raw['count'], 1);
    expect(raw['arabicText'], contains('سَمَّـيْتَ بِهِ نَفْسَكَ'));
    expect(raw['arabicText'], contains('اسْتَـأْثَرْتَ بِهِ'));

    const markers = <String, String>{
      'ar': 'سميت به نفسك',
      'en': 'named Yourself',
      'es': 'Te has nombrado',
      'fr': "T'es nommé",
      'de': 'Dich selbst benannt',
    };
    for (final entry in markers.entries) {
      final locale = entry.key;
      final translation = model.getDua(locale).translation;
      expect(translation, isNotEmpty);
      expect(translation, contains(entry.value),
          reason: 'Missing Names clause for $locale');
    }
    for (final locale in const ['id', 'it', 'nl', 'pt', 'ru', 'tr']) {
      expect(model.getDua(locale).translation, isNotEmpty);
    }
  });
}
