import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibla_time/core/constants/app_constants.dart';
import 'package:qibla_time/core/services/storage_service.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_cache_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_calculation_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_location_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_settings_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/datasources/prayer_widget_datasource.dart';
import 'package:qibla_time/features/prayer_times/data/repositories/prayer_times_repository_impl.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_location.dart';
import 'package:qibla_time/features/prayer_times/domain/entities/prayer_schedule.dart';

class _Location extends PrayerLocationDataSource {
  bool failPersistence = false;

  @override
  Future<PrayerLocation?> getCurrentLocation() async =>
      const PrayerLocation(latitude: 40.4168, longitude: -3.7038);

  @override
  Future<void> persistLastKnownLocation(PrayerLocation location) async {
    if (failPersistence) throw StateError('Storage unavailable');
  }
}

class _Widget extends PrayerWidgetDataSource {
  bool fail = false;
  int calls = 0;

  @override
  Future<void> sync(PrayerSchedule schedule) async {
    calls++;
    if (fail) throw StateError('Widget unavailable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box box;
  late _Location location;
  late _Widget widget;
  late PrayerCacheDataSource cache;
  late PrayerSettingsDataSource settings;
  late PrayerTimesRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory =
        await Directory.systemTemp.createTemp('prayer_repository_test_');
    Hive.init(directory.path);
    box = await Hive.openBox(StorageService.prayerCacheBox);
    location = _Location();
    widget = _Widget();
    cache = PrayerCacheDataSource();
    settings = PrayerSettingsDataSource();
    repository = PrayerTimesRepositoryImpl(
      locationDataSource: location,
      settingsDataSource: settings,
      cacheDataSource: cache,
      calculationDataSource: PrayerCalculationDataSource(),
      widgetDataSource: widget,
    );
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final setting in ['method', 'madhab', 'offset']) {
    test('recalculates after changing $setting with same-day cache', () async {
      final date = DateTime(2026, 4, 5, 12);
      final before = (await repository.getScheduleForDate(date))!;
      expect((await repository.getScheduleForDate(date))!.fromCache, isTrue);
      final prefs = await SharedPreferences.getInstance();
      switch (setting) {
        case 'method':
          await prefs.setInt(AppConstants.keyCalculationMethod,
              CalculationMethod.egyptian.index);
        case 'madhab':
          await prefs.setBool('madhab_hanafi', true);
        case 'offset':
          await prefs.setInt('time_offset', 10);
      }
      final after = (await repository.getScheduleForDate(date))!;
      expect(after.fromCache, isFalse);
      if (setting == 'method') {
        expect(after.schedule.fajr, isNot(before.schedule.fajr));
      } else if (setting == 'madhab') {
        expect(after.schedule.asr.isAfter(before.schedule.asr), isTrue);
      } else {
        expect(after.schedule.fajr.difference(before.schedule.fajr),
            const Duration(minutes: 10));
      }
      expect((await repository.getScheduleForDate(date))!.fromCache, isTrue);
    });
  }

  test('yesterday cache is not reused for today', () async {
    await repository.getScheduleForDate(DateTime(2026, 4, 5));
    final today = (await repository.getScheduleForDate(DateTime(2026, 4, 6)))!;
    expect(today.fromCache, isFalse);
    expect(today.schedule.date, DateTime(2026, 4, 6));
  });

  test('legacy entries remain stored but are not used', () async {
    const key = 'prayers_40.42_-3.70_2026-4-5';
    await box.put(key, 'legacy entry without settings');
    final result = (await repository.getScheduleForDate(DateTime(2026, 4, 5)))!;
    expect(result.fromCache, isFalse);
    expect(box.get(key), 'legacy entry without settings');
  });

  test('widget failure preserves both calculated and cached schedules',
      () async {
    widget.fail = true;
    final first = (await repository.getCurrentSchedule())!;
    final second = (await repository.getCurrentSchedule())!;
    expect(first.fromCache, isFalse);
    expect(second.fromCache, isTrue);
    expect(second.schedule.fajr, first.schedule.fajr);
    expect(widget.calls, 2);
  });

  test('unavailable cache does not prevent calculation or widget sync',
      () async {
    await box.close();
    final result = (await repository.getCurrentSchedule())!;
    expect(result.fromCache, isFalse);
    expect(result.schedule.times.length, 5);
    expect(widget.calls, 1);
  });

  test('corrupted cache is recalculated', () async {
    final date = DateTime(2026, 4, 5);
    final key = cache.buildKey((await location.getCurrentLocation())!, date,
        await settings.getSettings());
    await box.put(key, '{invalid');
    expect((await repository.getScheduleForDate(date))!.fromCache, isFalse);
    expect((await repository.getScheduleForDate(date))!.fromCache, isTrue);
  });

  test('location persistence failure keeps available coordinates usable',
      () async {
    location.failPersistence = true;
    final result = (await repository.getCurrentSchedule())!;
    expect(result.location.latitude, 40.4168);
    expect(result.schedule.times.length, 5);
  });
}
