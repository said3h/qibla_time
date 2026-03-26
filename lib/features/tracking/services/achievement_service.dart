import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        title: 'Primera oracion',
        description: 'Marca tu primera oracion completada.',
        icon: Icons.play_circle_outline,
        current: totalPrayers > 0 ? 1 : 0,
        target: 1,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'full_day',
        title: 'Dia completo',
        description: 'Completa las 5 oraciones en un mismo dia.',
        icon: Icons.today_outlined,
        current: fullDays > 0 ? 1 : 0,
        target: 1,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'streak_3',
        title: '3 dias seguidos',
        description: 'Manten una racha de 3 dias completos.',
        icon: Icons.local_fire_department_outlined,
        current: bestStreak,
        target: 3,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'streak_7',
        title: '7 dias seguidos',
        description: 'Manten una racha de 7 dias completos.',
        icon: Icons.workspace_premium_outlined,
        current: bestStreak,
        target: 7,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'streak_30',
        title: '30 dias seguidos',
        description: 'Manten una racha de 30 dias completos.',
        icon: Icons.emoji_events_outlined,
        current: bestStreak,
        target: 30,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'total_100',
        title: '100 oraciones',
        description: 'Acumula 100 oraciones completadas.',
        icon: Icons.auto_graph_outlined,
        current: totalPrayers,
        target: 100,
      ),
      _buildAchievement(
        unlockedMap: unlockedMap,
        id: 'first_ramadan',
        title: 'Primer Ramadan activo',
        description: 'Activa QiblaTime durante Ramadan.',
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
