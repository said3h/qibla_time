import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/l10n.dart';
import '../../prayer_times/domain/entities/ramadan_status.dart';
import '../../prayer_times/presentation/providers/ramadan_providers.dart';
import '../models/achievement.dart';
import '../models/tracking_models.dart';
import 'tracking_service.dart';

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final tracking = ref.watch(prayerTrackingProvider);
  final ramadanStatus = ref.watch(ramadanStatusProvider).valueOrNull;
  return ref.read(achievementServiceProvider).evaluateAchievements(
        tracking,
        ramadanStatus: ramadanStatus,
      );
});

class AchievementService {
  static const _prefsKey = 'qiblatime_achievements';

  Future<List<Achievement>> evaluateAchievements(
    TrackingState tracking, {
    RamadanStatus? ramadanStatus,
  }) async {
    final l10n = appLocalizationsForCurrentLocale();
    final prefs = await SharedPreferences.getInstance();
    final unlockedMap = _decodeUnlockedMap(prefs.getString(_prefsKey));
    final now = DateTime.now();

    final fullDays = tracking.data.values
        .where((prayers) => prayers.values.where((value) => value).length == 5)
        .length;
    final totalPrayers = tracking.totalPrayersCompleted;
    final bestStreak = tracking.bestStreak;
    final ramadanProgress = ramadanStatus?.isEnabled == true ? 1 : 0;

    final achievements = <Achievement>[
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'first_prayer',
        title: l10n.achievementFirstPrayerTitle,
        description: l10n.achievementFirstPrayerDescription,
        icon: Icons.play_circle_outline,
        current: totalPrayers > 0 ? 1 : 0,
        target: 1,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'full_day',
        title: l10n.achievementFullDayTitle,
        description: l10n.achievementFullDayDescription,
        icon: Icons.today_outlined,
        current: fullDays > 0 ? 1 : 0,
        target: 1,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'streak_3',
        title: l10n.achievementStreak3Title,
        description: l10n.achievementStreak3Description,
        icon: Icons.local_fire_department_outlined,
        current: bestStreak,
        target: 3,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'streak_7',
        title: l10n.achievementStreak7Title,
        description: l10n.achievementStreak7Description,
        icon: Icons.workspace_premium_outlined,
        current: bestStreak,
        target: 7,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'streak_30',
        title: l10n.achievementStreak30Title,
        description: l10n.achievementStreak30Description,
        icon: Icons.emoji_events_outlined,
        current: bestStreak,
        target: 30,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'total_100',
        title: l10n.achievementTotal100Title,
        description: l10n.achievementTotal100Description,
        icon: Icons.auto_graph_outlined,
        current: totalPrayers,
        target: 100,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'first_ramadan',
        title: l10n.achievementFirstRamadanTitle,
        description: l10n.achievementFirstRamadanDescription,
        icon: Icons.nightlight_round,
        current: ramadanProgress,
        target: 1,
      ),
    ].map((achievement) {
      if (achievement.isUnlocked && !unlockedMap.containsKey(achievement.id)) {
        unlockedMap[achievement.id] = now.toIso8601String();
        return Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          icon: achievement.icon,
          current: achievement.current,
          target: achievement.target,
          unlockedAt: now,
        );
      }
      return achievement;
    }).toList()
      ..sort((a, b) {
        if (a.isUnlocked == b.isUnlocked) {
          return a.title.compareTo(b.title);
        }
        return a.isUnlocked ? -1 : 1;
      });

    await prefs.setString(_prefsKey, jsonEncode(unlockedMap));
    return achievements;
  }

  Achievement _buildAchievement({
    required Map<String, String> unlockedMap,
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required int current,
    required int target,
  }) {
    final unlockedAt = unlockedMap[id];
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      current: current,
      target: target,
      unlockedAt: unlockedAt == null ? null : DateTime.tryParse(unlockedAt),
    );
  }

  Map<String, String> _decodeUnlockedMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return <String, String>{};
    }
  }
}
