// lib/features/tracking/services/tracking_service.dart
//
// Gestiona el registro de oraciones completadas.
// Almacena en SharedPreferences como JSON.
//
// Estructura de datos:
// {
//   "2026-03-19": {"fajr": true, "dhuhr": true, "asr": false, "maghrib": false, "isha": false},
//   "2026-03-18": {"fajr": true, "dhuhr": true, "asr": true,  "maghrib": true,  "isha": true},
//   ...
// }

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracking_models.dart';

// ── Providers ──────────────────────────────────────────────────

final prayerTrackingProvider =
    StateNotifierProvider<PrayerTrackingNotifier, TrackingState>((ref) {
  return PrayerTrackingNotifier();
});

// ── Notifier ───────────────────────────────────────────────────

class PrayerTrackingNotifier extends StateNotifier<TrackingState> {
  static const _prefsKey = 'prayer_tracking_data';
  static const _validPrayers = {
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  };

  PrayerTrackingNotifier() : super(TrackingState.empty()) {
    _load();
  }

  // ── Carga inicial ───────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      final data = decoded.map((date, prayers) {
        final map = (prayers as Map<String, dynamic>).map(
          (k, v) => MapEntry(_normalizePrayerKey(k), v as bool),
        );
        return MapEntry(date, map);
      });
      state = TrackingState.fromData(data);
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(state.data));
  }

  // ── Marcar / desmarcar oración ──────────────────────────────

  Future<void> togglePrayer(String prayer, {DateTime? date}) async {
    final key = _dateKey(date ?? DateTime.now());
    final dayData = Map<String, bool>.from(state.data[key] ?? _emptyDay());
    final normalizedPrayer = _normalizePrayerKey(prayer);
    dayData[normalizedPrayer] = !(dayData[normalizedPrayer] ?? false);

    final newData = Map<String, Map<String, bool>>.from(state.data);
    newData[key] = dayData;
    state = TrackingState.fromData(newData);
    await _save();
  }

  bool isPrayerDone(String prayer, {DateTime? date}) {
    final key = _dateKey(date ?? DateTime.now());
    return state.data[key]?[_normalizePrayerKey(prayer)] ?? false;
  }

  // ── Helpers ─────────────────────────────────────────────────

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Map<String, bool> _emptyDay() => {
    'fajr': false, 'dhuhr': false, 'asr': false,
    'maghrib': false, 'isha': false,
  };

  // ── Métodos para compatibilidad con HomeScreen ─────────────

  /// Devuelve la racha actual (para compatibilidad)
  int getStreak() => state.currentStreak;

  /// Devuelve las oraciones completadas para una fecha (para compatibilidad)
  List<String> getCompletedPrayers(DateTime date) {
    final key = _dateKey(date);
    final dayData = state.data[key];
    if (dayData == null) return [];
    return dayData.entries.where((e) => e.value).map((e) => e.key).toList();
  }

  /// Comprueba si una oración está completada en una fecha
  bool isPrayerCompleted(String prayer, DateTime date) {
    final key = _dateKey(date);
    return state.data[key]?[_normalizePrayerKey(prayer)] ?? false;
  }

  static String _normalizePrayerKey(String prayer) {
    final normalized = prayer.trim().toLowerCase();
    if (_validPrayers.contains(normalized)) {
      return normalized;
    }
    return normalized;
  }
}

// ── Estado ─────────────────────────────────────────────────────

class TrackingState {
  final Map<String, Map<String, bool>> data;

  const TrackingState({required this.data});

  factory TrackingState.empty() => const TrackingState(data: {});

  factory TrackingState.fromData(Map<String, Map<String, bool>> data) =>
      TrackingState(data: data);

  List<String> completedPrayersFor(DateTime date) {
    final key = _fmt(date);
    final dayData = data[key];
    if (dayData == null) return const [];
    return dayData.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
  }

  int completedCountFor(DateTime date) => completedPrayersFor(date).length;

  // ── Racha actual ────────────────────────────────────────────

  int get currentStreak {
    int streak = 0;
    var day = DateTime.now();

    // Si hoy no tiene 5/5 todavía, empezar desde ayer
    final todayKey = _fmt(day);
    final todayCount = _countForDay(todayKey);
    if (todayCount < 5) day = day.subtract(const Duration(days: 1));

    while (true) {
      final key = _fmt(day);
      if (_countForDay(key) == 5) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Mejor racha histórica ───────────────────────────────────

  int get bestStreak {
    if (data.isEmpty) return 0;
    int best = 0, current = 0;

    final sortedKeys = data.keys.toList()..sort();
    DateTime? prev;

    for (final key in sortedKeys) {
      final date = DateTime.parse(key);
      final isComplete = _countForDay(key) == 5;
      final isConsecutive = prev != null &&
          date.difference(prev).inDays == 1;

      if (isComplete && (prev == null || isConsecutive)) {
        current++;
        best = current > best ? current : best;
      } else {
        current = isComplete ? 1 : 0;
      }
      prev = isComplete ? date : null;
    }
    return best;
  }

  // ── Heatmap — últimos 30 días ───────────────────────────────

  List<HeatmapDay> get last30Days {
    final result = <HeatmapDay>[];
    for (int i = 29; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _fmt(date);
      result.add(HeatmapDay(
        date: date,
        completed: _countForDay(key),
      ));
    }
    return result;
  }

  // ── Progreso por oración (últimos 30 días) ──────────────────

  Map<String, double> get prayerCompletion {
    const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final counts  = {for (final p in prayers) p: 0};
    int totalDays = 0;

    for (int i = 0; i < 30; i++) {
      final key = _fmt(DateTime.now().subtract(Duration(days: i)));
      if (data.containsKey(key)) {
        totalDays++;
        for (final p in prayers) {
          if (data[key]?[p] == true) counts[p] = (counts[p] ?? 0) + 1;
        }
      }
    }

    if (totalDays == 0) return {for (final p in prayers) p: 0.0};
    return counts.map((p, c) => MapEntry(p, c / totalDays));
  }

  // ── Totales del mes actual ───────────────────────────────────

  MonthlyStats get currentMonthStats {
    final now = DateTime.now();
    int completed = 0, fullDays = 0;

    for (int i = 1; i <= now.day; i++) {
      final date = DateTime(now.year, now.month, i);
      final key  = _fmt(date);
      final count = _countForDay(key);
      completed += count;
      if (count == 5) fullDays++;
    }

    return MonthlyStats(
      month:          now.month,
      year:           now.year,
      prayersCompleted: completed,
      fullDays:       fullDays,
      totalDays:      now.day,
    );
  }

  WeeklySummary get currentWeekSummary {
    final days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      return WeeklyDaySummary(
        date: date,
        completed: _countForDay(_fmt(date)),
      );
    });

    final prayersCompleted = days.fold<int>(
      0,
      (sum, day) => sum + day.completed,
    );
    final strongestDay = days.reduce(
      (best, current) => current.completed >= best.completed ? current : best,
    );
    final weakestDay = days.reduce(
      (worst, current) => current.completed <= worst.completed ? current : worst,
    );

    return WeeklySummary(
      days: days,
      prayersCompleted: prayersCompleted,
      fullDays: days.where((day) => day.completed == 5).length,
      currentStreak: currentStreak,
      strongestDay: strongestDay,
      weakestDay: weakestDay,
    );
  }

  // ── Helpers privados ─────────────────────────────────────────

  int _countForDay(String key) =>
      data[key]?.values.where((v) => v).length ?? 0;

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
