import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../l10n/l10n.dart';
import '../../hadith/services/hadith_service.dart';
import '../models/achievement.dart';
import '../models/tracking_models.dart';
import '../services/achievement_service.dart';
import '../services/analytics_share_service.dart';
import '../services/tracking_service.dart';

enum _AnalyticsShareAction { image, text }

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(prayerTrackingProvider);
    final achievements = ref.watch(achievementsProvider);
    final themeName = ref.watch(themeControllerProvider);
    final tokens = QiblaThemes.fromName(themeName);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        backgroundColor: tokens.bgApp,
        elevation: 0,
        title: Text(
          l10n.commonStatistics,
          style: GoogleFonts.amiri(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: tokens.primary,
          ),
        ),
        actions: tracking.hasAnyCompletedPrayer
            ? [
                PopupMenuButton<_AnalyticsShareAction>(
                  tooltip: l10n.analyticsShareProgressTooltip,
                  icon: Icon(Icons.ios_share_rounded, color: tokens.primary),
                  color: tokens.bgSurface,
                  onSelected: (action) => _handleShareAction(
                    context,
                    ref,
                    tracking,
                    tokens,
                    action,
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _AnalyticsShareAction.image,
                      child: Text(
                        l10n.analyticsShareImage,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: _AnalyticsShareAction.text,
                      child: Text(
                        l10n.analyticsShareText,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: tokens.border),
        ),
      ),
      body: RefreshIndicator(
        color: tokens.primary,
        onRefresh: () async {
          ref.invalidate(prayerTrackingProvider);
          ref.invalidate(achievementsProvider);
        },
        child: !tracking.hasAnyCompletedPrayer
            ? _EmptyAnalyticsState(tokens: tokens)
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _WeeklySummaryCard(
                    summary: tracking.currentWeekSummary,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 16),
                  _StreakCard(tracking: tracking, tokens: tokens),
                  const SizedBox(height: 16),
                  // Hadices Stats - NUEVO
                  const _HadithStatsCard(),
                  const SizedBox(height: 16),
                  _AchievementsCard(
                    achievements: achievements,
                    tokens: tokens,
                  ),
                  const SizedBox(height: 16),
                  _HeatmapCard(tracking: tracking, tokens: tokens),
                  const SizedBox(height: 16),
                  _PrayerProgressCard(tracking: tracking, tokens: tokens),
                  const SizedBox(height: 16),
                  _MonthlyTotalsCard(tracking: tracking, tokens: tokens),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Future<void> _handleShareAction(
    BuildContext context,
    WidgetRef ref,
    TrackingState tracking,
    QiblaTokens tokens,
    _AnalyticsShareAction action,
  ) async {
    try {
      final service = ref.read(analyticsShareServiceProvider);
      switch (action) {
        case _AnalyticsShareAction.image:
          await service.shareWeeklyProgressAsImage(tracking, tokens);
          break;
        case _AnalyticsShareAction.text:
          await service.shareWeeklyProgressAsText(tracking);
          break;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.analyticsShareError,
              style: GoogleFonts.dmSans(),
            ),
          ),
        );
      }
    }
  }
}

class _EmptyAnalyticsState extends StatelessWidget {
  const _EmptyAnalyticsState({required this.tokens});

  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: tokens.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            children: [
              Icon(Icons.insights_outlined, size: 42, color: tokens.primary),
              const SizedBox(height: 14),
              Text(
                context.l10n.analyticsEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tokens.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.analyticsEmptyBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  height: 1.6,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Text(
                  context.l10n.analyticsEmptyHint,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.summary,
    required this.tokens,
  });

  final WeeklySummary summary;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: context.l10n.analyticsWeeklySummaryTitle, tokens: tokens),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: context.l10n.analyticsThisWeekLabel,
                  value: '${summary.prayersCompleted}/${summary.maxPossible}',
                  helper: context.l10n.commonPrayers,
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: context.l10n.analyticsFullDaysLabel,
                  value: '${summary.fullDays}',
                  helper: '5/5',
                  tokens: tokens,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: context.l10n.analyticsBestDayLabel,
                  value: summary.strongestDay.shortLabel,
                  helper: '${summary.strongestDay.completed}/5',
                  tokens: tokens,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Text(
              summary.interpretation,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.5,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.helper,
    required this.tokens,
  });

  final String label;
  final String value;
  final String helper;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.bgSurface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: tokens.primaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.tracking,
    required this.tokens,
  });

  final TrackingState tracking;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final streak = tracking.currentStreak;
    final best = tracking.bestStreak;
    final l10n = context.l10n;

    return _Card(
      tokens: tokens,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tokens.primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.primaryBorder),
            ),
            child: Icon(
              streak > 0
                  ? Icons.local_fire_department_rounded
                  : Icons.bedtime_outlined,
              color: tokens.primaryLight,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0
                      ? l10n.analyticsNoActiveStreak
                      : l10n.analyticsStreakDays(streak),
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tokens.primaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak == 0
                      ? l10n.analyticsStartStreakHint
                      : l10n.analyticsBestStreakHint(best),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (streak == best && best > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.primaryBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.primaryBorder),
              ),
              child: Text(
                l10n.analyticsRecordBadge,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tokens.primaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard({
    required this.achievements,
    required this.tokens,
  });

  final AsyncValue<List<Achievement>> achievements;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: context.l10n.analyticsAchievementsTitle, tokens: tokens),
          const SizedBox(height: 14),
          achievements.when(
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  context.l10n.analyticsAchievementsEmpty,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: tokens.textSecondary,
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (achievement) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AchievementTile(
                          achievement: achievement,
                          tokens: tokens,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.primary,
                  ),
                ),
              ),
            ),
            error: (_, __) => Text(
              context.l10n.analyticsAchievementsLoadError,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.tokens,
  });

  final Achievement achievement;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final surfaceColor = isUnlocked ? tokens.primaryBg : tokens.bgSurface2;
    final borderColor = isUnlocked ? tokens.primaryBorder : tokens.border;
    final iconColor = isUnlocked ? tokens.primaryLight : tokens.textSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isUnlocked ? tokens.activeBg : tokens.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(achievement.icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      achievement.progressLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked
                            ? tokens.primary
                            : tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.5,
                    color: tokens.textSecondary,
                  ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: achievement.progressRatio,
                      minHeight: 6,
                      backgroundColor: tokens.bgSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({
    required this.tracking,
    required this.tokens,
  });

  final TrackingState tracking;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final days = tracking.last30Days;

    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: context.l10n.analyticsLast30DaysTitle, tokens: tokens),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: days.length,
            itemBuilder: (_, index) => _HeatCell(day: days[index], tokens: tokens),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                context.l10n.analyticsLessLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: _legendCell(index),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.analyticsMoreLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: tokens.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendCell(int level) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _heatColor(level),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _heatColor(int level) {
    switch (level) {
      case 0:
        return tokens.bgSurface2;
      case 1:
        return tokens.primary.withOpacity(0.20);
      case 2:
        return tokens.primary.withOpacity(0.40);
      case 3:
        return tokens.primary.withOpacity(0.65);
      default:
        return tokens.primary;
    }
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.day,
    required this.tokens,
  });

  final HeatmapDay day;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${day.date.day}/${day.date.month}: ${day.completed}/5',
      child: Container(
        decoration: BoxDecoration(
          color: _color(),
          borderRadius: BorderRadius.circular(3),
          border: day.isToday
              ? Border.all(color: tokens.primary, width: 1.5)
              : null,
        ),
      ),
    );
  }

  Color _color() {
    if (day.completed == 0) return tokens.bgSurface2;
    if (day.completed <= 1) return tokens.primary.withOpacity(0.20);
    if (day.completed <= 2) return tokens.primary.withOpacity(0.40);
    if (day.completed <= 4) return tokens.primary.withOpacity(0.65);
    return tokens.primary;
  }
}

class _PrayerProgressCard extends StatelessWidget {
  const _PrayerProgressCard({
    required this.tracking,
    required this.tokens,
  });

  final TrackingState tracking;
  final QiblaTokens tokens;

  static const _prayers = [
    ('fajr', 'Fajr', 'فجر'),
    ('dhuhr', 'Dhuhr', 'ظهر'),
    ('asr', 'Asr', 'عصر'),
    ('maghrib', 'Maghrib', 'مغرب'),
    ('isha', 'Isha', 'عشاء'),
  ];

  @override
  Widget build(BuildContext context) {
    final completion = tracking.prayerCompletion;

    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: context.l10n.analyticsByPrayerTitle, tokens: tokens),
          const SizedBox(height: 14),
          ..._prayers.map(
            (prayer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PrayerBar(
                name: prayer.$2,
                arabic: prayer.$3,
                ratio: completion[prayer.$1] ?? 0,
                tokens: tokens,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerBar extends StatelessWidget {
  const _PrayerBar({
    required this.name,
    required this.arabic,
    required this.ratio,
    required this.tokens,
  });

  final String name;
  final String arabic;
  final double ratio;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isArabicOnly = Localizations.localeOf(context).languageCode == 'ar';
    final primaryLabel = isArabicOnly ? arabic : name;
    final percentage = (ratio * 100).round();

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                primaryLabel,
                style: GoogleFonts.amiri(
                  fontSize: 15,
                  color: tokens.textPrimary,
                ),
              ),
            ),
            if (!isArabicOnly)
              Text(
                arabic,
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  color: tokens.textSecondary,
                ),
              ),
            const Spacer(),
            Text(
              '$percentage%',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _barColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: tokens.bgSurface2,
            valueColor: AlwaysStoppedAnimation<Color>(_barColor()),
          ),
        ),
      ],
    );
  }

  Color _barColor() {
    if (ratio >= 0.8) return tokens.primary;
    if (ratio >= 0.5) return tokens.primary.withOpacity(0.7);
    return tokens.primary.withOpacity(0.4);
  }
}

class _MonthlyTotalsCard extends StatelessWidget {
  const _MonthlyTotalsCard({
    required this.tracking,
    required this.tokens,
  });

  final TrackingState tracking;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    final stats = tracking.currentMonthStats;
    final completionPercentage = (stats.completionRate * 100).round();
    final l10n = context.l10n;

    return _Card(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: stats.monthName, tokens: tokens),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: stats.completionRate,
                      strokeWidth: 7,
                      backgroundColor: tokens.bgSurface2,
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.primary),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _StatRow(
                      label: l10n.analyticsCompletedPrayersLabel,
                      value: '${stats.prayersCompleted}/${stats.maxPossible}',
                      tokens: tokens,
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      label: l10n.analyticsFullDaysLabel,
                      value: l10n.analyticsDaysValue(stats.fullDays),
                      tokens: tokens,
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      label: l10n.analyticsBestStreakLabel,
                      value: l10n.analyticsDaysValue(tracking.bestStreak),
                      tokens: tokens,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.tokens,
  });

  final String label;
  final String value;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: tokens.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    required this.tokens,
  });

  final Widget child;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: child,
    );
  }
}

class _CompactAnalyticsErrorCard extends StatelessWidget {
  const _CompactAnalyticsErrorCard({
    required this.tokens,
    required this.message,
  });

  final QiblaTokens tokens;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      tokens: tokens,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: tokens.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                height: 1.5,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.tokens,
  });

  final String title;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: tokens.textSecondary,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Tarjeta de Estadísticas de Hadices ────────────────────────────────

class _HadithStatsCard extends ConsumerWidget {
  const _HadithStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = QiblaThemes.current;
    final l10n = context.l10n;
    final favoritesAsync = ref.watch(hadithFavoritesProvider);
    final hadithsAsync = ref.watch(allHadithsProvider);

    return favoritesAsync.when(
      data: (favorites) => hadithsAsync.when(
        data: (hadiths) {
          final totalHadiths = hadiths.length;
          final favoritesCount = favorites.length;
          final collectionsCount = hadiths
              .map((hadith) => _extractCollection(hadith.reference))
              .toSet()
              .length;
          final gradesCount = hadiths
              .map((hadith) => hadith.grade.trim())
              .where((grade) => grade.isNotEmpty)
              .toSet()
              .length;
          final favoritesRatio = totalHadiths == 0
              ? 0.0
              : favoritesCount / totalHadiths;

          return _Card(
            tokens: tokens,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: l10n.commonHadiths, tokens: tokens),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: l10n.commonTotal,
                        value: totalHadiths.toString(),
                        icon: Icons.auto_stories,
                        color: Colors.green,
                        tokens: tokens,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatItem(
                        label: l10n.analyticsFavoritesLabel,
                        value: favoritesCount.toString(),
                        icon: Icons.favorite,
                        color: Colors.red,
                        tokens: tokens,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: l10n.analyticsCollectionsLabel,
                        value: collectionsCount.toString(),
                        icon: Icons.folder,
                        color: Colors.orange,
                        tokens: tokens,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatItem(
                        label: l10n.analyticsGradesLabel,
                        value: gradesCount.toString(),
                        icon: Icons.verified,
                        color: Colors.blue,
                        tokens: tokens,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.analyticsSavedFavoritesLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(favoritesRatio * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: tokens.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: favoritesRatio,
                        backgroundColor: tokens.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tokens.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => _Card(
          tokens: tokens,
          child: Center(
            child: CircularProgressIndicator(color: tokens.primary),
          ),
        ),
        error: (_, __) => _CompactAnalyticsErrorCard(
          tokens: tokens,
          message: l10n.analyticsHadithStatsLoadError,
        ),
      ),
      loading: () => _Card(
        tokens: tokens,
        child: Center(
          child: CircularProgressIndicator(color: tokens.primary),
        ),
      ),
      error: (_, __) => _CompactAnalyticsErrorCard(
        tokens: tokens,
        message: l10n.analyticsHadithStatsLoadError,
      ),
    );
  }

  String _extractCollection(String reference) {
    final refLower = reference.toLowerCase();
    if (refLower.contains('bujari') || refLower.contains('bukhari')) {
      return 'Bukhari';
    }
    if (refLower.contains('muslim')) return 'Muslim';
    if (refLower.contains('tirmidhi')) return 'Tirmidhi';
    if (refLower.contains('abu dawud') || refLower.contains('abudawud')) {
      return 'Abu Dawud';
    }
    if (refLower.contains('nasai')) return 'Nasai';
    if (refLower.contains('ibn majah') || refLower.contains('ibnmajah')) {
      return 'Ibn Majah';
    }
    if (refLower.contains('malik') || refLower.contains('muwatta')) {
      return 'Malik';
    }
    if (refLower.contains('ahmad')) return 'Ahmad';
    return 'Otros';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tokens,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final QiblaTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
