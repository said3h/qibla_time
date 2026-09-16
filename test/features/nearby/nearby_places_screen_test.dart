import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/nearby/models/nearby_place.dart';
import 'package:qibla_time/features/nearby/providers/nearby_places_provider.dart';
import 'package:qibla_time/features/nearby/screens/nearby_places_screen.dart';
import 'package:qibla_time/features/nearby/screens/nearby_mosques_screen.dart';
import 'package:qibla_time/features/nearby/services/nearby_places_repository.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/location_access_result.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/l10n/l10n.dart';

void main() {
  testWidgets('opens the available halal restaurant and butcher categories',
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
    expect(find.text('Coming soon'), findsNothing);

    await tester.tap(find.text('Halal restaurants'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NearbyHalalRestaurantsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Halal butchers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NearbyHalalButchersScreen), findsOneWidget);
  });

  testWidgets('filters halal places by verification status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyHalalRestaurantsProvider(nearbyDefaultRadiusMeters)
              .overrideWith((ref) async => NearbyPlacesResult.success(
                    places: const [
                      NearbyPlace(
                        id: 'verified-place',
                        category: NearbyPlaceCategory.halalRestaurant,
                        latitude: 40.1,
                        longitude: -3.1,
                        source: 'Geoapify / OpenStreetMap',
                        name: 'Verified Halal',
                        halalVerification: HalalVerificationStatus.verified,
                      ),
                      NearbyPlace(
                        id: 'possible-place',
                        category: NearbyPlaceCategory.halalRestaurant,
                        latitude: 40.2,
                        longitude: -3.2,
                        source: 'Geoapify / OpenStreetMap',
                        name: 'Possible Kebab',
                        halalVerification: HalalVerificationStatus.possible,
                      ),
                    ],
                    originSource: LocationAccessSource.manual,
                    originLocation: const PrayerLocation(
                      latitude: 40,
                      longitude: -3,
                    ),
                    fromCache: false,
                  )),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: NearbyHalalRestaurantsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Verified Halal'), findsOneWidget);

    await tester.tap(find.text('Halal according to source').first);
    await tester.pumpAndSettle();

    expect(find.text('Verified Halal'), findsOneWidget);
    expect(find.text('Possible Kebab'), findsNothing);

    await tester.tap(find.text('Confirm halal with the venue').first);
    await tester.pumpAndSettle();

    expect(find.text('Verified Halal'), findsNothing);
    expect(find.text('Possible Kebab'), findsOneWidget);
  });
}
