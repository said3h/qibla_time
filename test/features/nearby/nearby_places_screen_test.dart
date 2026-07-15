import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/nearby/screens/nearby_places_screen.dart';
import 'package:qibla_time/l10n/l10n.dart';

void main() {
  testWidgets('shows coming soon categories without opening empty screens',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: NearbyPlacesScreen(),
        ),
      ),
    );

    expect(find.text('Mosques'), findsOneWidget);
    expect(find.text('Halal restaurants'), findsOneWidget);
    expect(find.text('Halal butchers'), findsOneWidget);
    expect(find.text('Coming soon'), findsNWidgets(2));

    await tester.tap(find.text('Halal restaurants'));
    await tester.pumpAndSettle();

    expect(find.byType(NearbyPlacesScreen), findsOneWidget);
  });
}
