import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/core/theme/app_theme.dart';
import 'package:qibla_time/features/tafsir/models/tafsir_entry.dart';
import 'package:qibla_time/features/tafsir/providers/tafsir_provider.dart';
import 'package:qibla_time/features/tafsir/widgets/tafsir_panel.dart';
import 'package:qibla_time/l10n/l10n.dart';

void main() {
  testWidgets('TafsirPanel shows safe unavailable state', (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        overrides: [
          tafsirEntryProvider.overrideWith(
            (ref, request) async => const TafsirLoadResult(
              source: TafsirLoadSource.unavailable,
              errorCode: 'tafsir_not_configured',
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Tafsir'), findsOneWidget);
    expect(find.text('Tafsir unavailable'), findsOneWidget);
    expect(
      find.text(
        'A tafsir source is not available for this ayah yet.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('tafsir_not_configured'), findsNothing);
  });

  testWidgets('TafsirPanel shows debug info for unavailable debug results',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        overrides: [
          tafsirEntryProvider.overrideWith(
            (ref, request) async => const TafsirLoadResult(
              source: TafsirLoadSource.unavailable,
              errorCode: 'empty_tafsir_text',
              debugInfo: TafsirDebugInfo(
                provider: 'qul_preview',
                resourceId: '268',
                url: 'https://qul.tarteel.ai/resources/tafsir/268?ayah=1%3A1',
                statusCode: 200,
                fallbackReason: 'parse_empty',
                htmlLength: 1200,
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Debug info'), findsOneWidget);
    expect(find.text('provider: qul_preview'), findsOneWidget);
    expect(find.text('resourceId: 268'), findsOneWidget);
    expect(find.text('statusCode: 200'), findsOneWidget);
    expect(find.text('fallback: parse_empty'), findsOneWidget);
    expect(find.text('html: 1200 chars'), findsOneWidget);
  });

  testWidgets('TafsirPanel shows success state without visible source chip',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        overrides: [
          tafsirEntryProvider.overrideWith(
            (ref, request) async => const TafsirLoadResult(
              source: TafsirLoadSource.cache,
              entry: TafsirEntry(
                tafsirId: '169',
                resourceName: 'Fake Tafsir',
                languageCode: 'en',
                surahNumber: 2,
                ayahNumber: 255,
                text: 'Cached tafsir body.',
                source: 'test',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Fake Tafsir'), findsNothing);
    expect(find.text('Cached tafsir body.'), findsOneWidget);
    expect(find.text('Source: cache'), findsNothing);
  });

  testWidgets('TafsirPanel truncates long tafsir until read more is tapped',
      (tester) async {
    final longText = List.filled(70, 'Texto largo de tafsir').join(' ');
    await tester.pumpWidget(
      _wrapPanel(
        overrides: [
          tafsirEntryProvider.overrideWith(
            (ref, request) async => TafsirLoadResult(
              source: TafsirLoadSource.api,
              entry: TafsirEntry(
                tafsirId: '268',
                resourceName: 'Spanish Tafsir',
                languageCode: 'es',
                surahNumber: 2,
                ayahNumber: 255,
                text: longText,
                source: 'test',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Read more'), findsOneWidget);
    expect(find.text(longText), findsNothing);

    await tester.ensureVisible(find.text('Read more'));
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();

    expect(find.text('Show less'), findsOneWidget);
    expect(find.text(longText), findsOneWidget);
  });

  testWidgets('TafsirPanel can stay collapsed until tapped', (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        initiallyExpanded: false,
        overrides: [
          tafsirEntryProvider.overrideWith(
            (ref, request) async => const TafsirLoadResult(
              source: TafsirLoadSource.unavailable,
              errorCode: 'tafsir_not_configured',
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Tafsir unavailable'), findsNothing);

    await tester.tap(find.text('Tafsir'));
    await tester.pumpAndSettle();

    expect(find.text('Tafsir unavailable'), findsOneWidget);
  });
}

Widget _wrapPanel({
  required List<Override> overrides,
  bool initiallyExpanded = true,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: TafsirPanel(
                surahNumber: 2,
                ayahNumber: 255,
                languageCode: 'en',
                tafsirId: '169',
                initiallyExpanded: initiallyExpanded,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
