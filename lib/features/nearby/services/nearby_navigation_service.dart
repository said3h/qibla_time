import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/nearby_place.dart';

class NearbyNavigationService {
  const NearbyNavigationService();

  Future<bool> openDirections(NearbyPlace place) async {
    for (final uri in buildDirectionUris(place)) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } catch (_) {
        // Try the next compatible maps target.
      }
    }
    return false;
  }

  List<Uri> buildDirectionUris(NearbyPlace place) {
    final label = Uri.encodeComponent(place.name ?? 'Mosque');
    final lat = place.latitude.toStringAsFixed(6);
    final lng = place.longitude.toStringAsFixed(6);
    return <Uri>[
      if (defaultTargetPlatform == TargetPlatform.iOS)
        Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&q=$label'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
      ),
      Uri.parse(
          'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng'),
    ];
  }
}
