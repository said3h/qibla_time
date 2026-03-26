import 'package:flutter/material.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.current,
    required this.target,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int current;
  final int target;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null || current >= target;

  double get progressRatio {
    if (target <= 0) return isUnlocked ? 1 : 0;
    final ratio = current / target;
    return ratio.clamp(0, 1).toDouble();
  }

  String get progressLabel {
    if (isUnlocked) return 'Desbloqueado';
    return '$current/$target';
  }
}
