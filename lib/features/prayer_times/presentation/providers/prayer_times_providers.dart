import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan/adhan.dart';

import '../../data/datasources/prayer_cache_datasource.dart';
import '../../data/datasources/prayer_calculation_datasource.dart';
import '../../data/datasources/prayer_location_datasource.dart';
import '../../data/datasources/prayer_notifications_datasource.dart';
import '../../data/datasources/prayer_settings_datasource.dart';
import '../../data/datasources/prayer_widget_datasource.dart';
import '../../data/repositories/prayer_notifications_repository_impl.dart';
import '../../data/repositories/prayer_times_repository_impl.dart';
import '../../domain/entities/next_prayer_info.dart';
import '../../domain/entities/prayer_cache_status.dart';
import '../../domain/entities/prayer_location.dart';
import '../../domain/entities/prayer_location_diagnostic.dart';
import '../../domain/entities/resolved_prayer_schedule.dart';
import '../../domain/repositories/prayer_notifications_repository.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../../domain/usecases/get_next_prayer_info.dart';
import '../../domain/usecases/get_prayer_schedule.dart';
import '../../domain/usecases/reschedule_prayer_notifications.dart';

final prayerLocationDataSourceProvider = Provider<PrayerLocationDataSource>((ref) {
  return PrayerLocationDataSource();
});

final prayerSettingsDataSourceProvider =
    Provider<PrayerSettingsDataSource>((ref) {
  return PrayerSettingsDataSource();
});

final prayerCacheDataSourceProvider = Provider<PrayerCacheDataSource>((ref) {
  return PrayerCacheDataSource();
});

final prayerCalculationDataSourceProvider =
    Provider<PrayerCalculationDataSource>((ref) {
  return PrayerCalculationDataSource();
});

final prayerWidgetDataSourceProvider = Provider<PrayerWidgetDataSource>((ref) {
  return PrayerWidgetDataSource();
});

final prayerNotificationsDataSourceProvider =
    Provider<PrayerNotificationsDataSource>((ref) {
  return PrayerNotificationsDataSource();
});

final prayerLocationProvider = FutureProvider<PrayerLocation?>((ref) async {
  final accessResult = await ref.watch(prayerLocationDataSourceProvider).getLocation();
  return accessResult?.location;
});

final prayerLocationDiagnosticProvider =
    FutureProvider<PrayerLocationDiagnostic>((ref) async {
  return ref.watch(prayerLocationDataSourceProvider).getDiagnostic();
});

final prayerCalculationMethodProvider =
    FutureProvider<CalculationMethod>((ref) async {
  final settings = await ref.watch(prayerSettingsDataSourceProvider).getSettings();
  return settings.method;
});

final prayerMadhabProvider = FutureProvider<Madhab>((ref) async {
  final settings = await ref.watch(prayerSettingsDataSourceProvider).getSettings();
  return settings.madhab;
});

final prayerTimeOffsetProvider = FutureProvider<int>((ref) async {
  final settings = await ref.watch(prayerSettingsDataSourceProvider).getSettings();
  return settings.timeOffsetMinutes;
});

final prayerTimesRepositoryProvider = Provider<PrayerTimesRepository>((ref) {
  return PrayerTimesRepositoryImpl(
    locationDataSource: ref.watch(prayerLocationDataSourceProvider),
    settingsDataSource: ref.watch(prayerSettingsDataSourceProvider),
    cacheDataSource: ref.watch(prayerCacheDataSourceProvider),
    calculationDataSource: ref.watch(prayerCalculationDataSourceProvider),
    widgetDataSource: ref.watch(prayerWidgetDataSourceProvider),
  );
});

final prayerNotificationsRepositoryProvider =
    Provider<PrayerNotificationsRepository>((ref) {
  return PrayerNotificationsRepositoryImpl(
    ref.watch(prayerNotificationsDataSourceProvider),
  );
});

final getPrayerScheduleUseCaseProvider = Provider<GetPrayerScheduleUseCase>((ref) {
  return GetPrayerScheduleUseCase(ref.watch(prayerTimesRepositoryProvider));
});

final getNextPrayerInfoUseCaseProvider =
    Provider<GetNextPrayerInfoUseCase>((ref) {
  return const GetNextPrayerInfoUseCase();
});

final reschedulePrayerNotificationsUseCaseProvider =
    Provider<ReschedulePrayerNotificationsUseCase>((ref) {
  return ReschedulePrayerNotificationsUseCase(
    ref.watch(prayerNotificationsRepositoryProvider),
  );
});

final prayerCacheStatusProvider = Provider<PrayerCacheStatus>((ref) {
  return ref.watch(prayerCacheDataSourceProvider).getStatus();
});

final prayerNotificationsEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(prayerNotificationsDataSourceProvider).areNotificationsEnabled();
});

final systemNotificationPermissionProvider = FutureProvider<bool>((ref) async {
  return ref.watch(prayerNotificationsDataSourceProvider).isSystemPermissionGranted();
});

final prayerScheduleProvider = FutureProvider<ResolvedPrayerSchedule?>((ref) async {
  return ref.watch(getPrayerScheduleUseCaseProvider).call();
});

final prayerScheduleForDateProvider =
    FutureProvider.family<ResolvedPrayerSchedule?, DateTime>((ref, date) async {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      return ref
          .watch(prayerTimesRepositoryProvider)
          .getScheduleForDate(normalizedDate);
    });

final nextPrayerInfoProvider = Provider<NextPrayerInfo?>((ref) {
  final resolvedSchedule = ref.watch(prayerScheduleProvider).valueOrNull;
  if (resolvedSchedule == null) {
    return null;
  }

  return ref.watch(getNextPrayerInfoUseCaseProvider).call(
        resolvedSchedule.schedule,
      );
});

final prayerCountdownProvider = StreamProvider<Duration?>((ref) async* {
  yield _readCountdown(ref);
  yield* Stream.periodic(const Duration(seconds: 1), (_) => _readCountdown(ref));
});

Duration? _readCountdown(Ref ref) {
  final resolvedSchedule = ref.read(prayerScheduleProvider).valueOrNull;
  if (resolvedSchedule == null) {
    return null;
  }
  final nextPrayer = ref.read(getNextPrayerInfoUseCaseProvider).call(
        resolvedSchedule.schedule,
        now: DateTime.now(),
      );
  if (nextPrayer == null) {
    return null;
  }
  return nextPrayer.remaining.isNegative ? Duration.zero : nextPrayer.remaining;
}
