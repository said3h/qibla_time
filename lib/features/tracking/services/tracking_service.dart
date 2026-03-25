import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tracking_models.dart';

final prayerTrackingProvider =
    StateNotifierProvider<PrayerTrackingNotifier, TrackingState>((ref) {
  return PrayerTrackingNotifier();
});

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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final data = decoded.map((date, prayers) {
        final map = (prayers as Map<String, dynamic>).map(
          (key, value) => MapEntry(_normalizePrayerKey(key), value as bool),
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

  int getStreak() => state.currentStreak;

  List<String> getCompletedPrayers(DateTime date) {
    final key = _dateKey(date);
    final dayData = state.data[key];
    if (dayData == null) return [];
    return dayData.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
  }

  bool isPrayerCompleted(String prayer, DateTime date) {
    final key = _dateKey(date);
    return state.data[key]?[_normalizePrayerKey(prayer)] ?? false;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Map<String, bool> _emptyDay() => {
    'fajr': false,
    'dhuhr': false,
    'asr': false,
    'maghrib': false,
    'isha': false,
  };

  static String _normalizePrayerKey(String prayer) {
    final normalized = prayer.trim().toLowerCase();
    if (_validPrayers.contains(normalized)) {
      return normalized;
    }
    return normalized;
  }
}
