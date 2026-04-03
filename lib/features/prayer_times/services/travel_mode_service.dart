import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../l10n/l10n.dart';
import '../data/datasources/travel_location_label_datasource.dart';
import '../data/datasources/travel_mode_datasource.dart';
import '../data/datasources/travel_mode_notification_datasource.dart';
import '../domain/entities/prayer_location.dart';
import '../domain/entities/recent_location.dart';
import '../domain/entities/travel_pending_banner.dart';
import '../domain/entities/travel_mode_update_result.dart';
import '../domain/usecases/detect_travel_mode_change.dart';

class TravelModeService {
  TravelModeService({
    TravelModeDataSource? dataSource,
    TravelLocationLabelDataSource? labelDataSource,
    TravelModeNotificationDataSource? notificationDataSource,
    DetectTravelModeChangeUseCase? detectTravelModeChangeUseCase,
  })  : _dataSource = dataSource ?? TravelModeDataSource(),
        _labelDataSource = labelDataSource ?? TravelLocationLabelDataSource(),
        _notificationDataSource =
            notificationDataSource ?? TravelModeNotificationDataSource(),
        _detectTravelModeChangeUseCase =
            detectTravelModeChangeUseCase ??
            const DetectTravelModeChangeUseCase();

  final TravelModeDataSource _dataSource;
  final TravelLocationLabelDataSource _labelDataSource;
  final TravelModeNotificationDataSource _notificationDataSource;
  final DetectTravelModeChangeUseCase _detectTravelModeChangeUseCase;

  Future<bool> isEnabled() {
    return _dataSource.isEnabled();
  }

  Future<void> setEnabled(bool value) {
    return _dataSource.setEnabled(value);
  }

  Future<TravelModeUpdateResult> recordLocationUpdateFromLocation(
    PrayerLocation currentLocation,
  ) async {
    final timezone = DateTime.now().timeZoneName;
    final label = await _labelDataSource.resolveLabel(currentLocation);
    final state = await _dataSource.getState();

    final detection = _detectTravelModeChangeUseCase.call(
      enabled: state.enabled,
      currentLocation: currentLocation,
      currentTimezone: timezone,
      previousLocation: state.previousLocation,
      previousTimezone: state.previousTimezone,
    );

    final pendingBanner = detection.travelDetected
        ? TravelPendingBanner(
            label: label,
            distanceKm: detection.distanceKmRounded ?? 0,
          )
        : null;

    if (pendingBanner != null) {
      await _dataSource.setPendingBanner(pendingBanner);
      await _notificationDataSource.showTravelDetected(label);
    }

    await _dataSource.saveCurrentContext(
      label: label,
      timezone: timezone,
    );
    await _dataSource.storeRecentLocation(
      RecentLocation(
        label: label,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        timezone: timezone,
        timestamp: DateTime.now(),
      ),
    );

    return TravelModeUpdateResult(
      label: label,
      travelDetected: detection.travelDetected,
      pendingBanner: pendingBanner,
    );
  }

  Future<TravelModeUpdateResult> recordLocationUpdate(Position position) async {
    return recordLocationUpdateFromLocation(
      PrayerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }

  Future<TravelPendingBanner?> getPendingBanner() {
    return _dataSource.getPendingBanner();
  }

  Future<void> clearPendingBanner() {
    return _dataSource.clearPendingBanner();
  }

  Future<String?> getLastLocationLabel() {
    return _dataSource.getLastLocationLabel();
  }

  Future<List<RecentLocation>> getRecentLocations() {
    return _dataSource.getRecentLocations();
  }
}

final travelModeServiceProvider = Provider<TravelModeService>((ref) {
  return TravelModeService();
});

final travelerModeEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(travelModeServiceProvider).isEnabled();
});

final travelBannerProvider = FutureProvider<String?>((ref) async {
  final languageCode = ref.watch(currentLanguageCodeProvider);
  final pendingBanner = await ref
      .watch(travelModeServiceProvider)
      .getPendingBanner();
  if (pendingBanner == null) {
    return null;
  }

  final l10n = appLocalizationsForLocaleCode(languageCode);
  return l10n.travelModeBannerLocationDetected(
    pendingBanner.label,
    pendingBanner.distanceKm,
  );
});

final recentLocationsProvider = FutureProvider<List<RecentLocation>>((
  ref,
) async {
  return ref.watch(travelModeServiceProvider).getRecentLocations();
});

final lastLocationLabelProvider = FutureProvider<String?>((ref) async {
  return ref.watch(travelModeServiceProvider).getLastLocationLabel();
});
