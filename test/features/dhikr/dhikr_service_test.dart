import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/core/constants/app_constants.dart';
import 'package:qibla_time/features/dhikr/services/dhikr_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DhikrService', () {
    late DhikrService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = DhikrService();
    });

    test('increment suma total e historial del dia', () async {
      final now = DateTime(2026, 3, 25);

      final snapshot = await service.increment(now: now);

      expect(snapshot.todayCount, 1);
      expect(snapshot.lifetimeTotal, 1);
      expect(snapshot.rollingWeekCount, 1);
      expect(snapshot.recentDays.last.count, 1);
    });

    test('loadSnapshot calcula hoy, ayer y semana desde el historial', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyDhikrTotalCount: 42,
        AppConstants.keyDhikrSessionGoal: 50,
        AppConstants.keyDhikrDailyGoal: 120,
        AppConstants.keyDhikrDailyHistory: jsonEncode({
          '2026-03-20': 7,
          '2026-03-24': 11,
          '2026-03-25': 9,
        }),
      });
      service = DhikrService();

      final snapshot = await service.loadSnapshot(
        now: DateTime(2026, 3, 25),
      );

      expect(snapshot.lifetimeTotal, 42);
      expect(snapshot.sessionGoal, 50);
      expect(snapshot.dailyGoal, 120);
      expect(snapshot.todayCount, 9);
      expect(snapshot.yesterdayCount, 11);
      expect(snapshot.rollingWeekCount, 27);
    });
  });
}
