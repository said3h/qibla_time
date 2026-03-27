import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/resolved_prayer_schedule.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/usecases/find_invalid_prayer_cache_entries.dart';
import '../../domain/usecases/select_prayer_schedule_source.dart';
import '../datasources/prayer_cache_datasource.dart';
import '../datasources/prayer_calculation_datasource.dart';
import '../datasources/prayer_location_datasource.dart';
import '../datasources/prayer_settings_datasource.dart';
import '../datasources/prayer_widget_datasource.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  PrayerTimesRepositoryImpl({
    required PrayerLocationDataSource locationDataSource,
    required PrayerSettingsDataSource settingsDataSource,
    required PrayerCacheDataSource cacheDataSource,
    required PrayerCalculationDataSource calculationDataSource,
    required PrayerWidgetDataSource widgetDataSource,
    SelectPrayerScheduleSourceUseCase? selectSourceUseCase,
    FindInvalidPrayerCacheEntriesUseCase? findInvalidEntriesUseCase,
  })  : _locationDataSource = locationDataSource,
        _settingsDataSource = settingsDataSource,
        _cacheDataSource = cacheDataSource,
        _calculationDataSource = calculationDataSource,
        _widgetDataSource = widgetDataSource,
        _selectSourceUseCase =
            selectSourceUseCase ?? const SelectPrayerScheduleSourceUseCase(),
        _findInvalidEntriesUseCase =
            findInvalidEntriesUseCase ??
            const FindInvalidPrayerCacheEntriesUseCase();

  final PrayerLocationDataSource _locationDataSource;
  final PrayerSettingsDataSource _settingsDataSource;
  final PrayerCacheDataSource _cacheDataSource;
  final PrayerCalculationDataSource _calculationDataSource;
  final PrayerWidgetDataSource _widgetDataSource;
  final SelectPrayerScheduleSourceUseCase _selectSourceUseCase;
  final FindInvalidPrayerCacheEntriesUseCase _findInvalidEntriesUseCase;

  @override
  Future<PrayerLocation?> getCurrentLocation() {
    return _locationDataSource.getCurrentLocation();
  }

  @override
  Future<ResolvedPrayerSchedule?> getCurrentSchedule() async {
    return _getScheduleFor(DateTime.now(), syncWidget: true);
  }

  @override
  Future<ResolvedPrayerSchedule?> getScheduleForDate(DateTime date) async {
    return _getScheduleFor(date, syncWidget: false);
  }

  Future<ResolvedPrayerSchedule?> _getScheduleFor(
    DateTime reference, {
    required bool syncWidget,
  }) async {
    final location = await _locationDataSource.getCurrentLocation();
    if (location == null) {
      return null;
    }
    await _locationDataSource.persistLastKnownLocation(location);

    final settings = await _settingsDataSource.getSettings();
    final cachedSchedule = await _cacheDataSource.getFor(location, reference);
    final source = _selectSourceUseCase.call(
      cachedSchedule: cachedSchedule,
      currentLocation: location,
      now: reference,
    );

    if (source == PrayerScheduleSource.cache && cachedSchedule != null) {
      if (syncWidget) {
        await _widgetDataSource.sync(cachedSchedule.schedule);
      }
      return ResolvedPrayerSchedule(
        location: location,
        settings: settings,
        schedule: cachedSchedule.schedule,
        fromCache: true,
      );
    }

    final calculated = _calculationDataSource.calculate(
      location: location,
      settings: settings,
      now: reference,
    );
    await _cacheDataSource.save(location: location, schedule: calculated);
    if (syncWidget) {
      await _widgetDataSource.sync(calculated);
    }
    return ResolvedPrayerSchedule(
      location: location,
      settings: settings,
      schedule: calculated,
      fromCache: false,
    );
  }

  @override
  Future<void> invalidateCacheForLocation(
    PrayerLocation location, {
    double kmThreshold = 50,
  }) async {
    final entries = await _cacheDataSource.getAll();
    final keys = _findInvalidEntriesUseCase.call(
      entries: entries,
      currentLocation: location,
      now: DateTime.now(),
      kmThreshold: kmThreshold,
    );
    await _cacheDataSource.deleteAll(keys);
  }
}
