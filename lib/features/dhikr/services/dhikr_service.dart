import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

class DhikrDayStat {
  const DhikrDayStat({
    required this.date,
    required this.count,
  });

  final DateTime date;
  final int count;
}

class DhikrSnapshot {
  const DhikrSnapshot({
    required this.lifetimeTotal,
    required this.todayCount,
    required this.yesterdayCount,
    required this.rollingWeekCount,
    required this.sessionGoal,
    required this.dailyGoal,
    required this.recentDays,
  });

  final int lifetimeTotal;
  final int todayCount;
  final int yesterdayCount;
  final int rollingWeekCount;
  final int sessionGoal;
  final int dailyGoal;
  final List<DhikrDayStat> recentDays;

  bool get dailyGoalReached => todayCount >= dailyGoal;
}

class DhikrService {
  static const int _defaultSessionGoal = 33;
  static const int _defaultDailyGoal = 99;
  static const int _historyWindowDays = 30;

  Future<DhikrSnapshot> loadSnapshot({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    return _buildSnapshot(
      prefs,
      _loadHistory(prefs),
      _normalizeNow(now),
    );
  }

  Future<DhikrSnapshot> increment({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveNow = _normalizeNow(now);
    final history = _loadHistory(prefs);
    final key = _dateKey(effectiveNow);

    history[key] = (history[key] ?? 0) + 1;
    final pruned = _pruneHistory(history, effectiveNow);

    final currentTotal = prefs.getInt(AppConstants.keyDhikrTotalCount) ?? 0;
    await prefs.setInt(AppConstants.keyDhikrTotalCount, currentTotal + 1);
    await prefs.setString(
      AppConstants.keyDhikrDailyHistory,
      jsonEncode(pruned),
    );

    return _buildSnapshot(prefs, pruned, effectiveNow);
  }

  Future<DhikrSnapshot> updateGoals({
    int? sessionGoal,
    int? dailyGoal,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (sessionGoal != null) {
      await prefs.setInt(
        AppConstants.keyDhikrSessionGoal,
        _normalizeGoal(sessionGoal, _defaultSessionGoal),
      );
    }
    if (dailyGoal != null) {
      await prefs.setInt(
        AppConstants.keyDhikrDailyGoal,
        _normalizeGoal(dailyGoal, _defaultDailyGoal),
      );
    }

    return _buildSnapshot(
      prefs,
      _loadHistory(prefs),
      _normalizeNow(now),
    );
  }

  DhikrSnapshot _buildSnapshot(
    SharedPreferences prefs,
    Map<String, int> history,
    DateTime now,
  ) {
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));
    final sessionGoal = _normalizeGoal(
      prefs.getInt(AppConstants.keyDhikrSessionGoal),
      _defaultSessionGoal,
    );
    final dailyGoal = _normalizeGoal(
      prefs.getInt(AppConstants.keyDhikrDailyGoal),
      _defaultDailyGoal,
    );

    final recentDays = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return DhikrDayStat(
        date: day,
        count: history[_dateKey(day)] ?? 0,
      );
    });

    return DhikrSnapshot(
      lifetimeTotal: prefs.getInt(AppConstants.keyDhikrTotalCount) ?? 0,
      todayCount: history[todayKey] ?? 0,
      yesterdayCount: history[yesterdayKey] ?? 0,
      rollingWeekCount: recentDays.fold<int>(
        0,
        (sum, day) => sum + day.count,
      ),
      sessionGoal: sessionGoal,
      dailyGoal: dailyGoal,
      recentDays: recentDays,
    );
  }

  Map<String, int> _loadHistory(SharedPreferences prefs) {
    final raw = prefs.getString(AppConstants.keyDhikrDailyHistory);
    if (raw == null || raw.isEmpty) return <String, int>{};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return <String, int>{};
    }
  }

  Map<String, int> _pruneHistory(Map<String, int> history, DateTime now) {
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: _historyWindowDays - 1));

    return Map<String, int>.fromEntries(
      history.entries.where((entry) {
        final date = DateTime.tryParse(entry.key);
        return date != null && !date.isBefore(cutoff);
      }),
    );
  }

  int _normalizeGoal(int? value, int fallback) {
    if (value == null || value <= 0) return fallback;
    return value;
  }

  DateTime _normalizeNow(DateTime? now) {
    final value = now ?? DateTime.now();
    return DateTime(value.year, value.month, value.day);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

final dhikrServiceProvider = Provider<DhikrService>((ref) {
  return DhikrService();
});

final dhikrSnapshotProvider = FutureProvider.autoDispose<DhikrSnapshot>((
  ref,
) async {
  return ref.watch(dhikrServiceProvider).loadSnapshot();
});
