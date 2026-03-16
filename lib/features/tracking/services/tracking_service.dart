import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:convert';

// Provider for tracking completed prayers
final prayerTrackingProvider = StateNotifierProvider<PrayerTrackingNotifier, Map<String, List<String>>>((ref) {
  return PrayerTrackingNotifier();
});

class PrayerTrackingNotifier extends StateNotifier<Map<String, List<String>>> {
  PrayerTrackingNotifier() : super({}) {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(AppConstants.keyMarkedPrayers);
    if (data != null) {
      final Map<String, dynamic> decoded = json.decode(data);
      state = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
    }
  }

  Future<void> togglePrayer(DateTime date, String prayerName) async {
    final dateKey = "${date.year}-${date.month}-${date.day}";
    final currentList = List<String>.from(state[dateKey] ?? []);
    
    if (currentList.contains(prayerName)) {
      currentList.remove(prayerName);
    } else {
      currentList.add(prayerName);
    }

    final newState = {...state, dateKey: currentList};
    state = newState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMarkedPrayers, json.encode(newState));
  }

  int getStreak() {
    int streak = 0;
    DateTime date = DateTime.now();
    
    while (true) {
      final dateKey = "${date.year}-${date.month}-${date.day}";
      final list = state[dateKey] ?? [];
      // If all 5 prayers (Fajr, Dhuhr, Asr, Maghrib, Isha) are done
      if (list.length >= 5) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
