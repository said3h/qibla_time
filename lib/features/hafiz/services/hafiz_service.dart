import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/services/storage_service.dart';
import '../models/hafiz_models.dart';

class HafizService {
  Box get _box => Hive.box(StorageService.hafizBox);

  List<HafizProgress> getProgress() {
    return _box.values
        .whereType<String>()
        .map((item) => HafizProgress.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.surahNumber.compareTo(b.surahNumber));
  }

  Future<void> savePlan(HafizProgress progress) async {
    await _box.put('${progress.surahNumber}', jsonEncode(progress.toJson()));
  }

  Future<void> incrementRepetition(int surahNumber) async {
    final key = '$surahNumber';
    final value = _box.get(key);
    if (value is! String) return;
    final current = HafizProgress.fromJson(jsonDecode(value) as Map<String, dynamic>);
    final updatedCount = (current.completedRepetitions + 1).clamp(0, current.targetRepetitions);
    final nextReview = updatedCount >= current.targetRepetitions
        ? DateTime.now().add(const Duration(days: 2))
        : DateTime.now().add(const Duration(hours: 12));
    await savePlan(current.copyWith(
      completedRepetitions: updatedCount,
      nextReviewAt: nextReview,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> resetPlan(int surahNumber) async {
    await _box.delete('$surahNumber');
  }

  Map<String, dynamic> exportSnapshot() {
    return {
      'plans': getProgress().map((item) => item.toJson()).toList(),
    };
  }

  Future<void> restoreSnapshot(Map<String, dynamic> json) async {
    await _box.clear();
    final plans = (json['plans'] as List<dynamic>? ?? []);
    for (final plan in plans) {
      final progress = HafizProgress.fromJson(plan as Map<String, dynamic>);
      await savePlan(progress);
    }
  }
}

final hafizServiceProvider = Provider<HafizService>((ref) => HafizService());

final hafizProgressProvider = StateProvider<List<HafizProgress>>((ref) {
  return ref.watch(hafizServiceProvider).getProgress();
});
