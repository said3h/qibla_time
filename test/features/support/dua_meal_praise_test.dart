import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  test('meal praise preserves the meaning of Hisn 181 in displayed text', () {
    final entries = (jsonDecode(
      File('assets/data/duas_multilang.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    final raw = entries.singleWhere((e) => e['id'] == 'hisn_food_181');
    final model = DuaMultilenguaje.fromJson(raw);
    const english = 'To Allah belongs abundant, pure and blessed praise. '
        'We cannot fulfil it adequately, nor abandon it, nor do without it, '
        'O our Lord.';
    for (final locale in ['en']) {
      final dua = model.getDua(locale);
      expect(dua.translation, english);
      expect(dua.category, 'food');
      expect(dua.count, 1);
      expect(dua.arabicText, raw['arabicText']);
    }
    expect(
      model.getDua('nl').translation,
      'Aan Allah behoort overvloedige, zuivere en gezegende lof. Wij kunnen '
      'die niet naar behoren opbrengen, haar niet opgeven en niet zonder haar, '
      'o onze Heer.',
    );
    expect(
      model.getDua('de').translation,
      'Allah gebührt reichliches, gutes und gesegnetes Lob. Wir können es '
      'nicht vollständig erfüllen, es nicht aufgeben und nicht darauf '
      'verzichten, o unser Herr.',
    );
    expect(
      model.getDua('id').translation,
      'Milik Allah segala pujian yang melimpah, baik dan penuh berkah. Kami '
      'tidak mampu menunaikannya dengan sempurna, tidak meninggalkannya, dan '
      'tidak dapat hidup tanpanya, wahai Tuhan kami.',
    );
    expect(
      model.getDua('it').translation,
      'Ad Allah appartiene una lode abbondante, buona e benedetta. Non '
      'possiamo renderle pienamente giustizia, né abbandonarla né farne a meno, '
      'o nostro Signore.',
    );
    expect(
        model.getDua('es').translation,
        'A Allah pertenece una alabanza abundante, buena y bendecida, '
        'que no podemos rendir plenamente, ni abandonar, ni dejar de necesitar, '
        'oh Señor nuestro.');
    expect(raw['reference'], 'Hisn al-Muslim 181');
    expect(entries, hasLength(200));
    expect(
        jsonEncode(entries), isNot(contains('Our Lord is never without need')));
  });
}
