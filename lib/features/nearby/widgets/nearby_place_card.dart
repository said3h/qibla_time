import 'package:flutter/material.dart';
import 'package:qibla_time/core/theme/local_fonts.dart';

import '../../../core/utils/qibla_snackbar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../models/nearby_place.dart';

class NearbyPlaceCard extends StatelessWidget {
  const NearbyPlaceCard({
    super.key,
    required this.place,
    required this.onDirections,
    this.nextPrayerLabel,
  });

  final NearbyPlace place;
  final Future<bool> Function() onDirections;
  final String? nextPrayerLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final title = place.name?.trim().isNotEmpty == true
        ? place.name!.trim()
        : _unnamedTitle(context);

    return Semantics(
      container: true,
      label: title,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tokens.primaryBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _categoryIcon(),
                    color: tokens.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          color: tokens.textPrimary,
                        ),
                      ),
                      if (place.distanceMeters != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.nearbyDistance(
                            _formatDistance(place.distanceMeters!),
                          ),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: tokens.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (nextPrayerLabel != null) ...[
              const SizedBox(height: 12),
              _InfoPill(
                icon: Icons.schedule_rounded,
                text: l10n.nearbyPrayerTimeDisclaimer(nextPrayerLabel!),
              ),
            ],
            const SizedBox(height: 12),
            _OptionalInfo(icon: Icons.place_outlined, text: place.address),
            _OptionalInfo(icon: Icons.phone_outlined, text: place.phone),
            _OptionalInfo(icon: Icons.language_outlined, text: place.website),
            _OptionalInfo(
              icon: Icons.access_time_rounded,
              text: place.openingHours,
            ),
            _OptionalInfo(
              icon: Icons.accessible_forward_rounded,
              text: place.wheelchair == null
                  ? null
                  : l10n.nearbyWheelchair(place.wheelchair!),
            ),
            _OptionalInfo(
              icon: Icons.my_location_rounded,
              text:
                  '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: '${l10n.nearbyDirections}: $title',
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final opened = await onDirections();
                    if (!opened && context.mounted) {
                      showQiblaSnackBarWithMessenger(
                        context,
                        messenger: messenger,
                        message: l10n.nearbyDirectionsError,
                        icon: Icons.error_outline_rounded,
                      );
                    }
                  },
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(l10n.nearbyDirections),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  IconData _categoryIcon() {
    return switch (place.category) {
      NearbyPlaceCategory.mosque => Icons.mosque_outlined,
      NearbyPlaceCategory.halalRestaurant => Icons.restaurant_menu_outlined,
      NearbyPlaceCategory.halalButcher => Icons.storefront_outlined,
    };
  }

  String _unnamedTitle(BuildContext context) {
    return switch (place.category) {
      NearbyPlaceCategory.mosque => context.l10n.nearbyUnnamedMosque,
      NearbyPlaceCategory.halalRestaurant =>
        context.l10n.nearbyUnnamedRestaurant,
      NearbyPlaceCategory.halalButcher => context.l10n.nearbyUnnamedButcher,
    };
  }
}

class _OptionalInfo extends StatelessWidget {
  const _OptionalInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final value = text?.trim();
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    final tokens = QiblaThemes.current;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tokens.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.4,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.primaryBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.primaryBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: tokens.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.35,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
