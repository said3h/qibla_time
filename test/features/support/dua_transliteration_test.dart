import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  const reviewed = {
    'sleep_5': "Al-ḥamdu lillāhi alladhī aḥyānā ba‘da mā amātanā.",
    'repentance_3':
        "Astaghfiru llāha l-‘aẓīma alladhī lā ilāha illā huwa l-ḥayyu l-qayyūmu wa atūbu ilayh.",
    'rain_3': "Allāhumma sqinā ghaythan mughīthan marī’an nāfi‘an.",
    'stress_5': "Rabbi innī ẓalamtu nafsī faghfir lī.",
    'gratitude_3': "Allāhumma laka l-ḥamdu ḥattā tarḍā.",
    'gratitude_4': "Shukran lillāh.",
    'after_prayer_6': "Allāhumma lā tukhzinī yawma l-qiyāmah.",
    'after_prayer_7': "Allāhumma ajirnī mina n-nār.",
    'wudu_3':
        "Shahidtu an lā ilāha illā llāhu wa anna Muḥammadan ‘abduhu wa rasūluh.",
    'hajj_3': "Rabbi j‘alnī muqīma ṣ-ṣalāti wa min dhurriyyatī.",
    'hajj_4': "Allāhumma j‘al fī qalbī nūran wa fī baṣarī nūran.",
    'parents_3': "Allāhumma bārik lī fī ahlī.",
    'parents_4':
        "Allāhumma ghfir li-wālidayya warḥamhumā kamā rabbayānī ṣaghīrā.",
  };
  final entries =
      (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();
  for (final item in reviewed.entries) {
    test('${item.key} shares its transcription across all locales', () {
      final raw = entries.singleWhere((e) => e['id'] == item.key);
      final model = DuaMultilenguaje.fromJson(raw);
      expect(raw['transliteration'], item.value);
      for (final locale in (raw['translations'] as Map).keys.cast<String>()) {
        expect(model.getDua(locale).transliteration, item.value,
            reason: locale);
        expect(model.toDua(locale).transliteration, item.value, reason: locale);
      }
      expect(item.value, isNot(contains('http')));
      expect(item.value, isNot(contains('Recite')));
    });
  }
  test('all duas have reviewed transcriptions', () {
    final empty = entries
        .where((e) => (e['transliteration'] as String).trim().isEmpty)
        .map((e) => e['id'])
        .toSet();
    expect(empty, isEmpty);
    expect(entries, hasLength(200));
  });
}
