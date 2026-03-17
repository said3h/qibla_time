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
      if (list.length >= 5) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, double> getPrayerStats() {
    if (state.isEmpty) return {};
    
    final Map<String, int> counts = {
      'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0
    };
    
    int totalDays = state.length;
    for (var prayers in state.values) {
      for (var prayer in prayers) {
        if (counts.containsKey(prayer)) {
          counts[prayer] = counts[prayer]! + 1;
        }
      }
    }
    
    return counts.map((key, value) => MapEntry(key, value / totalDays));
  }

  Map<String, double> getMonthlyStats() {
    if (state.isEmpty) return {};
    
    final Map<String, List<int>> monthlyData = {};
    
    state.forEach((dateKey, prayers) {
      final parts = dateKey.split('-');
      final monthKey = "${parts[0]}-${parts[1]}"; // YYYY-MM
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = [0, 0]; // [completed, total_possible]
      }
      
      monthlyData[monthKey]![0] += prayers.length;
      monthlyData[monthKey]![1] += 5;
    });
    
    return monthlyData.map((key, value) => MapEntry(key, value[0] / value[1]));
  }
}
