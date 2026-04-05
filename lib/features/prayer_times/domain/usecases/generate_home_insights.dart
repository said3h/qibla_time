import '../../../../core/localization/locale_controller.dart';
import '../entities/home_insight.dart';
import '../entities/ramadan_status.dart';
import '../../../../l10n/l10n.dart';
import '../entities/prayer_name.dart';
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
    final l10n = appLocalizationsForCurrentLocale();
    final candidates = <HomeInsight>[];
    final prayerCountToday = tracking.completedCountFor(now);
    final activeDays = tracking.data.values
        .where((day) => day.values.any((completed) => completed))
        .length;

    final todayInsight = _todayProgressInsight(
      prayerCountToday,
      now,
      l10n: l10n,
    );
    if (todayInsight != null) {
      candidates.add(todayInsight);
    }

    final streakInsight = _streakInsight(tracking.currentStreak, l10n: l10n);
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
      l10n: l10n,
    );
    if (prayerPatternInsight != null) {
      candidates.add(prayerPatternInsight);
    }

    final dhikrInsight = _dhikrInsight(
      todayCount: dhikrTodayCount,
      dailyGoal: dhikrDailyGoal,
      l10n: l10n,
    );
    if (dhikrInsight != null) {
      candidates.add(dhikrInsight);
    }

    final ramadanInsight = _ramadanInsight(
      ramadanStatus: ramadanStatus,
      weeklySummary: weeklySummary,
      prayerCountToday: prayerCountToday,
      l10n: l10n,
    );
    if (ramadanInsight != null) {
      candidates.add(ramadanInsight);
    }

    if (candidates.isEmpty) {
      candidates.add(
        HomeInsight(
          kind: HomeInsightKind.guidance,
          title: l10n.homeInsightStartTodayTitle,
          message: activeDays == 0
              ? l10n.homeInsightStartTodayFirstMessage
              : l10n.homeInsightStartTodayMoreMessage,
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

  HomeInsight? _todayProgressInsight(
    int prayerCountToday,
    DateTime now, {
    required AppLocalizations l10n,
  }) {
    if (prayerCountToday == 4) {
      return HomeInsight(
        kind: HomeInsightKind.progress,
        title: l10n.homeInsightAlmostCompleteTodayTitle,
        message: l10n.homeInsightAlmostCompleteTodayMessage,
      );
    }
    if (prayerCountToday > 0 && prayerCountToday < 4) {
      return HomeInsight(
        kind: HomeInsightKind.progress,
        title: l10n.homeInsightGoodPaceTodayTitle,
        message: l10n.homeInsightGoodPaceTodayMessage(prayerCountToday),
      );
    }
    if (prayerCountToday == 0 && now.hour >= 12) {
      return HomeInsight(
        kind: HomeInsightKind.progress,
        title: l10n.homeInsightStillCanStartTitle,
        message: l10n.homeInsightStillCanStartMessage,
      );
    }
    return null;
  }

  HomeInsight? _streakInsight(
    int streak, {
    required AppLocalizations l10n,
  }) {
    if (streak >= 2) {
      return HomeInsight(
        kind: HomeInsightKind.streak,
        title: l10n.homeInsightStreakInMotionTitle,
        message: l10n.homeInsightStreakInMotionMessage(streak),
      );
    }
    return null;
  }

  HomeInsight? _improvementInsight(TrackingState tracking, DateTime now) {
    final l10n = appLocalizationsForCurrentLocale();
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
        title: l10n.homeInsightBetterThanLastWeekTitle,
        message: l10n.homeInsightBetterThanLastWeekMessage(delta),
      );
    }
    return null;
  }

  HomeInsight? _prayerPatternInsight(
    TrackingState tracking, {
    required int activeDays,
    required AppLocalizations l10n,
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
        title: l10n.homeInsightMostConsistentPrayerTitle,
        message: l10n.homeInsightMostConsistentPrayerMessage(prayer),
      );
    }

    if (weakest.value <= 0.45 && strongest.value - weakest.value >= 0.12) {
      final prayer = _prayerLabel(weakest.key);
      return HomeInsight(
        kind: HomeInsightKind.prayerPattern,
        title: l10n.homeInsightPrayerToStrengthenTitle,
        message: l10n.homeInsightPrayerToStrengthenMessage(prayer),
      );
    }

    return null;
  }

  HomeInsight? _dhikrInsight({
    int? todayCount,
    int? dailyGoal,
    required AppLocalizations l10n,
  }) {
    if (todayCount == null || dailyGoal == null || dailyGoal <= 0) {
      return null;
    }

    if (todayCount >= dailyGoal) {
      return HomeInsight(
        kind: HomeInsightKind.dhikr,
        title: l10n.homeInsightDhikrDoneTitle,
        message: l10n.homeInsightDhikrDoneMessage(todayCount),
      );
    }

    if (todayCount >= (dailyGoal / 2).ceil() && todayCount > 0) {
      return HomeInsight(
        kind: HomeInsightKind.dhikr,
        title: l10n.homeInsightDhikrGoodPaceTitle,
        message: l10n.homeInsightDhikrGoodPaceMessage(todayCount, dailyGoal),
      );
    }

    return null;
  }

  HomeInsight? _ramadanInsight({
    required RamadanStatus? ramadanStatus,
    required WeeklySummary weeklySummary,
    required int prayerCountToday,
    required AppLocalizations l10n,
  }) {
    if (ramadanStatus == null || !ramadanStatus.isEnabled) {
      return null;
    }

    if (weeklySummary.completionRate >= 0.7) {
      return HomeInsight(
        kind: HomeInsightKind.ramadan,
        title: l10n.homeInsightRamadanConsistencyTitle,
        message: l10n.homeInsightRamadanConsistencyMessage,
      );
    }

    if (prayerCountToday >= 2) {
      return HomeInsight(
        kind: HomeInsightKind.ramadan,
        title: l10n.homeInsightRamadanMomentumTitle,
        message: l10n.homeInsightRamadanMomentumMessage,
      );
    }

    return HomeInsight(
      kind: HomeInsightKind.ramadan,
      title: ramadanStatus.headerLabel,
      message: l10n.homeInsightRamadanSmallStepsMessage,
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
    final languageCode = AppLocaleController.effectiveLanguageCode();
    switch (prayerKey) {
      case 'fajr':
        return PrayerName.fajr.localizedDisplayName(languageCode);
      case 'dhuhr':
        return PrayerName.dhuhr.localizedDisplayName(languageCode);
      case 'asr':
        return PrayerName.asr.localizedDisplayName(languageCode);
      case 'maghrib':
        return PrayerName.maghrib.localizedDisplayName(languageCode);
      case 'isha':
        return PrayerName.isha.localizedDisplayName(languageCode);
      default:
        return prayerKey;
    }
  }
}
