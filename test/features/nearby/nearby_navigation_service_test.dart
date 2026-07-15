import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/nearby/models/nearby_place.dart';
import 'package:qibla_time/features/nearby/services/nearby_navigation_service.dart';

void main() {
  test('builds external map candidates with encoded coordinates and label', () {
    const service = NearbyNavigationService();
    const place = NearbyPlace(
      id: 'node/1',
      category: NearbyPlaceCategory.mosque,
      latitude: 38.3456789,
      longitude: -0.4812345,
      source: 'OpenStreetMap',
      name: 'Alicante Central Mosque',
    );

    final uris = service.buildDirectionUris(place);
    final values = uris.map((uri) => uri.toString()).toList();

    expect(
        values,
        contains(
            'geo:38.345679,-0.481235?q=38.345679,-0.481235(Alicante%20Central%20Mosque)'));
    expect(
      values,
      contains(
          'https://www.google.com/maps/dir/?api=1&destination=38.345679,-0.481235'),
    );
    expect(
      values,
      contains(
          'https://www.openstreetmap.org/?mlat=38.345679&mlon=-0.481235#map=17/38.345679/-0.481235'),
    );
  });
}
