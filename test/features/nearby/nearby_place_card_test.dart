import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/nearby/models/nearby_place.dart';
import 'package:qibla_time/features/nearby/widgets/nearby_place_card.dart';
import 'package:qibla_time/l10n/l10n.dart';

void main() {
  testWidgets('labels verified and possible halal places clearly',
      (tester) async {
    Future<void> pumpPlace(HalalVerificationStatus status) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NearbyPlaceCard(
              place: NearbyPlace(
                id: 'test-place',
                category: NearbyPlaceCategory.halalRestaurant,
                latitude: 40.4,
                longitude: -3.7,
                source: 'Geoapify / OpenStreetMap',
                name: 'Test Kebab',
                halalVerification: status,
              ),
              onDirections: () async => true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpPlace(HalalVerificationStatus.verified);
    expect(find.text('Halal verificado'), findsOneWidget);

    await pumpPlace(HalalVerificationStatus.possible);
    expect(find.text('Confirma si es halal'), findsOneWidget);
  });
}
