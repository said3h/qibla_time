import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibla_time/core/services/settings_service.dart';
import 'package:qibla_time/core/services/storage_service.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_calculation_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_location_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_notifications_datasource.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_settings.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/resolved_prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:qibla_time/features/prayer_times/presentation/providers/prayer_times_providers.dart';
import 'package:qibla_time/features/prayer_times/services/adhan_manager.dart';
import 'package:qibla_time/features/prayer_times/services/notification_service.dart';
import 'package:qibla_time/features/tracking/services/weekly_summary_notification_service.dart';

class _Location extends PrayerLocationDataSource {
  @override
  Future<bool> hasManualLocation() async => true;
}

class _Schedule implements GetPrayerScheduleUseCase {
  DateTime date = DateTime(2099, 12, 29);

  @override
  Future<ResolvedPrayerSchedule?> call() async {
    const location = PrayerLocation(latitude: 40.4168, longitude: -3.7038);
    const settings = PrayerSettings(
      method: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
      timeOffsetMinutes: 0,
      fajrAngle: 18,
      ishaAngle: 17,
      methodName: 'MWL',
    );
    return ResolvedPrayerSchedule(
      location: location,
      settings: settings,
      schedule: PrayerCalculationDataSource().calculate(
        location: location,
        settings: settings,
        now: date,
      ),
      fromCache: false,
    );
  }
}

class _Summary extends WeeklySummaryNotificationService {
  @override
  Future<void> scheduleWeeklySummaryNotification() async {}
}

class _Notifications implements NotificationService {
  final active = <int, DateTime>{};
  final attempted = <int>[];
  bool exactAllowed = true;
  int? failId;
  int cancellations = 0;

  @override
  Future<void> cancelPrayerNotifications() async {
    cancellations++;
    active.clear();
  }

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> canScheduleExactAdhanAlarms() async => exactAllowed;

  @override
  Future<AdhanScheduleResult> scheduleAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledAt,
    required String adhanFile,
  }) async {
    attempted.add(id);
    if (id == failId) throw StateError('Alarm scheduling failed');
    if (!exactAllowed) return AdhanScheduleResult.exactAlarmPermissionRequired;
    active[id] = scheduledAt;
    return AdhanScheduleResult.scheduled;
  }

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late _Notifications notifications;
  late _Schedule schedule;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetPrefsForTesting();
    notifications = _Notifications();
    schedule = _Schedule();
    container = ProviderContainer(overrides: [
      prayerLocationDataSourceProvider.overrideWithValue(_Location()),
      getPrayerScheduleUseCaseProvider.overrideWithValue(schedule),
      prayerNotificationsDataSourceProvider.overrideWithValue(
        PrayerNotificationsDataSource(notificationService: notifications),
      ),
      weeklySummaryNotificationServiceProvider.overrideWithValue(_Summary()),
    ]);
  });

  tearDown(() {
    container.dispose();
    StorageService.resetPrefsForTesting();
  });

  test('schedules six calendar days with distinct IDs across year boundary',
      () async {
    await container.read(adhanManagerProvider).scheduleTodayAdhans();
    expect(
        notifications.active.keys, orderedEquals(List.generate(30, (i) => i)));
    for (var day = 0; day < 6; day++) {
      final expected = DateTime(2099, 12, 29 + day);
      final actual = notifications.active[day * 5]!;
      expect(DateTime(actual.year, actual.month, actual.day), expected);
    }
    expect(notifications.cancellations, 1);
  });

  test('renewing next day replaces the window instead of duplicating alarms',
      () async {
    final manager = container.read(adhanManagerProvider);
    await manager.scheduleTodayAdhans();
    final previousFajr = notifications.active[0];
    schedule.date = DateTime(2099, 12, 30);
    await manager.scheduleTodayAdhans();
    expect(notifications.active.length, 30);
    expect(notifications.active[0], isNot(previousFajr));
    expect(notifications.cancellations, 2);
  });

  test('disabling one prayer excludes it from every day', () async {
    await SettingsService.instance.savePrayerNotificationEnabled('asr', false);
    await container.read(adhanManagerProvider).scheduleTodayAdhans();
    expect(notifications.active.length, 24);
    for (var day = 0; day < 6; day++) {
      expect(notifications.active.containsKey(day * 5 + 2), isFalse);
    }
  });

  test('global disable cancels the previous window without scheduling',
      () async {
    final manager = container.read(adhanManagerProvider);
    await manager.scheduleTodayAdhans();
    await SettingsService.instance.saveNotificationsEnabled(false);
    notifications.attempted.clear();
    await manager.scheduleTodayAdhans();
    expect(notifications.active, isEmpty);
    expect(notifications.attempted, isEmpty);
  });

  test('exact permission denial never becomes a scheduled adhan', () async {
    notifications.exactAllowed = false;
    await container.read(adhanManagerProvider).scheduleTodayAdhans();
    expect(notifications.attempted.length, 30);
    expect(notifications.active, isEmpty);
  });

  test('one failed alarm does not prevent the remaining days', () async {
    notifications.failId = 7;
    await container.read(adhanManagerProvider).scheduleTodayAdhans();
    expect(notifications.active.length, 29);
    expect(notifications.active.containsKey(29), isTrue);
  });
}
