import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  test('Sayyid al-Istighfar retains the complete invocation in all locales',
      () {
    final entries =
        (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
                as List)
            .cast<Map<String, dynamic>>();
    final raw = entries.singleWhere((e) => e['id'] == 'repentance_1');
    final other =
        entries.singleWhere((e) => e['id'] == 'hisn_morning_evening_80');
    const endings = <String, String>{
      "es": "nadie perdona los pecados sino Tú.",
      "en": "none who may forgive sins but You.",
      "ar": "إِلاّ أَنْتَ",
      "fr": "nul autre que Toi ne pardonne les péchés.",
      "de": "niemand außer Dir vergibt die Sünden.",
      "it": "nessuno perdona i peccati se non Tu.",
      "tr": "günahları Senden başka bağışlayan yoktur.",
      "id": "tidak ada yang mengampuni dosa selain Engkau.",
      "ru": "никто, кроме Тебя, не прощает грехи.",
      "pt": "ninguém perdoa os pecados além de Ti.",
      "nl": "niemand vergeeft zonden behalve U.",
    };
    final model = DuaMultilenguaje.fromJson(raw);
    expect((raw['translations'] as Map).keys, unorderedEquals(endings.keys));
    expect(raw['arabicText'], other['arabicText']);
    expect(raw['transliteration'], other['transliteration']);
    expect(raw['arabicText'], contains('فَاغْفـِرْ لي'));
    expect(raw['reference'], 'Al-Bukhari 6306');
    for (final locale in endings.keys) {
      final dua = model.getDua(locale);
      expect(dua.id, 'repentance_1');
      expect(dua.count, 1);
      expect(dua.isFeatured, isTrue);
      expect(dua.translation, endsWith(endings[locale]!));
      expect(dua.arabicText, raw['arabicText']);
      expect(dua.transliteration, raw['transliteration']);
    }
    expect(model.getDua('es').category, 'repentance');
    expect(entries, hasLength(200));
    expect(entries.map((e) => e['id']).toSet(), hasLength(200));
  });
}
