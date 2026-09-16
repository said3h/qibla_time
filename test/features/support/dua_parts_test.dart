import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/core/theme/app_theme.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';
import 'package:qibla_time/features/support/services/dua_share_service.dart';
import 'package:qibla_time/features/support/utils/dua_locale_presentation.dart';
import 'package:qibla_time/features/support/widgets/dua_parts_content.dart';

void main() {
  final entries =
      (jsonDecode(File('assets/data/duas_multilang.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();
  final raw = entries.singleWhere((e) => e['id'] == 'sickness_4');
  final model = DuaMultilenguaje.fromJson(raw);

  test('all locales resolve ordered parts with independent counts', () {
    for (final locale in (raw['translations'] as Map).keys.cast<String>()) {
      for (final dua in [model.getDua(locale), model.toDua(locale)]) {
        expect(dua.parts.map((p) => p.count), [3, 7]);
        expect(dua.reference, 'Muslim 2202');
        expect(dua.parts.map((p) => p.arabicText).join('\n\n'), dua.arabicText);
        expect(
            dua.parts.map((p) => p.translation).join('\n\n'), dua.translation);
        expect(dua.parts.map((p) => p.transliteration).join('\n\n'),
            dua.transliteration);
        expect(dua.copyWithTranslation(dua.translation).parts, dua.parts);
      }
    }
    expect(model.getDua('zz').parts.map((p) => p.count), [3, 7]);
    expect(model.toDua('zz').parts.map((p) => p.count), [3, 7]);
  });

  test('legacy entries keep no parts and invalid counts are rejected', () {
    final legacy = DuaMultilenguaje.fromJson(entries.first).getDua('es');
    expect(legacy.parts, isEmpty);
    expect(() => DuaPart.fromJson({'arabicText': 'x', 'count': 0}),
        throwsFormatException);
    expect(entries, hasLength(200));
  });

  test(
      'text and image share retain both counts including single-language export',
      () {
    const service = DuaShareService();
    final dua = model.getDua('es');
    for (final data in [
      service.buildShareData(dua),
      service.buildImageShareData(dua)
    ]) {
      expect(data.arabicText, contains('(×3)'));
      expect(data.arabicText, contains('(×7)'));
      expect(data.translation, contains('(×3)'));
      expect(data.translation, contains('(×7)'));
    }
    expect(service.buildImageShareData(dua, includeArabic: false).arabicText,
        isNull);
    expect(
        service.buildImageShareData(dua, includeTranslation: false).translation,
        isEmpty);
  });

  for (final locale in ['es', 'ar']) {
    for (final theme in [QiblaThemes.dark, QiblaThemes.light]) {
      testWidgets('parts fit narrow reader $locale ${theme.bgPage}',
          (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final dua = model.getDua(locale);
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: DuaPartsContent(
                  parts: dua.parts, tokens: theme, languageCode: locale)),
        ))));
        expect(find.text(DuaLocalePresentation.repeatCountLabel(locale, 3)),
            findsOneWidget);
        expect(find.text(DuaLocalePresentation.repeatCountLabel(locale, 7)),
            findsOneWidget);
        expect(find.text(dua.parts.last.arabicText), findsOneWidget);
        expect(find.text(dua.parts.first.transliteration),
            locale == 'ar' ? findsNothing : findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
