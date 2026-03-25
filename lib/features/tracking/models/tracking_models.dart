// lib/features/tracking/models/tracking_models.dart

class HeatmapDay {
  final DateTime date;
  final int completed; // 0-5 oraciones completadas

  const HeatmapDay({required this.date, required this.completed});

  double get ratio => completed / 5.0;

  bool get isFull    => completed == 5;
  bool get isEmpty   => completed == 0;
  bool get isPartial => completed > 0 && completed < 5;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class MonthlyStats {
  final int month;
  final int year;
  final int prayersCompleted;  // total de oraciones marcadas
  final int fullDays;          // días con las 5 oraciones
  final int totalDays;         // días transcurridos en el mes

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.prayersCompleted,
    required this.fullDays,
    required this.totalDays,
  });

  // Máximo posible = 5 oraciones × días transcurridos
  int get maxPossible => totalDays * 5;

  double get completionRate =>
      maxPossible == 0 ? 0.0 : prayersCompleted / maxPossible;

  String get monthName {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return names[month];
  }
}

class WeeklyDaySummary {
  const WeeklyDaySummary({
    required this.date,
    required this.completed,
  });

  final DateTime date;
  final int completed;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String get shortLabel {
    const labels = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return labels[date.weekday - 1];
  }
}

class WeeklySummary {
  const WeeklySummary({
    required this.days,
    required this.prayersCompleted,
    required this.fullDays,
    required this.currentStreak,
    required this.strongestDay,
    required this.weakestDay,
  });

  final List<WeeklyDaySummary> days;
  final int prayersCompleted;
  final int fullDays;
  final int currentStreak;
  final WeeklyDaySummary strongestDay;
  final WeeklyDaySummary weakestDay;

  int get maxPossible => days.length * 5;

  double get completionRate =>
      maxPossible == 0 ? 0.0 : prayersCompleted / maxPossible;

  bool get hasAnyActivity => prayersCompleted > 0;

  String get interpretation {
    if (!hasAnyActivity) {
      return 'Empieza marcando tus oraciones y veras aqui tu semana.';
    }
    if (completionRate >= 0.85) {
      return 'Semana muy solida. Has mantenido una constancia excelente.';
    }
    if (completionRate >= 0.6) {
      return 'Buen ritmo esta semana. Un pequeno empujon te acerca al 5/5.';
    }
    return 'Cada oracion cuenta. Intenta cerrar fuerte los proximos dias.';
  }
}

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
    return dayData.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  int completedCountFor(DateTime date) => completedPrayersFor(date).length;

  int get currentStreak {
    var streak = 0;
    var day = DateTime.now();

    final todayKey = _fmt(day);
    final todayCount = _countForDay(todayKey);
    if (todayCount < 5) {
      day = day.subtract(const Duration(days: 1));
    }

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

  int get bestStreak {
    if (data.isEmpty) return 0;
    var best = 0;
    var current = 0;

    final sortedKeys = data.keys.toList()..sort();
    DateTime? previousDate;

    for (final key in sortedKeys) {
      final date = DateTime.parse(key);
      final isComplete = _countForDay(key) == 5;
      final isConsecutive =
          previousDate != null && date.difference(previousDate).inDays == 1;

      if (isComplete && (previousDate == null || isConsecutive)) {
        current++;
        if (current > best) {
          best = current;
        }
      } else {
        current = isComplete ? 1 : 0;
      }

      previousDate = isComplete ? date : null;
    }

    return best;
  }

  List<HeatmapDay> get last30Days {
    final result = <HeatmapDay>[];
    for (var index = 29; index >= 0; index--) {
      final date = DateTime.now().subtract(Duration(days: index));
      final key = _fmt(date);
      result.add(
        HeatmapDay(
          date: date,
          completed: _countForDay(key),
        ),
      );
    }
    return result;
  }

  Map<String, double> get prayerCompletion {
    const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final counts = {for (final prayer in prayers) prayer: 0};
    var totalDays = 0;

    for (var index = 0; index < 30; index++) {
      final key = _fmt(DateTime.now().subtract(Duration(days: index)));
      if (data.containsKey(key)) {
        totalDays++;
        for (final prayer in prayers) {
          if (data[key]?[prayer] == true) {
            counts[prayer] = (counts[prayer] ?? 0) + 1;
          }
        }
      }
    }

    if (totalDays == 0) {
      return {for (final prayer in prayers) prayer: 0.0};
    }

    return counts.map(
      (prayer, count) => MapEntry(prayer, count / totalDays),
    );
  }

  MonthlyStats get currentMonthStats {
    final now = DateTime.now();
    var completed = 0;
    var fullDays = 0;

    for (var day = 1; day <= now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final key = _fmt(date);
      final count = _countForDay(key);
      completed += count;
      if (count == 5) {
        fullDays++;
      }
    }

    return MonthlyStats(
      month: now.month,
      year: now.year,
      prayersCompleted: completed,
      fullDays: fullDays,
      totalDays: now.day,
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

    final prayersCompleted =
        days.fold<int>(0, (sum, day) => sum + day.completed);
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

  int _countForDay(String key) =>
      data[key]?.values.where((value) => value).length ?? 0;

  static String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
