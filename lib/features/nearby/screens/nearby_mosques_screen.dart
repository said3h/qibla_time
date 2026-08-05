import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibla_time/core/theme/local_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../prayer_times/domain/entities/location_access_result.dart';
import '../../prayer_times/domain/entities/next_prayer_info.dart';
import '../../prayer_times/domain/entities/prayer_name.dart';
import '../../prayer_times/domain/entities/resolved_prayer_schedule.dart';
import '../../prayer_times/presentation/providers/prayer_times_providers.dart';
import '../providers/nearby_places_provider.dart';
import '../models/nearby_place.dart';
import '../services/nearby_distance_service.dart';
import '../services/nearby_navigation_service.dart';
import '../services/nearby_places_repository.dart';
import '../widgets/nearby_place_card.dart';

class NearbyMosquesScreen extends NearbyResultsScreen {
  const NearbyMosquesScreen({super.key})
      : super(category: NearbyPlaceCategory.mosque);
}

class NearbyHalalRestaurantsScreen extends NearbyResultsScreen {
  const NearbyHalalRestaurantsScreen({super.key})
      : super(category: NearbyPlaceCategory.halalRestaurant);
}

class NearbyHalalButchersScreen extends NearbyResultsScreen {
  const NearbyHalalButchersScreen({super.key})
      : super(category: NearbyPlaceCategory.halalButcher);
}

class NearbyResultsScreen extends ConsumerStatefulWidget {
  const NearbyResultsScreen({
    super.key,
    required this.category,
  });

  final NearbyPlaceCategory category;

  @override
  ConsumerState<NearbyResultsScreen> createState() =>
      _NearbyResultsScreenState();
}

class _NearbyResultsScreenState extends ConsumerState<NearbyResultsScreen> {
  final _navigationService = const NearbyNavigationService();
  final _distanceService = const NearbyDistanceService();

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final radiusMeters = ref.watch(nearbyRadiusProvider);
    final resultAsync = switch (widget.category) {
      NearbyPlaceCategory.mosque =>
        ref.watch(nearbyMosquesProvider(radiusMeters)),
      NearbyPlaceCategory.halalRestaurant =>
        ref.watch(nearbyHalalRestaurantsProvider(radiusMeters)),
      NearbyPlaceCategory.halalButcher =>
        ref.watch(nearbyHalalButchersProvider(radiusMeters)),
    };
    final isMosque = widget.category == NearbyPlaceCategory.mosque;
    final nextPrayer = isMosque ? ref.watch(nextPrayerInfoProvider) : null;
    final prayerSchedule =
        isMosque ? ref.watch(prayerScheduleProvider).valueOrNull : null;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _title(context),
              subtitle: _subtitle(context),
              onBack: () => Navigator.of(context).pop(),
            ),
            _Controls(
              radiusMeters: radiusMeters,
              onRadiusChanged: (value) {
                ref.read(nearbyRadiusProvider.notifier).state = value;
              },
            ),
            Expanded(
              child: resultAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: tokens.primary),
                ),
                error: (_, __) => _ErrorState(
                  message: l10n.nearbyPlacesLoadError,
                  onRetry: () => _invalidate(radiusMeters),
                ),
                data: (result) {
                  if (result.status ==
                      NearbyPlacesResultStatus.locationUnavailable) {
                    return _LocationUnavailableState(
                      onRetry: () => _invalidate(radiusMeters),
                    );
                  }

                  if (result.places.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _SourceNotice(
                          fromCache: result.fromCache,
                          source: result.originSource,
                          usesGeoapify: result.places.any(
                            (place) => place.source.startsWith('Geoapify'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _EmptyState(
                          body: _emptyBody(context),
                          onRetry: () => _invalidate(radiusMeters),
                        ),
                      ],
                    );
                  }

                  final listItems = _buildListItems(result.places);
                  return RefreshIndicator(
                    onRefresh: () => _refresh(radiusMeters),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: listItems.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _SourceNotice(
                            fromCache: result.fromCache,
                            source: result.originSource,
                            usesGeoapify: result.places.any(
                              (place) => place.source.startsWith('Geoapify'),
                            ),
                          );
                        }
                        final item = listItems[index - 1];
                        if (item.header != null) {
                          return _VerificationHeader(
                            status: item.header!,
                            showExplanation:
                                item.header == HalalVerificationStatus.possible,
                          );
                        }
                        final place = item.place!;
                        final nextPrayerLabel = isMosque
                            ? _safeNextPrayerLabel(
                                context: context,
                                result: result,
                                prayerSchedule: prayerSchedule,
                                nextPrayer: nextPrayer,
                              )
                            : null;
                        return NearbyPlaceCard(
                          place: place,
                          nextPrayerLabel: nextPrayerLabel,
                          onDirections: () =>
                              _navigationService.openDirections(place),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    return switch (widget.category) {
      NearbyPlaceCategory.mosque => context.l10n.nearbyMosques,
      NearbyPlaceCategory.halalRestaurant =>
        context.l10n.nearbyHalalRestaurants,
      NearbyPlaceCategory.halalButcher => context.l10n.nearbyHalalButchers,
    };
  }

  List<_NearbyResultItem> _buildListItems(List<NearbyPlace> places) {
    if (widget.category == NearbyPlaceCategory.mosque) {
      return places.map(_NearbyResultItem.forPlace).toList();
    }

    final items = <_NearbyResultItem>[];
    for (final status in HalalVerificationStatus.values) {
      final matching = places.where((place) {
        if (status == HalalVerificationStatus.possible) {
          return place.halalVerification != HalalVerificationStatus.verified;
        }
        return place.halalVerification == status;
      }).toList();
      if (matching.isEmpty) continue;
      items.add(_NearbyResultItem.forHeader(status));
      items.addAll(matching.map(_NearbyResultItem.forPlace));
    }
    return items;
  }

  String _subtitle(BuildContext context) {
    return switch (widget.category) {
      NearbyPlaceCategory.mosque => context.l10n.nearbyMosquesScreenSubtitle,
      NearbyPlaceCategory.halalRestaurant =>
        context.l10n.nearbyHalalRestaurantsScreenSubtitle,
      NearbyPlaceCategory.halalButcher =>
        context.l10n.nearbyHalalButchersScreenSubtitle,
    };
  }

  String _emptyBody(BuildContext context) {
    return switch (widget.category) {
      NearbyPlaceCategory.mosque => context.l10n.nearbyNoResultsBody,
      NearbyPlaceCategory.halalRestaurant =>
        context.l10n.nearbyNoRestaurantsBody,
      NearbyPlaceCategory.halalButcher => context.l10n.nearbyNoButchersBody,
    };
  }

  void _invalidate(int radiusMeters) {
    switch (widget.category) {
      case NearbyPlaceCategory.mosque:
        ref.invalidate(nearbyMosquesProvider(radiusMeters));
      case NearbyPlaceCategory.halalRestaurant:
        ref.invalidate(nearbyHalalRestaurantsProvider(radiusMeters));
      case NearbyPlaceCategory.halalButcher:
        ref.invalidate(nearbyHalalButchersProvider(radiusMeters));
    }
  }

  Future<void> _refresh(int radiusMeters) async {
    _invalidate(radiusMeters);
    switch (widget.category) {
      case NearbyPlaceCategory.mosque:
        await ref.read(nearbyMosquesProvider(radiusMeters).future);
      case NearbyPlaceCategory.halalRestaurant:
        await ref.read(nearbyHalalRestaurantsProvider(radiusMeters).future);
      case NearbyPlaceCategory.halalButcher:
        await ref.read(nearbyHalalButchersProvider(radiusMeters).future);
    }
  }

  String? _safeNextPrayerLabel({
    required BuildContext context,
    required NearbyPlacesResult result,
    required ResolvedPrayerSchedule? prayerSchedule,
    required NextPrayerInfo? nextPrayer,
  }) {
    final originLocation = result.originLocation;
    if (originLocation == null ||
        prayerSchedule == null ||
        nextPrayer == null) {
      return null;
    }

    final scheduleDistance = _distanceService.distanceMeters(
      fromLatitude: originLocation.latitude,
      fromLongitude: originLocation.longitude,
      toLatitude: prayerSchedule.location.latitude,
      toLongitude: prayerSchedule.location.longitude,
    );
    if (scheduleDistance > 750 || nextPrayer.remaining.isNegative) {
      return null;
    }

    final prayerName = nextPrayer.prayer.displayName;
    final remaining = nextPrayer.remaining;
    final minutes = remaining.inMinutes;
    return minutes < 60
        ? context.l10n.nearbyPrayerStartsInMinutes(prayerName, minutes)
        : context.l10n.nearbyPrayerStartsInHours(
            prayerName,
            remaining.inHours,
            remaining.inMinutes.remainder(60),
          );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: tokens.textPrimary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28,
                    color: tokens.primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: tokens.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.radiusMeters,
    required this.onRadiusChanged,
  });

  final int radiusMeters;
  final ValueChanged<int> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.nearbySearchRadius,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: tokens.textSecondary,
                ),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: radiusMeters,
                dropdownColor: tokens.bgSurface,
                borderRadius: BorderRadius.circular(14),
                items: nearbyRadiusOptionsMeters.map((meters) {
                  return DropdownMenuItem<int>(
                    value: meters,
                    child: Text(
                      '${meters ~/ 1000} km',
                      style: GoogleFonts.dmSans(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onRadiusChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyResultItem {
  const _NearbyResultItem.forPlace(this.place) : header = null;
  const _NearbyResultItem.forHeader(this.header) : place = null;

  final NearbyPlace? place;
  final HalalVerificationStatus? header;
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader({
    required this.status,
    required this.showExplanation,
  });

  final HalalVerificationStatus status;
  final bool showExplanation;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final verified = status == HalalVerificationStatus.verified;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified_outlined : Icons.info_outline_rounded,
                size: 17,
                color: verified ? tokens.primary : tokens.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                verified
                    ? context.l10n.nearbyHalalVerified
                    : context.l10n.nearbyPossibleHalal,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
          if (showExplanation) ...[
            const SizedBox(height: 5),
            Text(
              context.l10n.nearbyPossibleHalalExplanation,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                height: 1.4,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceNotice extends StatelessWidget {
  const _SourceNotice({
    required this.fromCache,
    required this.source,
    required this.usesGeoapify,
  });

  final bool fromCache;
  final LocationAccessSource? source;
  final bool usesGeoapify;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final locationLabel = source == LocationAccessSource.manual
        ? l10n.nearbyUsingManualCity
        : l10n.nearbyUsingDeviceLocation;
    final attribution = usesGeoapify
        ? l10n.nearbyGeoapifyAttribution
        : l10n.nearbyOsmAttribution;
    final attributionUri = usesGeoapify
        ? Uri.parse('https://www.geoapify.com/')
        : Uri.parse('https://www.openstreetmap.org/copyright');

    return Semantics(
      button: true,
      label: attribution,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => launchUrl(
          attributionUri,
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.primaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.primaryBorder),
          ),
          child: Text(
            [
              locationLabel,
              attribution,
              if (fromCache) l10n.nearbyCachedResults,
            ].join(' · '),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              height: 1.45,
              color: tokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.cloud_off_outlined,
      title: message,
      body: context.l10n.nearbyPlacesLoadErrorBody,
      actionLabel: context.l10n.nearbyRetry,
      onAction: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.body,
    required this.onRetry,
  });

  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.search_off_rounded,
      title: context.l10n.nearbyNoResults,
      body: body,
      actionLabel: context.l10n.nearbyRetry,
      onAction: onRetry,
    );
  }
}

class _LocationUnavailableState extends StatelessWidget {
  const _LocationUnavailableState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateMessage(
      icon: Icons.location_off_outlined,
      title: context.l10n.nearbyLocationDenied,
      body: context.l10n.nearbyLocationDeniedBody,
      actionLabel: context.l10n.nearbyAllowLocation,
      onAction: onRetry,
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: tokens.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.45,
                color: tokens.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
