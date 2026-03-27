import '../entities/home_insight.dart';
import '../entities/ramadan_status.dart';
import '../../../tracking/models/tracking_models.dart';

class GenerateHomeInsightsUseCase {
  const GenerateHomeInsightsUseCase();

  HomeInsightBundle call({
    required TrackingState tracking,
    required WeeklySummary weeklySummary,
    required DateTime now,
    RamadanStatus? ramadanStatus,
    int? dhikrTodayCount,
    int? dhikrDailyGoal,
  }) {
    final candidates = <HomeInsight>[];
    final prayerCountToday = tracking.completedCountFor(now);
    final activeDays = tracking.data.values
        .where((day) => day.values.any((completed) => completed))
        .length;

    final todayInsight = _todayProgressInsight(prayerCountToday, now);
    if (todayInsight != null) {
      candidates.add(todayInsight);
    }

    final streakInsight = _streakInsight(tracking.currentStreak);
    if (streakInsight != null) {
      candidates.add(streakInsight);
    }

    final improvementInsight = _improvementInsight(tracking, now);
    if (improvementInsight != null) {
      candidates.add(improvementInsight);
    }

    final prayerPatternInsight = _prayerPatternInsight(
      tracking,
      activeDays: activeDays,
    );
    if (prayerPatternInsight != null) {
      candidates.add(prayerPatternInsight);
    }

    final dhikrInsight = _dhikrInsight(
      todayCount: dhikrTodayCount,
      dailyGoal: dhikrDailyGoal,
    );
    if (dhikrInsight != null) {
      candidates.add(dhikrInsight);
    }

    final ramadanInsight = _ramadanInsight(
      ramadanStatus: ramadanStatus,
      weeklySummary: weeklySummary,
      prayerCountToday: prayerCountToday,
    );
    if (ramadanInsight != null) {
      candidates.add(ramadanInsight);
    }

    if (candidates.isEmpty) {
      candidates.add(
        HomeInsight(
          kind: HomeInsightKind.guidance,
          title: 'Empieza hoy',
          message: activeDays == 0
              ? 'Marca tus primeras oraciones y la app empezará a mostrar patrones útiles.'
              : 'Sigue marcando tus oraciones y verás insights más precisos en Inicio.',
        ),
      );
    }

    final primary = candidates.first;
    final secondaryCandidates = candidates
        .skip(1)
        .where((insight) => insight.kind != primary.kind)
        .toList();
    final secondary = secondaryCandidates.isEmpty
        ? null
        : secondaryCandidates[now.day % secondaryCandidates.length];

    return HomeInsightBundle(
      primary: primary,
      secondary: secondary,
    );
  }

  HomeInsight? _todayProgressInsight(int prayerCountToday, DateTime now) {
    if (prayerCountToday == 4) {
      return const HomeInsight(
        kind: HomeInsightKind.progress,
        title: 'Casi completas hoy',
        message: 'Te falta 1 oración para cerrar el 5/5 de hoy.',
      );
    }
    if (prayerCountToday > 0 && prayerCountToday < 4) {
      return HomeInsight(
        kind: HomeInsightKind.progress,
        title: 'Buen ritmo hoy',
        message: 'Llevas $prayerCountToday/5 oraciones marcadas. Mantener el impulso cuenta.',
      );
    }
    if (prayerCountToday == 0 && now.hour >= 12) {
      return const HomeInsight(
        kind: HomeInsightKind.progress,
        title: 'Todavía puedes empezar',
        message: 'Aún no has marcado oraciones hoy. Empezar por la siguiente ya cambia el día.',
      );
    }
    return null;
  }

  HomeInsight? _streakInsight(int streak) {
    if (streak >= 2) {
      return HomeInsight(
        kind: HomeInsightKind.streak,
        title: 'Racha en marcha',
        message: 'Llevas una racha de $streak días completos. Protégela hoy.',
      );
    }
    return null;
  }

  HomeInsight? _improvementInsight(TrackingState tracking, DateTime now) {
    final currentWeek = _completedPrayersInWindow(
      tracking,
      endDate: now,
      days: 7,
    );
    final previousWeek = _completedPrayersInWindow(
      tracking,
      endDate: now.subtract(const Duration(days: 7)),
      days: 7,
    );

    if (previousWeek == 0) {
      return null;
    }

    final delta = currentWeek - previousWeek;
    if (delta >= 4) {
      return HomeInsight(
        kind: HomeInsightKind.improvement,
        title: 'Vas mejor que la semana pasada',
        message: 'Has sumado $delta oraciones más que en los 7 días anteriores.',
      );
    }
    return null;
  }

  HomeInsight? _prayerPatternInsight(
    TrackingState tracking, {
    required int activeDays,
  }) {
    if (activeDays < 5) {
      return null;
    }

    final prayerCompletion = tracking.prayerCompletion;
    if (prayerCompletion.values.every((value) => value == 0)) {
      return null;
    }

    final sorted = prayerCompletion.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakest = sorted.first;
    final strongest = sorted.last;

    if (strongest.value >= 0.75 && strongest.value - weakest.value >= 0.12) {
      final prayer = _prayerLabel(strongest.key);
      return HomeInsight(
        kind: HomeInsightKind.prayerPattern,
        title: 'Tu oración más constante',
        message: '$prayer es la que mejor estás manteniendo este último tramo.',
      );
    }

    if (weakest.value <= 0.45 && strongest.value - weakest.value >= 0.12) {
      final prayer = _prayerLabel(weakest.key);
      return HomeInsight(
        kind: HomeInsightKind.prayerPattern,
        title: 'Punto a reforzar',
        message: '$prayer es la oración que más te cuesta ahora mismo. Un pequeño foco ahí puede mover toda la semana.',
      );
    }

    return null;
  }

  HomeInsight? _dhikrInsight({
    int? todayCount,
    int? dailyGoal,
  }) {
    if (todayCount == null || dailyGoal == null || dailyGoal <= 0) {
      return null;
    }

    if (todayCount >= dailyGoal) {
      return HomeInsight(
        kind: HomeInsightKind.dhikr,
        title: 'Dhikr del día cumplido',
        message: 'Ya alcanzaste tu meta diaria de dhikr con $todayCount repeticiones.',
      );
    }

    if (todayCount >= (dailyGoal / 2).ceil() && todayCount > 0) {
      return HomeInsight(
        kind: HomeInsightKind.dhikr,
        title: 'Buen ritmo de dhikr',
        message: 'Llevas $todayCount/$dailyGoal repeticiones hoy. Vas por buen camino.',
      );
    }

    return null;
  }

  HomeInsight? _ramadanInsight({
    required RamadanStatus? ramadanStatus,
    required WeeklySummary weeklySummary,
    required int prayerCountToday,
  }) {
    if (ramadanStatus == null || !ramadanStatus.isEnabled) {
      return null;
    }

    if (weeklySummary.completionRate >= 0.7) {
      return const HomeInsight(
        kind: HomeInsightKind.ramadan,
        title: 'Buena constancia en Ramadan',
        message: 'Durante Ramadan estas manteniendo un ritmo solido en tus oraciones.',
      );
    }

    if (prayerCountToday >= 2) {
      return const HomeInsight(
        kind: HomeInsightKind.ramadan,
        title: 'Aprovecha el impulso de hoy',
        message: 'Ramadan es un buen momento para cerrar fuerte el resto del dia.',
      );
    }

    return HomeInsight(
      kind: HomeInsightKind.ramadan,
      title: ramadanStatus.headerLabel,
      message: 'Las pequenas constancias de hoy pueden pesar mucho durante Ramadan.',
    );
  }

  int _completedPrayersInWindow(
    TrackingState tracking, {
    required DateTime endDate,
    required int days,
  }) {
    var total = 0;
    for (var index = 0; index < days; index++) {
      final date = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).subtract(Duration(days: index));
      total += tracking.completedCountFor(date);
    }
    return total;
  }

  String _prayerLabel(String prayerKey) {
    switch (prayerKey) {
      case 'fajr':
        return 'Fajr';
      case 'dhuhr':
        return 'Dhuhr';
      case 'asr':
        return 'Asr';
      case 'maghrib':
        return 'Maghrib';
      case 'isha':
        return 'Isha';
      default:
        return prayerKey;
    }
  }
}
