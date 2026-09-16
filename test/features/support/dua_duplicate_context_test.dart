import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final entries = (jsonDecode(
    File('assets/data/duas_multilang.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>();
  Map<String, dynamic> entry(String id) =>
      entries.singleWhere((e) => e['id'] == id);

  test('Repeated Arabic retains separate IDs, contexts and counts', () {
    final food = entry('food_3');
    final prayer = entry('after_prayer_3');
    expect(food['arabicText'], prayer['arabicText']);
    expect(food['count'], 1);
    expect(prayer['count'], 33);
    for (final e in [food, prayer]) {
      final translations = e['translations'] as Map;
      expect(translations, hasLength(11));
      for (final t in translations.values) {
        expect(t['reference'],
            e['id'] == 'food_3' ? 'Sahih Muslim 2734a' : 'Sahih Muslim 597a');
        expect(t['count'], e['count']);
      }
      expect(translations['nl']['translation'], 'Alle lof zij Allah.');
      expect(translations['it']['translation'], 'Lode ad Allah.');
    }
    expect(
        food['translations']['de']['translation'], 'Alles Lob gebührt Allah.');
    expect(food['translations']['es']['category'], 'food');
    expect(prayer['translations']['es']['category'], 'after_prayer');
  });

  test('Ayat al-Kursi contains only recited Arabic in both contexts', () {
    final prayer = entry('hisn_after_salam_71');
    final morning = entry('hisn_morning_evening_76');
    expect(prayer['arabicText'], morning['arabicText']);
    expect(prayer['translations']['ar']['translation'], prayer['arabicText']);
    expect(prayer['reference'], 'Hisn al-Muslim 71');
    expect(morning['reference'], 'Hisn al-Muslim 75');
    expect(entries, hasLength(200));
    expect(entries.map((e) => e['id']).toSet(), hasLength(200));
    expect(
        entry('morning_3')['arabicText'], entry('protection_1')['arabicText']);
  });
}
