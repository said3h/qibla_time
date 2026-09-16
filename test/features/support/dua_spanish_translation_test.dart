import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';

void main() {
  // Sources and review notes: scripts/dua_spanish_translation_batch_*.md.
  const reviewed = {
    'hisn_salah_opening_29': [
      'He vuelto mi rostro',
      'Te pido perdón y a Ti me vuelvo arrepentido.',
    ],
    'hisn_salah_opening_30': [
      'Oh Allah, Señor de Yibril',
      'Tú guías a quien quieres por un camino recto.',
    ],
    'hisn_salah_ruku_33': [
      'Gloria a mi Señor',
      'el Grandioso.',
    ],
    'hisn_salah_ruku_34': [
      'Gloria a Ti, oh Allah',
      'Oh Allah, perdóname.',
    ],
    'hisn_salah_ruku_35': [
      'Glorificado y Santísimo eres',
      'Señor de los ángeles y del Espíritu.',
    ],
    'hisn_salah_ruku_36': [
      'Oh Allah, ante Ti me inclino',
      'todo lo que sostienen mis pies.',
    ],
    'hisn_salah_ruku_37': [
      'Gloria al Dueño del poder',
      'de la majestad y de la grandeza.',
    ],
    'hisn_salah_rise_38': [
      'Allah escucha',
      'a quien Lo alaba.',
    ],
    'hisn_salah_rise_39': [
      'Señor nuestro, a Ti pertenece la alabanza',
      'una alabanza abundante, buena y bendita.',
    ],
    'hisn_salah_rise_40': [
      'Una alabanza que llene los cielos',
      'nada de ello le sirve ante Ti.',
    ],
    'hisn_salah_sujud_41': ['Gloria a mi Señor', 'el Altísimo.'],
    'hisn_salah_sujud_44': [
      'Oh Allah, ante Ti me prosterno',
      'Bendito sea Allah, el mejor de los creadores.',
    ],
    'hisn_salah_sujud_46': [
      'Oh Allah, perdona todos mis pecados',
      'los públicos y los secretos.',
    ],
    'hisn_salah_sujud_47': [
      'Oh Allah, me refugio en Tu complacencia',
      'Tú eres tal como Te has alabado a Ti mismo.',
    ],
    'hisn_salah_between_sujud_48': [
      'Señor mío, perdóname.',
      'Señor mío, perdóname.',
    ],
    'hisn_salah_between_sujud_49': [
      'Oh Allah, perdóname, ten misericordia de mí',
      'provéeme de sustento y eleva mi rango.',
    ],
    'hisn_salah_tilawah_sujud_50': [
      'Mi rostro se prosterna ante Quien lo creó',
      'Bendito sea Allah, el mejor de los creadores.',
    ],
    'hisn_salah_tilawah_sujud_51': [
      'Oh Allah, anota para mí una recompensa',
      'como la aceptaste de Tu siervo Dawud.',
    ],
  };

  const batchThree = {
    'hisn_salah_tashahhud_52': [
      'Todos los honores',
      'Su siervo y Su Mensajero.'
    ],
    'hisn_salah_tashahhud_53': [
      'Oh Allah, concede Tu favor a Muhammad y a la familia',
      'digno de alabanza y glorioso.'
    ],
    'hisn_salah_tashahhud_54': [
      'Oh Allah, concede Tu favor a Muhammad, a sus esposas',
      'digno de alabanza y glorioso.'
    ],
    'hisn_salah_before_salam_55': [
      'Oh Allah, me refugio en Ti del castigo',
      'del mal de la prueba del falso mesías.'
    ],
    'hisn_salah_before_salam_56': [
      'Oh Allah, me refugio en Ti del castigo',
      'del pecado y de las deudas.'
    ],
    'hisn_salah_before_salam_57': [
      'Oh Allah, he sido muy injusto conmigo mismo',
      'el Perdonador, el Misericordioso.'
    ],
    'hisn_salah_before_salam_58': [
      'Oh Allah, perdona mis pecados pasados y futuros',
      'No hay divinidad digna de adoración sino Tú.'
    ],
    'hisn_salah_before_salam_60': [
      'Oh Allah, me refugio en Ti de la avaricia',
      'del castigo de la tumba.'
    ],
    'hisn_salah_before_salam_61': [
      'Oh Allah, Te pido el Paraíso',
      'me refugio en Ti del Fuego.'
    ],
    'hisn_salah_before_salam_62': [
      'Oh Allah, por Tu conocimiento de lo oculto',
      'haz de nosotros guías bien guiados.'
    ],
  };
  const batchFour = {
    'hisn_salah_before_salam_63': [
      'Oh Allah, Te pido',
      'Tú eres el Perdonador, el Misericordioso.'
    ],
    'hisn_salah_before_salam_64': [
      'Oh Allah, Te suplico porque a Ti pertenece toda alabanza.',
      'Te pido el Paraíso y me refugio en Ti del Fuego.'
    ],
    'hisn_salah_before_salam_65': [
      'Oh Allah, Te suplico dando testimonio',
      'no engendró ni fue engendrado y no tiene igual.'
    ],
    'hisn_after_salam_71': [
      'Allah, no hay divinidad digna de adoración sino Él',
      'Él es el Altísimo, el Grandioso.'
    ],
    'hisn_after_salam_72': [
      'No hay divinidad digna de adoración sino Allah',
      'tiene poder sobre todas las cosas.'
    ],
    'hisn_after_salam_73': [
      'Oh Allah, Te pido conocimiento beneficioso',
      'obras aceptadas por Ti.'
    ],
  };
  const batchFive = {
    'hisn_morning_evening_76': [
      "Allah, no hay divinidad d",
      "l Altísimo, el Grandioso."
    ],
    'hisn_morning_evening_78': [
      "Hemos amanecido y el domi",
      " del castigo de la tumba."
    ],
    'hisn_morning_evening_80': [
      "Oh Allah, Tú eres mi Seño",
      "dona los pecados sino Tú."
    ],
    'hisn_morning_evening_81': [
      "Oh Allah, al amanecer Te ",
      "Tu siervo y Tu Mensajero."
    ],
    'hisn_morning_evening_82': [
      "Oh Allah, todo favor con ",
      "anza y el agradecimiento."
    ],
    'hisn_morning_evening_85': [
      "Oh Allah, Te pido perdón ",
      "er destruido desde abajo."
    ],
    'hisn_morning_evening_86': [
      "Oh Allah, Conocedor de lo",
      "causárselo a un musulmán."
    ],
    'hisn_morning_evening_87': [
      "En el nombre de Allah, co",
      " oye, Quien todo lo sabe."
    ],
    'hisn_morning_evening_88': [
      "Estoy complacido con Alla",
      "Muhammad como mi Profeta."
    ],
    'hisn_morning_evening_89': [
      "Oh Viviente, Sustentador ",
      "mismo ni por un instante."
    ],
  };
  const batchSix = {
    'hisn_salah_opening_31': [
      "Allah es el Más Grande, i",
      "to y de sus incitaciones."
    ],
    'hisn_morning_evening_75': [
      "Toda alabanza pertenece ú",
      " no habrá ningún profeta."
    ],
    'hisn_morning_evening_79': [
      "Oh Allah, por Ti amanecem",
      "mos, y a Ti regresaremos."
    ],
    'hisn_morning_evening_83': [
      "Oh Allah, concédeme salud",
      "gna de adoración sino Tú."
    ],
  };
  const allReviewed = {
    ...reviewed,
    ...batchThree,
    ...batchFour,
    ...batchFive,
    ...batchSix
  };

  final entries = (jsonDecode(
    File('assets/data/duas_multilang.json').readAsStringSync(),
  ) as List)
      .cast<Map<String, dynamic>>();

  for (final item in allReviewed.entries) {
    test('${item.key} resolves Spanish rather than the English placeholder',
        () {
      final raw = entries.singleWhere((entry) => entry['id'] == item.key);
      final dua = DuaMultilenguaje.fromJson(raw).getDua('es');
      final translations = raw['translations'] as Map<String, dynamic>;
      final spanish = translations['es'] as Map<String, dynamic>;
      final english = translations['en'] as Map<String, dynamic>;

      expect(dua.id, item.key);
      expect(dua.translation, spanish['translation']);
      expect(dua.translation, isNot(english['translation']));
      expect(dua.translation, startsWith(item.value.first));
      expect(dua.translation, endsWith(item.value.last));
      expect(dua.arabicText, raw['arabicText']);
      expect(dua.reference, raw['reference']);
      expect(dua.count, raw['count']);
      expect(dua.translation, isNot(contains('http')));
      expect(dua.translation, isNot(contains('Recite')));
      expect(dua.translation, isNot(contains('Hisn')));
    });
  }

  test('morning adhkar references match the verified source in every locale',
      () {
    for (final id in batchFive.keys) {
      final raw = entries.singleWhere((entry) => entry['id'] == id);
      final number = int.parse(id.split('_').last) - 1;
      final reference = 'Hisn al-Muslim $number';
      expect(raw['reference'], reference);
      final translations = raw['translations'] as Map<String, dynamic>;
      expect(translations.length, 11);
      for (final locale in translations.keys) {
        expect(
            DuaMultilenguaje.fromJson(raw).getDua(locale).reference, reference,
            reason: '$id / $locale');
      }
    }
    final testimony = entries
        .singleWhere((entry) => entry['id'] == 'hisn_morning_evening_81');
    expect(testimony['count'], 4);
  });

  test('repaired content retains both variants and correct references', () {
    Map<String, dynamic> entry(String id) =>
        entries.singleWhere((e) => e['id'] == id);
    final opening = entry('hisn_salah_opening_31');
    expect(opening['arabicText'], contains('وَهَمْـزِه'));
    final variants = entry('hisn_morning_evening_79');
    expect((variants['arabicText'] as String).split('\n\n'), hasLength(2));
    expect((variants['transliteration'] as String).split('\n\n'), hasLength(2));
    expect(variants['arabicText'], isNot(contains('فليقل')));
    expect(variants['transliteration'], isNot(contains('When you')));
    expect(variants['transliteration'], endsWith('wa ilaykal-maṣīr.'));
    final health = entry('hisn_morning_evening_83');
    expect(health['arabicText'], isNot(contains('إلاّ اللّه أَنْـتَ')));
    expect(health['count'], 3);
    for (final pair in {
      'hisn_morning_evening_75': '75a',
      'hisn_morning_evening_79': '78',
      'hisn_morning_evening_83': '82'
    }.entries) {
      final raw = entry(pair.key);
      final translations = raw['translations'] as Map<String, dynamic>;
      for (final locale in translations.keys) {
        expect(DuaMultilenguaje.fromJson(raw).getDua(locale).reference,
            'Hisn al-Muslim ${pair.value}');
      }
    }
    expect(entries, hasLength(200));
  });

  test('reviewed entries retain unique IDs', () {
    final ids = entries.map((entry) => entry['id']).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids, containsAll(allReviewed.keys));
  });

  test('recitation prostration titles are Spanish', () {
    for (final id in [
      'hisn_salah_tilawah_sujud_50',
      'hisn_salah_tilawah_sujud_51'
    ]) {
      final raw = entries.singleWhere((entry) => entry['id'] == id);
      expect(DuaMultilenguaje.fromJson(raw).getDua('es').title,
          'Al prosternarse durante la recitación del Corán');
    }
  });
}
